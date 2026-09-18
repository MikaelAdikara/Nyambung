import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useApp, useAsync } from '../ctx'
import { fmtDate } from '../format'
import { Icon } from '../icons'
import type { PhraseOut, PhraseVoice } from '../types'
import { ChildHeader, ErrorBox, Loading, Panel, StatusPill } from '../ui'
import { audioPreviewError } from '../audio'

const MAX_TEXT = 60
const VOICES: { id: PhraseVoice; label: string; hint: string }[] = [
  { id: 'cowo', label: 'Suara papan cowok', hint: 'Sama dengan suara papan anak' },
  { id: 'cewe', label: 'Suara papan cewek', hint: 'Sama dengan suara papan anak' },
  { id: 'keluarga', label: 'Suara keluarga', hint: 'Tiruan suara orang tua' },
]
const VOICE_LABEL: Record<PhraseVoice, string> = { cowo: 'Suara papan (cowok)', cewe: 'Suara papan (cewek)', keluarga: 'Suara keluarga' }

// D5 Frasa audio: terapis/guru menulis kalimat pendek, server membuat MP3 sekali, keluarga menerimanya
// sebagai usulan. Setelah diterima, kartu teks + audio diputar luring di papan anak.
export function D5({ childId }: { childId: string }) {
  const { source } = useApp()
  const [res, reload] = useAsync(async () => {
    const [overview, phrases, voice] = await Promise.all([source.children(), source.phrases(childId), source.voiceStatus(childId)])
    const child = overview.children.find((c) => c.child_id === childId)
    return { child, phrases, voice }
  }, [source, childId])

  const [text, setText] = useState('')
  const [voice, setVoice] = useState<PhraseVoice>('cowo')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [sent, setSent] = useState<PhraseOut | null>(null)
  const player = usePlayer()

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <ChildHeader childId={childId} page="D5" name={null} />
        <ErrorBox error={res.error} />
      </section>
    )

  const { child, phrases, voice: status } = res.data
  const demo = source.kind === 'demo'
  const name = child?.nickname ?? null
  const clean = text.trim().replace(/\s+/g, ' ')
  const voiceReady = voice === 'keluarga' ? status.clone_active : status.openai
  const pending = phrases.filter((p) => p.status === 'usulan').length

  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (demo || !clean || !voiceReady) return
    setBusy(true)
    setError(null)
    setSent(null)
    try {
      const p = await source.createPhrase(childId, clean, voice)
      setSent(p)
      setText('')
      void player.play(childId, p.phrase_id)
      reload()
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <section>
      <ChildHeader
        childId={childId}
        page="D5"
        name={name}
        meta={
          <>
            {phrases.length} frasa audio · {pending} menunggu keputusan keluarga
          </>
        }
      />

      <div className="grid-main">
        <Panel title="Buat frasa audio" icon="wave" tone="lavender">
          <form className="phrase-form" onSubmit={submit}>
            <label htmlFor="phrase">Kalimat pendek untuk {name ?? 'anak'}</label>
            <input
              id="phrase"
              className="phrase-input"
              maxLength={MAX_TEXT}
              value={text}
              onChange={(e) => setText(e.target.value)}
              placeholder="mis. Aku mau istirahat"
              disabled={demo}
              autoComplete="off"
            />
            <div className="counter">
              {text.length}/{MAX_TEXT}
            </div>

            <fieldset className="voices">
              <legend>Suara</legend>
              {VOICES.map((v) => {
                const off = v.id === 'keluarga' ? !status.clone_active : !status.openai
                return (
                  <label key={v.id} className={`voice${voice === v.id ? ' on' : ''}${off ? ' off' : ''}`}>
                    <input type="radio" name="voice" value={v.id} checked={voice === v.id} onChange={() => setVoice(v.id)} disabled={demo} />
                    <Icon name={v.id === 'keluarga' ? 'mic' : 'wave'} size={20} />
                    <span>
                      <strong>{v.label}</strong>
                      <span>{off ? (v.id === 'keluarga' ? 'Belum diaktifkan orang tua' : 'Belum aktif di server') : v.hint}</span>
                    </span>
                  </label>
                )
              })}
            </fieldset>

            <div className="actions">
              <button className="button" type="submit" disabled={demo || busy || !clean || !voiceReady}>
                {busy ? 'Membuat MP3…' : 'Buat frasa audio'}
              </button>
            </div>
            <p className="muted small">
              Server membuat satu MP3. Visual kartunya tetap teks dengan ikon audio—bukan gambar AI. Setelah keluarga memilih
              “Tambah ke papan”, MP3 tersimpan di HP dan dapat diputar tanpa internet.
            </p>
            {demo && <p className="muted small">Mode demo: frasa tidak dibuat. Masuk sebagai terapis untuk mengirim.</p>}
            {error && <p className="form-error">{error}</p>}
            {sent && (
              <p className="ok" role="status">
                “{sent.text}” terkirim. Keluarga dapat memilih “Tambah ke papan” atau “Tidak dipakai” saat HP tersambung.
              </p>
            )}
          </form>
        </Panel>

        <Panel title="Suara keluarga" icon="mic" tone="coral">
          {status.clone_active ? (
            <div className="clone on">
              <Icon name="check" size={22} />
              <p>
                Aktif, disetujui oleh <strong>{status.clone_consent_by}</strong> pada {fmtDate(status.clone_consent_at)}. Frasa dengan suara
                keluarga terdengar seperti suara orang tua {name ?? 'anak'}.
              </p>
            </div>
          ) : (
            <div className="clone">
              <Icon name="mic" size={22} />
              <p>
                Belum aktif. Hanya orang tua yang bisa mengaktifkannya dari aplikasi (Atur → Frasa audio → Suara keluarga), dengan
                persetujuan dan rekaman suaranya sendiri.
              </p>
            </div>
          )}
          <ul className="checks">
            <li className={status.openai ? 'yes' : 'no'}>
              <Icon name={status.openai ? 'check' : 'clock'} size={16} /> Suara papan untuk frasa {status.openai ? 'aktif' : 'belum aktif'} di server
            </li>
            <li className={status.elevenlabs ? 'yes' : 'no'}>
              <Icon name={status.elevenlabs ? 'check' : 'clock'} size={16} /> Layanan tiruan suara {status.elevenlabs ? 'aktif' : 'belum aktif'}{' '}
              di server
            </li>
          </ul>
          <p className="panel-foot">
            Rekaman contoh orang tua diteruskan ke layanan suara tanpa disimpan server. Orang tua bisa mencabut kapan saja.
          </p>
        </Panel>
      </div>

      <Panel title="Riwayat frasa audio" icon="note">
        {phrases.length === 0 ? (
          <p className="panel-empty">Belum ada frasa untuk {name ?? 'anak ini'}.</p>
        ) : (
          <div className="table-wrap">
            <table className="table">
              <thead>
                <tr>
                  <th>Frasa</th>
                  <th>Suara</th>
                  <th>Dari</th>
                  <th>Status</th>
                  <th className="num">Dipakai</th>
                  <th>Tanggal</th>
                  <th>
                    <span className="sr-only">Putar</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {phrases.map((p) => (
                  <tr key={p.phrase_id}>
                    <td>
                      <strong>“{p.text}”</strong>
                    </td>
                    <td>{VOICE_LABEL[p.voice]}</td>
                    <td>{p.created_by === 'keluarga' ? 'Keluarga' : p.created_by}</td>
                    <td>
                      <StatusPill status={p.status} />
                    </td>
                    <td className="num">{p.used_count}×</td>
                    <td>{fmtDate(p.created_at)}</td>
                    <td>
                      <button
                        type="button"
                        className="icon-button"
                        onClick={() => void player.play(childId, p.phrase_id)}
                        disabled={demo}
                        title={demo ? 'Mode demo tidak punya klip suara' : 'Putar'}
                        aria-label={`Putar “${p.text}”`}
                      >
                        <Icon name={player.playing === p.phrase_id ? 'pause' : 'play'} size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
        <p className="panel-foot">“Dipakai” = ketukan kartu frasa di papan (anak dan pendamping) yang sudah tersinkron.</p>
        {player.error && (
          <p className="form-error" role="alert">
            {player.error}
          </p>
        )}
      </Panel>
    </section>
  )
}

// Satu pemutar untuk halaman ini. Klip diambil dengan Bearer, disimpan sebagai URL objek, dan dilepas saat pergi.
function usePlayer() {
  const { source } = useApp()
  const audio = useRef<HTMLAudioElement | null>(null)
  const urls = useRef(new Map<string, string>())
  const [playing, setPlaying] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const cache = urls.current
    return () => {
      audio.current?.pause()
      for (const u of cache.values()) URL.revokeObjectURL(u)
      cache.clear()
    }
  }, [])

  const play = async (childId: string, phraseId: string) => {
    setError(null)
    if (playing === phraseId) {
      audio.current?.pause()
      setPlaying(null)
      return
    }
    let url = urls.current.get(phraseId)
    if (!url) {
      const fetched = await source.phraseAudio(childId, phraseId)
      if (!fetched) {
        setError(audioPreviewError(source.kind))
        return
      }
      url = fetched
      urls.current.set(phraseId, url)
    }
    audio.current?.pause()
    const a = new Audio(url)
    audio.current = a
    a.onended = () => setPlaying(null)
    a.onerror = () => {
      setPlaying(null)
      setError(audioPreviewError(source.kind))
    }
    setPlaying(phraseId)
    try {
      await a.play()
    } catch {
      setPlaying(null)
      setError(audioPreviewError(source.kind))
    }
  }
  return { play, playing, error }
}
