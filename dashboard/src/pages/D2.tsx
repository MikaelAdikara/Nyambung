import { href } from '../route'
import { useApp, useAsync } from '../ctx'
import { fmtDate, pct, relTime, wordLabel } from '../format'
import { attentionSignals } from '../attention'
import { BarChart, ErrorBox, Loading, StatCard, TrendBadge, WordIcon } from '../ui'

const HOURS = Array.from({ length: 24 }, (_, h) => String(h).padStart(2, '0'))
const WEEKS = ['5 pk lalu', '4 pk lalu', '3 pk lalu', '2 pk lalu', 'pekan lalu', 'pekan ini']

// D2 ringkasan seorang anak (jalur 4 §4.4, teks 02 §7)
export function D2({ childId }: { childId: string }) {
  const { source, vocab } = useApp()
  const [res] = useAsync(async () => {
    const [summary, targets] = await Promise.all([source.summary(childId, 7), source.targets(childId)])
    return { summary, targets }
  }, [source, childId])

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <a href={href.d1()}>← Keluarga binaan</a>
        <ErrorBox error={res.error} />
      </section>
    )

  const s = res.data.summary
  const accepted = new Set(res.data.targets.filter((t) => t.status === 'diterima').flatMap((t) => t.words))
  const diff = s.unique_words - s.unique_words_prev
  const signals = attentionSignals(s, res.data.targets, vocab)
  const acceptedTargets = res.data.targets.filter((t) => t.status === 'diterima')

  return (
    <section>
      <a href={href.d1()}>← Keluarga binaan</a>
      <h1>
        {s.nickname ?? '(tanpa nama)'}, {s.age_years ?? '–'} tahun · rutinitas {s.routine ?? '–'}
      </h1>
      <p className="muted meta">
        Arah 3 pekan: <TrendBadge trend={s.trend_3w} /> · Sinkron terakhir: {relTime(s.last_sync)} ·{' '}
        {s.linked_weeks === null ? 'Belum tertaut' : `Tertaut ${s.linked_weeks} pekan`}
        {s.pending_targets > 0 && ` · ${s.pending_targets} usulan menunggu jawaban keluarga`}
      </p>

      {signals.length > 0 && (
        <div className="card attention">
          <h2>Perlu diperiksa</h2>
          <ul>
            {signals.map((x) => (
              <li key={x}>{x}</li>
            ))}
          </ul>
          <p className="muted">Ditandai oleh aturan tetap, bukan kesimpulan klinis. Penafsirannya tetap di tangan terapis.</p>
        </div>
      )}

      <div className="stats">
        <StatCard
          label="Kata berbeda pekan ini"
          value={s.unique_words}
          sub={`pekan lalu ${s.unique_words_prev} (${diff > 0 ? '+' : ''}${diff})`}
          accent="teal"
        />
        <StatCard
          label="Ketukan anak tanpa contoh ≤ 60 dtk"
          value={pct(s.spontaneous_ratio)}
          sub={`${s.spontaneous_taps} dari ${s.child_taps} ketukan anak`}
          accent="teal"
        />
        <StatCard
          label="Hari misi selesai"
          value={`${s.missions_done} dari ${s.missions_total}`}
          sub={`belum sempat ${s.missions_skipped} hari`}
          accent="coral"
        />
        <StatCard
          label="Total ketukan pekan ini"
          value={s.total_taps}
          sub={`${s.child_taps} ketukan anak, termasuk ${s.parent_taps} ketukan orang tua saat modeling`}
        />
      </div>
      <p className="note">
        <strong>Angka ini pola pemakaian, bukan ukuran kemampuan anak.</strong> "Tanpa contoh" hanya berarti tidak ada
        ketukan pendamping dalam 60 detik sebelumnya; aplikasi tidak merekam suara, jadi tidak tahu apakah anak dipancing
        secara lisan. Angka ini juga bergantung pada giliran yang dipilih pendamping.
      </p>

      <div className="grid-2">
        <div className="card">
          <BarChart title="Kata berbeda per pekan" values={s.weekly_unique_6w} labels={WEEKS} />
        </div>
        <div className="card">
          <BarChart title="Jam pemakaian" values={s.hour_histogram} labels={HOURS} labelEvery={3} color="var(--navy)" />
        </div>
      </div>

      <div className="card">
        <h2>Kata yang paling sering</h2>
        <p className="muted">
          Hitungan ketukan anak dalam 7 hari terakhir ({s.child_taps} ketukan anak, {s.parent_taps} ketukan pendamping tidak
          dihitung di sini).
        </p>
        {s.top_words.length === 0 ? (
          <p className="muted">Belum ada ketukan anak dalam 7 hari terakhir.</p>
        ) : (
          <ol className="top-words">
            {s.top_words.map((w) => (
              <li key={w.word}>
                <WordIcon id={w.word} />
                <span className="top-word-label">{wordLabel(vocab, w.word)}</span>
                {accepted.has(w.word) && <span className="badge badge-target">target diterima</span>}
                <span className="top-word-count">{w.count}×</span>
              </li>
            ))}
          </ol>
        )}
      </div>

      {acceptedTargets.length > 0 && (
        <div className="card">
          <h2>Target yang diterima keluarga</h2>
          <ul className="targets">
            {acceptedTargets.map((t) => (
              <li key={t.target_id}>
                <strong>{t.words.map((w) => wordLabel(vocab, w)).join(', ')}</strong> · diterima {fmtDate(t.answered_at)} · dipakai{' '}
                {t.used_count_since_accept} kali sejak diterima (anak dan pendamping)
              </li>
            ))}
          </ul>
        </div>
      )}

      <div className="card must-read">
        <h2>Catatan wajib dibaca</h2>
        <p>
          Seluruh angka di halaman ini lahir otomatis dari ketukan simbol di aplikasi keluarga, bukan dari ingatan atau isian
          orang tua. Yang tidak ada di sini: audio ruangan, video, dan lokasi, karena ketiganya tidak pernah direkam. Foto
          kartu personal juga tidak pernah dikirim; yang terlihat hanya labelnya, misalnya GELAS.
        </p>
      </div>

      <nav className="actions">
        <a className="button" href={href.d3(childId)}>
          Usulkan kata
        </a>
        <a className="button secondary" href={href.d4(childId)}>
          Catatan sesi
        </a>
      </nav>
    </section>
  )
}
