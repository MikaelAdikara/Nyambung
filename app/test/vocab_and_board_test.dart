import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/app_state.dart';
import 'package:nyambung/data/db/schema.dart';
import 'package:nyambung/data/repo/vocab_loader.dart';

/// Tes tanpa sqflite: pengurai CSV, isi kosakata, cermin, dan paritas skema.
void main() {
  final vocabText = File(vocabCsvAsset).readAsStringSync();
  final pagesText = File(pagesCsvAsset).readAsStringSync();
  final symbols = parseVocab(vocabText);
  final pages = parsePages(pagesText);
  final page0 = symbols.where((s) => s.page == 0).toList()..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));

  group('pengurai CSV', () {
    test('menghormati kutip, koma di dalam kutip, kutip ganda, CRLF, dan medan kosong', () {
      final rows = parseCsv('a,b,c\r\n1,"x, y",\r\n2,"say ""hi""",z\n');
      expect(rows, [
        ['a', 'b', 'c'],
        ['1', 'x, y', ''],
        ['2', 'say "hi"', 'z'],
      ]);
    });

    test('freq_rank kosong itu sah (bigram)', () {
      final km = csvToMaps(vocabText).firstWhere((r) => r['word_id'] == 'kamar_mandi');
      expect(km['freq_rank'], isEmpty);
    });
  });

  group('kosakata', () {
    test('120 baris, word_id unik, (page, position_index) unik', () {
      expect(symbols, hasLength(120));
      expect(symbols.map((s) => s.wordId).toSet(), hasLength(120));
      expect(symbols.map((s) => '${s.page}:${s.positionIndex}').toSet(), hasLength(120));
    });

    test('halaman 0 berisi 12 kata di posisi 0–11 sesuai susunan tetap', () {
      expect(page0.map((s) => s.positionIndex), List.generate(12, (i) => i));
      expect(page0.map((s) => s.wordId), [
        'mau', 'berhenti', 'bantu', //
        'tidak', 'selesai', 'sakit',
        'aku', 'makan', 'minum',
        'ya', 'lagi', 'itu',
      ]);
    });

    test('halaman 1–12 tidak memakai posisi 0–5 dan jumlah kata cocok dengan pages.csv', () {
      final rows = csvToMaps(pagesText);
      for (final r in rows) {
        final p = int.parse(r['page']!);
        final own = symbols.where((s) => s.page == p).toList();
        expect(own, hasLength(int.parse(r['content_slots_used']!)), reason: 'halaman $p');
        if (p > 0) expect(own.where((s) => s.positionIndex < mirrorSlots), isEmpty, reason: 'halaman $p');
      }
      expect(pages, hasLength(13));
    });

    test('symbol_path menunjuk ke assets/symbols/png atau assets/symbols/custom', () {
      for (final s in symbols) {
        expect(s.symbolPath, anyOf(startsWith('assets/symbols/png/'), startsWith('assets/symbols/custom/')));
        expect(s.isCustom, s.symbolPath.startsWith('assets/symbols/custom/'));
      }
    });

    test('setiap simbol Mulberry punya berkas PNG di aset', () {
      final missing = symbols.where((s) => !s.isCustom && !File(s.symbolPath).existsSync()).map((s) => s.wordId);
      expect(missing, isEmpty);
    });

    final customMissing = page0.where((s) => !File(s.symbolPath).existsSync()).map((s) => s.wordId).toList();
    test(
      'setiap kata halaman 0 punya berkas simbol (tidak jatuh ke cadangan huruf)',
      () => expect(customMissing, isEmpty),
      skip: customMissing.isEmpty ? false : 'menunggu gambar tim dari jalur 4 (j4-simbol-inti): ${customMissing.join(', ')}',
    );
  });

  group('papan', () {
    test('sel 0–5 setiap halaman kategori = posisi 0–5 halaman 0 dan cocok dengan mirror_word_ids', () {
      final top = page0.take(mirrorSlots).map((s) => s.wordId).toList();
      for (final page in pages.where((p) => p.page > 0)) {
        final cells = buildCells(symbols, page.page);
        expect(cells.take(mirrorSlots).map((s) => s?.wordId), top, reason: 'halaman ${page.page}');
        expect(page.mirrorWordIds, top, reason: 'pages.csv halaman ${page.page}');
      }
    });

    test('sel ditempatkan berdasarkan position_index; slot kosong tetap memegang tempat', () {
      for (final page in pages) {
        final cells = buildCells(symbols, page.page);
        for (var i = 0; i < cells.length; i++) {
          if (cells[i] != null) expect(cells[i]!.positionIndex, i);
        }
      }
    });
  });

  test('schema.dart identik dengan schema.sql', () {
    final sql = File('lib/data/db/schema.sql').readAsStringSync();
    expect(normalizeSql(schemaStatements.map((s) => '$s;').join('\n')), normalizeSql(sql));
  });
}
