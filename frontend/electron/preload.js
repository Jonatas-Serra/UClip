const { ipcRenderer, contextBridge } = require('electron')

contextBridge.exposeInMainWorld('electronAPI', {
  minimizeAfterCopy: () => ipcRenderer.send('minimize-after-copy'),
  rendererLog: (...args) => ipcRenderer.send('renderer-log', ...args),
  rendererError: (...args) => ipcRenderer.send('renderer-error', ...args),
})
