import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/features/onboarding/therapist_entry.dart';

void main() {
  test('alamat papan pantau memakai host server, port 5173', () {
    expect(dashboardUrlFor('http://192.168.1.20:8000'), 'http://192.168.1.20:5173');
    expect(dashboardUrlFor(' http://10.0.2.2:8000/ '), 'http://10.0.2.2:5173');
  });

  test('server belum diatur atau rusak → alamat bawaan', () {
    expect(dashboardUrlFor(null), 'http://127.0.0.1:5173');
    expect(dashboardUrlFor(''), 'http://127.0.0.1:5173');
    expect(dashboardUrlFor('bukan alamat'), 'http://127.0.0.1:5173');
  });
}
