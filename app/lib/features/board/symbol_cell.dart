import 'dart:async';

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
    final face = SymbolFace(symbol: widget.symbol, width: widget.width, height: widget.height);
    final Widget input;
    if (widget.holdMs <= 0) {
      input = GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => widget.onSelect(widget.symbol), child: face);
    } else {
      input = Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          _cancel();
          _timer = Timer(Duration(milliseconds: widget.holdMs), () {
            _timer = null;
            widget.onSelect(widget.symbol);
          });
        },
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: face,
      );
    }
    return Semantics(button: true, label: widget.symbol.labelSpeech, excludeSemantics: true, child: input);
  }
}

/// Tampilan sel tanpa input. Dipakai juga oleh pratinjau (A4) dan bilah ujaran.
class SymbolFace extends StatelessWidget {
  const SymbolFace({super.key, required this.symbol, required this.width, required this.height, this.compact = false});

  final WordSymbol symbol;
  final double width;
  final double height;

  /// Versi kecil untuk bilah ujaran: garis lebih tipis, tanpa penanda.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = PosStyle.of(symbol.pos);
    final dpr = MediaQuery.devicePixelRatioOf(context);
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
        color: style.fill,
        border: Border.all(color: style.border, width: 2),
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
                  child: Image.asset(
                    symbol.symbolPath,
                    cacheWidth: (imageSize * dpr).round(),
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
