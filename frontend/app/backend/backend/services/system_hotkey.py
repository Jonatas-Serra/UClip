"""Utilities to register a global hotkey in GNOME via gsettings.

This creates a custom keybinding in the schema
`org.gnome.settings-daemon.plugins.media-keys` under `custom-keybindings`.

Note: This works on GNOME. On Wayland or restricted environments the gsettings approach
may still work because it's a GNOME setting, but the compositor may ignore it.
"""

import subprocess
import logging
from typing import List

logger = logging.getLogger("uclip.system_hotkey")


def _gsettings_get(schema: str, key: str) -> str:
    out = subprocess.check_output(["gsettings", "get", schema, key], text=True)
    return out.strip()


def _gsettings_set(schema: str, key: str, value: str):
    subprocess.check_call(["gsettings", "set", schema, key, value])


def list_custom_bindings() -> List[str]:
    raw = _gsettings_get("org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings")
    try:
        return eval(raw)
    except Exception:
        return []


def set_custom_bindings(bindings: List[str]):
    # bindings must be a Python-style list string
    _gsettings_set("org.gnome.settings-daemon.plugins.media-keys", "custom-keybindings", str(bindings))


def register_gnome_hotkey(name: str, command: str, binding: str):
    """Register a custom keybinding in GNOME.

    Example:
        register_gnome_hotkey('UClip toggle', '/usr/bin/uclip-toggle', '<Super>v')
    """
    base = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
    current = list_custom_bindings()
    # generate new path not colliding
    idx = 0
    while f"{base}custom{idx}/" in current:
        idx += 1
    new_path = f"{base}custom{idx}/"
    new_list = current + [new_path]
    set_custom_bindings(new_list)

    schema_path = f"org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:{new_path}"
    # gsettings expects: gsettings set <schema:path> key value
    _gsettings_set(schema_path, "name", f"'{name}'")
    _gsettings_set(schema_path, "command", f"'{command}'")
    _gsettings_set(schema_path, "binding", f"'{binding}'")
    logger.info("Registered hotkey %s -> %s", binding, command)

