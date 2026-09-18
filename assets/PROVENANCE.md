# Asal-usul aset konten

Folder `assets/` berisi **konten**, bukan kode: data kosakata, gambar simbol, dan lisensinya.
Semuanya disiapkan tim sebelum Hack Day dan dibawa masuk pada jam ke-0. Tidak ada berkas kode di folder ini.

Setiap berkas di bawah tercatat hash SHA-256-nya di `assets/PROVENANCE.sha256`. Untuk memeriksa bahwa isinya
tidak berubah sejak disiapkan:

```
sha256sum -c assets/PROVENANCE.sha256        # Git Bash / Linux
shasum -a 256 -c assets/PROVENANCE.sha256    # macOS
```

Hasil yang benar: 175 baris `OK`, nol `FAILED`.

---

## Data kosakata

| Berkas | Isi | Cara dibuat | Sumber dan lisensi |
|---|---|---|---|
| `vocab/core_vocab_id.csv` | 120 kata inti Bahasa Indonesia, 13 kolom | Ditulis dari tabel `docs/hackday/05-kosakata-dan-simbol.md` §3. Lulus lima pemeriksaan §2: 120 baris, halaman 0 sesuai `00-rencana.md` §3, tanpa slot ganda, tanpa slot cermin terpakai, jumlah per halaman cocok. | Riset tim. Dasar pemilihan kata: `docs/hackday/03-basis-ilmiah.md`. |
| `vocab/pages.csv` | 13 halaman papan | Ditulis dari tabel §4 dokumen yang sama | Riset tim |
| `vocab/_source/id_50k_2018.txt` | 50.000 kata teratas OpenSubtitles 2018 Bahasa Indonesia, beserta jumlah kemunculan | Diunduh apa adanya, tidak diubah | hermitdave/FrequencyWords (kode MIT); data turunan korpus OpenSubtitles2018 dari OPUS. Rincian: `vocab/_source/SOURCE.md` |
| `vocab/_source/SOURCE.md` | Tanggal unduh, commit sumber, hash, keterbatasan korpus | Ditulis tim | — |

Kolom `freq_rank` di CSV bisa diperiksa langsung terhadap `id_50k_2018.txt`: peringkat = nomor baris kata itu.
Kolom `therapist_ok` bernilai `belum` di semua baris karena daftar ini **belum ditinjau terapis wicara**.

## Simbol

| Berkas | Jumlah | Cara dibuat | Sumber dan lisensi |
|---|---|---|---|
| `symbols/mulberry/{word_id}.svg` | 85 | SVG asli Mulberry, isi tidak diubah, hanya diganti nama menjadi `word_id` | Mulberry Symbols v3.6.1 © Steve Lee, **CC BY-SA 4.0**. Diunduh 13 Sep 2026 dari rilis resmi GitHub, `mulberry-symbols.zip`, SHA-256 `9da3f23a17bd71aec3c94eae9a3367e977e7b65d3d7feeaadb3f4690182aa05b` |
| `symbols/png/{word_id}.png` | 85 | SVG di atas dirasterkan ke PNG 256 × 256, latar transparan | Sama dengan di atas. Rasterisasi bukan perubahan isi gambar. |
| `symbols/LICENSE-mulberry.txt` | 1 | Teks lisensi dari rilis Mulberry | — |
| `symbols/ATTRIBUTION.md` | 1 | Ditulis tim | — |
| `symbols/custom/` | **0** | **Kosong.** 35 simbol gambar tim dibuat saat Hack Day (`05-kosakata-dan-simbol.md` §6) | CC BY-SA 4.0 saat dibuat |

Pemetaan `word_id` ke nama berkas asli Mulberry ada di kolom `simbol` tabel `05-kosakata-dan-simbol.md` §3.
Kecocokan 85 nama itu dengan berkas di sini sudah diperiksa otomatis pada 17 Sep 2026: semua cocok, dan tidak ada
PNG Mulberry untuk 35 kata yang ditandai gambar tim.

## Audio

`audio/core/` **kosong**. Tidak ada rekaman suara yang dibawa. Papan memakai TTS perangkat sampai ada rekaman.

---

## Yang tidak ada di folder ini

Tidak ada kode aplikasi, server, papan pantau, skrip pembuat data, APK, keystore, maupun data peristiwa.
Semuanya dibangun di dalam jendela Hack Day 18–19 September 2026 dan terlihat di riwayat commit.
