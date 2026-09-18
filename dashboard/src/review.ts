import { useEffect, useRef } from 'react'
import type { DataSource } from './data'
import type { Route } from './route'

// Waktu tinjauan untuk kartu D1: berapa lama terapis membuka halaman satu anak (D2–D4) sebelum pindah.
// Dihitung per detak 5 detik, hanya saat tab terlihat dan ada gerakan/ketikan dalam 2 menit terakhir, supaya tab
// yang ditinggal terbuka tidak ikut terhitung. Dikirim saat pindah ke anak lain, ke D1, atau saat tab ditutup.
const TICK_MS = 5_000
const IDLE_MS = 120_000
const MIN_SECONDS = 5

function childOf(route: Route): string | null {
  return route.page === 'D2' || route.page === 'D3' || route.page === 'D4' ? route.childId : null
}

export function useReviewTimer(route: Route, source: DataSource): void {
  const child = childOf(route)
  const state = useRef({ child: null as string | null, seconds: 0, lastInput: Date.now() })

  useEffect(() => {
    const s = state.current
    const flush = () => {
      if (s.child && s.seconds >= MIN_SECONDS) source.recordReview(s.child, s.seconds)
      s.seconds = 0
    }
    if (s.child !== child) {
      flush()
      s.child = child
      s.lastInput = Date.now()
    }
    if (!child) return

    const input = () => {
      s.lastInput = Date.now()
    }
    const tick = window.setInterval(() => {
      if (document.visibilityState === 'visible' && Date.now() - s.lastInput < IDLE_MS) s.seconds += TICK_MS / 1000
    }, TICK_MS)
    const events = ['pointermove', 'pointerdown', 'keydown', 'scroll', 'wheel'] as const
    for (const e of events) window.addEventListener(e, input, { passive: true })
    window.addEventListener('pagehide', flush)
    return () => {
      window.clearInterval(tick)
      for (const e of events) window.removeEventListener(e, input)
      window.removeEventListener('pagehide', flush)
    }
  }, [child, source])
}
