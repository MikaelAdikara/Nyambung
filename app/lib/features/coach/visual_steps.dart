import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../board/symbol_cell.dart';
import 'companion_widgets.dart';

/// Satu langkah bergambar: gambar (simbol papan atau ikon) di atas, teks pendek di bawah.
class VisualStep {
  const VisualStep({required this.text, this.icon, this.word});

  final String text;
  final IconData? icon;

  /// `word_id` simbol papan yang ditampilkan sebagai gambar langkah ini (menggantikan ikon).
  final String? word;
}

/// Deret langkah bernomor, rata tengah, tinggi sama. Dipakai di pelajaran 60 detik dan layar misi supaya orang tua
/// melihat apa yang dilakukan, bukan hanya membacanya.
class VisualSteps extends StatelessWidget {
  const VisualSteps({super.key, required this.steps, this.tint = CompanionColors.tealTint});

  final List<VisualStep> steps;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Center(child: Icon(Icons.chevron_right_rounded, color: CompanionColors.muted, size: 20)),
              ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                decoration: BoxDecoration(
                  color: CompanionColors.panel,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: CompanionColors.line),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: CompanionColors.tealDeep, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 58,
                      child: Center(
                        child: switch (steps[i]) {
                          VisualStep(word: final w?) when app.symbolById(w) != null => SymbolFace(
                            symbol: app.symbolById(w)!,
                            width: 58,
                            height: 58,
                            compact: true,
                          ),
                          VisualStep(icon: final icon) => Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                            child: Icon(icon ?? Icons.circle_outlined, size: 28, color: CompanionColors.tealText),
                          ),
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[i].text,
                      textAlign: TextAlign.center,
                      style: AppText.cap.copyWith(color: CompanionColors.ink, fontWeight: FontWeight.w800, height: 1.25),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tiga langkah misi harian untuk satu kata: tekan, ucapkan, tunggu.
List<VisualStep> missionSteps(String wordId, String label) => [
  VisualStep(word: wordId, icon: Icons.touch_app_rounded, text: 'Tekan $label'),
  VisualStep(icon: Icons.record_voice_over_rounded, text: 'Ucapkan "${label.toLowerCase()}"'),
  const VisualStep(icon: Icons.hourglass_bottom_rounded, text: 'Tunggu 5 detik'),
];
