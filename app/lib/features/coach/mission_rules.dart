const defaultMissionWords = ['mau', 'lagi', 'tidak', 'berhenti', 'bantu', 'selesai', 'minum', 'makan'];
const lessonSequence = ['modeling_dasar', 'tunggu_lima_detik', 'tanpa_paksa', 'kata_inti_dulu', 'ulang_lima_kali'];

int missionWeek(DateTime childCreatedAt, DateTime now) {
  final created = DateTime(childCreatedAt.year, childCreatedAt.month, childCreatedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final elapsedDays = today.difference(created).inDays.clamp(0, 1 << 31);
  return elapsedDays ~/ 7 + 1;
}

String defaultTargetForWeek(int week) => defaultMissionWords[(week - 1).clamp(0, 1 << 31) % defaultMissionWords.length];

String lessonForWeek(int week) => lessonSequence[(week - 1).clamp(0, 1 << 31) % lessonSequence.length];

String missionIdForWeek(int week) => 'misi-w$week';

String routineDisplayLabel(String routine) => switch (routine) {
  'mandi' => 'mandi sore',
  'main' => 'main pagi',
  _ => 'makan sore',
};
