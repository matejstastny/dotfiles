#!/usr/bin/env bash
#
# pre-service backup of a fedora asahi remix install to onedrive.
#
#   real run:   sudo tmux new -s bk ~/dotfiles/asahi-backup.sh
#   self test:  sudo ~/dotfiles/asahi-backup.sh --test
#
# asks nothing once started. root is required at launch because it snapshots
# btrfs subvolumes, mounts subvolid=5 and images partitions.
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
STAGE=/var/tmp/asahi-backup
SPLIT_SIZE=2G
REMOTE_BASE="onedrive:backups"
MIN_FREE_GIB=110
RCLONE_CONF="/home/$OWNER/.config/rclone/rclone.conf"
ZSTD_LEVEL=3

TEST=0
PURGE_STAGE=0
for a in "${@:-}"; do
  case "$a" in
    ""|--) ;;
    --test)        TEST=1 ;;
    --purge-stage) PURGE_STAGE=1 ;;
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
  REMOTE_BASE="onedrive:_asahi_backup_test"
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

echo "    checking onedrive auth and quota"
rc rclone about onedrive: || { echo "!! rclone cannot reach onedrive"; exit 1; }

#--------------------------------------------------------------------- archive
if [[ -f "$STATE/archives-complete" ]]; then
  echo ">>> archives already staged, skipping straight to upload"
else
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
           | grep -vxE 'root|home' | grep -v '^\.bk-' || true)
  if [[ -n "$NESTED" ]]; then
    echo "!! WARNING: nested subvolumes are NOT captured by these snapshots:"
    printf '%s\n' "$NESTED" | sed 's/^/     /'
    printf '%s\n' "$NESTED" > "$M/NESTED-SUBVOLS-NOT-BACKED-UP.txt"
  fi

  ROOT_EXCL=(
    ./proc ./sys ./dev ./run ./tmp ./home ./lost+found
    ./var/cache ./var/tmp ./var/log ./var/swap
    ./var/lib/systemd/coredump
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
    make_tar root "$TOP/.bk-root" ./etc
  else
    make_tar root "$TOP/.bk-root" . "${ROOT_EXCL[@]}"
    make_tar home "$TOP/.bk-home" . "${HOME_EXCL[@]}"
    if [[ -d "$TOP/.bk-home/$OWNER/linux-fairydust/.git" ]]; then
      make_tar fairydust-git "$TOP/.bk-home/$OWNER/linux-fairydust" .git
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
| `fairydust-untracked.tar.zst` | untracked non-ignored files from the kernel tree |
| `nvme0n1p1.img.zst`       | iBootSystemContainer, reference only, not restorable |
| `nvme0n1p3.img.zst`       | Asahi APFS stub, reference only, not restorable |
| `nvme0n1p4.img.zst`       | the EFI system partition (m1n1 + u-boot + grub) |
| `nvme0n1p5.img.zst`       | `/boot` (kernels + initramfs) |
| `meta/`                   | partition table, package lists, UUIDs, unit state |
| `SHA256SUMS`              | checksums for everything above |

Excluded on purpose, all regenerable: `~/.cache`, the 8G swapfile,
`node_modules`, `target/{debug,release}`, pnpm/npm/cargo/rustup/gradle caches,
`factorio`, Steam `steamapps`, `/var/{cache,tmp,log}`, and the kernel build
output. PrismLauncher and `/usr` are included in full.

## 1. pull it back down

    rclone copy onedrive:backups/<NAME> ./restore --transfers 4 --onedrive-chunk-size 100M
    cd restore && sha256sum -c SHA256SUMS

## 2. reinstall asahi

Boot macOS, run the Asahi installer, and give the Linux partition **at least as
much space as before** (it was 363.5 GiB). Let it complete and boot into the
fresh Fedora Asahi install. Check `meta/os-release` for the release to match.

## 3. unpack over the fresh install

From a live USB or a root shell, with the new install's subvolumes mounted.
Mount the btrfs top level and unpack into the subvolumes directly:

    mkdir -p /mnt/top
    mount -o subvolid=5 /dev/nvme0n1p6 /mnt/top    # confirm the device first

    cat root.tar.zst.* | zstd -dc | \
      tar -C /mnt/top/root --numeric-owner --xattrs --xattrs-include='*' \
          --selinux --acls -p --same-owner --overwrite -xf -

    cat home.tar.zst.* | zstd -dc | \
      tar -C /mnt/top/home --numeric-owner --xattrs --xattrs-include='*' \
          --selinux --acls -p --same-owner --overwrite -xf -

The `--xattrs-include='*' --selinux` flags are **mandatory**. This system runs
SELinux in Enforcing mode; drop those flags and every file loses its security
label, which leaves a system you cannot log into.

`-p --same-owner` is equally mandatory. Without `-p`, GNU tar strips setuid and
setgid bits on extract, which silently breaks all 27 setuid binaries in `/usr`,
`sudo` and `passwd` among them. Verify afterwards against
`meta/setuid-setgid-files.txt` and `meta/file-capabilities.txt`:

    find /usr -xdev -type f \( -perm -4000 -o -perm -2000 \) | sort

## 4. fix up fstab and boot

New partitions get new UUIDs. The restored `/etc/fstab` carries the *old* ones,
so it must be rewritten:

    blkid                        # read the new UUIDs
    cat meta/fstab               # the old file, for the structure and options

Keep the mount options exactly as they were, in particular
`compress=zstd:1,subvol=root` and `subvol=home`. Then regenerate the swapfile,
which was deliberately not backed up:

    btrfs filesystem mkswapfile --size 8g /var/swap/swapfile

## 5. relabel, then reinstall packages if anything is off

    touch /.autorelabel && reboot      # safety net if any label looks wrong

    dnf install $(cat meta/dnf-userinstalled.txt)
    # flatpaks: see meta/flatpak-remotes.txt then meta/flatpak-all.txt
    # enabled units: meta/systemd-enabled.txt

## 6. the kernel tree

    mkdir linux-fairydust && cd linux-fairydust
    cat ../fairydust-git.tar.zst.* | zstd -dc | tar -p --same-owner -xf -
    git checkout .                     # restore the worktree from .git
    git apply ../meta/fairydust-uncommitted.patch   # if non-empty
    tar -xf ../fairydust-untracked.tar.zst          # if present

## note on p4 and p5

The ESP and `/boot` images are from the *old* install. A fresh Asahi install
writes its own working versions of both. Do not blindly dd these back, you will
usually break the new boot chain. Treat them as a reference for recovering a
specific kernel, initramfs or grub config.
MD

  printf '%s\n' "$NAME" > "$STAGE/BACKUP-NAME.txt"
  date -Is                > "$STAGE/BACKUP-DATE.txt"

  echo ">>> checksumming"
  ( cd "$STAGE" && find . -maxdepth 2 -type f \
      ! -name SHA256SUMS ! -name backup.log ! -path './.state/*' -print0 \
    | sort -z | xargs -0 sha256sum > SHA256SUMS )

  touch "$STATE/archives-complete"
  echo ">>> archive stage complete: $(du -sh "$STAGE" | cut -f1)"
fi

#--------------------------------------------------------------------- verify local
echo ">>> verifying local archives read back cleanly"
shopt -s nullglob
for label in root home fairydust-git; do
  parts=( "$STAGE/$label".tar.zst.* )
  (( ${#parts[@]} )) || continue
  printf '    %-14s ' "$label"
  if cat "${parts[@]}" | zstd -dc -q | tar -tf - >/dev/null 2>&1; then
    echo OK
  else
    echo FAILED; FAIL=1
  fi
done
for f in "$STAGE"/*.img.zst "$STAGE"/*.tar.zst; do
  printf '    %-14s ' "$(basename "$f")"
  if zstd -t -q "$f" 2>/dev/null; then echo OK; else echo FAILED; FAIL=1; fi
done
shopt -u nullglob

if (( FAIL )); then
  echo "!! local verification failed, refusing to upload a bad archive"
  exit 1
fi

#--------------------------------------------------------------------- upload
# the log is excluded because it keeps growing while we work, which would make
# rclone check report a spurious mismatch. it is uploaded last, on its own.
RC_EXCL=( --exclude '/.state/**' --exclude '/backup.log' )

echo ">>> uploading to $DEST"
chown -R "$OWNER:$OWNER" "$STAGE"
rc rclone copy "$STAGE" "$DEST" "${RC_EXCL[@]}" \
  --onedrive-chunk-size 100M \
  --transfers 8 \
  --retries 10 --retries-sleep 20s --low-level-retries 20 \
  --stats 30s --stats-one-line

echo ">>> verifying remote against local (hash compare)"
if rc rclone check "$STAGE" "$DEST" "${RC_EXCL[@]}" --one-way; then
  echo "    remote verification OK"
else
  echo "!! remote verification FAILED"; FAIL=1
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
  echo " size:     $(du -sh "$STAGE" | cut -f1)"
  echo " restore:  see RESTORE.md inside the backup"
  echo
  echo " staging is still on disk. reclaim the space with:"
  echo "   sudo rm -rf $STAGE"
  if (( PURGE_STAGE )); then
    echo " --purge-stage given, removing staging now"
    rm -rf "$STAGE"
  fi
fi
echo " finished $(date -Is)"
echo "=============================================================="
