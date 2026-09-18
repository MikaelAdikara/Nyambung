import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/features/progress/today_journal.dart';
import 'package:nyambung/data/models.dart';

UtteranceEvent ev(String ts, String content, String method, {String actor = 'anak', String session = 's1', String? context = 'makan'}) =>
    UtteranceEvent(
      eventId: '$ts$content$method',
      childId: 'c',
      tsDevice: ts,
      content: content,
      method: method,
      actor: actor,
      promptLevel: 'spontan',
      context: context,
      sessionId: session,
    );

void main() {
  test('sesi dengan UCAPKAN tampil sebagai ujaran; ketukan tunggalnya tidak diulang', () {
    final items = buildTodayJournal([
      ev('2026-09-18T07:30:00+07:00', 'mau', 'SEL'),
      ev('2026-09-18T07:30:05+07:00', 'minum', 'SEL'),
      ev('2026-09-18T07:30:09+07:00', 'mau minum', 'UCP'),
    ]);
    expect(items, hasLength(1));
    expect(items.single.words, ['mau', 'minum']);
    expect(items.single.spoken, isTrue);
  });

  test('sesi tanpa UCAPKAN tampil sebagai deretan ketukan, dipisah anak dan pendamping', () {
    final items = buildTodayJournal([
      ev('2026-09-18T17:00:00+07:00', 'mau', 'SEL', actor: 'pendamping', session: 's2', context: 'misi-w1'),
      ev('2026-09-18T17:00:10+07:00', 'lagi', 'SEL', session: 's2', context: 'misi-w1'),
    ]);
    expect(items.map((i) => i.actor).toSet(), {'anak', 'pendamping'});
    expect(items.every((i) => !i.spoken), isTrue);
  });

  test('MIS, TGT, dan HAP tidak pernah tampil sebagai ujaran; urutan terbaru dulu dan dibatasi', () {
    final events = [
      ev('2026-09-18T08:00:00+07:00', 'selesai', 'MIS', actor: 'pendamping', session: 'x', context: 'misi-w1'),
      ev('2026-09-18T08:00:01+07:00', 'diterima', 'TGT', actor: 'pendamping', session: 'x', context: 't1'),
      ev('2026-09-18T08:00:02+07:00', 'mau', 'HAP', session: 'y'),
      for (var i = 0; i < 12; i++) ev('2026-09-18T09:${i.toString().padLeft(2, '0')}:00+07:00', 'ya', 'UCP', session: 'u$i'),
    ];
    final items = buildTodayJournal(events);
    expect(items, hasLength(10));
    expect(items.first.at.isAfter(items.last.at), isTrue);
    expect(items.expand((i) => i.words).toSet(), {'ya'});
  });
}
