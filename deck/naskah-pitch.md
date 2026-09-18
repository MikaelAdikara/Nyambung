# Nyambung — Naskah Pitch Final (5 menit)

Hackathon IFEST 2026 · *Tech for Human Connections* · Tim Teen Tensors

Pasangan berkas: `deck/Nyambung-Pitch-Deck.pptx` (dan `.pdf`). Naskah per slide juga ada di *speaker notes*. Sumber
riset tambahan beserta batasnya: `deck/riset-pendukung.md`.

**Cara pakai.** Hafalkan maksud tiap bagian, bukan kata per kata. Kalimat bercetak tebal adalah kalimat kunci yang
harus keluar. `[DEMO]` adalah aksi di HP atau laptop. Angka hanya dari `docs/hackday/03-basis-ilmiah.md`,
`deck/riset-pendukung.md`, atau hasil uji tim sendiri (lihat "Asal angka").

**Nada.** Empati di pembuka dan penutup, klinis di tengah: sebut sumber, sebut batas, jangan melebih-lebihkan.

---

## Peta waktu

| Waktu | Slide | Bagian | Pilar juri |
|---|---|---|---|
| 0:00–0:10 | Judul *(manual)* | Perkenalan | — |
| 0:10–0:30 | Hook *(manual)* | Tiga kalimat | Masalah |
| 0:30–0:55 | 1 | Data masalah | **Masalah** |
| 0:55–1:12 | 2 | Celah di antara fitur | Masalah |
| 1:12–1:22 | 3 | Nyambung: satu loop | **Solusi** |
| 1:22–1:47 | 4 | [DEMO] Papan luring + suara | Solusi |
| 1:47–1:59 | 5 | Aset dan sumbernya | Solusi |
| 1:59–2:19 | 6 | [DEMO] Pendamping harian | Solusi |
| 2:19–2:37 | 7 | Kenapa misinya dirancang begini (riset) | Solusi |
| 2:37–2:57 | 8 | [DEMO] Sinkron otomatis + arsitektur | Solusi / Kelayakan teknis |
| 2:57–3:24 | 9 | [DEMO] Dasbor terapis + usulan kata | Solusi |
| 3:24–3:39 | 10 | Basis ilmiah + opini FORMAPI UB | Solusi (validasi) |
| 3:39–4:06 | 11 | Kelayakan: sudah jalan, biaya, penerapan | **Kelayakan** |
| 4:06–4:34 | 12 | Dampak + metrik terukur | **Dampak** |
| 4:34–4:48 | 13 | Penutup | — |
| 4:48–5:00 | | **Cadangan 12 detik** (demo lambat, jeda sinkron) | |

Slide 14–16 adalah **lampiran untuk Q&A** (12 kata inti, batasan dan roadmap, ringkasan `PERUBAHAN.md`). Jangan
ditampilkan saat pitch; buka hanya bila juri bertanya.

Latar belakang dipangkas dari ±1 menit 40 detik (naskah lama 0:30–2:10) menjadi 42 detik (slide 1–2).

---

## 0:00–0:10 · Judul dan perkenalan *(slide manual)*

> "Selamat pagi, Bapak dan Ibu juri. Kami Teen Tensors: saya Mikael, bersama [nama], [nama], dan [nama]."

Catatan: jangan menyebut nama produk dulu kalau slide judul juga belum memperlihatkan logo. Nama Nyambung baru
muncul di slide 3.

## 0:10–0:30 · Hook *(slide manual)*

> "Bayangkan mulai hari ini Anda tidak bisa lagi mengucapkan tiga kalimat ini:
> **Aku sakit. Aku mau minum. Tolong berhenti.**
> Sakitnya tetap terasa. Hausnya tetap ada. Yang berubah hanya satu: orang lain harus menebak.
> Bagi sebagian anak autis nonverbal, ini bukan bayangan satu hari. Ini keseharian mereka:
> dua orang di ruangan yang sama, tapi tidak tersambung."

## 0:30–0:55 · Slide 1 — Masalah

> "Datanya jelas. **25 sampai 30 persen anak autis tetap minimally verbal setelah usia lima tahun.**
> Teknologinya sebenarnya sudah ada: AAC, papan simbol yang bisa bersuara. Tapi **29,3 persen alat bantu ditinggalkan
> sepenuhnya**, paling banyak di tahun pertama. Dan menurut survei 275 terapis wicara, penyebabnya
> **kurang pelatihan dan kurang dukungan**, bukan anaknya.
> Jadi masalahnya bukan di papan. Keluarga tidak pernah diajari 'bicara balik' dengan papan itu, dan terapis tidak
> tahu apa yang terjadi di rumah di antara sesi."

## 0:55–1:12 · Slide 2 — Celah

> "Solusi yang ada sudah kuat di bagiannya masing-masing. BerKata membawa AAC ke Bahasa Indonesia. Jellow gratis dan
> luring. Avaz matang di kustomisasi dan materi pendamping. CoughDrop punya laporan dan kolaborasi tim.
> Kami belum menemukan satu alur yang menyatukan semuanya untuk keluarga Indonesia.
> **Celahnya bukan di satu fitur. Celahnya ada di antara fitur.**"

## 1:12–1:22 · Slide 3 — Nyambung

> "Maka kami membangun **Nyambung**: AAC luring-pertama yang menyambungkan anak, keluarga, dan terapis dalam satu loop.
> Bukan hanya memberi anak suara, tapi **memastikan suaranya sampai, dipahami, dan kembali menjadi intervensi.**"

## 1:22–1:47 · Slide 4 — Papan bicara `[DEMO]`

`[DEMO]` Tunjukkan HP sudah **mode pesawat**. Tekan **AKU → MAU → MINUM**, biarkan suaranya keluar.

> "HP ini tidak punya internet. **Kalau anak butuh sinyal untuk bilang 'aku sakit', sistemnya belum aksesibel.**
> Dua belas kata inti ini dipilih dari literatur, dan posisinya tidak pernah pindah, karena anak menghafal gerakan
> tangan. Suaranya dua lapis: suara papan yang sama di setiap HP, dan suara Ibu atau Ayah untuk dua belas kata inti.
> **Rekaman itu tidak pernah keluar dari HP.** Suara sintetis personal masih roadmap, bukan klaim hari ini."

## 1:47–1:59 · Slide 5 — Aset dan sumbernya

> "Semua aset kami punya asal yang jelas. **Simbolnya dari Mulberry Symbols karya Steve Lee, berlisensi terbuka CC
> BY-SA 4.0**, digambar desainer dan ditinjau terapis wicara. Kata yang tidak punya padanan jujur kami gambar sendiri
> dengan gaya yang sama. Suara papan diberi label suara buatan AI, dan semua aset tercatat lengkap dengan hash-nya."

## 1:59–2:19 · Slide 6 — Pendamping harian `[DEMO]`

`[DEMO]` Pindah ke beranda orang tua. Tunjukkan kartu **"Tekan MAU lima kali saat makan"**, buka papan bersama,
tekan MAU dua kali di giliran pendamping, kembali: **2 dari 5**. Tunjuk dua tombol setara.

> "Yang perlu belajar bukan hanya anak. **Lingkungannya juga.**
> Setiap hari orang tua mendapat satu pelajaran 60 detik dan satu misi di bawah lima menit yang menempel pada
> rutinitas. Penghitungnya terisi sendiri dari ketukan. **Tanpa streak, tanpa rasa bersalah, tanpa formulir.**"

## 2:19–2:37 · Slide 7 — Kenapa misinya dirancang begini

> "Desain misinya tidak kami karang. **Intervensi yang dijalankan orang tua, dan intervensi yang disisipkan di
> rutinitas, termasuk praktik berbasis bukti untuk autisme** menurut tinjauan 972 studi. Uji acak pada 82 balita
> menunjukkan pelatihan orang tua di kegiatan sehari-hari meningkatkan komunikasi sosial.
> Kenapa tanpa streak? Riset kebiasaan menunjukkan **melewatkan satu hari tidak merusak pembentukan kebiasaan.**
> Yang belum teruji, seperti pelajaran 60 detik, kami tandai dan uji di pilot."

## 2:37–2:57 · Slide 8 — Sinkron otomatis dan arsitektur `[DEMO]`

`[DEMO]` Matikan mode pesawat. **Jangan tekan apa pun.** Bicara sambil menunggu (sinkron berjalan tiap 20 detik
selama aplikasi terbuka).

> "Sekarang saya nyalakan internetnya, dan saya tidak menekan tombol kirim.
> Arsitekturnya *local-first*: setiap ketukan ditulis ke log yang tidak bisa diubah, bersama antrean kirimnya,
> **dalam satu transaksi**. Saat dikirim ulang, server mengenali ID yang sama, jadi tidak ada data ganda. Kami sudah
> mengujinya dengan mematikan proses secara paksa: hasilnya identik.
> **Bagi pengguna kami, koneksi putus bukan kasus pinggiran. Itu syarat desain.**"

## 2:57–3:24 · Slide 9 — Dasbor terapis `[DEMO]`

`[DEMO]` Buka dasbor di laptop (D1). Tunjuk badge **Perlu ditinjau** dan alasannya. Masuk D3, usulkan **BERHENTI**,
kirim. Di HP: kartu usulan → **Terima**.

> "Ketukan tadi sudah sampai. Tapi kalau kami hanya melempar ratusan data, bebannya cuma pindah ke terapis.
> Jadi dasbor menandai anak yang perlu ditinjau, **selalu dengan alasannya**. Aturannya tetap dan bisa diperiksa.
> **Bukan 'kata AI'; keputusan klinis tetap di tangan terapis.**
> Terapis lalu mengusulkan kata baru. Di HP, keluarga memilih **Terima atau Tolak, tanpa perlu alasan.**"

## 3:24–3:39 · Slide 10 — Basis ilmiah dan validasi

> "Kami tidak mengklaim Nyambung sudah terbukti efektif; kami merakit praktik yang sudah terbukti.
> Kami juga meminta pendapat **[A], Ketua Umum FORMAPI Universitas Brawijaya**, yang berpengalaman mendampingi anak
> berkebutuhan khusus: *'[kutipan singkat asli dari A]'*.
> **Validasi klinis bersama terapis wicara adalah bagian dari pilot kami.**"

## 3:39–4:06 · Slide 11 — Kelayakan

> "Apakah layak? Ini sudah berjalan, dibangun dalam 24 jam: APK rilis 18 MB untuk Android 8 dengan RAM 2 GB, dan
> **78 tes otomatis lulus.**
> Bagi keluarga, biayanya **nol rupiah**: tanpa kuota untuk bicara, simbol berlisensi terbuka, dan suara 120 kata
> dibuat sekali dengan biaya di bawah 20 sen dolar.
> Kami mulai dengan pilot enam pekan bersama satu terapis wicara, lalu tumbuh lewat terapis, karena **setiap kode
> undangan terapis adalah pintu masuk satu keluarga.**
> Batasannya kami tulis terbuka: belum HTTPS, dan [belum diuji di HP fisik 2 GB — perbarui bila sudah]."

## 4:06–4:34 · Slide 12 — Dampak

> "Dampaknya kami ukur dengan jujur. Masalah intinya alat ditinggalkan, jadi **metrik utama pilot adalah retensi hari
> ke-14, minimal 60 persen.**
> Pendukungnya: hari misi terlaksana, usulan yang dijawab keluarga, dan waktu tinjauan terapis yang diukur otomatis.
> Jumlah kata kami baca sebagai **pola pemakaian, bukan nilai kemampuan anak.**
> Kalau tinjauan cukup lima menit per anak, satu jam terapis bisa memantau dua belas keluarga. **Itu asumsi, dan
> pilot yang akan mengujinya.**"

## 4:34–4:48 · Slide 13 — Penutup

> "Nyambung bukan sekadar papan bicara. Kami menyambungkan suara anak, kapasitas keluarga, dan keahlian terapis.
> Karena hubungan antarmanusia tidak dimulai saat seseorang bisa bicara.
> **Hubungan dimulai saat ia bisa dipahami.**
> Anak. Keluarga. Terapis. **Nyambung.**"

`[Tahan 2 detik.]`

---

## Opini profesional: FORMAPI UB

**Yang harus diisi tim sebelum tampil (slide 10 dan naskah):** nama lengkap A, jabatan, dan satu kutipan asli
(≤ 25 kata) dari percakapan dengan A. Minta izin A untuk namanya dipakai. **Jangan mengarang kutipan.**

Posisikan dengan tepat, karena juri bisa bertanya:

- FORMAPI adalah Forum Mahasiswa Peduli Inklusi. A adalah **praktisi pendamping anak berkebutuhan khusus**, bukan
  terapis wicara berlisensi. Sebut "masukan praktisi" atau "konsultasi", **jangan "validasi klinis"**.
- Yang sudah dikonsultasikan dengan FORMAPI UB: pemilihan kata (`03-basis-ilmiah.md` §8). Bila A juga memberi masukan
  soal alur pendampingan orang tua, sebut itu; kalau tidak, ubah baris kedua "Tangga validasi" di slide 10.
- Kalimat siap pakai: *"Pemilihan kata berbasis literatur dengan alasan tertulis per kata, sudah dikonsultasikan
  dengan FORMAPI UB, dan validasi klinis bersama terapis wicara adalah bagian dari pilot."*

---

## Jawaban Q&A yang harus konsisten

| Pertanyaan | Jawaban |
|---|---|
| Apa kebaruannya kalau AAC sudah ada? | Integrasinya: AAC Bahasa Indonesia yang luring, pelatihan orang tua di dalam rutinitas, bukti otomatis dari rumah, triase beralasan, dan usulan yang bisa ditolak keluarga, dalam satu loop. |
| Sudah ada terapis yang memverifikasi? | Pemilihan kata berbasis literatur dan sudah dikonsultasikan dengan FORMAPI UB; opini [A] sebagai praktisi. Validasi klinis bersama terapis wicara adalah pilot enam pekan kami. Daftar kata belum ditinjau terapis wicara (`therapist_ok = belum`). |
| Bukti misi harian berhasil? | Komponennya berbasis bukti: intervensi oleh orang tua, intervensi di rutinitas, dan *time delay* termasuk praktik berbasis bukti (NCAEP 2020); RCT Wetherby 2014; *aided modeling* efektif (Biggs 2018, O'Neill 2018). **Paket misi Nyambung sendiri belum diuji**; itu tujuan pilot. |
| Kenapa tidak ada streak atau hitungan hari beruntun? | Melewatkan satu kesempatan tidak berpengaruh berarti pada pembentukan kebiasaan (Lally 2010); orang tua anak *minimally verbal* sudah menanggung stres pengasuhan lebih tinggi (Guerrera 2025). |
| Berapa lama sampai jadi kebiasaan? | Median 59–66 hari (Keller 2021; Lally 2010). Jadi retensi hari ke-14 hanya sinyal awal, dan pilot 6 pekan belum menjangkau median itu. |
| Simbolnya dari mana, boleh dipakai? | Mulberry Symbols © Steve Lee, CC BY-SA 4.0: boleh komersial dengan atribusi, turunan berlisensi sama, simbolnya tidak boleh dijual. 85 simbol dipakai tanpa diubah; 35 kata digambar tim. |
| Simbolnya cocok untuk anak Indonesia? | Mulberry dirancang untuk pengguna dewasa. Simbol yang lebih mudah ditebak lebih cepat dipelajari (Mizuko 1987), jadi kecocokannya diuji di pilot; simbol buatan tim belum diuji pada anak. |
| AAC bikin anak malas bicara? | Tidak. Tinjauan 23 studi: AAC tidak menghambat dan bisa menambah produksi bicara (Millar 2006). |
| Kenapa tidak pakai AI untuk terapis? | Keputusan klinis harus bisa dijelaskan dan diperiksa. Triase memakai aturan tetap dengan alasan tertulis. Tidak ada model ML saat aplikasi berjalan. |
| Suaranya rekaman manusia? | Suara papan adalah klip sintetis yang dibuat sekali lalu dibundel di APK: luring dan sama di semua HP, tapi bukan rekaman manusia. Keluarga bisa merekam suaranya sendiri untuk 12 kata inti. |
| Voice cloning sudah jadi? | Belum. Syaratnya kalau dibangun: rekaman keluarga tetap tidak meninggalkan perangkat (invarian privasi 18). |
| Bagian teknis tersulit? | Menjaga kesinambungan data tanpa membuat komunikasi anak bergantung pada server: perangkat sebagai sumber kebenaran, log append-only, outbox dalam satu transaksi, sinkron idempoten. |
| Apakah menggantikan terapis? | Tidak. Nyambung memindahkan beban mengumpulkan informasi dari terapis, bukan penilaian klinisnya. |
| Data anak dikirim, persetujuannya? | Hanya setelah orang tua menebus kode undangan sekali pakai (UU PDP Pasal 25). Yang dikirim hanya ketukan simbol dan konfirmasi misi; tidak ada audio, video, foto, atau lokasi. Belum: HTTPS dan enkripsi di perangkat. |
| Penghitung misi bisa dicurangi? | Bisa. Yang dicatat ketukan contoh, bukan interaksi. Karena itu metrik utama pilot retensi; misi indikator pendukung. |

---

## Yang diubah dari naskah sebelumnya, dan alasannya

1. **Latar belakang dipadatkan** dari 1:40 menjadi 0:42. Tema dan "dua orang di ruangan yang sama" digabung ke hook.
2. **Ditambah slide judul dan perkenalan 10 detik** (dikerjakan manual bersama slide hook).
3. **"Brady et al. (2021)" dihapus**, karena `03-basis-ilmiah.md` §9 mencatat publikasi yang cocok tidak ditemukan.
4. **Ditambah slide aset (5):** asal simbol Mulberry, simbol tim, kosakata, suara, font, dan jejak audit.
5. **Ditambah slide riset misi (7):** setiap elemen misi dikaitkan ke bukti yang sudah diverifikasi, dan yang belum
   teruji ditandai D.
6. **Ditambah slide basis ilmiah + opini FORMAPI UB (10)**, dengan posisi jujur: konsultasi praktisi, bukan validasi
   klinis.
7. **Ditambah slide Kelayakan dan Dampak tersendiri (11, 12)**, pilar wajib deck dengan bobot 20% di penilaian.
8. **"Tiga level suara" diluruskan** dengan yang benar-benar dibangun.
9. **"Diam 1–2 detik lalu data muncul" diganti** dengan menjelaskan arsitektur sambil menunggu (sinkron tiap 20 detik).
10. **Contoh usulan diganti ke BERHENTI**, sesuai lingkar demo `00-rencana.md` §4.
11. **"Penyebab utama" di slide 1 tidak diberi label "#1"**; Johnson 2006 menyebut beberapa faktor, jadi slide
    memakai angka 275 terapis wicara.

## Asal angka

| Angka | Sumber |
|---|---|
| 25–30% anak autis tetap *minimally verbal* setelah 5 tahun | Tager-Flusberg & Kasari (2013) |
| 29,3% alat bantu ditinggalkan, terbanyak di tahun pertama | Phillips & Zhao (1993), 227 responden |
| Kurang pelatihan dan dukungan | Johnson, Inglebret, Jones & Ray (2006), survei 275 terapis wicara |
| 972 artikel, 28 praktik berbasis bukti; PII 55, NI 75, Time Delay 31 artikel | Steinbrenner dkk. (2020), NCAEP, Tabel 3.1 |
| RCT 82 balita, pelatihan orang tua di kegiatan sehari-hari | Wetherby dkk. (2014), *Pediatrics* |
| 48 studi, 267 anak, *aided modeling* umumnya efektif | Biggs, Carter & Gilson (2018), *AJIDD* |
| d = 0,65 dari 94 studi | Gollwitzer & Sheeran (2006) |
| Median 66 hari; melewatkan satu kesempatan tidak berpengaruh berarti | Lally dkk. (2010), 96 orang |
| RCT 192 orang, median 59 hari, pengulangan prediktor utama | Keller dkk. (2021), *BJHP* |
| AAC tidak menghambat bicara, 23 studi | Millar, Light & Schlosser (2006) |
| Simbol transparan lebih mudah dipelajari anak 3 tahun | Mizuko (1987) |
| +19 / +22 ujaran komunikatif (pekan 12 / 24) | Kasari dkk. (2014), 61 anak |
| 3,3 dtk vs 6,0 dtk menemukan simbol | Thistle dkk. (2018) |
| 9 dari 12 kata inti ada di Banajee (2003) atau Project Core | `03-basis-ilmiah.md` §3 |
| Retensi hari ke-14 ≥ 60% | `03-basis-ilmiah.md` §6 |
| 45 tes server + 33 tes aplikasi = 78 lulus | `pytest` 18 Sep 14:45; `status/jalur-1.md` |
| Uji mati paksa: 60 diterima + 40 duplikat → identik | `status/jalur-3.md` |
| Angka dasbor = server, 0 selisih | uji jalur 4 |
| APK rilis 18,2 MB (armeabi-v7a) | `README.md` |
| Jeda ketukan → suara median 21 ms (emulator 2 GB, bukan HP fisik) | `README.md` |
| Klip suara 120 kata < US$0,20 | `PERUBAHAN.md` entri 3 |
| Server pilot ± Rp100–150 rb/bulan | **estimasi** harga VPS kecil, belum termasuk domain dan HTTPS |
| 175 berkas aset diverifikasi SHA-256 | `assets/PROVENANCE.md` |
| 16 perubahan tercatat | `PERUBAHAN.md` |

**Perlu dicek tim sebelum tampil:**
- Klaim fitur kompetitor (BerKata, Jellow, Avaz, CoughDrop) berasal dari naskah awal dan belum ada di sumber mana pun
  di repo. Cocokkan dengan situs resmi masing-masing dan simpan tautannya untuk Q&A.
- Estimasi biaya server: ganti dengan harga penyedia yang benar-benar akan dipakai.
- Status "belum diuji di HP fisik 2 GB" di slide 11: perbarui begitu `int-1-hp-ke-d2` atau uji HP fisik selesai.
