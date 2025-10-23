#!/bin/bash

# 🧪 Script para testar o processo de release localmente
# Simula o que acontece no GitHub Actions

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 Testing Release Process Locally...${NC}\n"

# Simular tag de versão
MOCK_TAG="v0.1.0"
VERSION="${MOCK_TAG#v}"

echo -e "${BLUE}1️⃣  Simulating tag: $MOCK_TAG${NC}"
echo "   Version: $VERSION"
echo ""

# Navegar para o diretório do frontend
cd /home/jonatasserra/Projetos/UClip/frontend

# Instalar dependências
echo -e "${BLUE}2️⃣  Installing dependencies...${NC}"
npm ci

# Build frontend
echo -e "${BLUE}3️⃣  Building frontend...${NC}"
npm run build

# Preparar app
echo -e "${BLUE}4️⃣  Preparing app...${NC}"
npm run prepack

# Build packages
echo -e "${BLUE}5️⃣  Building packages...${NC}"
npx electron-builder --linux deb AppImage --publish never

# Listar arquivos gerados
echo -e "${BLUE}6️⃣  Listing generated files...${NC}"
echo "=== Content of dist ==="
ls -lah dist/ | grep -E "AppImage|deb" || echo "No files found"
echo ""

# Renomear arquivos
echo -e "${BLUE}7️⃣  Renaming files...${NC}"
cd dist

# Renomear .deb
if [ -f uclip-frontend_*.deb ]; then
    DEB_FILE=$(ls uclip-frontend_*.deb)
    NEW_DEB_NAME="UClip-${VERSION}.deb"
    mv "$DEB_FILE" "$NEW_DEB_NAME"
    echo -e "   ${GREEN}✓${NC} Renamed: $DEB_FILE → $NEW_DEB_NAME"
fi

# Renomear .AppImage
if [ -f uclip-frontend-*.AppImage ]; then
    APPIMAGE_FILE=$(ls uclip-frontend-*.AppImage)
    NEW_APPIMAGE_NAME="UClip-${VERSION}.AppImage"
    mv "$APPIMAGE_FILE" "$NEW_APPIMAGE_NAME"
    echo -e "   ${GREEN}✓${NC} Renamed: $APPIMAGE_FILE → $NEW_APPIMAGE_NAME"
fi

echo ""
echo -e "${BLUE}8️⃣  Final files (ready for release):${NC}"
ls -lh UClip-* 2>/dev/null || echo "No UClip-* files found"

echo ""
echo -e "${GREEN}✅ Test complete!${NC}"
echo ""
echo -e "${YELLOW}💡 These files would be uploaded to GitHub Release:${NC}"
for file in UClip-*.{deb,AppImage}; do
    if [ -f "$file" ]; then
        SIZE=$(du -h "$file" | cut -f1)
        echo "   • $file ($SIZE)"
    fi
done
