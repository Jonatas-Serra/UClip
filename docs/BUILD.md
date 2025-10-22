# Building & Packaging

This document explains how to build the frontend and package the Electron app locally and in CI.

Local build (AppImage/deb):

1. Ensure you have Node 18+ and npm installed.
2. From project root run:

```bash
# builds frontend and runs electron-builder locally (outputs into frontend/build or dist)
make package
```

3. The script `scripts/build_electron_local.sh` runs `npx electron-builder --linux --dir` which produces unpacked output. Remove `--dir` to create packages.

CI / Release:

- The workflow `.github/workflows/release.yml` will run on tag pushes `v*`, build the frontend, run electron-builder and create a GitHub Release draft. It requires the repository's `GITHUB_TOKEN` to be available (provided automatically on GitHub Actions).

Secrets and publishing:

- To publish artifacts to GitHub Releases or other stores, you may need to set additional secrets (e.g., `GH_TOKEN`, signing keys). Keep them in repository `Settings > Secrets`.

Icons and assets:

- Replace `frontend/assets/icon.png` with your app icons (png and/or svg). electron-builder expects `buildResources` directory with icon files for packaging.

Icon replacement
- Place your app icons (PNG or SVG) into `frontend/buildResources/` with names like `icon-128x128.png`, `icon-256x256.png`, etc. You can generate them from a single SVG or PNG using `scripts/generate_icons.py`:

```bash
source .venv/bin/activate
python3 scripts/generate_icons.py frontend/assets/icon.png frontend/buildResources
```

Secrets for publishing
- For publishing releases automatically you may need to add repository secrets (Settings → Secrets):
	- `GITHUB_TOKEN` (already provided by Actions for the repository) — used for creating releases.
	- `GH_TOKEN` or other tokens if publishing to other stores.
	- Signing keys (PGP) if you want to sign packages — add them as secrets and configure electron-builder to use them.


*** End Patch