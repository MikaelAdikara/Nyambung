import { useState, type ReactNode } from 'react'
import { useApp } from './ctx'
import { ApiError } from './data'
import { personalLabel, phraseLabel } from './format'
import { Icon, type IconName } from './icons'
import { href, type Route } from './route'
import type { Trend } from './types'

export function Loading() {
  return (
    <div className="loading" role="status">
      <span className="loading-dot" />
      <span className="loading-dot" />
      <span className="loading-dot" />
      <span className="sr-only">Memuat…</span>
    </div>
  )
}

// ---------- avatar huruf awal (tanpa foto: dasbor tidak pernah menerima foto keluarga) ----------

const TONES = ['teal', 'coral', 'sky', 'lavender', 'sun', 'leaf'] as const
export type Tone = (typeof TONES)[number]

export function toneFor(key: string): Tone {
  let h = 0
  for (const ch of key) h = (h * 31 + ch.charCodeAt(0)) >>> 0
  return TONES[h % TONES.length]
}

export function Avatar({ name, size = 36, tone }: { name: string; size?: number; tone?: Tone }) {
  const letters = name
    .replace(/\(.*?\)/g, '')
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase())
    .join('')
  return (
    <span className={`avatar tone-${tone ?? toneFor(name)}`} style={{ width: size, height: size, fontSize: size * 0.4 }} aria-hidden="true">
      {letters || '?'}
    </span>
  )
}

// ---------- kepala halaman seorang anak + tab D2–D5 ----------

const CHILD_TABS: { page: Route['page']; label: string; icon: IconName; to: (id: string) => string }[] = [
  { page: 'D2', label: 'Ringkasan', icon: 'chart', to: href.d2 },
  { page: 'D3', label: 'Usulkan kata', icon: 'target', to: href.d3 },
  { page: 'D5', label: 'Frasa bersuara', icon: 'wave', to: href.d5 },
  { page: 'D4', label: 'Catatan sesi', icon: 'note', to: href.d4 },
]

export function ChildHeader({
  childId,
  page,
  name,
  meta,
}: {
  childId: string
  page: Route['page']
  name: string | null
  meta?: ReactNode
}) {
  return (
    <header className="child-head">
      <a className="back" href={href.d1()}>
        <Icon name="back" size={16} /> Keluarga binaan
      </a>
      <div className="child-title">
        <Avatar name={name ?? '?'} size={52} tone={toneFor(childId)} />
        <div>
          <h1>{name ?? '(tanpa nama)'}</h1>
          {meta && <div className="child-meta">{meta}</div>}
        </div>
      </div>
      <nav className="tabs" aria-label="Bagian">
        {CHILD_TABS.map((t) => (
          <a key={t.page} href={t.to(childId)} className={`tab${t.page === page ? ' active' : ''}`} aria-current={t.page === page ? 'page' : undefined}>
            <Icon name={t.icon} size={17} />
            {t.label}
          </a>
        ))}
      </nav>
    </header>
  )
}

// ---------- panel berjudul (kartu utama halaman) ----------

export function Panel({
  title,
  icon,
  tone = 'teal',
  actions,
  children,
  className,
}: {
  title: ReactNode
  icon?: IconName
  tone?: Tone
  actions?: ReactNode
  children: ReactNode
  className?: string
}) {
  return (
    <section className={`panel${className ? ` ${className}` : ''}`}>
      <header className="panel-head">
        {icon && (
          <span className={`panel-icon tone-${tone}`}>
            <Icon name={icon} size={18} />
          </span>
        )}
        <h2>{title}</h2>
        {actions && <div className="panel-actions">{actions}</div>}
      </header>
      {children}
    </section>
  )
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

export function StatCard({
  label,
  value,
  sub,
  accent,
  icon,
  to,
  onClick,
}: {
  label: string
  value: ReactNode
  sub?: ReactNode
  accent?: Tone
  icon?: IconName
  to?: string
  onClick?: () => void
}) {
  const body = (
    <>
      {icon && (
        <span className={`stat-icon tone-${accent ?? 'teal'}`}>
          <Icon name={icon} size={22} />
        </span>
      )}
      <div className="stat-body">
        <div className="stat-label">{label}</div>
        <div className="stat-value">{value}</div>
        {sub && <div className="stat-sub">{sub}</div>}
      </div>
      {(to || onClick) && <Icon name="arrow" size={20} className="stat-arrow" />}
    </>
  )
  if (onClick)
    return (
      <button type="button" className={`stat stat-link${accent ? ` stat-${accent}` : ''}`} onClick={onClick}>
        {body}
      </button>
    )
  return to ? (
    <a className={`stat stat-link${accent ? ` stat-${accent}` : ''}`} href={to}>
      {body}
    </a>
  ) : (
    <div className={`stat${accent ? ` stat-${accent}` : ''}`}>{body}</div>
  )
}

// ---------- status pil: ikon + teks, bukan warna saja ----------

export function StatusPill({ status }: { status: 'usulan' | 'diterima' | 'ditolak' }) {
  const t = { usulan: ['clock', 'Menunggu'], diterima: ['check', 'Diterima'], ditolak: ['back', 'Tidak dipakai'] } as const
  const [icon, text] = t[status]
  return (
    <span className={`pill pill-${status}`}>
      <Icon name={icon} size={13} />
      {text}
    </span>
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
// Sama dengan warna sel papan di aplikasi (app/lib/core/theme.dart PosStyle).
const POS_FILL: Record<string, string> = {
  pengatur: '#E8F6F5',
  ganti: '#FCDE9E',
  kerja: '#E1F4E7',
  sifat: '#DEF3FC',
  tanya: '#EDECFB',
  benda: '#FBE3D2',
  sosial: '#FDE1E2',
}

export function WordIcon({ id, size = 40 }: { id: string; size?: number }) {
  const { vocab } = useApp()
  const w = vocab.get(id)
  const [failed, setFailed] = useState(false)
  const phrase = phraseLabel(id)
  const fill = POS_FILL[w?.pos ?? (phrase ? 'sosial' : 'benda')] ?? POS_FILL.benda
  return (
    <span
      className="word-icon"
      style={{ width: size, height: size, background: fill }}
      title={
        personalLabel(id) ? 'Kartu personal dari foto keluarga (fotonya tidak dikirim)' : phrase ? 'Kartu frasa bersuara' : undefined
      }
    >
      {phrase ? (
        <Icon name="wave" size={Math.round(size * 0.5)} />
      ) : w && !failed ? (
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
