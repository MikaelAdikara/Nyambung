# Status jalur 1 — Papan
Diperbarui: 09:55

## Sedang dikerjakan
1.2 Skema + pemuat kosakata (tes CSV, paritas skema, cermin)

## Tonggak selesai (tag)
- j1-kerangka (09:55): app terbuka, AppScope di atas MaterialApp, AppState + DAO nyata, DB terbuka, 120 kata termuat

## Perkiraan tonggak berikutnya
j1-skema sekitar 10:30

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 2: titik masuk A1 dan B1 ada di `app/lib/main.dart` (`BootGate`), sementara berisi
  `PlaceholderOnboarding` / `PlaceholderHome` dari `core/placeholder_home.dart`. Tulis di statusmu nama kelas
  layar A1 dan B1 bila siap, jalur 1 yang mengganti.
- ke jalur 2: `FutureBuilder` pakai `CachedFuture` (`core/cached_future.dart`) dengan kunci `app.dataVersion`,
  jangan future yang dibuat di `build()`. `AppScope.of` hanya di `build`/`didChangeDependencies`.
- ke jalur 4: 6 simbol halaman 0 (TIDAK, YA, BERHENTI, SAKIT, AKU, ITU) ditunggu di `assets/symbols/custom/`;
  sampai ada, papan menampilkan huruf pertama.

## Perubahan API/kontrak yang perlu diketahui
- Model simbol bernama `WordSymbol` (bukan `Symbol`, bentrok dengan `dart:core`). Semua model di `app/lib/data/models.dart`.
- `AppState`: `child`, `dataVersion`, `createChild(nickname:, ageYears:, routine:, gridCols: 3)`,
  `logTap(content:, method:, byParent:, context:)`, `logMission(missionId, status)` (menghitung `reps_counted` sendiri
  dari ketukan; simpan dulu `Mission` lewat `missionDao.upsert`), `missionReps(missionId, date)`,
  `logTargetAnswer(targetId, accepted)`, `symbolsForPage(page)`, `cellsForPage(page)`, `symbolById(id)`,
  `speech`, `eventDao`, `missionDao`, `targetDao`, `linkDao`, `holdMs`/`setHoldMs`, `markDataChanged()`,
  `deleteAllData()`, `updateRoutine(routine)`.
- `EventDao` sudah nyata (bukan stub): `append` (event + outbox satu transaksi), `pendingBatch(limit: 40)`,
  `markSynced(ids, ts)`, `defer(ids)`, `outboxCount()`, `lastSyncedAt()`, `countOnDate(...)`, `since(...)`, `all()`.
  `UtteranceEvent.toSyncJson()` menghasilkan bentuk peristiwa kontrak §4.
- `TargetDao.upsertFromServer` tidak menimpa status lokal `diterima`/`ditolak`.
- Konstanta `Method`, `Actor`, `PromptLevel`, `MissionStatus`, `TargetStatus`, `Routine`, `PrefKeys` di `core/constants.dart`.
- Windows: build Gradle "Unable to establish loopback connection" → set `TEMP`/`TMP` ke `C:\dev\tmp` (path tanpa spasi).

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
