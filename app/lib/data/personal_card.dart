/// Kartu personal dari foto (C3).
///
/// `word_id` kartu personal berbentuk `prs-<label>-<6 hex>`, mis. `prs-gelas-3fa9c1`. Label ikut di dalam id supaya
/// dasbor terapis bisa menampilkan GELAS tanpa tabel tambahan; fotonya tidak pernah meninggalkan perangkat.
/// Label diubah ke huruf kecil dan karakter selain huruf/angka menjadi `_`, jadi id tidak pernah berisi spasi
/// (konten `UCP` memisahkan `word_id` dengan spasi).
library;

import 'dart:math' as math;

const personalPrefix = 'prs-';

/// Panjang label kartu personal (huruf kapital di sel papan).
const personalLabelMax = 20;

/// Label yang boleh disimpan: dirapikan spasinya, huruf kapital, paling panjang [personalLabelMax].
String normalizePersonalLabel(String raw) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  return t.length > personalLabelMax ? t.substring(0, personalLabelMax).trimRight() : t;
}

String personalWordId(String label, {math.Random? random}) {
  final slug = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  final r = random ?? math.Random.secure();
  final hex = List.generate(6, (_) => r.nextInt(16).toRadixString(16)).join();
  return '$personalPrefix${slug.isEmpty ? 'kartu' : slug}-$hex';
}

bool isPersonalWordId(String wordId) => wordId.startsWith(personalPrefix);

/// Slot kosong pertama untuk kartu baru di halaman kategori: mulai sesudah sel cermin, lewati slot yang terisi
/// (termasuk kata tersembunyi, karena ia tetap memegang posisinya). [cells] = hasil `buildCells`.
int nextFreeSlot(List<Object?> cells, {required int firstContentSlot}) {
  for (var i = firstContentSlot; i < cells.length; i++) {
    if (cells[i] == null) return i;
  }
  return cells.length < firstContentSlot ? firstContentSlot : cells.length;
}
