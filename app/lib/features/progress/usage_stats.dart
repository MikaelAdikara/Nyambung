/// Hitungan pemakaian untuk B1 (beranda) dan C1 (perkembangan). Fungsi murni atas log peristiwa, jadi bisa dites
/// tanpa sqflite. Angka ini tampilan lokal saja: yang dikirim ke server tetap peristiwa mentah (invarian 6).
///
/// Semua hitungan memakai ketukan **anak** (`SEL`/`KAT`/`PRS`), sama dengan ringkasan server (kontrak §5).
library;

import '../../core/constants.dart';
import '../../core/time.dart';
import '../../data/models.dart';

class WordCount {
  const WordCount(this.word, this.count);

  final String word;
  final int count;
}

class UsageStats {
  const UsageStats({required this.childTaps, required this.uniqueWords, required this.topWords, required this.spontaneous});

  /// Ketukan simbol oleh anak.
  final int childTaps;

  /// Kata berbeda yang ditekan anak.
  final int uniqueWords;

  /// Kata paling sering, terbanyak dulu (seri diurutkan menurut `word_id`).
  final List<WordCount> topWords;

  /// Ketukan anak yang `spontan` (tanpa contoh pendamping ≤ 60 detik sebelumnya).
  final int spontaneous;

  /// Bagian spontan 0..1, atau null bila anak belum menekan apa pun.
  double? get spontaneousShare => childTaps == 0 ? null : spontaneous / childTaps;

  static const empty = UsageStats(childTaps: 0, uniqueWords: 0, topWords: [], spontaneous: 0);
}

bool _childTap(UtteranceEvent e) => e.actor == Actor.anak && Method.taps.contains(e.method);

DateTime? _at(UtteranceEvent e) => DateTime.tryParse(e.tsDevice)?.toLocal();

/// Hitungan atas peristiwa dengan waktu di `[from, to)`. [from] null = sejak awal.
UsageStats usageBetween(Iterable<UtteranceEvent> events, {DateTime? from, required DateTime to, int top = 3}) {
  final counts = <String, int>{};
  var taps = 0;
  var spontaneous = 0;
  for (final e in events) {
    if (!_childTap(e)) continue;
    final at = _at(e);
    if (at == null || !at.isBefore(to) || (from != null && at.isBefore(from))) continue;
    taps++;
    if (e.promptLevel == PromptLevel.spontan) spontaneous++;
    counts.update(e.content, (c) => c + 1, ifAbsent: () => 1);
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return UsageStats(
    childTaps: taps,
    uniqueWords: counts.length,
    topWords: [for (final e in ranked.take(top)) WordCount(e.key, e.value)],
    spontaneous: spontaneous,
  );
}

/// Kata berbeda per jendela 7 hari, [weeks] jendela berurutan dari yang terlama; jendela terakhir berakhir hari ini.
List<int> weeklyUniqueBars(Iterable<UtteranceEvent> events, DateTime now, {int weeks = 7}) {
  final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  final sets = List.generate(weeks, (_) => <String>{});
  for (final e in events) {
    if (!_childTap(e)) continue;
    final at = _at(e);
    if (at == null || !at.isBefore(end)) continue;
    final back = end.difference(at).inDays ~/ 7;
    if (back < weeks) sets[weeks - 1 - back].add(e.content);
  }
  return [for (final s in sets) s.length];
}

/// Keadaan misi untuk [days] hari terakhir (terlama dulu, hari ini terakhir): `true` selesai, `false` belum sempat,
/// `null` tidak dikonfirmasi. Log misi apa pun pada tanggal itu dihitung (misi berganti tiap pekan).
List<bool?> missionDays(Iterable<MissionLog> logs, DateTime now, {int days = 7}) {
  final byDate = <String, bool>{};
  for (final l in logs) {
    final done = l.status == MissionStatus.selesai;
    byDate[l.date] = (byDate[l.date] ?? false) || done;
  }
  final today = DateTime(now.year, now.month, now.day);
  return [for (var i = days - 1; i >= 0; i--) byDate[localDate(today.subtract(Duration(days: i)))]];
}

/// Jumlah hari berstatus selesai sejak [from] (inklusif, tanggal lokal `YYYY-MM-DD`), dan jumlah hari dalam rentang.
(int done, int days) missionDoneSince(Iterable<MissionLog> logs, DateTime from, DateTime now) {
  final start = DateTime(from.year, from.month, from.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = today.difference(start).inDays + 1;
  final first = localDate(start);
  final done = {
    for (final l in logs)
      if (l.status == MissionStatus.selesai && l.date.compareTo(first) >= 0) l.date,
  }.length;
  return (done, days < 1 ? 1 : days);
}
