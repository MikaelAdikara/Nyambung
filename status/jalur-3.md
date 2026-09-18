# Status jalur 3 — Server
Diperbarui: 10:40

## Sedang dikerjakan
3.6 README (draf di main; tag j3-readme menunggu dasbor jalur 4 ada dan uji clone bersih)

## Tonggak selesai (tag)
- j0-repo: kerangka repo, hash aset 175/175 OK
- j3-sync: `POST /v1/sync/events` idempoten, 422 untuk medan tak dikenal dan `ts_device` tanpa zona, trigger append-only
- j3-auth: undangan, tebus, cabut, token Bearer (SHA-256), 401/403/404/410 sesuai kontrak
- j3-ringkasan: `/v1/children`, `/summary`, `/targets` sesuai kontrak §5; 29 tes pytest lulus
- j3-simulator: `tools/simclient.py` + `seed/demo_events.json` (5 anak ilustratif, 870 peristiwa, 21 hari; Arka naik,
  Bima turun, Reza tetap, Tiara perlu ditinjau, 1 target diterima, 1 usulan menunggu). Uji mati paksa setelah 200:
  kirim ulang 60 diterima + 40 duplikat → `verify` identical: true
- (tanpa tag) `tools/validate_vocab.py`: LULUS, 35 simbol gambar tim belum ada

## Perkiraan tonggak berikutnya
j3-readme setelah dasbor ada; j3-apk setelah int-1-hp-ke-d2

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 4: definisi agregat ada sebagai docstring di `server/app/services/summary.py`. Detail yang perlu dicerminkan
  persis: jendela = `[now − days, now)` pada `ts_utc`; `top_words` maks 10, urut hitungan menurun lalu kata menaik;
  `weekly_unique_6w` = 6 jendela 7 hari mundur dari `now`; `trend_3w` selalu pakai pekan 7 hari (tidak ikut `days`);
  `linked_weeks` = floor(hari sejak tautan aktif tertua / 7); `missions_*_6w` = jendela 42 hari.
- ke jalur 2: server menerima `Authorization: Bearer <device_token>`; `ts_device` wajib ber-offset (pakai `nowIso()` jalur 1).

- ke jalur 4: `seed/demo_events.json` sudah ada (bentuk kontrak §7), stempel relatif terhadap 18 Sep 10:30 WIB.
  Jalankan ulang `python tools/simclient.py demo` di hari demo supaya jendela 7 hari tidak kosong.

## Perubahan API/kontrak yang perlu diketahui
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
