import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'companion_controller.dart';
import 'companion_widgets.dart';
import 'lessons.dart';
import 'mission_screen.dart';
import 'visual_steps.dart';

/// Pelajaran 60 detik: tiga langkah bergambar dulu, lalu contoh dan alasan singkat dengan sumbernya.
class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.state, required this.lessonKey});

  final CompanionController state;
  final String lessonKey;

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[lessonKey] ?? lessons.values.first;
    return CompanionPage(
      title: 'Pelajaran 60 detik',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              children: [
                FadeSlideIn(index: 0, child: Text(lesson.title, style: AppText.h1)),
                const SizedBox(height: 16),
                FadeSlideIn(index: 1, child: VisualSteps(steps: lesson.steps)),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
                  child: _LessonBlock(
                    icon: Icons.menu_book_rounded,
                    label: 'Caranya',
                    text: lesson.how,
                    color: CompanionColors.tealTint,
                    border: CompanionColors.mint,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: _LessonBlock(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Contoh',
                    text: lesson.example,
                    color: CompanionColors.sunTint,
                    border: CompanionColors.sunTint,
                    accent: CompanionColors.sunText,
                  ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 4,
                  child: _LessonBlock(icon: Icons.science_outlined, label: 'Kenapa', text: lesson.why, source: lesson.source),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: PrimaryButton(
              label: 'Mengerti, mulai misi',
              icon: Icons.play_arrow_rounded,
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: state))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({
    required this.icon,
    required this.label,
    required this.text,
    this.color = CompanionColors.panel,
    this.border = CompanionColors.line,
    this.accent = CompanionColors.tealText,
    this.source,
  });

  final IconData icon;
  final String label;
  final String text;
  final Color color;
  final Color border;
  final Color accent;
  final String? source;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: color,
    borderColor: border,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: 8),
            Text(label, style: AppText.bodyStrong.copyWith(color: accent)),
          ],
        ),
        const SizedBox(height: 8),
        Text(text, style: companionBodyStyle),
        if (source != null) ...[const SizedBox(height: 10), Text('Dasar: $source', style: AppText.cap)],
      ],
    ),
  );
}
