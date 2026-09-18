import 'package:flutter/material.dart';

import 'companion_widgets.dart';
import 'fake_app_state.dart';
import 'lesson_screen.dart';
import 'mission_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, this.openChildBoard});

  final FakeAppState state;
  final VoidCallback? openChildBoard;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final child = state.child;
      return Scaffold(
        backgroundColor: CompanionColors.bg,
        appBar: AppBar(
          backgroundColor: CompanionColors.bg,
          elevation: 0,
          title: Text('Halo, keluarga ${child?.nickname ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            PrimaryButton(label: 'Buka Papan Bicara untuk anak', icon: Icons.grid_view_rounded, onPressed: openChildBoard),
            const SizedBox(height: 16),
            _MissionCard(state: state),
            const SizedBox(height: 16),
            CompanionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pekan ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Pekan ini ${child?.nickname ?? 'anak'} menekan TIDAK 4 kali, dan 3 kata lain.', style: companionBodyStyle),
                  const SizedBox(height: 8),
                  const Text('Angka ini lahir dari ketukan papan, bukan dari isian.', style: companionMutedStyle),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SyncCard(state: state),
          ],
        ),
      );
    },
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.state});

  final FakeAppState state;

  @override
  Widget build(BuildContext context) {
    final mission = state.mission;
    return CompanionCard(
      color: CompanionColors.navySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tekan ${mission.targetWord.toUpperCase()} lima kali saat ${state.routineLabel}',
            style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Ibu atau Ayah yang menekan sambil bicara. Anak tidak perlu menekan apa pun.', style: companionBodyStyle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(state: state, lessonKey: mission.lessonKey),
                    ),
                  ),
                  child: const Text('Pelajaran 60 detik', textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: state))),
                  child: const Text('Mulai misi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.state});

  final FakeAppState state;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: CompanionColors.sand,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.isOnline
              ? 'Semua catatan sudah sampai ke terapis.'
              : 'Tidak ada jaringan saat ini. ${state.outboxCount} catatan tersimpan di perangkat dan akan terkirim nanti.',
          style: companionBodyStyle,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: state.syncNow, child: const Text('Kirim sekarang')),
        ),
      ],
    ),
  );
}
