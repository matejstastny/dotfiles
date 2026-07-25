#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "✦ ✧ ✦  VSCodium devcontainer setup"
echo ""

# ── devcontainer CLI ──────────────────────────────────────
echo "✦ Installing @devcontainers/cli..."
pnpm add -g @devcontainers/cli

# ── Remote Containers extension (VSIX from MS marketplace) ──
echo ""
echo "✦ Downloading ms-vscode-remote.remote-containers..."

VERSION=$(curl -fsSL \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json;api-version=3.0-preview.1" \
    --data '{"filters":[{"criteria":[{"filterType":7,"value":"ms-vscode-remote.remote-containers"}]}],"flags":512}' \
    "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" | \
    python3 -c "import sys,json; print(json.load(sys.stdin)['results'][0]['extensions'][0]['versions'][0]['version'])")
echo "  version: $VERSION"

VSIX_GZ=$(mktemp --suffix=.vsix.gz)
VSIX=$(mktemp --suffix=.vsix)
curl -fsSL \
    "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/ms-vscode-remote/vsextensions/remote-containers/${VERSION}/vspackage" \
    -o "$VSIX_GZ"
python3 -c "
import gzip, shutil
with gzip.open('$VSIX_GZ', 'rb') as f_in, open('$VSIX', 'wb') as f_out:
    shutil.copyfileobj(f_in, f_out)
"
codium --install-extension "$VSIX"
rm -f "$VSIX_GZ" "$VSIX"

# ── Patch: bypass Microsoft-only license check ─────────────
echo ""
echo "✦ Patching extension to run in VSCodium..."
EXT_JS=$(echo ~/.vscode-oss/extensions/ms-vscode-remote.remote-containers-*/dist/extension/extension.js)
python3 - "$EXT_JS" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
import sys, re

path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()

changed = False

# Patch 1: bypass Microsoft-only license guard
old1 = '!pz.DevContainersOnlyLicensedForMicrosoftVSCode()'
if old1 in content:
    content = content.replace(old1, '!true', 1)
    changed = True
    print("  patched: license guard")
else:
    print("  skip: license guard (already patched or changed)")

# Patch 2: use product.serverDownloadUrlTemplate for server download URL
old2 = 'let m=`${c}/commit:${r}/server-${s?n.id.replace("linux-","linux-legacy-"):n.id}${i?"-web":""}/${o}`'
new2 = (
    'let m=(()=>{'
    'let tpl=e.product&&e.product.serverDownloadUrlTemplate;'
    'if(tpl){'
    'let[_o,..._ar]=(n.id||"linux-arm64").split("-");'
    'let _a=_ar.join("-");'
    'return tpl.replace("${os}",_o).replace("${arch}",_a);'
    '}'
    'return`${c}/commit:${r}/server-${s?n.id.replace("linux-","linux-legacy-"):n.id}${i?"-web":""}/${o}`;'
    '})()'
)
if old2 in content:
    content = content.replace(old2, new2, 1)
    changed = True
    print("  patched: server download URL")
else:
    print("  skip: server download URL (already patched or changed)")

if changed:
    with open(path, 'w') as f:
        f.write(content)
PYEOF

# ── Patch product.json: allow proposed APIs for the extension ──
echo ""
echo "✦ Patching VSCodium product.json (requires fix-codium to have been run)..."
PRODUCT_JSON="/usr/share/codium/resources/app/product.json"
python3 - "$PRODUCT_JSON" << 'PYEOF'
import sys, json

path = sys.argv[1]
ext_id = "ms-vscode-remote.remote-containers"

try:
    with open(path, "r") as f:
        product = json.load(f)
except PermissionError:
    print(f"  error: cannot read {path} — run bin/fix-codium first")
    sys.exit(1)

allowed = product.get("extensionAllowedProposedApi", [])
if ext_id in allowed:
    print("  skip: extensionAllowedProposedApi (already set)")
    sys.exit(0)

allowed.append(ext_id)
product["extensionAllowedProposedApi"] = allowed

try:
    with open(path, "w") as f:
        json.dump(product, f, indent="\t")
    print("  patched: extensionAllowedProposedApi")
except PermissionError:
    print(f"  error: cannot write {path} — run bin/fix-codium first")
    sys.exit(1)
PYEOF

echo ""
echo "✦ ✧ ✦  Done!"
echo ""
echo "Next steps:"
echo "  1. Run bin/fix-codium if you haven't (gives write access to /usr/share/codium)"
echo "  2. Restart VSCodium to activate the extension"
echo "  3. Use rofi ✦ code ✦ — projects with .devcontainer/ are marked [dc]"
echo "  4. Alt+D in rofi to open directly in devcontainer (via kitty + devcon)"
echo ""
