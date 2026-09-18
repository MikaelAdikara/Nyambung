import 'package:flutter/material.dart';

import '../coach/companion_widgets.dart';
import '../coach/companion_controller.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final name = state.child?.nickname ?? 'anak';
    return CompanionPage(
      title: 'Perkembangan',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pekan ${state.currentWeek}: ${state.weeklyWords.length} kata berbeda dari $name',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (state.weeklyWords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Kata baru: ${state.weeklyWords.map((word) => word.toUpperCase()).join(', ')}', style: companionBodyStyle),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Ini catatan pemakaian, bukan penilaian kemampuan.', style: companionMutedStyle),
        ],
      ),
    );
  }
}
