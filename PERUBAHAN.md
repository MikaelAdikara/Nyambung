# Perubahan terhadap Proposal

Setiap perubahan dicatat saat itu juga, satu entri per perubahan.

Format entri:

```
## <judul singkat> (<jam>, jalur <N>)
- **Kondisi di proposal:** ...
- **Yang diubah:** ...
- **Alasan:** ...
- **Dampak terhadap masalah inti:** ...
```

---

## 1. Kelola kosakata (C2) dan kartu dari foto (C3) tidak dibangun (10:45, jalur 2)
- **Kondisi di proposal:** Layar C2 "Kelola kosakata" untuk menyembunyikan simbol tanpa menggeser posisinya dan
  menambah kartu baru, serta C3 "Kartu baru dari foto" untuk membuat kartu personal dari foto benda milik anak
  (mockup P dan Q di lampiran proposal).
- **Yang diubah:** Kedua layar tidak dibangun selama Hack Day. Papan memakai 120 kata tetap dari berkas kosakata.
- **Alasan:** Urutan buang #1 yang disepakati sebelum acara (`00-rencana.md` §6). Waktu dialihkan ke papan luring,
  pencatatan, sinkron, dan jembatan terapis yang menjadi jalur demo.
- **Dampak terhadap masalah inti:** Papan bicara tetap luring penuh dengan posisi simbol yang tidak pernah berpindah
  (M1). Keluarga belum bisa menambahkan kata khas rumah (benda milik anak, nama orang dekat) atau menyembunyikan kata;
  kosakata hanya bisa berubah lewat pembaruan aplikasi.

## 2. Suara keluarga hanya direkam untuk satu kata (10:45, jalur 2)
- **Kondisi di proposal:** Layar C4 "Suara keluarga" merekam suara ibu atau ayah per kata inti, dengan daftar kata dan
  keterangan kata mana yang sudah memakai suara keluarga dan mana yang masih suara HP (mockup R).
- **Yang diubah:** Rekaman dibuat sekali di pemasangan (A5) untuk satu kata, MAU (kata misi pertama). Layar C4 untuk
  merekam kata lain belum ada; kata selain MAU memakai suara HP (TTS luring). Rekaman tetap hanya tersimpan di perangkat.
- **Alasan:** Rekaman suara keluarga ada di urutan buang #4 (`00-rencana.md` §6). Satu kata cukup untuk membuktikan
  alurnya (izin mikrofon, simpan lokal, putar saat pendamping mengetuk) tanpa menghabiskan waktu jalur kritis.
- **Dampak terhadap masalah inti:** Saat memberi contoh (M2), anak mendengar suara orang tuanya hanya untuk MAU;
  kata lain terdengar dengan suara HP. Suara papan saat anak sendiri yang mengetuk tidak berubah, karena memang
  dirancang memakai suara papan, bukan suara ibu.

## 3. Suara papan memakai klip sintetis yang dibundel, bukan TTS perangkat (10:40, jalur 1 & 3)
- **Kondisi di proposal:** Papan bicara memakai suara TTS bawaan perangkat (id-ID) secara luring. Ketukan anak dengan
  nada 1,3 dan ketukan pendamping dengan nada 1,0 supaya terdengar berbeda. Folder audio bundel disiapkan kosong.
- **Yang diubah:** Setiap kata dari 120 kata sekarang punya klip suara yang dibundel di dalam APK
  (`app/assets/audio/core/`). Ada dua set: suara remaja cowok (`cowo`, bawaan) dan cewek (`cewe`). Klip dibuat sekali
  di laptop dengan OpenAI TTS (`gpt-4o-mini-tts`, suara fable dan marin), bukan saat aplikasi berjalan. Ketukan satu
  kata dan tombol UCAPKAN sama-sama memutar klip ini secara berurutan. TTS perangkat tetap jadi cadangan kalau ada kata
  tanpa klip. Asal-usul lengkap ada di `assets/PROVENANCE.md` bagian Audio.
- **Alasan:** Banyak HP Android murah di Indonesia tidak punya mesin TTS Bahasa Indonesia, atau suaranya terdengar
  robotik. Suara papan adalah suara anak, jadi harus sama di setiap perangkat dan tidak bergantung pada ROM. Klip statis
  tetap luring penuh dan tidak butuh model ML saat aplikasi berjalan (invarian 1 dan 5). Biaya pembuatan kurang dari
  $0,20, dan APK hanya bertambah ± 1 MB.
- **Dampak terhadap masalah inti:** M1 menguat, karena suara papan konsisten dan jelas tanpa internet di perangkat apa
  pun. Batasan yang perlu disebut jujur:
  - suaranya **sintetis buatan AI, bukan rekaman manusia**;
  - lafal belum ditinjau satu per satu, dan beberapa kata mungkin masih beraksen Inggris;
  - bila tidak ada rekaman keluarga, ketukan pendamping memakai klip yang sama dengan ketukan anak, sehingga beda nada
    1,0 / 1,3 hilang;
  - pilihan cowok/cewek belum punya tombol di Pengaturan, jadi semua perangkat memakai suara cowok.
  Entri 2 ("kata selain MAU memakai suara HP") perlu disesuaikan: kata selain MAU sekarang memakai klip bundel ini.

## 4. Kelola kosakata (C2) dan suara keluarga per kata (C4) akhirnya dibangun (11:20, jalur 1 & 2)
- **Kondisi di proposal:** C2 menyembunyikan simbol tanpa menggeser posisinya; C4 merekam suara ibu atau ayah per kata
  inti. Entri 1 dan 2 mencatat keduanya ditunda.
- **Yang diubah:** Pengaturan kini punya **Kelola kosakata**: ketuk kata untuk menyembunyikan atau menampilkannya lagi,
  dan kata yang disembunyikan tetap memegang slotnya. Ada juga **Suara keluarga**: 12 kata inti dengan status rekaman,
  plus tombol rekam, dengarkan, ulangi, dan hapus. Pilihan **Suara papan** (cowok/cewek) juga sudah ada, jadi batasan
  terakhir di entri 3 tidak berlaku lagi.
- **Alasan:** Jalur kritis (papan, outbox, sinkron, target) sudah hidup, sehingga waktu tersisa dipakai untuk layar
  proposal yang paling murah dan tidak butuh paket baru.
- **Dampak terhadap masalah inti:** M2 menguat karena anak mendengar suara orang tuanya pada 12 kata inti, tidak hanya MAU.
  Yang **masih belum ada**: menambah kata atau kartu baru (C3 kartu foto), dan rekaman untuk kata di luar halaman inti.

## 5. Penanda tab TUBUH setelah SAKIT (11:20, jalur 1)
- **Kondisi di proposal:** SAKIT ada di posisi tetap halaman inti, dan kata tubuh ada di halaman TUBUH. Belum ada jalan
  pintas dari SAKIT ke TUBUH.
- **Yang diubah:** Setelah SAKIT diketuk, tab TUBUH digulir ke tampilan dan diberi garis toska. Papan tidak pindah
  halaman sendiri, tidak ada pop-up, tidak ada kosakata baru, dan tidak ada peristiwa tambahan. Kata tubuh yang diketuk
  tetap tercatat sebagai `KAT`.
- **Alasan:** Mempersingkat jalur "SAKIT + PERUT" tanpa sistem nyeri baru dan tanpa skala intensitas.
- **Dampak terhadap masalah inti:** Memperluas komunikasi fungsional S1 (M1). Ini bukan alat diagnosis: aplikasi tidak
  menyimpulkan penyebab atau tingkat sakit.

## 6. Sekarang → Nanti dan linimasa "Hari ini" (11:20, jalur 2)
- **Kondisi di proposal:** Misi menempel pada rutinitas, tapi belum ada urutan visual dua langkah. C1 hanya menampilkan
  ringkasan per pekan.
- **Yang diubah:** Beranda punya tombol **Sekarang → Nanti**: orang tua memilih dua kata yang sudah ada, lalu
  menunjukkannya ke anak sebagai dua kartu besar. Pasangan kata ini hanya disimpan di preferensi perangkat, tidak
  menjadi peristiwa, dan tidak dikirim ke server. C1 dibuka dengan bagian **Hari ini**, yaitu ujaran hari ini yang
  disusun otomatis dari log peristiwa. MIS dan TGT tidak pernah ditampilkan sebagai ujaran.
- **Alasan:** Data pemakaian lebih mudah dibaca keluarga dalam bentuk kalimat daripada grafik. Urutan kegiatan juga
  membantu rutinitas. Tidak ada formulir tambahan.
- **Dampak terhadap masalah inti:** Mendukung M2 dan M3 dari sisi keluarga. Urutan visual ini **belum punya rujukan di
  `03-basis-ilmiah.md`**, jadi tidak diklaim berbasis bukti.

## 7. Sinkron otomatis berkala (11:20, jalur 2)
- **Kondisi di proposal:** Peristiwa dikirim oleh pekerja latar saat jaringan tersedia.
- **Yang diubah:** Sebelumnya pengiriman hanya terjadi saat beranda dibuka, setelah kembali dari papan, atau lewat
  **Kirim sekarang**. Sekarang beranda juga mencoba kirim setiap 20 detik, dan sekali lagi saat aplikasi kembali aktif,
  sambil menarik usulan terapis. Ini hanya berjalan selama aplikasi terbuka. Belum ada layanan latar Android
  (WorkManager) yang jalan saat aplikasi tertutup.
- **Alasan:** Supaya skenario "mode pesawat dimatikan → catatan sampai ke terapis" berjalan tanpa tombol.
- **Dampak terhadap masalah inti:** Jembatan M3 terasa otomatis. Luring tetap keadaan biasa, bukan peringatan.

## 8. Dasbor menjelaskan alasan "Perlu ditinjau" dan mengganti label "spontan" (11:20, jalur 4)
- **Kondisi di proposal:** D1 memberi badge Perlu ditinjau. D2 menampilkan "rasio ujaran spontan".
- **Yang diubah:** Setiap badge di D1 sekarang disertai alasannya, diambil dari aturan `needs_review` yang sudah beku.
  D2 menampilkan kartu **Perlu diperiksa** yang juga memuat penurunan kata berbeda lebih dari 50% dan target diterima
  yang belum dipakai selama 7 hari, beserta kalimat bahwa ini aturan tetap, bukan kesimpulan klinis. D2 juga
  menampilkan pemakaian target yang diterima. Kartu "Ketukan spontan" diganti namanya menjadi **"Ketukan anak tanpa
  contoh ≤ 60 dtk"**. Kontrak API tidak berubah.
- **Alasan:** Aplikasi tidak merekam suara, jadi tidak bisa tahu apakah anak dipancing secara lisan. Label yang jujur
  hanya menyebut apa yang teramati. Alasan yang terlihat membuat triase terapis bisa dijelaskan.
- **Dampak terhadap masalah inti:** M4: terapis bisa langsung melihat siapa yang perlu ditinjau dan kenapa. Nama medan
  `spontaneous_ratio` di API tetap sama. Teks D4 sejak awal sudah memakai rumusan "tanpa contoh dalam 60 detik".

## 9. Terapis masuk dengan email dan kata sandi; keluarga tetap tanpa akun (11:30, jalur 3 & 4)
- **Kondisi di proposal:** Terapis masuk papan pantau dengan token Bearer dari variabel lingkungan server, ditempel
  di gerbang token. Keluarga tertaut lewat kode undangan, tanpa akun.
- **Yang diubah:** Server mendapat login email + kata sandi (`POST /v1/auth/login`, `/logout`, `GET /v1/auth/me`),
  tabel `therapist_login` (hash scrypt) dan `therapist_session` (token sesi 30 hari, hanya SHA-256 disimpan). Akun dibuat
  pengelola lewat `tools/create_therapist.py`; dua akun demo ilustratif disediakan. Gerbang dasbor meminta email dan
  kata sandi; token server tetap bisa dipakai lewat tautan "Pakai token server". Layar A1 aplikasi mendapat tautan kecil
  "Saya terapis →" yang menunjukkan alamat papan pantau. Kontrak §4 bertambah tiga endpoint; endpoint lama tidak berubah.
- **Alasan:** Menempel token panjang tidak layak untuk terapis sungguhan bila aplikasi dikomersialkan. Keluarga sengaja
  tidak diberi login: papan harus jalan luring sejak dibuka pertama kali (invarian 1) dan pemasangan hanya menanyakan
  nama panggilan dan usia.
- **Dampak terhadap masalah inti:** Jembatan terapis (M3) dan satu terapis untuk banyak keluarga (M4) kini bisa dipakai
  terapis tanpa bantuan pengelola server setiap kali masuk; setiap terapis hanya melihat keluarga yang tertaut kepadanya.
  Papan anak (M1) tidak berubah dan tetap luring. Belum ada: lupa kata sandi, pembatasan laju login, hapus akun.


## 10. Tab halaman papan pindah ke rel kiri dan diberi nama bermakna (12:05, jalur 1)
- **Kondisi di proposal:** Tab 13 halaman berbaris horizontal di bawah papan dan bergulir ke samping. Halaman 1, 2, 4, 5
  bernama KATA INTI 2, KATA INTI 3, KEGIATAN, KEGIATAN 2.
- **Yang diubah:** Tab menjadi satu kolom tetap di kiri papan (ikon + label, tinggi 64 dp), urutan dan posisinya tidak
  berubah. Nama baru: INTI, SIAPA & BOLEH, ARAH & JUMLAH, GERAK, SEHARI-HARI; halaman lain tetap. Nomor halaman dan
  posisi kata tidak berubah, jadi peristiwa, sinkron, dan dasbor tidak terdampak. `pages.csv` dibaca ulang setiap
  bootstrap, jadi perangkat yang sudah terpasang langsung memakai nama baru. Sel simbol kini menampilkan keadaan tekan
  seketika (latar lebih gelap + garis 4 dp), tanpa transisi.
- **Alasan:** Di baris horizontal sebagian besar kategori tersembunyi di luar layar, dan "KATA INTI 2/3" tidak bermakna
  bagi anak maupun orang tua. Tanpa umpan balik tekan, papan terasa kaku dan anak tidak tahu sel mana yang tersentuh.
- **Dampak terhadap masalah inti:** M1: kategori lebih cepat ditemukan dan tetap di tempat yang sama (perencanaan motorik).
  Lebar grid berkurang ±92 dp; sel di HP 360 dp tetap ± 13 mm (≥ 10 mm, invarian 12). Kontras teks saat ditekan ≥ 6,4:1.

## 11. Urutan kata di bilah ujaran bisa digeser (12:15, jalur 1)
- **Kondisi di proposal:** Bilah ujaran hanya bertambah dari kanan dan berkurang lewat HAPUS (satu langkah dari
  belakang). Invarian 11: tanpa animasi di papan anak.
- **Yang diubah:** Setiap kata di bilah bisa ditahan ± 0,5 detik lalu diseret ke tempat lain, di papan anak dan papan
  misi. Kata yang diangkat sedikit membesar dengan bayangan tipis, kata lain bergeser memberi tempat. UCAPKAN
  membunyikan urutan baru, dan peristiwa `UCP` mencatat urutan akhir itu. Tidak ada kode peristiwa baru. Invarian 11 di
  CLAUDE.md diberi pengecualian untuk gerak ini.
- **Alasan:** Anak (atau pendamping yang memberi contoh) sering memilih kata tidak berurutan, misalnya MAU lalu MAKAN
  lalu AKU. Tanpa geser, satu-satunya cara memperbaiki kalimat adalah menghapus dari belakang dan mengetuk ulang.
- **Dampak terhadap masalah inti:** M1: menyusun kalimat lebih murah langkahnya. Gerak hanya terjadi saat jari sedang
  menyeret, jadi tidak ada gerakan yang tidak dipicu anak. Terapis tidak melihat penggeseran sebagai peristiwa
  tersendiri; yang terlihat hanya urutan kalimat yang diucapkan.

## 12. Layar orang tua: tab bawah sungguhan dan gerak halus (12:25, jalur 2 & 1)
- **Kondisi di proposal:** Beranda memakai bilah bawah yang membuka Perkembangan, Terapis, dan Pengaturan sebagai
  halaman baru. Tema mematikan percikan dan sorotan, jadi tombol tidak memberi tanda saat ditekan.
- **Yang diubah:** Beranda punya `NavigationBar` empat tab (Beranda, Perkembangan, Terapis, Pengaturan); kartu usulan
  terapis membuka tab Terapis. Tombol memberi lapisan tekan 12 % dan tombol utama mengecil ke 0,97 selama ditekan.
  Lingkaran penghitung misi yang baru terisi memudar satu per satu; layar "Tercatat" masuk memudar dan naik 12 dp,
  **sama persis** untuk "Selesai" dan "Belum sempat". Kartu yang muncul di beranda dan pergantian memuat → isi memudar
  halus; titik merah berdenyut saat merekam suara keluarga. Semua di bawah 350 ms dan seketika bila Android diatur
  "Hapus animasi". Token warna pendamping disatukan dengan token papan.
- **Alasan:** Tanpa umpan balik, aplikasi terasa kaku dan orang tua tidak yakin ketukannya diterima.
- **Dampak terhadap masalah inti:** M2: pendamping harian terasa lebih ringan dipakai. Papan anak tidak ikut bergerak
  (kecuali geser urutan bilah, entri 11); nada bebas rasa bersalah (invarian 15) dijaga dengan gerak yang identik.

## 13. Kartu dari foto (C3) akhirnya dibangun (13:55, jalur 1 & 2)
- **Kondisi di proposal:** C3 membuat kartu personal dari foto benda milik anak. Entri 1 dan 4 mencatatnya belum ada.
- **Yang diubah:** Kelola kosakata punya tombol **Tambah kartu baru**. Orang tua memotret benda (atau memilih dari galeri
  lewat aplikasi bawaan Android, tanpa izin kamera di Nyambung), menulis label huruf kapital, dan memilih halaman
  kategori. Kartu mengisi kotak kosong berikutnya, sehingga sel lain tidak bergeser. Kotak kosong di halaman kategori
  kini tampil bergaris putus-putus (B5). Ketukan kartu tercatat sebagai `PRS` dengan `word_id` `prs-<label>-<6 hex>`,
  dan dasbor menampilkan labelnya (mis. GELAS). Suara keluarga (C4) juga bisa direkam untuk kartu ini.
- **Alasan:** Kata khas rumah (gelas kesayangan, boneka, nama benda) adalah yang paling ingin disampaikan anak.
- **Dampak terhadap masalah inti:** M1 menguat karena papan bisa memuat benda milik anak sendiri. Fotonya **tidak pernah
  dikirim** ke server (invarian 18 diperluas ke foto); terapis hanya melihat label. Batasan: label hanya lewat
  `word_id`, jadi mengganti label berarti membuat kartu baru; kartu tidak bisa dipindah posisinya.

## 14. Catatan sesi D4 tersimpan di server dan ringkasannya bisa dikirim ke keluarga (13:55, jalur 3, 4 & 2)
- **Kondisi di proposal:** D4 berupa paragraf siap salin dari data rumah, tanpa penyimpanan catatan bebas (status jalur
  4, butir 4.6).
- **Yang diubah:** D4 kini memuat butir otomatis "Sebelum sesi, dari data rumah", formulir catatan terapis (tanggal,
  catatan, fokus pekan depan, jadwal sesi berikutnya) yang tersimpan di server, tabel sesi sebelumnya yang bisa diubah,
  dan tombol **Kirim ringkasan ke keluarga** dengan teks yang bisa disunting. Hanya teks ringkasan itu yang ditarik HP
  keluarga saat sinkron dan tampil di C5; catatan terapis tidak pernah sampai ke keluarga. Seed demo memuat dua
  catatan sesi ilustratif. Endpoint baru: `sessions`, `sessions/{id}/share`, `shared-summaries`.
- **Alasan:** Mockup D4 dan C5 menunjukkan catatan sesi dan jadwal sesi berikutnya. Tanpa jalur balik, hasil sesi tatap
  muka hanya sampai ke keluarga lewat ingatan.
- **Dampak terhadap masalah inti:** M3 menjadi dua arah untuk hasil sesi, bukan hanya usulan kata. Catatan terapis
  adalah teks bebas di server, jadi terapis bertanggung jawab untuk tidak menulis diagnosis di sana (invarian 20 hanya
  dijaga aplikasi, bukan isi tulisan terapis). Belum ada: hapus catatan, dan riwayat ringkasan di HP hanya bertambah.

## 15. Waktu tinjauan terapis diukur (13:55, jalur 3 & 4)
- **Kondisi di proposal:** Sasaran tinjauan < 5 menit per anak, tanpa pengukuran.
- **Yang diubah:** Dasbor menghitung lama halaman satu anak (D2–D4) terbuka, hanya saat tab terlihat dan ada interaksi
  dalam 2 menit terakhir, lalu mengirimnya ke `POST /v1/review-time`. D1 menampilkan rerata 30 hari. Mode demo tidak
  mengukur.
- **Alasan:** Klaim "satu terapis, banyak keluarga" butuh angka yang teramati, bukan perkiraan.
- **Dampak terhadap masalah inti:** M4 bisa dibuktikan dengan data pemakaian. Yang diukur adalah waktu terapis, bukan
  anak atau keluarga.

## Desain ulang visual dan gerak halus, termasuk di papan anak (18 Sep, jalur 1)
- **Kondisi di proposal:** palet navy–krem, font sistem; invarian 11: papan mode anak tanpa animasi sama sekali
  (kecuali geser urutan bilah ujaran).
- **Yang diubah:** seluruh aplikasi mengikuti desain ulang (mint + tosca, satu tombol utama lime, judul Fredoka dan isi
  Nunito dibundel, kaki halaman awan, logo asli). Warna sel tujuh kelas kata mengikuti desain; teks sel tetap ≥ 4,5:1.
  Salinan teks di layar orang tua dipangkas (keterangan panjang dan kalimat penafian dibuang; label "ilustratif",
  batas produk, dan daftar yang dibagikan ke terapis tetap ada). Di papan anak ditambah gerak halus: sel mengecil
  0,95 selama ditekan (100 ms), kata baru di bilah masuk 180 ms, isi halaman memudar 150 ms saat pindah tab, tab aktif
  berganti warna 160 ms, dan papan memudar masuk 200 ms. Semua gerak nol bila setelan Android "Hapus animasi" aktif.
- **Alasan:** permintaan tim setelah uji tampilan; gerak dibatasi pada umpan balik sentuh dan peralihan, di bawah 200 ms.
- **Dampak terhadap masalah inti:** posisi simbol tetap tidak pernah berpindah (invarian 8); tanpa hadiah, suara latar,
  atau gamifikasi. Gerak di papan belum diuji dengan anak autis; bila terapis menilai mengganggu, cukup set durasi
  di `board_screen.dart` dan `symbol_cell.dart` ke nol.


## 16. Frasa bersuara lewat server (14:45)
- **Kondisi di proposal:** Papan hanya memakai 120 kata dengan klip bundel dan kartu foto. Kalimat khas keluarga atau
  sekolah ("Jangan nyontek") tidak punya suara selain TTS perangkat. Invarian 5: tidak ada dependensi ML saat runtime.
- **Yang diubah:** Orang tua (Pengaturan → Frasa bersuara) dan terapis/guru (dasbor) bisa mengetik frasa ≤ 60 karakter.
  Server membuat klipnya sekali dengan OpenAI TTS (suara papan cowo/cewe yang sama dengan klip bundel), perangkat
  mengunduhnya ke folder aplikasi, lalu kartu frasa (`word_id` `frs-…`, peristiwa `PRS`) diputar tanpa internet.
  Frasa dari terapis/guru berstatus usulan dan dijawab keluarga dengan dua tombol setara (peristiwa `TGT`,
  context = phrase_id). Batas 30 frasa per anak per hari.
- **Alasan:** permintaan tim. Kalimat pendek yang akrab membantu anak memahami instruksi di rumah dan di sekolah.
- **Dampak terhadap masalah inti:** Invarian 5 dilonggarkan: server (bukan aplikasi) memanggil model suara saat frasa
  **dibuat**. Papan, suara, misi, dan pencatatan tetap luring penuh (invarian 1). Membuat frasa baru butuh internet
  dan tautan terapis. Tanpa `OPENAI_API_KEY`, fitur ini tampil "belum aktif". Suara sintetis, bukan rekaman manusia.

## 17. Tiruan suara keluarga (ElevenLabs), hanya dengan persetujuan orang tua (14:45)
- **Kondisi di proposal:** Invarian 18: rekaman suara keluarga tidak pernah meninggalkan perangkat. Suara keluarga
  hanya dari rekaman per kata.
- **Yang diubah:** Orang tua bisa mengaktifkan "Suara keluarga": menyetujui empat butir (suaranya sendiri; rekaman
  dikirim ke ElevenLabs; terapis/guru bisa membuat frasa dengan suara ini sebagai usulan; bisa dicabut), menulis
  pemilik suara, lalu membaca tiga kalimat (≥ 8 detik masing-masing). Server meneruskan rekaman ke ElevenLabs Instant
  Voice Cloning dari memori, tanpa menulisnya ke disk, dan hanya menyimpan `voice_id`. Nama anak tidak dikirim.
  Rekaman contoh di HP dihapus setelah terkirim atau saat layar ditutup. Mencabut menghapus suara di ElevenLabs.
  Terapis/guru yang tertaut bisa membuat frasa dengan suara ini; frasanya tetap usulan yang boleh ditolak.
- **Alasan:** permintaan tim. Contoh kasus: guru ingin anak mendengar "Jangan nyontek" dengan suara orang tuanya,
  karena anak sudah terbiasa dengan suara itu.
- **Dampak terhadap masalah inti:** Invarian 18 kini berbunyi "tidak pernah meninggalkan perangkat **kecuali orang tua
  mengaktifkan tiruan suara**". Rekaman per kata (C4) tetap tidak pernah dikirim. Risiko yang kami akui: suara
  tiruan disimpan penyedia pihak ketiga selama belum dicabut, dan kemiripannya belum diuji dengan anak. Butuh
  `ELEVENLABS_API_KEY` (paket berbayar ElevenLabs); tanpa kunci, fitur tampil "belum aktif".

## 18. Simbol berwarna penuh dan 35 simbol yang hilang terisi (15:30)
- **Kondisi sebelumnya:** 85 PNG Mulberry tampil sebagai siluet hitam karena perasteran sebelum acara mengabaikan
  `<style>` di SVG. 35 kata "gambar tim" belum punya gambar dan tampil sebagai huruf pertama (SAKIT = "S").
- **Yang diubah:** Semua simbol dirasterkan ulang dengan warna. 14 kata ternyata punya padanan Mulberry yang jelas
  (mis. SAKIT = orang sakit kepala, TIDAK = silang, ITU = menunjuk); 21 sisanya digambar tim mengikuti gaya `05` §6.
  Kata bawaan tidak lagi bertanda `is_custom`: sebelumnya ketukan AKU, TIDAK, BERHENTI, YA, ITU tercatat `PRS`
  (kartu personal) dan tidak terhitung di penghitung misi. HP lama diperbarui saat aplikasi dibuka.
- **Alasan:** Anak autis nonverbal butuh isyarat visual yang bermakna; huruf pertama tidak membawa makna.
- **Dampak:** Simbol tim belum diuji pada anak (batasan `03` §8). Rincian sumber di `assets/PROVENANCE.md`.

## 19. Rutinitas tanpa jam dan generator misi yang bisa dilacak (15:30)
- **Kondisi sebelumnya:** Pilihan "Makan sore / Mandi sore / Main pagi" memakai jam tanpa dasar. Kata misi
  bergilir dari satu daftar tetap yang sama untuk semua rutinitas, dan terapis tidak bisa melihat kata misi harian.
- **Yang diubah:** Pilihan menjadi "Waktu makan / mandi / main" beserta contoh simbol yang punya giliran alami di
  kegiatan itu (jam berapa pun boleh). Aturan misi tertulis di `mission_rules.dart`: pekan ke-N sejak pemasangan;
  usulan terapis yang diterima menggantikan urutan bawaan; tanpa usulan, satu kata per pekan dari 12 kata inti
  dengan urutan per rutinitas, mulai dari fungsi meminta (MAU/LAGI; Bondy & Frost 1994). `mission_id` kini
  `misi-w{pekan}-{kata}`, sehingga dasbor D2 menampilkan panel "Misi harian" (kata, asal, 14 hari terakhir) dari
  peristiwa mentah saja. Beranda dan layar misi menampilkan "Kenapa kata ini?".
- **Alasan:** Setiap pilihan harus punya dasar yang bisa dijelaskan, dan terapis harus bisa melacak misi keluarga.
- **Dampak:** Urutan per rutinitas dan dosis lima contoh tetap asumsi tim (tingkat D). Pelajaran 60 detik dan layar
  misi kini bergambar; tombol misi langsung membuka papan dengan kata target disorot (hanya mode misi, bukan mode anak).

## 20. Layar pilihan "Aku {nama}" / "Aku orang tua" dengan PIN (15:30)
- **Kondisi sebelumnya:** Aplikasi selalu terbuka di beranda orang tua; anak yang membuka sendiri masuk ke pengaturan.
- **Yang diubah:** Layar pertama berisi dua pilihan. "Aku {nama}" langsung ke papan anak. "Aku orang tua" meminta PIN
  4 angka yang dibuat saat pemasangan (SHA-256 bergaram, hanya di HP). Tiga kali salah → dua tombol setara "Coba
  lagi" dan "Aku {nama}"; putaran salah berikutnya menambah jeda 30 detik. Lupa PIN: ketik nama panggilan anak.
  Beranda terkunci lagi setelah 5 menit di latar belakang, dan ada tombol kunci di beranda.
- **Alasan:** permintaan tim.
- **Dampak:** PIN adalah pagar, bukan pengaman data. Anak yang bisa mengetik namanya sendiri bisa membuat PIN baru.

## 21. Orang tua boleh mengatur posisi kata di halaman kategori (15:30)
- **Kondisi di proposal:** Invarian 8, posisi simbol tidak pernah berpindah.
- **Yang diubah:** Di Kelola kosakata (layar orang tua), kata di halaman kategori bisa ditahan lalu digeser; bila slot
  terisi, keduanya bertukar. Halaman inti dan enam sel cermin tetap terkunci. Kartu foto dan kartu frasa bisa
  dihapus; kata bawaan hanya bisa disembunyikan. Ada pencarian kata lintas halaman.
- **Alasan:** permintaan tim, supaya kosakata bisa disesuaikan keluarga.
- **Dampak:** Invarian 8 kini berarti "papan tidak pernah memindahkan simbol sendiri". Layar menjelaskan bahwa anak
  belajar dari letak tetap (Thistle dkk. 2018) dan menyarankan pindahkan seperlunya.

## 22. Foto menjadi visual scene AAC yang dapat dipakai luring (18 Sep 2026)
- **Kondisi sebelumnya:** Satu foto hanya dapat menjadi satu kartu dengan satu label. Keluarga harus memotong atau
  membuat banyak kartu untuk satu kegiatan nyata.
- **Yang diubah:** Pengaturan → Papan dari foto membuat satu foto memiliki satu sampai enam hotspot. Pendamping dapat
  menambah, menggeser, mengubah ukuran, memetakan kata, menyimpan draf, melanjutkan draf setelah aplikasi dibuka lagi,
  mengedit versi, dan mengarsipkan papan. Tab FOTO memakai BoardScreen, bilah ujaran, tahan sentuh, screen pinning,
  audio luring, serta event KAT/PRS yang sama dengan grid. Enam sel kata inti tetap berada di posisi tetap.
- **Bantuan AI:** Dengan persetujuan per permintaan, server mengirim JPEG tanpa metadata dan inventaris kata aktif ke
  Gemini untuk memperoleh maksimum enam kandidat. Token perangkat diperiksa sebelum body dibaca, body dibatasi 4 MiB,
  JPEG 2 MiB/1280 px, satu request aktif per anak, dan sepuluh percobaan per 24 jam. AI hanya membuat draf; pemetaan
  yang belum cocok tidak dapat disimpan sebelum diperbaiki keluarga. Tanpa key, tautan, atau internet, editor manual
  tetap tersedia.
- **Dampak:** Klaim luring berlaku pada papan final dan komunikasi anak. Foto meninggalkan perangkat hanya pada alur
  bantuan AI yang disetujui; server tidak menyimpan foto. Fitur ini bukan pengenal maksud, emosi, hubungan keluarga,
  diagnosis, atau rekomendasi klinis.

## 23. Bantuan AI papan foto memakai OpenAI bila Gemini tidak diatur (18 Sep 2026)
- **Kondisi sebelumnya:** Draf area papan foto hanya bisa dibuat Gemini; kunci Gemini belum ada sehingga fitur selalu
  "belum aktif".
- **Yang diubah:** Server memakai OpenAI Responses API (model bawaan `gpt-5.4`, keluaran JSON ber-skema ketat,
  `store: false`) dengan `OPENAI_API_KEY` yang sudah dipakai suara papan. Gemini tetap diutamakan bila kunci dan
  modelnya diisi. Dialog persetujuan di aplikasi menyebut OpenAI atau Google sesuai setelan server.
- **Dampak:** Aturan privasi tetap: foto hanya dikirim setelah persetujuan per permintaan, tidak disimpan server, dan
  hasilnya tetap draf yang wajib diperiksa keluarga.

## 24. AI papan foto tidak lagi memilih kata fungsi, dan area bertumpuk dibuang (18 Sep 2026)
- **Kondisi sebelumnya:** AI memetakan benda ke kata apa saja dari inventaris (laptop → NANTI, wajah → LAGI) dan
  bisa mengembalikan kotak besar yang saling menumpuk. Strip jalan pintas di bawah foto memakai gaya bingkai area
  setinggi 46 dp sehingga tampak terpotong.
- **Yang diubah:** Aplikasi tidak mengirim kata fungsi (pos pengatur, tanya, sosial, ganti) ke AI; pendamping tetap
  bisa memilihnya manual. Inventaris membawa `pos` dan `category`. Prompt meminta benda nyata saja (tanpa orang atau
  wajah), kotak yang tidak menumpuk, dan `null` bila tidak ada kata yang cocok. Server membuang area yang lebih dari
  separuhnya tertutup area sebelumnya dan tidak memakai satu kata dua kali. Strip bawah menjadi tombol kartu ≥ 64 dp.
- **Dampak:** AI lebih sering mengembalikan area tanpa kata; itu disengaja, karena kata yang salah lebih buruk
  daripada kosong. Hasil tetap draf yang wajib diperiksa keluarga.

## 25. Mode guru dengan PIN titipan orang tua (18 Sep 2026)
- **Kondisi sebelumnya:** Frasa bersuara keluarga dari guru hanya bisa lewat dasbor terapis sebagai usulan yang
  dijawab keluarga satu per satu (PERUBAHAN #16, #17).
- **Yang diubah:** Pengaturan → PIN guru: orang tua membuat PIN 4 angka per orang (nama + masa berlaku 1, 3, 5, 7
  hari, atau tidak kedaluwarsa), lalu bisa memperpanjang, mengaktifkan lagi, atau mencabutnya. Layar pertama
  menampilkan "Aku guru" setelah ada PIN guru. Mode guru hanya bisa membuat frasa (suara keluarga atau suara papan)
  dan membuka papan sebagai pendamping; tidak ada akses ke pengaturan, data, atau kosakata. Frasa guru langsung
  menjadi kartu di papan dan tercatat atas nama pemegang PIN; orang tua melihat daftar itu dan bisa menghapus
  frasanya. PIN guru harus beda dari PIN orang tua dan PIN guru aktif lain, disimpan SHA-256 bergaram hanya di HP,
  dicek ulang sebelum setiap frasa, dan mode guru tertutup setelah 5 menit di latar belakang.
- **Alasan:** permintaan tim. Guru butuh frasa saat itu juga, dan orang tua sering tidak bisa menjawab usulan tepat
  waktu.
- **Dampak:** Persetujuan bergeser dari per frasa menjadi titipan per orang (invarian 18 dan 19): orang tua tidak lagi
  menyetujui tiap kalimat, tetapi memilih siapa yang dipercaya, sampai kapan, dan bisa menghapus setelahnya. PIN
  hanya berlaku di HP anak, jadi guru membuat frasa di HP itu. Di server frasa guru tercatat sebagai `keluarga`
  (dibuat dengan token perangkat); nama guru hanya ada di catatan lokal HP.
