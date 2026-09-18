import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/time.dart';
import 'package:nyambung/data/models.dart';
import 'package:nyambung/features/coach/mission_rules.dart';
import 'package:nyambung/features/progress/progress_screen.dart';

UtteranceEvent tap(String word, DateTime at, {String actor = 'anak', String method = 'SEL'}) => UtteranceEvent(
  eventId: '$word-${at.microsecondsSinceEpoch}-$actor',
  childId: 'c',
  tsDevice: isoWithOffset(at),
  content: word,
  method: method,
  actor: actor,
  promptLevel: 'spontan',
  context: 'makan',
  sessionId: 's',
);

void main() {
  test('riwayat C1: 6 pekan terbaru di atas, kata baru hanya di pekan pertama muncul', () {
    final created = DateTime(2026, 8, 1, 9);
    final events = [
      tap('mau', created.add(const Duration(days: 1))), // pekan 1
      tap('mau', created.add(const Duration(days: 8))), // pekan 2, bukan kata baru
      tap('tidak', created.add(const Duration(days: 9))), // pekan 2, baru
      tap('lagi', created.add(const Duration(days: 9)), actor: 'pendamping'), // bukan ketukan anak
      tap('mau tidak', created.add(const Duration(days: 9)), method: 'UCP'), // bukan ketukan
    ];
    final history = buildHistory(events, created, 7);
    expect(history.map((w) => w.week), [7, 6, 5, 4, 3, 2]);
    final w2 = history.last;
    expect(w2.uniqueWords, 2);
    expect(w2.newWords, ['tidak']);
    expect(history.first.uniqueWords, 0);
  });

  test('riwayat C1 di pekan pertama hanya satu pekan', () {
    final created = DateTime.now();
    expect(buildHistory(const [], created, 1).map((w) => w.week), [1]);
  });

  test('format waktu singkat dan tanggal', () {
    final now = DateTime(2026, 9, 18, 12);
    expect(formatWaktuSingkat(isoWithOffset(DateTime(2026, 9, 18, 10, 5)), now: now), 'hari ini 10.05');
    expect(formatWaktuSingkat(isoWithOffset(DateTime(2026, 9, 17, 18, 30)), now: now), 'kemarin 18.30');
    expect(formatWaktuSingkat(isoWithOffset(DateTime(2026, 9, 16, 7, 0)), now: now), '16 September 07.00');
    expect(formatTanggal(isoWithOffset(DateTime(2026, 9, 18, 10))), '18 September 2026');
  });
}
