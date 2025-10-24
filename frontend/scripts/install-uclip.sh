#!/usr/bin/env bash
# UClip Installation Script
# Automates setup: install dependencies, copy AppImage, register hotkey

set -euo pipefail

APP_VERSION="0.1.14"

echo "==== UClip Installation Script ===="
echo ""

# Detect OS
if ! command -v uname &> /dev/null; then
  echo "Error: Unable to detect OS"
  exit 1
fi

OS=$(uname -s)
if [[ "$OS" != "Linux" ]]; then
  echo "Error: This script supports Linux only (detected: $OS)"
  exit 1
fi

# Detect distro (basic)
if command -v apt-get &> /dev/null; then
  PKG_MGR="apt-get"
  DISTRO="debian-based"
elif command -v dnf &> /dev/null; then
  PKG_MGR="dnf"
  DISTRO="fedora-based"
else
  echo "Warning: Package manager not detected. Manual dependency installation may be required."
  DISTRO="unknown"
fi

echo "Detected: $DISTRO"
echo ""

# Step 1: Install system dependencies
echo "Step 1: Installing system dependencies..."
if [[ "$DISTRO" == "debian-based" ]]; then
  echo "Using apt-get..."
  sudo apt-get update
  sudo apt-get install -y \
    python3 python3-pip python3-venv \
    libsqlite3-dev \
    xclip \
    wl-clipboard \
    dconf-cli \
    libxcb-xfixes0 libxcb-xtest0 libfuse2 || true
elif [[ "$DISTRO" == "fedora-based" ]]; then
  echo "Using dnf..."
  sudo dnf install -y \
    python3 python3-pip \
    sqlite-devel \
    xclip \
    wl-clipboard \
    dconf \
    libxcb libxcb-devel fuse-libs || true
fi
echo "✓ System dependencies installed"
echo ""

# Step 2: Install AppImage
echo "Step 2: Installing UClip AppImage..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
APPIMAGE_SRC="$PROJECT_ROOT/frontend/dist/UClip-${APP_VERSION}.AppImage"

if [[ ! -f "$APPIMAGE_SRC" ]]; then
  echo "Error: AppImage not found at $APPIMAGE_SRC"
  echo "Please build it first: cd frontend && npm run prepack && npx electron-builder --linux"
  exit 1
fi

INSTALL_PATH="/usr/local/bin/uclip"
sudo cp "$APPIMAGE_SRC" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"
echo "✓ AppImage installed at $INSTALL_PATH"
echo ""

# Step 3: Setup Python venv and backend
echo "Step 3: Setting up Python backend..."
if [[ ! -d "$PROJECT_ROOT/.venv" ]]; then
  cd "$PROJECT_ROOT"
  python3 -m venv .venv
  echo "✓ Virtual environment created"
else
  echo "✓ Virtual environment already exists"
fi

source "$PROJECT_ROOT/.venv/bin/activate"
pip install -q -r "$PROJECT_ROOT/backend/requirements.txt" || true
echo "✓ Python dependencies installed"
echo ""

# Step 4: Register hotkey (GNOME)
echo "Step 4: Attempting to register hotkey..."
if command -v gsettings &> /dev/null; then
  echo "Detected GNOME. Registering custom keybinding..."
  
  EXECUTABLE="$INSTALL_PATH"
  NAME="UClip Toggle"
  BINDING="<Super>v"
  
  # Find next available custom index
  index=0
  while true; do
    path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$index/"
    if ! gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null | grep -q "$path"; then
      break
    fi
    index=$((index+1))
  done
  
  new_binding_path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom$index/"
  
  current=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings || echo "[]")
  updated=$(python3 - <<PY
import ast,sys
cur = sys.argv[1]
try:
    arr = ast.literal_eval(cur)
except Exception:
    arr = []
if not isinstance(arr, list):
    arr = []
if "$new_binding_path" not in arr:
    arr.append("$new_binding_path")
print(repr(arr))
PY
"$current")
  
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path name "$NAME"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path binding "$BINDING"
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$new_binding_path command "$EXECUTABLE"
  
  echo "✓ Hotkey registered: $BINDING"
else
  echo "! gsettings not found. If you use GNOME, install dconf-cli:"
  echo "  sudo apt-get install dconf-cli"
  echo ""
  echo "  For sway/hyprland, add to ~/.config/sway/config:"
  echo "  bindsym Mod4+v exec /usr/local/bin/uclip"
fi
echo ""

# Step 5: Create backend service (optional)
echo "Step 5: Setup backend auto-start (optional)..."
echo "Would you like to install as a systemd user service (runs at boot)? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
  SERVICE_PATH="$HOME/.config/systemd/user/uclip-backend.service"
  mkdir -p "$(dirname "$SERVICE_PATH")"
  
  cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=UClip Backend Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$PROJECT_ROOT
Environment="PATH=$PROJECT_ROOT/.venv/bin"
ExecStart=$PROJECT_ROOT/.venv/bin/python3 -u $PROJECT_ROOT/scripts/run_local.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
  
  systemctl --user daemon-reload
  systemctl --user enable uclip-backend.service
  systemctl --user start uclip-backend.service
  
  echo "✓ Backend service installed and started"
  echo "  Check status: systemctl --user status uclip-backend.service"
else
  echo "! You'll need to start the backend manually when needed:"
  echo "  source ~/.venv/bin/activate && python3 scripts/run_local.sh"
fi
echo ""

echo "==== Installation Complete ===="
echo ""
echo "Next steps:"
echo "  1. Start the backend (if not using systemd service):"
echo "     cd $PROJECT_ROOT && source .venv/bin/activate && python3 scripts/run_local.sh"
echo "  2. Copy something to clipboard (Ctrl+C)"
echo "  3. Press Super+V to open UClip (or click the AppImage)"
echo ""
echo "For help, see: $PROJECT_ROOT/docs/INSTALL.md"
