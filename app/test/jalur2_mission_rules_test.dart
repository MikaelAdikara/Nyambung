import 'package:flutter_test/flutter_test.dart';
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

  test('kata misi bawaan berulang dalam urutan yang dibekukan', () {
    expect(List.generate(8, (index) => defaultTargetForWeek(index + 1)), defaultMissionWords);
    expect(defaultTargetForWeek(9), 'mau');
  });

  test('pelajaran berulang dalam urutan yang dibekukan', () {
    expect(List.generate(5, (index) => lessonForWeek(index + 1)), lessonSequence);
    expect(lessonForWeek(6), 'modeling_dasar');
  });

  test('id misi dan label rutinitas mengikuti kontrak layar', () {
    expect(missionIdForWeek(3), 'misi-w3');
    expect(routineDisplayLabel('makan'), 'makan sore');
    expect(routineDisplayLabel('mandi'), 'mandi sore');
    expect(routineDisplayLabel('main'), 'main pagi');
  });
}
