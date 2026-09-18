# Status jalur 1 — Papan
Diperbarui: 10:55

## Sedang dikerjakan
1.7 Pengerasan: tinggal uji HP fisik + RAM 2 GB (butuh perangkat). j1-suara ditahan: rekaman suara sedang dibuat manusia

## Tonggak selesai (tag)
- j1-kerangka: app terbuka, AppScope di atas MaterialApp, AppState + DAO nyata, DB terbuka, 120 kata termuat
- j1-skema: skema = kontrak, pemuat CSV sekali, 10 tes lulus. 1 tes dilewati: 6 simbol gambar tim halaman 0 belum ada
- j1-papan: B4 + B5 di emulator (HP) dan 320 dp; ketuk menambah bilah + bunyi; KEGIATAN: enam sel teratas identik posisinya
- j1-outbox: event + outbox satu transaksi; 10 ketukan = 10 + 10 baris; matikan paksa → angka tetap; trigger menolak
  UPDATE isi/DELETE, UPDATE synced_at lolos (diuji dengan sqlite3 di emulator)
- j1-kunci: screen pinning; Home tidak keluar dari papan anak (PINNED), tahan TAHAN 1,5 dtk → keluar + lepas kunci

## Selesai tanpa tag
- Hapus semua data juga menghapus rekaman keluarga dan berkas ekspor sementara (permintaan jalur 2, invarian 18)
- Tanda tangan rilis: `android/key.properties` + `nyambung-release.jks` (dibuat 18 Sep, di-gitignore) dibaca lewat
  `rootProject.file`; tanpa berkas itu rilis ditandatangani kunci debug. APK rilis arm64 = 18,8 MB, apksigner: CN=Nyambung

## Belum ditag
- j1-suara: kode jalan; mode pesawat → ketuk MAU → TTS memutar audio (tercatat di dumpsys audio). **Belum didengar
  manusia** apakah nada anak (1,3) dan pendamping (1,0) terdengar berbeda. Tag setelah didengar.

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 2: papan siap dipakai. Mode anak: `Navigator.push(context, BoardScreen.childRoute())`.
  Mode misi: `Navigator.push(context, MaterialPageRoute(builder: (_) => BoardScreen(missionContext: missionId, allowTurnToggle: true)))`.
  Import `package:nyambung/features/board/board_screen.dart`. Hapus `fake_board_screen.dart` setelah beralih.
- ke jalur 2: sebelum `logMission`/penghitung, simpan misi dengan `app.missionDao.upsert(Mission(...))`
  (kolom `target_word` REFERENCES symbol). Penghitung: `app.missionReps(missionId, localDate(DateTime.now()))`.
- ke jalur 2 (selesai 10:45): `main.dart` sekarang membuka `OnboardingFlow` (belum ada anak) / `HomeScreen`. Diuji di emulator:
  A1→A6 → B1 → Mulai misi → papan bersama → pendamping tekan MAU 2× → kembali: "2 dari 5".
- ke jalur 2 (izin): boleh menambah berkas tes sendiri di `app/test/` dengan nama `jalur2_*_test.dart`. Jangan ubah
  berkas tes jalur 1. `vocab_and_board_test.dart` sudah di `main` sebagai contoh tes tanpa sqflite.
- ke jalur 2: `FutureBuilder` pakai `CachedFuture` (`core/cached_future.dart`) dengan kunci `app.dataVersion`.
  `AppScope.of` hanya di `build`/`didChangeDependencies`.
- ke jalur 4: 6 simbol halaman 0 (TIDAK, YA, BERHENTI, SAKIT, AKU, ITU) ditunggu di `assets/symbols/custom/`;
  sampai ada, papan menampilkan huruf pertama.
- ke semua: pesan commit sekarang deskriptif dalam bahasa Inggris tanpa awalan `[jN]` (lihat CLAUDE.md).

## Perubahan API/kontrak yang perlu diketahui
- Model simbol bernama `WordSymbol` (bukan `Symbol`). Semua model di `app/lib/data/models.dart`.
- `AppState`: `child`, `dataVersion`, `createChild(nickname:, ageYears:, routine:, gridCols: 3)`,
  `logTap(content:, method:, byParent:, context:)`, `logMission(missionId, status)` (menghitung `reps_counted` sendiri),
  `missionReps(missionId, date)`, `logTargetAnswer(targetId, accepted)`, `symbolsForPage(page)`, `cellsForPage(page)`,
  `symbolById(id)`, `allSymbols`, `pages`, `speech`, `eventDao`, `missionDao`, `targetDao`, `linkDao`,
  `holdMs`/`setHoldMs`, `markDataChanged()`, `deleteAllData()`, `updateRoutine(routine)`.
- `EventDao` nyata: `append`, `pendingBatch(limit: 40)`, `markSynced(ids, ts)`, `defer(ids)`, `outboxCount()`,
  `totalCount()`, `lastSyncedAt()`, `countOnDate(...)`, `since(...)`, `all()`. `UtteranceEvent.toSyncJson()` = bentuk kontrak §4.
- `SpeechService`: `ttsIdAvailable`, `firstUtteranceLatencyMs` (untuk C6 Uji suara), `speakWord`, `speakText(text, byParent:)`.
- `TargetDao.upsertFromServer` tidak menimpa status lokal `diterima`/`ditolak`.
- Konstanta di `core/constants.dart`; waktu ber-offset di `core/time.dart` (`nowIso()`, `isoWithOffset()`, `localDate()`).
- Windows: build Gradle "Unable to establish loopback connection" → set `TEMP`/`TMP` ke `C:\dev\tmp` (path tanpa spasi).

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
