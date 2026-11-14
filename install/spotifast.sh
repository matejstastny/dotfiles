#!/usr/bin/env bash
set -euo pipefail

REPOSITORY="crmne/spotifast"

case "$(uname -m)" in
	aarch64 | arm64) RPM_ARCH="aarch64" ;;
	x86_64 | amd64) RPM_ARCH="x86_64" ;;
	*)
		echo "Spotifast does not publish an RPM for $(uname -m)."
		exit 1
		;;
esac

command -v curl >/dev/null || {
	echo "curl is required to install Spotifast."
	exit 1
}
command -v python3 >/dev/null || {
	echo "python3 is required to read the Spotifast release metadata."
	exit 1
}

echo "==> Fetching the latest Spotifast release..."
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPOSITORY/releases/latest")
read -r TAG RPM_NAME RPM_URL < <(
	python3 -c '
import json
import sys

release = json.load(sys.stdin)
arch = sys.argv[1]
rpm = next(
    (asset for asset in release["assets"] if asset["name"].endswith(f".{arch}.rpm")),
    None,
)
if rpm is None:
    raise SystemExit("No {} RPM is available in {}.".format(arch, release["tag_name"]))
print(release["tag_name"], rpm["name"], rpm["browser_download_url"])
' "$RPM_ARCH" <<<"$RELEASE_JSON"
)

INSTALLED_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' spotifast 2>/dev/null || true)
LATEST_VERSION=${RPM_NAME#spotifast-}
LATEST_VERSION=${LATEST_VERSION%.$RPM_ARCH.rpm}
if [ "$INSTALLED_VERSION" = "$LATEST_VERSION.$RPM_ARCH" ]; then
	echo "==> Spotifast $TAG is already installed."
	exit 0
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Downloading Spotifast $TAG ($RPM_ARCH)..."
curl -fL --retry 3 --retry-delay 2 "$RPM_URL" -o "$TMP_DIR/$RPM_NAME"

echo "==> Verifying download..."
curl -fsSL "https://github.com/$REPOSITORY/releases/download/$TAG/packaging-checksums.txt" \
	-o "$TMP_DIR/packaging-checksums.txt"
(cd "$TMP_DIR" && grep -F "  $RPM_NAME" packaging-checksums.txt | sha256sum -c -)

echo "==> Installing Spotifast $TAG..."
sudo dnf install -y "$TMP_DIR/$RPM_NAME"

echo "==> Spotifast $TAG installed. Launch it with: spotifast"
