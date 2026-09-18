import { href } from '../route'

// D3 usulan target: isi di tonggak 4.5.
export function D3({ childId }: { childId: string }) {
  return (
    <section>
      <a href={href.d2(childId)}>← Ringkasan anak</a>
      <h1>Usulkan kata untuk pekan ini</h1>
    </section>
  )
}
