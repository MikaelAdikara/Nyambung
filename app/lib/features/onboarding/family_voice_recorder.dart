import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../coach/companion_widgets.dart';

/// Rekaman suara keluarga untuk satu kata (A5). Hanya merekam selama tombol rekam aktif, disimpan di
/// folder aplikasi, dan tidak pernah disinkronkan (invarian 17 dan 18). Dipakai `SpeechService` saat
/// ketukan pendamping.
class FamilyVoiceRecorder extends StatefulWidget {
  const FamilyVoiceRecorder({super.key, this.wordId = 'mau', required this.onRecorded});

  final String wordId;

  /// Dipanggil dengan jalur berkas setelah rekaman selesai (belum disimpan ke simbol).
  final ValueChanged<String?> onRecorded;

  @override
  State<FamilyVoiceRecorder> createState() => _FamilyVoiceRecorderState();
}

enum _RecState { idle, recording, recorded, denied }

class _FamilyVoiceRecorderState extends State<FamilyVoiceRecorder> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  _RecState _state = _RecState.idle;
  String? _path;

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _state = _RecState.denied);
        return;
      }
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}family');
      await dir.create(recursive: true);
      final path = '${dir.path}${Platform.pathSeparator}${widget.wordId}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1), path: path);
      setState(() => _state = _RecState.recording);
    } catch (e, st) {
      ErrorLog.record('rekam:start', e, st);
      setState(() => _state = _RecState.denied);
    }
  }

  Future<void> _stop() async {
    try {
      _path = await _recorder.stop();
    } catch (e, st) {
      ErrorLog.record('rekam:stop', e, st);
    }
    setState(() => _state = _path == null ? _RecState.idle : _RecState.recorded);
    widget.onRecorded(_path);
  }

  Future<void> _play() async {
    final path = _path;
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e, st) {
      ErrorLog.record('rekam:putar', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = AppScope.of(context).symbolById(widget.wordId)?.labelDisplay ?? widget.wordId.toUpperCase();
    return CompanionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ucapkan "${word.toLowerCase()}" dengan suara biasa.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (_state == _RecState.denied)
            const Text('Izin mikrofon tidak diberikan. Tidak apa-apa; papan tetap memakai suara bawaan.', style: companionMutedStyle)
          else
            Row(
              children: [
                Expanded(
                  child: _state == _RecState.recording
                      ? FilledButton.icon(onPressed: _stop, icon: const Icon(Icons.stop), label: const Text('Berhenti'))
                      : OutlinedButton.icon(
                          onPressed: _start,
                          icon: const Icon(Icons.mic),
                          label: Text(_state == _RecState.recorded ? 'Ulangi' : 'Rekam'),
                        ),
                ),
                if (_state == _RecState.recorded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(onPressed: _play, icon: const Icon(Icons.play_arrow), label: const Text('Dengarkan')),
                  ),
                ],
              ],
            ),
          if (_state == _RecState.recording) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                RecordingDot(),
                SizedBox(width: 6),
                Text('Sedang merekam…', style: companionMutedStyle),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
