#!/bin/bash

LABEL=$(python3 - << 'EOF'
import ctypes, os

PROCESSOR_CPU_LOAD_INFO = 2
CPU_STATE_MAX = 4
CPU_STATE_IDLE = 2

lib = ctypes.CDLL('/usr/lib/libSystem.dylib')

mach_host_self = lib.mach_host_self
mach_host_self.restype = ctypes.c_uint
mach_host_self.argtypes = []
host = mach_host_self()

ncpu_arr = ctypes.c_uint()
info_ptr = ctypes.c_void_p()
info_cnt = ctypes.c_uint()

ret = lib.host_processor_info(
    host, PROCESSOR_CPU_LOAD_INFO,
    ctypes.byref(ncpu_arr), ctypes.byref(info_ptr), ctypes.byref(info_cnt)
)

if ret != 0:
    print('?')
    exit()

ncpu = ncpu_arr.value
ticks = ctypes.cast(info_ptr, ctypes.POINTER(ctypes.c_uint32))

curr = []
for i in range(ncpu):
    base = i * CPU_STATE_MAX
    curr.extend([ticks[base + j] for j in range(CPU_STATE_MAX)])

state_file = f'/tmp/sketchybar_cpu_{ncpu}'
blocks = '▁▁▂▃▄▅▆▇█'

try:
    with open(state_file) as f:
        prev = list(map(int, f.read().split()))
    result = ''
    for i in range(ncpu):
        base = i * CPU_STATE_MAX
        dc = [curr[base + j] - prev[base + j] for j in range(CPU_STATE_MAX)]
        total = sum(dc)
        idle = dc[CPU_STATE_IDLE]
        usage = (total - idle) / total * 100 if total > 0 else 0.0
        usage = max(0.0, min(100.0, usage))
        idx = min(int(usage / 100 * 8 + 0.5), 8)
        result += blocks[idx]
    print(result)
except FileNotFoundError:
    print('▁' * ncpu)

with open(state_file, 'w') as f:
    f.write(' '.join(map(str, curr)))
EOF
)

sketchybar --set "$NAME" label="$LABEL"
