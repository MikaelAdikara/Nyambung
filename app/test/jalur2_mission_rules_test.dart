import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/data/models.dart';
import 'package:nyambung/features/coach/mission_rules.dart';

void main() {
  test('pekan misi dimulai dari 1 dan berganti setiap tujuh hari lokal', () {
    final created = DateTime(2026, 9, 18, 8);

    expect(missionWeek(created, DateTime(2026, 9, 18, 23)), 1);
    expect(missionWeek(created, DateTime(2026, 9, 24, 23)), 1);
    expect(missionWeek(created, DateTime(2026, 9, 25)), 2);
  });

  test('tanggal sebelum pembuatan anak tetap menghasilkan pekan pertama', () {
    expect(missionWeek(DateTime(2026, 9, 18), DateTime(2026, 9, 17)), 1);
  });

  test('kata misi bawaan mengikuti urutan per rutinitas, hanya dari 12 kata inti', () {
    for (final entry in routineMissionWords.entries) {
      expect(List.generate(8, (i) => defaultTargetForWeek(i + 1, routine: entry.key)), entry.value);
      expect(defaultTargetForWeek(9, routine: entry.key), entry.value.first);
      expect(
        entry.value.toSet().difference(const {
          'mau',
          'berhenti',
          'bantu',
          'tidak',
          'selesai',
          'sakit',
          'aku',
          'makan',
          'minum',
          'ya',
          'lagi',
          'itu',
        }),
        isEmpty,
      );
    }
    // Pekan pertama selalu fungsi meminta (MAU atau LAGI).
    expect({for (final r in routineMissionWords.keys) defaultTargetForWeek(1, routine: r)}, {'mau', 'lagi'});
  });

  test('pelajaran berulang dalam urutan yang dibekukan', () {
    expect(List.generate(5, (index) => lessonForWeek(index + 1)), lessonSequence);
    expect(lessonForWeek(6), 'modeling_dasar');
  });

  test('usulan terapis yang diterima menggantikan urutan bawaan; id misi memuat katanya', () {
    final now = DateTime(2026, 9, 18, 10);
    final bawaan = planMission(week: 2, routine: 'makan', targets: const [], now: now);
    expect(bawaan.source, MissionSource.bawaan);
    expect(bawaan.word, 'lagi');
    expect(bawaan.missionId, 'misi-w2-lagi');

    const later = VocabTarget(targetId: 't2', words: ['bantu'], note: null, weekIndex: 5, status: 'diterima', receivedAt: '2026-09-18');
    const accepted = VocabTarget(
      targetId: 't1',
      words: ['berhenti'],
      note: null,
      weekIndex: null,
      status: 'diterima',
      receivedAt: '2026-09-17',
    );
    const pending = VocabTarget(targetId: 't0', words: ['ya'], note: null, weekIndex: null, status: 'usulan', receivedAt: '2026-09-18');
    final plan = planMission(week: 2, routine: 'makan', targets: const [later, accepted, pending], now: now);
    expect(plan.source, MissionSource.terapis);
    expect(plan.word, 'berhenti', reason: 'usulan pekan 5 belum berlaku, usulan yang belum dijawab diabaikan');
    expect(plan.missionId, 'misi-w2-berhenti');
  });

  test('label rutinitas tanpa jam', () {
    expect(routineDisplayLabel('makan'), 'waktu makan');
    expect(routineDisplayLabel('mandi'), 'waktu mandi');
    expect(routineDisplayLabel('main'), 'waktu main');
  });
}
