/// DAO tulisan tangan, satu kelas per tabel. Tanpa codegen.
library;

import 'dart:math' as math;

import 'package:sqflite/sqflite.dart';

import '../../core/constants.dart';
import '../models.dart';
import '../phrase.dart';

class ChildDao {
  ChildDao(this.db);
  final Database db;

  /// Aplikasi memegang satu anak per perangkat.
  Future<Child?> first() async {
    final rows = await db.query('child', orderBy: 'created_at', limit: 1);
    return rows.isEmpty ? null : Child.fromRow(rows.first);
  }

  Future<void> insert(Child c) => db.insert('child', c.toRow());

  /// Mengganti rutinitas (A3 "bisa diganti kapan saja di pengaturan"). `grid_cols` sengaja tidak punya pengubah.
  Future<void> updateRoutine(String childId, String routine) =>
      db.update('child', {'routine': routine}, where: 'child_id = ?', whereArgs: [childId]);
}

class SymbolDao {
  SymbolDao(this.db);
  final Database db;

  Future<int> count() async => Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM symbol')) ?? 0;

  Future<List<WordSymbol>> all() async {
    final rows = await db.query('symbol', orderBy: 'page, position_index');
    return rows.map(WordSymbol.fromRow).toList();
  }

  /// Sisipkan semua dalam satu transaksi (pemuat CSV sekali jalan).
  Future<void> insertAll(List<WordSymbol> symbols) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in symbols) {
        batch.insert('symbol', s.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Perbarui `symbol_path` kata bawaan dari CSV dan pastikan kata bawaan tidak bertanda `is_custom`
  /// (versi lama menandai kata bergambar tim sebagai kartu personal, sehingga ketukannya tercatat PRS).
  Future<void> refreshBuiltIn(List<WordSymbol> fromCsv) async {
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final s in fromCsv) {
        batch.update('symbol', {'symbol_path': s.symbolPath, 'is_custom': 0}, where: 'word_id = ?', whereArgs: [s.wordId]);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Menyembunyikan simbol tetap memegang posisinya (invarian 8): baris tidak dihapus, sel tampil kosong.
  Future<void> setHidden(String wordId, bool hidden) =>
      db.update('symbol', {'is_hidden': hidden ? 1 : 0}, where: 'word_id = ?', whereArgs: [wordId]);

  /// Pindahkan simbol ke posisi lain di halamannya (keputusan orang tua di Kelola kosakata, bukan papan anak).
  /// Bila posisi tujuan terisi, kedua simbol bertukar tempat. Satu transaksi; posisi sementara -1 menghindari
  /// benturan `UNIQUE (page, position_index)`.
  Future<void> moveWithinPage(int page, int from, int to) async {
    if (from == to) return;
    await db.transaction((txn) async {
      await txn.update('symbol', {'position_index': -1}, where: 'page = ? AND position_index = ?', whereArgs: [page, from]);
      await txn.update('symbol', {'position_index': from}, where: 'page = ? AND position_index = ?', whereArgs: [page, to]);
      await txn.update('symbol', {'position_index': to}, where: 'page = ? AND position_index = -1', whereArgs: [page]);
    });
  }

  /// Hapus kartu buatan keluarga (kartu foto `prs-` atau kartu frasa `frs-`). Kata bawaan tidak pernah dihapus,
  /// hanya disembunyikan. Log peristiwa lama tetap utuh (invarian 3).
  Future<void> deleteCustom(String wordId) => db.delete('symbol', where: 'word_id = ? AND is_custom = 1', whereArgs: [wordId]);

  /// Kartu personal (C3). Gagal bila posisi di halaman itu sudah terisi (`UNIQUE (page, position_index)`).
  Future<void> insertCustom(WordSymbol s) => db.insert('symbol', s.toRow(), conflictAlgorithm: ConflictAlgorithm.abort);

  /// Klip kartu frasa setelah terunduh (jalur berkas lokal).
  Future<void> setAudioPath(String wordId, String path) =>
      db.update('symbol', {'audio_path': path}, where: 'word_id = ?', whereArgs: [wordId]);

  /// Rekaman keluarga, jalur berkas lokal. Tidak pernah disinkronkan (invarian 18).
  Future<void> setFamilyAudio(String wordId, String? path) =>
      db.update('symbol', {'family_audio': path}, where: 'word_id = ?', whereArgs: [wordId]);
}

/// Log peristiwa append-only + outbox (invarian 3 dan 4).
///
/// Urutan yang benar di klien sinkron (jalur 2): kirim [pendingBatch] → **hanya bila server menjawab 200**
/// panggil [markSynced]; selain itu [defer]. Kalau aplikasi mati di antara jawaban server dan
/// [markSynced], batch terkirim ulang dan server menghitungnya sebagai duplikat. Itu benar (idempoten
/// berdasarkan `event_id`).
class EventDao {
  EventDao(this.db);
  final Database db;

  /// INSERT `utterance_event` dan `outbox` dalam **satu transaksi**.
  Future<void> append(UtteranceEvent e) async {
    await db.transaction((txn) async {
      await txn.insert('utterance_event', e.toRow());
      await txn.insert('outbox', {'event_id': e.eventId, 'attempts': 0});
    });
  }

  /// Peristiwa yang siap dikirim (belum lewat masa tunggu backoff), urut sesuai waktu masuk outbox.
  Future<List<UtteranceEvent>> pendingBatch({int limit = Limits.syncBatch}) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await db.rawQuery(
      'SELECT e.* FROM outbox o JOIN utterance_event e ON e.event_id = o.event_id '
      'WHERE o.next_try_at IS NULL OR o.next_try_at <= ? ORDER BY o.id LIMIT ?',
      [now, limit],
    );
    return rows.map(UtteranceEvent.fromRow).toList();
  }

  /// Dalam satu transaksi: isi `synced_at` (satu-satunya kolom yang boleh di-UPDATE) dan hapus baris outbox.
  Future<void> markSynced(List<String> eventIds, String ts) async {
    if (eventIds.isEmpty) return;
    await db.transaction((txn) async {
      for (final chunk in _chunks(eventIds)) {
        final q = List.filled(chunk.length, '?').join(',');
        await txn.rawUpdate('UPDATE utterance_event SET synced_at = ? WHERE event_id IN ($q)', [ts, ...chunk]);
        await txn.rawDelete('DELETE FROM outbox WHERE event_id IN ($q)', chunk);
      }
    });
  }

  /// Gagal kirim: naikkan `attempts` dan isi `next_try_at` dengan backoff eksponensial (5 dtk × 2^n, maks 10 mnt).
  Future<void> defer(List<String> eventIds) async {
    if (eventIds.isEmpty) return;
    await db.transaction((txn) async {
      for (final chunk in _chunks(eventIds)) {
        final q = List.filled(chunk.length, '?').join(',');
        final rows = await txn.rawQuery('SELECT id, attempts FROM outbox WHERE event_id IN ($q)', chunk);
        for (final r in rows) {
          final attempts = (r['attempts']! as int) + 1;
          final secs = math.min(600, 5 * math.pow(2, attempts - 1).toInt());
          final next = DateTime.now().toUtc().add(Duration(seconds: secs)).toIso8601String();
          await txn.update('outbox', {'attempts': attempts, 'next_try_at': next}, where: 'id = ?', whereArgs: [r['id']]);
        }
      }
    });
  }

  /// Jumlah peristiwa yang belum sampai ke server (termasuk yang sedang menunggu backoff).
  Future<int> outboxCount() async => Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM outbox')) ?? 0;

  Future<int> totalCount() async => Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM utterance_event')) ?? 0;

  /// `synced_at` terbaru, untuk kartu "Terakhir {waktu}" di B1.
  Future<String?> lastSyncedAt() async {
    final rows = await db.rawQuery('SELECT MAX(synced_at) AS t FROM utterance_event');
    return rows.first['t'] as String?;
  }

  /// Stempel waktu ketukan pendamping terakhir (untuk `prompt_level`).
  Future<String?> lastParentTapTs(String childId) async {
    final rows = await db.rawQuery(
      "SELECT ts_device FROM utterance_event WHERE child_id = ? AND actor = ? AND method IN ('SEL','KAT','PRS') "
      'ORDER BY ts_device DESC LIMIT 1',
      [childId, Actor.pendamping],
    );
    return rows.isEmpty ? null : rows.first['ts_device'] as String?;
  }

  /// Peristiwa pada tanggal lokal `YYYY-MM-DD` (prefiks `ts_device`) dengan penyaring opsional.
  /// Contoh penghitung misi (02 §5): `countOnDate(childId, today, actor: 'pendamping',
  /// methods: {'SEL','KAT'}, content: targetWord, context: missionId)`.
  Future<int> countOnDate(String childId, String date, {String? actor, Set<String>? methods, String? content, String? context}) async {
    final where = <String>['child_id = ?', 'ts_device LIKE ?'];
    final args = <Object?>[childId, '$date%'];
    if (actor != null) {
      where.add('actor = ?');
      args.add(actor);
    }
    if (methods != null && methods.isNotEmpty) {
      where.add('method IN (${List.filled(methods.length, '?').join(',')})');
      args.addAll(methods);
    }
    if (content != null) {
      where.add('content = ?');
      args.add(content);
    }
    if (context != null) {
      where.add('context = ?');
      args.add(context);
    }
    final rows = await db.rawQuery('SELECT COUNT(*) FROM utterance_event WHERE ${where.join(' AND ')}', args);
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Semua peristiwa anak dengan `ts_device >= fromIso` (string ISO lokal), terlama dulu.
  /// Untuk ringkasan pekan (B1) dan riwayat (C1).
  Future<List<UtteranceEvent>> since(String childId, String fromIso) async {
    final rows = await db.query(
      'utterance_event',
      where: 'child_id = ? AND ts_device >= ?',
      whereArgs: [childId, fromIso],
      orderBy: 'ts_device',
    );
    return rows.map(UtteranceEvent.fromRow).toList();
  }

  /// Semua peristiwa (untuk ekspor S7).
  Future<List<UtteranceEvent>> all() async {
    final rows = await db.query('utterance_event', orderBy: 'ts_device');
    return rows.map(UtteranceEvent.fromRow).toList();
  }

  static Iterable<List<String>> _chunks(List<String> ids) sync* {
    for (var i = 0; i < ids.length; i += 400) {
      yield ids.sublist(i, math.min(i + 400, ids.length));
    }
  }
}

class MissionDao {
  MissionDao(this.db);
  final Database db;

  /// Simpan definisi misi (`mission_id = "misi-w{week}"`, 02 §5). Menimpa bila sudah ada.
  Future<void> upsert(Mission m) => db.insert('mission', m.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<Mission?> byId(String missionId) async {
    final rows = await db.query('mission', where: 'mission_id = ?', whereArgs: [missionId]);
    return rows.isEmpty ? null : Mission.fromRow(rows.first);
  }

  Future<MissionLog?> logFor(String missionId, String date) async {
    final rows = await db.query('mission_log', where: 'mission_id = ? AND date = ?', whereArgs: [missionId, date]);
    return rows.isEmpty ? null : MissionLog.fromRow(rows.first);
  }

  /// Satu `mission_log` per (misi, tanggal). Konfirmasi ulang di hari yang sama memperbarui baris ini.
  Future<void> upsertLog(String missionId, String date, String status, int repsCounted) => db.rawInsert(
    'INSERT INTO mission_log (mission_id, date, status, reps_counted) VALUES (?, ?, ?, ?) '
    'ON CONFLICT(mission_id, date) DO UPDATE SET status = excluded.status, reps_counted = excluded.reps_counted',
    [missionId, date, status, repsCounted],
  );

  Future<List<MissionLog>> logs() async {
    final rows = await db.query('mission_log', orderBy: 'date');
    return rows.map(MissionLog.fromRow).toList();
  }
}

class TargetDao {
  TargetDao(this.db);
  final Database db;

  Future<List<VocabTarget>> all() async {
    final rows = await db.query('vocab_target', orderBy: 'received_at DESC');
    return rows.map(VocabTarget.fromRow).toList();
  }

  Future<VocabTarget?> byId(String targetId) async {
    final rows = await db.query('vocab_target', where: 'target_id = ?', whereArgs: [targetId]);
    return rows.isEmpty ? null : VocabTarget.fromRow(rows.first);
  }

  /// Simpan target dari server. **Status lokal adalah kebenaran**: jawaban `diterima`/`ditolak` lokal
  /// tidak pernah ditimpa `usulan` dari server yang belum menerima peristiwa TGT.
  Future<void> upsertFromServer(VocabTarget t) async {
    final existing = await byId(t.targetId);
    if (existing == null) {
      await db.insert('vocab_target', t.toRow());
      return;
    }
    final status = existing.status == TargetStatus.usulan ? t.status : existing.status;
    await db.update(
      'vocab_target',
      {'words': t.toRow()['words'], 'note': t.note, 'week_index': t.weekIndex, 'status': status},
      where: 'target_id = ?',
      whereArgs: [t.targetId],
    );
  }

  Future<void> setStatus(String targetId, String status) =>
      db.update('vocab_target', {'status': status}, where: 'target_id = ?', whereArgs: [targetId]);
}

class LinkDao {
  LinkDao(this.db);
  final Database db;

  Future<List<TherapistLink>> all() async {
    final rows = await db.query('therapist_link', orderBy: 'linked_at DESC');
    return rows.map(TherapistLink.fromRow).toList();
  }

  /// Tautan aktif (belum dicabut), atau `null`.
  Future<TherapistLink?> active() async {
    final rows = await db.query(
      'therapist_link',
      where: 'revoked_at IS NULL AND linked_at IS NOT NULL',
      orderBy: 'linked_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : TherapistLink.fromRow(rows.first);
  }

  Future<void> insert(TherapistLink l) => db.insert('therapist_link', l.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> markRevoked(String linkId, String ts) =>
      db.update('therapist_link', {'revoked_at': ts}, where: 'link_id = ?', whereArgs: [linkId]);
}

class SummaryDao {
  SummaryDao(this.db);
  final Database db;

  Future<List<TherapistSummary>> all() async {
    final rows = await db.query('therapist_summary', orderBy: 'shared_at DESC');
    return rows.map(TherapistSummary.fromRow).toList();
  }

  /// Simpan ringkasan dari server; kiriman ulang dari terapis menimpa baris yang sama.
  Future<void> upsert(TherapistSummary s) => db.insert('therapist_summary', s.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
}

class PhraseDao {
  PhraseDao(this.db);
  final Database db;

  Future<List<Phrase>> all() async {
    final rows = await db.query('phrase', orderBy: 'created_at DESC');
    return rows.map(Phrase.fromRow).toList();
  }

  Future<Phrase?> byId(String phraseId) async {
    final rows = await db.query('phrase', where: 'phrase_id = ?', whereArgs: [phraseId]);
    return rows.isEmpty ? null : Phrase.fromRow(rows.first);
  }

  /// Simpan frasa dari server. Seperti target: jawaban lokal (`diterima`/`ditolak`) tidak ditimpa `usulan`
  /// dari server yang belum menerima peristiwa TGT, dan jalur klip lokal dipertahankan.
  Future<void> upsertFromServer(Phrase p) async {
    final existing = await byId(p.phraseId);
    if (existing == null) {
      await db.insert('phrase', p.toRow());
      return;
    }
    final status = existing.status == PhraseStatus.usulan ? p.status : existing.status;
    await db.update('phrase', {'status': status}, where: 'phrase_id = ?', whereArgs: [p.phraseId]);
  }

  Future<void> setStatus(String phraseId, String status) =>
      db.update('phrase', {'status': status}, where: 'phrase_id = ?', whereArgs: [phraseId]);

  Future<void> setAudio(String phraseId, String path) =>
      db.update('phrase', {'audio_path': path}, where: 'phrase_id = ?', whereArgs: [phraseId]);
}
