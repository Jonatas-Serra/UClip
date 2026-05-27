const { app, BrowserWindow, globalShortcut, Menu, Tray, ipcMain, clipboard, nativeImage } = require('electron')
const path = require('path')
const fs = require('fs')

let win = null
let tray = null

// --------- single instance + toggle flag ---------
// Quando o atalho global do GNOME (Super+V via gsettings) dispara `uclip --toggle`,
// uma segunda instância do Electron tenta subir. O lock garante que a segunda
// instância apenas notifica a primeira (que então faz o toggle da janela)
// e morre, em vez de abrir uma janela nova.
const isToggleInvocation = process.argv.includes('--toggle')
const gotLock = app.requestSingleInstanceLock({ toggle: isToggleInvocation })

if (!gotLock) {
  app.quit()
  process.exit(0)
}

app.on('second-instance', (_event, _argv, _cwd, additionalData) => {
  const wantsToggle = additionalData && additionalData.toggle
  if (wantsToggle) {
    toggleWindow()
  } else if (win) {
    try { win.show(); win.focus() } catch (e) { /* ignore */ }
  }
})

// Helper function to resolve icon path across different environments
function resolveIconPath() {
  const candidates = [
    path.join(__dirname, '..', 'app', 'assets', 'icon.png'),
    path.join(__dirname, '..', 'assets', 'icon.png'),
    path.join(__dirname, '..', 'buildResources', 'icon.png'),
  ]
  for (const iconPath of candidates) {
    if (fs.existsSync(iconPath)) return iconPath
  }
  return undefined
}

function toggleWindow() {
  if (!win) return
  try {
    if (win.isVisible() && win.isFocused()) {
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
    width: 460,
    height: 640,
    show: false,
    frame: false,
    transparent: true,
    backgroundColor: '#00000000',
    alwaysOnTop: true,
    skipTaskbar: false,
    resizable: false,
    icon: resolveIconPath(),
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
      spellcheck: false,
      preload: path.join(__dirname, 'preload.js'),
    },
  })

  // Posicionar no canto inferior direito
  try {
    const primaryDisplay = require('electron').screen.getPrimaryDisplay()
    const { width: screenWidth, height: screenHeight } = primaryDisplay.workAreaSize
    win.setPosition(screenWidth - 460 - 12, screenHeight - 640 - 12)
  } catch (e) { /* ignore */ }

  const isDev = process.env.UCLIP_DEV === '1' || process.env.NODE_ENV === 'development'
  if (isDev) {
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

    let chosenUrl = null
    for (const url of devCandidates) {
      const ok = await checkUrl(url)
      if (ok) { chosenUrl = url; break }
    }

    if (chosenUrl) {
      try {
        await win.loadURL(chosenUrl)
        try { win.webContents.openDevTools({ mode: 'detach' }) } catch (e) { /* ignore */ }
      } catch (e) {
        console.error('loadURL failed:', e)
      }
    } else {
      console.error('Dev server não encontrado em localhost:5173-5183')
    }
  } else {
    try {
      const candidates = []
      if (app.isPackaged) {
        candidates.push(path.join(process.resourcesPath, 'app.asar', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, 'app.asar', 'app', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, 'app', 'app', 'dist', 'index.html'))
        candidates.push(path.join(process.resourcesPath, 'app', 'dist', 'index.html'))
      }
      candidates.push(path.join(__dirname, '..', 'dist', 'index.html'))

      const chosen = candidates.find(c => { try { return fs.existsSync(c) } catch { return false } })
      if (chosen) {
        await win.loadFile(chosen)
      } else {
        console.error('index.html não encontrado em nenhum candidato')
      }
    } catch (err) {
      console.error('Erro ao resolver index.html:', err)
    }
  }

  // Não mostrar automaticamente — usuário invoca via Super+V ou tray
  win.once('ready-to-show', () => {
    // Em modo dev mostra; em produção, fica oculto até toggle
    if (process.env.UCLIP_DEV === '1') {
      try { win.show() } catch (e) { /* ignore */ }
    }
  })

  // Hide ao perder foco (comportamento padrão de clipboard manager)
  win.on('blur', () => {
    if (process.env.UCLIP_DEV !== '1') {
      try { win.hide() } catch (e) { /* ignore */ }
    }
  })
}

function createTray() {
  if (tray) return
  try {
    const trayIconCandidates = [
      path.join(__dirname, '..', 'app', 'assets', 'icon-64x64.png'),
      path.join(__dirname, '..', 'app', 'assets', 'icon.png'),
      path.join(__dirname, '..', 'assets', 'icon-64x64.png'),
      path.join(__dirname, '..', 'assets', 'icon.png'),
      path.join(__dirname, '..', 'buildResources', 'icon-64x64.png'),
      path.join(__dirname, '..', 'buildResources', 'icon.png'),
    ]

    const trayIconToUse = trayIconCandidates.find(c => { try { return fs.existsSync(c) } catch { return false } })
    if (!trayIconToUse) {
      console.warn('Tray icon não encontrado')
      return
    }

    try {
      tray = new Tray(trayIconToUse)
    } catch (trayErr) {
      console.error('Tray falhou:', trayErr && trayErr.message ? trayErr.message : trayErr)
      return
    }

    const contextMenu = Menu.buildFromTemplate([
      { label: 'Abrir histórico', click: () => toggleWindow() },
      { type: 'separator' },
      ...(process.env.UCLIP_DEV === '1' ? [{ label: 'DevTools', click: () => { try { win && win.webContents.openDevTools({ mode: 'detach' }) } catch (e) { } } }] : []),
      { label: 'Sair', click: () => { app.isQuitting = true; app.quit() } },
    ])
    tray.setContextMenu(contextMenu)
    tray.setToolTip('UClip — Super+V para abrir')
    tray.on('click', () => toggleWindow())
  } catch (e) {
    console.error('createTray error:', e && e.message ? e.message : e)
  }
}

app.disableHardwareAcceleration()

app.whenReady().then(async () => {
  await createWindow()
  createTray()

  // Se o app foi invocado com --toggle (ex.: pelo atalho do GNOME), mostra a janela.
  // A segunda instância encaminhará esse caso via 'second-instance' handler.
  if (isToggleInvocation) {
    setTimeout(() => toggleWindow(), 200)
  }

  ipcMain.on('renderer-log', (_event, ...args) => console.log('[RENDERER]', ...args))
  ipcMain.on('renderer-error', (_event, ...args) => console.error('[RENDERER ERROR]', ...args))

  ipcMain.on('minimize-after-copy', () => { try { win && win.hide() } catch (e) { /* ignore */ } })

  ipcMain.on('window-minimize', () => {
    if (!win) return
    try { win.hide() } catch (e) { /* ignore */ }
  })

  ipcMain.on('window-close', () => {
    if (!win) return
    try { win.hide() } catch (e) { /* ignore */ }
  })

  ipcMain.handle('copy-image-from-path', async (_event, imagePath) => {
    if (!imagePath || typeof imagePath !== 'string') {
      return { ok: false, error: 'Caminho da imagem ausente' }
    }
    try {
      if (!fs.existsSync(imagePath)) {
        return { ok: false, error: 'Arquivo não encontrado' }
      }
      const image = nativeImage.createFromPath(imagePath)
      if (!image || image.isEmpty()) {
        return { ok: false, error: 'Imagem inválida' }
      }
      clipboard.writeImage(image)
      return { ok: true }
    } catch (err) {
      return { ok: false, error: err && err.message ? err.message : String(err) }
    }
  })

  // Tenta registrar Super+V no nível do Electron. Funciona em X11.
  // Em Wayland (GNOME default no Ubuntu 22+), o registro retorna false e
  // o atalho real é configurado via gsettings pelo postinst.
  let registered = false
  const candidates = ['Super+V', 'Control+Alt+V', 'Shift+Super+V']
  for (const shortcut of candidates) {
    try {
      registered = globalShortcut.register(shortcut, () => {
        try { toggleWindow() } catch (e) { console.error('toggle err', e) }
      })
      if (registered) {
        console.log(`Atalho "${shortcut}" registrado via Electron`)
        break
      }
    } catch (e) { /* tenta próximo */ }
  }

  if (!registered) {
    const wayland = process.env.WAYLAND_DISPLAY
    if (wayland) {
      console.log('Wayland detectado — Super+V deve estar configurado via gsettings (`uclip --toggle`)')
    } else {
      console.warn('Nenhum atalho global registrado. Use o ícone na bandeja.')
    }
  }

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
    if (!tray) createTray()
  })
})

app.on('will-quit', () => {
  try { globalShortcut.unregisterAll() } catch (e) { /* ignore */ }
})

app.on('window-all-closed', () => { /* mantém vivo no tray */ })

app.on('browser-window-created', (_e, window) => {
  try {
    window.on('close', (ev) => {
      if (process.platform === 'linux' && !app.isQuitting) {
        ev.preventDefault()
        try { window.hide() } catch (e) { /* ignore */ }
      }
    })
  } catch (e) { /* ignore */ }
})
