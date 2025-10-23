#!/bin/bash

# Script de configuração de autostart para o UClip
# Executado automaticamente após instalação do .deb

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Configurando autostart do UClip...${NC}"

# Create .config directory if it doesn't exist
mkdir -p ~/.config/autostart

# Create .desktop file for listener autostart (runs in user session)
cat > ~/.config/autostart/uclip-listener.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=UClip Clipboard Listener
Comment=UClip Clipboard Listener
Exec=/usr/local/bin/uclip-listener
Icon=uclip
Categories=Utility;
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

echo -e "${GREEN}✓ Autostart do listener configurado em ~/.config/autostart/${NC}"
echo -e "${BLUE}ℹ️  O listener será iniciado automaticamente na próxima sessão de desktop${NC}"

# Optional: start the listener now if we're in a desktop environment
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    echo -e "${BLUE}ℹ️  Tentando iniciar listener agora...${NC}"
    /usr/local/bin/uclip-listener > /dev/null 2>&1 &
    echo -e "${GREEN}✓ Listener iniciado em background${NC}"
else
    echo -e "${BLUE}ℹ️  Sessão gráfica não detectada. O listener será iniciado no próximo login de desktop${NC}"
fi
