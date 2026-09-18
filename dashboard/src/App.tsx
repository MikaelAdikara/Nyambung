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
import { href, useRoute } from './route'
import { useReviewTimer } from './review'
import type { VocabWord } from './types'
import { Ctx, useApp } from './ctx'
import { Ribbon } from './ui'
import { D1 } from './pages/D1'
import { D2 } from './pages/D2'
import { D3 } from './pages/D3'
import { D4 } from './pages/D4'

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

export default function App() {
  const [boot, setBoot] = useState<Boot>({ state: 'loading' })
  const [vocabList, setVocabList] = useState<VocabWord[]>([])

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

  // Nama terapis di bilah atas, terikat ke sumber yang memintanya supaya tidak tertinggal setelah keluar.
  const [named, setNamed] = useState<{ source: DataSource; name: string } | null>(null)
  const apiSource = boot.state === 'ready' && boot.source instanceof ApiSource ? boot.source : null
  useEffect(() => {
    if (!apiSource) return
    let live = true
    apiSource.me().then(
      (m) => live && setNamed({ source: apiSource, name: m.therapist }),
      () => {},
    )
    return () => {
      live = false
    }
  }, [apiSource])
  const therapist = named && apiSource && named.source === apiSource ? named.name : null

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

  const ctx = useMemo(
    () =>
      boot.state === 'ready'
        ? { source: boot.source, vocab: new Map(vocabList.map((w) => [w.word_id, w])), vocabList, onUnauthorized }
        : null,
    [boot, vocabList, onUnauthorized],
  )

  if (boot.state === 'loading') return <main className="page muted">Memuat…</main>
  if (boot.state === 'failed')
    return (
      <main className="page">
        <div className="card error">{boot.error}</div>
      </main>
    )
  if (boot.state === 'gate') return <LoginGate error={boot.error} onSubmit={signIn} />

  const demo = boot.source.kind === 'demo'
  return (
    <Ctx.Provider value={ctx}>
      {demo && <Ribbon reason={boot.reason} />}
      <header className="topbar">
        <a className="brand" href={href.d1()}>
          <span className="brand-dot teal" aria-hidden="true" />
          <span className="brand-dot coral" aria-hidden="true" />
          Nyambung <span className="muted">· papan pantau terapis</span>
        </a>
        {demo ? (
          <a href={withSource(false)}>Masuk sebagai terapis</a>
        ) : (
          <span className="account">
            {therapist && <span className="muted">{therapist}</span>}
            <button
              className="link"
              onClick={() => {
                if (boot.source instanceof ApiSource) void boot.source.logout()
                saveToken(null)
                setBoot({ state: 'gate' })
              }}
            >
              Keluar
            </button>
          </span>
        )}
      </header>
      <Routes />
    </Ctx.Provider>
  )
}

function Routes() {
  const route = useRoute()
  useReviewTimer(route, useApp().source)
  return (
    <main className="page">
      {route.page === 'D1' && <D1 />}
      {route.page === 'D2' && <D2 childId={route.childId} />}
      {route.page === 'D3' && <D3 childId={route.childId} />}
      {route.page === 'D4' && <D4 childId={route.childId} />}
      {route.page === 'unknown' && (
        <section className="card">
          <p>Halaman tidak ditemukan.</p>
          <a href={href.d1()}>Kembali ke Keluarga binaan</a>
        </section>
      )}
    </main>
  )
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
    <main className="page gate">
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
