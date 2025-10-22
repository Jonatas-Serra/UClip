const API_BASE_URL = 'http://127.0.0.1:8001'

export async function listClips(): Promise<any[]> {
  const res = await fetch(`${API_BASE_URL}/api/clips/`)
  if (!res.ok) throw new Error('Failed to fetch clips')
  return res.json()
}
