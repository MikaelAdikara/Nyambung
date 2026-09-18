import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/theme.dart';
import '../../data/sync/phrase_service.dart';
import '../coach/companion_widgets.dart';

/// Naskah contoh untuk klon suara: kalimat sehari-hari, ± 15 detik dibaca santai.
const cloneScripts = [
  'Selamat pagi, Nak. Ayo kita bangun, cuci muka, lalu sarapan bersama. Hari ini kita mau main di taman, ya.',
  'Pelan-pelan saja. Kalau butuh bantuan, bilang tolong. Kalau sudah selesai, bilang selesai. Ibu dan Ayah ada di sini.',
  'Wah, hebat sekali! Kamu mau minum air atau susu? Sekarang kita pakai sepatu dulu, nanti kita pergi ke sekolah.',
];

/// Rekaman terlalu pendek membuat tiruan suara kurang mirip.
const cloneMinSeconds = 8;

/// Klon suara keluarga (ElevenLabs). Hanya berjalan setelah orang tua menyetujui setiap butir dengan sadar.
///
/// Rekaman contoh disimpan sementara di folder cache aplikasi, dikirim sekali ke server yang meneruskannya ke
/// ElevenLabs tanpa menyimpannya, lalu dihapus dari HP, baik berhasil maupun layar ditutup. Orang tua bisa
/// mencabut kapan saja; suara tiruan dihapus di ElevenLabs.
class VoiceCloneScreen extends StatefulWidget {
  const VoiceCloneScreen({super.key});

  @override
  State<VoiceCloneScreen> createState() => _VoiceCloneScreenState();
}

class _VoiceCloneScreenState extends State<VoiceCloneScreen> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _owner = TextEditingController();
  late PhraseService _service;
  bool _started = false;

  VoiceStatus? _status;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  final _consents = List<bool>.filled(4, false);
  final _samples = List<String?>.filled(cloneScripts.length, null);
  int? _recording;
  DateTime? _recordStart;
  String? _sampleNote;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _service = PhraseService(AppScope.of(context));
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    _owner.dispose();
    unawaited(_deleteSamples());
    super.dispose();
  }

  Future<void> _deleteSamples() async {
    for (var i = 0; i < _samples.length; i++) {
      final path = _samples[i];
      _samples[i] = null;
      if (path == null) continue;
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  Future<void> _load() async {
    try {
      final s = await _service.status();
      if (mounted) setState(() => _status = s);
    } on PhraseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleRecord(int i) async {
    if (_recording == i) {
      String? path;
      try {
        path = await _recorder.stop();
      } catch (e, st) {
        ErrorLog.record('klon:berhenti', e, st);
      }
      final secs = _recordStart == null ? 0 : DateTime.now().difference(_recordStart!).inSeconds;
      // Rekaman lama (rekam ulang) atau yang terlalu pendek langsung dihapus dari HP.
      final discard = path != null && secs >= cloneMinSeconds ? _samples[i] : path;
      if (discard != null) unawaited(File(discard).delete().then((_) {}, onError: (_) {}));
      setState(() {
        _recording = null;
        if (path != null && secs >= cloneMinSeconds) {
          _samples[i] = path;
          _sampleNote = null;
        } else {
          _sampleNote = 'Rekaman terlalu pendek. Baca seluruh kalimat dengan santai (minimal $cloneMinSeconds detik).';
        }
      });
      return;
    }
    if (_recording != null) return;
    try {
      await _player.stop();
      if (!await _recorder.hasPermission()) {
        setState(() => _sampleNote = 'Izin mikrofon belum diberikan.');
        return;
      }
      final dir = Directory('${(await getTemporaryDirectory()).path}${Platform.pathSeparator}clone_samples');
      await dir.create(recursive: true);
      final path = '${dir.path}${Platform.pathSeparator}contoh-${i + 1}-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, sampleRate: 44100), path: path);
      setState(() {
        _recording = i;
        _recordStart = DateTime.now();
        _sampleNote = null;
      });
    } catch (e, st) {
      ErrorLog.record('klon:rekam', e, st);
      setState(() => _sampleNote = 'Mikrofon tidak bisa dipakai. Coba lagi.');
    }
  }

  Future<void> _playSample(int i) async {
    final path = _samples[i];
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e, st) {
      ErrorLog.record('klon:putar', e, st);
    }
  }

  bool get _canSubmit =>
      !_busy && _recording == null && _consents.every((c) => c) && _owner.text.trim().isNotEmpty && _samples.every((s) => s != null);

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await _service.clone(consentBy: _owner.text.trim(), samples: _samples.whereType<String>().toList());
      await _deleteSamples();
      if (mounted) setState(() => _status = s);
    } on PhraseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _revoke() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cabut suara keluarga?'),
        content: const Text(
          'Tiruan suara dihapus dari layanan suara dan frasa baru tidak bisa memakainya lagi. '
          'Kartu frasa yang sudah ada di papan tetap bisa diputar dan bisa kamu sembunyikan di Kelola kosakata.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cabut')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final s = await _service.revokeClone();
      if (mounted) setState(() => _status = s);
    } on PhraseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return CompanionPage(
      title: 'Suara keluarga',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (status == null)
            CompanionCard(child: Text(_error ?? 'Tidak tersambung ke server.', style: AppText.body))
          else if (status.cloneActive)
            ..._active(status)
          else if (!status.elevenlabs)
            const CompanionCard(
              child: Text('Tiruan suara keluarga belum aktif di server. Frasa tetap bisa dibuat dengan suara papan.', style: AppText.body),
            )
          else
            ..._setup(),
          if (_error != null && status != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _active(VoiceStatus s) => [
    CompanionCard(
      color: CompanionColors.leafTint,
      borderColor: CompanionColors.leafTint,
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: CompanionColors.leafText, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Suara keluarga aktif. Disetujui oleh ${s.cloneConsentBy ?? 'orang tua'}.',
              style: AppText.bodyStrong.copyWith(color: CompanionColors.leafText),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    const Text(
      'Kamu dan terapis/guru yang tersambung bisa membuat frasa dengan suara ini. Frasa dari mereka selalu datang '
      'sebagai usulan: kamu yang memutuskan masuk ke papan atau tidak.',
      style: AppText.muted,
    ),
    const SizedBox(height: 20),
    EqualOutlineButton(
      label: _busy ? 'Mencabut…' : 'Cabut suara keluarga',
      color: CompanionColors.caution,
      onPressed: _busy ? null : _revoke,
    ),
  ];

  List<Widget> _setup() {
    const items = [
      'Suara yang direkam adalah suaraku sendiri, dan aku setuju suaraku ditiru mesin untuk anakku.',
      'Rekaman contoh dikirim lewat server Nyambung ke ElevenLabs untuk membuat tiruan suara. Server tidak menyimpan rekamannya.',
      'Terapis/guru yang tersambung bisa membuat frasa dengan suara ini. Setiap frasa dari mereka tetap usulan yang boleh kutolak.',
      'Aku bisa mencabut kapan saja, dan tiruan suaranya akan dihapus.',
    ];
    return [
      const Text(
        'Anak sering lebih tenang mendengar suara orang tuanya. Dengan tiruan suara, guru bisa menyampaikan frasa '
        'seperti "Jangan nyontek" dengan suaramu, lewat papan anak.',
        style: AppText.muted,
      ),
      const SizedBox(height: 18),
      const Eyebrow('1 · Persetujuan'),
      const SizedBox(height: 6),
      CompanionCard(
        padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              CheckboxListTile(
                value: _consents[i],
                onChanged: (v) => setState(() => _consents[i] = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(items[i], style: AppText.body.copyWith(fontSize: 15)),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _owner,
        maxLength: 60,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Pemilik suara (mis. Ibu, Ayah)', border: OutlineInputBorder()),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      const Eyebrow('2 · Baca tiga kalimat'),
      const SizedBox(height: 6),
      const Text('Di ruangan yang tenang, suara biasa, tidak terburu-buru.', style: AppText.cap),
      const SizedBox(height: 8),
      for (var i = 0; i < cloneScripts.length; i++) ...[_sampleCard(i), const SizedBox(height: 10)],
      if (_sampleNote != null)
        Text(
          _sampleNote!,
          style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
        ),
      const SizedBox(height: 12),
      const Eyebrow('3 · Aktifkan'),
      const SizedBox(height: 8),
      PrimaryButton(
        label: _busy ? 'Membuat tiruan suara…' : 'Aktifkan suara keluarga',
        icon: Icons.record_voice_over_rounded,
        onPressed: _canSubmit ? _submit : null,
      ),
    ];
  }

  Widget _sampleCard(int i) {
    final recording = _recording == i;
    final done = _samples[i] != null;
    return CompanionCard(
      color: recording ? CompanionColors.coralTint : CompanionColors.panel,
      borderColor: recording ? CompanionColors.coral : CompanionColors.line,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${cloneScripts[i]}"', style: AppText.body),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _busy || (_recording != null && !recording) ? null : () => _toggleRecord(i),
                style: FilledButton.styleFrom(backgroundColor: recording ? CompanionColors.coralDeep : CompanionColors.tealDeep),
                icon: Icon(recording ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(recording ? 'Berhenti' : (done ? 'Rekam ulang' : 'Rekam')),
              ),
              const SizedBox(width: 8),
              if (done && !recording)
                IconButton(onPressed: () => _playSample(i), tooltip: 'Dengarkan', icon: const Icon(Icons.play_circle_outline_rounded)),
              const Spacer(),
              if (done && !recording) const Icon(Icons.check_circle_rounded, color: CompanionColors.leafText),
            ],
          ),
        ],
      ),
    );
  }
}
