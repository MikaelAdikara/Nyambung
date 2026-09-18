import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Token warna dari desain ulang (mint + tosca + lime, tosca dan koral dari logo). Warna yang membawa teks sudah
/// digelapkan seperlunya supaya kontras ≥ 4,5:1 (invarian 12); warna dekoratif memakai nilai desain apa adanya.
abstract final class AppColors {
  // Latar dan permukaan.
  static const bg = Color(0xFFF1FAFA); // mint
  static const panel = Color(0xFFFFFFFF); // kertas
  static const paperSoft = Color(0xFFFCFEFE); // papan anak, lebih sunyi
  static const sand = Color(0xFFE8F6F5);
  static const sandDeep = Color(0xFFD6EEEC);
  static const line = Color(0xFFDCEEEC);

  // Teks.
  static const ink = Color(0xFF172C2A);
  static const muted = Color(0xFF52706D);

  // Merek.
  static const teal = Color(0xFF14B3A6); // tosca logo, dekoratif (awan, garis, titik)
  static const tosca = Color(0xFF098277); // latar halaman tosca berisi teks putih
  static const tealDeep = Color(0xFF038075); // isian tombol dan kartu dengan teks putih
  static const tealText = Color(0xFF026E65); // teks toska di atas mint/putih/tint
  static const tealTint = Color(0xFFDFF6F3);
  static const mint = Color(0xFFA0DDD7);
  static const mintText = Color(0xFF085C54);
  static const lime = Color(0xFFBADE4A); // satu-satunya warna tombol utama
  static const limeText = Color(0xFF0B5E56);
  static const coral = Color(0xFFF2646A);
  static const coralDeep = Color(0xFFD34349); // isian tombol koral dengan teks putih
  static const coralText = Color(0xFFC23D42);
  static const coralTint = Color(0xFFFDE1E2);
  static const sunTint = Color(0xFFFDF0D2);
  static const sunLine = Color(0xFFF5C862);
  static const sunText = Color(0xFF8A5B0A);
  static const skyTint = Color(0xFFDEF3FC);
  static const skyText = Color(0xFF1D6F94);
  static const leafTint = Color(0xFFE1F4E7);
  static const leafText = Color(0xFF2C7A48);
  static const lavender = Color(0xFF7C79C4);
  static const lavenderDeep = Color(0xFF5B57A8);
  static const lavenderTint = Color(0xFFEDECFB);
  static const caution = Color(0xFFC93A29);
  static const cautionLine = Color(0xFFF0C3B8);

  // Nama lama, dipertahankan supaya pemanggil tidak perlu tahu palet berganti.
  static const navy = tealDeep;
  static const navySoft = tealTint;
  static const green = leafText;
}

/// Gaya teks. Fredoka (bulat, hangat) hanya untuk judul, tombol, dan angka besar; Nunito untuk sisanya.
abstract final class AppText {
  static const display = TextStyle(fontFamily: 'Fredoka', fontSize: 40, height: 1.05, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const h1 = TextStyle(fontFamily: 'Fredoka', fontSize: 28, height: 1.18, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const h2 = TextStyle(fontFamily: 'Fredoka', fontSize: 22, height: 1.25, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const h3 = TextStyle(fontFamily: 'Fredoka', fontSize: 19, height: 1.3, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const number = TextStyle(fontFamily: 'Fredoka', fontSize: 52, height: 1, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const body = TextStyle(fontFamily: 'Nunito', fontSize: 16.5, height: 1.5, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const bodyStrong = TextStyle(fontFamily: 'Nunito', fontSize: 16.5, height: 1.4, fontWeight: FontWeight.w800, color: AppColors.ink);
  static const muted = TextStyle(fontFamily: 'Nunito', fontSize: 14.5, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.muted);
  static const cap = TextStyle(fontFamily: 'Nunito', fontSize: 13, height: 1.4, fontWeight: FontWeight.w700, color: AppColors.muted);
  static const eyebrow = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w800,
    color: AppColors.muted,
  );
  static const button = TextStyle(fontFamily: 'Fredoka', fontSize: 17, fontWeight: FontWeight.w600);
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
    'pengatur': PosStyle(Color(0xFFE8F6F5), Color(0xFFC7C7D2), Color(0xFF172C2A), PosMarker.circle),
    'ganti': PosStyle(Color(0xFFFCDE9E), Color(0xFFE8B54A), Color(0xFF6E4400), PosMarker.triangle),
    'kerja': PosStyle(Color(0xFFE1F4E7), Color(0xFF6FC08F), Color(0xFF2A7445), PosMarker.square),
    'sifat': PosStyle(Color(0xFFDEF3FC), Color(0xFF6FC3EA), Color(0xFF1D6F94), PosMarker.diamond),
    'tanya': PosStyle(Color(0xFFEDECFB), Color(0xFFB7B4E8), Color(0xFF5B57A8), PosMarker.hexagon),
    'benda': PosStyle(Color(0xFFFBE3D2), Color(0xFFD89560), Color(0xFF8A4A1E), PosMarker.star),
    'sosial': PosStyle(Color(0xFFFDE1E2), Color(0xFFE8828C), Color(0xFF8A2E36), PosMarker.heart),
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

/// Lapisan tekan tombol: warna tinta 12 % selama ditekan. Tanpa percikan (tetap tenang), tapi tombol terasa menjawab.
WidgetStateProperty<Color?> _pressedOverlay(Color ink) =>
    WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? ink.withValues(alpha: 0.12) : null);

/// Tema aplikasi: tanpa percikan, tombol pil 56 dp, kartu tanpa bayangan. Tombol utama lime, tombol garis netral.
/// Pindah layar memudar maju (FadeForwards); dimatikan sendiri oleh Flutter bila "Hapus animasi" aktif.
ThemeData buildTheme() {
  const buttonShape = StadiumBorder();
  const buttonSize = Size(64, 56);
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    primary: AppColors.tealDeep,
    onPrimary: Colors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.limeText,
    surface: AppColors.bg,
    onSurface: AppColors.ink,
    error: AppColors.caution,
  );
  const pageTransitions = PageTransitionsTheme(
    builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder(backgroundColor: AppColors.bg)},
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: AppColors.line, width: 2),
  );
  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: AppColors.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: pageTransitions,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.h2,
    ),
    textTheme: const TextTheme(
      titleLarge: AppText.h2,
      bodyLarge: TextStyle(fontSize: 17, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600, color: AppColors.muted),
    ),
    cardTheme: CardThemeData(
      color: AppColors.panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panel,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: AppColors.teal, width: 2)),
      labelStyle: AppText.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.tealDeep,
        foregroundColor: Colors.white,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: AppText.button,
      ).copyWith(overlayColor: _pressedOverlay(Colors.white)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: AppText.button,
        side: const BorderSide(color: AppColors.line, width: 2),
      ).copyWith(overlayColor: _pressedOverlay(AppColors.ink)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tealText,
        textStyle: AppText.button,
        shape: buttonShape,
      ).copyWith(overlayColor: _pressedOverlay(AppColors.tealText)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.panel,
      selectedColor: AppColors.tealTint,
      side: const BorderSide(color: AppColors.line),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.teal : AppColors.sandDeep),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.tealDeep : AppColors.muted),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.teal),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppText.h2,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.panel,
      indicatorColor: AppColors.tealTint,
      surfaceTintColor: Colors.transparent,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: s.contains(WidgetState.selected) ? AppColors.tealText : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.tealText : AppColors.muted),
      ),
    ),
  );
}

/// Tema papan anak: tanpa lapisan tekan yang memudar di tombol. Sel simbol punya keadaan tekan sendiri.
ThemeData boardTheme(ThemeData base) {
  const none = WidgetStatePropertyAll<Color?>(Colors.transparent);
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(style: base.filledButtonTheme.style?.copyWith(overlayColor: none)),
    iconButtonTheme: const IconButtonThemeData(style: ButtonStyle(overlayColor: none)),
  );
}
