import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_controller.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import '../coach/home_cards.dart';
import 'today_journal.dart';
import 'usage_stats.dart';

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
  const _ProgressData(this.today, this.weeks, this.events, this.logs, this.since);

  final List<JournalItem> today;
  final List<WeekHistory> weeks;
  final List<UtteranceEvent> events;
  final List<MissionLog> logs;

  /// Hari pemasangan (awal rentang "Semua").
  final DateTime since;
}

/// Rentang C1.
enum _Range {
  week('Pekan ini', 7),
  month('Sebulan', 30),
  all('Semua', null);

  const _Range(this.label, this.days);

  final String label;
  final int? days;
}

class _ProgressScreenState extends State<ProgressScreen> {
  late final Future<_ProgressData> _history = _load();

  Future<_ProgressData> _load() async {
    final app = widget.state.app;
    final child = app.child;
    final created = DateTime.parse(child?.createdAt ?? DateTime.now().toIso8601String()).toLocal();
    if (child == null) return _ProgressData(const [], const [], const [], const [], created);
    final events = (await app.eventDao.all()).where((e) => e.childId == child.childId).toList();
    final today = localDate(DateTime.now());
    return _ProgressData(
      buildTodayJournal(events.where((e) => e.tsDevice.startsWith(today)).toList()),
      buildHistory(events, created, widget.state.currentWeek),
      events,
      await app.missionDao.logs(),
      created,
    );
  }

  _Range _range = _Range.week;

  Widget _rangeCards(_ProgressData data, String name) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final days = _range.days;
    final from = days == null ? null : end.subtract(Duration(days: days));
    final stats = usageBetween(data.events, from: from, to: end);
    final prev = from == null
        ? null
        : usageBetween(
            data.events,
            from: from.subtract(Duration(days: days!)),
            to: from,
          );
    final (done, dayCount) = missionDoneSince(data.logs, from == null || from.isBefore(data.since) ? data.since : from, now);
    final share = stats.spontaneousShare;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatCard(
          eyebrow: 'KATA BERBEDA YANG DIPAKAI ${name.toUpperCase()}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: Text('${stats.uniqueWords}', style: _bigNumber)),
                  WeekBars(values: weeklyUniqueBars(data.events, now, weeks: 6)),
                ],
              ),
              if (prev != null) ...[
                const SizedBox(height: 8),
                Text(
                  _compare(stats.uniqueWords, prev.uniqueWords, _range == _Range.week ? 'pekan lalu' : 'sebulan sebelumnya'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Jumlah kata berbeda yang $name tekan sendiri. Angka naik atau turun itu wajar; yang dilihat terapis adalah '
                'arah dalam beberapa pekan.',
                style: companionMutedStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'KATA YANG PALING SERING DIPAKAI',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats.topWords.isEmpty)
                Text('$name belum menekan papan dalam rentang ini.', style: companionMutedStyle)
              else
                for (final w in stats.topWords) _TopWordRow(word: w, max: stats.topWords.first.count, state: widget.state),
              const SizedBox(height: 8),
              Text(
                'Kata yang paling sering dipakai biasanya kata yang paling berguna untuk $name sekarang. Bukan berarti kata '
                'lain gagal.',
                style: companionMutedStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'UJARAN SPONTAN',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(share == null ? '–' : '${(share * 100).round()}%', style: _bigNumber),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('tanpa dipancing', style: companionBodyStyle),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _SplitBar(share: share ?? 0),
              const SizedBox(height: 8),
              const Wrap(
                spacing: 16,
                children: [
                  _Legend(filled: true, text: 'spontan'),
                  _Legend(filled: false, text: 'setelah dipancing'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Spontan berarti $name menekan simbol tanpa contoh dari Ibu atau Ayah semenit sebelumnya. Keduanya sama '
                'pentingnya; dipancing bukan hal buruk.',
                style: companionMutedStyle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'HARI DENGAN MISI MODELING SELESAI',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$done dari $dayCount', style: _bigNumber),
              const SizedBox(height: 8),
              const Text('Ini catatan, bukan nilai. Hari yang terlewat tidak menghapus apa pun.', style: companionMutedStyle),
            ],
          ),
        ),
      ],
    );
  }

  static String _compare(int now, int before, String label) {
    if (now > before) return 'Naik ${now - before} dari $label ($before kata)';
    if (now < before) return '$label: $before kata';
    return 'Sama dengan $label';
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
        builder: (context, snap) => AnimatedSwitcher(
          duration: Motion.of(context, Motion.fade),
          child: !snap.hasData
              ? const Center(key: ValueKey('memuat'), child: CircularProgressIndicator())
              : ListView(
                  key: const ValueKey('isi'),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final r in _Range.values)
                          ChoiceChip(label: Text(r.label), selected: r == _range, onSelected: (_) => setState(() => _range = r)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.fade),
                      child: KeyedSubtree(key: ValueKey(_range), child: _rangeCards(snap.data!, name)),
                    ),
                    const SizedBox(height: 12),
                    _todayCard(snap.data!.today, name),
                    const SizedBox(height: 20),
                    const Text(
                      'KATA BARU PER PEKAN',
                      style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: CompanionColors.muted),
                    ),
                    const SizedBox(height: 8),
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
                ),
        ),
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
            Image(image: symbolImage(symbol.symbolPath), width: 28, height: 28, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          const SizedBox(width: 6),
          Text(symbol?.labelDisplay ?? word.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

const _bigNumber = TextStyle(fontSize: 52, height: 1, fontWeight: FontWeight.w800);

class _StatCard extends StatelessWidget {
  const _StatCard({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: CompanionColors.muted),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _TopWordRow extends StatelessWidget {
  const _TopWordRow({required this.word, required this.max, required this.state});

  final WordCount word;
  final int max;
  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final symbol = state.app.symbolById(word.word);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: symbol == null ? null : Image(image: symbolImage(symbol.symbolPath), errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              state.wordLabel(word.word),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: max == 0 ? 0 : word.count / max),
              duration: Motion.of(context, Motion.enter),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: v, minHeight: 14, color: CompanionColors.navy, backgroundColor: CompanionColors.sand),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${word.count}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: share),
    duration: Motion.of(context, Motion.enter),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(value: v, minHeight: 16, color: CompanionColors.navy, backgroundColor: const Color(0xFFDCE6F1)),
    ),
  );
}

/// Legenda dengan bentuk berbeda (kotak penuh vs kotak garis), bukan hanya warna (invarian 10).
class _Legend extends StatelessWidget {
  const _Legend({required this.filled, required this.text});

  final bool filled;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: filled ? CompanionColors.navy : const Color(0xFFDCE6F1),
          borderRadius: BorderRadius.circular(3),
          border: filled ? null : Border.all(color: CompanionColors.navy, width: 1.5),
        ),
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ],
  );
}
