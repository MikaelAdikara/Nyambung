import 'package:flutter/material.dart';

import 'motion.dart';
import 'theme.dart';

/// Aset merek (assets/brand/): logo dibersihkan dari bayangan dan latar, awan, dan matahari dari berkas desain.
abstract final class BrandAssets {
  static const logoMark = 'assets/brand/logo_mark.png';
  static const cloud = 'assets/brand/cloud.png';
  static const sun = 'assets/brand/sun.png';
}

/// Logo Nyambung: tanda dua gelembung bicara di atas kotak putih bersudut bulat dengan bayangan toska tipis.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * 0.26),
      boxShadow: [
        BoxShadow(color: const Color(0xFF0B7A70).withValues(alpha: 0.18), blurRadius: size * 0.2, offset: Offset(0, size * 0.06)),
      ],
    ),
    child: Image.asset(BrandAssets.logoMark, filterQuality: FilterQuality.medium, semanticLabel: 'Nyambung'),
  );
}

/// Kaki halaman berbentuk awan dengan satu aksi di atasnya. Awan toska di atas latar mint, putih di atas latar tosca.
class CloudFooter extends StatelessWidget {
  const CloudFooter({super.key, required this.child, this.color = AppColors.teal, this.height = 150});

  final Widget child;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height + MediaQuery.paddingOf(context).bottom,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned.fill(
          child: Image.asset(BrandAssets.cloud, fit: BoxFit.fill, color: color, colorBlendMode: BlendMode.srcIn),
        ),
        Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + MediaQuery.paddingOf(context).bottom), child: child),
      ],
    ),
  );
}

/// Matahari tersenyum di pojok layar sambutan. Muncul sekali dengan putaran kecil lalu diam: dekorasi yang hanya
/// dilihat saat pemasangan, jadi boleh sedikit bermain.
class SunDecoration extends StatelessWidget {
  const SunDecoration({super.key, this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 900)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.rotate(
          angle: -0.35 * (1 - t),
          child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
        ),
      ),
      child: Image.asset(BrandAssets.sun, width: size, filterQuality: FilterQuality.medium),
    ),
  );
}

/// Kartu besar bergradasi (misi hari ini, terapis) dengan lingkaran putih samar di pojok kanan atas.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.child, this.colors = heroTeal, this.padding = const EdgeInsets.all(20)});

  static const heroTeal = [Color(0xFF0A8C80), Color(0xFF05675E)];
  static const heroLavender = [Color(0xFF6966B8), Color(0xFF4F4B99)];
  static const heroCoral = [Color(0xFFD34349), Color(0xFFB0343A)];

  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -36,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    ),
  );
}

/// Tombol ikon bulat (kembali, tutup): putih di atas mint, putih transparan di atas tosca.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.onDark = false});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool onDark;

  @override
  Widget build(BuildContext context) => PressScale(
    child: Tooltip(
      message: tooltip ?? '',
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: onDark ? Colors.white.withValues(alpha: 0.2) : AppColors.panel,
                  shape: BoxShape.circle,
                  boxShadow: onDark ? null : const [BoxShadow(color: Color(0x14038075), blurRadius: 3, offset: Offset(0, 1))],
                ),
                child: Icon(icon, size: 22, color: onDark ? Colors.white : AppColors.ink),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
