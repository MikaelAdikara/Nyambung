import { createContext, useContext, useEffect, useState } from 'react'
import { ApiError, type DataSource } from './data'
import type { VocabWord } from './types'

// ---------- konteks aplikasi ----------

export interface AppCtx {
  source: DataSource
  vocab: Map<string, VocabWord>
  vocabList: VocabWord[]
  onUnauthorized: () => void
}

export const Ctx = createContext<AppCtx | null>(null)

export function useApp(): AppCtx {
  const c = useContext(Ctx)
  if (!c) throw new Error('useApp di luar Ctx')
  return c
}

// ---------- pemuatan ----------

type Async<T> = { state: 'loading' } | { state: 'error'; error: Error } | { state: 'ok'; data: T }

export function useAsync<T>(load: () => Promise<T>, deps: unknown[]): [Async<T>, () => void] {
  const { onUnauthorized } = useApp()
  const [v, setV] = useState<Async<T>>({ state: 'loading' })
  const [tick, setTick] = useState(0)
  useEffect(() => {
    let live = true
    setV({ state: 'loading' })
    load().then(
      (data) => live && setV({ state: 'ok', data }),
      (error: Error) => {
        if (!live) return
        if (error instanceof ApiError && error.status === 401) onUnauthorized()
        setV({ state: 'error', error })
      },
    )
    return () => {
      live = false
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [...deps, tick])
  return [v, () => setTick((t) => t + 1)]
}
