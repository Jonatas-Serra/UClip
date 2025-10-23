/**
 * Electron main process for UClip
 * - Registers global shortcut Super+V to toggle the popup window
 * - Loads frontend dev server at http://127.0.0.1:5173 when DEV env is set
 * - Otherwise loads built files from frontend/dist
 */

const { app, BrowserWindow, globalShortcut } = require('electron')
const path = require('path')

let win = null

function createWindow() {
  win = new BrowserWindow({
    width: 480,
    height: 640,
    show: false,
    frame: false,
    alwaysOnTop: true,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
    },
  })

  const isDev = process.env.UCLIP_DEV === '1' || process.env.NODE_ENV === 'development'
  if (isDev) {
    // Try multiple hosts and ports (Vite may choose another port)
    const hosts = ['localhost', '127.0.0.1', '[::1]']
    const ports = []
    for (let p = 5173; p <= 5183; p++) ports.push(p)
    const devCandidates = []
    for (const h of hosts) for (const p of ports) devCandidates.push(`http://${h}:${p}`)

    const http = require('http')
    async function checkUrl(url, timeout = 400) {
      return new Promise((resolve) => {
        try {
          const req = http.get(url, (res) => { res.destroy(); resolve(true) })
          req.on('error', () => resolve(false))
          req.setTimeout(timeout, () => { req.destroy(); resolve(false) })
        } catch (e) { resolve(false) }
      })
    }

    (async () => {
      let chosen = null
      for (const url of devCandidates) {
        // eslint-disable-next-line no-await-in-loop
        const ok = await checkUrl(url)
        if (ok) { chosen = url; break }
      }
      if (chosen) {
        try {
          await win.loadURL(chosen)
          console.log('Loaded dev server URL:', chosen)
          try { win.webContents.openDevTools({ mode: 'detach' }) } catch (e) { /* ignore */ }
        } catch (e) { console.error('Failed to load dev URL', chosen, e) }
      } else {
        console.error('Could not find dev server on ports 5173-5183')
      }

      // Ensure the window is shown when content is ready
      try {
        win.once && win.once('ready-to-show', () => {
          try { win.show(); win.focus(); } catch (e) { /* ignore */ }
        })
      } catch (e) { /* ignore */ }
    })()
  } else {
    // Try multiple paths: packaged app structure vs dev structure
    const possiblePaths = [
      path.join(__dirname, '..', 'app', 'dist', 'index.html'),           // resources/app/dist
      path.join(__dirname, '..', 'frontend', 'dist', 'index.html'),      // development structure
    ]
    
    let loaded = false
    for (const filePath of possiblePaths) {
      try {
        console.log('Trying to load:', filePath)
        win.loadFileSync ? win.loadFileSync(filePath) : null
        win.loadFile(filePath)
        console.log('Successfully loaded:', filePath)
        loaded = true
        break
      } catch (e) {
        console.log('Failed to load:', filePath, e.message)
      }
    }
    
    if (!loaded) {
      console.error('Could not find index.html in any of the expected locations')
    }
  }
}

function toggleWindow() {
  if (!win) return
  if (win.isVisible()) {
    win.hide()
  } else {
    win.show()
    win.focus()
  }
}

app.whenReady().then(() => {
  createWindow()

  const registered = globalShortcut.register('Super+V', () => {
    try {
      toggleWindow()
    } catch (e) {
      console.error('Error toggling window', e)
    }
  })

  if (!registered) {
    console.warn('Global shortcut Super+V registration failed. On Wayland it may not be supported.')
  }

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('will-quit', () => {
  globalShortcut.unregisterAll()
})
