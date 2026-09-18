import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/features/settings/teacher_pins_screen.dart';
import 'package:nyambung/features/start/teacher_pin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('orang tua membuat PIN guru 3 hari', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TeacherPinStore(await SharedPreferences.getInstance());
    TeacherPin? made;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                made = await Navigator.of(context)
                    .push<TeacherPin>(MaterialPageRoute(builder: (_) => CreateTeacherPinScreen(store: store))),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bu Rina');
    await tester.tap(find.text('3 hari'));
    await tester.pump();
    await tester.tap(find.text('Lanjut, buat PIN'));
    await tester.pumpAndSettle();
    expect(find.text('PIN untuk Bu Rina'), findsOneWidget);

    for (var round = 0; round < 2; round++) {
      for (final d in ['2', '4', '6', '8']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
    }
    await tester.pumpAndSettle();

    expect(made?.name, 'Bu Rina');
    final left = made!.expiresAt!.difference(made!.createdAt);
    expect(left, const Duration(days: 3));
    expect(store.unlock('2468')?.id, made!.id);
  });
}
