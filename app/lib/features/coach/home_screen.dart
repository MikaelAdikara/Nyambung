import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../board/board_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/therapist_screen.dart';
import 'companion_controller.dart';
import 'companion_widgets.dart';
import 'lesson_screen.dart';
import 'mission_rules.dart';
import 'mission_screen.dart';
import 'now_next_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.openChildBoard});

  final VoidCallback? openChildBoard;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  /// Selama beranda terpasang, catatan dicoba kirim berkala dan usulan terapis ditarik. Tanpa jaringan percobaan
  /// ini gagal diam-diam; luring tetap keadaan biasa. Dilewati saat papan terbuka (dikirim begitu papan ditutup)
  /// dan saat aplikasi di latar belakang (dikirim saat kembali aktif).
  static const _autoSyncEvery = Duration(seconds: 20);

  CompanionController? _controller;
  AppState? _app;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(_autoSyncEvery, (_) {
      final active = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (active && _app?.boardOpen != true) _controller?.autoSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kembali ke aplikasi (mis. setelah mode pesawat dimatikan): coba kirim segera.
    if (state == AppLifecycleState.resumed && _app?.boardOpen != true) _controller?.autoSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_app == app) return;
    _app = app;
    _controller?.dispose();
    final controller = CompanionController(app);
    _controller = controller;
    controller.load().then((_) => controller.autoSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final child = controller.child;
        if (!controller.hasMission) {
          return const Scaffold(
            backgroundColor: CompanionColors.bg,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: CompanionColors.bg,
          appBar: AppBar(
            backgroundColor: CompanionColors.bg,
            elevation: 0,
            title: Text('Halo, keluarga ${child?.nickname ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                PrimaryButton(
                  label: 'Buka Papan Bicara untuk anak',
                  icon: Icons.grid_view_rounded,
                  onPressed:
                      widget.openChildBoard ??
                      () async {
                        await Navigator.of(context).push(BoardScreen.childRoute());
                        await controller.load();
                        await controller.autoSync();
                      },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NowNextScreen())),
                  icon: const Icon(Icons.view_column_outlined),
                  label: const Text('Sekarang → Nanti'),
                ),
                const SizedBox(height: 16),
                _MissionCard(state: controller),
                if (controller.pendingTargets.isNotEmpty) ...[const SizedBox(height: 16), _ProposalCard(state: controller)],
                const SizedBox(height: 16),
                CompanionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pekan ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(controller.weeklySummary, style: companionBodyStyle),
                      const SizedBox(height: 8),
                      const Text('Angka ini lahir dari ketukan papan, bukan dari isian.', style: companionMutedStyle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SyncCard(state: controller),
              ],
            ),
          ),
          bottomNavigationBar: _CompanionNavigation(state: controller),
        );
      },
    );
  }
}

class _CompanionNavigation extends StatelessWidget {
  const _CompanionNavigation({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) => BottomAppBar(
    color: CompanionColors.panel,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _destination(
          context,
          icon: Icons.bar_chart,
          label: 'Perkembangan',
          screen: ProgressScreen(state: state),
        ),
        _destination(
          context,
          icon: Icons.people_outline,
          label: 'Terapis',
          screen: TherapistScreen(state: state),
        ),
        _destination(context, icon: Icons.settings_outlined, label: 'Pengaturan', screen: const SettingsScreen()),
      ],
    ),
  );

  Widget _destination(BuildContext context, {required IconData icon, required String label, required Widget screen}) => Expanded(
    child: InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final mission = state.mission;
    return CompanionCard(
      color: CompanionColors.navySoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tekan ${state.targetLabel} lima kali saat ${state.routineLabel}',
            style: const TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Ibu atau Ayah yang menekan sambil bicara. Anak tidak perlu menekan apa pun.', style: companionBodyStyle),
          if (state.todayLog != null) ...[
            const SizedBox(height: 8),
            Text(
              state.todayLog!.status == 'selesai'
                  ? 'Misi hari ini sudah selesai. Terima kasih.'
                  : 'Hari ini belum sempat. Tidak apa-apa, besok ada lagi.',
              style: companionMutedStyle,
            ),
          ],
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

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TherapistScreen(state: state))),
    child: CompanionCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.pendingTargets.length} usulan kata dari terapis menunggu jawaban',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Boleh diterima atau ditolak tanpa alasan.', style: companionMutedStyle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    ),
  );
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: CompanionColors.sand,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          !state.linkedToTherapist
              ? 'Belum terhubung ke terapis. Catatan tetap tersimpan di perangkat.'
              : state.outboxCount == 0
              ? 'Semua catatan sudah sampai ke terapis.${state.lastSyncedAt == null ? '' : ' Terakhir ${formatWaktuSingkat(state.lastSyncedAt!)}.'}'
              : state.lastAttemptOffline
              ? 'Tidak ada jaringan saat ini. ${state.outboxCount} catatan tersimpan di perangkat dan akan terkirim nanti.'
              : '${state.outboxCount} catatan tersimpan di perangkat dan akan terkirim nanti.',
          style: companionBodyStyle,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: state.canSync && !state.syncing ? state.syncNow : null, child: const Text('Kirim sekarang')),
        ),
      ],
    ),
  );
}
