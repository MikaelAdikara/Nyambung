import { useState, type FormEvent } from 'react'
import { useApp, useAsync } from '../ctx'
import { fmtDate, pct, sessionText, wordLabel } from '../format'
import type { SessionNote, Summary, TargetOut, VocabWord } from '../types'
import { ChildHeader, ErrorBox, Loading } from '../ui'

const MAX_NOTE = 4000
const MAX_FAMILY = 1000

const today = () => {
  const d = new Date()
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
}

// Tanggal lokal tanpa zona (YYYY-MM-DD atau YYYY-MM-DDTHH:MM) → "23 September, 15.30"
export function fmtLocal(s: string | null): string {
  if (!s) return '–'
  const [date, time] = s.split('T')
  const [y, m, d] = date.split('-').map(Number)
  const label = new Date(y, m - 1, d).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', ...(time ? {} : { year: 'numeric' }) })
  return time ? `${label}, ${time.replace(':', '.')}` : label
}

// "Sebelum sesi, dari data rumah": butir otomatis dari ringkasan 7 hari, supaya waktu sesi tidak habis untuk
// menggali keadaan di rumah dari ingatan orang tua. Hanya pola pemakaian, bukan penilaian.
export function homeBullets(s: Summary, targets: TargetOut[], vocab: Map<string, VocabWord>): string[] {
  const out: string[] = []
  const diff = s.unique_words - s.unique_words_prev
  out.push(
    diff === 0
      ? `Kata berbeda tetap ${s.unique_words}, sama dengan pekan sebelumnya.`
      : `Kata berbeda ${diff > 0 ? 'naik' : 'turun'} dari ${s.unique_words_prev} ke ${s.unique_words} dibanding pekan sebelumnya.`,
  )
  const accepted = targets.find((t) => t.status === 'diterima')
  if (accepted) {
    const words = accepted.words.map((w) => wordLabel(vocab, w)).join(', ')
    out.push(`${words} dipakai ${accepted.used_count_since_accept} kali sejak diterima keluarga (anak dan pendamping).`)
  } else if (s.top_words.length > 0) {
    const top = s.top_words.slice(0, 3).map((w) => `${wordLabel(vocab, w.word)} ${w.count}×`)
    out.push(`Kata terbanyak: ${top.join(', ')}.`)
  }
  const total = s.hour_histogram.reduce((a, b) => a + b, 0)
  if (total > 0) {
    // Jendela dua jam dengan ketukan anak terbanyak
    let best = 0
    for (let h = 1; h < 23; h++) if (s.hour_histogram[h] + s.hour_histogram[h + 1] > s.hour_histogram[best] + s.hour_histogram[best + 1]) best = h
    const share = Math.round(((s.hour_histogram[best] + s.hour_histogram[best + 1]) / total) * 100)
    out.push(`Pemakaian menumpuk jam ${best} sampai ${best + 1} (${share}% ketukan anak).`)
  }
  out.push(`${pct(s.spontaneous_ratio)} ketukan anak tanpa contoh pendamping dalam 60 detik sebelumnya.`)
  out.push(`Misi modeling selesai ${s.missions_done} dari ${s.missions_total} hari.`)
  return out
}

function familyDraft(focus: string, next: string): string {
  const parts = []
  if (focus.trim()) parts.push(`Fokus pekan depan: ${focus.trim()}.`)
  if (next) parts.push(`Sesi berikutnya ${fmtLocal(next)}.`)
  parts.push('Terima kasih sudah memodelkan di rumah.')
  return parts.join(' ')
}

// D4 catatan sesi (dibangun penuh): butir otomatis dari data rumah, catatan terapis yang tersimpan di server,
// dan ringkasan yang bisa dikirim ke keluarga. Catatan terapis sendiri tidak pernah terlihat oleh keluarga.
export function D4({ childId }: { childId: string }) {
  const { source, vocab } = useApp()
  const [res, reload] = useAsync(async () => {
    const [summary, targets, sessions] = await Promise.all([source.summary(childId, 7), source.targets(childId), source.sessions(childId)])
    return { summary, targets, sessions }
  }, [source, childId])

  const [editing, setEditing] = useState<string | null>(null)
  const [date, setDate] = useState(today)
  const [note, setNote] = useState('')
  const [focus, setFocus] = useState('')
  const [next, setNext] = useState('')
  const [family, setFamily] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [done, setDone] = useState<string | null>(null)
  const [copied, setCopied] = useState(false)

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <ChildHeader childId={childId} page="D4" name={null} />
        <ErrorBox error={res.error} />
      </section>
    )

  const s = res.data.summary
  const name = s.nickname ?? 'anak'
  const demo = source.kind === 'demo'
  const bullets = homeBullets(s, res.data.targets, vocab)

  const load = (n: SessionNote | null) => {
    setEditing(n?.note_id ?? null)
    setDate(n?.session_date ?? today())
    setNote(n?.note ?? '')
    setFocus(n?.focus ?? '')
    setNext(n?.next_session ?? '')
    setFamily(null)
    setError(null)
    setDone(null)
  }

  const body = () => ({
    session_date: date,
    note: note.trim(),
    ...(focus.trim() ? { focus: focus.trim() } : {}),
    ...(next ? { next_session: next } : {}),
  })

  const save = async (e?: FormEvent): Promise<SessionNote | null> => {
    e?.preventDefault()
    if (demo || !note.trim()) return null
    setBusy(true)
    setError(null)
    try {
      const saved = await source.saveSession(childId, body(), editing ?? undefined)
      setEditing(saved.note_id)
      setDone('Catatan tersimpan. Hanya kamu yang bisa membacanya.')
      reload()
      return saved
    } catch (err) {
      setError((err as Error).message)
      return null
    } finally {
      setBusy(false)
    }
  }

  const share = async () => {
    if (family === null || !family.trim()) return
    const saved = await save()
    if (!saved) return
    setBusy(true)
    try {
      await source.shareSession(childId, saved.note_id, family.trim())
      setFamily(null)
      setDone('Ringkasan dikirim. Keluarga menerimanya di tab Terapis saat HP tersambung. Catatan sesimu tidak ikut terkirim.')
      reload()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(sessionText(s, vocab))
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopied(false)
    }
  }

  return (
    <section>
      <ChildHeader childId={childId} page="D4" name={s.nickname} meta="Catatan sesi tatap muka. Catatan ini milik terapis dan tidak terlihat oleh keluarga." />

      <div className="grid-2 session-grid">
        <div className="card">
          <h2>Sebelum sesi, dari data rumah</h2>
          <ul className="home-bullets">
            {bullets.map((b) => (
              <li key={b}>{b}</li>
            ))}
          </ul>
          <p className="note">
            Butir ini tersusun sendiri sebelum sesi dimulai, jadi waktu sesi tidak habis untuk menggali keadaan di rumah dari
            ingatan orang tua. Angka ini pola pemakaian, bukan ukuran kemampuan anak.
          </p>
          <div className="actions">
            <button className="button secondary" onClick={copy}>
              Salin ringkasan
            </button>
            {copied && (
              <span className="ok" role="status">
                Tersalin.
              </span>
            )}
          </div>
        </div>

        <form className="card session-form" onSubmit={save}>
          <h2>{editing ? `Ubah catatan sesi ${fmtLocal(date)}` : `Catatan sesi ${fmtLocal(date)}`}</h2>
          <label htmlFor="date">Tanggal sesi</label>
          <input id="date" type="date" value={date} max={today()} onChange={(e) => setDate(e.target.value)} disabled={demo} />
          <label htmlFor="note">Catatan terapis</label>
          <textarea
            id="note"
            rows={6}
            maxLength={MAX_NOTE}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            disabled={demo}
            placeholder="Apa yang terlihat di sesi, apa yang perlu dicoba keluarga."
          />
          <div className="field-pair">
            <div>
              <label htmlFor="focus">Fokus pekan depan</label>
              <input id="focus" maxLength={200} value={focus} onChange={(e) => setFocus(e.target.value)} disabled={demo} placeholder="mis. jeda tunggu 10 detik" />
            </div>
            <div>
              <label htmlFor="next">Sesi berikutnya</label>
              <input id="next" type="datetime-local" value={next} onChange={(e) => setNext(e.target.value)} disabled={demo} />
            </div>
          </div>
          <div className="actions">
            <button className="button" type="submit" disabled={demo || busy || !note.trim()}>
              Simpan catatan
            </button>
            <button
              className="button secondary"
              type="button"
              disabled={demo || busy || !note.trim()}
              onClick={() => setFamily(family === null ? familyDraft(focus, next) : null)}
            >
              Kirim ringkasan ke keluarga
            </button>
            {editing && (
              <button className="link" type="button" onClick={() => load(null)}>
                Catatan baru
              </button>
            )}
          </div>
          {family !== null && (
            <div className="family-share">
              <label htmlFor="family">Yang diterima keluarga (catatan terapis di atas tidak ikut terkirim)</label>
              <textarea id="family" rows={3} maxLength={MAX_FAMILY} value={family} onChange={(e) => setFamily(e.target.value)} />
              <div className="actions">
                <button className="button" type="button" disabled={busy || !family.trim()} onClick={share}>
                  Kirim ke keluarga
                </button>
                <button className="link" type="button" onClick={() => setFamily(null)}>
                  Batal
                </button>
              </div>
            </div>
          )}
          {demo && <p className="muted small">Mode demo: catatan tidak disimpan dan tidak dikirim. Masuk sebagai terapis untuk menulis.</p>}
          {error && <p className="form-error">{error}</p>}
          {done && (
            <p className="ok" role="status">
              {done}
            </p>
          )}
        </form>
      </div>

      <div className="card">
        <h2>Sesi sebelumnya</h2>
        {res.data.sessions.length === 0 ? (
          <p className="muted">Belum ada catatan sesi untuk {name}.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Tanggal</th>
                  <th>Catatan</th>
                  <th>Fokus</th>
                  <th>Keluarga</th>
                  <th />
                </tr>
              </thead>
              <tbody>
                {res.data.sessions.map((n) => (
                  <tr key={n.note_id} className={n.note_id === editing ? 'row-editing' : undefined}>
                    <td>
                      <strong>{fmtLocal(n.session_date)}</strong>
                    </td>
                    <td>
                      <div className="clamp">{n.note}</div>
                    </td>
                    <td>{n.focus ?? '–'}</td>
                    <td>{n.shared_at ? `ringkasan dikirim ${fmtDate(n.shared_at)}` : <span className="muted">hanya terapis</span>}</td>
                    <td>
                      {!demo && (
                        <button className="link" type="button" onClick={() => load(n)}>
                          Ubah
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </section>
  )
}
