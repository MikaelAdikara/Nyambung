import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/data/models.dart';
import 'package:nyambung/data/scene.dart';
import 'package:nyambung/features/scenes/scene_canvas.dart';

const mobil = WordSymbol(
  wordId: 'mobil',
  labelDisplay: 'MOBIL',
  labelSpeech: 'mobil',
  pos: 'benda',
  category: 'main',
  page: 1,
  positionIndex: 6,
  symbolPath: '',
);

void main() {
  testWidgets('hotspot memakai tahan sentuh dan memilih word_id yang sama', (tester) async {
    final image = File('assets/symbols/png/aku.png').absolute;
    final selected = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            height: 400,
            child: SceneCanvas(
              imagePath: image.path,
              imageSize: const Size(100, 100),
              hotspots: const [SceneHotspot(id: 'h1', box: SceneBox(x: 0.1, y: 0.1, width: 0.8, height: 0.8), wordId: 'mobil')],
              symbolById: (id) => id == 'mobil' ? mobil : null,
              holdMs: 300,
              onSelect: (symbol) => selected.add(symbol.wordId),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final gesture = await tester.startGesture(tester.getCenter(find.text('MOBIL').first));
    await tester.pump(const Duration(milliseconds: 200));
    expect(selected, isEmpty);
    await tester.pump(const Duration(milliseconds: 120));
    expect(selected, ['mobil']);
    await gesture.up();
    await tester.pump();
    expect(selected, ['mobil']);
    await tester.pumpWidget(const SizedBox());
  });
}
