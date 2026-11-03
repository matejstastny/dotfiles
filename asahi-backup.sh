#!/usr/bin/env bash
#
# pre-service backup of a fedora asahi remix install to onedrive.
#
#   real run:   sudo tmux new -s bk ~/dotfiles/asahi-backup.sh
#   self test:  sudo ~/dotfiles/asahi-backup.sh --test
#   paranoid:   sudo tmux new -s bk ~/dotfiles/asahi-backup.sh --verify-full
#
# asks nothing once started. root is required at launch because it snapshots
# btrfs subvolumes, mounts subvolid=5 and images partitions.
#
# the destination must be an rclone crypt remote: this archive contains
# /etc/shadow, ~/.ssh and the login keyrings, and it refuses to upload in
# plaintext. the passphrase is NOT inside the backup, keep it elsewhere.
#
# this does NOT produce a bootable image. the asahi boot chain lives in a
# LocalPolicy in nvme0n1p1 signed against this machine's secure enclave plus
# the apfs stub at p3, so restoring blocks onto a wiped disk will not boot.
# the restore path is: reinstall asahi from macos, then unpack this over it.
# see RESTORE.md, which this script writes into the backup.

set -euo pipefail

#--------------------------------------------------------------------- config
OWNER=elara
DISK=/dev/nvme0n1
BTRFS_PART="${DISK}p6"
RAW_PARTS=(1 3 4 5)              # iboot container, asahi apfs stub, esp, /boot
TOP=/mnt/asahi-bk-top
STAGE="${ASAHI_BK_STAGE:-/var/tmp/asahi-backup}"
SPLIT_SIZE=2G
RCLONE_REMOTE="onedrive-crypt"        # must be type=crypt, enforced below
REMOTE_BASE="$RCLONE_REMOTE:backups"
MIN_FREE_GIB=75
RCLONE_CONF="/home/$OWNER/.config/rclone/rclone.conf"
ZSTD_LEVEL=3

TEST=0
PURGE_STAGE=0
VERIFY_FULL=0
for a in "${@:-}"; do
  case "$a" in
    ""|--) ;;
    --test)        TEST=1 ;;
    --purge-stage) PURGE_STAGE=1 ;;
    --verify-full) VERIFY_FULL=1 ;;
    -h|--help)     sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown argument: $a" >&2; exit 2 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "error: must run as root. try:" >&2
  echo "  sudo tmux new -s bk $0 $*" >&2
  exit 1
fi

# keep the machine awake for the whole run, including with the lid shut
if [[ -z "${ASAHI_BK_INHIBITED:-}" ]]; then
  export ASAHI_BK_INHIBITED=1
  exec systemd-inhibit --what=idle:sleep:shutdown --who=asahi-backup \
       --why="pre-service backup in progress" "$0" "$@"
fi

if (( TEST )); then
  REMOTE_BASE="$RCLONE_REMOTE:_asahi_backup_test"
  STAGE=/var/tmp/asahi-backup-test
  SPLIT_SIZE=16M
  MIN_FREE_GIB=3
  RAW_PARTS=(4)
  rm -rf "$STAGE"
fi

STATE="$STAGE/.state"
mkdir -p "$STATE"
LOG="$STAGE/backup.log"
exec > >(tee -a "$LOG") 2>&1

# a resumed run must reuse the original destination name
if [[ -f "$STATE/name" ]]; then
  NAME=$(<"$STATE/name")
  echo ">>> resuming existing run: $NAME"
else
  NAME="$( (( TEST )) && echo selftest || echo "asahi-$(hostname -s)" )-$(date +%Y%m%d-%H%M%S)"
  printf '%s\n' "$NAME" > "$STATE/name"
fi
DEST="$REMOTE_BASE/$NAME"
M="$STAGE/meta"
FAIL=0

echo "=============================================================="
echo " asahi backup   $(date -Is)"
echo " mode           $( (( TEST )) && echo SELF-TEST || echo full )"
echo " staging        $STAGE"
echo " destination    $DEST"
echo "=============================================================="

#--------------------------------------------------------------------- helpers
# rclone must run as the owning user: the oauth token lives in their config and
# refreshing it as root would leave a root-owned config behind.
rc() { runuser -u "$OWNER" -- env RCLONE_CONFIG="$RCLONE_CONF" "$@"; }
asuser() { runuser -u "$OWNER" -- "$@"; }

cleanup() {
  set +e
  for s in root home; do
    [[ -e "$TOP/.bk-$s" ]] && btrfs subvolume delete "$TOP/.bk-$s" >/dev/null 2>&1
  done
  if mountpoint -q "$TOP"; then umount "$TOP" && rmdir "$TOP" 2>/dev/null; fi
}
trap cleanup EXIT

# make_tar <label> <srcdir> <member> [exclude...]
make_tar() {
  local label="$1" src="$2" member="$3"; shift 3
  local -a args=(
    --numeric-owner --xattrs --xattrs-include='*' --selinux --acls --sparse
    --warning=no-file-ignored --warning=no-file-changed --warning=no-file-removed
  )
  local e
  for e in "$@"; do args+=( "--exclude=$e" ); done

  echo ">>> archiving $label"
  # a resumed run would otherwise leave stale higher-numbered parts behind from
  # a longer previous attempt, and cat label.tar.zst.* would splice them back in
  rm -f "$STAGE/$label".tar.zst.*

  local free; free=$(df -BG --output=avail "$STAGE" | tail -1 | tr -dc '0-9')
  if (( free < 20 )); then
    echo "!! only ${free} GiB free on the staging fs, stopping before $label"
    echo "   set ASAHI_BK_STAGE to a path on an external disk and rerun"
    return 1
  fi

  set +e
  tar -C "$src" "${args[@]}" -cf - "$member" 2>"$M/tar-$label.err" \
    | zstd -T0 "-$ZSTD_LEVEL" -q -c \
    | pv -f -N "$label" -i 20 \
    | split -b "$SPLIT_SIZE" -d -a 4 - "$STAGE/$label.tar.zst."
  local st=( "${PIPESTATUS[@]}" )
  set -e

  # tar exit 1 is warnings only, which is expected noise from a live tree
  if (( st[0] > 1 )); then
    echo "!! tar failed for $label (exit ${st[0]})"; sed -n '1,25p' "$M/tar-$label.err"; return 1
  fi
  (( st[1] == 0 )) || { echo "!! zstd failed for $label"; return 1; }
  (( st[3] == 0 )) || { echo "!! split failed for $label"; return 1; }
  (( st[0] == 1 )) && echo "   tar reported warnings, see meta/tar-$label.err"
  echo "   staged so far: $(du -sh "$STAGE" | cut -f1)"
  return 0
}

# verify_label <label>: prove the staged parts read back as a tar
verify_label() {
  local label="$1"
  local -a parts
  shopt -s nullglob; parts=( "$STAGE/$label".tar.zst.* ); shopt -u nullglob
  (( ${#parts[@]} )) || { echo "!! no parts staged for $label"; return 1; }
  printf '    %-14s ' "readback"
  if cat "${parts[@]}" | zstd -dc -q | tar -tf - >/dev/null 2>&1; then
    echo OK
  else
    echo FAILED; return 1
  fi
}

# sums_label <label>: record checksums while the parts still exist locally
sums_label() {
  local label="$1"
  ( cd "$STAGE" && sha256sum ./"$label".tar.zst.* ) > "$STATE/sums-$label"
}

# upload_label <label>: push just this label, size check it, then prove content
upload_label() {
  local label="$1"
  local -a inc=( --include "/$label.tar.zst.*" )
  echo ">>> uploading $label"
  chown -R "$OWNER:$OWNER" "$STAGE"
  rc rclone copy "$STAGE" "$DEST" "${inc[@]}" \
    --onedrive-chunk-size 100M \
    --transfers 8 \
    --retries 10 --retries-sleep 20s --low-level-retries 20 \
    --stats 30s --stats-one-line || return 1

  rc rclone check "$STAGE" "$DEST" "${inc[@]}" --one-way --size-only || return 1

  if (( VERIFY_FULL )); then
    echo "    full content verification of $label, downloading it back"
    rc rclone check "$STAGE" "$DEST" "${inc[@]}" --one-way --download || return 1
    echo "    full content verification OK"
    return 0
  fi

  # crypt cannot pass hashes through, so sample one part and hash it for real
  local pick want got
  pick=$(cd "$STAGE" && ls "$label".tar.zst.* | shuf -n 1)
  want=$(awk -v f="./$pick" '$2==f{print $1}' "$STATE/sums-$label")
  got=$(rc rclone cat "$DEST/$pick" 2>/dev/null | sha256sum | cut -d' ' -f1)
  if [[ -n "$want" && "$want" == "$got" ]]; then
    echo "    content spot check on $pick OK"
  else
    echo "!! content spot check on $pick MISMATCH (local ${want:-?}, remote ${got:-?})"
    return 1
  fi
}

# stage_one <label> <srcdir> <member> [exclude...]
# archive, verify, checksum, upload, then drop the local copy. staging only ever
# holds one archive at a time: the full set does not fit beside the live data.
stage_one() {
  local label="$1"
  if [[ -f "$STATE/done-$label" ]]; then
    echo ">>> $label already uploaded by an earlier run, skipping"
    return 0
  fi
  make_tar "$@"      || return 1
  verify_label "$label" || return 1
  sums_label   "$label"
  upload_label "$label" || return 1
  if (( TEST )); then
    echo "    test mode: keeping $label staged for the selinux round trip"
  else
    rm -f "$STAGE/$label".tar.zst.*
  fi
  touch "$STATE/done-$label"
  echo "    $label done, $(df -BG --output=avail "$STAGE" | tail -1 | tr -dc '0-9') GiB free on staging again"
}

#--------------------------------------------------------------------- preflight
echo ">>> preflight"
for t in btrfs tar zstd split pv sfdisk rclone runuser getfattr; do
  command -v "$t" >/dev/null || { echo "!! missing required tool: $t"; exit 1; }
done
[[ -b "$BTRFS_PART" ]] || { echo "!! $BTRFS_PART is not a block device"; exit 1; }
[[ -r "$RCLONE_CONF" ]] || { echo "!! no rclone config at $RCLONE_CONF"; exit 1; }

FREE_GIB=$(df -BG --output=avail "$STAGE" | tail -1 | tr -dc '0-9')
echo "    free space on staging fs: ${FREE_GIB} GiB (need ${MIN_FREE_GIB})"
(( FREE_GIB >= MIN_FREE_GIB )) || { echo "!! not enough free space to stage the archive"; exit 1; }

echo "    checking $RCLONE_REMOTE is encrypted"
if [[ "$(rc rclone config show "$RCLONE_REMOTE" 2>/dev/null | awk -F ' = ' '/^type/{print $2}')" != crypt ]]; then
  echo "!! $RCLONE_REMOTE is not an rclone crypt remote."
  echo "   this archive contains /etc/shadow, ~/.ssh and your login keyrings."
  echo "   refusing to upload it in plaintext. see RESTORE.md section 1."
  exit 1
fi

echo "    checking remote auth and quota"
rc rclone about "$RCLONE_REMOTE:" || { echo "!! rclone cannot reach $RCLONE_REMOTE"; exit 1; }

# a wrong or regenerated passphrase uploads perfectly happily and hands back
# garbage months later, so prove one file survives the trip before committing
echo "    crypt round trip"
PROBE=$(mktemp -d /var/tmp/asahi-bk-probe.XXXXXX)
printf '%s\n' "$NAME" > "$PROBE/probe"
chown -R "$OWNER:$OWNER" "$PROBE"
if rc rclone copy "$PROBE/probe" "$REMOTE_BASE/.probe" >/dev/null 2>&1 \
   && rc rclone cat "$REMOTE_BASE/.probe/probe" 2>/dev/null | grep -qxF "$NAME"; then
  echo "    crypt round trip OK"
else
  echo "!! crypt round trip failed, not uploading"; rm -rf "$PROBE"; exit 1
fi
rc rclone purge "$REMOTE_BASE/.probe" >/dev/null 2>&1 || true
rm -rf "$PROBE"

#--------------------------------------------------------------------- archive
mkdir -p "$M"
cp "$0" "$M/asahi-backup.sh"

echo ">>> collecting metadata"
sfdisk -d "$DISK"                           > "$M/partition-table.sfdisk"
sfdisk -l "$DISK"                           > "$M/partition-table.txt" 2>/dev/null || true
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,PARTLABEL,UUID,PARTUUID,MOUNTPOINT \
                                            > "$M/lsblk.txt"
blkid                                       > "$M/blkid.txt" 2>/dev/null || true
cat /proc/mounts                            > "$M/proc-mounts.txt"
cp /etc/fstab                                 "$M/fstab"
cp /etc/os-release                            "$M/os-release"
uname -a                                    > "$M/uname.txt"
getenforce                                  > "$M/selinux-mode.txt" 2>/dev/null || true
btrfs filesystem usage /                    > "$M/btrfs-usage.txt" 2>/dev/null || true
btrfs subvolume list /                      > "$M/btrfs-subvols.txt" 2>/dev/null || true
efibootmgr -v                               > "$M/efibootmgr.txt" 2>/dev/null || true
find /boot/efi -maxdepth 4                  > "$M/boot-efi-tree.txt" 2>/dev/null || true
cp /boot/config-*                             "$M/" 2>/dev/null || true
docker images --digests                     > "$M/docker-images.txt" 2>/dev/null || true
docker ps -a                                > "$M/docker-ps.txt"     2>/dev/null || true
docker volume ls                            > "$M/docker-volumes.txt" 2>/dev/null || true
# so a future run can see at a glance what made the root archive big. btrfs
# reports shared extents once, tar does not, so these numbers are a floor.
du -xh --max-depth=2 / 2>/dev/null | sort -rh | head -40 \
                                            > "$M/root-usage-top40.txt" || true
du -xsh /var/lib/docker /var/lib/containers /var/lib/libvirt 2>/dev/null \
                                            > "$M/container-store-sizes.txt" || true
rpm -qa | sort                              > "$M/rpm-all.txt"
dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort \
                                            > "$M/dnf-userinstalled.txt" || true
dnf repolist --all                          > "$M/dnf-repolist.txt" 2>/dev/null || true
flatpak list --columns=application,origin,branch,installation \
                                            > "$M/flatpak-all.txt" 2>/dev/null || true
flatpak remotes --columns=name,url           > "$M/flatpak-remotes.txt" 2>/dev/null || true
systemctl list-unit-files --state=enabled --no-pager \
                                            > "$M/systemd-enabled.txt" 2>/dev/null || true
find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -printf '%M %u %g %p\n' 2>/dev/null \
  | sort                                    > "$M/setuid-setgid-files.txt" || true
getcap -r /usr /opt                         > "$M/file-capabilities.txt" 2>/dev/null || true
asuser systemctl --user list-unit-files --state=enabled --no-pager \
                                            > "$M/systemd-user-enabled.txt" 2>/dev/null || true

# uncommitted kernel work, read from the live tree so git can touch its index
LIVE_LFD="/home/$OWNER/linux-fairydust"
if [[ -d "$LIVE_LFD/.git" ]]; then
  echo ">>> capturing linux-fairydust git state"
  g() { asuser git --no-optional-locks -C "$LIVE_LFD" "$@"; }
  g remote -v              > "$M/fairydust-remotes.txt"  2>/dev/null || true
  g branch -vv             > "$M/fairydust-branches.txt" 2>/dev/null || true
  g log --oneline -40      > "$M/fairydust-log.txt"      2>/dev/null || true
  g status --porcelain     > "$M/fairydust-status.txt"    2>/dev/null || true
  g diff HEAD              > "$M/fairydust-uncommitted.patch" 2>/dev/null || true
  # .config is gitignored (.gitignore matches .*), so it rides in neither the
  # .git tar nor the untracked tar, and /boot carries no config-7.1.13-fairydust+.
  # meta/ is its only copy in this backup.
  cp "$LIVE_LFD/.config"       "$M/fairydust-kernel.config"     2>/dev/null || true
  cp "$LIVE_LFD/.config.old"   "$M/fairydust-kernel.config.old" 2>/dev/null || true
  cp "$LIVE_LFD"/localversion* "$M/" 2>/dev/null || true
  g ls-files --others --exclude-standard -z \
                           > "$STATE/fairydust-untracked.nul" 2>/dev/null || true
  if [[ -s "$STATE/fairydust-untracked.nul" ]]; then
    tar -C "$LIVE_LFD" --null -T "$STATE/fairydust-untracked.nul" \
        --numeric-owner --xattrs --xattrs-include='*' -cf - 2>/dev/null \
      | zstd -T0 "-$ZSTD_LEVEL" -q -o "$STAGE/fairydust-untracked.tar.zst" -f || true
  fi
fi

echo ">>> imaging small partitions"
for p in "${RAW_PARTS[@]}"; do
  dev="${DISK}p${p}"
  [[ -b "$dev" ]] || { echo "    skip $dev (absent)"; continue; }
  echo "    $dev -> nvme0n1p${p}.img.zst"
  dd if="$dev" bs=4M status=none \
    | zstd -T0 "-$ZSTD_LEVEL" -q -o "$STAGE/nvme0n1p${p}.img.zst" -f
done

echo ">>> mounting btrfs top level and snapshotting"
mkdir -p "$TOP"
mountpoint -q "$TOP" || mount -o subvolid=5 "$BTRFS_PART" "$TOP"
for s in root home; do
  [[ -e "$TOP/.bk-$s" ]] && btrfs subvolume delete "$TOP/.bk-$s" >/dev/null
  btrfs subvolume snapshot -r "$TOP/$s" "$TOP/.bk-$s" >/dev/null
  echo "    snapshot: .bk-$s"
done

# nested subvolumes appear as empty dirs inside a snapshot, so their contents
# would be silently missed. say so loudly rather than pretend.
NESTED=$(btrfs subvolume list "$TOP" | awk '{print $NF}' \
         | grep -vxE 'root|home|root/var/swap' | grep -v '^\.bk-' || true)
if [[ -n "$NESTED" ]]; then
  echo "!! WARNING: nested subvolumes are NOT captured by these snapshots:"
  printf '%s\n' "$NESTED" | sed 's/^/     /'
  printf '%s\n' "$NESTED" > "$M/NESTED-SUBVOLS-NOT-BACKED-UP.txt"
fi

ROOT_EXCL=(
  ./proc ./sys ./dev ./run ./tmp ./home ./lost+found
  ./var/cache ./var/tmp ./var/log ./var/swap
  ./var/lib/systemd/coredump
  # the whole docker tree goes, and volumes come back as their own archive
  # below. layer stores are heavily reflinked, so btrfs counts a shared extent
  # once while tar writes out every reference: this machine held ~94 GiB on
  # disk for ~194 GiB logical. naming the layer dirs directly is a trap too,
  # they move between versions (overlay2 for the classic graphdriver,
  # containerd/ for the overlayfs snapshotter), so take the lot.
  ./var/lib/docker
  ./var/lib/containers
)
HOME_EXCL=(
  "./$OWNER/.cache"
  "./$OWNER/.local/share/pnpm/store"
  "./$OWNER/.local/share/Steam/steamapps"
  "./$OWNER/.npm/_cacache"
  "./$OWNER/.cargo/registry"
  "./$OWNER/.cargo/git"
  "./$OWNER/.rustup/toolchains"
  "./$OWNER/.gradle/caches"
  "./$OWNER/factorio"
  "./$OWNER/linux-fairydust"
  "./$OWNER/.var/app/*/cache"
  '*/node_modules'
  '*/target/debug'
  '*/target/release'
  '*/__pycache__'
  '*/.venv'
  '*/.next/cache'
)

if (( TEST )); then
  stage_one root "$TOP/.bk-root" ./etc
else
  stage_one root "$TOP/.bk-root" . "${ROOT_EXCL[@]}"
  stage_one home "$TOP/.bk-home" . "${HOME_EXCL[@]}"
  if [[ -d "$TOP/.bk-home/$OWNER/linux-fairydust/.git" ]]; then
    stage_one fairydust-git "$TOP/.bk-home/$OWNER/linux-fairydust" .git
  fi
  # named volumes are the one part of /var/lib/docker that is not re-pullable
  if [[ -d "$TOP/.bk-root/var/lib/docker/volumes" ]]; then
    stage_one docker-volumes "$TOP/.bk-root/var/lib/docker" volumes
  fi
fi

cat > "$STAGE/RESTORE.md" <<'MD'
# restoring this backup

This backup is **not a bootable image** and cannot be dd'd back into place.
The Asahi boot chain depends on a LocalPolicy blob in `nvme0n1p1` that is
signed against this machine's Secure Enclave, plus the APFS stub container at
`nvme0n1p3`. Those are not reproducible from a block copy, and a logic board
swap invalidates them regardless. Restore is therefore: reinstall, then unpack.

## 0. what is in here

| file | contents |
|---|---|
| `root.tar.zst.*`          | the `root` btrfs subvolume, incl. `/usr`, `/etc`, `/opt`, `/var` |
| `home.tar.zst.*`          | the `home` btrfs subvolume (`/home/elara`) |
| `fairydust-git.tar.zst.*` | the `.git` of the kernel tree, build output excluded |
| `fairydust-untracked.tar.zst` | untracked non-ignored files from the kernel tree, if any |
| `docker-volumes.tar.zst.*` | `/var/lib/docker/volumes`, the only non-re-pullable part of docker |
| `nvme0n1p1.img.zst`       | iBootSystemContainer, reference only, not restorable |
| `nvme0n1p3.img.zst`       | Asahi APFS stub, reference only, not restorable |
| `nvme0n1p4.img.zst`       | the EFI system partition (m1n1 + u-boot + grub) |
| `nvme0n1p5.img.zst`       | `/boot` (kernels + initramfs + dtbs) |
| `meta/fairydust-kernel.config` | the exact `.config` of the running custom kernel |
| `meta/config-*`           | the `/boot` configs of the stock and older kernels |
| `meta/`                   | partition table, package lists, UUIDs, unit state |
| `SHA256SUMS`              | checksums for everything above |

Excluded on purpose, all regenerable: `~/.cache`, the 8G swapfile,
`node_modules`, `target/{debug,release}`, pnpm/npm/cargo/rustup/gradle caches,
`factorio`, Steam `steamapps`, `/var/{cache,tmp,log}`, and the kernel build
output. PrismLauncher and `/usr` are included in full.

`/var/lib/docker` is excluded wholesale, and `/var/lib/docker/volumes` is
archived separately as `docker-volumes.tar.zst.*`. GNU tar cannot include a
subdirectory of an excluded parent, hence the separate archive.

The reason for excluding it: layer stores are heavily reflinked, so btrfs counts
a shared extent once while `tar` writes out every reference. This machine held
~94 GiB of docker on disk for ~194 GiB logical (64 GB images, 122 GB build
cache), which inflated the root archive to 90.7 GiB and filled the staging
filesystem. Layer dir names also move between docker versions (`overlay2` for
the classic graphdriver, `containerd/` for the overlayfs snapshotter), so the
whole tree is excluded rather than named subdirectories.

Images and build cache are re-pullable. `meta/docker-images.txt`,
`meta/docker-ps.txt` and `meta/docker-volumes.txt` record what was present.
To restore the volumes:

    cat docker-volumes.tar.zst.* | zstd -dc | \
      tar -C /mnt/top/root/var/lib/docker -p --same-owner --xattrs -xf -

    docker image ls              # empty, re-pull or rebuild from
    cat meta/docker-images.txt   # this inventory

Note that `~/linux-fairydust` is excluded as a tree. What survives of it is the
`.git` tarball, `meta/fairydust-uncommitted.patch` for the dirty worktree, and
`meta/fairydust-kernel.config`. A full rebuild is required after restore.

## 1. pull it back down

The destination is an `rclone crypt` remote, so all of the above was encrypted
client side before upload. **The passphrase is not in this backup.** The rclone
config that holds it lives inside `home.tar.zst`, which is itself encrypted, so
there is no way in without the passphrase from the password manager.

On a fresh machine, recreate both remotes first:

    rclone config create onedrive onedrive                  # runs the oauth flow
    rclone config create onedrive-crypt crypt               \
        remote onedrive:backups-enc                         \
        filename_encryption off directory_name_encryption false \
        password '<passphrase>' --obscure

    rclone copy onedrive-crypt:backups/<NAME> ./restore \
        --transfers 4 --onedrive-chunk-size 100M
    cd restore && sha256sum -c SHA256SUMS

`SHA256SUMS` is the authoritative integrity check. `rclone check` against a
crypt remote cannot compare hashes (OneDrive's QuickXorHash does not survive
the encryption layer), so the backup script only verified sizes plus a random
sample. Run the `sha256sum -c` above and believe that instead.

Filename encryption is deliberately off. The names leak nothing interesting and
being able to see and selectively fetch a single `nvme0n1p5.img.zst` from the
OneDrive web UI is worth more during a disaster than hiding the string
`root.tar.zst`.

## 2. reinstall asahi

Boot macOS, run the Asahi installer, and give the Linux partition **at least as
much space as before** (it was 363.5 GiB). Let it complete and boot into the
fresh Fedora Asahi install once, to confirm its own boot chain works. Check
`meta/os-release` for the release to match.

## 3. unpack over the fresh install

Do this from a live USB or a rescue shell, not from the install you are about to
replace. **Replace the subvolumes, do not extract on top of them.** Extracting
over the fresh subvolumes leaves a union of two systems: every file the fresh
install has that this backup does not would survive, which for `/etc` gives you
a config set that matches neither system.

    mkdir -p /mnt/top
    mount -o subvolid=5 /dev/nvme0n1p6 /mnt/top    # confirm the device first

    btrfs subvolume delete /mnt/top/root
    btrfs subvolume delete /mnt/top/home
    btrfs subvolume create /mnt/top/root
    btrfs subvolume create /mnt/top/home

    cat root.tar.zst.* | zstd -dc | \
      tar -C /mnt/top/root --numeric-owner --xattrs --xattrs-include='*' \
          --selinux --acls -p --same-owner -xf -

    cat home.tar.zst.* | zstd -dc | \
      tar -C /mnt/top/home --numeric-owner --xattrs --xattrs-include='*' \
          --selinux --acls -p --same-owner -xf -

The `--xattrs-include='*' --selinux` flags are **mandatory**. This system runs
SELinux in Enforcing mode; drop those flags and every file loses its security
label, which leaves a system you cannot log into.

`-p --same-owner` is equally mandatory. Without `-p`, GNU tar strips setuid and
setgid bits on extract, which silently breaks all 27 setuid binaries in `/usr`,
`sudo` and `passwd` among them. Verify afterwards against
`meta/setuid-setgid-files.txt` and `meta/file-capabilities.txt`:

    find /usr -xdev -type f \( -perm -4000 -o -perm -2000 \) | sort

## 4. fix up fstab and the swapfile

New partitions get new UUIDs. The restored `/etc/fstab` carries the *old* ones,
so it must be rewritten:

    blkid                        # read the new UUIDs
    cat meta/fstab               # the old file, for the structure and options

Keep the mount options exactly as they were, in particular
`compress=zstd:1,subvol=root` and `subvol=home`. Then recreate the swap, which
was deliberately not backed up. `/var/swap` was its own subvolume, so that it
stays out of snapshots of `root`:

    btrfs subvolume create /mnt/top/root/var/swap
    btrfs filesystem mkswapfile --size 8g /mnt/top/root/var/swap/swapfile

## 5. put the custom kernel back

The root tar restored `/usr/lib/modules/7.1.13-fairydust+` and its siblings,
but the kernel image, initramfs and dtbs live on the ext4 `/boot` partition,
which the fresh install rewrote. Pull them out of the old image rather than
dd'ing the whole thing back:

    zstd -d nvme0n1p5.img.zst -o p5.img
    mkdir -p /mnt/oldboot && mount -o ro,loop p5.img /mnt/oldboot
    cp -a /mnt/oldboot/vmlinuz-7.1.13-fairydust+        /boot/
    cp -a /mnt/oldboot/initramfs-7.1.13-fairydust+.img  /boot/
    cp -a /mnt/oldboot/dtbs/7.1.13-fairydust+           /boot/dtbs/

Then regenerate the boot entries using the *new* install's grub:

    grub2-mkconfig -o /boot/grub2/grub.cfg

Keep the stock `kernel-core` entry in the list. It is the way back in if the
fairydust kernel does not come up on the replacement machine.

To rebuild from source instead, `meta/fairydust-kernel.config` is the exact
config that produced the running kernel, and it is the only copy anywhere:
`/boot` never had a `config-7.1.13-fairydust+` and `CONFIG_IKCONFIG_PROC` is
off, so there is no `/proc/config.gz` to fall back on.

    make olddefconfig          # after copying meta/fairydust-kernel.config to .config

## 6. relabel, then reinstall packages if anything is off

    touch /.autorelabel && reboot      # safety net if any label looks wrong

The root tar already carried `/var/lib/rpm`, so packages are restored as real
installed files and the rpmdb agrees with them. The lists below are a
cross-check, not the restore path. Use them only if something is actually
missing:

    rpm -Va --nofiledigest | head -50
    dnf install $(cat meta/dnf-userinstalled.txt)
    # flatpaks: see meta/flatpak-remotes.txt then meta/flatpak-all.txt
    # enabled units: meta/systemd-enabled.txt

## 7. the kernel tree

    mkdir linux-fairydust && cd linux-fairydust
    cat ../fairydust-git.tar.zst.* | zstd -dc | tar -p --same-owner -xf -
    git checkout .                     # restore the worktree from .git
    git apply ../meta/fairydust-uncommitted.patch   # if non-empty
    tar -xf ../fairydust-untracked.tar.zst          # if present
    cp ../meta/fairydust-kernel.config .config

## note on p4 and p5

The ESP and `/boot` images are from the *old* install. A fresh Asahi install
writes its own working versions of both. Do not blindly dd these back, you will
usually break the new boot chain. Treat them as a read-only source to copy
individual files out of, as in section 5.
MD

printf '%s\n' "$NAME" > "$STAGE/BACKUP-NAME.txt"
date -Is                > "$STAGE/BACKUP-DATE.txt"

#------------------------------------------------- images, metadata and the sums
# the big tars are already uploaded and gone from staging by this point. what is
# left is small: partition images, meta/, the docs and the single-file archives.
echo ">>> verifying images and single-file archives"
shopt -s nullglob
for f in "$STAGE"/*.img.zst "$STAGE"/*.tar.zst; do
  printf '    %-24s ' "$(basename "$f")"
  if zstd -t -q "$f" 2>/dev/null; then echo OK; else echo FAILED; FAIL=1; fi
done
shopt -u nullglob

if (( FAIL )); then
  echo "!! local verification failed, refusing to finish"
  exit 1
fi

# per-label sums were recorded before each archive was deleted, so SHA256SUMS
# still covers the whole backup even though most of it is no longer on disk
echo ">>> assembling SHA256SUMS"
( cd "$STAGE" && find . -maxdepth 2 -type f \
    ! -name SHA256SUMS ! -name backup.log ! -path './.state/*' -print0 \
  | sort -z | xargs -0 sha256sum ) > "$STAGE/SHA256SUMS"
cat "$STATE"/sums-* >> "$STAGE/SHA256SUMS" 2>/dev/null || true
# -u because in test mode the parts are kept, so find and sums-* both see them
sort -u -k2 -o "$STAGE/SHA256SUMS" "$STAGE/SHA256SUMS"
echo "    $(wc -l < "$STAGE/SHA256SUMS") files covered"

# the log is excluded because it keeps growing while we work, which would make
# rclone check report a spurious mismatch. it is uploaded last, on its own.
RC_EXCL=( --exclude '/.state/**' --exclude '/backup.log' )

echo ">>> uploading metadata, images and docs"
chown -R "$OWNER:$OWNER" "$STAGE"
rc rclone copy "$STAGE" "$DEST" "${RC_EXCL[@]}" \
  --onedrive-chunk-size 100M \
  --transfers 8 \
  --retries 10 --retries-sleep 20s --low-level-retries 20 \
  --stats 30s --stats-one-line

# crypt cannot pass onedrive's QuickXorHash through to the plaintext layer, so a
# plain `rclone check` degrades to a size compare without saying so. each big
# archive already had a part downloaded and hashed at upload time; this covers
# the small files that are still on disk.
echo ">>> final presence and size check on what is still staged"
if rc rclone check "$STAGE" "$DEST" "${RC_EXCL[@]}" --one-way --size-only; then
  echo "    presence and size OK"
else
  echo "!! remote size verification FAILED"; FAIL=1
fi

if (( VERIFY_FULL )); then
  echo ">>> full content verification of the small files"
  if rc rclone check "$STAGE" "$DEST" "${RC_EXCL[@]}" --one-way --download; then
    echo "    full content verification OK"
  else
    echo "!! full content verification FAILED"; FAIL=1
  fi
else
  echo ">>> spot-checking the small files"
  mapfile -t SAMPLE < <(cd "$STAGE" && find . -maxdepth 2 -type f \
      ! -name SHA256SUMS ! -name backup.log ! -path './.state/*' -printf '%P\n' \
    | shuf -n 3)
  for f in "${SAMPLE[@]}"; do
    want=$(awk -v f="./$f" '$2==f{print $1}' "$STAGE/SHA256SUMS")
    got=$(rc rclone cat "$DEST/$f" 2>/dev/null | sha256sum | cut -d' ' -f1)
    if [[ -n "$want" && "$want" == "$got" ]]; then
      echo "    $f OK"
    else
      echo "!! $f MISMATCH (local ${want:-?}, remote ${got:-?})"; FAIL=1
    fi
  done
fi

rc rclone copy "$STAGE/backup.log" "$DEST" >/dev/null 2>&1 || true

#--------------------------------------------------------------------- selinux round trip
if (( TEST )); then
  echo ">>> selinux xattr round trip"
  TD=$(mktemp -d /var/tmp/asahi-selinux-check.XXXXXX)
  cat "$STAGE"/root.tar.zst.* | zstd -dc -q \
    | tar -C "$TD" --numeric-owner --xattrs --xattrs-include='*' --selinux --acls \
          -p --same-owner -xf - ./etc/fstab ./etc/shadow 2>/dev/null || true
  orig=$(getfattr -n security.selinux --only-values /etc/fstab 2>/dev/null | tr -d '\0' || true)
  rest=$(getfattr -n security.selinux --only-values "$TD/etc/fstab" 2>/dev/null | tr -d '\0' || true)
  echo "    original: ${orig:-<none>}"
  echo "    restored: ${rest:-<none>}"
  if [[ -n "$rest" && "$orig" == "$rest" ]]; then
    echo "    SELINUX ROUND TRIP: OK"
  else
    echo "    SELINUX ROUND TRIP: FAILED"; FAIL=1
  fi
  rm -rf "$TD"

  echo ">>> purging test folder from onedrive"
  rc rclone purge "$REMOTE_BASE" >/dev/null 2>&1 || true
  rm -rf "$STAGE"
fi

#--------------------------------------------------------------------- done
echo "=============================================================="
if (( FAIL )); then
  echo " RESULT: FAILED. see above. staging kept at $STAGE"
  exit 1
fi

if (( TEST )); then
  echo " RESULT: self test PASSED. pipeline is sound."
  echo " now run:  sudo tmux new -s bk $0"
else
  echo " RESULT: OK"
  echo " uploaded: $DEST"
  echo " size:     $(rc rclone size "$DEST" 2>/dev/null | tail -1)"
  echo " restore:  see RESTORE.md inside the backup"
  echo
  echo " the big archives were deleted from staging as they uploaded."
  echo " what is left is metadata and partition images: $(du -sh "$STAGE" 2>/dev/null | cut -f1)"
  echo "   sudo rm -rf $STAGE    # to clear the rest"
  if (( PURGE_STAGE )); then
    echo " --purge-stage given, removing staging now"
    rm -rf "$STAGE"
  fi
fi
echo " finished $(date -Is)"
echo "=============================================================="
