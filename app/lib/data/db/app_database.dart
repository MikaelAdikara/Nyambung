import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Membuka basis data perangkat (sumber kebenaran, invarian 2).
class AppDatabase {
  AppDatabase._();

  static const fileName = 'nyambung.db';

  static Future<String> path() async => p.join(await getDatabasesPath(), fileName);

  static Future<Database> open() async {
    return openDatabase(
      await path(),
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        final batch = db.batch();
        for (final s in schemaStatements) {
          batch.execute(s);
        }
        await batch.commit(noResult: true);
      },
    );
  }

  /// "Hapus semua data" di C6: menghapus berkas basis data seluruhnya, bukan DELETE baris (kontrak §1).
  /// Tutup [db] dulu. Setelahnya aplikasi harus memanggil `AppState.bootstrap` ulang.
  static Future<void> deleteFile(Database db) async {
    await db.close();
    await deleteDatabase(await path());
  }
}
