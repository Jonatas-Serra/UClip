#!/usr/bin/env bash
# Register a custom keybinding in GNOME using gsettings
# Usage: register_gnome_shortcut.sh "<name>" "<binding>" "<command>"
set -euo pipefail
NAME="$1"
BINDING="$2"
COMMAND="$3"

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
KEYS_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"

# Read existing list
current=$(gsettings get ${SCHEMA} custom-keybindings || echo "[]")

# Determine new binding path
index=0
while true; do
  candidate="${KEYS_PATH}/custom$index/"
  if [[ "$current" != *"$candidate"* ]]; then
    break
  fi
  index=$((index+1))
done

new_entry="$candidate"

# Use Python to safely insert the new entry into the GSettings array literal
updated=$(python3 - <<PY
import ast,sys
cur = sys.argv[1]
try:
  arr = ast.literal_eval(cur)
except Exception:
  arr = []
if not isinstance(arr, list):
  arr = []
if "$new_entry" not in arr:
  arr.append("$new_entry")
print(repr(arr))
PY
"$current")

gsettings set ${SCHEMA} custom-keybindings "$updated"

base_key="${SCHEMA}.custom-keybinding:${candidate%/}"
gsettings set ${base_key} name "$NAME"
gsettings set ${base_key} binding "$BINDING"
gsettings set ${base_key} command "$COMMAND"

echo "Registered GNOME shortcut: $NAME -> $BINDING -> $COMMAND"
