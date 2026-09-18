import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nyambung/data/sync/scene_ai_service.dart';

void main() {
  test('scene AI client mengirim token, consent, inventaris dan membaca kandidat', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'request_id': 'r1',
          'provider': 'google',
          'model': 'fake',
          'image_width': 100,
          'image_height': 50,
          'candidates': [
            {
              'id': 'h1',
              'observed_label': 'mobil',
              'word_id': 'mobil',
              'box': {'x': 0.1, 'y': 0.2, 'width': 0.3, 'height': 0.4},
            },
          ],
          'warnings': [],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = SceneAiService(baseUrl: 'http://server', token: 'tok', client: client);
    final result = await service.analyze(childId: 'c1', jpegBytes: [1, 2, 3], allowedSymbols: const [('mobil', 'MOBIL')]);

    expect(captured.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(captured.body)['consent'], isTrue);
    expect(result.hotspots.single.wordId, 'mobil');
    expect(result.width, 100);
  });

  test('scene AI client menerjemahkan error server tanpa membocorkan payload', () async {
    final client = MockClient((_) async => http.Response('{"detail":"batas analisis foto harian tercapai"}', 429));
    final service = SceneAiService(baseUrl: 'http://server', token: 'tok', client: client);
    await expectLater(
      service.analyze(childId: 'c1', jpegBytes: [1, 2, 3], allowedSymbols: const [('mobil', 'MOBIL')]),
      throwsA(isA<SceneAiException>().having((e) => e.message, 'message', contains('batas analisis'))),
    );
  });
}
