#!/usr/bin/env bash
#set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

source "$ROOT_DIR/.venv/bin/activate"

cd "$ROOT_DIR/frontend"

# install dependencies if needed
npm install

# build frontend
npm run build

# run electron-builder locally (AppImage + deb)
npx electron-builder --linux --arm64 --x64 --dir

echo "Build finished. Check frontend/dist and frontend/build for artifacts (or run npx electron-builder without --dir to create packages)."
