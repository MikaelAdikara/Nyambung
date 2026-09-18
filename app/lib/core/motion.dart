import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Gerak halus untuk layar orang tua. Papan anak tidak memakai berkas ini (invarian 11), kecuali geser urutan bilah.
///
/// Semua durasi di bawah 350 ms, kurva `easeOut` untuk yang masuk. Bila setelan Android "Hapus animasi" aktif,
/// [Motion.of] mengembalikan nol dan semuanya berpindah seketika.
abstract final class Motion {
  static const press = Duration(milliseconds: 120);
  static const release = Duration(milliseconds: 160);
  static const fade = Duration(milliseconds: 200);
  static const resize = Duration(milliseconds: 240);
  static const enter = Duration(milliseconds: 320);
  static const enterStep = Duration(milliseconds: 70);

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}

/// Umpan balik tekan: anaknya mengecil ke 0,97 selama jari menempel, lalu kembali. Jari yang bergeser (menggulir)
/// membatalkan. Tidak menangkap ketukan; tombol di dalamnya tetap menerima ketukan seperti biasa.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;
  Offset _down = Offset.zero;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (e) {
      _down = e.position;
      _set(true);
    },
    onPointerMove: (e) {
      if ((e.position - _down).distance > kTouchSlop) _set(false);
    },
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: Motion.of(context, _pressed ? Motion.press : Motion.release),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Masuk sekali saat pertama tampil: memudar dari 0 dan naik 12 dp, setelah jeda [index] × 70 ms.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = Motion.enterStep * widget.index;
    final total = delay + Motion.enter;
    _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) Motion.reduced(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, 12 * (1 - _t.value)), child: child),
    ),
    child: widget.child,
  );
}

/// Muncul dan hilangnya [child] (atau `null`) tidak menyentak isi di bawahnya: tinggi berubah halus dan isinya memudar.
class SmoothReveal extends StatelessWidget {
  const SmoothReveal({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: Motion.of(context, Motion.resize),
    curve: Curves.easeOutCubic,
    alignment: Alignment.topCenter,
    child: AnimatedSwitcher(
      duration: Motion.of(context, Motion.fade),
      child: child ?? const SizedBox(width: double.infinity),
    ),
  );
}

/// Titik merah yang berdenyut pelan selama mikrofon merekam (opasitas 1 ↔ 0,4, 900 ms). Diam bila animasi dimatikan.
class RecordingDot extends StatefulWidget {
  const RecordingDot({super.key});

  @override
  State<RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<RecordingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 1.0, end: 0.4).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: Container(
      width: 12,
      height: 12,
      decoration: const BoxDecoration(color: Color(0xFFD34349), shape: BoxShape.circle),
    ),
  );
}

/// Masuk sekali dengan sedikit pantulan: skala 0,85 → 1 (easeOutBack) dan memudar, 420 ms setelah jeda [delay].
/// Hanya untuk momen yang jarang (konfirmasi misi, kartu tersimpan).
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 420);
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + _run);
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(widget.delay.inMilliseconds / (widget.delay + _run).inMilliseconds, 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) Motion.reduced(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => Opacity(
      opacity: Curves.easeOut.transform(_t.value),
      child: Transform.scale(scale: 0.85 + 0.15 * Curves.easeOutBack.transform(_t.value), child: child),
    ),
    child: widget.child,
  );
}

/// Masuk cepat untuk hal yang sering terjadi (kata baru di bilah ujaran): skala 0,8 → 1 dan memudar, 180 ms,
/// sekali saat widget pertama dipasang.
class QuickIn extends StatefulWidget {
  const QuickIn({super.key, required this.child});

  final Widget child;

  @override
  State<QuickIn> createState() => _QuickInState();
}

class _QuickInState extends State<QuickIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) Motion.reduced(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final t = Curves.easeOutCubic.transform(_c.value);
      return Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
      );
    },
    child: widget.child,
  );
}
