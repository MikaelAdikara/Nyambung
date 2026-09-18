import 'package:flutter/material.dart';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(lesson.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          _LessonBlock(label: 'Caranya', text: lesson.how),
          const SizedBox(height: 12),
          _LessonBlock(label: 'Contoh', text: lesson.example),
          const SizedBox(height: 12),
          _LessonBlock(label: 'Kenapa', text: lesson.why),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Mengerti, mulai misi',
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: state))),
          ),
        ],
      ),
    );
  }
}

class _LessonBlock extends StatelessWidget {
  const _LessonBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CompanionColors.navy),
        ),
        const SizedBox(height: 8),
        Text(text, style: companionBodyStyle),
      ],
    ),
  );
}
