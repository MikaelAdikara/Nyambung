import 'package:flutter/material.dart';

import '../board/board_screen.dart';
import '../../core/motion.dart';
import 'companion_widgets.dart';
import 'confirm_screen.dart';
import 'companion_controller.dart';

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
      return CompanionPage(
        title: 'Misi berjalan',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            Text(
              'Tekan ${state.targetLabel} sambil bicara, 5 kali, saat ${state.routineLabel}.',
              style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Anak tidak perlu menekan. Kalau ia menekan sendiri, itu bonus dan ikut tercatat.', style: companionMutedStyle),
            const SizedBox(height: 24),
            CompanionCard(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.fade),
                    child: Text(
                      '$shownReps dari ${mission.repsTarget}',
                      key: ValueKey(shownReps),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RepDots(filled: shownReps, total: mission.repsTarget),
                  const SizedBox(height: 16),
                  const Text(
                    'Terisi sendiri dari papan. Penghitung ini mencatat contoh yang Ibu atau Ayah berikan, bukan menilai anak.',
                    textAlign: TextAlign.center,
                    style: companionMutedStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Buka papan bersama anak',
              icon: Icons.grid_view_rounded,
              onPressed: () async {
                if (openBoard != null) {
                  await openBoard!();
                } else {
                  await Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => BoardScreen(missionContext: mission.id, allowTurnToggle: true)));
                }
                await state.load();
                await state.autoSync();
              },
            ),
            const SizedBox(height: 20),
            const Text('Kedua tombol di bawah sama nilainya. Tidak ada hari yang gagal.', style: companionMutedStyle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: EqualOutlineButton(label: 'Belum sempat hari ini', onPressed: () => _confirm(context, 'belum_sempat')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EqualOutlineButton(label: 'Selesai', onPressed: () => _confirm(context, 'selesai')),
                ),
              ],
            ),
          ],
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
          Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(CompanionColors.panel, CompanionColors.teal, _level(i)),
              border: Border.all(color: CompanionColors.teal, width: 2),
            ),
          ),
      ],
    ),
  );
}
