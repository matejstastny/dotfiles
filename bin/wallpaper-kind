#!/usr/bin/env bash
#@ print "live" for video wallpapers, "still" for everything else

for path in "$@"; do
	case "${path,,}" in
	*.mp4 | *.webm | *.mkv | *.mov | *.m4v | *.avi) echo live ;;
	*) echo still ;;
	esac
done
