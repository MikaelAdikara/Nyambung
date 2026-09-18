import { useEffect, useMemo, useState, type FormEvent } from 'react'
import type { Routine } from '../types'
import { useApp, useAsync } from '../ctx'
import { fmtDate, wordLabel } from '../format'
import { ChildHeader, ErrorBox, Loading, StatusPill, WordIcon } from '../ui'

const MAX_WORDS = 5
// Saran rancangan: paling banyak tiga kata per pekan supaya keluarga tidak kewalahan
const SUGGESTED_WORDS = 3
const MAX_NOTE = 600

// Draf usulan per anak, hanya di browser ini (localStorage bisa diblokir: gagal diam-diam)
interface Draft {
  picked: string[]
  note: string
  routine: Routine | ''
}
const draftKey = (childId: string) => `nyambung.draft.${childId}`

function readDraft(childId: string): Draft | null {
  try {
    const raw = localStorage.getItem(draftKey(childId))
    return raw ? (JSON.parse(raw) as Draft) : null
  } catch {
    return null
  }
}

function writeDraft(childId: string, draft: Draft | null): boolean {
  try {
    if (draft) localStorage.setItem(draftKey(childId), JSON.stringify(draft))
    else localStorage.removeItem(draftKey(childId))
    return true
  } catch {
    return false
  }
}

// D3 usulan target (jalur 4 §4.5, teks 02 §7)
export function D3({ childId }: { childId: string }) {
  const { source, vocab, vocabList } = useApp()
  const [res, reload] = useAsync(async () => {
    const [summary, targets] = await Promise.all([source.summary(childId, 7), source.targets(childId)])
    return { summary, targets }
  }, [source, childId])

  const [picked, setPicked] = useState<string[]>([])
  const [query, setQuery] = useState('')
  const [note, setNote] = useState('')
  const [routine, setRoutine] = useState<Routine | ''>('')
  const [sending, setSending] = useState(false)
  const [sendError, setSendError] = useState<string | null>(null)
  const [sent, setSent] = useState<string | null>(null)
  const [draftNote, setDraftNote] = useState<string | null>(null)

  // Muat draf tersimpan untuk anak ini
  useEffect(() => {
    const d = readDraft(childId)
    if (!d) return
    setPicked(d.picked.slice(0, MAX_WORDS))
    setNote(d.note)
    setRoutine(d.routine)
    setDraftNote('Draf tersimpan dimuat.')
  }, [childId])

  const saveDraft = () => {
    const ok = writeDraft(childId, { picked, note, routine })
    setDraftNote(ok ? 'Draf tersimpan di browser ini. Belum terkirim ke keluarga.' : 'Browser menolak menyimpan draf.')
  }

  const shown = useMemo(() => {
    const q = query.trim().toLowerCase()
    const list = [...vocabList].sort((a, b) => a.page - b.page || a.position_index - b.position_index)
    return q ? list.filter((w) => w.word_id.includes(q) || w.label_display.toLowerCase().includes(q)) : list
  }, [vocabList, query])

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <ChildHeader childId={childId} page="D3" name={null} />
        <ErrorBox error={res.error} />
      </section>
    )

  const s = res.data.summary
  const demo = source.kind === 'demo'

  const toggle = (id: string) =>
    setPicked((p) => (p.includes(id) ? p.filter((x) => x !== id) : p.length < MAX_WORDS ? [...p, id] : p))

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (demo || picked.length === 0) return
    setSending(true)
    setSendError(null)
    try {
      const t = await source.createTarget(childId, {
        words: picked,
        ...(note.trim() ? { note: note.trim() } : {}),
        ...(s.linked_weeks !== null ? { week_index: s.linked_weeks + 1 } : {}),
        ...(routine ? { routine } : {}),
      })
      setSent(t.words.map((w) => wordLabel(vocab, w)).join(', '))
      writeDraft(childId, null)
      setDraftNote(null)
      setPicked([])
      setNote('')
      setRoutine('')
      reload()
    } catch (err) {
      setSendError((err as Error).message)
    } finally {
      setSending(false)
    }
  }

  return (
    <section>
      <ChildHeader
        childId={childId}
        page="D3"
        name={s.nickname}
        meta="Pilih kata yang akan bergilir sebagai misi harian setelah diterima keluarga. Keluarga boleh tidak memakainya tanpa alasan."
      />

      <form className="card" onSubmit={submit}>
        <div className="picked" aria-live="polite">
          <strong>
            Dipilih {picked.length} dari {MAX_WORDS}:
          </strong>{' '}
          {picked.length === 0 ? (
            <span className="muted">belum ada</span>
          ) : (
            picked.map((id) => (
              <button type="button" key={id} className="chip" onClick={() => toggle(id)} title="Batalkan pilihan">
                {wordLabel(vocab, id)} ×
              </button>
            ))
          )}
        </div>

        {picked.length > SUGGESTED_WORDS && (
          <p className="muted small">Disarankan paling banyak {SUGGESTED_WORDS} kata per pekan supaya keluarga tidak kewalahan.</p>
        )}
        <p className="muted small">Angka "dipakai" = ketukan anak 7 hari terakhir.</p>

        <label htmlFor="q">Cari kata</label>
        <input id="q" type="search" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="mis. berhenti" />

        <div className="word-grid" role="group" aria-label="120 kata">
          {shown.map((w) => {
            const on = picked.includes(w.word_id)
            const full = !on && picked.length >= MAX_WORDS
            const used = s.word_counts[w.word_id] ?? 0
            return (
              <button
                type="button"
                key={w.word_id}
                className={`word-cell${on ? ' on' : ''}`}
                aria-pressed={on}
                disabled={full}
                onClick={() => toggle(w.word_id)}
              >
                <WordIcon id={w.word_id} size={48} />
                <span>{w.label_display}</span>
                <span className={`word-use${used ? '' : ' none'}`}>{used ? `dipakai ${used} kali` : 'belum dipakai'}</span>
              </button>
            )
          })}
          {shown.length === 0 && <p className="muted">Tidak ada kata yang cocok.</p>}
        </div>

        <label htmlFor="note">Catatan untuk keluarga (satu kalimat)</label>
        <textarea id="note" rows={2} maxLength={MAX_NOTE} value={note} onChange={(e) => setNote(e.target.value)} />
        <div className="muted small">
          {note.length}/{MAX_NOTE}
        </div>

        <label htmlFor="routine">Rutinitas (opsional)</label>
        <select id="routine" value={routine} onChange={(e) => setRoutine(e.target.value as Routine | '')}>
          <option value="">–</option>
          <option value="makan">makan</option>
          <option value="mandi">mandi</option>
          <option value="main">main</option>
        </select>

        <div className="actions">
          <button className="button" type="submit" disabled={demo || sending || picked.length === 0}>
            Kirim target kata
          </button>
          <button className="button secondary" type="button" onClick={saveDraft} disabled={picked.length === 0 && !note.trim()}>
            Simpan draf
          </button>
          {draftNote && (
            <span className="muted small" role="status">
              {draftNote}
            </span>
          )}
        </div>
        {demo && <p className="muted small">Mode demo: target kata tidak dikirim ke server. Masuk sebagai terapis untuk mengirim.</p>}
        {sendError && <p className="form-error">{sendError}</p>}
        {sent && (
          <p className="ok" role="status">
            Target {sent} terkirim. Keluarga dapat memilih “Terima sebagai misi” atau “Tidak dipakai” saat perangkat tersambung.
          </p>
        )}
      </form>

      <div className="card">
        <h2>Riwayat target kata</h2>
        {res.data.targets.length === 0 ? (
          <p className="muted">Belum ada target kata untuk anak ini.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Kata</th>
                  <th>Status</th>
                  <th>Tanggal</th>
                  <th>Pemakaian</th>
                </tr>
              </thead>
              <tbody>
                {res.data.targets.map((t) => (
                  <tr key={t.target_id}>
                    <td>
                      {t.words.map((w) => wordLabel(vocab, w)).join(', ')}
                      {t.note && <div className="muted small">{t.note}</div>}
                    </td>
                    <td>
                      <StatusPill status={t.status} />
                    </td>
                    <td>{fmtDate(t.answered_at ?? t.created_at)}</td>
                    <td>{t.status === 'diterima' ? `dipakai ${t.used_count_since_accept} kali sejak diterima` : '–'}</td>
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
