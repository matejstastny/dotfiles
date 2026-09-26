#!/home/elara/.local/share/pipx/venvs/pyatv/bin/python3

import sys
import asyncio
import pyatv


async def print_what_is_playing(loop):
    """Find a device and print what is playing."""
    print("Discovering devices on network...")
    atvs = await pyatv.scan(loop)

    if not atvs:
        print("No device found", file=sys.stderr)
        return

    config = atvs[0]

    print(f"Connecting to {config.address}")
    atv = await pyatv.connect(config, loop)

    try:
        print(await atv.metadata.playing())
    finally:
        atv.close()  # Do not forget to close


if __name__ == "__main__":
    event_loop = asyncio.get_event_loop()
    event_loop.run_until_complete(print_what_is_playing(event_loop))
