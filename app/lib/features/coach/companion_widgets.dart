import 'package:flutter/material.dart';

abstract final class CompanionColors {
  static const bg = Color(0xFFF5F2EA);
  static const panel = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C1C1C);
  static const muted = Color(0xFF5F5B52);
  static const navy = Color(0xFF1F4E79);
  static const navySoft = Color(0xFFE3EBF3);
  static const coral = Color(0xFFC8734F);
  static const teal = Color(0xFF2A7F7A);
  static const line = Color(0xFFE4DFD3);
  static const sand = Color(0xFFEFE9DB);
  static const green = Color(0xFF2D6A3E);
}

class CompanionPage extends StatelessWidget {
  const CompanionPage({super.key, required this.title, required this.body, this.actions});

  final String title;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CompanionColors.bg,
    appBar: AppBar(
      backgroundColor: CompanionColors.bg,
      foregroundColor: CompanionColors.ink,
      elevation: 0,
      title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      actions: actions,
    ),
    body: SafeArea(child: body),
  );
}

class CompanionCard extends StatelessWidget {
  const CompanionCard({super.key, required this.child, this.color = CompanionColors.panel, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CompanionColors.line),
    ),
    child: child,
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: CompanionColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class EqualOutlineButton extends StatelessWidget {
  const EqualOutlineButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: CompanionColors.ink,
        side: const BorderSide(color: CompanionColors.navy, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

const companionBodyStyle = TextStyle(fontSize: 17, height: 1.4, color: CompanionColors.ink);
const companionMutedStyle = TextStyle(fontSize: 15, height: 1.4, color: CompanionColors.muted);
