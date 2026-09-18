import 'package:flutter/material.dart';

import 'companion_widgets.dart';
import 'companion_controller.dart';

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key, required this.state, required this.status, required this.parentTaps, required this.childTaps});

  final CompanionController state;
  final String status;
  final int parentTaps;
  final int childTaps;

  @override
  Widget build(BuildContext context) {
    final done = status == 'selesai';
    return CompanionPage(
      title: done ? 'Tercatat' : 'Tercatat: belum sempat',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              done ? 'Misi hari ini selesai.' : 'Hari ini belum sempat. Besok ada misi yang sama.',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            CompanionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• $parentTaps ketukan Ibu/Ayah saat memberi contoh', style: companionBodyStyle),
                  const SizedBox(height: 8),
                  Text('• $childTaps ketukan anak', style: companionBodyStyle),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Catatan ini akan sampai ke terapis saat ada jaringan. Tidak ada yang perlu dilaporkan lagi.',
              style: companionMutedStyle,
            ),
            const Spacer(),
            PrimaryButton(label: 'Kembali ke beranda', onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
          ],
        ),
      ),
    );
  }
}
