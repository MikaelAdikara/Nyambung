import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react'
import {
  ApiError,
  ApiSource,
  loadDemoSource,
  loadVocab,
  loginWithPassword,
  readToken,
  saveToken,
  serverReachable,
  type DataSource,
} from './data'
import { href, useRoute, type Route } from './route'
import { useReviewTimer } from './review'
import type { VocabWord } from './types'
import { Ctx, useApp } from './ctx'
import { Icon, type IconName } from './icons'
import { Avatar, Ribbon } from './ui'
import { D1 } from './pages/D1'
import { D2 } from './pages/D2'
import { D3 } from './pages/D3'
import { D4 } from './pages/D4'
import { D5 } from './pages/D5'

type Boot =
  | { state: 'loading' }
  | { state: 'gate'; error?: string }
  | { state: 'ready'; source: DataSource; reason: string | null }
  | { state: 'failed'; error: string }

const wantsDemo = () => new URLSearchParams(window.location.search).get('source') === 'demo'

function withSource(demo: boolean): string {
  const url = new URL(window.location.href)
  if (demo) url.searchParams.set('source', 'demo')
  else url.searchParams.delete('source')
  return url.toString()
}

const LOGO = `${import.meta.env.BASE_URL}brand/logo_mark.png`

export default function App() {
  const [boot, setBoot] = useState<Boot>({ state: 'loading' })
  const [vocabList, setVocabList] = useState<VocabWord[]>([])
  const [query, setQuery] = useState('')

  const startDemo = useCallback(async (reason: string | null) => {
    try {
      setBoot({ state: 'ready', source: await loadDemoSource(), reason })
    } catch (e) {
      setBoot({ state: 'failed', error: (e as Error).message })
    }
  }, [])

  useEffect(() => {
    loadVocab().then(setVocabList, () => setVocabList([]))
    ;(async () => {
      if (wantsDemo()) return startDemo(null)
      // Server tidak terjangkau → otomatis mode demo, alasannya ditampilkan (jalur 4 §4.2).
      const unreachable = await serverReachable()
      if (unreachable) return startDemo(`${unreachable} Menampilkan data ilustratif.`)
      const token = readToken()
      setBoot(token ? { state: 'ready', source: new ApiSource(token), reason: null } : { state: 'gate' })
    })()
  }, [startDemo])

  // Nama terapis, terikat ke sumber yang memintanya supaya tidak tertinggal setelah keluar.
  const [named, setNamed] = useState<{ source: DataSource; name: string; email: string | null } | null>(null)
  const apiSource = boot.state === 'ready' && boot.source instanceof ApiSource ? boot.source : null
  useEffect(() => {
    if (!apiSource) return
    let live = true
    apiSource.me().then(
      (m) => live && setNamed({ source: apiSource, name: m.therapist, email: m.email }),
      () => {},
    )
    return () => {
      live = false
    }
  }, [apiSource])
  const me = named && apiSource && named.source === apiSource ? named : null

  const signIn = async (cred: Credentials) => {
    try {
      const token = 'token' in cred ? cred.token : await loginWithPassword(cred.email, cred.password)
      const source = new ApiSource(token)
      await source.children()
      saveToken(token)
      setBoot({ state: 'ready', source, reason: null })
    } catch (e) {
      const msg =
        e instanceof ApiError && e.status === 401 && 'token' in cred
          ? 'Token tidak dikenal. Periksa lagi atau minta ke pengelola server.'
          : (e as Error).message
      setBoot({ state: 'gate', error: msg })
    }
  }

  const onUnauthorized = useCallback(() => {
    saveToken(null)
    setBoot({ state: 'gate', error: 'Sesi berakhir atau token tidak berlaku. Masuk lagi.' })
  }, [])

  const signOut = () => {
    if (boot.state === 'ready' && boot.source instanceof ApiSource) void boot.source.logout()
    saveToken(null)
    setBoot({ state: 'gate' })
  }

  const ctx = useMemo(
    () =>
      boot.state === 'ready'
        ? {
            source: boot.source,
            vocab: new Map(vocabList.map((w) => [w.word_id, w])),
            vocabList,
            onUnauthorized,
            therapist: me?.name ?? null,
            query,
            setQuery,
          }
        : null,
    [boot, vocabList, onUnauthorized, me, query],
  )

  if (boot.state === 'loading')
    return (
      <main className="boot" aria-busy="true">
        <img src={LOGO} alt="" width={56} height={56} />
      </main>
    )
  if (boot.state === 'failed')
    return (
      <main className="boot">
        <div className="card error">{boot.error}</div>
      </main>
    )
  if (boot.state === 'gate') return <LoginGate error={boot.error} onSubmit={signIn} />

  const demo = boot.source.kind === 'demo'
  return (
    <Ctx.Provider value={ctx}>
      <Shell demo={demo} reason={boot.reason} me={me} onSignOut={signOut} />
    </Ctx.Provider>
  )
}

function Shell({
  demo,
  reason,
  me,
  onSignOut,
}: {
  demo: boolean
  reason: string | null
  me: { name: string; email: string | null } | null
  onSignOut: () => void
}) {
  const route = useRoute()
  const { source, query, setQuery } = useApp()
  useReviewTimer(route, source)
  const childId = 'childId' in route ? route.childId : null

  // Pindah halaman: gulir ke atas, seperti aplikasi multi-halaman.
  useEffect(() => {
    window.scrollTo({ top: 0 })
  }, [route.page, childId])

  const name = me?.name ?? (demo ? 'Mode demo' : 'Terapis')
  return (
    <div className="shell">
      <aside className="sidebar" aria-label="Navigasi">
        <a className="sidebar-logo" href={href.d1()} title="Nyambung · papan pantau terapis">
          <img src={LOGO} alt="Nyambung" width={30} height={30} />
        </a>
        <nav className="sidebar-nav">
          <NavItem icon="home" label="Keluarga binaan" to={href.d1()} active={route.page === 'D1'} />
        </nav>
        {demo ? (
          <a className="nav-item" href={withSource(false)} title="Masuk sebagai terapis" aria-label="Masuk sebagai terapis">
            <Icon name="link" />
            <span className="nav-label">Masuk</span>
          </a>
        ) : (
          <button className="nav-item" onClick={onSignOut} title="Keluar" aria-label="Keluar">
            <Icon name="logout" />
            <span className="nav-label">Keluar</span>
          </button>
        )}
      </aside>

      <div className="workspace">
        {demo && <Ribbon reason={reason} />}
        <header className="topbar">
          <label className="search">
            <Icon name="search" size={18} />
            <span className="sr-only">Cari anak</span>
            <input
              type="search"
              value={query}
              placeholder="Cari anak"
              onChange={(e) => {
                setQuery(e.target.value)
                if (route.page !== 'D1') window.location.hash = href.d1()
              }}
            />
          </label>
          <div className="account">
            <Avatar name={name} size={40} tone="teal" />
            <div className="account-text">
              <strong>{name}</strong>
              <span>{me?.email ?? (demo ? 'data ilustratif' : 'papan pantau terapis')}</span>
            </div>
          </div>
        </header>
        <main className="page">
          <Page route={route} />
        </main>
      </div>
    </div>
  )
}

function NavItem({ icon, label, to, active }: { icon: IconName; label: string; to: string; active: boolean }) {
  return (
    <a
      className={`nav-item${active ? ' active' : ''}`}
      href={to}
      aria-current={active ? 'page' : undefined}
      title={label}
      aria-label={label}
    >
      <Icon name={icon} />
      <span className="nav-label">{label}</span>
    </a>
  )
}

function Page({ route }: { route: Route }) {
  switch (route.page) {
    case 'D1':
      return <D1 />
    case 'D2':
      return <D2 childId={route.childId} />
    case 'D3':
      return <D3 childId={route.childId} />
    case 'D4':
      return <D4 childId={route.childId} />
    case 'D5':
      return <D5 childId={route.childId} />
    default:
      return (
        <section className="card">
          <p>Halaman tidak ditemukan.</p>
          <a href={href.d1()}>Kembali ke Keluarga binaan</a>
        </section>
      )
  }
}

type Credentials = { email: string; password: string } | { token: string }

// Gerbang masuk (02 §7, diubah: email + kata sandi; token server tetap bisa dipakai untuk simulator/pengelola).
// Token sesi hanya di sessionStorage.
function LoginGate({ error, onSubmit }: { error?: string; onSubmit: (cred: Credentials) => Promise<void> }) {
  const [useToken, setUseToken] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [token, setToken] = useState('')
  const [busy, setBusy] = useState(false)
  const ready = useToken ? token.trim() !== '' : email.trim() !== '' && password !== ''
  const submit = async (e: FormEvent) => {
    e.preventDefault()
    if (!ready) return
    setBusy(true)
    await onSubmit(useToken ? { token: token.trim() } : { email: email.trim(), password })
    setBusy(false)
  }
  return (
    <main className="gate">
      <div className="gate-hero" aria-hidden="true">
        <img src={LOGO} alt="" width={64} height={64} />
        <p className="gate-hero-title">Nyambung</p>
        <p>Papan pantau terapis: pola pemakaian dari rumah, target kata, frasa audio, dan catatan sesi.</p>
      </div>
      <form className="card gate-card" onSubmit={submit}>
        <h1>Masuk sebagai terapis</h1>
        {useToken ? (
          <>
            <label htmlFor="token">Token server</label>
            <input id="token" type="password" autoComplete="off" value={token} onChange={(e) => setToken(e.target.value)} autoFocus />
          </>
        ) : (
          <>
            <label htmlFor="email">Email</label>
            <input
              id="email"
              type="email"
              autoComplete="username"
              inputMode="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoFocus
            />
            <label htmlFor="password">Kata sandi</label>
            <input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </>
        )}
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <button className="button" type="submit" disabled={busy || !ready}>
          {busy ? 'Memeriksa…' : 'Masuk'}
        </button>
        <p className="small muted gate-note">Akun terapis dibuat oleh pengelola klinik. Belum punya akun? Hubungi pengelola.</p>
        <div className="gate-links small">
          <a href={withSource(true)}>Lihat data ilustratif</a>
          <button type="button" className="link" onClick={() => setUseToken(!useToken)}>
            {useToken ? 'Masuk dengan email' : 'Pakai token server'}
          </button>
        </div>
      </form>
    </main>
  )
}
