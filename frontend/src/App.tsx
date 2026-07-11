import React, { useEffect, useState, useRef, useMemo, useCallback } from 'react'
import { listClips, Clip } from './api'

declare const __APP_VERSION__: string

declare global {
  interface Window {
    electronAPI?: {
      minimizeAfterCopy: () => void
      rendererLog: (...args: any[]) => void
      rendererError: (...args: any[]) => void
      minimizeWindow?: () => void
      closeWindow?: () => void
      copyImageFromPath?: (imagePath: string) => Promise<{ ok: boolean; error?: string }>
    }
  }
}

// ----------------------------- icons -----------------------------
// SVGs inline para manter zero dependências adicionais.

const Icon = {
  Search: () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="7" />
      <path d="m21 21-4.3-4.3" />
    </svg>
  ),
  Refresh: () => (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 12a9 9 0 0 1 15-6.7L21 8" />
      <path d="M21 3v5h-5" />
      <path d="M21 12a9 9 0 0 1-15 6.7L3 16" />
      <path d="M3 21v-5h5" />
    </svg>
  ),
  Minimize: () => (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M5 12h14" /></svg>
  ),
  Close: () => (
    <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><path d="M18 6 6 18M6 6l12 12" /></svg>
  ),
  Copy: () => (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="14" height="14" x="8" y="8" rx="2" />
      <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
    </svg>
  ),
  Check: () => (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M20 6 9 17l-5-5" /></svg>
  ),
  TextIcon: () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 7V4h18v3" />
      <path d="M9 20h6" />
      <path d="M12 4v16" />
    </svg>
  ),
  ImageIcon: () => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect width="18" height="18" x="3" y="3" rx="2" />
      <circle cx="9" cy="9" r="2" />
      <path d="m21 15-3.1-3.1a2 2 0 0 0-2.8 0L6 21" />
    </svg>
  ),
  Inbox: () => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="22 12 16 12 14 15 10 15 8 12 2 12" />
      <path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
    </svg>
  ),
  Brand: () => (
    <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'relative', zIndex: 1 }}>
      <rect width="14" height="14" x="8" y="8" rx="2" />
      <path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" />
    </svg>
  ),
}

// ----------------------------- helpers -----------------------------

function relativeTime(iso: string): string {
  const date = new Date(iso)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const sec = Math.floor(diffMs / 1000)
  if (sec < 60) return 'agora'
  const min = Math.floor(sec / 60)
  if (min < 60) return `${min}m`
  const hr = Math.floor(min / 60)
  if (hr < 24) return `${hr}h`
  const day = Math.floor(hr / 24)
  if (day < 7) return `${day}d`
  return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' })
}

// ----------------------------- main component -----------------------------

export default function App() {
  const [clips, setClips] = useState<Clip[]>([])
  const [searchTerm, setSearchTerm] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null)
  const [copied, setCopied] = useState<number | null>(null)
  const [imageErrors, setImageErrors] = useState<Set<number>>(new Set())
  const selectedRef = useRef<HTMLDivElement>(null)
  const searchInputRef = useRef<HTMLInputElement>(null)

  const filteredClips = useMemo(() => {
    if (!searchTerm.trim()) return clips
    const term = searchTerm.trim().toLowerCase()
    return clips.filter((clip) => {
      const content = String(clip.content ?? '').toLowerCase()
      const mime = String(clip.mime ?? '').toLowerCase()
      return content.includes(term) || mime.includes(term)
    })
  }, [clips, searchTerm])

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await listClips()
      setClips(data)
    } catch (e: any) {
      const errMsg = e?.message || String(e) || 'Unknown error'
      setError(`Backend indisponível: ${errMsg}`)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
    const interval = setInterval(load, 2000)
    return () => clearInterval(interval)
  }, [load])

  // Foco no search ao abrir
  useEffect(() => {
    searchInputRef.current?.focus()
  }, [])

  // Setas, Enter, Esc
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') {
        if (searchTerm) {
          setSearchTerm('')
        } else {
          window.electronAPI?.closeWindow?.()
        }
        return
      }
      if (!filteredClips.length) return
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setSelectedIndex((prev) => (prev === null ? 0 : Math.min(prev + 1, filteredClips.length - 1)))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setSelectedIndex((prev) => (prev === null ? filteredClips.length - 1 : Math.max(prev - 1, 0)))
      } else if (e.key === 'Enter') {
        e.preventDefault()
        if (selectedIndex !== null) {
          copyToClipboard(filteredClips[selectedIndex])
        }
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filteredClips, selectedIndex, searchTerm])

  useEffect(() => {
    if (filteredClips.length === 0) {
      setSelectedIndex(null)
      return
    }
    setSelectedIndex((prev) => {
      if (prev === null || prev >= filteredClips.length) return 0
      return prev
    })
  }, [filteredClips.length])

  useEffect(() => {
    if (filteredClips.length > 0) setSelectedIndex(0)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchTerm])

  useEffect(() => {
    if (selectedRef.current) {
      selectedRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }, [selectedIndex])

  async function copyToClipboard(clip: Clip) {
    try {
      if (clip.mime && clip.mime.startsWith('image')) {
        let copiedImage = false
        const imagePath = clip.file_path ?? null
        if (imagePath && window.electronAPI?.copyImageFromPath) {
          try {
            const result = await window.electronAPI.copyImageFromPath(imagePath)
            copiedImage = !!result?.ok
          } catch (ipcError) {
            console.error('copyImageFromPath threw:', ipcError)
          }
        }
        if (!copiedImage) {
          await copyImageViaFetch(clip.content)
        }
      } else {
        await navigator.clipboard.writeText(clip.content)
      }
      setCopied(clip.id)
      setTimeout(() => setCopied(null), 1400)
      setTimeout(() => window.electronAPI?.minimizeAfterCopy?.(), 800)
    } catch (e: any) {
      setError(`Erro ao copiar: ${e.message}`)
      setTimeout(() => setError(null), 2200)
    }
  }

  async function copyImageViaFetch(imageUrl: string) {
    const response = await fetch(imageUrl)
    if (!response.ok) throw new Error(`Falha ao baixar imagem (${response.status})`)
    const blob = await response.blob()
    await navigator.clipboard.write([new ClipboardItem({ [blob.type]: blob })])
  }

  return (
    <div className="uc-app">
      {/* ---------------- header ---------------- */}
      <header className="uc-header">
        <div className="uc-header-row">
          <div className="uc-brand">
            <div className="uc-brand-mark"><Icon.Brand /></div>
            <span className="uc-brand-name">UClip</span>
          </div>
          <div className="uc-window-controls">
            <button
              type="button"
              className="uc-window-btn"
              onClick={() => window.electronAPI?.minimizeWindow?.()}
              title="Minimizar"
              aria-label="Minimizar"
            >
              <Icon.Minimize />
            </button>
            <button
              type="button"
              className="uc-window-btn uc-window-btn--close"
              onClick={() => window.electronAPI?.closeWindow?.()}
              title="Fechar"
              aria-label="Fechar"
            >
              <Icon.Close />
            </button>
          </div>
        </div>

        <div className="uc-search">
          <span className="uc-search-icon"><Icon.Search /></span>
          <input
            ref={searchInputRef}
            type="text"
            className="uc-search-input"
            placeholder="Buscar no histórico…"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            autoFocus
          />
          {!searchTerm && (
            <div className="uc-search-kbd">
              <span className="uc-kbd">↑</span>
              <span className="uc-kbd">↓</span>
            </div>
          )}
        </div>

        {error && (
          <div className="uc-error">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="12" cy="12" r="10" /><path d="M12 8v4M12 16h.01" />
            </svg>
            {error}
          </div>
        )}

        <div className="uc-meta">
          <div className="uc-counter">
            <span className="uc-counter-dot" />
            {filteredClips.length === clips.length
              ? `${clips.length} ${clips.length === 1 ? 'clip' : 'clips'}`
              : `${filteredClips.length} / ${clips.length}`}
          </div>
          <button
            type="button"
            className={`uc-icon-btn ${loading ? 'uc-icon-btn--loading' : ''}`}
            onClick={load}
            disabled={loading}
            title="Atualizar"
            aria-label="Atualizar"
          >
            <Icon.Refresh />
          </button>
        </div>
      </header>

      {/* ---------------- list ---------------- */}
      <div className="uc-list">
        {filteredClips.length === 0 && !loading && (
          <div className="uc-empty">
            <div className="uc-empty-illus"><Icon.Inbox /></div>
            <div className="uc-empty-title">
              {searchTerm.trim() ? 'Nenhum resultado' : 'Histórico vazio'}
            </div>
            <div className="uc-empty-hint">
              {searchTerm.trim() ? 'Tente outro termo de busca' : 'Copie algo (Ctrl+C) para começar'}
            </div>
          </div>
        )}

        {filteredClips.map((clip, idx) => {
          const isImage = !!clip.mime && clip.mime.startsWith('image')
          const isSelected = selectedIndex === idx
          const isCopied = copied === clip.id
          const hasImageError = imageErrors.has(clip.id)
          return (
            <div
              key={clip.id}
              ref={isSelected ? selectedRef : null}
              onClick={() => setSelectedIndex(idx)}
              onDoubleClick={() => copyToClipboard(clip)}
              className={`uc-clip ${isSelected ? 'uc-clip--selected' : ''}`}
            >
              <div className="uc-clip-icon">
                {isImage ? <Icon.ImageIcon /> : <Icon.TextIcon />}
              </div>
              <div className="uc-clip-body">
                <div className="uc-clip-meta-line">
                  <span className="uc-clip-type-tag">{isImage ? 'IMG' : 'TXT'}</span>
                  <span>{relativeTime(clip.created_at)}</span>
                </div>
                {isImage ? (
                  hasImageError ? (
                    <div className="uc-clip-image-wrap">
                      <div className="uc-clip-image-fallback">imagem indisponível</div>
                    </div>
                  ) : (
                    <div className="uc-clip-image-wrap">
                      <img
                        src={clip.content}
                        alt={`clip-${clip.id}`}
                        className="uc-clip-image"
                        loading="lazy"
                        onError={() => {
                          setImageErrors((prev) => {
                            const next = new Set(prev)
                            next.add(clip.id)
                            return next
                          })
                        }}
                      />
                    </div>
                  )
                ) : (
                  <div className="uc-clip-preview">{clip.content}</div>
                )}
              </div>
              <div className="uc-clip-actions">
                <button
                  type="button"
                  className={`uc-copy-btn ${isCopied ? 'uc-copy-btn--copied' : ''}`}
                  onClick={(e) => {
                    e.stopPropagation()
                    copyToClipboard(clip)
                  }}
                  title="Copiar"
                  aria-label="Copiar"
                >
                  {isCopied ? <Icon.Check /> : <Icon.Copy />}
                </button>
              </div>
            </div>
          )
        })}
      </div>

      {/* ---------------- footer ---------------- */}
      <footer className="uc-footer">
        <div className="uc-footer-hints">
          <span className="uc-hint"><span className="uc-kbd">↵</span> copiar</span>
          <span className="uc-hint"><span className="uc-kbd">↑↓</span> navegar</span>
          <span className="uc-hint"><span className="uc-kbd">esc</span> fechar</span>
        </div>
        <span>v{__APP_VERSION__}</span>
      </footer>
    </div>
  )
}
