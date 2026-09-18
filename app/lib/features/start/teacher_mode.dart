import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/phrase.dart';
import '../../data/sync/phrase_service.dart';
import '../board/board_screen.dart';
import '../coach/companion_widgets.dart';
import '../settings/teacher_pins_screen.dart';
import 'parent_pin.dart';
import 'teacher_pin.dart';

/// "Aku guru": ketik PIN yang diberikan orang tua. Tiga kali salah → jeda yang makin panjang, seperti PIN orang tua.
class TeacherPinScreen extends StatefulWidget {
  const TeacherPinScreen({super.key, required this.store, required this.onUnlocked});

  final TeacherPinStore store;
  final ValueChanged<TeacherPin> onUnlocked;

  @override
  State<TeacherPinScreen> createState() => _TeacherPinScreenState();
}

class _TeacherPinScreenState extends State<TeacherPinScreen> {
  String _value = '';
  int _wrong = 0;
  int _rounds = 0;
  bool _error = false;
  DateTime? _waitUntil;

  bool get _waiting => _waitUntil != null && DateTime.now().isBefore(_waitUntil!);

  void _changed(String v) {
    if (_waiting) {
      final s = _waitUntil!.difference(DateTime.now()).inSeconds + 1;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Tunggu $s detik lagi.')));
      return;
    }
    setState(() {
      _value = v;
      _error = false;
    });
    if (v.length < ParentPin.length) return;
    final pin = widget.store.unlock(v);
    if (pin != null) {
      widget.onUnlocked(pin);
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _wrong++;
      _error = true;
      _value = '';
      if (_wrong >= ParentPin.attemptsPerRound) {
        _wrong = 0;
        _rounds++;
        _waitUntil = DateTime.now().add(Duration(seconds: 30 * _rounds));
      }
    });
  }

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Masuk guru',
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ? 'PIN salah atau sudah tidak berlaku.' : 'Ketik PIN dari orang tua',
              textAlign: TextAlign.center,
              style: AppText.bodyStrong.copyWith(color: _error ? AppColors.coralText : AppColors.ink),
            ),
            const SizedBox(height: 16),
            PinPad(value: _value, onChanged: _changed, error: _error),
            const SizedBox(height: 8),
            const Text(
              'PIN kedaluwarsa? Minta orang tua memperpanjangnya di Pengaturan → PIN guru.',
              textAlign: TextAlign.center,
              style: AppText.cap,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Mode guru: hanya membuat frasa (suara keluarga atau suara papan) dan membuka papan sebagai pendamping.
/// Tidak ada akses ke pengaturan, data, atau kosakata. Setiap frasa langsung ditaruh di papan dan dicatat atas
/// nama pemegang PIN, supaya orang tua bisa melihat dan menghapusnya di Pengaturan → PIN guru.
class TeacherModeScreen extends StatefulWidget {
  const TeacherModeScreen({super.key, required this.pin, required this.store, required this.onExit});

  final TeacherPin pin;
  final TeacherPinStore store;
  final VoidCallback onExit;

  @override
  State<TeacherModeScreen> createState() => _TeacherModeScreenState();
}

class _TeacherModeScreenState extends State<TeacherModeScreen> with WidgetsBindingObserver {
  /// Mode guru tertutup sendiri bila HP ditinggal di latar belakang selama ini.
  static const relockAfter = Duration(minutes: 5);

  final _text = TextEditingController();
  final _player = AudioPlayer();
  late AppState _app;
  late PhraseService _service;
  bool _started = false;
  DateTime? _pausedAt;

  VoiceStatus? _status;
  String? _statusError;
  String _voice = PhraseVoice.keluarga;
  bool _busy = false;
  String? _error;
  String? _playingId;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _playerSub = _player.onPlayerStateChanged.listen((s) {
      if (s != PlayerState.playing && _playingId != null && mounted) setState(() => _playingId = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _app = AppScope.of(context);
    _service = PhraseService(_app);
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _text.dispose();
    _playerSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _pausedAt = DateTime.now();
    if (state == AppLifecycleState.resumed) {
      final away = _pausedAt == null ? Duration.zero : DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away >= relockAfter || !widget.store.isActive(widget.pin.id)) widget.onExit();
    }
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _service.status();
      if (!mounted) return;
      setState(() {
        _status = s;
        _statusError = null;
        if (!s.cloneActive && _voice == PhraseVoice.keluarga) {
          _voice = _app.voiceSet == PhraseVoice.cewe ? PhraseVoice.cewe : PhraseVoice.cowo;
        }
      });
    } on PhraseException catch (e) {
      if (mounted) setState(() => _statusError = e.message);
    }
  }

  List<TeacherPhraseLog> get _mine => widget.store.log().where((e) => e.pinId == widget.pin.id).toList();

  Future<void> _play(String phraseId) async {
    if (_playingId == phraseId) {
      await _player.stop();
      if (mounted) setState(() => _playingId = null);
      return;
    }
    final phrase = (await _app.phraseDao.all()).where((p) => p.phraseId == phraseId).firstOrNull;
    final path = phrase?.audioPath;
    if (path == null) return;
    try {
      await _player.stop();
      if (mounted) setState(() => _playingId = phraseId);
      await _player.play(DeviceFileSource(path));
    } catch (e, st) {
      ErrorLog.record('guru:putar', e, st);
      if (mounted) setState(() => _playingId = null);
    }
  }

  Future<void> _create() async {
    final text = normalizePhraseText(_text.text);
    if (text.isEmpty) return;
    // PIN bisa kedaluwarsa atau dicabut saat guru masih di layar ini.
    if (!widget.store.isActive(widget.pin.id)) {
      widget.onExit();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await _service.create(text, _voice);
      await _app.addPhraseCard(p);
      await widget.store.addLog(
        TeacherPhraseLog(
          phraseId: p.phraseId,
          pinId: widget.pin.id,
          teacher: widget.pin.name,
          text: p.text,
          voice: p.voice,
          at: DateTime.now(),
        ),
      );
      _text.clear();
      if (!mounted) return;
      final card = _app.phraseCard(p);
      final page = _app.pages.where((x) => x.page == card?.page).map((x) => x.tabLabel).firstOrNull ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${p.text}" ada di papan, halaman $page.')));
      setState(() {});
      unawaited(_play(p.phraseId));
    } on PhraseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e, st) {
      ErrorLog.record('guru:frasa', e, st);
      if (mounted) setState(() => _error = 'Frasa belum tersimpan. Coba sekali lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloneReady = _status?.cloneActive ?? false;
    final ready = normalizePhraseText(_text.text).isNotEmpty && !_busy && _statusError == null && _status != null;
    final mine = _mine;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onExit();
      },
      child: CompanionPage(
        title: 'Mode guru',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(onPressed: widget.onExit, icon: const Icon(Icons.logout_rounded), label: const Text('Keluar')),
          ),
        ],
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            CompanionCard(
              color: CompanionColors.tealTint,
              borderColor: CompanionColors.mint,
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: AppColors.tealText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Masuk sebagai ${widget.pin.name}', style: AppText.h3),
                        Text(teacherPinStatus(widget.pin, DateTime.now()), style: AppText.cap),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Frasa yang kamu buat langsung ada di papan dan tercatat atas namamu. Orang tua bisa melihat dan menghapusnya.',
              style: AppText.muted,
            ),
            const SizedBox(height: 20),
            const Eyebrow('Buat frasa'),
            const SizedBox(height: 8),
            CompanionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _text,
                    maxLength: phraseTextMax,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.bodyStrong,
                    decoration: const InputDecoration(hintText: 'mis. Jangan nyontek', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  const Text('SUARA', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in [PhraseVoice.keluarga, PhraseVoice.cowo, PhraseVoice.cewe])
                        ChoiceChip(
                          label: Text(PhraseVoice.label(v)),
                          selected: _voice == v,
                          onSelected: v == PhraseVoice.keluarga && !cloneReady ? null : (_) => setState(() => _voice = v),
                        ),
                    ],
                  ),
                  if (_statusError != null) ...[
                    const SizedBox(height: 10),
                    Text(_statusError!, style: AppText.cap),
                  ] else if (_status != null && !cloneReady) ...[
                    const SizedBox(height: 10),
                    const Text('Suara keluarga belum diaktifkan orang tua. Frasa memakai suara papan.', style: AppText.cap),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: _busy ? 'Membuat suara…' : 'Buat dan taruh di papan',
                    icon: Icons.graphic_eq_rounded,
                    onPressed: ready ? _create : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            NavRow(
              icon: Icons.grid_view_rounded,
              title: 'Buka papan',
              subtitle: 'Pakai papan bersama anak, termasuk kartu frasa',
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BoardScreen(allowTurnToggle: true))),
            ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Eyebrow('Frasa buatanmu'),
              const SizedBox(height: 8),
              for (final e in mine) ...[
                CompanionCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.text, style: AppText.bodyStrong),
                            Text('${PhraseVoice.label(e.voice)} · ${formatShortDateTime(e.at)}', style: AppText.cap),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _play(e.phraseId),
                        tooltip: _playingId == e.phraseId ? 'Berhenti' : 'Putar',
                        icon: AnimatedSwitcher(
                          duration: Motion.of(context, Motion.press),
                          child: Icon(
                            _playingId == e.phraseId ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                            key: ValueKey(_playingId == e.phraseId),
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
