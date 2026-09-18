import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/error_log.dart';
import '../phrase.dart';
import 'sync_service.dart';

/// Status suara di server untuk anak ini.
class VoiceStatus {
  const VoiceStatus({required this.openai, required this.elevenlabs, required this.cloneActive, this.cloneConsentBy, this.cloneConsentAt});

  /// Suara papan (OpenAI) untuk frasa baru sudah aktif di server.
  final bool openai;

  /// Klon suara keluarga (ElevenLabs) sudah aktif di server.
  final bool elevenlabs;
  final bool cloneActive;
  final String? cloneConsentBy;
  final String? cloneConsentAt;

  factory VoiceStatus.fromJson(Map<String, dynamic> j) => VoiceStatus(
    openai: j['openai'] == true,
    elevenlabs: j['elevenlabs'] == true,
    cloneActive: j['clone_active'] == true,
    cloneConsentBy: j['clone_consent_by'] as String?,
    cloneConsentAt: j['clone_consent_at'] as String?,
  );
}

/// Gagal menghubungi server atau server menolak. [message] siap ditampilkan ke orang tua.
class PhraseException implements Exception {
  const PhraseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Frasa bersuara dan klon suara keluarga. Semua panggilan butuh jaringan dan tautan terapis aktif; papan sendiri
/// tidak pernah menunggu layanan ini (klip diunduh ke folder aplikasi, lalu diputar luring).
class PhraseService {
  PhraseService(this.app, {http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 12);

  /// Membuat suara (OpenAI/ElevenLabs) bisa butuh beberapa detik; unggah sampel klon lebih lama.
  static const _generateTimeout = Duration(seconds: 60);

  final AppState app;
  final http.Client _client;

  String get _base => SyncService.serverBaseUrl(app);

  Future<(String, String)> _auth() async {
    final child = app.child;
    final token = app.prefs.getString(PrefKeys.deviceToken);
    if (child == null || token == null || token.isEmpty || await app.linkDao.active() == null) {
      throw const PhraseException('Frasa baru butuh sambungan ke terapis. Sambungkan dulu di Pengaturan.');
    }
    return (child.childId, token);
  }

  Map<String, String> _headers(String token, {bool json = false}) => {
    'Authorization': 'Bearer $token',
    if (json) 'Content-Type': 'application/json; charset=utf-8',
  };

  PhraseException _fail(http.Response r) {
    String? detail;
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['detail'] is String) detail = body['detail'] as String;
    } catch (_) {}
    return switch (r.statusCode) {
      401 => const PhraseException('Sambungan ke terapis sudah dicabut.'),
      409 => const PhraseException('Suara keluarga belum diaktifkan.'),
      429 => PhraseException(detail ?? 'Terlalu banyak frasa hari ini. Coba lagi besok.'),
      503 => PhraseException(detail ?? 'Layanan suara belum aktif di server.'),
      _ => PhraseException(detail ?? 'Server menolak permintaan (${r.statusCode}).'),
    };
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PhraseException {
      rethrow;
    } catch (e, st) {
      ErrorLog.record('frasa', e, st);
      throw const PhraseException('Tidak tersambung ke server. Frasa yang sudah ada tetap bisa dipakai tanpa internet.');
    }
  }

  Future<VoiceStatus> status() => _guard(() async {
    final (childId, token) = await _auth();
    final r = await _client.get(Uri.parse('$_base/v1/children/$childId/voice'), headers: _headers(token)).timeout(_timeout);
    if (r.statusCode != 200) throw _fail(r);
    return VoiceStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  });

  /// Buat frasa milik keluarga, unduh klipnya, simpan lokal. Belum ditaruh di papan.
  Future<Phrase> create(String text, String voice) => _guard(() async {
    final (childId, token) = await _auth();
    final r = await _client
        .post(
          Uri.parse('$_base/v1/children/$childId/phrases'),
          headers: _headers(token, json: true),
          body: jsonEncode({'text': normalizePhraseText(text), 'voice': voice}),
        )
        .timeout(_generateTimeout);
    if (r.statusCode != 201) throw _fail(r);
    final phrase = Phrase.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    await app.phraseDao.upsertFromServer(phrase);
    final path = await _download(childId, token, phrase);
    return Phrase(
      phraseId: phrase.phraseId,
      text: phrase.text,
      voice: phrase.voice,
      createdBy: phrase.createdBy,
      createdAt: phrase.createdAt,
      status: phrase.status,
      audioPath: path,
    );
  });

  /// Aktifkan klon suara keluarga. [samples] = berkas rekaman di perangkat; dikirim sekali ke server yang
  /// meneruskannya ke ElevenLabs tanpa menyimpannya. Berkas lokal dihapus pemanggil setelah berhasil.
  Future<VoiceStatus> clone({required String consentBy, required List<String> samples}) => _guard(() async {
    final (childId, token) = await _auth();
    final encoded = [
      for (var i = 0; i < samples.length; i++)
        {'filename': 'contoh-${i + 1}.m4a', 'data_b64': base64Encode(await File(samples[i]).readAsBytes())},
    ];
    final r = await _client
        .post(
          Uri.parse('$_base/v1/children/$childId/voice/clone'),
          headers: _headers(token, json: true),
          body: jsonEncode({'consent': true, 'consent_by': consentBy, 'samples': encoded}),
        )
        .timeout(const Duration(seconds: 150));
    if (r.statusCode != 200) throw _fail(r);
    return VoiceStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  });

  /// Cabut klon suara keluarga: dihapus di ElevenLabs dan server. Kartu frasa yang sudah ada di papan tetap.
  Future<VoiceStatus> revokeClone() => _guard(() async {
    final (childId, token) = await _auth();
    final r = await _client.delete(Uri.parse('$_base/v1/children/$childId/voice/clone'), headers: _headers(token)).timeout(_timeout);
    if (r.statusCode != 200) throw _fail(r);
    return VoiceStatus.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  });

  /// Dipanggil saat sinkron: tarik daftar frasa, unduh klip yang belum ada. Terbaik-usaha, tidak pernah melempar.
  Future<void> pull(String childId) async {
    final token = app.prefs.getString(PrefKeys.deviceToken);
    if (token == null || token.isEmpty || await app.linkDao.active() == null) return;
    try {
      final r = await _client.get(Uri.parse('$_base/v1/children/$childId/phrases'), headers: _headers(token)).timeout(_timeout);
      if (r.statusCode != 200) return;
      for (final raw in jsonDecode(r.body) as List<dynamic>) {
        await app.phraseDao.upsertFromServer(Phrase.fromJson(raw as Map<String, dynamic>));
      }
      for (final p in await app.phraseDao.all()) {
        if (p.audioPath == null && p.status != PhraseStatus.ditolak) await _download(childId, token, p);
      }
      app.markDataChanged();
    } catch (e, st) {
      ErrorLog.record('frasa:tarik', e, st);
    }
  }

  /// Unduh klip ke `phrases/<phrase_id>.mp3`, catat di DB, dan perbarui kartu papan bila sudah ada.
  Future<String> _download(String childId, String token, Phrase p) async {
    final r = await _client
        .get(Uri.parse('$_base/v1/children/$childId/phrases/${p.phraseId}/audio'), headers: _headers(token))
        .timeout(_generateTimeout);
    if (r.statusCode != 200 || r.bodyBytes.length < 100) throw _fail(r);
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}phrases');
    await dir.create(recursive: true);
    final path = '${dir.path}${Platform.pathSeparator}${p.phraseId}.mp3';
    await File(path).writeAsBytes(r.bodyBytes, flush: true);
    await app.phraseDao.setAudio(p.phraseId, path);
    if (app.symbolById(p.wordId) != null) {
      await app.symbolDao.setAudioPath(p.wordId, path);
      await app.reloadSymbols();
    }
    return path;
  }
}
