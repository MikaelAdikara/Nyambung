import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/data/models.dart';
import 'package:nyambung/data/phrase.dart';
import 'package:nyambung/features/board/symbol_cell.dart';

void main() {
  test('word_id frasa sama dengan rumus server (server/tests/test_voice.py)', () {
    expect(phraseWordId('Jangan nyontek!', '3fa9c1d2-0000-4000-8000-000000000000'), 'frs-jangan_nyontek-3fa9c1d2');
    expect(phraseWordId('???', 'abcdef12-3456'), 'frs-frasa-abcdef12');
    expect(phraseWordId('Ayo kita pergi ke sekolah sekarang juga', 'abcdef12'), 'frs-ayo_kita_pergi_ke_sekola-abcdef12');
    expect(isPhraseWordId('frs-halo-12345678'), isTrue);
    expect(phraseWordId('Halo', 'abcdef12').contains(' '), isFalse);
  });

  test('status lokal: frasa keluarga, label suara', () {
    const p = Phrase(
      phraseId: 'abcdef12-0000',
      text: 'Halo',
      voice: PhraseVoice.keluarga,
      createdBy: 'keluarga',
      createdAt: '2026-09-18T10:00:00Z',
      status: PhraseStatus.diterima,
    );
    expect(p.fromFamily, isTrue);
    expect(Phrase.fromRow(p.toRow()).wordId, p.wordId);
    expect(PhraseVoice.label(PhraseVoice.keluarga), 'Suara keluarga');
  });

  testWidgets('kartu frasa menampilkan kalimat lengkap, bukan huruf pertama', (tester) async {
    const card = WordSymbol(
      wordId: 'frs-jangan_nyontek-3fa9c1d2',
      labelDisplay: 'JANGAN NYONTEK',
      labelSpeech: 'Jangan nyontek',
      pos: 'sosial',
      category: 'frasa',
      page: 3,
      positionIndex: 20,
      symbolPath: '',
      isCustom: true,
    );
    await tester.pumpWidget(const MaterialApp(home: Center(child: SymbolFace(symbol: card, width: 120, height: 110))));
    expect(find.text('JANGAN NYONTEK'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
