import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../coach/companion_controller.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import 'today_journal.dart';

/// Satu pekan riwayat: kata berbeda yang ditekan anak dan kata yang baru pertama kali muncul.
class WeekHistory {
  const WeekHistory(this.week, this.uniqueWords, this.newWords);

  final int week;
  final int uniqueWords;
  final List<String> newWords;
}

/// C1: 6 pekan terakhir, terbaru di atas. Pekan dihitung dari hari pemasangan (sama dengan pekan misi).
List<WeekHistory> buildHistory(List<UtteranceEvent> events, DateTime childCreatedAt, int currentWeek) {
  final byWeek = <int, Set<String>>{};
  final firstSeen = <String, int>{};
  final taps = events.where((e) => e.actor == Actor.anak && Method.taps.contains(e.method)).toList()
    ..sort((a, b) => a.tsDevice.compareTo(b.tsDevice));
  for (final e in taps) {
    final at = DateTime.tryParse(e.tsDevice)?.toLocal();
    if (at == null) continue;
    final week = missionWeek(childCreatedAt, at);
    byWeek.putIfAbsent(week, () => <String>{}).add(e.content);
    firstSeen.putIfAbsent(e.content, () => week);
  }
  final first = currentWeek - 5 < 1 ? 1 : currentWeek - 5;
  return [
    for (var w = currentWeek; w >= first; w--)
      WeekHistory(
        w,
        byWeek[w]?.length ?? 0,
        [
          for (final word in byWeek[w] ?? const <String>{})
            if (firstSeen[word] == w) word,
        ]..sort(),
      ),
  ];
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.state});

  final CompanionController state;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressData {
  const _ProgressData(this.today, this.weeks);

  final List<JournalItem> today;
  final List<WeekHistory> weeks;
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final Future<_ProgressData> _history = _load();

  Future<_ProgressData> _load() async {
    final app = widget.state.app;
    final child = app.child;
    if (child == null) return const _ProgressData([], []);
    final events = (await app.eventDao.all()).where((e) => e.childId == child.childId).toList();
    final today = localDate(DateTime.now());
    return _ProgressData(
      buildTodayJournal(events.where((e) => e.tsDevice.startsWith(today)).toList()),
      buildHistory(events, DateTime.parse(child.createdAt).toLocal(), widget.state.currentWeek),
    );
  }

  String _contextLabel(String? context) {
    if (context == null) return '';
    if (context.startsWith('misi-')) return ' · misi';
    return Routine.all.contains(context) ? ' · ${routineDisplayLabel(context)}' : '';
  }

  Widget _todayCard(List<JournalItem> items, String name) {
    return CompanionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hari ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Belum ada ketukan papan hari ini.', style: companionMutedStyle)
          else
            for (final item in items) ...[
              Text(
                '${item.at.hour.toString().padLeft(2, '0')}.${item.at.minute.toString().padLeft(2, '0')}'
                '${_contextLabel(item.context)} · ${item.actor == Actor.anak ? name : 'contoh Ibu/Ayah'}'
                '${item.spoken ? '' : ' · ditekan tanpa UCAPKAN'}',
                style: companionMutedStyle,
              ),
              Text(
                '"${item.words.map(widget.state.wordLabel).join(' ')}"',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
            ],
          const Text('Tersusun sendiri dari ketukan papan. Tidak ada yang perlu diisi.', style: companionMutedStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.state.child?.nickname ?? 'anak';
    return CompanionPage(
      title: 'Perkembangan',
      body: FutureBuilder<_ProgressData>(
        future: _history,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _todayCard(snap.data!.today, name),
              const SizedBox(height: 12),
              for (final week in snap.data!.weeks) ...[
                CompanionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pekan ${week.week}: ${week.uniqueWords} kata berbeda dari $name',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      if (week.newWords.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [for (final w in week.newWords) _WordChip(word: w, state: widget.state)],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text('Ini catatan pemakaian, bukan penilaian kemampuan.', style: companionMutedStyle),
            ],
          );
        },
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.state});

  final String word;
  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final symbol = state.app.symbolById(word);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CompanionColors.sand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CompanionColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (symbol != null)
            Image.asset(symbol.symbolPath, width: 28, height: 28, cacheWidth: 84, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(width: 6),
          Text(symbol?.labelDisplay ?? word.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
