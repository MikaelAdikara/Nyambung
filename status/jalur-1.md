# Status jalur 1 — Papan
Diperbarui: 14:25

**Mulai 11:20 semua jalur bekerja langsung di `main`** (tidak ada lagi kerja paralel; branch jalur sudah tergabung).

## Sedang dikerjakan
Paket HP kentang + UX (18 Sep siang): 1) optimasi O1–O3 ✔, 2) tab halaman di kiri + nama tab baru + keadaan tekan ✔,
3) geser urutan bilah ujaran ✔, 4) animasi layar orang tua ✔, 5) O4–O6 + ukur ulang ✔. j1-suara ditahan: belum didengar manusia.

## Desain ulang (18 Sep 14:25)
Semua layar mengikuti `nyambung-redesign.html`: token baru di `core/theme.dart` (`AppColors`, `AppText`), komponen merek di
`core/brand.dart` (logo, awan, matahari, kartu hero), tombol utama lime di `companion_widgets.dart`. Font Fredoka + Nunito
dibundel (`app/assets/fonts/`), ikon peluncur adaptif dari logo asli. Gerak halus baru: `PopIn`, `QuickIn`, `CountUp`,
transisi FadeForwards; papan anak ikut bergerak halus (lihat PERUBAHAN.md). Dicek di emulator: A1–A6, beranda, misi,
konfirmasi, papan anak + misi, Kembang, Terapis, Atur. 33 tes lulus, analyzer bersih.

## Optimasi HP kentang (diukur di emulator arm64 Android 16, `-memory 2048 -cores 2`, APK rilis; **perkiraan, bukan HP fisik**)
- O1 klip kata tunggal lewat SoundPool (`PlayerMode.lowLatency`, satu pemutar per klip, LRU 40), kata inti dimuat saat
  bootstrap, halaman kategori saat tab dibuka. UCAPKAN dan rekaman keluarga tetap MediaPlayer. Jeda dari perintah stop
  sampai audio mulai (logcat AudioFocus → AppOps): **median 98 ms → 21 ms** (12 ketukan MAU/BANTU tiap versi)
- O2 sinkron berkala di beranda dilewati saat papan terbuka (`AppState.boardOpen`) dan saat aplikasi di latar belakang
- O3 satu kunci cache gambar per simbol (256 px) untuk papan, bilah, pratinjau; semua halaman didekode di latar sesudah
  frame pertama papan; cache gambar dibatasi 48 MB (120 simbol ± 30 MB)
- O4 perender: Impeller OpenGLES di emulator (tanpa Vulkan). Tidak diubah; belum diuji di GPU Mali/Adreno lama
- O5 APK: gemuk 56,4 MB vs per-ABI `armeabi-v7a` 18,2 MB / `arm64-v8a` 20,7 MB. README: pasang per-ABI, cek ABI HP
- O6 pembangunan ulang: satu-satunya pendengar `AppState` adalah `BootGate` (mengembalikan `const HomeScreen`), jadi
  ketukan tidak membangun ulang layar lain; tidak ada yang diubah. Thread UI (APK profil): median 0,3 ms, p90 ≤ 3,1 ms,
  lonjakan 40 ms saat papan dibuka. Raster 44–58 ms di emulator = SwiftShader, bukan angka GPU

## Tonggak selesai (tag)
- j1-kerangka: app terbuka, AppScope di atas MaterialApp, AppState + DAO nyata, DB terbuka, 120 kata termuat
- j1-skema: skema = kontrak, pemuat CSV sekali, 10 tes lulus. 1 tes dilewati: 6 simbol gambar tim halaman 0 belum ada
- j1-papan: B4 + B5 di emulator (HP) dan 320 dp; ketuk menambah bilah + bunyi; KEGIATAN: enam sel teratas identik posisinya
- j1-outbox: event + outbox satu transaksi; 10 ketukan = 10 + 10 baris; matikan paksa → angka tetap; trigger menolak
  UPDATE isi/DELETE, UPDATE synced_at lolos (diuji dengan sqlite3 di emulator)
- j1-kunci: screen pinning; Home tidak keluar dari papan anak (PINNED), tahan TAHAN 1,5 dtk → keluar + lepas kunci

## Selesai tanpa tag
- Skema v2: tabel `therapist_summary` (ringkasan sesi dari terapis, C5), pemutakhiran menjalankan ulang pernyataan
  `IF NOT EXISTS`. `SummaryDao`, `SymbolDao.insertCustom`. Kartu personal (`data/personal_card.dart`): `word_id`
  `prs-<label>-<6 hex>`, slot kosong berikutnya sesudah sel cermin. Hitungan pemakaian murni (`usage_stats.dart`)
  untuk B1/C1. Tes `personal_card_and_stats_test.dart`; 33 tes lulus, analyzer bersih
- `core/motion.dart`: `PressScale`, `FadeSlideIn`, `SmoothReveal`, `RecordingDot`, semua lewat `Motion.of` (nol bila
  "Hapus animasi"). Beranda `NavigationBar` 4 tab (hanya tab terpilih dibangun). `boardTheme` mematikan lapisan tekan
  di papan. `CompanionColors` = typedef `AppColors`. Tes `motion_test.dart`. Dicek di emulator: misi → papan →
  MAU ×2 + geser AKU → kembali "2 dari 5" → Selesai → Hari ini "MAU MAKAN MAU AKU"
- Bilah ujaran `ReorderableListView` horizontal: tahan ± 0,5 dtk lalu seret (onReorderItem), kata diangkat 1,05×
  + bayangan, kata baru membuat bilah lompat ke ujung kanan tanpa animasi. Tanpa peristiwa baru. Dicek di emulator:
  MAU BERHENTI BANTU → seret BANTU ke depan → BANTU MAU BERHENTI → UCAPKAN memutar 3 klip
- Rel tab kiri (92 dp, tab 64 dp, 13 tab satu kolom) menggantikan tab bawah; penanda TUBUH sesudah SAKIT tetap jalan
  di rel. Nama tab baru di `pages.csv` (dua salinan + hash PROVENANCE diperbarui, `validate_vocab` LULUS). Keadaan
  tekan seketika di `SymbolCell`; bilah ujaran berbentuk jalur cekung; UCAPKAN tinggi 64 dp. Dicek di emulator
- Penanda tab TUBUH setelah SAKIT (N1); tahan-untuk-memilih batal saat jari menggulir; label kata misi memakai
  `label_display`. Diuji di emulator: SAKIT → tab TUBUH bergaris toska → PERUT → UCAPKAN "sakit perut"
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
- (13:55) `AppState`: `summaryDao`, `nextCardSlot(page)`, `addPersonalCard(label:, page:, photoPath:)`, `childLock`/
  `setChildLock`, `afterOnboarding` (enum `AfterOnboarding`). `PrefKeys.childLock`. Sinkron menarik
  `/shared-summaries` terbaik-usaha setelah target.
- `TargetDao.upsertFromServer` tidak menimpa status lokal `diterima`/`ditolak`.
- Konstanta di `core/constants.dart`; waktu ber-offset di `core/time.dart` (`nowIso()`, `isoWithOffset()`, `localDate()`).
- Windows: build Gradle "Unable to establish loopback connection" → set `TEMP`/`TMP` ke `C:\dev\tmp` (path tanpa spasi).

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
