"""Utilities to register a hotkey in Sway/Wayland compositors using swaymsg.

This attempts to use `swaymsg` to bind a key to a command. Works on Sway/Hyprland (swaymsg compatible).
"""
import shutil
import subprocess
import logging

logger = logging.getLogger("uclip.wayland_hotkey")


def register_sway_hotkey(binding: str, command: str) -> bool:
    """Register a hotkey in sway by issuing `bindsym <binding> <command>` via swaymsg.

    Returns True if the command was sent successfully.
    """
    swaymsg = shutil.which("swaymsg")
    if not swaymsg:
        logger.debug("swaymsg not found")
        return False
    try:
        # Use -- to avoid shell interpretation
        subprocess.check_call([swaymsg, f"bindsym {binding} {command}"])
        logger.info("Registered sway hotkey %s -> %s", binding, command)
        return True
    except Exception as e:
        logger.exception("Failed to register sway hotkey: %s", e)
        return False
