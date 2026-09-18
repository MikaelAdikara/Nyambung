import { useEffect, useMemo, useRef, useState } from 'react'
import type { ChildRow, InviteOut, PhraseOut, SessionNote } from '../types'
import { href } from '../route'
import { useApp, useAsync } from '../ctx'
import { relTime } from '../format'
import { reviewReasons } from '../attention'
import { Icon } from '../icons'
import { Avatar, ErrorBox, Loading, Panel, StatCard, StatusPill, TrendBadge, toneFor } from '../ui'

const fmtMinutes = (m: number) => m.toLocaleString('id-ID', { maximumFractionDigits: 1 })
const DAY_MS = 86_400_000

const localIso = (d: Date) => {
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}

// Sapaan tanpa label "(ilustratif)" di dalam kurung.
const greetName = (name: string | null) => (name ? name.replace(/\s*\(.*?\)\s*/g, '').trim() : null)

interface Upcoming {
  child: ChildRow
  at: string // YYYY-MM-DD atau YYYY-MM-DDTHH:MM (waktu lokal sesi)
  focus: string | null
}

interface Extras {
  upcoming: Upcoming[]
  phrases: (PhraseOut & { nickname: string | null })[]
}

// Jadwal sesi dan frasa terbaru dikumpulkan dari tiap anak. Gagal satu anak tidak menggagalkan beranda.
async function loadExtras(
  children: ChildRow[],
  sessions: (id: string) => Promise<SessionNote[]>,
  phrases: (id: string) => Promise<PhraseOut[]>,
): Promise<Extras> {
  const today = localIso(new Date())
  const rows = await Promise.all(
    children.map(async (c) => {
      const [s, p] = await Promise.all([sessions(c.child_id).catch(() => []), phrases(c.child_id).catch(() => [])])
      return { c, s, p }
    }),
  )
  const upcoming: Upcoming[] = []
  for (const { c, s } of rows) {
    // Sesi berikutnya = next_session terbaru yang belum lewat, dari catatan sesi terakhir yang mengisinya.
    const next = s
      .map((n) => ({ at: n.next_session, focus: n.focus }))
      .filter((n): n is { at: string; focus: string | null } => !!n.at && n.at.slice(0, 10) >= today)
      .sort((a, b) => a.at.localeCompare(b.at))[0]
    if (next) upcoming.push({ child: c, at: next.at, focus: next.focus })
  }
  const phraseRows = rows
    .flatMap(({ c, p }) => p.map((x) => ({ ...x, nickname: c.nickname })))
    .sort((a, b) => b.created_at.localeCompare(a.created_at))
  return { upcoming: upcoming.sort((a, b) => a.at.localeCompare(b.at)), phrases: phraseRows }
}

// D1 Keluarga binaan (jalur 4 §4.3, teks 02 §7), tata letak beranda terapis.
export function D1() {
  const { source, query, therapist } = useApp()
  const [res] = useAsync(() => source.children(), [source])
  const [extras] = useAsync(
    async () => (res.state === 'ok' ? loadExtras(res.data.children, (id) => source.sessions(id), (id) => source.phrases(id)) : null),
    [source, res.state],
  )
  const tableRef = useRef<HTMLDivElement>(null)
  const [onlyReview, setOnlyReview] = useState(false)

  const shown = useMemo(() => {
    if (res.state !== 'ok') return []
    const q = query.trim().toLowerCase()
    return res.data.children.filter((c) => (!q || (c.nickname ?? '').toLowerCase().includes(q)) && (!onlyReview || c.needs_review))
  }, [res, query, onlyReview])

  const toTable = (review: boolean) => {
    setOnlyReview(review)
    tableRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  const name = greetName(therapist)
  const today = new Date().toLocaleDateString('id-ID', { weekday: 'long', day: 'numeric', month: 'long' })

  return (
    <section className="d1">
      <div className="hero">
        <div className="hero-text">
          <h1>{name ? `Halo, ${name}` : 'Halo'}</h1>
          <p>
            {today}
            {res.state === 'ok' &&
              (res.data.needs_review > 0
                ? ` · ${res.data.needs_review} keluarga perlu ditinjau`
                : ' · semua keluarga berjalan seperti biasa')}
          </p>
        </div>
        <div className="hero-actions">
          <InviteButton />
          {res.state === 'ok' && <PhraseLauncher kids={res.data.children} />}
        </div>
        <svg className="hero-waves" viewBox="0 0 800 200" preserveAspectRatio="none" aria-hidden="true">
          <path d="M0 140C120 90 220 170 360 130S600 60 800 110V200H0Z" />
          <path d="M0 170C160 130 300 200 460 160S680 120 800 150V200H0Z" />
        </svg>
      </div>

      {res.state === 'loading' && <Loading />}
      {res.state === 'error' && <ErrorBox error={res.error} />}
      {res.state === 'ok' && (
        <>
          <div className="stats stats-3">
            <StatCard icon="users" accent="teal" label="Keluarga aktif" value={res.data.active_families} onClick={() => toTable(false)} />
            <StatCard icon="alert" accent="coral" label="Perlu ditinjau" value={res.data.needs_review} onClick={() => toTable(true)} />
            <StatCard
              icon="clock"
              accent="lavender"
              label="Usulan menunggu keluarga"
              value={res.data.pending_targets}
              sub="Keluarga berhak menolak tanpa alasan."
            />
          </div>
          <p className="facts">
            <span>
              <Icon name="sync" size={16} /> Belum sinkron &gt; 7 hari: <strong>{res.data.unsynced_over_7d}</strong>
            </span>
            <span>
              <Icon name="clock" size={16} /> Waktu tinjauan rata-rata:{' '}
              <strong>{res.data.review_avg_minutes === null ? 'belum diukur' : `${fmtMinutes(res.data.review_avg_minutes)} menit`}</strong>
              {res.data.review_avg_minutes === null
                ? source.kind === 'demo'
                  ? ' (mode demo tidak mengukur)'
                  : ' (terukur saat halaman anak dibuka)'
                : ` dari ${res.data.review_count_30d} tinjauan 30 hari · sasaran di bawah 5 menit per anak`}
            </span>
          </p>

          <div className="d1-grid">
            <div className="d1-col">
              <Schedule upcoming={extras.state === 'ok' && extras.data ? extras.data.upcoming : null} />
              <ReviewList rows={res.data.children.filter((c) => c.needs_review)} />
            </div>

            <div className="d1-col">
            <div ref={tableRef} className="d1-table">
              <Panel
                title="Keluarga binaan"
                icon="users"
                actions={
                  <div className="segmented" role="group" aria-label="Saring">
                    <button type="button" aria-pressed={!onlyReview} onClick={() => setOnlyReview(false)}>
                      Semua
                    </button>
                    <button type="button" aria-pressed={onlyReview} onClick={() => setOnlyReview(true)}>
                      Perlu ditinjau
                    </button>
                  </div>
                }
              >
                <FamilyTable rows={shown} empty={res.data.children.length === 0} filtered={!!query.trim() || onlyReview} />
              </Panel>
            </div>

            <RecentPhrases rows={extras.state === 'ok' && extras.data ? extras.data.phrases : null} />
            </div>
          </div>
        </>
      )}
    </section>
  )
}

function FamilyTable({ rows, empty, filtered }: { rows: ChildRow[]; empty: boolean; filtered: boolean }) {
  if (empty) return <p className="panel-empty">Belum ada keluarga yang tertaut. Buat kode undangan dan berikan ke keluarga.</p>
  if (rows.length === 0) return <p className="panel-empty">{filtered ? 'Tidak ada anak yang cocok.' : 'Belum ada data.'}</p>
  return (
    <div className="table-wrap">
      <table className="table">
        <thead>
          <tr>
            <th>Anak</th>
            <th className="num" title="Kata berbeda yang diketuk anak dalam 7 hari terakhir">
              Kata berbeda
            </th>
            <th>Arah 3 pekan</th>
            <th>Misi 7 hari</th>
            <th>Sinkron</th>
            <th>Status</th>
            <th>
              <span className="sr-only">Buka</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {rows.map((c) => (
            <tr key={c.child_id} className="row-link" onClick={() => (window.location.hash = href.d2(c.child_id))}>
              <td>
                <span className="who">
                  <Avatar name={c.nickname ?? '?'} size={34} tone={toneFor(c.child_id)} />
                  <span>
                    <a href={href.d2(c.child_id)} onClick={(e) => e.stopPropagation()}>
                      {c.nickname ?? '(tanpa nama)'}
                    </a>
                    <span className="who-sub">
                      {c.age_years ?? '–'} tahun · {c.routine ?? '–'}
                    </span>
                  </span>
                </span>
              </td>
              <td className="num">{c.unique_words}</td>
              <td>
                <TrendBadge trend={c.trend_3w} />
              </td>
              <td>
                {c.missions_done} dari {c.missions_total}
              </td>
              <td title={c.last_sync ?? ''}>{relTime(c.last_sync)}</td>
              <td>
                {c.needs_review ? (
                  <span className="pill pill-review" title={reviewReasons(c).join(' · ')}>
                    <Icon name="alert" size={13} />
                    Perlu ditinjau
                  </span>
                ) : (
                  <span className="pill pill-ok">
                    <Icon name="check" size={13} />
                    Berjalan
                  </span>
                )}
              </td>
              <td className="row-go">
                <Icon name="chevron" size={18} />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

function Schedule({ upcoming }: { upcoming: Upcoming[] | null }) {
  const days = useMemo(() => {
    const start = new Date()
    start.setHours(0, 0, 0, 0)
    return Array.from({ length: 7 }, (_, i) => new Date(start.getTime() + i * DAY_MS))
  }, [])
  const [picked, setPicked] = useState<string | null>(null)
  const byDay = (iso: string) => (upcoming ?? []).filter((u) => u.at.slice(0, 10) === iso)
  const list = picked ? byDay(picked) : (upcoming ?? [])

  return (
    <Panel
      title="Jadwal sesi"
      icon="calendar"
      className="d1-schedule"
      actions={
        picked && (
          <button type="button" className="link" onClick={() => setPicked(null)}>
            Semua
          </button>
        )
      }
    >
      <div className="days" role="group" aria-label="Pilih hari">
        {days.map((d) => {
          const iso = localIso(d)
          const has = byDay(iso).length > 0
          return (
            <button
              type="button"
              key={iso}
              className={`day${picked === iso ? ' on' : ''}${has ? ' has' : ''}`}
              aria-pressed={picked === iso}
              onClick={() => setPicked(picked === iso ? null : iso)}
            >
              <span className="day-num">{d.getDate()}</span>
              <span className="day-name">{d.toLocaleDateString('id-ID', { weekday: 'short' })}</span>
            </button>
          )
        })}
      </div>
      {upcoming === null ? (
        <Loading />
      ) : list.length === 0 ? (
        <p className="panel-empty">
          {picked ? 'Tidak ada sesi di hari ini.' : 'Belum ada sesi terjadwal. Isi "Sesi berikutnya" di catatan sesi.'}
        </p>
      ) : (
        <ul className="sessions">
          {list.map((u) => {
            const [date, time] = u.at.split('T')
            const [y, m, d] = date.split('-').map(Number)
            return (
              <li key={u.child.child_id + u.at}>
                <a href={href.d4(u.child.child_id)}>
                  <Avatar name={u.child.nickname ?? '?'} size={40} tone={toneFor(u.child.child_id)} />
                  <span className="session-who">
                    <strong>{u.child.nickname ?? '(tanpa nama)'}</strong>
                    <span>{u.focus ?? 'Sesi tatap muka'}</span>
                  </span>
                  <span className="session-when">
                    <span>{new Date(y, m - 1, d).toLocaleDateString('id-ID', { weekday: 'short', day: 'numeric', month: 'short' })}</span>
                    <strong>{time ? time.replace(':', '.') : 'jam belum diisi'}</strong>
                  </span>
                </a>
              </li>
            )
          })}
        </ul>
      )}
    </Panel>
  )
}

function RecentPhrases({ rows }: { rows: (PhraseOut & { nickname: string | null })[] | null }) {
  const voice = { cowo: 'Suara papan (cowok)', cewe: 'Suara papan (cewek)', keluarga: 'Suara keluarga' }
  return (
    <Panel title="Frasa bersuara terbaru" icon="wave" tone="lavender" className="d1-phrases">
      {rows === null ? (
        <Loading />
      ) : rows.length === 0 ? (
        <p className="panel-empty">Belum ada frasa. Buka halaman anak → Frasa bersuara untuk mengirim yang pertama.</p>
      ) : (
        <div className="table-wrap">
          <table className="table">
            <thead>
              <tr>
                <th>Frasa</th>
                <th>Anak</th>
                <th>Suara</th>
                <th>Status</th>
                <th className="num">Dipakai</th>
              </tr>
            </thead>
            <tbody>
              {rows.slice(0, 5).map((p) => (
                <tr key={p.phrase_id} className="row-link" onClick={() => (window.location.hash = href.d5(p.child_id))}>
                  <td>
                    <strong>“{p.text}”</strong>
                    <span className="who-sub">{p.created_by === 'keluarga' ? 'dibuat keluarga' : `dari ${p.created_by}`}</span>
                  </td>
                  <td>{p.nickname ?? '–'}</td>
                  <td>{voice[p.voice]}</td>
                  <td>
                    <StatusPill status={p.status} />
                  </td>
                  <td className="num">{p.used_count}×</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Panel>
  )
}

function ReviewList({ rows }: { rows: ChildRow[] }) {
  return (
    <Panel title="Perlu ditinjau" icon="alert" tone="coral" className="d1-review">
      {rows.length === 0 ? (
        <p className="panel-empty">Tidak ada yang ditandai pekan ini.</p>
      ) : (
        <ul className="review-list">
          {rows.map((c) => (
            <li key={c.child_id}>
              <a href={href.d2(c.child_id)}>
                <Avatar name={c.nickname ?? '?'} size={36} tone={toneFor(c.child_id)} />
                <span>
                  <strong>{c.nickname ?? '(tanpa nama)'}</strong>
                  <span className="who-sub">{reviewReasons(c).join(' · ')}</span>
                </span>
                <Icon name="chevron" size={18} className="row-go" />
              </a>
            </li>
          ))}
        </ul>
      )}
      <p className="panel-foot">Ditandai oleh aturan tetap, bukan kesimpulan klinis.</p>
    </Panel>
  )
}

function InviteButton() {
  const { source } = useApp()
  const [invite, setInvite] = useState<InviteOut | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const demo = source.kind === 'demo'

  const create = async () => {
    setBusy(true)
    setError(null)
    try {
      setInvite(await source.createInvite())
    } catch (e) {
      setError((e as Error).message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="invite">
      <button
        className="button ghost"
        onClick={create}
        disabled={busy || demo}
        title={demo ? 'Mode demo tidak membuat kode undangan.' : undefined}
      >
        <Icon name="plus" size={18} /> {busy ? 'Membuat…' : 'Buat kode undangan'}
      </button>
      {invite && (
        <div className="invite-card" role="status">
          <span className="invite-code">{invite.invite_code}</span>
          <span>Berlaku 7 hari, sekali pakai.</span>
        </div>
      )}
      {error && <p className="hero-error">{error}</p>}
    </div>
  )
}

// "Kirim frasa": pilih anak, lalu ke halaman frasa bersuara anak itu.
function PhraseLauncher({ kids }: { kids: ChildRow[] }) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    if (!open) return
    const close = (e: MouseEvent | KeyboardEvent) => {
      if (e instanceof KeyboardEvent ? e.key === 'Escape' : !ref.current?.contains(e.target as Node)) setOpen(false)
    }
    window.addEventListener('mousedown', close)
    window.addEventListener('keydown', close)
    return () => {
      window.removeEventListener('mousedown', close)
      window.removeEventListener('keydown', close)
    }
  }, [open])
  return (
    <div className="launcher" ref={ref}>
      <button className="button cta" aria-expanded={open} aria-haspopup="menu" onClick={() => setOpen(!open)} disabled={kids.length === 0}>
        Kirim frasa bersuara <Icon name="wave" size={18} />
      </button>
      {open && (
        <div className="menu" role="menu">
          <p>Untuk siapa?</p>
          {kids.map((c) => (
            <a key={c.child_id} role="menuitem" href={href.d5(c.child_id)} onClick={() => setOpen(false)}>
              <Avatar name={c.nickname ?? '?'} size={28} tone={toneFor(c.child_id)} />
              {c.nickname ?? '(tanpa nama)'}
            </a>
          ))}
        </div>
      )}
    </div>
  )
}
