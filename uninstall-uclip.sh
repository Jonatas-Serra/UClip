#!/bin/bash
# UClip Complete Uninstall Script
# This script removes UClip and all its components from your system

set -e

echo "🗑️  UClip Complete Uninstall Script"
echo "======================================"
echo ""
echo "⚠️  This will remove:"
echo "  • UClip application package"
echo "  • Backend services (systemd)"
echo "  • Installation directory (/opt/UClip)"
echo "  • Command-line shortcuts (/usr/local/bin/uclip*)"
echo "  • Autostart configuration"
echo "  • Database files"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Uninstall cancelled"
    exit 0
fi

echo ""
echo "🛑 Stopping services..."
sudo systemctl stop uclip-backend.service 2>/dev/null || true
sudo systemctl stop uclip-listener.service 2>/dev/null || true
sudo systemctl disable uclip-backend.service 2>/dev/null || true
sudo systemctl disable uclip-listener.service 2>/dev/null || true
echo "✅ Services stopped"

echo ""
echo "📦 Removing package..."
sudo dpkg -r uclip 2>/dev/null || true
echo "✅ Package removed"

echo ""
echo "🗂️  Removing installation directory..."
sudo rm -rf /opt/UClip
echo "✅ /opt/UClip removed"

echo ""
echo "🔗 Removing command shortcuts..."
sudo rm -f /usr/local/bin/uclip
sudo rm -f /usr/local/bin/uclip-api
sudo rm -f /usr/local/bin/uclip-listener
echo "✅ Shortcuts removed"

echo ""
echo "⚙️  Removing systemd services..."
sudo rm -f /etc/systemd/system/uclip-backend.service
sudo rm -f /etc/systemd/system/uclip-listener.service
sudo systemctl daemon-reload
echo "✅ Systemd services removed"

echo ""
echo "📋 Removing autostart configurations..."
rm -f ~/.config/autostart/uclip-listener.desktop
echo "✅ Autostart removed for current user"

echo ""
echo "🧹 Checking for remaining traces..."
if [ -d /opt/UClip ]; then
    echo "⚠️  /opt/UClip still exists (may require manual removal)"
fi

if command -v uclip &> /dev/null; then
    echo "⚠️  'uclip' command still found"
fi

echo ""
echo "✅ UClip uninstall complete!"
echo ""
echo "Summary:"
echo "  • Packages removed"
echo "  • Services stopped and disabled"
echo "  • Installation files deleted"
echo "  • Configuration cleaned"
echo ""
echo "Your clipboard history database (if any) has been removed."