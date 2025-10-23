#!/bin/bash

# 📦 Script para gerar DEB localmente
# Uso: ./scripts/build_deb.sh

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}📦 Building DEB package for UClip...${NC}\n"

# Step 0: Clean development database and images
echo -e "${BLUE}0️⃣  Cleaning development data...${NC}"
if [ -f "uclip.db" ]; then
    echo "   Removing development database: uclip.db"
    rm -f uclip.db uclip.db-shm uclip.db-wal
fi
if [ -d "images" ]; then
    echo "   Removing development images directory"
    rm -rf images
fi
if [ -d "backend/images" ]; then
    echo "   Removing backend images directory"
    rm -rf backend/images
fi
echo -e "${GREEN}   ✓ Development data cleaned${NC}\n"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Error: Node.js is not installed${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ Error: npm is not installed${NC}"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}❌ Error: frontend/package.json not found${NC}"
    echo "Please run this script from the UClip root directory"
    exit 1
fi

cd frontend

# Step 1: Install dependencies
echo -e "${BLUE}1️⃣  Installing dependencies...${NC}"
npm ci

# Step 2: Build frontend with Vite
echo -e "${BLUE}2️⃣  Building frontend with Vite...${NC}"
npm run build

# Step 3: Prepare app for packaging
echo -e "${BLUE}3️⃣  Preparing app for packaging...${NC}"
npm run prepack

# Step 4: Build DEB only
echo -e "${BLUE}4️⃣  Building DEB package...${NC}"
npx electron-builder --linux deb --publish never

# Step 5: Rename and check if DEB was created
echo -e "${BLUE}5️⃣  Renaming packages...${NC}"
cd dist

# Get version from package.json
VERSION=$(node -p "require('../package.json').version")

# Rename .deb file
if ls uclip-frontend_*.deb 1> /dev/null 2>&1; then
    OLD_DEB=$(ls -t uclip-frontend_*.deb | head -1)
    NEW_DEB="UClip-${VERSION}.deb"
    mv "$OLD_DEB" "$NEW_DEB"
    echo "   Renamed: $OLD_DEB → $NEW_DEB"
fi

# Check if renamed DEB exists
if ls UClip-*.deb 1> /dev/null 2>&1; then
    DEB_FILE=$(ls -t UClip-*.deb | head -1)
    DEB_SIZE=$(du -h "$DEB_FILE" | cut -f1)
    echo -e "${GREEN}✅ DEB package created successfully!${NC}\n"
    echo -e "${BLUE}📦 Package details:${NC}"
    echo "   Name: $DEB_FILE"
    echo "   Size: $DEB_SIZE"
    echo "   Location: $(pwd)/$DEB_FILE"
    echo ""
    echo -e "${YELLOW}💡 To install locally:${NC}"
    echo "   sudo dpkg -i $DEB_FILE"
    echo ""
    echo -e "${YELLOW}💡 To test without installing:${NC}"
    echo "   ar x $DEB_FILE"
else
    echo -e "${RED}❌ Failed to create DEB package${NC}"
    cd ..
    exit 1
fi

cd ..

# Step 6: Try to build AppImage too
echo -e "${BLUE}6️⃣  Building AppImage package...${NC}"
npx electron-builder --linux AppImage --publish never

echo -e "${BLUE}7️⃣  Renaming AppImage...${NC}"
cd dist

# Rename .AppImage file
if ls uclip-frontend-*.AppImage 1> /dev/null 2>&1; then
    OLD_APPIMAGE=$(ls -t uclip-frontend-*.AppImage | head -1)
    NEW_APPIMAGE="UClip-${VERSION}.AppImage"
    mv "$OLD_APPIMAGE" "$NEW_APPIMAGE"
    echo "   Renamed: $OLD_APPIMAGE → $NEW_APPIMAGE"
fi

if ls UClip-*.AppImage 1> /dev/null 2>&1; then
    APPIMAGE_FILE=$(ls -t UClip-*.AppImage | head -1)
    APPIMAGE_SIZE=$(du -h "$APPIMAGE_FILE" | cut -f1)
    echo -e "${GREEN}✅ AppImage package created successfully!${NC}\n"
    echo -e "${BLUE}📦 Package details:${NC}"
    echo "   Name: $APPIMAGE_FILE"
    echo "   Size: $APPIMAGE_SIZE"
    echo "   Location: $(pwd)/$APPIMAGE_FILE"
    echo ""
    echo -e "${YELLOW}💡 To run AppImage:${NC}"
    echo "   chmod +x $APPIMAGE_FILE"
    echo "   ./$APPIMAGE_FILE"
fi

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo -e "${BLUE}📍 Generated files:${NC}"
ls -lh UClip-*.deb UClip-*.AppImage 2>/dev/null || echo "No packages found"

cd ..
