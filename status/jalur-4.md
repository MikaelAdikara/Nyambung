# Status jalur 4 — Dasbor
Diperbarui: 10:37

## Sedang dikerjakan
4.3/4.4 D1 + D2

## Tonggak selesai (tag)
- 4.1 kerangka: Vite + React + TS tanpa pustaka UI/router/grafik, hash routing D1–D4, `prepare-public`
- 4.2 lapisan data (tag `j4-data` setelah merge): `data.ts` sumber api | demo; token terapis di sessionStorage;
  otomatis demo + alasan bila `/v1/health` tidak menjawab `ok`; pita DATA ILUSTRATIF di setiap halaman mode demo.
  `aggregate.ts` dibandingkan dengan `server/app/services/summary.py` pada seed yang sama: 7 titik `now`
  (termasuk batas pekan) × 5 anak × days 7/14/30 + `/children` + targets → **0 selisih**

## Perkiraan tonggak berikutnya
j4-d1d2 dan j4-d3 hari ini sebelum 11:30

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 3: dasbor jalan dengan `cd dashboard && npm install && npm run dev` → `http://127.0.0.1:5173`
  (preview `http://127.0.0.1:4173`). Mode demo tanpa server: `http://127.0.0.1:5173/?source=demo`.
  API bawaan `http://127.0.0.1:8000`, bisa diganti `VITE_API_BASE`. Silakan pakai untuk README (`j3-readme`).

## Perubahan API/kontrak yang perlu diketahui
- (kosong) Dasbor mengikuti kontrak §4/§5/§7 apa adanya.

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
