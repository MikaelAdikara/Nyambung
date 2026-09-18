import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/models.dart';
import 'constants.dart';
import 'error_log.dart';

/// Dua suara (00-rencana §2):
/// - ketukan **anak**: audio bundel `{word_id}.ogg` bila ada → TTS id-ID nada 1,3;
/// - ketukan **pendamping**: rekaman keluarga bila ada → audio bundel → TTS nada 1,0.
///
/// Setiap panggilan plugin diberi batas waktu. Pada ROM tanpa mesin TTS, papan tetap terbuka tanpa suara.
class SpeechService {
  SpeechService({FlutterTts? tts, AudioPlayer? player}) : _ttsOverride = tts, _playerOverride = player;

  static const childPitch = 1.3;
  static const parentPitch = 1.0;
  static const language = 'id-ID';

  final FlutterTts? _ttsOverride;
  final AudioPlayer? _playerOverride;
  FlutterTts? _tts;
  AudioPlayer? _player;
  Set<String> _bundledAssets = const {};

  /// Mesin TTS menyediakan Bahasa Indonesia. Ditampilkan di C6 "Uji suara".
  bool ttsIdAvailable = false;

  /// Latensi ucapan pertama (ms), dari panggilan `speak` sampai TTS mulai bicara. Ditampilkan di C6.
  int? firstUtteranceLatencyMs;

  bool _ready = false;
  bool get isReady => _ready;
  Stopwatch? _pendingLatency;

  Future<T?> _guard<T>(String what, Future<T> Function() call) async {
    try {
      return await call().timeout(Limits.pluginTimeout);
    } catch (e, st) {
      ErrorLog.record('tts:$what', e, st);
      return null;
    }
  }

  /// Dipanggil sekali saat bootstrap. Tidak pernah melempar dan tidak pernah menggantung > ±12 detik.
  Future<void> init() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle).timeout(Limits.pluginTimeout);
      _bundledAssets = manifest.listAssets().where((a) => a.startsWith('assets/audio/')).toSet();
    } catch (e, st) {
      ErrorLog.record('speech:manifest', e, st);
    }
    try {
      _player = _playerOverride ?? AudioPlayer();
      final tts = _ttsOverride ?? FlutterTts();
      _tts = tts;
      final available = await _guard('isLanguageAvailable', () => tts.isLanguageAvailable(language));
      ttsIdAvailable = available == true;
      if (!ttsIdAvailable) {
        final langs = await _guard('getLanguages', () => tts.getLanguages);
        ttsIdAvailable = langs is List && langs.any((l) => l.toString().toLowerCase().replaceAll('_', '-') == 'id-id');
      }
      await _guard('setLanguage', () => tts.setLanguage(language));
      await _guard('awaitSpeakCompletion', () => tts.awaitSpeakCompletion(false));
      tts.setStartHandler(() {
        final sw = _pendingLatency;
        if (sw != null) {
          firstUtteranceLatencyMs ??= sw.elapsedMilliseconds;
          _pendingLatency = null;
        }
      });
      _ready = true;
    } catch (e, st) {
      ErrorLog.record('speech:init', e, st);
    }
  }

  bool _hasBundled(String? path) => path != null && _bundledAssets.contains(path);

  String _bundledFor(WordSymbol s) => s.audioPath ?? 'assets/audio/core/${s.wordId}.ogg';

  /// Hentikan ucapan sebelumnya sebelum mulai yang baru.
  Future<void> stop() async {
    await _guard('stop', () => _tts?.stop() ?? Future.value());
    try {
      await _player?.stop().timeout(Limits.pluginTimeout);
    } catch (_) {}
  }

  /// Bunyikan satu kata sesuai siapa yang menekan.
  Future<void> speakWord(WordSymbol s, {required bool byParent}) async {
    await stop();
    try {
      if (byParent && s.familyAudio != null) {
        await _player?.play(DeviceFileSource(s.familyAudio!)).timeout(Limits.pluginTimeout);
        return;
      }
      final bundled = _bundledFor(s);
      if (_hasBundled(bundled)) {
        await _player?.play(AssetSource(bundled.substring('assets/'.length))).timeout(Limits.pluginTimeout);
        return;
      }
    } catch (e, st) {
      ErrorLog.record('speech:audio', e, st);
    }
    await speakText(s.labelSpeech, byParent: byParent, stopFirst: false);
  }

  /// Bunyikan teks lewat TTS dengan nada anak (1,3) atau pendamping (1,0).
  Future<void> speakText(String text, {required bool byParent, bool stopFirst = true}) async {
    final tts = _tts;
    if (tts == null || text.trim().isEmpty) return;
    if (stopFirst) await stop();
    await _guard('setPitch', () => tts.setPitch(byParent ? parentPitch : childPitch));
    if (firstUtteranceLatencyMs == null) _pendingLatency = Stopwatch()..start();
    await _guard('speak', () => tts.speak(text));
  }

  /// UCAPKAN: bunyikan rangkaian kata di bilah ujaran sebagai satu kalimat.
  Future<void> speakSentence(List<WordSymbol> words, {required bool byParent}) =>
      speakText(words.map((w) => w.labelSpeech).join(' '), byParent: byParent);

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
  }
}
