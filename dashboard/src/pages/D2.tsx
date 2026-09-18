import { href } from '../route'

// D2 ringkasan seorang anak: isi di tonggak 4.4.
export function D2({ childId }: { childId: string }) {
  return (
    <section>
      <a href={href.d1()}>← Keluarga binaan</a>
      <h1>Ringkasan anak</h1>
      <p className="muted">{childId}</p>
      <nav className="actions">
        <a className="button" href={href.d3(childId)}>
          Usulkan kata
        </a>
        <a className="button secondary" href={href.d4(childId)}>
          Ringkasan sesi
        </a>
      </nav>
    </section>
  )
}
