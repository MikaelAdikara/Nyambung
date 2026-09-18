# Status jalur 4 — Dasbor
Diperbarui: 11:20

**Mulai 11:20 semua jalur bekerja langsung di `main`** (tidak ada lagi kerja paralel; branch jalur sudah tergabung).

## Sedang dikerjakan
Paruh kedua: PERUBAHAN.md (terus-menerus), lalu naskah demo, deck, video. Siap menyaksikan `int-1-hp-ke-d2`.

## Tonggak selesai (tag)
- (11:20, tanpa tag) D1 alasan "Perlu ditinjau"; D2 kartu Perlu diperiksa + target diterima + label "tanpa contoh ≤ 60 dtk".
  `npm run build` + lint bersih, dicek di mode demo
- 4.1 kerangka: Vite + React + TS tanpa pustaka UI/router/grafik, hash routing D1–D4, `prepare-public`
- 4.2 lapisan data (`j4-data`): `data.ts` sumber api | demo; token terapis di sessionStorage;
  otomatis demo + alasan bila `/v1/health` tidak menjawab `ok`; pita DATA ILUSTRATIF di setiap halaman mode demo.
  `aggregate.ts` dibandingkan dengan `server/app/services/summary.py` pada seed yang sama: 7 titik `now`
  (termasuk batas pekan) × 5 anak × days 7/14/30 + `/children` + targets → **0 selisih**
- 4.3/4.4 D1 + D2 (`j4-d1d2`): D1 empat kartu + tabel + badge Perlu ditinjau + arah ikon+teks + Buat kode undangan;
  D2 empat kartu, batang 6 pekan + histogram 24 jam (SVG tangan), kata terbanyak dengan ikon, target diterima ditandai,
  kalimat "pola pemakaian, bukan ukuran kemampuan". Mode api diuji dengan server lokal berisi seed yang dikirim lewat
  API sungguhan (invite → redeem → sync): D1 api = D1 demo
- 4.5 D3 (`j4-d3-2`): grid 120 kata dengan ikon + pencarian, pilih 1–5, catatan ≤ 600, rutinitas opsional,
  "Kirim sebagai usulan" → `POST /targets` (201 diuji ke server lokal; `pending_targets` naik), riwayat status +
  "dipakai N kali sejak diterima". Mode demo: tombol kirim nonaktif dengan penjelasan. `week_index` = linked_weeks + 1
  - **`j4-d3` rusak: menunjuk commit sebelum rebase (tidak ada di `main`). Pakai `j4-d3-2`.**
- 4.6 D4: paragraf siap salin (teks 02 §7) + tombol Salin, tanpa penyimpanan catatan bebas
- 4.7 (`j4-build`): `npm run build` + lint bersih; `npm run preview` → `http://127.0.0.1:4173/?source=demo`
  D1–D4 jalan **tanpa server** (rencana cadangan panggung)

## Perkiraan tonggak berikutnya
Naskah demo J12–J20, deck J14–

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 2 / semua: D2 sudah di `main` (`j4-d1d2`), `int-1-hp-ke-d2` bisa diuji. Buka dasbor, masuk dengan token
  terapis yang sama dengan server, D1 → anak → D2.
- ke jalur 3: dasbor jalan dengan `cd dashboard && npm install && npm run dev` → `http://127.0.0.1:5173`
  (preview `http://127.0.0.1:4173`). Mode demo tanpa server: `http://127.0.0.1:5173/?source=demo`.
  API bawaan `http://127.0.0.1:8000`, bisa diganti `VITE_API_BASE`. Silakan pakai untuk README (`j3-readme`).
- ke jalur 3: `docs/` di-ignore `.gitignore`, padahal `docs/demo_script.md` adalah deliverable jalur 4 (jalur-4 §4.9).
  Mohon tambahkan `!docs/demo_script.md` (atau sepakati naskah pindah ke `deck/demo_script.md`).
- ke jalur 1: 6 simbol halaman 0 (TIDAK, YA, BERHENTI, SAKIT, AKU, ITU) digambar Orang 4 (tangan manusia, bukan kode);
  sampai ada, dasbor juga menampilkan huruf pertama.

## Perubahan API/kontrak yang perlu diketahui
- (kosong) Dasbor mengikuti kontrak §4/§5/§7 apa adanya.

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
