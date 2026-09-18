import 'package:flutter/material.dart';

import '../board/board_screen.dart';
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
              'Tekan ${mission.targetWord.toUpperCase()} sambil bicara, 5 kali, saat ${state.routineLabel}.',
              style: const TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Anak tidak perlu menekan. Kalau ia menekan sendiri, itu bonus dan ikut tercatat.', style: companionMutedStyle),
            const SizedBox(height: 24),
            CompanionCard(
              child: Column(
                children: [
                  Text('$shownReps dari ${mission.repsTarget}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      mission.repsTarget,
                      (index) => Container(
                        width: 30,
                        height: 30,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < shownReps ? CompanionColors.teal : CompanionColors.panel,
                          border: Border.all(color: CompanionColors.teal, width: 2),
                        ),
                      ),
                    ),
                  ),
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
