import { useEffect, useState } from 'react'

// Hash routing tangan sendiri (jalur 4 §4.1): #/ D1, #/anak/:id D2, #/anak/:id/target D3, #/anak/:id/sesi D4.
export type Route =
  | { page: 'D1' }
  | { page: 'D2'; childId: string }
  | { page: 'D3'; childId: string }
  | { page: 'D4'; childId: string }
  | { page: 'unknown'; hash: string }

export function parseHash(hash: string): Route {
  const path = hash.replace(/^#/, '').split('?')[0] || '/'
  const parts = path.split('/').filter(Boolean)
  if (parts.length === 0) return { page: 'D1' }
  if (parts[0] === 'anak' && parts[1]) {
    const childId = decodeURIComponent(parts[1])
    if (parts.length === 2) return { page: 'D2', childId }
    if (parts.length === 3 && parts[2] === 'target') return { page: 'D3', childId }
    if (parts.length === 3 && parts[2] === 'sesi') return { page: 'D4', childId }
  }
  return { page: 'unknown', hash }
}

export const href = {
  d1: () => '#/',
  d2: (childId: string) => `#/anak/${encodeURIComponent(childId)}`,
  d3: (childId: string) => `#/anak/${encodeURIComponent(childId)}/target`,
  d4: (childId: string) => `#/anak/${encodeURIComponent(childId)}/sesi`,
}

export function useRoute(): Route {
  const [route, setRoute] = useState(() => parseHash(window.location.hash))
  useEffect(() => {
    const onChange = () => setRoute(parseHash(window.location.hash))
    window.addEventListener('hashchange', onChange)
    return () => window.removeEventListener('hashchange', onChange)
  }, [])
  return route
}
