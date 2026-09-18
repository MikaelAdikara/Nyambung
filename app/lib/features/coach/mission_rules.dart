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

const _bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

/// `2026-09-18T03:20:38Z` → `18 September 2026` (waktu lokal perangkat).
String formatTanggal(String iso) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return iso;
  return '${t.day} ${_bulan[t.month - 1]} ${t.year}';
}

/// Jadwal lokal tanpa zona dari terapis: `2026-09-23T15:30` → `23 September, 15.30`; `2026-09-23` → `23 September 2026`.
String formatJadwal(String local) {
  final t = DateTime.tryParse(local);
  if (t == null) return local;
  if (!local.contains('T')) return '${t.day} ${_bulan[t.month - 1]} ${t.year}';
  return '${t.day} ${_bulan[t.month - 1]}, ${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
}

/// Waktu singkat untuk kartu catatan: `hari ini 10.20`, `kemarin 18.05`, atau `16 September 18.05`.
String formatWaktuSingkat(String iso, {DateTime? now}) {
  final t = DateTime.tryParse(iso)?.toLocal();
  if (t == null) return iso;
  final n = now ?? DateTime.now();
  final jam = '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'hari ini $jam';
  if (diff == 1) return 'kemarin $jam';
  return '${t.day} ${_bulan[t.month - 1]} $jam';
}
