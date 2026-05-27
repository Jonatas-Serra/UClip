#!/bin/bash
# UClip — Uninstall script
# Remove pacote .deb, user systemd services, atalho GNOME e dados.

set -e

PURGE_DATA=0
if [ "${1:-}" = "--purge" ]; then
    PURGE_DATA=1
fi

echo "[UClip] Removendo pacote..."
sudo apt-get remove -y uclip 2>/dev/null || true
sudo dpkg --purge uclip 2>/dev/null || true

echo "[UClip] Removendo user services + atalho para cada usuário..."
for user_home in /home/*/; do
    [ -d "$user_home" ] || continue
    username=$(basename "$user_home")
    if ! id "$username" >/dev/null 2>&1; then continue; fi
    user_id=$(id -u "$username")
    user_env="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$user_id/bus XDG_RUNTIME_DIR=/run/user/$user_id"

    sudo -u "$username" env $user_env systemctl --user stop uclip-backend.service uclip-listener.service 2>/dev/null || true
    sudo -u "$username" env $user_env systemctl --user disable uclip-backend.service uclip-listener.service 2>/dev/null || true

    rm -f "$user_home/.config/systemd/user/uclip-backend.service"
    rm -f "$user_home/.config/systemd/user/uclip-listener.service"
    rm -f "$user_home/.config/autostart/uclip-listener.desktop"

    sudo -u "$username" env $user_env systemctl --user daemon-reload 2>/dev/null || true

    # Remove atalho GNOME
    sudo -u "$username" env $user_env bash << 'GSETTINGS' || true
if ! command -v gsettings >/dev/null 2>&1; then exit 0; fi

SCHEMA="org.gnome.settings-daemon.plugins.media-keys"
PATH_BASE="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
NEW_PATH="$PATH_BASE/uclip/"

CURRENT=$(gsettings get "$SCHEMA" custom-keybindings 2>/dev/null || echo "@as []")
NEW=$(echo "$CURRENT" | sed -E "s#, *'$NEW_PATH'##g; s#'$NEW_PATH', *##g; s#'$NEW_PATH'##g; s#\[ *,#[#; s#,  *\]#]#")
gsettings set "$SCHEMA" custom-keybindings "$NEW" 2>/dev/null || true

SCHEMA_CB="${SCHEMA}.custom-keybinding:$NEW_PATH"
gsettings reset-recursively "$SCHEMA_CB" 2>/dev/null || true
GSETTINGS

    if [ $PURGE_DATA -eq 1 ]; then
        echo "[UClip] Removendo dados de $username..."
        rm -rf "$user_home/.local/share/uclip"
    fi
done

echo "[UClip] Removendo binários e wrappers..."
sudo rm -f /usr/local/bin/uclip /usr/local/bin/uclip-api /usr/local/bin/uclip-listener
sudo rm -rf /opt/UClip

echo "[UClip] Removendo system services antigos (legado)..."
sudo systemctl stop uclip-backend.service uclip-listener.service 2>/dev/null || true
sudo systemctl disable uclip-backend.service uclip-listener.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/uclip-backend.service /etc/systemd/system/uclip-listener.service
sudo systemctl daemon-reload 2>/dev/null || true

echo ""
echo "[UClip] ✅ Desinstalado!"
if [ $PURGE_DATA -eq 0 ]; then
    echo "    Histórico preservado em ~/.local/share/uclip"
    echo "    Use --purge para apagá-lo também"
fi
