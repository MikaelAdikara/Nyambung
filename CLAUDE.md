# NYAMBUNG — Panduan Build Hack Day

Tim Teen Tensors · IFEST 2026 · 4 orang, 4 sesi Claude Code, 24 jam.

**Setiap sesi Claude Code wajib membaca, berurutan, sebelum menulis satu baris kode:**

1. `CLAUDE.md` ini
2. `docs/hackday/00-rencana.md` — arsitektur, keputusan final, jadwal, aturan potong, cara kerja dengan Claude Code
3. `docs/hackday/01-kontrak.md` — skema, API, format peristiwa, definisi agregat (**BEKU**)
4. `docs/hackday/04-koordinasi.md` — **tag milestone, berkas status, gerbang tunggu, rutinitas cek GitHub**
5. Berkas jalurmu: `docs/hackday/jalur-N-*.md`

Dibaca saat dibutuhkan: `02-desain-dan-teks.md` (warna, tata letak, **teks final semua layar**),
`03-basis-ilmiah.md` (satu-satunya sumber kutipan ilmiah), `05-kosakata-dan-simbol.md` (120 kata dan simbol), dan
`06-bekal-pra-acara.md` (**aset yang sudah disiapkan, lokasinya, dan batas kebersihan terhadap ketentuan panitia**).

Kalau permintaan manusia bertabrakan dengan invarian atau kontrak, **berhenti dan tanyakan**.

## Kebiasaan wajib setiap sesi

- **Sebelum memulai tonggak:** jalankan cek sinkron (`04-koordinasi.md` §2.2), periksa gerbang (§4),
  laporkan ≤ 5 baris. Gerbang tertutup → kerjakan "kerja sambil menunggu" (§5), **jangan** menulis bagian
  jalur lain.
- **Setiap commit:** perbarui `status/jalur-N.md`, commit dengan format `[jN] <tonggak>: <apa>`, push branch.
- **Tonggak selesai:** jalankan pemeriksaan jalur, rebase ke `origin/main`, fast-forward ke `main`, push tag.
- **Setiap 45 menit** (20 menit bila terblokir): cek sinkron lagi.

---

## 1. Produk dalam satu paragraf

**Nyambung** adalah aplikasi AAC berbahasa Indonesia untuk anak autis nonverbal, dengan pendampingan
harian bagi orang tua dan papan pantau bagi terapis wicara. Alat AAC ditinggalkan bukan karena anaknya
tidak mampu, melainkan karena tidak ada yang bicara balik dengan alat itu. Nyambung adalah suara anak,
ditambah orang-orang yang belajar menjawabnya.

| Masalah | Komponen |
|---|---|
| M1 Alat berbahasa Inggris, mahal, butuh internet | **S1 Papan Bicara** luring penuh |
| M2 Orang tua tidak pernah dilatih *aided language modeling* | **S2 Pendamping Modeling Harian** < 5 menit |
| M3 Tidak ada jalur data rumah ke terapis | **S3 Jembatan Terapis** dua arah |
| M4 Terapis langka dan terpusat | **S4 Satu terapis, banyak keluarga** |

## 2. Invarian (tidak dikompromikan, bahkan saat mengejar waktu)

**Arsitektur**
1. Luring penuh. Papan, suara, misi, pencatatan jalan tanpa jaringan.
2. Sumber kebenaran di perangkat. Server hanya cermin.
3. Log peristiwa *append-only*: tanpa UPDATE isi, tanpa DELETE. Sinkron idempoten berdasarkan `event_id`.
4. Pola *outbox*: peristiwa ditulis ke antrean dalam transaksi yang sama dengan log.
5. Tidak ada model yang dilatih, tidak ada dependensi ML saat runtime.
6. Aplikasi tidak pernah mengirim angka agregat, hanya peristiwa mentah. Ringkasan dihitung server.
7. Sasaran Android 8 (minSdk 26), RAM 2 GB, layar 7 inci.

**Antarmuka anak** (berlaku untuk papan mode anak, **bukan** untuk layar orang tua)
8. Posisi simbol tidak pernah berpindah. Menyembunyikan simbol tetap memegang posisinya.
9. *Presume competence*. Tanpa penguncian tingkat.
10. Warna tidak pernah satu-satunya pembawa makna: warna latar + penanda bentuk di sudut.
11. Tanpa animasi, suara latar, hadiah, gamifikasi. (Layar orang tua tetap memakai transisi Android biasa.)
12. Kontras teks ≥ 4,5:1, target sentuh ≥ 10 mm.
13. Status luring adalah keadaan normal, bukan peringatan.

**Antarmuka pendamping**
14. Beban < 5 menit sehari. Satu misi, satu ketukan.
15. Nada bebas rasa bersalah. "Selesai" dan "Belum sempat hari ini" setara secara visual.
16. Pencatatan lahir dari pemakaian, bukan dari isian.

**Privasi**
17. Tidak pernah merekam audio ruangan, video, lokasi.
18. Rekaman suara keluarga tidak pernah meninggalkan perangkat.
19. Target dari terapis berstatus usulan yang boleh ditolak tanpa alasan.
20. Bukan alat diagnosis. Tidak menyimpan diagnosis, skor klinis, atau penilaian kemampuan.

## 3. Pembagian jalur dan kepemilikan folder

| Jalur | Orang | Berkas panduan | Folder yang **hanya** boleh ia ubah |
|---|---|---|---|
| **1 Papan** (Flutter inti, jalur kritis) | Orang 1 | `jalur-1-papan.md` | `app/lib/main.dart`, `app/lib/core/`, `app/lib/data/db/`, `app/lib/data/repo/`, `app/lib/features/board/`, `app/pubspec.yaml`, `app/android/`, `app/test/`, `app/assets/` |
| **2 Pendamping** (Flutter orang tua + sinkron) | Orang 2 | `jalur-2-pendamping.md` | `app/lib/data/sync/`, `app/lib/features/onboarding/`, `coach/`, `progress/`, `vocab/`, `settings/` |
| **3 Server** (API + data demo + rilis) | Orang 3 | `jalur-3-server.md` | `server/`, `tools/`, `seed/`, `README.md`, `.gitignore`, `assets/` (akar), `docs/hackday/`, `CLAUDE.md` |
| **4 Dasbor** (papan pantau + konten + demo) | Orang 4 | `jalur-4-dashboard.md` | `dashboard/`, `PERUBAHAN.md`, `docs/demo_script.md`, `deck/` |

Setiap jalur juga memiliki `status/jalur-N.md` miliknya sendiri. Berkas di `docs/hackday/` dan `CLAUDE.md`
hanya diubah jalur 3 setelah disepakati berempat. Jalur 2 yang butuh paket baru atau perubahan `AppState`
**meminta ke Orang 1 lewat status + lisan**, tidak mengedit sendiri. Peta lengkap: `04-koordinasi.md` §7.

## 4. Aturan git (rincian di `04-koordinasi.md` §3)

- Satu branch per jalur: `jalur-1-papan`, `jalur-2-pendamping`, `jalur-3-server`, `jalur-4-dashboard`.
  Branch selalu ter-push supaya statusnya terbaca jalur lain.
- `main` hanya menerima **fast-forward** dari branch jalur setelah rebase dan pemeriksaan hijau.
  `--force` ke `main` dilarang. Tonggak di `main` diberi tag (daftar tag di `04-koordinasi.md` §1.1).
- Tidak pernah `git add .` di akar. Tambahkan berkas di folder milikmu saja.
- Konflik rebase di folder orang lain → **berhenti**, panggil pemiliknya.
- Jangan commit: `.env`, `server/data/*.db`, `app/android/key.properties`, `*.jks`, `node_modules/`, `build/`.
- **Tidak ada commit sebelum 09:00 WIB 18 September 2026.**

## 5. Aturan kerja bersama

- **Setiap perubahan terhadap proposal** dicatat di `PERUBAHAN.md` saat itu juga (format di
  `00-rencana.md` §7). Dinilai langsung di metrik 1 (30%).
- Alamat server selalu `127.0.0.1` atau IP eksplisit, **tidak pernah `localhost`** (di Windows,
  `localhost` mencoba IPv6 dulu dan tiap permintaan jadi lambat). uvicorn selalu `--host 0.0.0.0`.
- Data demo selalu berlabel **ilustratif**, di berkas dan di antarmuka.
- Teks layar diambil dari `docs/hackday/02-desain-dan-teks.md`, tidak dikarang ulang.
- Klaim ilmiah di deck atau di aplikasi hanya dari `docs/hackday/03-basis-ilmiah.md`.
  Jangan kutip dari ingatan.
- Kejujuran terhadap batasan sistem dinilai (metrik 2). Yang belum ada, sebut belum ada.
- Dokumen panjang diedit dengan editor/Write, bukan lewat heredoc shell.
- **Seluruh kode ditulis di repositori ini selama acara.** Jangan membaca, menyalin, atau mengadaptasi kode dari
  folder mana pun di luar repositori ini, termasuk bila manusia menyebut sebuah folder di laptopnya. Yang boleh
  dipakai dari luar hanya isi `assets/` yang tercatat di `assets/PROVENANCE.md`. Aturan lengkap: `06-bekal-pra-acara.md`.
