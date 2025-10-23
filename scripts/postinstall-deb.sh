#!/bin/bash

# UClip Post-Installation Script
# This script sets up the Python backend after installing the .deb package

set -e

echo "Configurando backend do UClip..."

# Create backend directory
INSTALL_DIR="/opt/UClip"
BACKEND_DIR="$INSTALL_DIR/backend"
VENV_DIR="$INSTALL_DIR/.venv"
DATA_DIR="$HOME/.local/share/uclip"

# Create data directory
mkdir -p "$DATA_DIR"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Instalando..."
    apt-get update
    apt-get install -y python3 python3-pip python3-venv xclip wl-clipboard
fi

# Create virtual environment if not exists
if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Criando ambiente virtual Python..."
    python3 -m venv "$VENV_DIR"
fi

# Install backend dependencies
if [ -f "$BACKEND_DIR/requirements.txt" ]; then
    echo "📦 Instalando dependências do backend..."
    "$VENV_DIR/bin/pip" install --upgrade pip > /dev/null 2>&1
    "$VENV_DIR/bin/pip" install -r "$BACKEND_DIR/requirements.txt" > /dev/null 2>&1
fi

# Create wrapper script for API
mkdir -p /usr/local/bin

cat > /usr/local/bin/uclip-api << 'EOF'
#!/bin/bash
cd /opt/UClip
source .venv/bin/activate
exec python backend/cli/run_api.py
EOF

chmod +x /usr/local/bin/uclip-api

# Create wrapper script for listener
cat > /usr/local/bin/uclip-listener << 'EOF'
#!/bin/bash
cd /opt/UClip
source .venv/bin/activate
exec python backend/cli/run_listener.py
EOF

chmod +x /usr/local/bin/uclip-listener

# Create systemd user service for backend API
mkdir -p /usr/share/uclip

cat > /usr/share/uclip/uclip-backend.service << 'EOF'
[Unit]
Description=UClip Backend API
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/uclip-api
Restart=on-failure
RestartSec=5
Environment="PATH=/opt/UClip/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=default.target
EOF

# Create systemd user service for clipboard listener
cat > /usr/share/uclip/uclip-listener.service << 'EOF'
[Unit]
Description=UClip Clipboard Listener
After=uclip-backend.service

[Service]
Type=simple
ExecStart=/usr/local/bin/uclip-listener
Restart=on-failure
RestartSec=5
Environment="PATH=/opt/UClip/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[Install]
WantedBy=default.target
EOF

# Setup systemd services for current user
mkdir -p ~/.config/systemd/user/
cp /usr/share/uclip/uclip-backend.service ~/.config/systemd/user/
cp /usr/share/uclip/uclip-listener.service ~/.config/systemd/user/

# Enable and start services
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable uclip-backend.service uclip-listener.service 2>/dev/null || true
systemctl --user restart uclip-backend.service uclip-listener.service 2>/dev/null || true

echo "✅ Backend do UClip configurado!"

