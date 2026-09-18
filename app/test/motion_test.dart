import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/motion.dart';

double _scale(WidgetTester t) => t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  testWidgets('PressScale mengecil selama ditekan dan kembali saat dilepas', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Center(
          child: PressScale(
            child: FilledButton(onPressed: () => taps++, child: const Text('Mulai')),
          ),
        ),
      ),
    );
    expect(_scale(t), 1);
    final g = await t.startGesture(t.getCenter(find.text('Mulai')));
    await t.pump();
    expect(_scale(t), 0.97);
    await g.up();
    await t.pumpAndSettle();
    expect(_scale(t), 1);
    expect(taps, 1, reason: 'ketukan tetap sampai ke tombol');
  });

  testWidgets('setelan hapus animasi membuat gerak seketika', (t) async {
    await t.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: FadeSlideIn(index: 3, child: Text('Tercatat'))),
      ),
    );
    await t.pump();
    final opacity = t.widget<Opacity>(find.ancestor(of: find.text('Tercatat'), matching: find.byType(Opacity)).first);
    expect(opacity.opacity, 1);
  });
}
