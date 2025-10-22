const { app, BrowserWindow, globalShortcut, Menu, Tray, ipcMain } = require('electron')
const path = require('path')
const fs = require('fs')

let win = null
let tray = null

function toggleWindow() {
  if (!win) return
  try {
    if (win.isVisible()) {
      win.hide()
    } else {
      win.show()
      win.focus()
    }
  } catch (e) {
    console.error('toggleWindow error', e)
  }
}

async function createWindow() {
  win = new BrowserWindow({
    width: 480,
    height: 640,
    show: false,
    frame: false,
    alwaysOnTop: true,
    icon: path.join(__dirname, '..', 'buildResources', 'icon.png'),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      preload: path.join(__dirname, 'preload.js'),
    },
  })

  // Posicionar no canto inferior direito da tela principal
  const primaryDisplay = require('electron').screen.getPrimaryDisplay()
  const { width: screenWidth, height: screenHeight } = primaryDisplay.workAreaSize
  const windowWidth = 480
  const windowHeight = 640
  const x = screenWidth - windowWidth - 10  // 10px de margem à direita
  const y = screenHeight - windowHeight - 10 // 10px de margem inferior
  win.setPosition(x, y)

  const isDev = process.env.UCLIP_DEV === '1' || process.env.NODE_ENV === 'development'
  if (isDev) {
    // Try common dev server addresses (localhost may resolve to ::1) and multiple ports
    const hosts = ['localhost', '127.0.0.1', '[::1]']
    const ports = []
    for (let p = 5173; p <= 5183; p++) ports.push(p)
    const devCandidates = []
    for (const h of hosts) for (const p of ports) devCandidates.push(`http://${h}:${p}`)

    // Helper: test URL availability via http request
    const http = require('http')
    async function checkUrl(url, timeout = 400) {
      return new Promise((resolve) => {
        try {
          const req = http.get(url, (res) => {
            // any 2xx/3xx/4xx is acceptable as server is present
            res.destroy()
            resolve(true)
          })
          req.on('error', () => resolve(false))
          req.setTimeout(timeout, () => { req.destroy(); resolve(false) })
        } catch (e) { resolve(false) }
      })
    }

    let chosenUrl = null
    for (const url of devCandidates) {
      // eslint-disable-next-line no-await-in-loop
      const ok = await checkUrl(url)
      if (ok) { chosenUrl = url; break }
    }

    if (!chosenUrl) {
      console.error('Failed to find a running dev server on localhost:5173-5183. Ensure `npm run dev` is running (vite).')
    } else {
      try {
        await win.loadURL(chosenUrl)
        console.log('Loaded dev server URL:', chosenUrl)
        try { win.webContents.openDevTools({ mode: 'detach' }) } catch (e) { /* ignore */ }
      } catch (e) {
        console.error('loadURL failed for chosen dev URL:', chosenUrl, e)
      }
    }
  } else {
    // When packaged, files are inside the resources/app.asar; when unpacked during dev
    // __dirname may point inside the asar or to the electron folder. Use app.isPackaged
    // and process.resourcesPath to build a path that works in both cases.
    try {
      const candidates = []
      if (app.isPackaged) {
        // Typical locations
        candidates.push(path.join(process.resourcesPath, 'app.asar', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, 'app.asar', 'app', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, 'app.asar', 'dist', 'linux-unpacked', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, '..', 'dist', 'index.html'))
      }
      // Fallback when not packaged or during development builds
      candidates.push(path.join(__dirname, '..', 'dist', 'index.html'))

      let chosen = null
      for (const c of candidates) {
        try {
          if (fs.existsSync(c)) {
            chosen = c
            break
          }
        } catch (e) {
          // ignore
        }
      }

      if (!chosen) {
        console.error('Could not find index.html. Tried candidates:', candidates)
      } else {
        console.log('Loading index from:', chosen)
        try {
          await win.loadFile(chosen)
        } catch (err) {
          console.error('Failed to load index file:', chosen, err)
        }
      }
    } catch (err) {
      console.error('Error resolving index.html path:', err)
    }
  }

  // Show when ready
  win.once('ready-to-show', () => {
    try {
      win.show()
    } catch (e) {
      // ignore
    }
  })
}

function createTray() {
  if (tray) return
  
  // Wrap the entire createTray logic in a try-catch to prevent unhandled promise rejections
  try {
    const trayIconPath = path.join(__dirname, '..', 'buildResources', 'icon-64x64.png')
    const defaultIcon = path.join(__dirname, '..', 'assets', 'icon.png')
    const iconPath = fs.existsSync(trayIconPath) ? trayIconPath : defaultIcon

    let trayIconToUse = null
    const candidates = [
      iconPath,
      path.join(process.resourcesPath || '', 'app.asar', 'assets', 'icon.png'),
      path.join(process.resourcesPath || '', 'app.asar', 'app', 'assets', 'icon.png'),
      path.join(process.resourcesPath || '', '..', 'uclip-frontend.png'),
      path.join(process.resourcesPath || '', '..', 'resources', 'assets', 'icon.png'),
      path.join(process.resourcesPath || '', '..', 'usr', 'share', 'icons', 'hicolor', '256x256', 'apps', 'uclip-frontend.png'),
      path.join(process.resourcesPath || '', '..', 'usr', 'share', 'icons', 'hicolor', '128x128', 'apps', 'uclip-frontend.png'),
      path.join(process.resourcesPath || '', '..', 'usr', 'share', 'icons', 'hicolor', '64x64', 'apps', 'uclip-frontend.png'),
    ]

    for (const c of candidates) {
      try {
        if (!c) continue
        if (!fs.existsSync(c)) continue
        const stat = fs.statSync(c)
        if (!stat || stat.size === 0) continue
        try {
          const data = fs.readFileSync(c)
          const tmp = path.join(app.getPath('temp'), `uclip-tray-icon-${Math.random().toString(36).slice(2, 8)}.png`)
          fs.writeFileSync(tmp, data)
          trayIconToUse = tmp
          console.log('✓ Tray icon loaded from:', c)
          break
        } catch (e) {
          continue
        }
      } catch (e) {
        continue
      }
    }

    if (!trayIconToUse) {
      console.warn('Could not find tray icon, using empty/default')
      trayIconToUse = defaultIcon
    }

    try {
      tray = new Tray(trayIconToUse)
      console.log('✓ Tray created successfully')
    } catch (trayErr) {
      console.error('Failed to create Tray:', trayErr && trayErr.message ? trayErr.message : trayErr)
      return
    }

    const contextMenu = Menu.buildFromTemplate([
      { label: 'Mostrar/Ocultar', click: () => toggleWindow() },
      { label: 'Histórico', click: () => toggleWindow() },
      ...(process.env.UCLIP_DEV === '1' ? [{ label: 'Abrir DevTools', click: () => { try { win && win.webContents.openDevTools({ mode: 'detach' }) } catch (e) { } } }] : []),
      { type: 'separator' },
      { label: 'Sair', click: () => { app.isQuitting = true; app.quit() } },
    ])
    tray.setContextMenu(contextMenu)
    tray.setToolTip('UClip - Gerenciador de Clipboard')
    tray.on('click', () => toggleWindow())
  } catch (e) {
    console.error('Error in createTray:', e && e.message ? e.message : e)
  }
}

app.whenReady().then(async () => {
  await createWindow()
  createTray()

  // Setup IPC for renderer logs
  ipcMain.on('renderer-log', (event, ...args) => {
    console.log('[RENDERER]', ...args)
  })
  ipcMain.on('renderer-error', (event, ...args) => {
    console.error('[RENDERER ERROR]', ...args)
  })

  // IPC para minimizar a janela após copiar
  ipcMain.on('minimize-after-copy', () => {
    if (win) {
      try {
        win.hide()
      } catch (e) {
        console.error('Error minimizing:', e)
      }
    }
  })

  // Try to register global shortcut
  let registered = false
  const shortcutCandidates = ['Super+V', 'Control+Alt+V', 'Shift+Super+V']
  
  for (const shortcut of shortcutCandidates) {
    try {
      registered = globalShortcut.register(shortcut, () => {
        console.log('✓ Global shortcut triggered:', shortcut)
        try { 
          toggleWindow()
        } catch (e) { 
          console.error('Error toggling window', e) 
        }
      })
      if (registered) {
        console.log(`✓✓✓ Atalho "${shortcut}" registrado com sucesso!`)
        break
      } else {
        console.warn(`❌ Atalho "${shortcut}" falhou (em uso), tentando próximo...`)
      }
    } catch (e) {
      console.warn(`⚠️ Exception ao registrar "${shortcut}":`, e && e.message ? e.message : e)
    }
  }

  if (!registered) {
    const wayland = process.env.WAYLAND_DISPLAY || process.env.WAYLAND_SOCKET
    const display = process.env.DISPLAY
    console.warn('⚠️⚠️⚠️ Nenhum atalho global foi registrado.')
    console.warn(`   - DISPLAY: ${display || 'não definido'}`)
    console.warn(`   - WAYLAND: ${wayland ? 'SIM (atalhos podem não funcionar)' : 'não'}`)
    console.warn('   - Solução: use o ícone na bandeja do sistema')
  }

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
    if (!tray) createTray()
  })
})

app.on('will-quit', () => {
  try { globalShortcut.unregisterAll() } catch (e) { /* ignore */ }
})

// On Linux we prefer to keep app running when windows closed
app.on('window-all-closed', (e) => {
  // do not quit on close; user can quit via tray
  if (process.platform !== 'darwin') {
    // prevent default behaviour of quitting
    // but allow explicit app.quit()
  }
})

// Minimize to tray on close (intercept close on linux)
app.on('before-quit', (e) => {
  // nothing special here; keep for future extension
})

// Intercept window close and hide to tray instead
app.on('browser-window-created', (e, window) => {
  try {
    window.on('close', (ev) => {
      if (process.platform === 'linux' && !app.isQuitting) {
        ev.preventDefault()
        try { window.hide() } catch (e) { /* ignore */ }
      }
    })
  } catch (e) { /* ignore */ }
})

