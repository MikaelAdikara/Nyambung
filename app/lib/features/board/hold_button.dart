import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// Tombol kunci mode anak: tahan 1,5 detik untuk keluar. Lepas lebih cepat = batal.
/// Lingkaran progres di sekeliling ikon adalah **indikator keadaan**, bukan animasi dekoratif.
class HoldButton extends StatefulWidget {
  const HoldButton({super.key, required this.onComplete, this.label = 'TAHAN'});

  final VoidCallback onComplete;
  final String label;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton> with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(vsync: this, duration: Limits.lockHold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _progress.value = 0;
        widget.onComplete();
      }
    });

  void _start() => _progress.forward(from: 0);

  void _cancel() {
    if (_progress.isAnimating) _progress.stop();
    _progress.value = 0;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tahan untuk keluar',
      child: Tooltip(
        message: 'Tahan untuk keluar',
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _start(),
          onPointerUp: (_) => _cancel(),
          onPointerCancel: (_) => _cancel(),
          child: Container(
            constraints: const BoxConstraints(minWidth: 72, minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (_, _) => CircularProgressIndicator(
                          value: _progress.value,
                          strokeWidth: 3,
                          color: AppColors.lime,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      const Icon(Icons.lock_rounded, size: 20, color: Colors.white),
                    ],
                  ),
                ),
                Text(
                  widget.label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
