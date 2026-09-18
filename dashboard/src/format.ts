import type { Summary, VocabWord } from './types'

// Kartu personal dari foto (C3) punya word_id `prs-<label>-<6 hex>`, mis. prs-gelas_arka-3fa9c1 → GELAS ARKA.
// Fotonya tidak pernah dikirim; dasbor hanya punya label ini.
const PERSONAL = /^prs-(.+)-[0-9a-f]{6}$/

export function personalLabel(id: string): string | null {
  const m = PERSONAL.exec(id)
  return m ? m[1].replace(/_/g, ' ').toUpperCase() : null
}

export function wordLabel(vocab: Map<string, VocabWord>, id: string): string {
  return vocab.get(id)?.label_display ?? personalLabel(id) ?? id.toUpperCase()
}

// ---------- waktu ----------

export function relTime(iso: string | null): string {
  if (!iso) return 'belum pernah'
  const diff = Date.now() - Date.parse(iso)
  const min = Math.round(diff / 60_000)
  if (min < 1) return 'baru saja'
  if (min < 60) return `${min} menit lalu`
  const h = Math.round(min / 60)
  if (h < 24) return `${h} jam lalu`
  const d = Math.round(h / 24)
  return `${d} hari lalu`
}

export function fmtDate(iso: string | null): string {
  if (!iso) return '–'
  return new Date(iso).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
}

export function pct(r: number | null): string {
  return r === null ? '–' : `${Math.round(r * 100)}%`
}

// Paragraf siap salin, teks persis 02 §7 D4.
export function sessionText(s: Summary, vocab: Map<string, VocabWord>): string {
  const p = s.spontaneous_ratio === null ? 0 : Math.round(s.spontaneous_ratio * 100)
  const top = s.top_words.slice(0, 5).map((w) => wordLabel(vocab, w.word).toLowerCase())
  return (
    `Dalam 7 hari terakhir ${s.nickname ?? 'anak'} memakai ${s.unique_words} kata berbeda (${s.unique_words_prev} pekan sebelumnya). ` +
    `${p}% ketukan anak terjadi tanpa contoh dalam 60 detik sebelumnya. ` +
    `Misi selesai ${s.missions_done} dari ${s.missions_total} hari. ` +
    `Kata terbanyak: ${top.length ? top.join(', ') : '–'}.`
  )
}
