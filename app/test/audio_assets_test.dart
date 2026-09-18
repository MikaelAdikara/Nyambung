import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Setiap kata di CSV punya klip audio bundel di kedua set suara, dan tidak ada klip yatim.
void main() {
  final wordIds = File('assets/vocab/core_vocab_id.csv')
      .readAsLinesSync()
      .skip(1)
      .where((l) => l.trim().isNotEmpty)
      .map((l) => l.split(',').first)
      .toSet();

  for (final set in ['cowo', 'cewe']) {
    test('audio bundel $set lengkap untuk ${wordIds.length} kata', () {
      final dir = Directory('assets/audio/core/$set');
      final clips = dir.listSync().map((f) => f.uri.pathSegments.last).where((n) => n.endsWith('.ogg')).toSet();
      final expected = {for (final id in wordIds) '$id.ogg'};
      expect(expected.difference(clips), isEmpty, reason: 'kata tanpa klip');
      expect(clips.difference(expected), isEmpty, reason: 'klip tanpa kata');
      for (final name in clips) {
        expect(File('${dir.path}/$name').lengthSync(), greaterThan(1000), reason: '$name terlalu kecil');
      }
    });
  }
}
