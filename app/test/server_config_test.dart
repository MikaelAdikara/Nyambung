import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/constants.dart';

void main() {
  test('tanpa isian di Atur → alamat bawaan build', () {
    expect(ServerConfig.resolve(null), ServerConfig.defaultUrl);
    expect(ServerConfig.resolve('   '), ServerConfig.defaultUrl);
  });

  test('isian di Atur menimpa bawaan dan dirapikan', () {
    expect(ServerConfig.resolve(' http://192.168.1.20:8000/ '), 'http://192.168.1.20:8000');
    expect(ServerConfig.resolve('http://localhost:8000'), 'http://127.0.0.1:8000');
    expect(ServerConfig.resolve('https://api.nyambung.id'), 'https://api.nyambung.id');
  });
}
