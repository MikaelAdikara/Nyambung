// Satu antarmuka, dua sumber (jalur 4 §4.2):
//  - api : server jalur 3 dengan Bearer token terapis (sessionStorage, tidak pernah localStorage)
//  - demo: ?source=demo, atau otomatis bila server tidak terjangkau; dihitung di browser oleh aggregate.ts
import { DemoAggregator } from './aggregate'
import type { ChildrenOverview, DemoFile, InviteOut, SessionNote, SessionNoteIn, Summary, TargetIn, TargetOut, VocabWord } from './types'

export const API_BASE: string = (import.meta.env.VITE_API_BASE as string | undefined) ?? 'http://127.0.0.1:8000'
const TOKEN_KEY = 'nyambung.therapistToken'

export class ApiError extends Error {
  readonly status: number
  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

export interface DataSource {
  readonly kind: 'api' | 'demo'
  children(): Promise<ChildrenOverview>
  summary(childId: string, days?: number): Promise<Summary>
  targets(childId: string): Promise<TargetOut[]>
  createTarget(childId: string, body: TargetIn): Promise<TargetOut>
  createInvite(): Promise<InviteOut>
  sessions(childId: string): Promise<SessionNote[]>
  saveSession(childId: string, body: SessionNoteIn, noteId?: string): Promise<SessionNote>
  shareSession(childId: string, noteId: string, familyText: string): Promise<SessionNote>
  // Waktu tinjauan D1. Terbaik-usaha: gagal kirim tidak pernah mengganggu terapis.
  recordReview(childId: string, seconds: number): void
}

export function readToken(): string | null {
  try {
    return sessionStorage.getItem(TOKEN_KEY)
  } catch {
    return null
  }
}

export function saveToken(token: string | null): void {
  try {
    if (token) sessionStorage.setItem(TOKEN_KEY, token)
    else sessionStorage.removeItem(TOKEN_KEY)
  } catch {
    // sessionStorage diblokir: token hanya hidup selama halaman terbuka
  }
}

// Login email + kata sandi → token sesi 30 hari (disimpan di tempat yang sama dengan token env).
export async function loginWithPassword(email: string, password: string): Promise<string> {
  let res: Response
  try {
    res = await fetch(`${API_BASE}/v1/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    })
  } catch {
    throw new ApiError(0, `Server ${API_BASE} tidak terjangkau.`)
  }
  if (res.status === 401) throw new ApiError(401, 'Email atau kata sandi salah.')
  if (!res.ok) throw new ApiError(res.status, `Server menjawab ${res.status}.`)
  return ((await res.json()) as { token: string }).token
}

export class ApiSource implements DataSource {
  readonly kind = 'api'
  private readonly token: string
  constructor(token: string) {
    this.token = token
  }

  private async req<T>(method: string, path: string, body?: unknown): Promise<T> {
    let res: Response
    try {
      res = await fetch(API_BASE + path, {
        method,
        headers: { Authorization: `Bearer ${this.token}`, ...(body ? { 'Content-Type': 'application/json' } : {}) },
        body: body ? JSON.stringify(body) : undefined,
      })
    } catch {
      throw new ApiError(0, `Server ${API_BASE} tidak terjangkau.`)
    }
    if (!res.ok) {
      let detail = res.statusText
      try {
        const j = (await res.json()) as { detail?: unknown }
        if (typeof j.detail === 'string') detail = j.detail
      } catch {
        // badan bukan JSON
      }
      throw new ApiError(res.status, detail)
    }
    return (await res.json()) as T
  }

  children() {
    return this.req<ChildrenOverview>('GET', '/v1/children')
  }
  summary(childId: string, days = 7) {
    return this.req<Summary>('GET', `/v1/children/${encodeURIComponent(childId)}/summary?days=${days}`)
  }
  targets(childId: string) {
    return this.req<TargetOut[]>('GET', `/v1/children/${encodeURIComponent(childId)}/targets`)
  }
  createTarget(childId: string, body: TargetIn) {
    return this.req<TargetOut>('POST', `/v1/children/${encodeURIComponent(childId)}/targets`, body)
  }
  createInvite() {
    return this.req<InviteOut>('POST', '/v1/link/invite')
  }
  sessions(childId: string) {
    return this.req<SessionNote[]>('GET', `/v1/children/${encodeURIComponent(childId)}/sessions`)
  }
  saveSession(childId: string, body: SessionNoteIn, noteId?: string) {
    const base = `/v1/children/${encodeURIComponent(childId)}/sessions`
    return noteId
      ? this.req<SessionNote>('PUT', `${base}/${encodeURIComponent(noteId)}`, body)
      : this.req<SessionNote>('POST', base, body)
  }
  shareSession(childId: string, noteId: string, familyText: string) {
    return this.req<SessionNote>(
      'POST',
      `/v1/children/${encodeURIComponent(childId)}/sessions/${encodeURIComponent(noteId)}/share`,
      { family_text: familyText },
    )
  }
  recordReview(childId: string, seconds: number) {
    // keepalive: tetap terkirim walau tab sedang ditutup
    void fetch(`${API_BASE}/v1/review-time`, {
      method: 'POST',
      keepalive: true,
      headers: { Authorization: `Bearer ${this.token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ child_id: childId, seconds: Math.min(3600, Math.round(seconds)) }),
    }).catch(() => undefined)
  }
  me() {
    return this.req<{ therapist: string; email: string | null }>('GET', '/v1/auth/me')
  }
  // Mencabut sesi di server. Token env tidak bisa dicabut dari sini (403), cukup dilupakan di browser.
  async logout(): Promise<void> {
    try {
      await fetch(`${API_BASE}/v1/auth/logout`, { method: 'POST', headers: { Authorization: `Bearer ${this.token}` } })
    } catch {
      // luring: token tetap dilupakan di browser dan kedaluwarsa sendiri
    }
  }
}

export class DemoSource implements DataSource {
  readonly kind = 'demo'
  private readonly agg: DemoAggregator
  constructor(agg: DemoAggregator) {
    this.agg = agg
  }

  async children() {
    return this.agg.overview()
  }
  async summary(childId: string, days = 7) {
    const s = this.agg.summary(childId, days)
    if (!s) throw new ApiError(404, 'anak tidak ditemukan')
    return s
  }
  async targets(childId: string) {
    if (!this.agg.child(childId)) throw new ApiError(404, 'anak tidak ditemukan')
    return this.agg.targets(childId)
  }
  async createTarget(): Promise<TargetOut> {
    throw new ApiError(0, 'Mode demo tidak mengirim ke server.')
  }
  async createInvite(): Promise<InviteOut> {
    throw new ApiError(0, 'Mode demo tidak membuat kode undangan.')
  }
  async sessions(childId: string) {
    if (!this.agg.child(childId)) throw new ApiError(404, 'anak tidak ditemukan')
    return this.agg.sessions(childId)
  }
  async saveSession(): Promise<SessionNote> {
    throw new ApiError(0, 'Mode demo tidak menyimpan catatan sesi.')
  }
  async shareSession(): Promise<SessionNote> {
    throw new ApiError(0, 'Mode demo tidak mengirim ke keluarga.')
  }
  recordReview() {
    // mode demo tidak mengukur waktu tinjauan
  }
}

export async function loadDemoSource(): Promise<DemoSource> {
  const res = await fetch(`${import.meta.env.BASE_URL}demo_events.json`)
  if (!res.ok) throw new Error(`demo_events.json tidak termuat (${res.status}). Jalankan npm run prepare-public.`)
  return new DemoSource(new DemoAggregator((await res.json()) as DemoFile))
}

// Server hidup? /v1/health tanpa auth. Port bisa dijawab proses lain, jadi periksa `ok: true`.
export async function serverReachable(): Promise<string | null> {
  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), 2500)
  try {
    const res = await fetch(`${API_BASE}/v1/health`, { signal: ctrl.signal })
    if (!res.ok) return `Server ${API_BASE} menjawab ${res.status}.`
    const j = (await res.json()) as { ok?: boolean }
    return j.ok === true ? null : `Alamat ${API_BASE} bukan server Nyambung.`
  } catch {
    return `Server ${API_BASE} tidak terjangkau.`
  } finally {
    clearTimeout(timer)
  }
}

// ---------- kosakata (ikon kata dan grid D3) ----------

// Pengurai CSV yang menghormati kutip (source_note bisa berisi koma, kontrak §6).
export function parseCsv(text: string): string[][] {
  const rows: string[][] = []
  let row: string[] = []
  let field = ''
  let quoted = false
  for (let i = 0; i < text.length; i++) {
    const ch = text[i]
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') {
        field += '"'
        i++
      } else if (ch === '"') quoted = false
      else field += ch
    } else if (ch === '"') quoted = true
    else if (ch === ',') {
      row.push(field)
      field = ''
    } else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && text[i + 1] === '\n') i++
      row.push(field)
      rows.push(row)
      row = []
      field = ''
    } else field += ch
  }
  if (field || row.length) {
    row.push(field)
    rows.push(row)
  }
  return rows.filter((r) => r.some((f) => f !== ''))
}

export async function loadVocab(): Promise<VocabWord[]> {
  const res = await fetch(`${import.meta.env.BASE_URL}core_vocab_id.csv`)
  if (!res.ok) throw new Error(`core_vocab_id.csv tidak termuat (${res.status}).`)
  const [header, ...rows] = parseCsv(await res.text())
  const col = (name: string) => header.indexOf(name)
  const c = {
    id: col('word_id'),
    label: col('label_display'),
    pos: col('pos'),
    cat: col('category'),
    page: col('page'),
    posi: col('position_index'),
    sym: col('symbol_file'),
  }
  return rows.map((r) => ({
    word_id: r[c.id],
    label_display: r[c.label],
    pos: r[c.pos],
    category: r[c.cat],
    page: Number(r[c.page]),
    position_index: Number(r[c.posi]),
    symbol_file: r[c.sym],
  }))
}
