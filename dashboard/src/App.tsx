import { href, useRoute } from './route'
import { D1 } from './pages/D1'
import { D2 } from './pages/D2'
import { D3 } from './pages/D3'
import { D4 } from './pages/D4'

export default function App() {
  const route = useRoute()
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
