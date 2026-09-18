import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
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
    final bars = weeklyUniqueBars(data.events, now, weeks: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Kata berbeda',
                value: CountUp(
                  value: stats.uniqueWords,
                  style: _tileNumber.copyWith(color: CompanionColors.tealText),
                ),
                note: prev == null ? 'sejak awal' : 'vs ${prev.uniqueWords} ${_range == _Range.week ? 'pekan lalu' : 'sebelumnya'}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Ketukan spontan',
                value: share == null
                    ? Text('–', style: _tileNumber.copyWith(color: CompanionColors.lavenderDeep))
                    : CountUp(
                        value: (share * 100).round(),
                        suffix: '%',
                        style: _tileNumber.copyWith(color: CompanionColors.lavenderDeep),
                      ),
                note: 'tanpa contoh 60 dtk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Hari misi selesai',
                value: Text('$done/$dayCount', style: _tileNumber.copyWith(color: CompanionColors.leafText)),
                note: _range.label.toLowerCase(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricTile(
                label: 'Ketukan $name',
                value: CountUp(value: stats.childTaps, style: _tileNumber),
                note: _range.label.toLowerCase(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'Kata berbeda per pekan',
          child: LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final w = (box.maxWidth - gap * (bars.length - 1)) / bars.length;
              return WeekBars(values: bars, height: 84, barWidth: w.clamp(8, 48), gap: gap);
            },
          ),
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'Kata yang paling sering',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats.topWords.isEmpty)
                Text('$name belum menekan papan dalam rentang ini.', style: companionMutedStyle)
              else
                for (final w in stats.topWords) _TopWordRow(word: w, max: stats.topWords.first.count, state: widget.state),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StatCard(
          eyebrow: 'Spontan atau dipancing',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SplitBar(share: share ?? 0),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 16,
                children: [
                  _Legend(filled: true, text: 'spontan'),
                  _Legend(filled: false, text: 'setelah dipancing'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _contextLabel(String? context) {
    if (context == null) return '';
    if (context.startsWith('misi-')) return ' · misi';
    return Routine.all.contains(context) ? ' · ${routineDisplayLabel(context)}' : '';
  }

  Widget _todayCard(List<JournalItem> items, String name) {
    return _StatCard(
      eyebrow: 'Hari ini',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            const Text('Belum ada ketukan papan hari ini.', style: companionMutedStyle)
          else
            for (final item in items) ...[
              Text(
                '${item.at.hour.toString().padLeft(2, '0')}.${item.at.minute.toString().padLeft(2, '0')}'
                '${_contextLabel(item.context)} · ${item.actor == Actor.anak ? name : 'contoh Ibu/Ayah'}'
                '${item.spoken ? '' : ' · tanpa UCAPKAN'}',
                style: AppText.cap,
              ),
              const SizedBox(height: 2),
              Text('"${item.words.map(widget.state.wordLabel).join(' ')}"', style: AppText.bodyStrong),
              const SizedBox(height: 10),
            ],
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  children: [
                    _RangeSwitch(value: _range, onChanged: (r) => setState(() => _range = r)),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: Motion.of(context, Motion.fade),
                      child: KeyedSubtree(key: ValueKey(_range), child: _rangeCards(snap.data!, name)),
                    ),
                    const SizedBox(height: 12),
                    _todayCard(snap.data!.today, name),
                    const SizedBox(height: 20),
                    const Eyebrow('Kata baru per pekan'),
                    const SizedBox(height: 8),
                    for (final week in snap.data!.weeks) ...[
                      CompanionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('Pekan ${week.week}', style: AppText.h3)),
                                Text('${week.uniqueWords} kata', style: AppText.bodyStrong.copyWith(color: CompanionColors.tealText)),
                              ],
                            ),
                            if (week.newWords.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [for (final w in week.newWords) _WordChip(word: w, state: widget.state)],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 6),
                    const Text('Angka ini pola pemakaian, bukan ukuran kemampuan anak.', textAlign: TextAlign.center, style: AppText.cap),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Pilihan rentang: tiga pil dalam satu rel; penanda putih bergeser ke pilihan (240 ms).
class _RangeSwitch extends StatelessWidget {
  const _RangeSwitch({required this.value, required this.onChanged});

  final _Range value;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = _Range.values;
    final index = values.indexOf(value);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: CompanionColors.sand, borderRadius: BorderRadius.circular(99)),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: Motion.of(context, Motion.resize),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * index / (values.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: const [BoxShadow(color: Color(0x1A038075), blurRadius: 6, offset: Offset(0, 2))],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final r in values)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: r == value,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(r),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.of(context, Motion.fade),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: r == value ? CompanionColors.tealText : CompanionColors.muted,
                          ),
                          child: Text(r.label),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.note});

  final String label;
  final Widget value;
  final String note;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cap),
        const SizedBox(height: 2),
        value,
        Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.cap),
      ],
    ),
  );
}

const _tileNumber = TextStyle(fontFamily: 'Fredoka', fontSize: 30, height: 1.15, fontWeight: FontWeight.w600, color: CompanionColors.ink);

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.state});

  final String word;
  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final symbol = state.app.symbolById(word);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: CompanionColors.tealTint, borderRadius: BorderRadius.circular(99)),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.eyebrow, required this.child});

  final String eyebrow;
  final Widget child;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Eyebrow(eyebrow), const SizedBox(height: 12), child]),
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
                child: LinearProgressIndicator(value: v, minHeight: 12, color: CompanionColors.teal, backgroundColor: CompanionColors.sand),
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
      child: LinearProgressIndicator(
        value: v,
        minHeight: 16,
        color: CompanionColors.lavender,
        backgroundColor: CompanionColors.lavenderTint,
      ),
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
          color: filled ? CompanionColors.lavender : CompanionColors.lavenderTint,
          borderRadius: BorderRadius.circular(3),
          border: filled ? null : Border.all(color: CompanionColors.lavenderDeep, width: 1.5),
        ),
      ),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ],
  );
}
