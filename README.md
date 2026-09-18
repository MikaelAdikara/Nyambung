# Nyambung

Nyambung adalah papan AAC (komunikasi augmentatif dan alternatif) berbahasa Indonesia untuk anak autis nonverbal,
yang dapat dipakai penuh tanpa internet. Di sekelilingnya ada pendampingan harian kurang dari lima menit untuk orang tua
(satu misi *aided language modeling* per hari), dan papan pantau untuk terapis wicara yang menerima pola pemakaian
papan dari rumah. Aplikasi hanya mengirim peristiwa ketukan mentah; ringkasan dihitung di server, dan target dari
terapis selalu berupa usulan yang boleh ditolak keluarga.

> Nyambung bukan alat diagnosis. Angka di papan pantau adalah pola pemakaian, bukan ukuran kemampuan anak.

Fitur **Papan dari foto** mengubah foto kegiatan menjadi visual scene AAC berisi sampai enam area bicara. Pendamping
boleh menyusun area sendiri atau meminta vision AI membuat draf, lalu wajib memeriksa pemetaan kata sebelum menyimpan.
Papan final, foto, suara, dan pemakaiannya tetap luring; foto hanya dikirim saat bantuan AI dipilih dengan persetujuan
eksplisit pada setiap permintaan.

## Struktur repo

| Folder | Isi |
|---|---|
| `app/` | Aplikasi Android (Flutter): papan bicara, pendamping orang tua, SQLite lokal + outbox |
| `server/` | API FastAPI + SQLite (WAL): sinkron idempoten, autentikasi Bearer, agregasi ringkasan |
| `dashboard/` | Papan pantau terapis (React + Vite + TypeScript) |
| `tools/` | `simclient.py` (perangkat tiruan + data demo), `validate_vocab.py` (pemeriksaan data kosakata) |
| `seed/` | `demo_events.json`: data demo **ilustratif** hasil simulator |
| `assets/` | 120 kata inti, 85 simbol Mulberry, atribusi; asal-usul dan hash di `assets/PROVENANCE.md` |

## Prasyarat (versi yang dipakai tim)

| Perkakas | Versi |
|---|---|
| Python | 3.11.6 |
| Flutter | 3.47.4 (stable), Dart 3.13.3 |
| JDK | 17 (17.0.20) |
| Android SDK | platform `android-36` (compileSdk 36), build-tools 36.0.0 |
| Android NDK | 28.2.13676358 |
| CMake (SDK) | 3.22.1 |
| Node.js / npm | Node 24.19.0 (untuk dasbor) |

Aplikasi menargetkan Android 8.0 ke atas (`minSdk 26`). Di Windows dengan nama pengguna berspasi, bila Gradle gagal
dengan `Unable to establish loopback connection`, arahkan `TEMP` dan `TMP` ke folder tanpa spasi (mis. `C:\dev\tmp`).

## Menjalankan

Selalu pakai `127.0.0.1` atau IP LAN eksplisit (di Windows nama host lokal mencoba IPv6 dulu dan setiap permintaan jadi lambat).

### 1. Server

```bash
cd server
python -m venv .venv
.venv/Scripts/python -m pip install -r requirements.txt        # Linux/macOS: .venv/bin/python
```

Set token terapis (≥ 16 karakter; server hanya menyimpan SHA-256-nya), lalu jalankan:

```bash
# PowerShell: $env:NYAMBUNG_THERAPIST_TOKENS="token-demo-panjang-2026:Bu Rina (ilustratif)"
export NYAMBUNG_THERAPIST_TOKENS="token-demo-panjang-2026:Bu Rina (ilustratif)"
.venv/Scripts/python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Cek: `http://127.0.0.1:8000/v1/health` harus menjawab `{"ok": true, ...}`. Contoh isi `.env` ada di `server/.env.example`.
Basis data ada di `server/data/nyambung.db` (tidak di-commit; ubah dengan `NYAMBUNG_DB_PATH`).

Bantuan AI papan foto bersifat opsional. Cukup `OPENAI_API_KEY` (kunci yang sama dengan suara papan; model bawaan
`gpt-5.4`, ubah lewat `NYAMBUNG_OPENAI_VISION_MODEL`). Bila `GEMINI_API_KEY` dan `NYAMBUNG_VISION_MODEL` diisi, Gemini
yang dipakai. Kunci hanya berada di server. Tanpa kunci, editor manual tetap bekerja.
Server menerima maksimal satu analisis aktif dan sepuluh percobaan per anak dalam 24 jam pada konfigurasi prototype.

Akun login terapis (email + kata sandi) dibuat oleh pengelola, tidak ada pendaftaran terbuka:

```bash
server/.venv/Scripts/python tools/create_therapist.py --demo                                  # dua akun ILUSTRATIF
server/.venv/Scripts/python tools/create_therapist.py --email rina@klinik.id --name "Bu Rina"   # kata sandi ditanyakan
```

Akun demo: `rina@demo.nyambung.id` dan `dimas@demo.nyambung.id`, kata sandi `nyambung-demo`. Nama akun demo sama
dengan contoh token env, jadi keduanya menunjuk terapis yang sama. Login menghasilkan token sesi 30 hari; server hanya
menyimpan SHA-256-nya, dan kata sandi di-hash dengan scrypt. Token env tetap berlaku untuk simulator dan pengelola.

Tes:

```bash
server/.venv/Scripts/python -m pytest -q server/tests
```

### 2. Data demo (simulator)

Dengan server menyala dan `NYAMBUNG_THERAPIST_TOKENS` terset di terminal yang sama:

```bash
python tools/simclient.py demo --days 21
# atau masuk dengan akun demo, dan tulis seed ke tempat lain supaya seed/demo_events.json tidak berubah:
python tools/simclient.py demo --email rina@demo.nyambung.id --password nyambung-demo --out tools/.sim/seed.json
```

Lima keluarga ilustratif ditautkan lewat kode undangan, peristiwa 21 hari dikirim lewat outbox yang sama dengan
aplikasi, dan `seed/demo_events.json` ditulis ulang. Uji ketahanan sinkron (proses dimatikan setelah server menjawab 200
tetapi sebelum outbox dibersihkan, lalu dikirim ulang):

```bash
python tools/simclient.py tap --child <child_id> --n 100
python tools/simclient.py sync --child <child_id> --crash-after 1     # keluar dengan kode 137
python tools/simclient.py sync --child <child_id>                     # sisa terkirim, duplikat terhitung
python tools/simclient.py verify --child <child_id>                   # {"identical": true}
```

### 3. Papan pantau

```bash
cd dashboard
npm install
npm run dev          # http://127.0.0.1:5173 (masuk dengan email + kata sandi terapis) · http://127.0.0.1:5173/?source=demo tanpa server
npm run build        # hasil di dashboard/dist; `npm run preview` → http://127.0.0.1:4173
```

Dasbor memanggil API di `http://127.0.0.1:8000`; ganti dengan variabel lingkungan `VITE_API_BASE` (mis.
`VITE_API_BASE=http://192.168.1.10:8000 npm run dev`). Bila server tidak menjawab `/v1/health`, dasbor pindah ke mode
demo dengan pita **DATA ILUSTRATIF** di setiap halaman.

### 4. Aplikasi Android

```bash
cd app
flutter pub get
flutter test
flutter run                                   # emulator atau HP dengan USB debugging
flutter build apk --release --split-per-abi   # armeabi-v7a dan arm64-v8a
```

**Tanda tangan rilis.** Buat keystore sekali dan simpan di luar git (sudah di-gitignore):

```bash
cd app/android
keytool -genkeypair -keystore nyambung-release.jks -storetype PKCS12 -alias nyambung -keyalg RSA -keysize 2048 -validity 10000
```

lalu tulis `app/android/key.properties`:

```
storeFile=nyambung-release.jks
storePassword=<kata sandi>
keyAlias=nyambung
keyPassword=<kata sandi>
```

Tanpa `key.properties`, APK rilis ditandatangani kunci debug (tetap bisa dipasang untuk uji). Ukuran APK rilis
(18 Sep 2026, sesudah klip suara bundel): `arm64-v8a` 20,7 MB, `armeabi-v7a` 18,2 MB. `flutter build apk --release`
tanpa `--split-per-abi` menghasilkan satu APK gemuk 56,4 MB; jangan bagikan yang itu.

**HP berspesifikasi rendah.** Banyak HP murah Android 8 masih 32-bit: cek dengan
`adb shell getprop ro.product.cpu.abi`, lalu pasang `app-armeabi-v7a-release.apk` bila hasilnya `armeabi-v7a`.
Yang sudah disiapkan untuk HP seperti ini:

- Klip kata diputar lewat SoundPool yang sudah dimuat; di emulator 2 GB / 2 inti, jeda dari ketukan diproses sampai
  audio mulai turun dari median 98 ms ke 21 ms (APK rilis, 12 ketukan).
- Semua gambar simbol didekode di latar sesudah papan terbuka; cache gambar dibatasi 48 MB.
- Sinkron berkala berhenti selama papan terbuka dan saat aplikasi di latar belakang.
- Perender: Flutter memakai Impeller (Vulkan bila ada, OpenGLES bila tidak; emulator memakai OpenGLES).

- Waktu kerja thread UI per frame (APK profil, timeline VM service, buka papan + 9 ketukan + 7 pindah tab):
  median 0,3 ms, p90 ≤ 3,1 ms. Lonjakan 40 ms hanya saat papan pertama kali dibuka.

Semua angka di atas dari emulator, **belum dari HP fisik** 2 GB. Waktu rasterisasi di emulator ini (median 44–58 ms)
tidak bisa dipakai: emulator menggambar dengan OpenGL perangkat lunak (SwiftShader), bukan GPU. Perilaku Impeller di
GPU Mali/Adreno lama juga belum diuji.

**Alamat server ditanam saat build**, jadi keluarga tidak perlu mengetik apa pun. Pakai IP laptop yang menjalankan
server (cek dengan `ipconfig`), atau alamat VPS nanti:

```bash
flutter build apk --release --split-per-abi --dart-define=NYAMBUNG_SERVER=http://192.168.1.10:8000
```

Tanpa `--dart-define`, bawaannya `http://127.0.0.1:8000` (hanya berguna untuk `adb reverse tcp:8000 tcp:8000`).
Isian **Atur → Teknis → Alamat server** tetap ada sebagai penimpa, misalnya bila IP laptop berganti; mengosongkannya
mengembalikan alamat bawaan build. Emulator Android menjangkau laptop lewat `http://10.0.2.2:8000`.

## Lisensi simbol

Simbol dari **Mulberry Symbols** © Steve Lee, **CC BY-SA 4.0** (https://mulberrysymbols.org): boleh dipakai
komersial, wajib atribusi, dan turunannya wajib berlisensi sama. Rincian di `assets/symbols/ATTRIBUTION.md`.
Simbol yang belum punya gambar tampil sebagai huruf pertama katanya.

## Batasan yang kami akui

- Server memakai HTTP di jaringan lokal, belum HTTPS.
- Login terapis belum punya lupa kata sandi, pembatasan laju percobaan login, atau halaman hapus akun (wajib di
  Play Store/App Store begitu ada pembuatan akun). Akun dibuat lewat `tools/create_therapist.py`.
- Keluarga sengaja tanpa akun (papan harus jalan luring sejak dibuka pertama kali). Akibatnya data belum bisa
  dipulihkan saat ganti HP selain lewat ekspor JSON.
- Server memakai SQLite: cukup untuk pilot satu klinik. Untuk banyak klinik perlu Postgres; semua SQL server ada di
  `server/app/` sehingga pemindahan terbatas di situ.
- Belum ada pembatasan laju tebakan kode undangan (kode 8 karakter, sekali pakai, kedaluwarsa 7 hari).
- Token perangkat disimpan di `shared_preferences` tanpa enkripsi.
- Suara papan memakai TTS perangkat, bukan rekaman manusia; kualitasnya bergantung mesin TTS di HP.
- Belum diuji di banyak ROM Android; kunci layar anak memakai *screen pinning* yang meminta konfirmasi sekali.
- Daftar 120 kata belum ditinjau terapis wicara (`therapist_ok = belum`).
- Data di papan pantau mode demo dan `seed/demo_events.json` sepenuhnya **ilustratif**, bukan data keluarga sungguhan.
