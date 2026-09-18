import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/features/start/parent_pin.dart';
import 'package:nyambung/features/start/teacher_pin.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late TeacherPinStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = TeacherPinStore(prefs);
    await ParentPin.set(prefs, '1111');
  });

  test('PIN guru membuka mode guru sampai kedaluwarsa', () async {
    final start = DateTime(2026, 9, 18, 8);
    final pin = await store.create(name: 'Bu Rina', pin: '2468', days: 3, now: start);
    expect(store.unlock('2468', now: start.add(const Duration(days: 2)))?.id, pin.id);
    expect(store.unlock('2468', now: start.add(const Duration(days: 3))), isNull);
    expect(store.unlock('0000', now: start), isNull);
  });

  test('tanpa kedaluwarsa tetap berlaku', () async {
    await store.create(name: 'Pak Budi', pin: '1357', days: null, now: DateTime(2026));
    expect(store.unlock('1357', now: DateTime(2030))?.name, 'Pak Budi');
  });

  test('PIN tidak boleh sama dengan PIN orang tua atau PIN guru aktif', () async {
    expect(store.conflict('1111'), isNotNull);
    await store.create(name: 'Bu Rina', pin: '2468', days: 7);
    expect(store.conflict('2468'), isNotNull);
    expect(store.conflict('9999'), isNull);
    expect(store.conflict('12a4'), isNotNull);
  });

  test('perpanjang menghidupkan lagi, cabut menghapus', () async {
    final pin = await store.create(name: 'Bu Rina', pin: '2468', days: 1, now: DateTime(2020));
    expect(store.unlock('2468'), isNull);
    await store.extend(pin.id, 5);
    expect(store.unlock('2468')?.id, pin.id);
    await store.revoke(pin.id);
    expect(store.unlock('2468'), isNull);
    expect(store.all(), isEmpty);
  });

  test('catatan frasa guru tersimpan terbaru dulu dan bisa dihapus', () async {
    TeacherPhraseLog entry(String id) =>
        TeacherPhraseLog(phraseId: id, pinId: 'p1', teacher: 'Bu Rina', text: 'Jangan nyontek', voice: 'keluarga', at: DateTime(2026));
    await store.addLog(entry('a'));
    await store.addLog(entry('b'));
    expect(store.log().map((e) => e.phraseId), ['b', 'a']);
    await store.removeLog('b');
    expect(store.log().map((e) => e.phraseId), ['a']);
  });
}
