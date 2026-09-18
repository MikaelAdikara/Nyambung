import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';

/// C4 Suara keluarga: daftar 12 kata inti (halaman 0) dengan status rekaman. Satu perekam dan satu pemutar
/// untuk seluruh layar. Rekaman disimpan di folder aplikasi `family/` dan tidak pernah dikirim (invarian 17, 18).
class FamilyVoiceScreen extends StatefulWidget {
  const FamilyVoiceScreen({super.key});

  @override
  State<FamilyVoiceScreen> createState() => _FamilyVoiceScreenState();
}

class _FamilyVoiceScreenState extends State<FamilyVoiceScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  late AppState _app;

  /// Kata yang sedang direkam, atau null.
  String? _recording;
  bool _denied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start(WordSymbol s) async {
    try {
      await _player.stop();
      if (!await _recorder.hasPermission()) {
        setState(() => _denied = true);
        return;
      }
      final dir = Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}family');
      await dir.create(recursive: true);
      // Berkas baru per rekaman supaya pemutar tidak memakai salinan lama dari cache.
      final path = '${dir.path}${Platform.pathSeparator}${s.wordId}-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1), path: path);
      setState(() => _recording = s.wordId);
    } catch (e, st) {
      ErrorLog.record('c4:rekam', e, st);
      setState(() => _denied = true);
    }
  }

  Future<void> _stop(WordSymbol s) async {
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e, st) {
      ErrorLog.record('c4:berhenti', e, st);
    }
    if (path != null) {
      final old = s.familyAudio;
      await _app.symbolDao.setFamilyAudio(s.wordId, path);
      await _app.reloadSymbols();
      if (old != null && old != path) _deleteFile(old);
    }
    if (mounted) setState(() => _recording = null);
  }

  Future<void> _play(WordSymbol s) async {
    final path = s.familyAudio;
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e, st) {
      ErrorLog.record('c4:putar', e, st);
    }
  }

  Future<void> _remove(WordSymbol s) async {
    final path = s.familyAudio;
    await _app.symbolDao.setFamilyAudio(s.wordId, null);
    await _app.reloadSymbols();
    if (path != null) _deleteFile(path);
    if (mounted) setState(() {});
  }

  void _deleteFile(String path) {
    try {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    } catch (e, st) {
      ErrorLog.record('c4:hapus', e, st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _app.symbolsForPage(0);
    return CompanionPage(
      title: 'Suara keluarga',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'Suara ini dipakai saat Ibu atau Ayah memberi contoh di papan, supaya anak mendengar orang yang dikenalnya. '
            'Saat anak sendiri yang menekan, papan bicara dengan suara anak, karena itu suaranya.',
            style: companionBodyStyle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Rekaman tersimpan di perangkat ini saja dan tidak pernah dikirim ke siapa pun, termasuk terapis.',
            style: companionMutedStyle,
          ),
          if (_denied) ...[
            const SizedBox(height: 12),
            const Text('Izin mikrofon tidak diberikan. Tidak apa-apa; papan tetap memakai suara bawaan.', style: companionMutedStyle),
          ],
          const SizedBox(height: 16),
          for (final s in words) ...[_row(s), const SizedBox(height: 8)],
        ],
      ),
    );
  }

  Widget _row(WordSymbol s) {
    final recordingThis = _recording == s.wordId;
    final busyOther = _recording != null && !recordingThis;
    final hasVoice = s.familyAudio != null;
    return CompanionCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image(image: symbolImage(s.symbolPath), width: 40, height: 40, errorBuilder: (_, _, _) => const SizedBox(width: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.labelDisplay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              if (recordingThis) ...[const RecordingDot(), const SizedBox(width: 6)],
              Text(
                recordingThis
                    ? 'Sedang merekam…'
                    : hasVoice
                    ? 'Suara keluarga'
                    : 'Suara papan',
                style: companionMutedStyle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              recordingThis
                  ? FilledButton.icon(onPressed: () => _stop(s), icon: const Icon(Icons.stop), label: const Text('Berhenti'))
                  : OutlinedButton.icon(
                      onPressed: busyOther ? null : () => _start(s),
                      icon: const Icon(Icons.mic),
                      label: Text(hasVoice ? 'Ulangi' : 'Rekam'),
                    ),
              if (hasVoice && !recordingThis) ...[
                OutlinedButton.icon(
                  onPressed: busyOther ? null : () => _play(s),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Dengarkan'),
                ),
                TextButton(onPressed: busyOther ? null : () => _remove(s), child: const Text('Hapus rekaman')),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
