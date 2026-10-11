#!/usr/bin/env bash

TIME=$(date '+%I:%M')

LOCATION_FILE="$HOME/.config/waybar/location"
LOCATION=""
if [ -f "$LOCATION_FILE" ]; then
    LOCATION=$(head -1 "$LOCATION_FILE" | tr -d '\n')
fi

# Build URL: prefer explicit location; fall back to IP-based lookup if empty.
if [ -n "$LOCATION" ]; then
    URL="https://wttr.in/${LOCATION}?format=%c+%t+%h+%w"
else
    URL="https://wttr.in/?format=%c+%t+%h+%w"
fi

WEATHER=$(curl -s --max-time 5 "$URL" 2>/dev/null || echo "N/A")

# Parse wttr.in output: "condition temp humidity wind"
COND=$(printf '%s' "$WEATHER" | awk '{print $1}')
TEMP=$(printf '%s' "$WEATHER" | awk '{print $2}')
HUM=$(printf '%s' "$WEATHER" | awk '{print $3}')
WIND=$(printf '%s' "$WEATHER" | awk '{print $4}')

# JSON-escape special chars (newlines must become literal \n).
TOOLTIP=$(printf 'Location: %s\n%s %s\nHumidity: %s\nWind: %s' \
    "${LOCATION:-auto}" "$COND" "$TEMP" "$HUM" "$WIND" \
    | sed -z 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g')

printf '{"text": "󰥔 %s", "tooltip": "%s"}\n' "$TIME" "$TOOLTIP"