import 'package:flutter/material.dart';

import '../board/board_screen.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import 'companion_widgets.dart';
import 'confirm_screen.dart';
import 'companion_controller.dart';
import 'visual_steps.dart';
import '../board/symbol_cell.dart';

class MissionScreen extends StatelessWidget {
  const MissionScreen({super.key, required this.state, this.openBoard});

  final CompanionController state;
  final Future<void> Function()? openBoard;

  Future<void> _confirm(BuildContext context, String status) async {
    await state.logMission(state.mission.id, status);
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ConfirmScreen(state: state, status: status, parentTaps: state.parentMissionTaps, childTaps: state.childMissionTaps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final mission = state.mission;
      final shownReps = mission.repsCounted.clamp(0, mission.repsTarget);
      final target = state.app.symbolById(mission.targetWord);
      return CompanionPage(
        title: 'Misi berjalan',
        body: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 32),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    if (target != null) SymbolFace(symbol: target, width: 128, height: 124),
                    const SizedBox(height: 12),
                    Text(
                      'Tekan ${state.targetLabel} sambil bicara, ${mission.repsTarget} kali, saat ${state.routineLabel}.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: CompanionColors.ink),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: CompanionColors.sand, borderRadius: BorderRadius.circular(99)),
                      child: Text(state.missionReason, textAlign: TextAlign.center, style: AppText.cap),
                    ),
                    const SizedBox(height: 18),
                    VisualSteps(steps: missionSteps(mission.targetWord, state.targetLabel)),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedSwitcher(
                          duration: Motion.of(context, Motion.resize),
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.3),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                              child: child,
                            ),
                          ),
                          child: Text('$shownReps', key: ValueKey(shownReps), style: AppText.number.copyWith(fontSize: 72)),
                        ),
                        Text(' dari ${mission.repsTarget}', style: AppText.h2.copyWith(color: CompanionColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _RepDots(filled: shownReps, total: mission.repsTarget),
                    const SizedBox(height: 14),
                    const Text('Terisi sendiri dari papan. Bukan menilai anak.', textAlign: TextAlign.center, style: AppText.cap),
                    const Spacer(),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Mulai: tekan ${state.targetLabel} di papan',
                      icon: Icons.touch_app_rounded,
                      onPressed: () async {
                        if (openBoard != null) {
                          await openBoard!();
                        } else {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BoardScreen(missionContext: mission.id, allowTurnToggle: true, highlightWord: mission.targetWord),
                            ),
                          );
                        }
                        await state.load();
                        await state.autoSync();
                      },
                    ),
                    const SizedBox(height: 12),
                    // Dua jawaban setara secara visual (invarian 15).
                    Row(
                      children: [
                        Expanded(
                          child: EqualOutlineButton(label: 'Belum sempat hari ini', onPressed: () => _confirm(context, 'belum_sempat')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: EqualOutlineButton(label: 'Selesai', onPressed: () => _confirm(context, 'selesai')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Lingkaran penghitung misi. Lingkaran yang baru terisi (mis. sepulang dari papan) memudar dari kosong ke toska
/// satu per satu, 220 ms dengan jeda 60 ms, supaya orang tua melihat apa yang bertambah.
class _RepDots extends StatefulWidget {
  const _RepDots({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  State<_RepDots> createState() => _RepDotsState();
}

class _RepDotsState extends State<_RepDots> with SingleTickerProviderStateMixin {
  static const _fill = Duration(milliseconds: 220);
  static const _step = Duration(milliseconds: 60);

  late final AnimationController _c = AnimationController(vsync: this);
  late int _from = widget.filled;

  @override
  void didUpdateWidget(_RepDots old) {
    super.didUpdateWidget(old);
    if (widget.filled > old.filled) {
      _from = old.filled;
      final added = widget.filled - old.filled;
      _c.duration = Motion.of(context, _fill + _step * (added - 1));
      _c.forward(from: 0);
    } else if (widget.filled < old.filled) {
      _from = widget.filled;
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Seberapa terisi lingkaran ke-[i] (0–1) pada saat ini.
  double _level(int i) {
    if (i < _from) return 1;
    if (i >= widget.filled) return 0;
    final total = _c.duration?.inMilliseconds ?? 0;
    if (total == 0) return 1;
    final start = (i - _from) * _step.inMilliseconds / total;
    final end = start + _fill.inMilliseconds / total;
    return Curves.easeOut.transform(((_c.value - start) / (end - start)).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.total; i++)
          Transform.scale(
            // Lingkaran yang baru terisi membesar sedikit lalu kembali, supaya terasa "masuk".
            scale: 1 + 0.18 * (1 - (2 * _level(i) - 1).abs()) * (i >= _from && i < widget.filled ? 1 : 0),
            child: Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(CompanionColors.panel, CompanionColors.teal, _level(i)),
                border: Border.all(color: Color.lerp(CompanionColors.sandDeep, CompanionColors.teal, _level(i))!, width: 2),
              ),
            ),
          ),
      ],
    ),
  );
}
