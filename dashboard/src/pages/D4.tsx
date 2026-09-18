import { href } from '../route'

// D4 catatan sesi: isi di tonggak 4.6.
export function D4({ childId }: { childId: string }) {
  return (
    <section>
      <a href={href.d2(childId)}>← Ringkasan anak</a>
      <h1>Ringkasan sesi</h1>
    </section>
  )
}
