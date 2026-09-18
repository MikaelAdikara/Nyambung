import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/phrase.dart';
import '../../data/sync/phrase_service.dart';
import '../coach/companion_widgets.dart';
import 'voice_clone_screen.dart';

/// Frasa bersuara: kalimat pendek (mis. "Jangan nyontek") dengan suara papan atau suara keluarga, dibuat sekali lewat
/// server lalu disimpan di HP. Frasa dari terapis/guru muncul sebagai usulan yang boleh ditolak tanpa alasan.
class PhraseScreen extends StatefulWidget {
  const PhraseScreen({super.key});

  @override
  State<PhraseScreen> createState() => _PhraseScreenState();
}

class _PhraseScreenState extends State<PhraseScreen> {
  final _text = TextEditingController();
  final _player = AudioPlayer();
  late AppState _app;
  late PhraseService _service;
  bool _started = false;

  List<Phrase> _phrases = const [];
  VoiceStatus? _status;
  String? _statusError;

  String _voice = PhraseVoice.cowo;
  bool _busy = false;
  String? _error;

  /// Frasa yang baru dibuat, menunggu ditaruh di papan.
  Phrase? _draft;
  int? _page;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _app = AppScope.of(context);
    _service = PhraseService(_app);
    _page = _app.defaultPhrasePage;
    _voice = _app.voiceSet == PhraseVoice.cewe ? PhraseVoice.cewe : PhraseVoice.cowo;
    unawaited(_reload());
    unawaited(_loadStatus());
  }

  @override
  void dispose() {
    _text.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final list = await _app.phraseDao.all();
    if (mounted) setState(() => _phrases = list);
  }

  Future<void> _loadStatus() async {
    try {
      final s = await _service.status();
      if (mounted) {
        setState(() {
          _status = s;
          _statusError = null;
          if (_voice == PhraseVoice.keluarga && !s.cloneActive) _voice = PhraseVoice.cowo;
        });
      }
    } on PhraseException catch (e) {
      if (mounted) setState(() => _statusError = e.message);
    }
  }

  Future<void> _play(Phrase p) async {
    final path = p.audioPath;
    if (path == null) return;
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (e, st) {
      ErrorLog.record('frasa:putar', e, st);
    }
  }

  Future<void> _create() async {
    final text = normalizePhraseText(_text.text);
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await _service.create(text, _voice);
      _text.clear();
      await _reload();
      if (mounted) setState(() => _draft = p);
      unawaited(_play(p));
    } on PhraseException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _place(Phrase p) async {
    try {
      await _app.addPhraseCard(p, page: _page);
      await _reload();
      if (!mounted) return;
      setState(() => _draft = null);
      final card = _app.phraseCard(p);
      final label = _app.pages.where((x) => x.page == card?.page).map((x) => x.tabLabel).firstOrNull ?? '';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${p.text}" ada di halaman $label.')));
    } catch (e, st) {
      ErrorLog.record('frasa:taruh', e, st);
      if (mounted) setState(() => _error = 'Kartu belum tersimpan. Coba sekali lagi.');
    }
  }

  Future<void> _answer(Phrase p, bool accept) async {
    try {
      await _app.answerPhrase(p, accept, page: _page);
      await _reload();
    } catch (e, st) {
      ErrorLog.record('frasa:jawab', e, st);
      if (mounted) setState(() => _error = 'Jawaban belum tersimpan. Coba sekali lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _phrases.where((p) => p.status == PhraseStatus.usulan).toList();
    final mine = _phrases.where((p) => p.status == PhraseStatus.diterima).toList();
    return CompanionPage(
      title: 'Frasa bersuara',
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStatus();
          await _reload();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'Kalimat pendek yang sering kamu ucapkan ke anak, jadi satu kartu di papan. Suaranya dibuat sekali lewat '
              'internet, lalu tersimpan di HP dan tetap bisa diputar tanpa internet.',
              style: AppText.muted,
            ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Eyebrow('Usulan dari terapis'),
              const SizedBox(height: 8),
              for (final p in pending) ...[
                _ProposalTile(phrase: p, onPlay: () => _play(p), onAnswer: (a) => _answer(p, a)),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 20),
            const Eyebrow('Buat frasa baru'),
            const SizedBox(height: 8),
            AnimatedSwitcher(duration: Motion.of(context, Motion.fade), child: _draft == null ? _form() : _placeDraft(_draft!)),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),
            NavRow(
              icon: Icons.record_voice_over_rounded,
              title: 'Suara keluarga',
              subtitle: _status == null
                  ? 'Tiruan suara orang tua untuk frasa'
                  : _status!.cloneActive
                  ? 'Aktif · disetujui ${_status!.cloneConsentBy ?? ''}'
                  : 'Belum aktif',
              tint: CompanionColors.coralTint,
              iconColor: CompanionColors.coralText,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VoiceCloneScreen()));
                unawaited(_loadStatus());
              },
            ),
            if (mine.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Eyebrow('Frasa tersimpan'),
              const SizedBox(height: 8),
              for (final p in mine) ...[
                _PhraseTile(
                  phrase: p,
                  onBoard: _app.phraseCard(p) != null,
                  onPlay: () => _play(p),
                  onPlace: p.audioPath == null ? null : () => _place(p),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _form() {
    final status = _status;
    final cloneReady = status?.cloneActive ?? false;
    final ready = normalizePhraseText(_text.text).isNotEmpty && !_busy && _statusError == null;
    return CompanionCard(
      key: const ValueKey('form'),
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
              for (final v in [PhraseVoice.cowo, PhraseVoice.cewe, PhraseVoice.keluarga])
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
          ] else if (status != null && !status.openai && _voice != PhraseVoice.keluarga) ...[
            const SizedBox(height: 10),
            const Text('Suara papan untuk frasa belum aktif di server.', style: AppText.cap),
          ],
          const SizedBox(height: 14),
          PrimaryButton(label: _busy ? 'Membuat suara…' : 'Buat suara', icon: Icons.graphic_eq_rounded, onPressed: ready ? _create : null),
        ],
      ),
    );
  }

  Widget _placeDraft(Phrase p) => CompanionCard(
    key: ValueKey(p.phraseId),
    color: CompanionColors.tealTint,
    borderColor: CompanionColors.mint,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('"${p.text}"', style: AppText.h3)),
            IconButton(onPressed: () => _play(p), tooltip: 'Putar', icon: const Icon(Icons.play_circle_fill_rounded, size: 36)),
          ],
        ),
        Text(PhraseVoice.label(p.voice), style: AppText.cap),
        const SizedBox(height: 12),
        const Text('TARUH DI HALAMAN', style: AppText.eyebrow),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pg in _app.pages.where((x) => x.page != 0))
              ChoiceChip(label: Text(pg.tabLabel), selected: pg.page == _page, onSelected: (_) => setState(() => _page = pg.page)),
          ],
        ),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Taruh di papan', icon: Icons.grid_view_rounded, onPressed: _page == null ? null : () => _place(p)),
        const SizedBox(height: 8),
        Center(
          child: TextButton(onPressed: () => setState(() => _draft = null), child: const Text('Nanti saja')),
        ),
      ],
    ),
  );
}

class _ProposalTile extends StatelessWidget {
  const _ProposalTile({required this.phrase, required this.onPlay, required this.onAnswer});

  final Phrase phrase;
  final VoidCallback onPlay;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: CompanionColors.sunTint,
    borderColor: CompanionColors.sunLine,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('"${phrase.text}"', style: AppText.h3),
                  Text('Dari ${phrase.createdBy} · ${PhraseVoice.label(phrase.voice)}', style: AppText.cap),
                ],
              ),
            ),
            IconButton(
              onPressed: phrase.audioPath == null ? null : onPlay,
              tooltip: phrase.audioPath == null ? 'Suara belum terunduh' : 'Putar',
              icon: const Icon(Icons.play_circle_fill_rounded, size: 36, color: CompanionColors.sunText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Dua pilihan setara: menolak tidak butuh alasan (invarian 19).
        Row(
          children: [
            Expanded(
              child: EqualOutlineButton(label: 'Tambah ke papan', onPressed: () => onAnswer(true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EqualOutlineButton(label: 'Tidak dipakai', onPressed: () => onAnswer(false)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PhraseTile extends StatelessWidget {
  const _PhraseTile({required this.phrase, required this.onBoard, required this.onPlay, required this.onPlace});

  final Phrase phrase;
  final bool onBoard;
  final VoidCallback onPlay;
  final VoidCallback? onPlace;

  @override
  Widget build(BuildContext context) => CompanionCard(
    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(phrase.text, style: AppText.bodyStrong),
              Text('${PhraseVoice.label(phrase.voice)}${phrase.fromFamily ? '' : ' · dari ${phrase.createdBy}'}', style: AppText.cap),
            ],
          ),
        ),
        if (onBoard)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: CompanionColors.leafText),
                SizedBox(width: 4),
                Text(
                  'Di papan',
                  style: TextStyle(color: CompanionColors.leafText, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          )
        else
          TextButton(onPressed: onPlace, child: const Text('Taruh')),
        IconButton(
          onPressed: phrase.audioPath == null ? null : onPlay,
          tooltip: 'Putar',
          icon: const Icon(Icons.play_circle_outline_rounded, size: 30),
        ),
      ],
    ),
  );
}
