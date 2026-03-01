#!/bin/bash

LABEL=$(python3 - << 'EOF'
import subprocess

total_bytes = int(subprocess.run(
    ['sysctl', '-n', 'hw.memsize'], capture_output=True, text=True
).stdout.strip())

vm = subprocess.run(['vm_stat'], capture_output=True, text=True).stdout

# Parse page size from header (e.g. "page size of 16384 bytes")
page_size = 4096
for line in vm.splitlines():
    if 'page size of' in line:
        page_size = int(line.split('page size of')[1].split()[0])
        break

pages = {}
for line in vm.splitlines():
    if 'Pages active:' in line:
        pages['active'] = int(line.split()[-1].rstrip('.'))
    elif 'Pages wired down:' in line:
        pages['wired'] = int(line.split()[-1].rstrip('.'))
    elif 'Pages occupied by compressor:' in line:
        pages['compressed'] = int(line.split()[-1].rstrip('.'))

used_gb = sum(pages.values()) * page_size / 1024**3
total_gb = total_bytes / 1024**3
print(f'{used_gb:.1f}/{total_gb:.0f}G')
EOF
)

sketchybar --set "$NAME" label="$LABEL"
