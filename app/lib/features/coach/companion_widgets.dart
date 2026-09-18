import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';

/// Warna layar pendamping = token papan (satu sumber di `core/theme.dart`).
typedef CompanionColors = AppColors;

/// Kerangka layar orang tua: tombol kembali bulat, judul Fredoka, latar mint.
class CompanionPage extends StatelessWidget {
  const CompanionPage({super.key, required this.title, required this.body, this.actions});

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return Scaffold(
      backgroundColor: CompanionColors.bg,
      appBar: AppBar(
        backgroundColor: CompanionColors.bg,
        foregroundColor: CompanionColors.ink,
        elevation: 0,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        leadingWidth: canPop ? 64 : 0,
        titleSpacing: canPop ? 4 : 20,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              )
            : null,
        title: Text(title, style: AppText.h2),
        actions: actions,
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

/// Kartu putih bersudut 20 dengan garis tipis.
class CompanionCard extends StatelessWidget {
  const CompanionCard({
    super.key,
    required this.child,
    this.color = CompanionColors.panel,
    this.borderColor = CompanionColors.line,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}

/// Kartu yang bisa diketuk: mengecil halus saat ditekan.
class TapCard extends StatelessWidget {
  const TapCard({
    super.key,
    required this.child,
    required this.onTap,
    this.color = CompanionColors.panel,
    this.borderColor = CompanionColors.line,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => PressScale(
    child: Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}

/// Baris kartu: ikon dalam kotak berwarna, judul + keterangan, chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tint = CompanionColors.tealTint,
    this.iconColor = CompanionColors.tealText,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color tint;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => TapCard(
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Row(
      children: [
        IconBadge(icon: icon, tint: tint, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyStrong),
              if (subtitle != null) Text(subtitle!, style: AppText.cap),
            ],
          ),
        ),
        trailing ?? const Icon(Icons.chevron_right_rounded, color: CompanionColors.muted),
      ],
    ),
  );
}

/// Ikon di dalam kotak bulat berwarna muda.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.tint = CompanionColors.tealTint,
    this.color = CompanionColors.tealText,
    this.size = 40,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(size * 0.32)),
    child: Icon(icon, size: size * 0.52, color: color),
  );
}

/// Tombol utama: pil lime. Satu-satunya warna ajakan bertindak.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.expand = true});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      backgroundColor: CompanionColors.lime,
      foregroundColor: CompanionColors.limeText,
      disabledBackgroundColor: CompanionColors.sandDeep,
      disabledForegroundColor: CompanionColors.muted,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      textStyle: AppText.button,
      elevation: 0,
    );
    final button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: style,
            child: Text(label, textAlign: TextAlign.center),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 22),
            label: Text(label, textAlign: TextAlign.center),
          );
    return PressScale(
      child: AnimatedContainer(
        duration: Motion.of(context, Motion.fade),
        height: 56,
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          boxShadow: onPressed == null
              ? const []
              : [
                  BoxShadow(
                    color: const Color(0xFF5A7814).withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    spreadRadius: -6,
                  ),
                ],
        ),
        child: button,
      ),
    );
  }
}

/// Tombol garis pil. Dipakai berpasangan untuk pilihan yang setara ("Selesai" / "Belum sempat hari ini").
class EqualOutlineButton extends StatelessWidget {
  const EqualOutlineButton({super.key, required this.label, required this.onPressed, this.color = CompanionColors.ink, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color == CompanionColors.ink ? CompanionColors.sandDeep : color.withValues(alpha: 0.45), width: 2),
      backgroundColor: CompanionColors.panel,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: AppText.button.copyWith(fontSize: 16),
    );
    return PressScale(
      child: SizedBox(
        height: 56,
        child: icon == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: style,
                child: Text(label, textAlign: TextAlign.center),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: style,
                icon: Icon(icon),
                label: Text(label, textAlign: TextAlign.center),
              ),
      ),
    );
  }
}

/// Label kecil kapital di atas bagian.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = CompanionColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: color));
}

/// Baris centang/silang untuk daftar yang dibagikan dan yang tidak. Bentuk ikon berbeda, bukan hanya warna.
class CheckRow extends StatelessWidget {
  const CheckRow({super.key, required this.text, this.ok = true});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            ok ? Icons.check_rounded : Icons.close_rounded,
            size: 20,
            color: ok ? CompanionColors.leafText : CompanionColors.caution,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 15))),
      ],
    ),
  );
}

const companionBodyStyle = AppText.body;
const companionMutedStyle = AppText.muted;
