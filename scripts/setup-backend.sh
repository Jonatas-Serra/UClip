#!/bin/bash

# UClip Backend Setup Script
# This script installs and configures the UClip Python backend

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Configurando backend do UClip...${NC}\n"

# Check if running on Linux
if [[ ! "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${RED}❌ Este script funciona apenas no Linux${NC}"
    exit 1
fi

# Install system dependencies
echo -e "${BLUE}1️⃣  Instalando dependências do sistema...${NC}"
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y python3 python3-pip python3-venv xclip wl-clipboard > /dev/null 2>&1
echo -e "${GREEN}   ✓ Dependências instaladas${NC}\n"

# Clone or update repository
INSTALL_DIR="$HOME/.local/share/uclip"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠️  UClip backend já existe em $INSTALL_DIR${NC}"
    read -p "Atualizar? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        cd "$INSTALL_DIR"
        git pull
    fi
else
    echo -e "${BLUE}2️⃣  Clonando repositório do UClip...${NC}"
    git clone https://github.com/Jonatas-Serra/UClip.git "$INSTALL_DIR" > /dev/null 2>&1
    echo -e "${GREEN}   ✓ Repositório clonado${NC}\n"
fi

# Create virtual environment
echo -e "${BLUE}3️⃣  Criando ambiente virtual Python...${NC}"
cd "$INSTALL_DIR"
python3 -m venv .venv
source .venv/bin/activate
echo -e "${GREEN}   ✓ Ambiente virtual criado${NC}\n"

# Install Python dependencies
echo -e "${BLUE}4️⃣  Instalando dependências Python...${NC}"
pip install --upgrade pip > /dev/null 2>&1
pip install -r backend/requirements.txt > /dev/null 2>&1
echo -e "${GREEN}   ✓ Dependências Python instaladas${NC}\n"

# Create systemd user services
echo -e "${BLUE}5️⃣  Criando serviços systemd...${NC}"
mkdir -p ~/.config/systemd/user/

# Backend API service
cat > ~/.config/systemd/user/uclip-backend.service << EOF
[Unit]
Description=UClip Backend API
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/.venv/bin/python backend/cli/run_api.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Clipboard listener service
cat > ~/.config/systemd/user/uclip-listener.service << EOF
[Unit]
Description=UClip Clipboard Listener
After=uclip-backend.service

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/.venv/bin/python backend/cli/run_listener.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo -e "${GREEN}   ✓ Serviços criados${NC}\n"

# Enable and start services
echo -e "${BLUE}6️⃣  Iniciando serviços...${NC}"
systemctl --user daemon-reload
systemctl --user enable uclip-backend.service uclip-listener.service
systemctl --user start uclip-backend.service uclip-listener.service
echo -e "${GREEN}   ✓ Serviços iniciados${NC}\n"

# Verify services are running
sleep 2
if systemctl --user is-active --quiet uclip-backend.service && \
   systemctl --user is-active --quiet uclip-listener.service; then
    echo -e "${GREEN}✅ Backend do UClip configurado com sucesso!${NC}\n"
    echo -e "${BLUE}📍 Serviços rodando:${NC}"
    echo "   • uclip-backend.service  - API REST (http://localhost:8000)"
    echo "   • uclip-listener.service - Listener de clipboard"
    echo ""
    echo -e "${BLUE}💡 Comandos úteis:${NC}"
    echo "   systemctl --user status uclip-backend   # Ver status"
    echo "   systemctl --user stop uclip-backend     # Parar"
    echo "   systemctl --user restart uclip-backend  # Reiniciar"
    echo "   journalctl --user -u uclip-backend -f   # Ver logs"
else
    echo -e "${RED}❌ Erro ao iniciar serviços${NC}"
    echo "Verifique os logs com:"
    echo "   journalctl --user -u uclip-backend -n 50"
    echo "   journalctl --user -u uclip-listener -n 50"
    exit 1
fi
