import { href } from '../route'
import { Icon } from '../icons'
import { useApp, useAsync } from '../ctx'
import { fmtDate, pct, relTime, wordLabel } from '../format'
import { attentionSignals } from '../attention'
import { BarChart, ChildHeader, ErrorBox, Loading, Panel, StatCard, TrendBadge, WordIcon } from '../ui'
import type { MissionDay, VocabWord } from '../types'

const HOURS = Array.from({ length: 24 }, (_, h) => String(h).padStart(2, '0'))
const WEEKS = ['5 pk lalu', '4 pk lalu', '3 pk lalu', '2 pk lalu', 'pekan lalu', 'pekan ini']

// D2 ringkasan seorang anak (jalur 4 §4.4, teks 02 §7)
export function D2({ childId }: { childId: string }) {
  const { source, vocab } = useApp()
  const [res] = useAsync(async () => {
    const [summary, targets, missions] = await Promise.all([source.summary(childId, 7), source.targets(childId), source.missions(childId, 14)])
    return { summary, targets, missions }
  }, [source, childId])

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <ChildHeader childId={childId} page="D2" name={null} />
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
      <ChildHeader
        childId={childId}
        page="D2"
        name={s.nickname}
        meta={
          <>
            {s.age_years ?? '–'} tahun · rutinitas {s.routine ?? '–'} · arah 3 pekan <TrendBadge trend={s.trend_3w} /> · sinkron{' '}
            {relTime(s.last_sync)} · {s.linked_weeks === null ? 'belum tertaut' : `tertaut ${s.linked_weeks} pekan`}
            {s.pending_targets > 0 && ` · ${s.pending_targets} usulan menunggu jawaban keluarga`}
          </>
        }
      />

      {signals.length > 0 && (
        <div className="card attention">
          <h2>
            <Icon name="alert" size={18} /> Perlu diperiksa
          </h2>
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
          icon="chart"
          label="Kata berbeda pekan ini"
          value={s.unique_words}
          sub={`pekan lalu ${s.unique_words_prev} (${diff > 0 ? '+' : ''}${diff})`}
          accent="teal"
        />
        <StatCard
          icon="sync"
          label="Ketukan anak tanpa contoh ≤ 60 dtk"
          value={pct(s.spontaneous_ratio)}
          sub={`${s.spontaneous_taps} dari ${s.child_taps} ketukan anak`}
          accent="teal"
        />
        <StatCard
          icon="calendar"
          label="Hari misi selesai"
          value={`${s.missions_done} dari ${s.missions_total}`}
          sub={`belum sempat ${s.missions_skipped} hari`}
          accent="coral"
        />
        <StatCard
          icon="target"
          accent="lavender"
          label="Total ketukan pekan ini"
          value={s.total_taps}
          sub={`${s.child_taps} ketukan anak, termasuk ${s.parent_taps} ketukan orang tua saat modeling`}
        />
      </div>
      <MissionPanel days={res.data.missions} vocab={vocab} />

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

      <Panel title="Kata yang paling sering" icon="target" className="section-gap">
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
      </Panel>

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
        <a className="button secondary" href={href.d5(childId)}>
          Kirim frasa bersuara
        </a>
        <a className="button secondary" href={href.d4(childId)}>
          Catatan sesi
        </a>
      </nav>
    </section>
  )
}

// Misi harian: kata, asalnya, dan hasil per hari. Aturan generator ada di aplikasi (mission_rules.dart):
// urutan kata inti per rutinitas, diganti usulan terapis yang diterima keluarga. Semua dari peristiwa mentah.
function MissionPanel({ days, vocab }: { days: MissionDay[]; vocab: Map<string, VocabWord> }) {
  const latest = days[0]
  const byDate = new Map<string, MissionDay>()
  // Satu sel per hari: misi yang dikonfirmasi didahulukan bila hari itu punya lebih dari satu misi.
  for (const d of days) if (!byDate.has(d.date) || (d.status && !byDate.get(d.date)?.status)) byDate.set(d.date, d)
  const today = new Date()
  const cells = Array.from({ length: 14 }, (_, i) => {
    const d = new Date(today.getFullYear(), today.getMonth(), today.getDate() - (13 - i))
    const iso = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    return { iso, d, m: byDate.get(iso) }
  })
  return (
    <Panel title="Misi harian orang tua" icon="calendar" className="section-gap">
      {latest ? (
        <div className="mission-now">
          {latest.word && <WordIcon id={latest.word} size={56} />}
          <div>
            <strong>
              {latest.word ? wordLabel(vocab, latest.word) : 'kata tidak tercatat'}
              {latest.week !== null && ` · pekan ke-${latest.week}`}
            </strong>
            <span>
              {latest.source === 'terapis'
                ? 'Dari usulanmu yang diterima keluarga. Berlaku sampai ada usulan baru.'
                : 'Urutan bawaan: 12 kata inti, mulai dari fungsi meminta, satu kata per pekan sesuai rutinitas keluarga.'}
            </span>
          </div>
        </div>
      ) : (
        <p className="panel-empty">Belum ada misi yang tercatat dalam 14 hari terakhir.</p>
      )}
      <ol className="mission-days" aria-label="14 hari terakhir">
        {cells.map(({ iso, d, m }) => (
          <li key={iso} className={`mday ${m?.status ?? (m ? 'dibuka' : 'kosong')}`} title={m ? `${m.mission_id}: ${m.parent_taps} contoh pendamping, ${m.child_taps} ketukan anak` : 'tidak ada misi'}>
            <span className="mday-date">{d.getDate()}</span>
            <span className="mday-mark" aria-hidden="true">
              {m?.status === 'selesai' ? '✓' : m?.status === 'belum_sempat' ? '–' : m ? '•' : ''}
            </span>
            <span className="mday-reps">{m ? `${Math.min(m.parent_taps, 99)}×` : ''}</span>
            <span className="sr-only">
              {iso}: {m?.status === 'selesai' ? 'selesai' : m?.status === 'belum_sempat' ? 'belum sempat' : m ? 'dibuka tanpa konfirmasi' : 'tidak ada misi'}
            </span>
          </li>
        ))}
      </ol>
      <p className="panel-foot">
        ✓ selesai · – belum sempat · • papan misi dibuka tanpa konfirmasi · angka = contoh pendamping pada kata misi hari itu. Belum sempat bukan
        kegagalan.
      </p>
    </Panel>
  )
}
