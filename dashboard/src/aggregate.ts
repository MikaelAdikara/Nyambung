// Agregator browser untuk mode demo. Cermin kontrak §5 dan server/app/services/summary.py baris demi baris;
// angka harus identik dengan server untuk data dan `now` yang sama. Definisi beku di J6.
import type { ChildRow, ChildrenOverview, DemoChild, DemoEvent, DemoFile, DemoTarget, Summary, TargetOut, Trend } from './types'

// Kontrak §5 "ketukan"
const TAP_METHODS = new Set(['SEL', 'KAT', 'PRS'])
const DAY_MS = 86_400_000

interface Ev {
  ts_utc: string
  date_local: string
  hour_local: number
  content: string
  method: string
  actor: string
  prompt_level: string
  context: string | null
}

// Server: utc_iso() = UTC, presisi detik, akhiran Z (strftime memotong pecahan detik).
export function utcIso(ms: number): string {
  return new Date(Math.floor(ms / 1000) * 1000).toISOString().replace('.000Z', 'Z')
}

function parseUtc(s: string): number {
  return Date.parse(s)
}

// Server menurunkan hour_local/date_local dari ts_device sebelum dinormalkan (kontrak §2),
// jadi diambil dari teks lokalnya, bukan dari zona waktu browser.
function toEv(e: DemoEvent): Ev {
  return {
    ts_utc: utcIso(Date.parse(e.ts_device)),
    date_local: e.ts_device.slice(0, 10),
    hour_local: Number(e.ts_device.slice(11, 13)),
    content: e.content,
    method: e.method,
    actor: e.actor,
    prompt_level: e.prompt_level,
    context: e.context,
  }
}

const inWin = (e: Ev, start: string, end: string) => start <= e.ts_utc && e.ts_utc < end

// Kontrak §5 "jendela": [now − days, now), digeser offsetDays ke belakang.
function win(now: number, days: number, offsetDays = 0): [string, string] {
  const end = now - offsetDays * DAY_MS
  return [utcIso(end - days * DAY_MS), utcIso(end)]
}

// Kontrak §5 "ketukan anak"
const childTaps = (evs: Ev[]) => evs.filter((e) => TAP_METHODS.has(e.method) && e.actor === 'anak')

// Kontrak §5 "unique_words"
function uniqueWords(evs: Ev[], [start, end]: [string, string]): number {
  return new Set(childTaps(evs).filter((e) => inWin(e, start, end)).map((e) => e.content)).size
}

// Kontrak §5 "missions_done" / "missions_skipped"
function missionDays(evs: Ev[], [start, end]: [string, string], content: string): number {
  return new Set(evs.filter((e) => e.method === 'MIS' && e.content === content && inWin(e, start, end)).map((e) => e.date_local)).size
}

// Kontrak §5 "trend_3w" (selalu pekan 7 hari, tidak ikut `days`)
function trend3w(evs: Ev[], now: number): Trend {
  const w0 = uniqueWords(evs, win(now, 7))
  const prev = [1, 2].map((k) => uniqueWords(evs, win(now, 7, 7 * k))).filter((w) => w > 0)
  if (prev.length === 0) return 'baru'
  const base = prev.reduce((a, b) => a + b, 0) / prev.length
  if (w0 >= base * 1.15 && w0 - base >= 1) return 'naik'
  if (w0 <= base * 0.85 && base - w0 >= 1) return 'turun'
  return 'tetap'
}

// Kontrak §5 "status target" dan "used_count_since_accept"
function targetRows(targets: DemoTarget[], evs: Ev[]): TargetOut[] {
  const ordered = [...targets].sort((a, b) =>
    a.created_at !== b.created_at ? (a.created_at < b.created_at ? 1 : -1) : a.target_id < b.target_id ? 1 : -1,
  )
  return ordered.map((t) => {
    const answers = evs.filter((e) => e.method === 'TGT' && e.context === t.target_id)
    let status: TargetOut['status'] = 'usulan'
    let answered_at: string | null = null
    let used = 0
    if (answers.length > 0) {
      const last = answers[answers.length - 1]
      status = last.content === 'diterima' || last.content === 'ditolak' ? last.content : 'usulan'
      answered_at = last.ts_utc
      if (status === 'diterima') {
        used = evs.filter((e) => TAP_METHODS.has(e.method) && t.words.includes(e.content) && e.ts_utc >= last.ts_utc).length
      }
    }
    return {
      target_id: t.target_id,
      child_id: t.child_id,
      words: t.words,
      note: t.note,
      week_index: t.week_index,
      routine: t.routine,
      therapist: t.therapist,
      created_at: t.created_at,
      status,
      answered_at,
      used_count_since_accept: used,
    }
  })
}

// Kontrak §5 "linked_weeks": floor(hari penuh sejak linked_at / 7)
function linkedWeeks(child: DemoChild, now: number): number | null {
  if (!child.linked_at) return null
  const days = Math.floor((now - parseUtc(child.linked_at)) / DAY_MS)
  return Math.max(0, Math.floor(days / 7))
}

// Kontrak §5 "needs_review" / "unsynced_over_7d": last_sync kosong atau > 7 hari
const stale = (sync: string | null, now: number) => sync === null || now - parseUtc(sync) > 7 * DAY_MS

export class DemoAggregator {
  private evsByChild = new Map<string, Ev[]>()
  private readonly file: DemoFile
  private readonly now: () => number

  constructor(file: DemoFile, now: () => number = Date.now) {
    this.file = file
    this.now = now
    for (const e of file.events) {
      const list = this.evsByChild.get(e.child_id) ?? []
      list.push(toEv(e))
      this.evsByChild.set(e.child_id, list)
    }
    // Server: ORDER BY ts_utc (urutan stabil untuk seri)
    for (const list of this.evsByChild.values()) list.sort((a, b) => (a.ts_utc < b.ts_utc ? -1 : a.ts_utc > b.ts_utc ? 1 : 0))
  }

  child(childId: string): DemoChild | undefined {
    return this.file.children.find((c) => c.child_id === childId)
  }

  private evs(childId: string): Ev[] {
    return this.evsByChild.get(childId) ?? []
  }

  targets(childId: string): TargetOut[] {
    return targetRows(
      this.file.targets.filter((t) => t.child_id === childId),
      this.evs(childId),
    )
  }

  summary(childId: string, days = 7, at = this.now()): Summary | null {
    const child = this.child(childId)
    if (!child) return null
    const evs = this.evs(childId)
    const w = win(at, days)
    const taps = evs.filter((e) => TAP_METHODS.has(e.method) && inWin(e, ...w))
    const kid = taps.filter((e) => e.actor === 'anak')
    const spont = kid.filter((e) => e.prompt_level === 'spontan').length

    const counts = new Map<string, number>()
    for (const e of kid) counts.set(e.content, (counts.get(e.content) ?? 0) + 1)
    // Kontrak §5 "top_words": hitungan menurun, seri word_id menaik (urutan kode titik seperti Python)
    const ordered = [...counts.entries()].sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0))
    const hist = new Array<number>(24).fill(0)
    for (const e of kid) hist[e.hour_local] += 1

    const targets = targetRows(
      this.file.targets.filter((t) => t.child_id === childId),
      evs,
    )
    return {
      child_id: childId,
      nickname: child.nickname,
      age_years: child.age_years,
      routine: child.routine,
      days,
      window_start_utc: w[0],
      window_end_utc: w[1],
      unique_words: counts.size,
      unique_words_prev: uniqueWords(evs, win(at, days, days)),
      spontaneous_ratio: kid.length ? spont / kid.length : null,
      missions_done: missionDays(evs, w, 'selesai'),
      missions_total: days,
      top_words: ordered.slice(0, 10).map(([word, count]) => ({ word, count })),
      hour_histogram: hist,
      last_sync: child.last_sync,
      trend_3w: trend3w(evs, at),
      total_taps: taps.length,
      parent_taps: taps.filter((e) => e.actor === 'pendamping').length,
      child_taps: kid.length,
      prompted_taps: kid.length - spont,
      spontaneous_taps: spont,
      missions_skipped: missionDays(evs, w, 'belum_sempat'),
      weekly_unique_6w: [5, 4, 3, 2, 1, 0].map((k) => uniqueWords(evs, win(at, 7, 7 * k))),
      missions_done_6w: missionDays(evs, win(at, 42), 'selesai'),
      missions_total_6w: 42,
      word_counts: Object.fromEntries(ordered),
      linked_weeks: linkedWeeks(child, at),
      pending_targets: targets.filter((t) => t.status === 'usulan').length,
    }
  }

  // D1: server children_overview()
  overview(at = this.now()): ChildrenOverview {
    const children: ChildRow[] = []
    for (const c of this.file.children) {
      const s = this.summary(c.child_id, 7, at)!
      children.push({
        child_id: c.child_id,
        nickname: s.nickname,
        age_years: s.age_years,
        routine: s.routine,
        unique_words: s.unique_words,
        trend_3w: s.trend_3w,
        missions_done: s.missions_done,
        missions_total: s.missions_total,
        last_sync: s.last_sync,
        pending_targets: s.pending_targets,
        needs_review: stale(s.last_sync, at) || s.trend_3w === 'turun' || s.missions_done <= 1,
      })
    }
    const name = (c: ChildRow) => (c.nickname ?? '').toLowerCase()
    children.sort((a, b) => Number(!a.needs_review) - Number(!b.needs_review) || (name(a) < name(b) ? -1 : name(a) > name(b) ? 1 : 0))
    return {
      active_families: children.length,
      needs_review: children.filter((c) => c.needs_review).length,
      unsynced_over_7d: children.filter((c) => stale(c.last_sync, at)).length,
      pending_targets: children.reduce((a, c) => a + c.pending_targets, 0),
      children,
    }
  }
}
