import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/app_state.dart';
import 'package:nyambung/core/time.dart';
import 'package:nyambung/data/models.dart';
import 'package:nyambung/data/personal_card.dart';
import 'package:nyambung/features/progress/usage_stats.dart';

UtteranceEvent tap(String word, DateTime at, {String actor = 'anak', String method = 'SEL', String prompt = 'spontan'}) => UtteranceEvent(
  eventId: '$word-${at.microsecondsSinceEpoch}-$actor-$method',
  childId: 'c',
  tsDevice: isoWithOffset(at),
  content: word,
  method: method,
  actor: actor,
  promptLevel: prompt,
  context: 'makan',
  sessionId: 's',
);

WordSymbol sym(String id, int page, int pos, {bool hidden = false}) => WordSymbol(
  wordId: id,
  labelDisplay: id.toUpperCase(),
  labelSpeech: id,
  pos: 'benda',
  category: 'x',
  page: page,
  positionIndex: pos,
  symbolPath: 'assets/symbols/png/$id.png',
  isHidden: hidden,
);

void main() {
  group('kartu personal', () {
    test('label dirapikan dan dibatasi', () {
      expect(normalizePersonalLabel('  gelas   arka '), 'GELAS ARKA');
      expect(normalizePersonalLabel('a' * 30).length, personalLabelMax);
      expect(normalizePersonalLabel('   '), '');
    });

    test('word_id memuat label tanpa spasi, jadi aman di konten UCAPKAN', () {
      final id = personalWordId('GELAS ARKA', random: math.Random(1));
      expect(id, startsWith('prs-gelas_arka-'));
      expect(id.contains(' '), isFalse);
      expect(isPersonalWordId(id), isTrue);
      expect(isPersonalWordId('mau'), isFalse);
      expect(personalWordId('!!!', random: math.Random(1)), startsWith('prs-kartu-'));
    });

    test('kartu baru mengisi slot kosong pertama sesudah cermin; kata tersembunyi tetap memegang slotnya', () {
      final symbols = [
        for (var i = 0; i < 6; i++) sym('inti$i', 0, i),
        sym('nasi', 8, 6),
        sym('roti', 8, 7, hidden: true),
        sym('susu', 8, 9),
      ];
      final cells = buildCells(symbols, 8);
      // Slot 8 kosong; slot 7 dipegang ROTI yang tersembunyi.
      expect(nextFreeSlot(cells, firstContentSlot: mirrorSlots), 8);
      // Halaman kosong: mulai tepat sesudah cermin.
      expect(nextFreeSlot(buildCells(symbols, 11), firstContentSlot: mirrorSlots), 6);
      // Halaman penuh: di ujung.
      final full = [...symbols, sym('teh', 8, 8)];
      expect(nextFreeSlot(buildCells(full, 8), firstContentSlot: mirrorSlots), 10);
    });
  });

  group('hitungan pemakaian', () {
    final now = DateTime(2026, 9, 18, 20);

    test('hanya ketukan anak yang dihitung; spontan dibagi seluruh ketukan anak', () {
      final events = [
        tap('mau', now.subtract(const Duration(hours: 1))),
        tap('mau', now.subtract(const Duration(hours: 2)), prompt: 'terpancing'),
        tap('minum', now.subtract(const Duration(days: 1))),
        tap('lagi', now.subtract(const Duration(hours: 1)), actor: 'pendamping', prompt: 'terpancing'),
        tap('mau minum', now.subtract(const Duration(hours: 1)), method: 'UCP'),
        tap('prs-gelas-abc123', now.subtract(const Duration(hours: 3)), method: 'PRS'),
        tap('tidak', now.subtract(const Duration(days: 9))),
      ];
      final end = DateTime(2026, 9, 19);
      final week = usageBetween(events, from: end.subtract(const Duration(days: 7)), to: end);
      expect(week.childTaps, 4);
      expect(week.uniqueWords, 3);
      expect(week.topWords.first.word, 'mau');
      expect(week.topWords.first.count, 2);
      expect(week.spontaneousShare, 0.75);
      expect(usageBetween(events, to: end).uniqueWords, 4);
      expect(usageBetween(const [], to: end).spontaneousShare, isNull);
    });

    test('batang pekan: terlama dulu, pekan ini terakhir', () {
      final events = [
        tap('mau', now),
        tap('minum', now.subtract(const Duration(days: 2))),
        tap('mau', now.subtract(const Duration(days: 8))),
        tap('lagi', now.subtract(const Duration(days: 20))),
      ];
      expect(weeklyUniqueBars(events, now, weeks: 4), [0, 1, 1, 2]);
    });

    test('titik misi 7 hari dan hitungan selesai sejak tanggal', () {
      final logs = [
        MissionLog(missionId: 'misi-w1', date: localDate(now), status: 'selesai', repsCounted: 5),
        MissionLog(missionId: 'misi-w1', date: localDate(now.subtract(const Duration(days: 2))), status: 'belum_sempat', repsCounted: 0),
        MissionLog(missionId: 'misi-w0', date: localDate(now.subtract(const Duration(days: 9))), status: 'selesai', repsCounted: 5),
      ];
      final dots = missionDays(logs, now);
      expect(dots.length, 7);
      expect(dots.last, isTrue);
      expect(dots[4], isFalse);
      expect(dots.first, isNull);
      final (done, days) = missionDoneSince(logs, now.subtract(const Duration(days: 6)), now);
      expect((done, days), (1, 7));
    });
  });
}
