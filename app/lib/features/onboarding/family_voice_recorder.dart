import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
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
    final recording = _state == _RecState.recording;
    final status = switch (_state) {
      _RecState.idle => 'Ketuk mikrofon, ucapkan "${word.toLowerCase()}"',
      _RecState.recording => 'Sedang merekam… ketuk lagi untuk berhenti',
      _RecState.recorded => 'Sudah direkam',
      _RecState.denied => 'Izin mikrofon tidak diberikan. Papan tetap memakai suara bawaan.',
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(color: CompanionColors.mint, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          if (_state != _RecState.denied) _MicButton(recording: recording, onTap: recording ? _stop : _start),
          const SizedBox(height: 12),
          Text(word, style: AppText.h2.copyWith(color: CompanionColors.mintText)),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.fade),
            child: Row(
              key: ValueKey(_state),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recording) ...[const RecordingDot(), const SizedBox(width: 6)],
                Flexible(
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: AppText.cap.copyWith(color: CompanionColors.mintText),
                  ),
                ),
              ],
            ),
          ),
          SmoothReveal(
            child: _state != _RecState.recorded
                ? null
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextButton.icon(
                      onPressed: _play,
                      style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: CompanionColors.mintText),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Dengarkan'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tombol mikrofon bulat 72 dp. Saat merekam berubah koral dengan ikon berhenti dan cincin yang mengembang pelan.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.recording, required this.onTap});

  final bool recording;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  void _sync() {
    if (widget.recording && !Motion.reduced(context)) {
      if (!_ring.isAnimating) _ring.repeat();
    } else {
      _ring
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.recording ? 'Berhenti merekam' : 'Rekam',
    excludeSemantics: true,
    child: PressScale(
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: 104,
          height: 104,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _ring,
                builder: (context, _) => Container(
                  width: 72 + 32 * _ring.value,
                  height: 72 + 32 * _ring.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CompanionColors.coral.withValues(alpha: 0.35 * (1 - _ring.value) * (widget.recording ? 1 : 0)),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: Motion.of(context, Motion.fade),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.recording ? CompanionColors.coralDeep : Colors.white,
                  boxShadow: const [BoxShadow(color: Color(0x22038075), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.press),
                  child: Icon(
                    widget.recording ? Icons.stop_rounded : Icons.mic_rounded,
                    key: ValueKey(widget.recording),
                    size: 34,
                    color: widget.recording ? Colors.white : CompanionColors.coralText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
