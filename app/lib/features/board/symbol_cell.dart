import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';

/// Satu sel papan: gambar, label kapital, warna per `pos`, dan penanda bentuk di sudut kanan atas.
///
/// `holdMs` = 0 → ketuk biasa memilih. `holdMs` > 0 → tahan selama itu untuk memilih; menggulir
/// (`onPointerCancel`) atau mengangkat jari lebih cepat membatalkan.
class SymbolCell extends StatefulWidget {
  const SymbolCell({super.key, required this.symbol, required this.width, required this.height, required this.onSelect, this.holdMs = 0});

  final WordSymbol symbol;
  final double width;
  final double height;
  final int holdMs;
  final ValueChanged<WordSymbol> onSelect;

  @override
  State<SymbolCell> createState() => _SymbolCellState();
}

class _SymbolCellState extends State<SymbolCell> {
  Timer? _timer;
  Offset _down = Offset.zero;

  /// Jari sedang di atas sel. Ditampilkan seketika tanpa transisi (invarian 11): anak melihat sel mana yang
  /// ia sentuh, tanpa gerakan.
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v && mounted) setState(() => _pressed = v);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final face = SymbolFace(symbol: widget.symbol, width: widget.width, height: widget.height, pressed: _pressed);
    final hold = widget.holdMs > 0;
    final Widget input = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _cancel();
        _down = e.position;
        _setPressed(true);
        if (hold) {
          _timer = Timer(Duration(milliseconds: widget.holdMs), () {
            _timer = null;
            widget.onSelect(widget.symbol);
          });
        }
      },
      // Jari yang bergeser sedang menggulir, bukan memilih: batalkan penahanan dan keadaan tekan. Listener tidak
      // menerima pointerCancel saat gulir menang di arena gestur.
      onPointerMove: (e) {
        if ((e.position - _down).distance > kTouchSlop) {
          _cancel();
          _setPressed(false);
        }
      },
      onPointerUp: (_) {
        _cancel();
        _setPressed(false);
      },
      onPointerCancel: (_) {
        _cancel();
        _setPressed(false);
      },
      child: hold ? face : GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => widget.onSelect(widget.symbol), child: face),
    );
    return Semantics(button: true, label: widget.symbol.labelSpeech, excludeSemantics: true, child: input);
  }
}

/// Tampilan sel tanpa input. Dipakai juga oleh pratinjau (A4) dan bilah ujaran.
class SymbolFace extends StatelessWidget {
  const SymbolFace({
    super.key,
    required this.symbol,
    required this.width,
    required this.height,
    this.compact = false,
    this.pressed = false,
  });

  final WordSymbol symbol;
  final double width;
  final double height;

  /// Versi kecil untuk bilah ujaran: garis lebih tipis, tanpa penanda.
  final bool compact;

  /// Sedang disentuh: latar sedikit lebih gelap dan garis tepi setebal 4 dp berwarna teks.
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final style = PosStyle.of(symbol.pos);
    final imageSize = height * 0.62;
    final letter = symbol.labelDisplay.isEmpty ? '?' : symbol.labelDisplay.characters.first;
    final fallback = Center(
      child: Text(
        letter,
        style: TextStyle(fontSize: imageSize * 0.6, fontWeight: FontWeight.w800, color: style.text),
      ),
    );
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: pressed ? Color.lerp(style.fill, style.border, 0.45) : style.fill,
        border: Border.all(color: pressed ? style.text : style.border, width: pressed ? 4 : 2),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(compact ? 3 : 6),
            child: Column(
              children: [
                SizedBox(
                  height: imageSize - (compact ? 6 : 12),
                  width: double.infinity,
                  child: Image(
                    image: symbolImage(symbol.symbolPath),
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        symbol.labelDisplay,
                        maxLines: 1,
                        style: TextStyle(fontSize: compact ? 13 : 18, fontWeight: FontWeight.w800, color: style.text),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!compact)
            Positioned(
              top: 5,
              right: 5,
              child: SizedBox(width: 13, height: 13, child: CustomPaint(painter: PosMarkerPainter(style.marker, style.border))),
            ),
        ],
      ),
    );
  }
}

/// Lebar dekode gambar simbol: sama dengan PNG sumber (256 px), jadi tidak pernah membesar.
const symbolDecodeWidth = 256;

/// Satu kunci cache per simbol untuk papan, bilah ujaran, dan pratinjau: tiap gambar didekode sekali
/// (± 256 KB) lalu dipakai ulang di semua ukuran, termasuk oleh [precacheSymbols].
ImageProvider symbolImage(String path) => ResizeImage(AssetImage(path), width: symbolDecodeWidth);

/// Dekode gambar simbol sebelum halamannya dibuka, satu per satu supaya tidak berebut dengan frame yang sedang
/// digambar. Berhenti bila [keepGoing] mengembalikan false (mis. papan sudah ditutup). Gambar yang belum ada
/// (sel huruf pertama) dilewati diam-diam.
Future<void> precacheSymbols(BuildContext context, Iterable<WordSymbol?> symbols, {required bool Function() keepGoing}) async {
  final seen = <String>{};
  for (final s in symbols) {
    if (s == null || !seen.add(s.symbolPath)) continue;
    if (!keepGoing() || !context.mounted) return;
    await precacheImage(symbolImage(s.symbolPath), context, onError: (_, _) {});
  }
}
