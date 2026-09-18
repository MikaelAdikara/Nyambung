# Nyambung

Aplikasi AAC (komunikasi augmentatif dan alternatif) berbahasa Indonesia untuk anak autis nonverbal,
dengan pendampingan harian bagi orang tua dan papan pantau bagi terapis wicara.

Alat AAC sering ditinggalkan bukan karena anaknya tidak mampu, tetapi karena tidak ada yang bicara balik
dengan alat itu. Nyambung adalah suara anak, ditambah orang-orang yang belajar menjawabnya.

| Masalah | Komponen |
|---|---|
| Alat berbahasa Inggris, mahal, butuh internet | **Papan Bicara** luring penuh |
| Orang tua tidak pernah dilatih *aided language modeling* | **Pendamping Modeling Harian** < 5 menit |
| Tidak ada jalur data rumah ke terapis | **Jembatan Terapis** dua arah |
| Terapis langka dan terpusat | **Satu terapis, banyak keluarga** |

## Arsitektur

```
Android (Flutter) ── SQLite lokal: utterance_event (append-only) + outbox, satu transaksi
      │  POST batch peristiwa mentah + Bearer token perangkat (saat ada jaringan)
      ▼
Server (FastAPI + SQLite WAL) ── event append-only, idempoten per event_id → agregasi
      │  GET + Bearer token terapis
      ▼
Papan pantau (React + Vite + TS) ── D1 daftar · D2 ringkasan · D3 usulan kata · D4 catatan
Aliran balik: usulan terapis → perangkat menarik target → keluarga terima/tolak → peristiwa TGT.
```

| Folder | Isi |
|---|---|
| `app/` | Flutter (Android, minSdk 26). `lib/core/` keadaan + tema + suara, `lib/data/` model + DB + DAO, `lib/features/` layar |
| `server/` | FastAPI + SQLite, tes pytest |
| `dashboard/` | React + Vite + TypeScript, hash routing, grafik SVG tangan |
| `tools/`, `seed/` | simulator dan data demo (selalu berlabel ilustratif) |
| `assets/` | konten: 120 kata (`vocab/`), simbol Mulberry CC BY-SA 4.0 (`symbols/`), asal-usul di `PROVENANCE.md` |
| `status/` | satu berkas status per jalur kerja |

## Invarian (tidak dikompromikan)

**Arsitektur**
1. Luring penuh: papan yang sudah disimpan, suara, misi, dan pencatatan jalan tanpa jaringan. Pembuatan frasa dan bantuan
   AI untuk draf papan foto adalah alur authoring opsional yang memerlukan jaringan.
2. Sumber kebenaran di perangkat; server hanya cermin.
3. Log peristiwa append-only: tanpa UPDATE isi, tanpa DELETE. Sinkron idempoten berdasarkan `event_id`.
4. Pola outbox: peristiwa ditulis ke antrean dalam transaksi yang sama dengan log.
5. Tidak ada model yang dilatih dan tidak ada dependensi ML di aplikasi. Server boleh memanggil model suara saat frasa
   dibuat dan vision AI saat pendamping meminta draf papan foto (PERUBAHAN #16 dan #22); hasil final diputar luring.
6. Aplikasi hanya mengirim peristiwa mentah, tidak pernah angka agregat. Ringkasan dihitung server.
7. Sasaran Android 8 (minSdk 26), RAM 2 GB, layar 7 inci.

**Papan mode anak**
8. Posisi simbol tidak pernah berpindah sendiri; simbol tersembunyi tetap memegang posisinya. Orang tua boleh menggeser
   kata di halaman kategori lewat Kelola kosakata; halaman inti dan sel cermin terkunci (PERUBAHAN #21).
9. *Presume competence*: tanpa penguncian tingkat.
10. Warna tidak pernah satu-satunya pembawa makna: warna latar + penanda bentuk di sudut.
11. Tanpa animasi, suara latar, hadiah, gamifikasi. Pengecualian: menggeser urutan kata di bilah ujaran (gerak hanya
    selama jari menyeret). Layar orang tua boleh memakai gerak halus yang menghormati setelan "hapus animasi".
12. Kontras teks ≥ 4,5:1, target sentuh ≥ 10 mm.
13. Status luring adalah keadaan normal, bukan peringatan.

**Pendamping**
14. Beban < 5 menit sehari. Satu misi, satu ketukan.
15. Nada bebas rasa bersalah: "Selesai" dan "Belum sempat hari ini" setara secara visual.
16. Pencatatan lahir dari pemakaian, bukan dari isian.

**Privasi**
17. Tidak pernah merekam audio ruangan, video, atau lokasi.
18. Rekaman suara keluarga tidak pernah meninggalkan perangkat, kecuali orang tua mengaktifkan tiruan suara dengan
    persetujuan eksplisit (PERUBAHAN #17). Server tidak menyimpan rekamannya, hanya `voice_id`.
19. Target dari terapis berstatus usulan yang boleh ditolak tanpa alasan.
20. Bukan alat diagnosis: tidak menyimpan diagnosis, skor klinis, atau penilaian kemampuan.
21. Foto papan tetap lokal kecuali pendamping memilih bantuan AI dan menyetujui pengiriman foto pada permintaan itu.
    Server tidak menyimpan foto; provider key tidak pernah masuk APK.

## Keputusan teknis

- Perangkat: **sqflite + DAO tulisan tangan**, tanpa codegen. Skema tunggal di `app/lib/data/db/schema.sql`,
  disalin ke `schema.dart` sebagai daftar pernyataan (tes memastikan keduanya identik).
- Keadaan: satu `AppState` (`ChangeNotifier`) diakses lewat `AppScope` (InheritedWidget) yang dipasang
  **di atas** `MaterialApp`. `AppScope.of` hanya di `build`/`didChangeDependencies`.
- `FutureBuilder` tidak pernah menerima future yang dibuat di `build()`; pakai `CachedFuture` dengan kunci
  `AppState.dataVersion`.
- Simbol PNG 256 px lewat `Image.asset`. Sel tanpa gambar menampilkan huruf pertama.
- Dua suara: ketukan anak = audio bundel → TTS id-ID nada 1,3; ketukan pendamping = rekaman keluarga →
  audio bundel → TTS nada 1,0. Semua panggilan plugin diberi timeout.
- Halaman 0 berisi 12 kata inti dengan susunan tetap 3 × 4. Halaman kategori: sel 0–5 = posisi 0–5 halaman 0
  (cermin **berdasarkan posisi**), konten mulai sel 6, gulir vertikal.
- Server: SQLite modul standar Python dengan WAL, tanpa Docker. Semua model masukan menolak medan tak dikenal (422).
- Autentikasi Bearer: token terapis dari env, token perangkat dikeluarkan sekali saat tebus kode undangan.
  Server hanya menyimpan SHA-256 token.
- `ts_device` selalu ISO-8601 **dengan** offset zona waktu.
- Format Dart: `dart format -l 140`.

## Kode peristiwa (`method`)

| Kode | Arti | `content` | `context` |
|---|---|---|---|
| `SEL` | pilih simbol halaman kata inti | `word_id` | `mission_id` di papan misi, selain itu rutinitas |
| `KAT` | pilih simbol halaman kategori | `word_id` | idem |
| `PRS` | kartu personal keluarga | `word_id` | idem |
| `HAP` | hapus satu langkah di bilah ujaran | `word_id` | idem |
| `UCP` | tekan UCAPKAN | `word_id` dipisah spasi | idem |
| `MIS` | konfirmasi misi harian | `selesai` \| `belum_sempat` | `mission_id` |
| `TGT` | jawaban atas usulan terapis (kata atau frasa) | `diterima` \| `ditolak` | `target_id` atau `phrase_id` |

`actor`: mode anak selalu `anak`; papan misi mengikuti tombol giliran; `MIS`/`TGT` selalu `pendamping`.
`prompt_level`: ketukan pendamping = `terpancing`; ketukan anak = `terpancing` bila ada ketukan pendamping
≤ 60 detik sebelumnya, selain itu `spontan`. Mnemonik ini khas Nyambung, bukan kode LAM resmi.

## Pembagian kerja

| Jalur | Branch | Folder |
|---|---|---|
| 1 Papan | `jalur-1-papan` | `app/lib/main.dart`, `app/lib/core/`, `app/lib/data/db/`, `app/lib/data/repo/`, `app/lib/data/models.dart`, `app/lib/features/board/`, `app/pubspec.yaml`, `app/android/`, `app/test/`, `app/assets/` |
| 2 Pendamping | `jalur-2-pendamping` | `app/lib/data/sync/`, `app/lib/features/{onboarding,coach,progress,vocab,settings}/` |
| 3 Server | `jalur-3-server` | `server/`, `tools/`, `seed/`, `README.md`, `.gitignore`, `.gitattributes`, `assets/`, `CLAUDE.md` |
| 4 Dasbor | `jalur-4-dashboard` | `dashboard/`, `PERUBAHAN.md`, `deck/` |

Hanya ubah folder milik jalurmu. Butuh paket baru, rute di `main.dart`, atau metode baru di `AppState`/DAO:
minta ke jalur 1 lewat status dan lisan.

## Alur git

- Kerja di branch jalur, selalu ter-push. Satu tonggak per commit.
- **Pesan commit deskriptif dalam bahasa Inggris**, menceritakan alur pembangunan, tanpa awalan kode jalur.
  Contoh: `Build initial app architecture: state, database, and bootstrap`,
  `Add core vocabulary schema and one-time CSV loader`, `Implement fixed-position communication board`.
- Setiap commit memperbarui `status/jalur-N.md` (sedang dikerjakan, tag selesai, terblokir oleh,
  permintaan ke jalur lain, perubahan API).
- Tonggak selesai: pemeriksaan hijau → `git rebase origin/main` → `git push origin HEAD:main`
  (fast-forward saja; `--force` ke `main` dilarang) → push tag tonggak (`j1-kerangka`, `j3-sync`, dst.).
- Cek jalur lain: `git fetch origin --tags`, lihat `git tag -l`, lalu baca `git show origin/<branch>:status/jalur-N.md`.
- Jangan `git add .` di akar. Konflik rebase di folder jalur lain: berhenti, panggil pemiliknya.
- Jangan commit `.env`, `*.db`, `app/android/key.properties`, `*.jks`, `node_modules/`, `build/`.

## Pemeriksaan per bagian

- **app:** `dart fix --apply` → `dart format lib test -l 140` → `dart analyze` bersih → `flutter test` lulus →
  jalankan di emulator/HP dan buka layar yang berubah. Analyzer bersih bukan bukti layar jalan.
- **server:** `pytest` lulus; uvicorn selalu `--host 0.0.0.0`.
- **dashboard:** `npm run build` bersih.

## Aturan kerja

- Alamat server selalu `127.0.0.1` atau IP eksplisit, **tidak pernah `localhost`** (di Windows mencoba IPv6 dulu).
- Data demo selalu berlabel **ilustratif**, di berkas dan di antarmuka.
- Setiap perubahan terhadap proposal dicatat di `PERUBAHAN.md` saat itu juga.
- Jujur terhadap batasan sistem: yang belum ada, sebut belum ada.
- Seluruh kode ditulis di repositori ini. Konten dari luar hanya yang tercatat di `assets/PROVENANCE.md`.
- Windows: bila build Gradle gagal "Unable to establish loopback connection", arahkan `TEMP`/`TMP` ke folder
  tanpa spasi (mis. `C:\dev\tmp`) lalu build ulang.
