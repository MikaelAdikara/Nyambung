import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/brand.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../board/board_screen.dart';
import '../board/symbol_cell.dart';
import '../progress/progress_screen.dart';
import '../scenes/scene_library_screen.dart';
import '../settings/link_required.dart';
import '../settings/settings_screen.dart';
import '../settings/therapist_screen.dart';
import '../vocab/phrase_screen.dart';
import '../vocab/voice_clone_screen.dart';
import 'companion_controller.dart';
import 'companion_widgets.dart';
import 'home_cards.dart';
import 'lesson_screen.dart';
import 'mission_rules.dart';
import 'mission_screen.dart';
import 'now_next_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.openChildBoard, this.onLock});

  final VoidCallback? openChildBoard;

  /// Kembali ke layar pilihan (Aku {nama} / Aku orang tua). Null = tanpa tombol kunci (tes).
  final VoidCallback? onLock;

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
    openTherapistTab.addListener(_onOpenTherapistTab);
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
    controller.load().then((_) {
      _openAfterOnboarding(controller);
      return controller.autoSync();
    });
  }

  /// Pilihan di A6 ("Buka misi hari ini" / "Lihat papan dulu") dijalankan sekali setelah beranda siap.
  void _openAfterOnboarding(CompanionController controller) {
    final app = _app;
    final next = app?.afterOnboarding;
    if (app == null || next == null || !mounted || !controller.hasMission) return;
    app.afterOnboarding = null;
    switch (next) {
      case AfterOnboarding.mission:
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: controller)));
      case AfterOnboarding.board:
        _openBoard(controller);
    }
  }

  Future<void> _openBoard(CompanionController controller) async {
    final open = widget.openChildBoard;
    if (open != null) return open();
    await Navigator.of(context).push(BoardScreen.childRoute());
    await controller.load();
    await controller.autoSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    openTherapistTab.removeListener(_onOpenTherapistTab);
    _ticker?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  /// Tab bawah: 0 Beranda, 1 Perkembangan, 2 Terapis, 3 Pengaturan. Hanya tab terpilih yang dibangun, jadi setiap
  /// kali dibuka datanya segar (sama seperti saat masih dibuka lewat rute).
  int _tab = 0;

  void _openTab(int i) => setState(() => _tab = i);

  void _onOpenTherapistTab() {
    if (mounted) _openTab(2);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return ListenableBuilder(
      listenable: controller ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        final ready = controller != null && controller.hasMission;
        return Scaffold(
          backgroundColor: CompanionColors.bg,
          body: AnimatedSwitcher(
            duration: Motion.of(context, Motion.resize),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: !ready
                ? const Center(key: ValueKey('memuat'), child: CircularProgressIndicator())
                : KeyedSubtree(key: ValueKey(_tab), child: _tabBody(controller)),
          ),
          bottomNavigationBar: !ready
              ? null
              : DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: CompanionColors.line)),
                  ),
                  child: NavigationBar(
                    selectedIndex: _tab,
                    onDestinationSelected: _openTab,
                    animationDuration: Motion.of(context, Motion.resize),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Hari Ini'),
                      NavigationDestination(
                        icon: Icon(Icons.bar_chart_outlined),
                        selectedIcon: Icon(Icons.bar_chart_rounded),
                        label: 'Kembang',
                      ),
                      NavigationDestination(icon: Icon(Icons.link_rounded), selectedIcon: Icon(Icons.link_rounded), label: 'Terapis'),
                      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Atur'),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _tabBody(CompanionController controller) => switch (_tab) {
    1 => ProgressScreen(state: controller),
    2 => TherapistScreen(state: controller),
    3 => const SettingsScreen(),
    _ => _home(controller),
  };

  Widget _home(CompanionController controller) {
    final child = controller.child;
    final sections = <Widget>[
      PrimaryButton(label: 'Buka Papan Bicara untuk anak', icon: Icons.grid_view_rounded, onPressed: () => _openBoard(controller)),
      _MissionCard(state: controller),
      _FeaturedSection(onReturn: controller.load),
      if (controller.pendingTargets.isNotEmpty) _ProposalCard(state: controller, onOpen: () => _openTab(2)),
      if (controller.pendingPhrases.isNotEmpty)
        _PhraseProposalCard(
          count: controller.pendingPhrases.length,
          from: controller.pendingPhrases.first.createdBy,
          onOpen: () async {
            await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PhraseScreen()));
            await controller.load();
          },
        ),
      WeekCard(state: controller),
      NavRow(
        icon: Icons.view_column_rounded,
        title: 'Sekarang → Nanti',
        subtitle: 'Urutan kegiatan dengan dua gambar',
        tint: CompanionColors.lavenderTint,
        iconColor: CompanionColors.lavenderDeep,
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const NowNextScreen())),
      ),
      _SyncCard(state: controller),
    ];
    return Scaffold(
      backgroundColor: CompanionColors.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  const BrandMark(size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Halo, keluarga ${child?.nickname ?? ''}', style: AppText.h2)),
                  if (widget.onLock != null)
                    RoundIconButton(icon: Icons.lock_outline_rounded, tooltip: 'Kunci layar orang tua', onPressed: widget.onLock),
                ],
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                FadeSlideIn(key: ValueKey(sections[i].runtimeType), index: i, child: sections[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu misi hari ini: gradasi tosca, satu kalimat misi, dua tombol.
class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final mission = state.mission;
    final log = state.todayLog;
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Misi hari ini', style: AppText.bodyStrong.copyWith(color: CompanionColors.tealTint, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      'Tekan ${state.targetLabel} lima kali saat ${state.routineLabel}',
                      style: AppText.h2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (state.app.symbolById(mission.targetWord) case final s?) SymbolFace(symbol: s, width: 76, height: 76, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ibu atau Ayah yang menekan sambil bicara.', style: AppText.body.copyWith(color: Colors.white, fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: CompanionColors.tealTint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(state.missionReason, style: AppText.cap.copyWith(color: CompanionColors.tealTint)),
              ),
            ],
          ),
          SmoothReveal(
            child: log == null
                ? null
                : Padding(
                    key: ValueKey(log.status),
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(99)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            log.status == 'selesai' ? 'Sudah selesai hari ini' : 'Belum sempat hari ini',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroButton(
                  label: 'Pelajaran 60 detik',
                  filled: false,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LessonScreen(state: state, lessonKey: mission.lessonKey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroButton(
                  label: 'Mulai misi',
                  filled: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MissionScreen(state: state))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressScale(
    child: SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
          foregroundColor: filled ? CompanionColors.tealText : Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: AppText.button.copyWith(fontSize: 15),
        ),
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    ),
  );
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.state, required this.onOpen});

  final CompanionController state;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onOpen,
    color: CompanionColors.sunTint,
    borderColor: CompanionColors.sunLine,
    child: Row(
      children: [
        const IconBadge(icon: Icons.lightbulb_outline_rounded, tint: Colors.white, color: CompanionColors.sunText),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '${state.pendingTargets.length} usulan kata dari terapis menunggu jawaban',
            style: AppText.bodyStrong.copyWith(color: CompanionColors.sunText),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: CompanionColors.sunText),
      ],
    ),
  );
}

/// Frasa bersuara dari terapis/guru yang menunggu jawaban keluarga.
class _PhraseProposalCard extends StatelessWidget {
  const _PhraseProposalCard({required this.count, required this.from, required this.onOpen});

  final int count;
  final String from;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onOpen,
    color: CompanionColors.lavenderTint,
    borderColor: CompanionColors.lavenderTint,
    child: Row(
      children: [
        const IconBadge(icon: Icons.graphic_eq_rounded, tint: Colors.white, color: CompanionColors.lavenderDeep),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            count == 1 ? 'Frasa bersuara dari $from menunggu jawaban' : '$count frasa bersuara menunggu jawaban',
            style: AppText.bodyStrong.copyWith(color: CompanionColors.lavenderDeep),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: CompanionColors.lavenderDeep),
      ],
    ),
  );
}

class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.state});

  final CompanionController state;

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = !state.linkedToTherapist
        ? (Icons.phone_android_rounded, CompanionColors.muted, 'Catatan tersimpan di perangkat ini')
        : state.outboxCount == 0
        ? (
            Icons.check_circle_rounded,
            CompanionColors.leafText,
            'Semua catatan sudah sampai ke terapis${state.lastSyncedAt == null ? '' : ' · ${formatWaktuSingkat(state.lastSyncedAt!)}'}',
          )
        : (
            state.lastAttemptOffline ? Icons.cloud_off_rounded : Icons.cloud_upload_outlined,
            CompanionColors.skyText,
            '${state.outboxCount} catatan menunggu jaringan',
          );
    return CompanionCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          IconBadge(icon: icon, tint: CompanionColors.sand, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fade),
              // Rata kiri: bawaan AnimatedSwitcher menaruh teks di tengah, jauh dari ikonnya.
              layoutBuilder: (current, previous) => Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
              child: Text(text, key: ValueKey(text), style: AppText.body.copyWith(fontSize: 15)),
            ),
          ),
          if (state.canSync && state.outboxCount > 0)
            TextButton(onPressed: state.syncing ? null : state.syncNow, child: Text(state.syncing ? 'Mengirim…' : 'Kirim')),
        ],
      ),
    );
  }
}

/// Fitur unggulan di beranda, tidak tersembunyi di Atur: papan dari foto dengan bantuan AI, suara keluarga, dan
/// frasa bersuara. Ketiganya dibuat daring sekali, lalu dipakai anak tanpa internet.
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection({required this.onReturn});

  final Future<void> Function() onReturn;

  Future<void> _push(BuildContext context, Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    await onReturn();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Eyebrow('Fitur unggulan')),
      _FeatureCard(
        icon: Icons.photo_camera_back_outlined,
        badge: 'AI',
        title: 'Papan dari foto',
        subtitle: 'Foto kegiatan nyata. AI memberi keterangan tiap benda dan mengusulkan katanya.',
        tint: CompanionColors.skyTint,
        iconColor: CompanionColors.skyText,
        onTap: () => _push(context, const SceneLibraryScreen()),
      ),
      const SizedBox(height: 10),
      _FeatureCard(
        icon: Icons.record_voice_over_rounded,
        badge: 'Klon suara',
        title: 'Suara keluarga',
        subtitle: 'Rekam tiga kalimat sekali. Frasa baru terdengar dengan suara Ibu atau Ayah.',
        tint: CompanionColors.coralTint,
        iconColor: CompanionColors.coralText,
        onTap: () => _push(context, const VoiceCloneScreen()),
      ),
      const SizedBox(height: 10),
      _FeatureCard(
        icon: Icons.graphic_eq_rounded,
        badge: 'Suara',
        title: 'Frasa bersuara',
        subtitle: 'Ketik kalimat pendek, jadi satu kartu bersuara di papan anak.',
        tint: CompanionColors.lavenderTint,
        iconColor: CompanionColors.lavenderDeep,
        onTap: () => _push(context, const PhraseScreen()),
      ),
    ],
  );
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    color: tint,
    borderColor: tint,
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 30, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(title, style: AppText.h3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      badge,
                      style: AppText.cap.copyWith(color: iconColor, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppText.muted.copyWith(color: AppColors.ink)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: iconColor),
      ],
    ),
  );
}
