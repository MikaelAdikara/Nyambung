import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/motion.dart';
import '../board/board_screen.dart';
import '../board/symbol_cell.dart';
import 'companion_controller.dart';
import 'companion_widgets.dart';

class ConfirmScreen extends StatelessWidget {
  const ConfirmScreen({super.key, required this.state, required this.status, required this.parentTaps, required this.childTaps});

  final CompanionController state;
  final String status;
  final int parentTaps;
  final int childTaps;

  @override
  Widget build(BuildContext context) {
    final done = status == 'selesai';
    final target = AppScope.of(context).symbolById(state.mission.targetWord);
    final name = state.child?.nickname ?? 'Anak';
    // Ketukan pendamping pada kata target di papan misi hari ini (penghitung misi), bukan semua ketukan.
    final reps = state.mission.repsCounted;
    return CompanionPage(
      title: done ? 'Tercatat' : 'Tercatat: belum sempat',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Masuk yang sama persis untuk kedua jawaban: tidak ada perayaan untuk "Selesai" (invarian 15).
            FadeSlideIn(
              index: 0,
              child: Text(
                done
                    ? 'Kamu memodelkan ${state.targetLabel} $reps kali saat ${state.routineLabel}. Tidak perlu tepat lima, '
                          'yang penting anak melihatnya.'
                    : 'Hari ini belum sempat. Besok ada misi yang sama, dan hari ini tidak menghapus apa pun.',
                style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              index: 1,
              child: CompanionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YANG TERCATAT HARI INI',
                      style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: CompanionColors.muted),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (target != null)
                          Image(
                            image: symbolImage(target.symbolPath),
                            width: 44,
                            height: 44,
                            errorBuilder: (_, _, _) => const SizedBox(width: 44),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(state.targetLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                        Text('$reps kali', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Divider(height: 24, color: CompanionColors.line),
                    Text(
                      childTaps == 0
                          ? '$name belum menekan sendiri di papan misi. Tidak apa-apa, ia sedang melihat contohmu.'
                          : '$name sendiri menekan papan $childTaps kali. Itu ikut tercatat, terpisah dari ketukanmu.',
                      style: companionMutedStyle,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              index: 2,
              child: CompanionCard(
                color: CompanionColors.sand,
                child: Text(
                  state.linkedToTherapist
                      ? 'Catatan hari ini terkirim sendiri ke terapis saat ada jaringan, tanpa perlu kamu buka lagi.'
                      : 'Catatan hari ini tersimpan di HP ini. Tidak ada yang perlu dilaporkan lagi.',
                  style: companionBodyStyle,
                ),
              ),
            ),
            const Spacer(),
            FadeSlideIn(
              index: 3,
              child: Column(
                children: [
                  PrimaryButton(label: 'Selesai', onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: EqualOutlineButton(
                      label: 'Buka Papan Bicara',
                      onPressed: () {
                        final nav = Navigator.of(context);
                        nav.popUntil((route) => route.isFirst);
                        nav.push(BoardScreen.childRoute());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
