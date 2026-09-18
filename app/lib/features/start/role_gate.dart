import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/brand.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../board/board_screen.dart';
import '../coach/companion_widgets.dart';
import '../coach/home_screen.dart';
import 'parent_pin.dart';

/// Layar pertama setiap kali aplikasi dibuka (setelah pemasangan): "Aku {nama anak}" langsung ke papan anak,
/// "Aku orang tua" lewat PIN ke beranda orang tua. Anak yang membuka aplikasi sendiri cukup satu ketukan untuk
/// bicara, dan tidak bisa masuk ke pengaturan.
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> with WidgetsBindingObserver {
  /// Beranda orang tua terkunci lagi bila aplikasi ditinggal di latar belakang selama ini.
  static const relockAfter = Duration(minutes: 5);

  late AppState _app;
  bool _started = false;
  bool _parent = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_started) {
      _started = true;
      // Tepat sesudah pemasangan orang tua masih memegang HP: langsung ke tujuan yang dipilih di A6.
      _parent = _app.afterOnboarding != null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      // Hanya dikunci bila orang tua sedang di beranda (tidak ada layar lain terbuka, mis. kamera kartu foto).
      if (_parent && away >= relockAfter && !(Navigator.maybeOf(context)?.canPop() ?? false)) setState(() => _parent = false);
    }
  }

  String get _childName => _app.child?.nickname.trim().isNotEmpty == true ? _app.child!.nickname.trim() : 'anak';

  Future<void> _openChild() async {
    await Navigator.of(context).push(BoardScreen.childRoute());
  }

  Future<void> _openParent() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => ParentPin.isSet(_app.prefs)
            ? ParentPinScreen(
                prefs: _app.prefs,
                childName: _childName,
                onUnlocked: () => Navigator.of(routeContext).pop(true),
                onChild: () => Navigator.of(routeContext).pop(false),
                onForgot: () => _forgot(routeContext),
              )
            : _CreatePinPage(onSaved: () => Navigator.of(routeContext).pop(true)),
      ),
    );
    if (!mounted) return;
    if (unlocked == true) {
      setState(() => _parent = true);
    } else if (unlocked == false) {
      await _openChild();
    }
  }

  /// Lupa PIN: ketik nama panggilan anak persis seperti saat pemasangan, lalu buat PIN baru.
  Future<void> _forgot(BuildContext routeContext) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: routeContext,
      builder: (context) => AlertDialog(
        title: const Text('Buat PIN baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ketik nama panggilan anak seperti saat pemasangan.'),
            const SizedBox(height: 12),
            TextField(controller: name, autofocus: true, textCapitalization: TextCapitalization.words),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, name.text.trim().toLowerCase() == _childName.toLowerCase()),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    name.dispose();
    if (!routeContext.mounted) return;
    if (ok != true) {
      if (ok == false) {
        ScaffoldMessenger.of(routeContext).showSnackBar(const SnackBar(content: Text('Nama belum cocok.')));
      }
      return;
    }
    final saved = await Navigator.of(routeContext)
        .push<bool>(MaterialPageRoute(builder: (c) => _CreatePinPage(onSaved: () => Navigator.of(c).pop(true))));
    if (saved == true && routeContext.mounted) Navigator.of(routeContext).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_parent) return HomeScreen(onLock: () => setState(() => _parent = false));
    final name = _childName;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const BrandMark(size: 56),
                  const SizedBox(height: 16),
                  Text('Siapa yang memakai?', style: AppText.h1, textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  FadeSlideIn(
                    index: 0,
                    child: _RoleCard(
                      big: true,
                      title: 'Aku $name',
                      subtitle: 'Buka papan bicara',
                      icon: Icons.grid_view_rounded,
                      colors: HeroCard.heroTeal,
                      letter: name.characters.first.toUpperCase(),
                      onTap: _openChild,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    index: 1,
                    child: _RoleCard(
                      title: 'Aku orang tua',
                      subtitle: ParentPin.isSet(_app.prefs) ? 'Masuk dengan PIN' : 'Buat PIN dulu',
                      icon: Icons.lock_rounded,
                      colors: const [AppColors.panel, AppColors.panel],
                      onTap: _openParent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.letter,
    this.big = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? letter;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final onDark = big;
    final fg = onDark ? Colors.white : AppColors.ink;
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: big ? 180 : 96),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              borderRadius: BorderRadius.circular(28),
              border: onDark ? null : Border.all(color: AppColors.line, width: 2),
              boxShadow: onDark ? const [BoxShadow(color: Color(0x33038075), blurRadius: 20, offset: Offset(0, 8))] : null,
            ),
            child: Row(
              children: [
                Container(
                  width: big ? 84 : 56,
                  height: big ? 84 : 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: onDark ? Colors.white : AppColors.tealTint, shape: BoxShape.circle),
                  child: letter != null
                      ? Text(letter!, style: AppText.display.copyWith(fontSize: 40, color: AppColors.tealDeep))
                      : Icon(icon, size: 28, color: AppColors.tealText),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: (big ? AppText.h1 : AppText.h2).copyWith(color: fg)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (big) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                          Flexible(
                            child: Text(subtitle, style: AppText.body.copyWith(color: onDark ? AppColors.tealTint : AppColors.muted)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 32, color: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Buat PIN pertama kali (pengguna lama yang belum punya PIN, atau lupa PIN).
class _CreatePinPage extends StatelessWidget {
  const _CreatePinPage({required this.onSaved});

  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return CompanionPage(
      title: 'PIN orang tua',
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PIN menjaga layar orang tua dari ketukan anak. Anak tetap bisa membuka papannya tanpa PIN.',
                textAlign: TextAlign.center,
                style: AppText.muted,
              ),
              const SizedBox(height: 20),
              PinSetup(
                onDone: (pin) async {
                  await ParentPin.set(app.prefs, pin);
                  onSaved();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
