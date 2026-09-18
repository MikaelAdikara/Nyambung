import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../db/dao.dart';
import '../models.dart';

const vocabCsvAsset = 'assets/vocab/core_vocab_id.csv';
const pagesCsvAsset = 'assets/vocab/pages.csv';

/// Pengurai CSV RFC 4180 kecil: menghormati kutip, `""` di dalam kutip, CRLF, dan medan kosong.
List<List<String>> parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  if (text.startsWith('﻿')) i = 1;
  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRow() {
    endField();
    if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
    row = <String>[];
  }

  for (; i < text.length; i++) {
    final ch = text[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(ch);
      }
    } else if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      endField();
    } else if (ch == '\n') {
      endRow();
    } else if (ch != '\r') {
      field.write(ch);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) endRow();
  return rows;
}

/// CSV → baris berkunci nama kolom.
List<Map<String, String>> csvToMaps(String text) {
  final rows = parseCsv(text);
  if (rows.isEmpty) return const [];
  final header = rows.first.map((h) => h.trim()).toList();
  return [
    for (final r in rows.skip(1)) {for (var c = 0; c < header.length; c++) header[c]: c < r.length ? r[c] : ''},
  ];
}

/// `symbol_file` → jalur aset. `mau.png` → `assets/symbols/png/mau.png`; `custom/aku.png` → `assets/symbols/custom/aku.png`.
String symbolAssetPath(String symbolFile) =>
    symbolFile.startsWith('custom/') ? 'assets/symbols/$symbolFile' : 'assets/symbols/png/$symbolFile';

/// Satu baris `core_vocab_id.csv` → [WordSymbol]. `freq_rank` tidak dipakai (boleh kosong).
WordSymbol symbolFromCsv(Map<String, String> r) {
  final file = r['symbol_file']!.trim();
  final audio = (r['audio_human_file'] ?? '').trim();
  return WordSymbol(
    wordId: r['word_id']!.trim(),
    labelDisplay: r['label_display']!.trim(),
    labelSpeech: r['label_speech']!.trim(),
    pos: r['pos']!.trim(),
    category: r['category']!.trim(),
    page: int.parse(r['page']!.trim()),
    positionIndex: int.parse(r['position_index']!.trim()),
    symbolPath: symbolAssetPath(file),
    audioPath: audio.isEmpty ? null : 'assets/audio/core/$audio',
    // Kata bawaan tidak pernah `is_custom`, walau gambarnya buatan tim (custom/): penanda itu khusus kartu personal
    // dan frasa keluarga, yang ketukannya dicatat `PRS`.
  );
}

List<WordSymbol> parseVocab(String csvText) => csvToMaps(csvText).map(symbolFromCsv).toList();

/// Satu halaman papan dari `pages.csv`.
class BoardPage {
  const BoardPage(this.page, this.tabLabel, this.mirrorWordIds);

  final int page;
  final String tabLabel;

  /// Hanya untuk verifikasi di tes. Aplikasi menggambar cermin dari **posisi** halaman 0.
  final List<String> mirrorWordIds;
}

List<BoardPage> parsePages(String csvText) => [
  for (final r in csvToMaps(csvText))
    BoardPage(
      int.parse(r['page']!.trim()),
      r['tab_label']!.trim(),
      r['mirror_word_ids']!.trim().isEmpty ? const [] : r['mirror_word_ids']!.trim().split(RegExp(r'\s+')),
    ),
];

/// Memuat CSV ke tabel `symbol` **sekali**: hanya bila tabel kosong, dalam satu transaksi,
/// lalu ditandai selesai di `shared_preferences`.
class VocabLoader {
  VocabLoader(this.symbols, this.bundle);

  final SymbolDao symbols;
  final AssetBundle bundle;

  Future<void> ensureLoaded() async {
    if (await symbols.count() > 0) {
      // Perbarui gambar kata bawaan dari CSV terbaru (mis. simbol Mulberry baru). Posisi, sembunyi, dan rekaman
      // keluarga tidak disentuh.
      await symbols.refreshBuiltIn(parseVocab(await bundle.loadString(vocabCsvAsset)));
      return;
    }
    final parsed = parseVocab(await bundle.loadString(vocabCsvAsset));
    await symbols.insertAll(parsed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.vocabLoaded, true);
  }

  Future<List<BoardPage>> loadPages() async => parsePages(await bundle.loadString(pagesCsvAsset));
}
