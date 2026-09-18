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
/// Audio bundel ada dua set suara sintetis (`assets/audio/core/cowo/`, `.../cewe/`), dipilih lewat [voiceSet].
/// Berkas di `assets/audio/core/{word_id}.ogg` (kontrak §6) tetap dipakai bila set terpilih tidak punya kata itu.
///
/// Klip kata tunggal diputar lewat pemutar latensi rendah (SoundPool) yang disimpan per klip, supaya ketukan
/// berikutnya pada kata yang sama tidak menunggu MediaPlayer menyiapkan berkas. Kata inti dimuat sejak awal.
///
/// Setiap panggilan plugin diberi batas waktu. Pada ROM tanpa mesin TTS, papan tetap terbuka tanpa suara.
class SpeechService {
  SpeechService({FlutterTts? tts, AudioPlayer? player}) : _ttsOverride = tts, _playerOverride = player;

  static const childPitch = 1.3;
  static const parentPitch = 1.0;
  static const language = 'id-ID';
  static const voiceSets = ['cowo', 'cewe'];

  final FlutterTts? _ttsOverride;
  final AudioPlayer? _playerOverride;
  FlutterTts? _tts;
  AudioPlayer? _player;
  Set<String> _bundledAssets = const {};

  /// Pemutar SoundPool per aset klip, urut pemakaian terakhir (yang paling lama tidak dipakai di depan).
  final _clipPlayers = <String, AudioPlayer>{};

  /// Batas pemutar klip yang dimuat. Satu klip ± 1 detik PCM (± 90 KB); 40 klip tetap ringan di RAM 2 GB.
  static const maxClipPlayers = 40;
  AudioPlayer? _activeClip;

  /// Pemutar utama (MediaPlayer) atau TTS mungkin sedang berbunyi; hanya dihentikan bila perlu.
  bool _mainBusy = false;

  /// Set suara audio bundel: `cowo` atau `cewe`.
  String voiceSet = voiceSets.first;

  /// Naik setiap [stop]; rangkaian UCAPKAN yang sedang berjalan berhenti bila nilainya berubah.
  int _generation = 0;

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

  /// Aset audio bundel untuk kata ini, atau null bila tidak ada (lalu jatuh ke TTS).
  String? _bundledFor(WordSymbol s) {
    for (final path in [s.audioPath, 'assets/audio/core/$voiceSet/${s.wordId}.ogg', 'assets/audio/core/${s.wordId}.ogg']) {
      if (path != null && _bundledAssets.contains(path)) return path;
    }
    return null;
  }

  Source? _sourceFor(WordSymbol s, {required bool byParent}) {
    if (byParent && s.familyAudio != null) return DeviceFileSource(s.familyAudio!);
    final bundled = _bundledFor(s);
    return bundled == null ? null : AssetSource(bundled.substring('assets/'.length));
  }

  /// Hentikan ucapan sebelumnya sebelum mulai yang baru.
  Future<void> stop() async {
    _generation++;
    final clip = _activeClip;
    _activeClip = null;
    final mainBusy = _mainBusy;
    _mainBusy = false;
    await Future.wait([
      if (clip != null) _quiet(clip.stop),
      if (mainBusy) _guard('stop', () => _tts?.stop() ?? Future.value()),
      if (mainBusy && _player != null) _quiet(_player!.stop),
    ]);
  }

  Future<void> _quiet(Future<void> Function() call) async {
    try {
      await call().timeout(Limits.pluginTimeout);
    } catch (_) {}
  }

  /// Bunyikan satu kata sesuai siapa yang menekan.
  Future<void> speakWord(WordSymbol s, {required bool byParent}) async {
    final family = byParent ? s.familyAudio : null;
    final bundled = family == null ? _bundledFor(s) : null;
    if (bundled != null) {
      // Jalur cepat: hentikan bunyi sebelumnya tanpa menunggu, lalu putar klip yang sudah dimuat.
      unawaited(stop());
      try {
        final clip = await _clipPlayer(bundled);
        if (clip != null) {
          _activeClip = clip;
          await clip.resume().timeout(Limits.pluginTimeout);
          return;
        }
      } catch (e, st) {
        ErrorLog.record('speech:clip', e, st);
      }
    }
    await stop();
    try {
      if (family != null) {
        _mainBusy = true;
        await _player?.play(DeviceFileSource(family)).timeout(Limits.pluginTimeout);
        return;
      }
    } catch (e, st) {
      ErrorLog.record('speech:audio', e, st);
    }
    await speakText(s.labelSpeech, byParent: byParent, stopFirst: false);
  }

  /// Pemutar SoundPool untuk satu aset klip; dibuat dan dimuat sekali, lalu dipakai ulang.
  Future<AudioPlayer?> _clipPlayer(String asset) async {
    final cached = _clipPlayers.remove(asset);
    if (cached != null) {
      _clipPlayers[asset] = cached;
      return cached;
    }
    if (_player == null) return null;
    final p = AudioPlayer();
    try {
      await p.setPlayerMode(PlayerMode.lowLatency).timeout(Limits.pluginTimeout);
      await p.setReleaseMode(ReleaseMode.stop).timeout(Limits.pluginTimeout);
      await p.setSource(AssetSource(asset.substring('assets/'.length))).timeout(Limits.pluginTimeout);
    } catch (e) {
      unawaited(p.dispose());
      rethrow;
    }
    // Pemanggil lain mungkin memuat aset yang sama bersamaan; simpan satu saja.
    final raced = _clipPlayers.remove(asset);
    if (raced != null) {
      unawaited(p.dispose());
      _clipPlayers[asset] = raced;
      return raced;
    }
    _clipPlayers[asset] = p;
    while (_clipPlayers.length > maxClipPlayers) {
      final oldest = _clipPlayers.keys.first;
      final evicted = _clipPlayers.remove(oldest)!;
      if (evicted != _activeClip) unawaited(evicted.dispose());
    }
    return p;
  }

  /// Muat klip kata-kata ini sebelum diketuk (kata inti saat bootstrap, halaman kategori saat dibuka).
  /// Berurutan dan diam-diam: gagal memuat berarti ketukan nanti memuat sendiri.
  Future<void> preload(Iterable<WordSymbol?> words) async {
    for (final w in words) {
      if (w == null) continue;
      final asset = _bundledFor(w);
      if (asset == null || _clipPlayers.containsKey(asset)) continue;
      try {
        await _clipPlayer(asset);
      } catch (e, st) {
        ErrorLog.record('speech:preload', e, st);
        return;
      }
    }
  }

  /// Bunyikan teks lewat TTS dengan nada anak (1,3) atau pendamping (1,0).
  Future<void> speakText(String text, {required bool byParent, bool stopFirst = true}) async {
    final tts = _tts;
    if (tts == null || text.trim().isEmpty) return;
    if (stopFirst) await stop();
    _mainBusy = true;
    await _guard('setPitch', () => tts.setPitch(byParent ? parentPitch : childPitch));
    if (firstUtteranceLatencyMs == null) _pendingLatency = Stopwatch()..start();
    await _guard('speak', () => tts.speak(text));
  }

  /// UCAPKAN: putar klip setiap kata berurutan dengan suara yang sama seperti saat diketuk.
  /// Bila ada kata tanpa klip, seluruh kalimat dibunyikan lewat TTS supaya tidak berganti suara di tengah.
  Future<void> speakSentence(List<WordSymbol> words, {required bool byParent}) async {
    await stop();
    final player = _player;
    final sources = [for (final w in words) _sourceFor(w, byParent: byParent)];
    if (player == null || sources.contains(null)) {
      await speakText(words.map((w) => w.labelSpeech).join(' '), byParent: byParent, stopFirst: false);
      return;
    }
    final generation = _generation;
    _mainBusy = true;
    try {
      for (final source in sources) {
        if (generation != _generation) return;
        final done = player.onPlayerComplete.first;
        await player.play(source!).timeout(Limits.pluginTimeout);
        try {
          await done.timeout(Limits.clipTimeout);
        } on TimeoutException {
          // Klip dihentikan (ketukan baru) atau tidak melapor selesai; lanjut atau berhenti lewat pemeriksaan generasi.
        }
      }
    } catch (e, st) {
      ErrorLog.record('speech:sentence', e, st);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _player?.dispose();
    for (final p in _clipPlayers.values) {
      await p.dispose();
    }
    _clipPlayers.clear();
  }
}
