# Nyambung

Nyambung adalah papan AAC (komunikasi augmentatif dan alternatif) berbahasa Indonesia untuk anak autis nonverbal,
yang berjalan penuh tanpa internet. Di sekelilingnya ada pendampingan harian kurang dari lima menit untuk orang tua
(satu misi *aided language modeling* per hari), dan papan pantau untuk terapis wicara yang menerima pola pemakaian
papan dari rumah. Aplikasi hanya mengirim peristiwa ketukan mentah; ringkasan dihitung di server, dan target dari
terapis selalu berupa usulan yang boleh ditolak keluarga.

> Nyambung bukan alat diagnosis. Angka di papan pantau adalah pola pemakaian, bukan ukuran kemampuan anak.

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

Tes:

```bash
server/.venv/Scripts/python -m pytest -q server/tests
```

### 2. Data demo (simulator)

Dengan server menyala dan `NYAMBUNG_THERAPIST_TOKENS` terset di terminal yang sama:

```bash
python tools/simclient.py demo --days 21
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
npm run dev          # http://127.0.0.1:5173 (masuk dengan token terapis) · http://127.0.0.1:5173/?source=demo tanpa server
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
(18 Sep 2026): `arm64-v8a` 18,8 MB, `armeabi-v7a` 16,3 MB.

Di HP, isi alamat server di Pengaturan dengan IP laptop yang menjalankan server (mis. `http://192.168.1.10:8000`);
emulator Android menjangkau laptop lewat `http://10.0.2.2:8000`.

## Lisensi simbol

Simbol dari **Mulberry Symbols** © Steve Lee, **CC BY-SA 4.0** (https://mulberrysymbols.org): boleh dipakai
komersial, wajib atribusi, dan turunannya wajib berlisensi sama. Rincian di `assets/symbols/ATTRIBUTION.md`.
Simbol yang belum punya gambar tampil sebagai huruf pertama katanya.

## Batasan yang kami akui

- Server memakai HTTP di jaringan lokal, belum HTTPS.
- Belum ada pembatasan laju tebakan kode undangan (kode 8 karakter, sekali pakai, kedaluwarsa 7 hari).
- Token perangkat disimpan di `shared_preferences` tanpa enkripsi.
- Suara papan memakai TTS perangkat, bukan rekaman manusia; kualitasnya bergantung mesin TTS di HP.
- Belum diuji di banyak ROM Android; kunci layar anak memakai *screen pinning* yang meminta konfirmasi sekali.
- Daftar 120 kata belum ditinjau terapis wicara (`therapist_ok = belum`).
- Data di papan pantau mode demo dan `seed/demo_events.json` sepenuhnya **ilustratif**, bukan data keluarga sungguhan.
