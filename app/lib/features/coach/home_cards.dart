import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'companion_controller.dart';
import 'companion_widgets.dart';

/// B1 "Sepekan ini": kata berbeda pekan ini, batang 7 pekan, perbandingan netral dengan pekan lalu, dan titik
/// misi 7 hari. Semua lahir dari ketukan papan dan konfirmasi misi, bukan dari isian.
class WeekCard extends StatelessWidget {
  const WeekCard({super.key, required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final name = state.child?.nickname ?? 'anak';
    final now = state.uniqueThisWeek;
    final prev = state.uniquePrevWeek;
    final diff = now - prev;
    final dots = state.missionDots;
    final done = dots.where((d) => d == true).length;
    return CompanionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Sepekan ini'),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CountUp(
                            value: now,
                            style: AppText.number.copyWith(color: CompanionColors.tealText),
                          ),
                          const SizedBox(height: 4),
                          Text('kata berbeda dipakai $name', style: AppText.muted),
                        ],
                      ),
                    ),
                    WeekBars(values: state.weekBars),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (diff > 0) _Pill(icon: Icons.arrow_upward_rounded, text: 'naik $diff'),
                    Text(diff == 0 && prev > 0 ? 'sama dengan pekan lalu' : 'pekan lalu $prev kata', style: AppText.muted),
                  ],
                ),
                const SizedBox(height: 10),
                Text(state.weeklySummary, style: AppText.body.copyWith(fontSize: 15)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hari dengan misi selesai', style: AppText.muted),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < dots.length; i++) ...[Expanded(child: _MissionDot(done: dots[i])), const SizedBox(width: 6)],
                    const SizedBox(width: 4),
                    Text('$done dari ${dots.length}', style: AppText.h3),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Angka yang naik dari 0 ke [value] sekali saat pertama tampil (600 ms), lalu mengikuti perubahan nilai.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.suffix = ''});

  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: Motion.of(context, const Duration(milliseconds: 600)),
    curve: Curves.easeOutCubic,
    builder: (context, v, _) => Text('${v.round()}$suffix', style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
  );
}

/// Batang kecil kata berbeda per pekan. Pekan ini toska, pekan lain netral. Batang tumbuh sekali saat pertama tampil
/// (320 ms), seketika bila animasi Android dimatikan.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.values, this.height = 72, this.barWidth = 14, this.gap = 5});

  final List<int> values;
  final double height;
  final double barWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final max = values.fold<int>(0, (m, v) => v > m ? v : m);
    return Semantics(
      label: 'Kata berbeda per pekan: ${values.join(', ')}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.of(context, Motion.enter),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Container(
                  width: barWidth,
                  height: 6 + (max == 0 ? 0 : (height - 6) * values[i] / max) * t,
                  decoration: BoxDecoration(
                    color: i == values.length - 1 ? CompanionColors.teal : CompanionColors.sandDeep,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5), bottom: Radius.circular(2)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: CompanionColors.leafTint, borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CompanionColors.green),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w800, color: CompanionColors.green),
        ),
      ],
    ),
  );
}

/// Satu hari: terisi = selesai, garis = belum sempat atau tidak dikonfirmasi. Bentuk berbeda (isi vs garis) supaya
/// warna bukan satu-satunya pembawa makna (invarian 10).
class _MissionDot extends StatelessWidget {
  const _MissionDot({required this.done});

  final bool? done;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: AnimatedContainer(
      duration: Motion.of(context, Motion.resize),
      decoration: BoxDecoration(
        color: done == true ? CompanionColors.teal : CompanionColors.bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: done == true ? CompanionColors.teal : CompanionColors.sandDeep, width: 2),
      ),
      child: done == true ? const FittedBox(child: Icon(Icons.check_rounded, color: Colors.white)) : null,
    ),
  );
}
