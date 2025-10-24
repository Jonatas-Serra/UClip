#!/bin/bash

# UClip - One-liner Installation Script
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/jonatasserra/UClip/main/scripts/install.sh)

set -e

APP_VERSION="0.1.14"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Banner
echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║  UClip Installation Script             ║"
echo "║  A modern clipboard manager for Linux  ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running on Linux
if [[ ! "$OSTYPE" == "linux-gnu"* ]]; then
    print_error "This script only works on Linux"
    exit 1
fi

# Detect distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    print_error "Cannot detect Linux distribution"
    exit 1
fi

print_info "Detected: $PRETTY_NAME"

# Step 1: Install system dependencies
print_info "Step 1/5: Installing system dependencies..."

case "$OS" in
    ubuntu|debian|linuxmint|pop-os)
        print_info "Using apt package manager"
        sudo apt-get update > /dev/null 2>&1
        sudo apt-get install -y python3 python3-pip python3-venv \
            xclip wl-clipboard libxcb-xtest0 libfuse2 git \
            > /dev/null 2>&1
        print_success "System dependencies installed"
        ;;
    fedora|rhel|centos)
        print_info "Using dnf package manager"
        sudo dnf install -y python3 python3-pip gcc-c++ \
            libxcb libxcb-devel wl-clipboard git \
            > /dev/null 2>&1
        print_success "System dependencies installed"
        ;;
    arch|manjaro)
        print_info "Using pacman package manager"
        sudo pacman -S --noconfirm python python-pip base-devel \
            xclip wl-clipboard git \
            > /dev/null 2>&1
        print_success "System dependencies installed"
        ;;
    *)
        print_warning "Unknown distribution: $OS"
        print_warning "Please install Python 3.8+, pip, xclip, and wl-clipboard manually"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        ;;
esac

# Step 2: Clone repository
print_info "Step 2/5: Cloning UClip repository..."

INSTALL_DIR="$HOME/Projects/UClip"
if [ -d "$INSTALL_DIR" ]; then
    print_warning "UClip already installed at $INSTALL_DIR"
    read -p "Update existing installation? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone https://github.com/Jonatas-Serra/UClip.git "$INSTALL_DIR" > /dev/null 2>&1
fi

print_success "Repository cloned to $INSTALL_DIR"

# Step 3: Setup Python environment
print_info "Step 3/5: Setting up Python environment..."

cd "$INSTALL_DIR"
python3 -m venv .venv > /dev/null 2>&1
source .venv/bin/activate
pip install -r backend/requirements.txt > /dev/null 2>&1
deactivate

print_success "Python environment ready"

# Step 4: Download/Build Frontend
print_info "Step 4/5: Setting up Frontend..."

# Check if AppImage exists in releases
if [ ! -f "$INSTALL_DIR/frontend/dist/UClip-${APP_VERSION}.AppImage" ]; then
    print_info "Downloading AppImage..."
    mkdir -p "$INSTALL_DIR/frontend/dist"
    wget -q https://github.com/Jonatas-Serra/UClip/releases/download/v${APP_VERSION}/UClip-${APP_VERSION}.AppImage \
        -O "$INSTALL_DIR/frontend/dist/UClip-${APP_VERSION}.AppImage"
fi

chmod +x "$INSTALL_DIR/frontend/dist/UClip-${APP_VERSION}.AppImage"

# Create symlink in /usr/local/bin
sudo ln -sf "$INSTALL_DIR/frontend/dist/UClip-${APP_VERSION}.AppImage" /usr/local/bin/uclip 2>/dev/null || \
    mkdir -p ~/.local/bin && ln -sf "$INSTALL_DIR/frontend/dist/UClip-${APP_VERSION}.AppImage" ~/.local/bin/uclip

print_success "Frontend installed"

# Step 5: Setup systemd service (optional)
print_info "Step 5/5: Setting up backend as system service (optional)..."

read -p "Install backend as systemd service? (recommended) (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p ~/.config/systemd/user
    
    cat > ~/.config/systemd/user/uclip-backend.service <<EOF
[Unit]
Description=UClip Backend Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/.venv/bin"
ExecStart=$INSTALL_DIR/.venv/bin/python3 $INSTALL_DIR/scripts/run_local.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable uclip-backend.service > /dev/null 2>&1
    systemctl --user start uclip-backend.service > /dev/null 2>&1
    
    print_success "Backend service installed and started"
    print_info "Service status: systemctl --user status uclip-backend.service"
else
    print_warning "Backend service not installed"
    print_info "You can start backend manually: cd $INSTALL_DIR && source .venv/bin/activate && python3 scripts/run_local.sh"
fi

# Final steps
echo
echo -e "${GREEN}╔════════════════════════════════════════╗"
echo "║  ✓ Installation Complete!             ║"
echo "╚════════════════════════════════════════╝${NC}"
echo

print_info "Quick start:"
echo "  1. Open UClip: ${BLUE}uclip${NC} or ${BLUE}Super+V${NC}"
echo "  2. Copy something: ${BLUE}Ctrl+C${NC}"
echo "  3. Open UClip: ${BLUE}Super+V${NC}"
echo

print_info "Documentation:"
echo "  • Quick Start: $INSTALL_DIR/docs/QUICK_START.md"
echo "  • Installation: $INSTALL_DIR/docs/INSTALL.pt.md"
echo "  • Usage Guide: $INSTALL_DIR/docs/USAGE.pt.md"
echo

print_info "Backend status:"
systemctl --user status uclip-backend.service 2>/dev/null || echo "  Not running (run: systemctl --user start uclip-backend.service)"

echo
print_success "UClip is ready! Press Super+V to open."
echo
