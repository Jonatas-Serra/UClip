# Electron notes

- The Electron main process registers a global shortcut `Super+V`. On Wayland this may not be supported depending on compositor and security settings. For Wayland you may need to use a helper or the desktop environment's global shortcut registration.
- The main process file is `electron/main.js`.
- In dev mode set environment variable `UCLIP_DEV=1` to load the frontend dev server.
