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
  Widget build(BuildContext context) => Column(
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
      SizedBox(
        height: 58,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemCount: hotspots.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final symbol = symbolById(hotspots[index].wordId);
            return SizedBox(
              width: 132,
              child: symbol == null
                  ? const FilledButton.tonal(onPressed: null, child: Text('TIDAK TERSEDIA'))
                  : _HotspotButton(symbol: symbol, holdMs: holdMs, onSelect: onSelect),
            );
          },
        ),
      ),
    ],
  );
}

class _HotspotButton extends StatefulWidget {
  const _HotspotButton({required this.symbol, required this.holdMs, required this.onSelect});
  final WordSymbol symbol;
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
      child: DecoratedBox(
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
            child: Text(
              widget.symbol.labelDisplay,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    ),
  );
}
