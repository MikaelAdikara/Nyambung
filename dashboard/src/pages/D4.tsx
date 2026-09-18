import { useState } from 'react'
import { href } from '../route'
import { useApp, useAsync } from '../ctx'
import { sessionText } from '../format'
import { ErrorBox, Loading } from '../ui'

// D4 catatan sesi (jalur 4 §4.6): hanya ringkasan otomatis, tanpa penyimpanan catatan bebas.
export function D4({ childId }: { childId: string }) {
  const { source, vocab } = useApp()
  const [res] = useAsync(() => source.summary(childId, 7), [source, childId])
  const [copied, setCopied] = useState(false)

  if (res.state === 'loading') return <Loading />
  if (res.state === 'error')
    return (
      <section>
        <a href={href.d1()}>← Keluarga binaan</a>
        <ErrorBox error={res.error} />
      </section>
    )

  const text = sessionText(res.data, vocab)
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      setCopied(false)
    }
  }

  return (
    <section>
      <a href={href.d2(childId)}>← {res.data.nickname ?? 'Ringkasan anak'}</a>
      <h1>Ringkasan sesi</h1>
      <div className="card">
        <p className="session-text">{text}</p>
        <div className="actions">
          <button className="button" onClick={copy}>
            Salin
          </button>
          {copied && (
            <span className="ok" role="status">
              Tersalin.
            </span>
          )}
        </div>
      </div>
      <p className="note">Angka ini pola pemakaian, bukan ukuran kemampuan anak.</p>
    </section>
  )
}
