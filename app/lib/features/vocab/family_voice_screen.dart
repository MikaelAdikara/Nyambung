import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/phrase.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';

/// C4 Suara keluarga: daftar 12 kata inti (halaman 0) dan kartu personal (C3) dengan status rekaman. Satu perekam
/// dan satu pemutar untuk seluruh layar. Rekaman disimpan di folder aplikasi `family/` dan tidak pernah dikirim
/// (invarian 17, 18).
class FamilyVoiceScreen extends StatefulWidget {
  const FamilyVoiceScreen({super.key, this.showPersonal = false});

  /// Dibuka dari C3 setelah kartu tersimpan: kartu personal ditaruh paling atas.
  final bool showPersonal;

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
    final core = _app.symbolsForPage(0);
    final personal = _app.allSymbols.where((s) => s.isCustom && !s.isHidden && !isPhraseWordId(s.wordId)).toList();
    final all = [...core, ...personal];
    final recorded = all.where((s) => s.familyAudio != null).length;
    final sections = [
      if (widget.showPersonal && personal.isNotEmpty) ('Kartu personal', personal),
      ('Kata inti', core),
      if (!widget.showPersonal && personal.isNotEmpty) ('Kartu personal', personal),
    ];
    return CompanionPage(
      title: 'Suara keluarga',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          CompanionCard(
            color: CompanionColors.coralTint,
            borderColor: CompanionColors.coralTint,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              '$recorded dari ${all.length} kata memakai suara keluarga saat Ibu atau Ayah memberi contoh.',
              style: AppText.body.copyWith(fontSize: 15, color: CompanionColors.coralText),
            ),
          ),
          SmoothReveal(
            child: !_denied
                ? null
                : const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Izin mikrofon tidak diberikan. Papan tetap memakai suara bawaan.', style: companionMutedStyle),
                  ),
          ),
          for (final (title, words) in sections) ...[
            const SizedBox(height: 18),
            Eyebrow(title),
            const SizedBox(height: 8),
            for (final s in words) ...[_row(s), const SizedBox(height: 8)],
          ],
        ],
      ),
    );
  }

  Widget _row(WordSymbol s) {
    final recordingThis = _recording == s.wordId;
    final busyOther = _recording != null && !recordingThis;
    final hasVoice = s.familyAudio != null;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.fade),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: recordingThis ? CompanionColors.coralTint : CompanionColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: recordingThis ? CompanionColors.coral : CompanionColors.line, width: recordingThis ? 2 : 1),
      ),
      child: Row(
        children: [
          Image(image: symbolImage(s.symbolPath), width: 36, height: 36, errorBuilder: (_, _, _) => const SizedBox(width: 36)),
          const SizedBox(width: 12),
          Expanded(child: Text(s.labelDisplay, style: AppText.bodyStrong)),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.fade),
            child: recordingThis
                ? const Row(
                    key: ValueKey('rekam'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RecordingDot(),
                      SizedBox(width: 6),
                      Text('Merekam', style: AppText.cap),
                    ],
                  )
                : hasVoice
                ? Container(
                    key: const ValueKey('ada'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: CompanionColors.tealTint, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      'Terekam',
                      style: AppText.cap.copyWith(color: CompanionColors.tealText, fontWeight: FontWeight.w800),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('kosong')),
          ),
          if (hasVoice && !recordingThis) ...[
            _SmallIcon(icon: Icons.play_arrow_rounded, tooltip: 'Dengarkan', onTap: busyOther ? null : () => _play(s)),
            _SmallIcon(icon: Icons.delete_outline_rounded, tooltip: 'Hapus rekaman', onTap: busyOther ? null : () => _remove(s)),
          ],
          _SmallIcon(
            icon: recordingThis ? Icons.stop_rounded : Icons.mic_rounded,
            tooltip: recordingThis ? 'Berhenti' : (hasVoice ? 'Rekam ulang' : 'Rekam'),
            filled: true,
            onTap: busyOther ? null : (recordingThis ? () => _stop(s) : () => _start(s)),
          ),
        ],
      ),
    );
  }
}

/// Tombol ikon bulat 44 dp di baris rekaman. [filled] = tombol mikrofon koral.
class _SmallIcon extends StatelessWidget {
  const _SmallIcon({required this.icon, required this.tooltip, required this.onTap, this.filled = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: PressScale(
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedOpacity(
              opacity: onTap == null ? 0.4 : 1,
              duration: Motion.of(context, Motion.fade),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: filled ? CompanionColors.coralTint : CompanionColors.sand, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: filled ? CompanionColors.coralText : CompanionColors.tealText),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
