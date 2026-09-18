import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
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
    return Scaffold(
      backgroundColor: CompanionColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            children: [
              const Spacer(),
              // Masuk yang sama persis untuk kedua jawaban: tidak ada perayaan khusus untuk "Selesai" (invarian 15).
              PopIn(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(color: CompanionColors.leafTint, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 38, color: CompanionColors.leafText),
                ),
              ),
              const SizedBox(height: 18),
              const FadeSlideIn(index: 1, child: Text('Tercatat', style: AppText.h1)),
              const SizedBox(height: 6),
              FadeSlideIn(
                index: 2,
                child: Text(
                  done ? 'Misi hari ini selesai.' : 'Belum sempat hari ini. Besok ada lagi.',
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: CompanionColors.muted),
                ),
              ),
              const SizedBox(height: 22),
              FadeSlideIn(
                index: 3,
                child: CompanionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (target != null)
                            Image(
                              image: symbolImage(target.symbolPath),
                              width: 40,
                              height: 40,
                              errorBuilder: (_, _, _) => const SizedBox(width: 40),
                            ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(state.targetLabel, style: AppText.h3)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CheckRow(text: '$reps ketukan Ibu/Ayah saat memberi contoh'),
                      CheckRow(text: childTaps == 0 ? '$name sedang melihat contohmu' : '$childTaps ketukan $name sendiri'),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              FadeSlideIn(
                index: 4,
                child: Column(
                  children: [
                    PrimaryButton(label: 'Kembali ke beranda', onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: EqualOutlineButton(
                        label: 'Buka Papan Bicara',
                        icon: Icons.grid_view_rounded,
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
      ),
    );
  }
}
