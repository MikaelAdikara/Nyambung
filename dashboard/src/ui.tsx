import { useState, type ReactNode } from 'react'
import { useApp } from './ctx'
import { ApiError } from './data'
import { personalLabel } from './format'
import type { Trend } from './types'

export function Loading() {
  return <p className="muted">Memuat…</p>
}

export function ErrorBox({ error }: { error: Error }) {
  const notFound = error instanceof ApiError && error.status === 404
  return (
    <div className="card error" role="alert">
      {notFound ? 'Anak tidak ditemukan atau tidak tertaut ke akun ini.' : error.message}
    </div>
  )
}

// ---------- pita ilustratif (02 §7) ----------

export function Ribbon({ reason }: { reason?: string | null }) {
  return (
    <div className="ribbon" role="note">
      <strong>DATA ILUSTRATIF</strong> — bukan data keluarga sungguhan.
      {reason && <span className="ribbon-reason"> {reason}</span>}
    </div>
  )
}

// ---------- kartu angka ----------

export function StatCard({ label, value, sub, accent }: { label: string; value: ReactNode; sub?: ReactNode; accent?: 'teal' | 'coral' }) {
  return (
    <div className={`card stat${accent ? ` stat-${accent}` : ''}`}>
      <div className="stat-label">{label}</div>
      <div className="stat-value">{value}</div>
      {sub && <div className="stat-sub">{sub}</div>}
    </div>
  )
}

// ---------- arah 3 pekan: ikon + teks, bukan warna saja (02 §7) ----------

const TREND: Record<Trend, { icon: string; text: string }> = {
  naik: { icon: '↑', text: 'naik' },
  tetap: { icon: '→', text: 'tetap' },
  turun: { icon: '↓', text: 'turun' },
  baru: { icon: '✦', text: 'baru' },
}

export function TrendBadge({ trend }: { trend: Trend }) {
  const t = TREND[trend] ?? TREND.tetap
  return (
    <span className={`trend trend-${trend}`}>
      <span aria-hidden="true">{t.icon}</span> {t.text}
    </span>
  )
}

// ---------- grafik batang SVG tangan ----------

export function BarChart({
  values,
  labels,
  title,
  height = 160,
  color = 'var(--teal)',
  labelEvery = 1,
}: {
  values: number[]
  labels: string[]
  title: string
  height?: number
  color?: string
  labelEvery?: number
}) {
  const max = Math.max(1, ...values)
  const n = values.length
  const W = 600
  const top = 18
  const bottom = 22
  const plot = height - top - bottom
  const slot = W / n
  const bar = Math.max(4, slot * 0.64)
  return (
    <figure className="chart">
      <figcaption>{title}</figcaption>
      <svg viewBox={`0 0 ${W} ${height}`} role="img" aria-label={`${title}: ${values.join(', ')}`} preserveAspectRatio="none">
        <line x1="0" x2={W} y1={top + plot} y2={top + plot} stroke="var(--line)" strokeWidth="2" />
        {values.map((v, i) => {
          const h = (v / max) * plot
          const x = i * slot + (slot - bar) / 2
          return (
            <g key={i}>
              <rect x={x} y={top + plot - h} width={bar} height={h} rx="3" fill={color}>
                <title>{`${labels[i]}: ${v}`}</title>
              </rect>
              {v > 0 && n <= 12 && (
                <text x={x + bar / 2} y={top + plot - h - 5} textAnchor="middle" className="chart-value">
                  {v}
                </text>
              )}
              {i % labelEvery === 0 && (
                <text x={i * slot + slot / 2} y={height - 5} textAnchor="middle" className="chart-label">
                  {labels[i]}
                </text>
              )}
            </g>
          )
        })}
      </svg>
    </figure>
  )
}

// ---------- ikon kata (simbol Mulberry / gambar tim) ----------

// Warna jenis kata (02 §2)
const POS_FILL: Record<string, string> = {
  pengatur: '#ECEAE5',
  ganti: '#F1E6C8',
  kerja: '#DDE8DD',
  sifat: '#DCE6F1',
  tanya: '#E6DDF0',
  benda: '#F6E7CF',
  sosial: '#F2DEE6',
}

export function WordIcon({ id, size = 40 }: { id: string; size?: number }) {
  const { vocab } = useApp()
  const w = vocab.get(id)
  const [failed, setFailed] = useState(false)
  const fill = POS_FILL[w?.pos ?? 'benda'] ?? POS_FILL.benda
  return (
    <span
      className="word-icon"
      style={{ width: size, height: size, background: fill }}
      title={personalLabel(id) ? 'Kartu personal dari foto keluarga (fotonya tidak dikirim)' : undefined}
    >
      {w && !failed ? (
        <img
          src={`${import.meta.env.BASE_URL}symbols/${w.symbol_file}`}
          alt=""
          width={size - 6}
          height={size - 6}
          loading="lazy"
          onError={() => setFailed(true)}
        />
      ) : (
        // Simbol gambar tim belum ada: huruf pertama, sama seperti papan di aplikasi
        <span className="word-icon-letter" aria-hidden="true">
          {(w?.label_display ?? personalLabel(id) ?? id).slice(0, 1).toUpperCase()}
        </span>
      )}
    </span>
  )
}
