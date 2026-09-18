import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/motion.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$now', style: const TextStyle(fontSize: 56, height: 1, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('kata berbeda dipakai $name', style: companionBodyStyle),
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
                    if (diff > 0) _Pill(icon: Icons.arrow_upward, text: 'naik $diff'),
                    Text(diff == 0 && prev > 0 ? 'sama dengan pekan lalu' : 'pekan lalu $prev kata', style: companionMutedStyle),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CompanionColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hari dengan misi modeling selesai', style: companionMutedStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < dots.length; i++) ...[Expanded(child: _MissionDot(done: dots[i])), const SizedBox(width: 6)],
                    const SizedBox(width: 4),
                    Text('$done dari ${dots.length}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Hari kosong tidak menghapus apa pun.', style: companionMutedStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Batang kecil kata berbeda per pekan. Pekan ini paling gelap. Batang tumbuh sekali saat pertama tampil
/// (320 ms), seketika bila animasi Android dimatikan.
class WeekBars extends StatelessWidget {
  const WeekBars({super.key, required this.values, this.height = 72, this.barWidth = 14});

  final List<int> values;
  final double height;
  final double barWidth;

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
                if (i > 0) const SizedBox(width: 5),
                Container(
                  width: barWidth,
                  height: 6 + (max == 0 ? 0 : (height - 6) * values[i] / max) * t,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFFDCE6F1),
                      CompanionColors.navy,
                      i >= values.length - 2 ? 1 : 0.15 + 0.5 * i / values.length,
                    ),
                    borderRadius: BorderRadius.circular(4),
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
    decoration: BoxDecoration(
      color: const Color(0xFFDDE8DD),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFFA9C4A9)),
    ),
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
    child: Container(
      decoration: BoxDecoration(
        color: done == true ? CompanionColors.navy : CompanionColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: done == true ? CompanionColors.navy : CompanionColors.line, width: 1.5),
      ),
    ),
  );
}

/// B1 "Buka Papan Bicara": empat kata kecil yang sering dipakai keluarga ini, ketuk kartu untuk membuka papan anak.
class BoardPreviewCard extends StatelessWidget {
  const BoardPreviewCard({super.key, required this.state, required this.onOpen});

  final CompanionController state;
  final VoidCallback onOpen;

  List<WordSymbol> _words(AppState app) {
    final ids = <String>{state.mission.targetWord, ...state.weeklyWords, 'mau', 'makan', 'minum', 'lagi'};
    return [
      for (final id in ids)
        if (app.symbolById(id) case final s? when !s.isHidden) s,
    ].take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final words = _words(AppScope.of(context));
    return PressScale(
      child: Material(
        color: CompanionColors.panel,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CompanionColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Buka Papan Bicara', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Mode anak, terkunci sampai kamu buka', style: companionMutedStyle),
                        ],
                      ),
                    ),
                    Container(
                      width: 52,
                      height: 44,
                      decoration: BoxDecoration(color: CompanionColors.navy, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, box) {
                    const gap = 8.0;
                    final w = (box.maxWidth - gap * 3) / 4;
                    return Row(
                      children: [
                        for (var i = 0; i < words.length; i++) ...[
                          if (i > 0) const SizedBox(width: gap),
                          SymbolFace(symbol: words[i], width: w, height: w * 0.95, compact: true),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
