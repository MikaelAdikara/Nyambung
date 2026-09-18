import '../../core/constants.dart';
import '../../data/models.dart';

/// Satu baris "Hari ini" di C1: ujaran yang diucapkan (UCAPKAN) atau, bila dalam satu sesi papan tidak ada
/// UCAPKAN, deretan kata yang ditekan. Format ulang deterministik dari log peristiwa; tidak ada isian dan
/// tidak ada penilaian.
class JournalItem {
  const JournalItem({required this.at, required this.words, required this.actor, required this.context, required this.spoken});

  final DateTime at;
  final List<String> words;

  /// `anak` atau `pendamping`.
  final String actor;
  final String? context;

  /// true = lewat UCAPKAN; false = deretan ketukan tanpa UCAPKAN.
  final bool spoken;
}

/// Susun maksimal [limit] baris terbaru dari peristiwa satu hari. MIS/TGT/HAP tidak pernah tampil sebagai ujaran.
List<JournalItem> buildTodayJournal(List<UtteranceEvent> events, {int limit = 10, int maxWords = 8}) {
  final sorted = [...events]..sort((a, b) => a.tsDevice.compareTo(b.tsDevice));
  final sessions = <String, List<UtteranceEvent>>{};
  for (final e in sorted) {
    sessions.putIfAbsent(e.sessionId, () => []).add(e);
  }
  final items = <JournalItem>[];
  for (final list in sessions.values) {
    final spoken = list.where((e) => e.method == Method.ucp && e.content.trim().isNotEmpty).toList();
    if (spoken.isNotEmpty) {
      for (final e in spoken) {
        final at = DateTime.tryParse(e.tsDevice)?.toLocal();
        if (at == null) continue;
        items.add(JournalItem(at: at, words: e.content.trim().split(RegExp(r'\s+')), actor: e.actor, context: e.context, spoken: true));
      }
      continue;
    }
    for (final actor in const [Actor.anak, Actor.pendamping]) {
      final taps = list.where((e) => e.actor == actor && Method.taps.contains(e.method)).toList();
      if (taps.isEmpty) continue;
      final at = DateTime.tryParse(taps.last.tsDevice)?.toLocal();
      if (at == null) continue;
      final words = taps.map((e) => e.content).toList();
      items.add(
        JournalItem(
          at: at,
          words: words.length > maxWords ? words.sublist(words.length - maxWords) : words,
          actor: actor,
          context: taps.last.context,
          spoken: false,
        ),
      );
    }
  }
  items.sort((a, b) => b.at.compareTo(a.at));
  return items.length > limit ? items.sublist(0, limit) : items;
}
