import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'companion_widgets.dart';
import 'companion_controller.dart';
import 'lessons.dart';
import 'mission_screen.dart';

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
                FadeSlideIn(
                  index: 1,
                  child: _LessonBlock(label: 'Caranya', text: lesson.how, color: CompanionColors.tealTint, border: CompanionColors.mint),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 2,
                  child: _LessonBlock(label: 'Contoh', text: lesson.example),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  index: 3,
                  child: _LessonBlock(label: 'Kenapa', text: lesson.why),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: PrimaryButton(
              label: 'Mengerti, mulai misi',
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: state))),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.label, required this.text, this.color = CompanionColors.panel, this.border = CompanionColors.line});

  final String label;
  final String text;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: color,
    borderColor: border,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label, color: CompanionColors.tealText),
        const SizedBox(height: 8),
        Text(text, style: companionBodyStyle),
      ],
    ),
  );
}
