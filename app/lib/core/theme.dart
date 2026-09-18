import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Token warna, dari 02-desain-dan-teks §1.
abstract final class AppColors {
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

/// Bentuk penanda di sudut sel (invarian 10: warna tidak pernah satu-satunya pembawa makna).
enum PosMarker { circle, triangle, square, diamond, hexagon, star, heart }

/// Gaya per jenis kata (Modified Fitzgerald Key), dari 02 §2.
class PosStyle {
  const PosStyle(this.fill, this.border, this.text, this.marker);

  final Color fill;
  final Color border;
  final Color text;
  final PosMarker marker;

  static const _styles = {
    'pengatur': PosStyle(Color(0xFFECEAE5), Color(0xFFC4BFB4), Color(0xFF34322D), PosMarker.circle),
    'ganti': PosStyle(Color(0xFFF1E6C8), Color(0xFFD1BD86), Color(0xFF4F3F0F), PosMarker.triangle),
    'kerja': PosStyle(Color(0xFFDDE8DD), Color(0xFFA9C4A9), Color(0xFF244B2C), PosMarker.square),
    'sifat': PosStyle(Color(0xFFDCE6F1), Color(0xFFA9BED6), Color(0xFF1F3B5C), PosMarker.diamond),
    'tanya': PosStyle(Color(0xFFE6DDF0), Color(0xFFBBA6D2), Color(0xFF3F2A5C), PosMarker.hexagon),
    'benda': PosStyle(Color(0xFFF6E7CF), Color(0xFFDDBF8C), Color(0xFF5C3F12), PosMarker.star),
    'sosial': PosStyle(Color(0xFFF2DEE6), Color(0xFFD5A6BB), Color(0xFF6B2A45), PosMarker.heart),
  };

  /// `pos` yang tidak dikenal memakai gaya `benda`.
  static PosStyle of(String pos) => _styles[pos] ?? _styles['benda']!;
}

/// Menggambar penanda bentuk tanpa aset.
class PosMarkerPainter extends CustomPainter {
  const PosMarkerPainter(this.marker, this.color);

  final PosMarker marker;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final c = Offset(w / 2, h / 2);
    final r = math.min(w, h) / 2;
    switch (marker) {
      case PosMarker.circle:
        canvas.drawCircle(c, r, paint);
      case PosMarker.square:
        canvas.drawRect(Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7), paint);
      case PosMarker.triangle:
        canvas.drawPath(_polygon(c, r, 3, -math.pi / 2), paint);
      case PosMarker.diamond:
        canvas.drawPath(_polygon(c, r, 4, -math.pi / 2), paint);
      case PosMarker.hexagon:
        canvas.drawPath(_polygon(c, r, 6, 0), paint);
      case PosMarker.star:
        canvas.drawPath(_star(c, r), paint);
      case PosMarker.heart:
        canvas.drawPath(_heart(w, h), paint);
    }
  }

  static Path _polygon(Offset c, double r, int n, double start) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final a = start + 2 * math.pi * i / n;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _star(Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + math.pi * i / 5;
      final p = Offset(c.dx + rr * math.cos(a), c.dy + rr * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  static Path _heart(double w, double h) {
    return Path()
      ..moveTo(w / 2, h * 0.95)
      ..cubicTo(-w * 0.1, h * 0.5, w * 0.15, -h * 0.15, w / 2, h * 0.28)
      ..cubicTo(w * 0.85, -h * 0.15, w * 1.1, h * 0.5, w / 2, h * 0.95)
      ..close();
  }

  @override
  bool shouldRepaint(PosMarkerPainter old) => old.marker != marker || old.color != color;
}

/// Tema aplikasi (02 §3): tanpa percikan, tombol 56 dp sudut 14, kartu tanpa bayangan.
ThemeData buildTheme() {
  const buttonText = TextStyle(fontSize: 18, fontWeight: FontWeight.w800);
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonSize = Size(64, 56);
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.navy, primary: AppColors.navy, surface: AppColors.bg, onSurface: AppColors.ink);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 18, height: 1.4, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 17, height: 1.4, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
        side: const BorderSide(color: AppColors.navy, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.navy, textStyle: buttonText),
    ),
  );
}
