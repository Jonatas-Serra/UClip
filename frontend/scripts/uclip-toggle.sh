#!/usr/bin/env bash
# Toggle/focus UClip window (X11). If no window found, start the app.
set -euo pipefail

APP_PATH="/home/jonatasserra/Projetos/UClip/frontend/dist/linux-unpacked/uclip-frontend"

command -v xdotool >/dev/null 2>&1 || { echo "xdotool not found, please install: sudo apt install xdotool wmctrl" >&2; }
command -v wmctrl >/dev/null 2>&1 || { echo "wmctrl not found, please install: sudo apt install wmctrl xdotool" >&2; }

# Find existing uclip process
PID=$(pgrep -f "$APP_PATH" | head -n1 || true)

if [[ -n "$PID" ]]; then
  # Try to find a window for that PID
  WINID=$(wmctrl -lp | awk -v pid="$PID" '$3==pid {print $1; exit}') || true
  if [[ -n "$WINID" ]]; then
    # If window exists, activate it
    xdotool windowactivate "$WINID" || wmctrl -ia "$WINID" || true
    exit 0
  fi
fi

# No running window found; start the app in background
nohup "$APP_PATH" > /tmp/uclip-frontend.log 2>&1 &
disown
echo "Started UClip (PID: $!)"
