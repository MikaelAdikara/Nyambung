import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/scene.dart';
import 'scene_geometry.dart';

class SceneCanvas extends StatelessWidget {
  const SceneCanvas({
    super.key,
    required this.imagePath,
    required this.imageSize,
    required this.hotspots,
    required this.symbolById,
    required this.onSelect,
    this.holdMs = 0,
  });

  final String imagePath;
  final Size imageSize;
  final List<SceneHotspot> hotspots;
  final WordSymbol? Function(String) symbolById;
  final ValueChanged<WordSymbol> onSelect;
  final int holdMs;

  @override
  Widget build(BuildContext context) {
    final spoken = [for (final h in hotspots) ?symbolById(h.wordId)];
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewport = Size(constraints.maxWidth, constraints.maxHeight);
              final imageRect = containedImageRect(imageSize, viewport);
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: imageRect,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.bg),
                    ),
                  ),
                  for (final hotspot in hotspots)
                    if (symbolById(hotspot.wordId) case final symbol?)
                      Positioned.fromRect(
                        rect: sceneBoxToRect(hotspot.box, imageRect),
                        child: _HotspotButton(symbol: symbol, holdMs: holdMs, onSelect: onSelect),
                      ),
                ],
              );
            },
          ),
        ),
        // Jalan pintas untuk area yang kecil atau berdempetan di foto: kata yang sama, dalam tombol ≥ 10 mm.
        if (spoken.isNotEmpty)
          SizedBox(
            height: 76,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              scrollDirection: Axis.horizontal,
              itemCount: spoken.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) => _HotspotButton(symbol: spoken[index], holdMs: holdMs, onSelect: onSelect, chip: true),
            ),
          ),
      ],
    );
  }
}

class _HotspotButton extends StatefulWidget {
  const _HotspotButton({required this.symbol, required this.holdMs, required this.onSelect, this.chip = false});
  final WordSymbol symbol;

  /// Tombol di jalan pintas bawah foto: kartu penuh dengan teks di tengah, bukan bingkai area.
  final bool chip;
  final int holdMs;
  final ValueChanged<WordSymbol> onSelect;

  @override
  State<_HotspotButton> createState() => _HotspotButtonState();
}

class _HotspotButtonState extends State<_HotspotButton> {
  Timer? _timer;
  bool _fired = false;

  void _start() {
    _fired = false;
    if (widget.holdMs == 0) return;
    _timer = Timer(Duration(milliseconds: widget.holdMs), () {
      _fired = true;
      widget.onSelect(widget.symbol);
    });
  }

  void _end() {
    _timer?.cancel();
    _timer = null;
    if (widget.holdMs == 0 && !_fired) widget.onSelect(widget.symbol);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.symbol.labelSpeech,
    child: Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _end(),
      onPointerCancel: (_) {
        _timer?.cancel();
        _timer = null;
      },
      child: widget.chip
          ? Container(
              constraints: const BoxConstraints(minWidth: 112),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.tealTint,
                border: Border.all(color: AppColors.tealDeep, width: 2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                widget.symbol.labelDisplay,
                maxLines: 1,
                style: const TextStyle(fontSize: 18, color: AppColors.tealDeep, fontWeight: FontWeight.w900),
              ),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.tealTint.withValues(alpha: 0.35),
                border: Border.all(color: AppColors.tealDeep, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: AppColors.ink.withValues(alpha: 0.82),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.symbol.labelDisplay,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ),
    ),
  );
}
