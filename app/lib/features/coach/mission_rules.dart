import '../../core/constants.dart';
import '../../data/models.dart';

/// Generator misi harian. Aturannya tetap dan bisa dilacak terapis (dasbor D2 "Misi harian"):
///
/// 1. **Pekan** = pekan ke-N sejak anak didaftarkan (7 hari pertama = pekan 1).
/// 2. **Kata**: bila keluarga menerima usulan terapis (yang `week_index`-nya kosong atau sudah tiba), kata misi
///    diambil dari usulan terbaru itu dan bergilir per hari bila isinya lebih dari satu kata. Usulan berlaku sampai
///    terapis mengirim usulan baru.
/// 3. Tanpa usulan, kata diambil dari **urutan bawaan per rutinitas**: hanya 12 kata inti halaman depan (03 §3,
///    Banajee 2003 / Project Core), dimulai dari fungsi meminta (MAU, LAGI; meminta adalah fungsi pertama AAC
///    bergambar, Bondy & Frost 1994), lalu menolak/berhenti, menutup, dan minta tolong. Satu kata per pekan.
///    Urutan per rutinitas dipilih supaya kata itu punya giliran alami di kegiatan tersebut (asumsi tim, tingkat D).
/// 4. **Dosis**: 5 contoh sehari pada satu rutinitas (03 §5, asumsi tim tingkat D, bukan dosis efektif).
/// 5. `mission_id` = `misi-w{pekan}-{kata}`, jadi server dan dasbor tahu kata misi dari peristiwa mentah saja.
const routineMissionWords = <String, List<String>>{
  'makan': ['mau', 'lagi', 'selesai', 'tidak', 'bantu', 'minum', 'berhenti', 'makan'],
  'mandi': ['lagi', 'berhenti', 'selesai', 'mau', 'bantu', 'tidak', 'sakit', 'aku'],
  'main': ['mau', 'lagi', 'bantu', 'berhenti', 'selesai', 'tidak', 'itu', 'aku'],
};

/// Kata-kata yang ditampilkan sebagai contoh giliran alami di pilihan rutinitas (A3).
const routineTurnWords = <String, List<String>>{
  'makan': ['mau', 'lagi', 'selesai'],
  'mandi': ['lagi', 'berhenti', 'selesai'],
  'main': ['mau', 'lagi', 'bantu'],
};

const lessonSequence = ['modeling_dasar', 'tunggu_lima_detik', 'tanpa_paksa', 'kata_inti_dulu', 'ulang_lima_kali'];

enum MissionSource { bawaan, terapis }

/// Rencana misi hari ini beserta alasannya, supaya orang tua dan terapis tahu kenapa kata ini.
class MissionPlan {
  const MissionPlan({required this.week, required this.word, required this.source, this.targetId});

  final int week;
  final String word;
  final MissionSource source;
  final String? targetId;

  String get missionId => 'misi-w$week-$word';
}

MissionPlan planMission({required int week, required String routine, required List<VocabTarget> targets, required DateTime now}) {
  final accepted =
      targets
          .where((t) => t.status == TargetStatus.diterima && t.words.isNotEmpty && (t.weekIndex == null || t.weekIndex! <= week))
          .toList()
        ..sort((a, b) => (b.receivedAt ?? '').compareTo(a.receivedAt ?? ''));
  final target = accepted.firstOrNull;
  if (target != null) {
    final day = DateTime(now.year, now.month, now.day).difference(DateTime(2024)).inDays;
    return MissionPlan(week: week, word: target.words[day % target.words.length], source: MissionSource.terapis, targetId: target.targetId);
  }
  return MissionPlan(
    week: week,
    word: defaultTargetForWeek(week, routine: routine),
    source: MissionSource.bawaan,
  );
}

int missionWeek(DateTime childCreatedAt, DateTime now) {
  final created = DateTime(childCreatedAt.year, childCreatedAt.month, childCreatedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final elapsedDays = today.difference(created).inDays.clamp(0, 1 << 31);
  return elapsedDays ~/ 7 + 1;
}

String defaultTargetForWeek(int week, {String routine = 'makan'}) {
  final words = routineMissionWords[routine] ?? routineMissionWords['makan']!;
  return words[(week - 1).clamp(0, 1 << 31) % words.length];
}

String lessonForWeek(int week) => lessonSequence[(week - 1).clamp(0, 1 << 31) % lessonSequence.length];

/// Nama rutinitas tanpa jam: keluarga memilih kegiatan, bukan waktu. Jam berapa pun kegiatan itu terjadi, misinya sama.
String routineDisplayLabel(String routine) => switch (routine) {
  'mandi' => 'waktu mandi',
  'main' => 'waktu main',
  _ => 'waktu makan',
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
