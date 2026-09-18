import { useState } from 'react'
import type { InviteOut } from '../types'
import { href } from '../route'
import { useApp, useAsync } from '../ctx'
import { relTime } from '../format'
import { ErrorBox, Loading, StatCard, TrendBadge } from '../ui'

// D1 Keluarga binaan (jalur 4 §4.3, teks 02 §7)
export function D1() {
  const { source } = useApp()
  const [res] = useAsync(() => source.children(), [source])

  return (
    <section>
      <div className="title-row">
        <h1>Keluarga binaan</h1>
        <InviteButton />
      </div>
      {res.state === 'loading' && <Loading />}
      {res.state === 'error' && <ErrorBox error={res.error} />}
      {res.state === 'ok' && (
        <>
          <div className="stats">
            <StatCard label="Keluarga aktif" value={res.data.active_families} />
            <StatCard label="Perlu ditinjau" value={res.data.needs_review} />
            <StatCard label="Belum sinkron > 7 hari" value={res.data.unsynced_over_7d} />
            <StatCard label="Usulan menunggu" value={res.data.pending_targets} />
          </div>
          {res.data.children.length === 0 ? (
            <div className="card muted">Belum ada keluarga yang tertaut. Buat kode undangan dan berikan ke keluarga.</div>
          ) : (
            <div className="card table-wrap">
              <table className="table">
                <thead>
                  <tr>
                    <th>Anak</th>
                    <th>Usia</th>
                    <th>Rutinitas</th>
                    <th className="num">Kata berbeda (7 hari)</th>
                    <th>Arah 3 pekan</th>
                    <th className="num">Misi</th>
                    <th>Sinkron terakhir</th>
                  </tr>
                </thead>
                <tbody>
                  {res.data.children.map((c) => (
                    <tr key={c.child_id} className="row-link" onClick={() => (window.location.hash = href.d2(c.child_id))}>
                      <td>
                        <a href={href.d2(c.child_id)} onClick={(e) => e.stopPropagation()}>
                          {c.nickname ?? '(tanpa nama)'}
                        </a>
                        {c.needs_review && <span className="badge">Perlu ditinjau</span>}
                      </td>
                      <td>{c.age_years ?? '–'}</td>
                      <td>{c.routine ?? '–'}</td>
                      <td className="num">{c.unique_words}</td>
                      <td>
                        <TrendBadge trend={c.trend_3w} />
                      </td>
                      <td className="num">
                        {c.missions_done}/{c.missions_total}
                      </td>
                      <td title={c.last_sync ?? ''}>{relTime(c.last_sync)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </section>
  )
}

function InviteButton() {
  const { source } = useApp()
  const [invite, setInvite] = useState<InviteOut | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [busy, setBusy] = useState(false)

  if (source.kind === 'demo')
    return (
      <button className="button secondary" disabled title="Mode demo tidak membuat kode undangan.">
        Buat kode undangan
      </button>
    )

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
      <button className="button" onClick={create} disabled={busy}>
        Buat kode undangan
      </button>
      {invite && (
        <div className="card invite-card" role="status">
          <div className="invite-code">{invite.invite_code}</div>
          <div className="muted">Berlaku 7 hari, sekali pakai.</div>
        </div>
      )}
      {error && <p className="form-error">{error}</p>}
    </div>
  )
}
