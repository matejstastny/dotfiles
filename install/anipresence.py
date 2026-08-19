#!/usr/bin/env python3
#@

import json
import os
import re
import socket
import subprocess
import sys
import time
from typing import Optional, Tuple

import requests
from pypresence import ActivityType, Presence, StatusDisplayType

CLIENT_ID    = os.environ.get("DRPC_CLIENT_ID", "1516318819965075476")
MPV_SOCKET   = os.environ.get("MPV_IPC_SOCKET", "/tmp/mpvsocket")
POLL_INTERVAL = 1

ANILIST_API   = "https://graphql.anilist.co"
ANILIST_QUERY = """
query ($search: String) {
  Media(search: $search, type: ANIME) {
    title { romaji english }
    episodes
    coverImage { large }
  }
}
"""

SERVICE_UNIT = """\
[Unit]
Description=ani-cli Discord Rich Presence
After=network.target

[Service]
ExecStart={script}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
"""

_anilist_cache: dict = {}


def get_ani_cli_episode() -> Tuple[Optional[str], Optional[int]]:
    try:
        ps = subprocess.run(["ps", "aux"], capture_output=True, text=True)
    except Exception:
        return None, None

    for line in ps.stdout.splitlines():
        if "force-media-title" not in line:
            continue
        if "mpv" not in line and "iina" not in line.lower():
            continue

        title_match = re.search(
            r"--(?:mpv-)?force-media-title=(.+?)(?=\s+https?://|\s+--\w|\s*$)",
            line,
        )
        if not title_match:
            continue

        media_title = title_match.group(1).strip().strip("'\"")
        ep_match = re.match(
            r"^(?P<title>.+?)\s+Episode\s+(?P<ep>\d+)\s*$",
            media_title,
            re.IGNORECASE,
        )
        if ep_match:
            return ep_match.group("title").strip(), int(ep_match.group("ep"))

    return None, None


def get_playback_info() -> Tuple[Optional[int], Optional[int], bool]:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(1)
            sock.connect(MPV_SOCKET)
            commands = [
                {"command": ["get_property", "pause"],         "request_id": 1},
                {"command": ["get_property", "time-pos"],       "request_id": 2},
                {"command": ["get_property", "time-remaining"], "request_id": 3},
            ]
            sock.sendall(("\n".join(json.dumps(c) for c in commands) + "\n").encode())

            results: dict = {}
            buf = b""
            while len(results) < 3:
                try:
                    chunk = sock.recv(4096)
                except socket.timeout:
                    break
                if not chunk:
                    break
                buf += chunk
                *lines, buf = buf.split(b"\n")
                for line in lines:
                    if not line:
                        continue
                    try:
                        resp = json.loads(line)
                        if resp.get("error") == "success" and "request_id" in resp:
                            results[resp["request_id"]] = resp.get("data")
                    except json.JSONDecodeError:
                        pass

        is_paused    = results.get(1, False)
        time_pos      = results.get(2)
        time_remaining = results.get(3)

        if is_paused:
            return None, None, True
        if time_pos is None or time_remaining is None:
            return None, None, False

        now = time.time()
        return int(now - time_pos), int(now + time_remaining), False
    except (FileNotFoundError, ConnectionRefusedError, OSError):
        return None, None, False
    except Exception:
        return None, None, False


def fetch_anilist(title: str) -> Optional[dict]:
    if title in _anilist_cache:
        return _anilist_cache[title]
    try:
        resp = requests.post(
            ANILIST_API,
            json={"query": ANILIST_QUERY, "variables": {"search": title}},
            timeout=10,
        )
        resp.raise_for_status()
        media = resp.json()["data"]["Media"]
        _anilist_cache[title] = media
        return media
    except Exception:
        _anilist_cache[title] = None
        return None


def display_name(meta: dict, fallback: str) -> str:
    titles = meta.get("title", {})
    return titles.get("english") or titles.get("romaji") or fallback


def install():
    script = os.path.realpath(__file__)
    unit_dir = os.path.expanduser("~/.config/systemd/user")
    os.makedirs(unit_dir, exist_ok=True)
    unit_path = os.path.join(unit_dir, "anipresence.service")
    with open(unit_path, "w") as f:
        f.write(SERVICE_UNIT.format(script=script))
    print(f"Wrote {unit_path}")
    subprocess.run(["systemctl", "--user", "daemon-reload"], check=True)
    subprocess.run(["systemctl", "--user", "enable", "--now", "anipresence"], check=True)
    print("Service enabled and started.")


def run():
    rpc = Presence(CLIENT_ID)
    try:
        rpc.connect()
    except Exception as e:
        sys.exit(f"Could not connect to Discord: {e}\nMake sure Discord is running.")

    print("Connected to Discord. Watching for ani-cli…", flush=True)

    current_title: Optional[str] = None
    currently_paused: bool = False

    while True:
        raw_title, ep = get_ani_cli_episode()

        if raw_title and ep is not None:
            start, end, is_paused = get_playback_info()

            if is_paused:
                if not currently_paused:
                    currently_paused = True
                    print("Paused.", flush=True)
                    try:
                        rpc.clear()
                    except Exception:
                        pass
            else:
                if currently_paused:
                    currently_paused = False
                    print("Resumed.", flush=True)

                meta          = fetch_anilist(raw_title)
                title_display = display_name(meta, raw_title) if meta else raw_title
                cover         = meta["coverImage"]["large"] if meta else None
                total         = meta.get("episodes") if meta else None

                if raw_title != current_title:
                    current_title = raw_title
                    print(f"Watching: {title_display} - Episode {ep}", flush=True)

                state = f"Episode {ep}" + (f" / {total}" if total else "")

                update_kwargs = dict(
                    activity_type=ActivityType.WATCHING,
                    status_display_type=StatusDisplayType.DETAILS,
                    name=title_display,
                    details=title_display,
                    state=state,
                    large_text=title_display,
                )
                if cover:
                    update_kwargs["large_image"] = cover
                if start and end:
                    update_kwargs["start"] = start
                    update_kwargs["end"] = end

                try:
                    rpc.update(**update_kwargs)
                except Exception:
                    pass

        else:
            if current_title is not None:
                print("Stopped watching.", flush=True)
                current_title  = None
                currently_paused = False
                try:
                    rpc.clear()
                except Exception:
                    pass

        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "install":
        install()
    else:
        run()
