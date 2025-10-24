export interface Clip {
  id: number
  content: string
  mime: string
  created_at: string
  file_path?: string | null
}

const API_BASE_URL = 'http://127.0.0.1:8001'

export async function listClips(): Promise<Clip[]> {
  const res = await fetch(`${API_BASE_URL}/api/clips/`)
  if (!res.ok) throw new Error('Failed to fetch clips')
  return res.json()
}
