#!/usr/bin/env bash
#@ subscribe to ntfy and mirror incoming pushes as desktop notifications

set -euo pipefail

TOPIC="${1:-general}"
TOKEN_FILE="$HOME/.config/ntfy-token"

curl -sfN \
	--config <(printf 'header = "Authorization: Bearer %s"\n' "$(cat "$TOKEN_FILE")") \
	"https://ntfy.elara.boo/$TOPIC/json" |
while IFS= read -r line; do
	[ "$(jq -r '.event' <<<"$line")" = "message" ] || continue

	title=$(jq -r --arg fallback "✦ $TOPIC" '.title // $fallback' <<<"$line")
	message=$(jq -r '.message' <<<"$line")

	notify-send "$title" "$message"
done
