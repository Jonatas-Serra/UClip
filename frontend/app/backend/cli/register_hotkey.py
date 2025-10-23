"""CLI to register the Super+V hotkey in GNOME.

Usage:
  python backend/cli/register_hotkey.py --command "/usr/bin/electron /path/to/app"
"""
import argparse
import logging
import shutil
from backend.services.system_hotkey import register_gnome_hotkey

logger = logging.getLogger("uclip.register_hotkey")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--command", help="Command to run when hotkey is pressed", default=None)
    parser.add_argument("--binding", help="Keybinding (gsettings) format", default='<Super>v')
    args = parser.parse_args()

    cmd = args.command
    if not cmd:
        # try to find electron binary
        electron = shutil.which('electron') or shutil.which('electronjs')
        if electron:
            cmd = f"{electron} {shutil.abspath('electron/main.js')}"
        else:
            # fallback: open the frontend URL
            cmd = "xdg-open http://127.0.0.1:5173"

    register_gnome_hotkey('UClip Toggle', cmd, args.binding)
    print('Hotkey registered')


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
