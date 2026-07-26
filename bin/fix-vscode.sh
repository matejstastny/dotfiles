#!/usr/bin/env bash
set -euo pipefail

sudo chown -R "$(whoami)" /usr/share/codium/resources

ROOT="$(dirname "$(realpath "$0")")/.."
CSS_SRC="$ROOT/configs/Code/custom.css"
VSCODE="/usr/share/code/resources/app"
CSS_TARGET="$VSCODE/out/vs/workbench/workbench.desktop.main.css"
JS_TARGET="$VSCODE/out/vs/workbench/workbench.desktop.main.js"
PRODUCT_JSON="$VSCODE/product.json"
CSS_MARKER="/* dotfiles:custom-css */"
JS_MARKER="/* dotfiles:font */"
FONT="Maple Mono NF"

# Selectors covering all text-bearing UI zones, excluding codicon icon elements
FONT_CSS=".monaco-workbench,.monaco-workbench input,.monaco-workbench select,.monaco-workbench textarea,.monaco-workbench .monaco-inputbox{font-family:\"$FONT\",monospace!important;}"

update_checksums() {
	python3 - "$CSS_TARGET" "$JS_TARGET" "$PRODUCT_JSON" <<'EOF'
import sys, hashlib, base64, json, subprocess
css_path, js_path, product_path = sys.argv[1], sys.argv[2], sys.argv[3]
def sha256b64(p): return base64.b64encode(hashlib.sha256(open(p,"rb").read()).digest()).decode()
product = json.loads(open(product_path).read())
product.setdefault("checksums", {}).update({
    "vs/workbench/workbench.desktop.main.css": sha256b64(css_path),
    "vs/workbench/workbench.desktop.main.js":  sha256b64(js_path),
})
subprocess.run(["sudo","tee",product_path], input=json.dumps(product,indent="\t").encode(), capture_output=True, check=True)
EOF
}

if [[ "${1:-}" == "--force" ]]; then
	echo "✦ Stripping CSS patch..."
	python3 - "$CSS_TARGET" "$CSS_MARKER" <<'EOF'
import sys, subprocess
path, marker = sys.argv[1], sys.argv[2]
content = open(path).read()
idx = content.find(marker)
if idx != -1:
    subprocess.run(["sudo","tee",path], input=(content[:idx].rstrip()+"\n").encode(), capture_output=True, check=True)
EOF

	echo "✦ Stripping JS font injection..."
	python3 - "$JS_TARGET" "$JS_MARKER" <<'EOF'
import sys, subprocess
path, marker = sys.argv[1], sys.argv[2]
content = open(path).read()
idx = content.find(marker)
if idx != -1:
    clean = content[:content.rfind('\n', 0, idx)].rstrip()
    sourcemap_idx = content.find('\n//# sourceMappingURL=')
    tail = content[sourcemap_idx:] if sourcemap_idx != -1 else ""
    subprocess.run(["sudo","tee",path], input=(clean + tail + "\n").encode(), capture_output=True, check=True)
    print("  stripped")
else:
    print("  nothing to strip")
EOF
fi

# CSS layout tweaks
if grep -qF "$CSS_MARKER" "$CSS_TARGET" 2>/dev/null; then
	echo "✦ CSS already patched"
else
	{
		printf '\n%s\n' "$CSS_MARKER"
		cat "$CSS_SRC"
	} | sudo tee -a "$CSS_TARGET" >/dev/null
	echo "✦ CSS patched"
fi

# JS font injection
if grep -qF "$JS_MARKER" "$JS_TARGET" 2>/dev/null; then
	echo "✦ JS font already injected"
else
	python3 - "$JS_TARGET" "$JS_MARKER" "$FONT_CSS" <<'EOF'
import sys, subprocess
path, marker, css = sys.argv[1], sys.argv[2], sys.argv[3]
content = open(path).read()
inject = f"\n{marker};(function(){{var s=document.createElement('style');s.textContent='{css}';document.head.appendChild(s);}}());\n"
sourcemap = '\n//# sourceMappingURL='
idx = content.find(sourcemap)
if idx == -1:
    new = content.rstrip() + inject
else:
    new = content[:idx] + inject + content[idx:]
subprocess.run(["sudo","tee",path], input=new.encode(), capture_output=True, check=True)
print("  injected")
EOF
	echo "✦ JS font injected"
fi

update_checksums

echo "✦ giving perms..."
sudo chown -R "$(whoami)" /usr/share/code

echo "✦ done — restart VSCode to apply"
