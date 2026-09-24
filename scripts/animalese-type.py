#!/usr/bin/env python3
#@ animal crossing style blip sound on every keystroke, system-wide

import asyncio
import random
import subprocess
from pathlib import Path

from evdev import InputDevice, list_devices, ecodes

SOUND_DIR = Path.home() / "dotfiles/assets/sounds/animalese"
BLIPS = sorted(SOUND_DIR.glob("blip*.wav"))

SKIP_KEYS = {
    ecodes.KEY_LEFTSHIFT, ecodes.KEY_RIGHTSHIFT,
    ecodes.KEY_LEFTCTRL, ecodes.KEY_RIGHTCTRL,
    ecodes.KEY_LEFTALT, ecodes.KEY_RIGHTALT,
    ecodes.KEY_LEFTMETA, ecodes.KEY_RIGHTMETA,
    ecodes.KEY_CAPSLOCK,
}


def find_keyboards():
    keyboards = []
    for path in list_devices():
        dev = InputDevice(path)
        caps = dev.capabilities().get(ecodes.EV_KEY, [])
        if ecodes.KEY_A in caps:
            keyboards.append(dev)
    return keyboards


def play_blip():
    blip = random.choice(BLIPS)
    subprocess.Popen(
        ["paplay", str(blip)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


async def watch(device):
    async for event in device.async_read_loop():
        if event.type == ecodes.EV_KEY and event.value == 1 and event.code not in SKIP_KEYS:
            play_blip()


async def main():
    keyboards = find_keyboards()
    if not keyboards:
        subprocess.run([
            "notify-send", "-t", "5000",
            "✦ animalese-type",
            "no keyboard devices found",
        ])
        return
    await asyncio.gather(*(watch(kb) for kb in keyboards))


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except PermissionError:
        subprocess.run([
            "notify-send", "-t", "5000",
            "✦ animalese-type",
            "permission denied reading /dev/input, is elara in the input group?",
        ])
