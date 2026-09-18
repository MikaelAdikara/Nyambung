import type { ChildRow, Summary, TargetOut, VocabWord } from './types'
import { wordLabel } from './format'

// Alasan "Perlu ditinjau" yang bisa dibaca. Aturan tetap, tanpa model: sistem hanya menandai pola yang
// mungkin perlu diperiksa, penafsirannya tetap pekerjaan terapis. Tiga alasan pertama adalah definisi
// needs_review kontrak §5 (server dan agregator demo), jadi badge dan alasannya tidak pernah berbeda.

const DAY_MS = 86_400_000

function daysSince(iso: string, now: number): number {
  return Math.floor((now - Date.parse(iso)) / DAY_MS)
}

/** Alasan needs_review untuk satu baris D1. Kosong ⇔ needs_review = false. */
export function reviewReasons(c: Pick<ChildRow, 'last_sync' | 'trend_3w' | 'missions_done' | 'missions_total'>, now = Date.now()): string[] {
  const out: string[] = []
  if (c.last_sync === null) out.push('Belum pernah sinkron')
  else if (now - Date.parse(c.last_sync) > 7 * DAY_MS) out.push(`Tidak sinkron ${daysSince(c.last_sync, now)} hari`)
  if (c.trend_3w === 'turun') out.push('Kata berbeda turun dibanding dua pekan sebelumnya')
  if (c.missions_done <= 1) out.push(`Misi selesai ${c.missions_done} dari ${c.missions_total} hari`)
  return out
}

/** Sinyal tambahan di D2 dari ringkasan + target. Bukan penilaian kemampuan. */
export function attentionSignals(s: Summary, targets: TargetOut[], vocab: Map<string, VocabWord>, now = Date.now()): string[] {
  const out = reviewReasons(s, now)
  if (s.unique_words_prev > 0 && s.unique_words < s.unique_words_prev * 0.5) {
    const drop = Math.round((1 - s.unique_words / s.unique_words_prev) * 100)
    out.push(`Kata berbeda turun ${drop}% dari pekan sebelumnya (${s.unique_words_prev} → ${s.unique_words})`)
  }
  for (const t of targets) {
    if (t.status !== 'diterima' || !t.answered_at || t.used_count_since_accept > 0) continue
    const days = daysSince(t.answered_at, now)
    if (days >= 7) out.push(`Target ${t.words.map((w) => wordLabel(vocab, w)).join(', ')} belum muncul ${days} hari sejak diterima`)
  }
  return out
}
