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
