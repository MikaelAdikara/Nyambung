import 'package:flutter/material.dart';

import '../coach/companion_widgets.dart';
import '../coach/fake_app_state.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, required this.state});

  final FakeAppState state;

  @override
  Widget build(BuildContext context) {
    final name = state.child?.nickname ?? 'anak';
    return CompanionPage(
      title: 'Perkembangan',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final week in const [(3, 7, 'BERHENTI, BANTU'), (2, 5, 'TIDAK'), (1, 4, 'MAU, LAGI')]) ...[
            CompanionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pekan ${week.$1}: ${week.$2} kata berbeda dari $name',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text('Kata baru: ${week.$3}', style: companionBodyStyle),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text('Ini catatan pemakaian, bukan penilaian kemampuan.', style: companionMutedStyle),
        ],
      ),
    );
  }
}
