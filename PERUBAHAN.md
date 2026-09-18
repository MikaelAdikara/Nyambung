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
