import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../scene.dart';

class SceneAiException implements Exception {
  const SceneAiException(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class SceneAiResult {
  const SceneAiResult({required this.requestId, required this.model, required this.width, required this.height, required this.hotspots});
  final String requestId;
  final String model;
  final int width;
  final int height;
  final List<DraftHotspot> hotspots;
}

class SceneAiService {
  SceneAiService({required this.baseUrl, required this.token, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final String token;
  final http.Client _client;

  Future<bool> available(String childId) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/v1/children/$childId/scene-ai/status'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body);
      return body is Map && body['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<SceneAiResult> analyze({
    required String childId,
    required List<int> jpegBytes,
    required List<(String, String)> allowedSymbols,
  }) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/v1/children/$childId/scene-ai/analyze'),
            headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'consent': true,
              'image_mime': 'image/jpeg',
              'image_base64': base64Encode(Uint8List.fromList(jpegBytes)),
              'allowed_symbols': [
                for (final (id, label) in allowedSymbols) {'word_id': id, 'label': label},
              ],
            }),
          )
          .timeout(const Duration(seconds: 40));
    } catch (_) {
      throw const SceneAiException('Server belum bisa menganalisis foto. Coba lagi atau atur sendiri.');
    }
    if (response.statusCode != 200) {
      var message = 'Foto belum bisa dianalisis.';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] is String) message = decoded['detail'] as String;
      } catch (_) {}
      throw SceneAiException(message, status: response.statusCode);
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final rows = (body['candidates'] as List).cast<Map>();
      return SceneAiResult(
        requestId: body['request_id'] as String,
        model: body['model'] as String,
        width: body['image_width'] as int,
        height: body['image_height'] as int,
        hotspots: rows.map((raw) {
          final row = Map<String, dynamic>.from(raw);
          return DraftHotspot(
            id: row['id'] as String,
            observedLabel: row['observed_label'] as String?,
            wordId: row['word_id'] as String?,
            box: SceneBox.fromJson(Map<String, Object?>.from(row['box'] as Map)),
          );
        }).toList(),
      );
    } catch (_) {
      throw const SceneAiException('Jawaban server tidak dapat dibaca. Atur area secara manual.');
    }
  }
}
