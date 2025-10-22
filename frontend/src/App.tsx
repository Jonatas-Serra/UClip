import React, { useEffect, useState, useRef } from "react";
import { listClips } from './api'

declare global {
  interface Window {
    electronAPI?: {
      minimizeAfterCopy: () => void
      rendererLog: (...args: any[]) => void
      rendererError: (...args: any[]) => void
    }
  }
}

export default function App() {
  const [clips, setClips] = useState<any[]>([])
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [selectedIndex, setSelectedIndex] = useState<number | null>(null)
  const [copied, setCopied] = useState<number | null>(null)
  const selectedRef = useRef<HTMLDivElement>(null)

  async function load() {
    setLoading(true)
    setError(null)
    try {
      const data = await listClips()
      setClips(data)
    } catch (e: any) {
      const errMsg = e?.message || String(e) || 'Unknown error'
      setError(`Erro ao carregar: ${errMsg}`)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
    const interval = setInterval(load, 2000)
    return () => clearInterval(interval)
  }, [])

  // Tratar teclas de seta
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (!clips.length) return

      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setSelectedIndex(prev => prev === null ? 0 : Math.min(prev + 1, clips.length - 1))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setSelectedIndex(prev => prev === null ? clips.length - 1 : Math.max(prev - 1, 0))
      } else if (e.key === 'Enter') {
        e.preventDefault()
        if (selectedIndex !== null) {
          copyToClipboard(clips[selectedIndex])
        }
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [clips, selectedIndex])

  // Auto-select primeiro item
  useEffect(() => {
    if (clips.length > 0 && selectedIndex === null) {
      setSelectedIndex(0)
    }
  }, [clips.length])

  // Scroll para item selecionado
  useEffect(() => {
    if (selectedRef.current) {
      selectedRef.current.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
    }
  }, [selectedIndex])

  async function copyToClipboard(clip: any) {
    try {
      if (clip.mime && clip.mime.startsWith('image')) {
        await copyImageToClipboard(clip.content)
      } else {
        await navigator.clipboard.writeText(clip.content)
      }
      
      setCopied(clip.id)
      
      setTimeout(() => {
        if (window.electronAPI?.minimizeAfterCopy) {
          window.electronAPI.minimizeAfterCopy()
        }
      }, 1000)
    } catch (e: any) {
      setError(`Erro ao copiar: ${e.message}`)
      setTimeout(() => setError(null), 2000)
    }
  }

  async function copyImageToClipboard(imageUrl: string) {
    try {
      const response = await fetch(imageUrl)
      const blob = await response.blob()
      await navigator.clipboard.write([
        new ClipboardItem({ [blob.type]: blob })
      ])
    } catch (e) {
      await navigator.clipboard.writeText(imageUrl)
    }
  }

  const styles = {
    container: {
      display: 'flex',
      flexDirection: 'column' as const,
      height: '100vh',
      background: 'linear-gradient(135deg, #1a1a1a 0%, #242424 100%)',
      color: '#e0e0e0',
    },
    header: {
      padding: '12px 16px',
      borderBottom: '1px solid #333',
      background: 'rgba(0,0,0,0.3)',
      backdropFilter: 'blur(10px)',
      userSelect: 'none',
      WebkitUserSelect: 'none',
      WebkitAppRegion: 'drag',
    },
    title: {
      fontSize: '18px',
      fontWeight: 'bold',
      margin: '0 0 4px 0',
      display: 'flex',
      alignItems: 'center',
      gap: '8px',
    },
    subtitle: {
      fontSize: '11px',
      color: '#888',
      margin: 0,
    },
    errorBox: {
      margin: '8px 0',
      padding: '8px 12px',
      background: 'rgba(220, 53, 69, 0.2)',
      border: '1px solid rgba(220, 53, 69, 0.4)',
      borderRadius: '6px',
      fontSize: '12px',
      color: '#ff6b6b',
      animation: 'slideIn 0.3s ease-out',
    },
    controls: {
      display: 'flex',
      gap: '8px',
      alignItems: 'center',
      padding: '8px 0',
    },
    button: {
      padding: '6px 12px',
      fontSize: '12px',
      border: 'none',
      borderRadius: '6px',
      cursor: 'pointer',
      background: 'linear-gradient(135deg, #0066cc 0%, #0052a3 100%)',
      color: '#fff',
      fontWeight: '500',
      transition: 'all 0.2s ease',
      opacity: 1,
      transform: 'scale(1)',
    },
    buttonDisabled: {
      opacity: 0.5,
      cursor: 'not-allowed',
    },
    counter: {
      fontSize: '11px',
      color: '#888',
      marginLeft: '8px',
    },
    listContainer: {
      flex: 1,
      overflowY: 'auto' as const,
      padding: '8px',
      display: 'flex',
      flexDirection: 'column' as const,
      gap: '6px',
    },
    emptyState: {
      display: 'flex',
      flexDirection: 'column' as const,
      alignItems: 'center',
      justifyContent: 'center',
      height: '100%',
      color: '#666',
      fontSize: '12px',
      animation: 'fadeIn 0.3s ease',
    },
    clipItem: {
      padding: '12px',
      background: 'rgba(255, 255, 255, 0.05)',
      border: '1px solid rgba(255, 255, 255, 0.1)',
      borderRadius: '8px',
      cursor: 'pointer',
      transition: 'all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1)',
      display: 'flex',
      gap: '8px',
      alignItems: 'flex-start',
    },
    clipItemSelected: {
      background: 'linear-gradient(135deg, rgba(0, 102, 204, 0.3) 0%, rgba(0, 82, 163, 0.3) 100%)',
      border: '1.5px solid #0066cc',
      boxShadow: '0 0 12px rgba(0, 102, 204, 0.2)',
      transform: 'translateX(4px)',
    },
    clipContent: {
      flex: 1,
      minWidth: 0,
    },
    timestamp: {
      fontSize: '10px',
      color: '#888',
      marginBottom: '4px',
    },
    preview: {
      fontSize: '12px',
      lineHeight: '1.4',
      color: '#d0d0d0',
      wordBreak: 'break-word' as const,
      whiteSpace: 'pre-wrap' as const,
      maxHeight: '100px',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
    },
    previewImage: {
      maxWidth: '100%',
      maxHeight: '100px',
      borderRadius: '4px',
      border: '1px solid rgba(255, 255, 255, 0.1)',
    },
    copyButton: {
      padding: '6px 10px',
      fontSize: '12px',
      border: 'none',
      borderRadius: '6px',
      cursor: 'pointer',
      background: 'rgba(0, 102, 204, 0.2)',
      color: '#0099ff',
      fontWeight: '500',
      whiteSpace: 'nowrap' as const,
      marginTop: '4px',
      transition: 'all 0.2s ease',
      minWidth: '40px',
    },
    copyButtonCopied: {
      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
      color: '#fff',
    },
  }

  return (
    <div style={styles.container as React.CSSProperties}>
      <style>{`
        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateY(-10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        @keyframes fadeIn {
          from {
            opacity: 0;
          }
          to {
            opacity: 1;
          }
        }
        
        @keyframes pulse {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0.7;
          }
        }
        
        .copy-btn:hover {
          transform: scale(1.05);
          opacity: 0.9;
        }
        
        .copy-btn:active {
          transform: scale(0.95);
        }
      `}</style>

      <div style={styles.header as React.CSSProperties} className="window-header">
        <div style={styles.title as React.CSSProperties}>
          📋 UClip
        </div>
        <p style={styles.subtitle as React.CSSProperties}>
          ⬆️ ⬇️ Navegar • Enter Copiar
        </p>
        
        {error && (
          <div style={styles.errorBox as React.CSSProperties}>
            ⚠️ {error}
          </div>
        )}
        
        <div style={styles.controls as React.CSSProperties}>
          <button 
            onClick={load}
            disabled={loading}
            style={{
              ...styles.button,
              ...(loading ? styles.buttonDisabled : {}),
            } as React.CSSProperties}
            className="copy-btn"
          >
            {loading ? '⏳' : '🔄'}
          </button>
          <span style={styles.counter as React.CSSProperties}>
            {clips.length} {clips.length === 1 ? 'clip' : 'clips'}
          </span>
        </div>
      </div>

      <div style={styles.listContainer as React.CSSProperties}>
        {clips.length === 0 && !loading && (
          <div style={styles.emptyState as React.CSSProperties}>
            <div style={{fontSize: '32px', marginBottom: '8px'}}>📭</div>
            <div>Nenhum clip</div>
            <div style={{fontSize: '10px', color: '#555', marginTop: '4px'}}>
              Copie algo para aparecer aqui
            </div>
          </div>
        )}
        
        {clips.map((clip, idx) => (
          <div
            key={clip.id}
            ref={selectedIndex === idx ? selectedRef : null}
            onClick={() => setSelectedIndex(idx)}
            className={`clip-item ${selectedIndex === idx ? 'selected' : ''}`}
            style={{
              ...styles.clipItem,
              ...(selectedIndex === idx ? styles.clipItemSelected : {}),
            } as React.CSSProperties}
          >
            <div style={styles.clipContent as React.CSSProperties}>
              <div style={styles.timestamp as React.CSSProperties}>
                {new Date(clip.created_at).toLocaleString('pt-BR', {
                  month: '2-digit',
                  day: '2-digit',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </div>
              
              {clip.mime && clip.mime.startsWith('image') ? (
                <img
                  src={clip.content}
                  alt={`clip-${clip.id}`}
                  style={styles.previewImage as React.CSSProperties}
                />
              ) : (
                <div style={styles.preview as React.CSSProperties}>
                  {clip.content}
                </div>
              )}
            </div>
            
            <button
              onClick={(e) => {
                e.stopPropagation()
                copyToClipboard(clip)
              }}
              style={{
                ...styles.copyButton,
                ...(copied === clip.id ? styles.copyButtonCopied : {}),
              } as React.CSSProperties}
              className="copy-btn"
            >
              {copied === clip.id ? '✓' : '📋'}
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
