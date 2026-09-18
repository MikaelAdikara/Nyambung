# Status jalur 3 — Server
Diperbarui: 14:45

## Sedang dikerjakan
3.7 APK rilis: tanda tangan siap (keystore baru 18 Sep, jalur 1 menambah signingConfig). Tag j3-apk menunggu int-1-hp-ke-d2 (HP fisik)

## Tonggak selesai (tag)
- (14:45, tanpa tag) Frasa bersuara: tabel `phrase` + `voice_clone`, `GET/POST /v1/children/{id}/phrases`,
  `GET .../phrases/{pid}/audio`, `GET .../voice`, `POST/DELETE .../voice/clone`. OpenAI TTS + ElevenLabs lewat urllib,
  kunci dari env/.env. 54 tes pytest lulus (penyedia suara tiruan).
- (13:55, tanpa tag) Catatan sesi D4: tabel `session_note`, `GET/POST/PUT /v1/children/{id}/sessions`,
  `POST .../sessions/{note_id}/share` (hanya `family_text` sampai ke keluarga), `GET /v1/children/{id}/shared-summaries`
  untuk perangkat. Waktu tinjauan D1: tabel `review_log`, `POST /v1/review-time`, rerata 30 hari di `/v1/children`.
  45 tes pytest lulus
- (13:55, tanpa tag) `simclient.py demo` menulis 2 catatan sesi ilustratif untuk Arka (yang terbaru dikirim ke keluarga);
  `seed/demo_events.json` dibuat ulang 18 Sep 13:50: 5 anak, 870 peristiwa, 2 target, 2 catatan sesi
- j0-repo: kerangka repo, hash aset 175/175 OK
- j3-sync: `POST /v1/sync/events` idempoten, 422 untuk medan tak dikenal dan `ts_device` tanpa zona, trigger append-only
- j3-auth: undangan, tebus, cabut, token Bearer (SHA-256), 401/403/404/410 sesuai kontrak
- j3-ringkasan: `/v1/children`, `/summary`, `/targets` sesuai kontrak §5; 29 tes pytest lulus
- j3-simulator: `tools/simclient.py` + `seed/demo_events.json` (5 anak ilustratif, 870 peristiwa, 21 hari; Arka naik,
  Bima turun, Reza tetap, Tiara perlu ditinjau, 1 target diterima, 1 usulan menunggu). Uji mati paksa setelah 200:
  kirim ulang 60 diterima + 40 duplikat → `verify` identical: true
- j3-readme: diuji dari clone bersih (`C:\dev	mp\clean`): pytest 29 lulus, validate_vocab LULUS, dasbor `npm install` +
  `npm run build` bersih, `flutter pub get` + `flutter test` 18 lulus, APK rilis tanpa keystore terbangun (16,3 MB armeabi-v7a)
- (tanpa tag) `tools/validate_vocab.py`: LULUS, 35 simbol gambar tim belum ada

## Perkiraan tonggak berikutnya
j3-apk setelah int-1-hp-ke-d2; README diuji ulang di J23 di laptop lain

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 4: definisi agregat ada sebagai docstring di `server/app/services/summary.py`. Detail yang perlu dicerminkan
  persis: jendela = `[now − days, now)` pada `ts_utc`; `top_words` maks 10, urut hitungan menurun lalu kata menaik;
  `weekly_unique_6w` = 6 jendela 7 hari mundur dari `now`; `trend_3w` selalu pakai pekan 7 hari (tidak ikut `days`);
  `linked_weeks` = floor(hari sejak tautan aktif tertua / 7); `missions_*_6w` = jendela 42 hari.
- ke jalur 2 (uji nyata j2-sinkron): server jalur 3 sudah siap. Jalankan server (lihat "Cara menjalankan"), buat kode
  undangan: `curl -X POST -H "Authorization: Bearer <token terapis>" http://127.0.0.1:8000/v1/link/invite`.
  Emulator menjangkau laptop lewat `http://10.0.2.2:8000` atau `adb reverse tcp:8000 tcp:8000` (lalu alamat bawaan
  `http://127.0.0.1:8000` di app bekerja). HP fisik: IP laptop dari `ipconfig`.
- ke jalur 2 (PERHATIAN): pada 10:10–10:15 sesi jalur 1/3 dan sesi jalur 2 memakai **emulator yang sama** di laptop ini
  (APK tertimpa 10:11). Jalur 1/3 sudah melepas `adb reverse` dan mematikan server uji 8010; server di 127.0.0.1:8000
  (PID 16044) bukan milik jalur 3 dan tidak disentuh. Temuan saat itu: setelah tebus berhasil di server,
  `shared_prefs` di emulator tidak berisi `device_token`, sehingga "Kirim sekarang" tidak mengirim apa pun. Mohon dicek.
- ke jalur 2: server menerima `Authorization: Bearer <device_token>`; `ts_device` wajib ber-offset (pakai `nowIso()` jalur 1).

- ke jalur 4: `seed/demo_events.json` sudah ada (bentuk kontrak §7), stempel relatif terhadap 18 Sep 10:30 WIB.
  Jalankan ulang `python tools/simclient.py demo` di hari demo supaya jendela 7 hari tidak kosong.

- Integrasi emulator → server → API ringkasan (10:46): 3 peristiwa anak dari app (TIDAK, BERHENTI, UCAPKAN) muncul di
  `/summary` sebagai 2 kata berbeda. Belum dilihat di layar D2 dan belum dari HP fisik, jadi `int-1-hp-ke-d2` belum ditag.

## Perubahan API/kontrak yang perlu diketahui
- (13:55) Endpoint baru, endpoint lama tidak berubah: catatan sesi (terapis pemiliknya saja), `share` → ringkasan
  keluarga, `shared-summaries` (token perangkat; tanpa `note`), `review-time` (204). `/v1/children` menambah
  `review_avg_minutes` dan `review_count_30d`. Semua masukan baru menolak medan tak dikenal (422).
- Tidak mengubah kontrak. CORS dibuka (`*`) supaya dasbor di port lain bisa memanggil API dengan header Bearer.

## Cara menjalankan (untuk tim)
```
cd server
py -3.11 -m venv .venv && .venv\Scripts\python -m pip install -r requirements.txt
set NYAMBUNG_THERAPIST_TOKENS=<token≥16>:Bu Rina (ilustratif)
.venv\Scripts\python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```
Tes: `server\.venv\Scripts\python -m pytest -q server/tests`. Cek dulu `http://<IP>:8000/v1/health` → `{"ok":true}`.

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
