"""CLI to register a hotkey on Wayland (sway) or fallback to GNOME.

Usage:
  python backend/cli/register_wayland_hotkey.py --command "xdg-open http://127.0.0.1:5173"
"""
import argparse
import logging
import shutil

from backend.services.wayland_hotkey import register_sway_hotkey
from backend.services.system_hotkey import register_gnome_hotkey

logger = logging.getLogger("uclip.register_wayland_hotkey")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--command", default=None)
    parser.add_argument("--binding", default='<Super>v')
    args = parser.parse_args()

    cmd = args.command
    if not cmd:
        cmd = "xdg-open http://127.0.0.1:5173"

    # sway/hyprland binding format uses e.g. Mod4+v or Super+v depending on compositor
    sway_binding = args.binding.replace('<Super>', 'Mod4')
    ok = register_sway_hotkey(sway_binding, cmd)
    if ok:
        print('Registered sway hotkey')
        return

    # fallback to GNOME
    register_gnome_hotkey('UClip Toggle', cmd, args.binding)
    print('Registered GNOME hotkey')


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    main()
