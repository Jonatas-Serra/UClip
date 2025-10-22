#!/usr/bin/env bash
# Register a keybinding in sway by appending to config or using swaymsg
# Usage: register_sway_shortcut.sh "<binding>" "<command>"
set -euo pipefail
BINDING="$1"
COMMAND="$2"

if command -v swaymsg >/dev/null 2>&1; then
  # Try to add temporary binding via swaymsg (won't persist across restarts)
  swaymsg "bindsym $BINDING exec $COMMAND" || {
    echo "Failed to register with swaymsg"
    exit 1
  }
  echo "Registered sway binding (temporary): $BINDING -> $COMMAND"
else
  echo "swaymsg not found. To persistently add binding, add the following line to your sway config:"
  echo "bindsym $BINDING exec $COMMAND"
fi
