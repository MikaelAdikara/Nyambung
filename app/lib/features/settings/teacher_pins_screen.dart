import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/theme.dart';
import '../../data/phrase.dart';
import '../coach/companion_widgets.dart';
import '../start/parent_pin.dart';
import '../start/teacher_pin.dart';

const _days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// "Jum, 20 Sep 14.05"
String formatShortDateTime(DateTime t) {
  final l = t.toLocal();
  return '${_days[l.weekday - 1]}, ${l.day} ${_months[l.month - 1]} ${l.hour.toString().padLeft(2, '0')}.${l.minute.toString().padLeft(2, '0')}';
}

/// Status PIN untuk ditampilkan: "Berlaku sampai …", "Tidak kedaluwarsa", atau "Kedaluwarsa …".
String teacherPinStatus(TeacherPin p, DateTime now) {
  final end = p.expiresAt;
  if (end == null) return 'Tidak kedaluwarsa';
  if (p.isExpired(now)) return 'Kedaluwarsa ${formatShortDateTime(end)}';
  return 'Berlaku sampai ${formatShortDateTime(end)}';
}

/// Pengaturan → PIN guru. Orang tua membuat PIN per orang (guru, pengasuh) dengan masa berlaku, melihat frasa yang
/// dibuat tiap orang, lalu memperpanjang, mencabut, atau menghapus frasanya dari papan.
class TeacherPinsScreen extends StatefulWidget {
  const TeacherPinsScreen({super.key});

  @override
  State<TeacherPinsScreen> createState() => _TeacherPinsScreenState();
}

class _TeacherPinsScreenState extends State<TeacherPinsScreen> {
  late AppState _app;
  late TeacherPinStore _store;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _app = AppScope.of(context);
    _store = TeacherPinStore(_app.prefs);
  }

  Future<void> _create() async {
    final made = await Navigator.of(context).push<TeacherPin>(MaterialPageRoute(builder: (_) => CreateTeacherPinScreen(store: _store)));
    if (made == null || !mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('PIN untuk ${made.name} tersimpan. Beri tahu PIN-nya secara langsung.')));
  }

  Future<void> _extend(TeacherPin p) async {
    final choice = await showDialog<_Duration>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Perpanjang PIN ${p.name}'),
        children: [
          for (final d in teacherPinDurations)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, _Duration(d)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(d == null ? 'Tidak kedaluwarsa' : '$d hari dari sekarang', style: AppText.bodyStrong),
              ),
            ),
        ],
      ),
    );
    if (choice == null) return;
    await _store.extend(p.id, choice.days);
    if (mounted) setState(() {});
  }

  Future<void> _revoke(TeacherPin p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cabut PIN ${p.name}?'),
        content: const Text(
          'PIN ini langsung tidak bisa dipakai. Frasa yang sudah dibuat tetap di papan; kamu bisa menghapusnya di bawah.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cabut')),
        ],
      ),
    );
    if (ok != true) return;
    await _store.revoke(p.id);
    if (mounted) setState(() {});
  }

  Future<void> _removePhrase(TeacherPhraseLog entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus frasa ini?'),
        content: Text('"${entry.text}" dihapus dari papan dan dari daftar ini.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final phrase = (await _app.phraseDao.all()).where((p) => p.phraseId == entry.phraseId).firstOrNull;
      final card = phrase == null ? null : _app.phraseCard(phrase);
      if (card != null) await _app.deleteCard(card);
      await _store.removeLog(entry.phraseId);
      if (mounted) setState(() {});
    } catch (e, st) {
      ErrorLog.record('guru:hapus', e, st);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frasa belum terhapus. Coba sekali lagi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pins = _store.all()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final log = _store.log();
    return CompanionPage(
      title: 'PIN guru',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const Text(
            'Beri PIN ke guru atau pengasuh yang kamu percaya. Dengan PIN itu mereka bisa membuat frasa dengan suara keluarga '
            'di HP ini lewat "Aku guru", tanpa masuk ke layar orang tua. Setiap frasa tercatat atas nama pembuatnya.',
            style: AppText.muted,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Buat PIN guru', icon: Icons.add_rounded, onPressed: _create),
          const SizedBox(height: 22),
          const Eyebrow('PIN yang sudah dibuat'),
          const SizedBox(height: 8),
          if (pins.isEmpty)
            const CompanionCard(child: Text('Belum ada PIN guru.', style: AppText.muted))
          else
            for (final p in pins) ...[
              _PinTile(
                pin: p,
                status: teacherPinStatus(p, now),
                expired: p.isExpired(now),
                phrases: log.where((e) => e.pinId == p.id).length,
                onExtend: () => _extend(p),
                onRevoke: () => _revoke(p),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 22),
          const Eyebrow('Frasa buatan guru'),
          const SizedBox(height: 8),
          if (log.isEmpty)
            const CompanionCard(child: Text('Belum ada frasa yang dibuat lewat PIN guru.', style: AppText.muted))
          else
            for (final e in log) ...[
              CompanionCard(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('"${e.text}"', style: AppText.bodyStrong),
                          Text('${e.teacher} · ${PhraseVoice.label(e.voice)} · ${formatShortDateTime(e.at)}', style: AppText.cap),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => unawaited(_removePhrase(e)),
                      tooltip: 'Hapus frasa',
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _Duration {
  const _Duration(this.days);
  final int? days;
}

class _PinTile extends StatelessWidget {
  const _PinTile({
    required this.pin,
    required this.status,
    required this.expired,
    required this.phrases,
    required this.onExtend,
    required this.onRevoke,
  });

  final TeacherPin pin;
  final String status;
  final bool expired;
  final int phrases;
  final VoidCallback onExtend;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) => CompanionCard(
    color: expired ? CompanionColors.bg : CompanionColors.panel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(expired ? Icons.lock_clock_outlined : Icons.badge_outlined, color: expired ? AppColors.muted : AppColors.tealText),
            const SizedBox(width: 10),
            Expanded(child: Text(pin.name, style: AppText.h3)),
            Text('$phrases frasa', style: AppText.cap),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: AppText.cap.copyWith(color: expired ? AppColors.coralText : AppColors.muted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: EqualOutlineButton(label: expired ? 'Aktifkan lagi' : 'Perpanjang', icon: Icons.update_rounded, onPressed: onExtend),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: EqualOutlineButton(label: 'Cabut', icon: Icons.block_rounded, onPressed: onRevoke),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Buat PIN guru: nama → masa berlaku → PIN 4 angka (ketik dua kali). Mengembalikan [TeacherPin] yang tersimpan.
class CreateTeacherPinScreen extends StatefulWidget {
  const CreateTeacherPinScreen({super.key, required this.store});

  final TeacherPinStore store;

  @override
  State<CreateTeacherPinScreen> createState() => _CreateTeacherPinScreenState();
}

class _CreateTeacherPinScreenState extends State<CreateTeacherPinScreen> {
  final _name = TextEditingController();
  int? _days = 1;
  bool _askPin = false;
  String? _error;

  /// Naik setiap kali PIN ditolak, supaya [PinSetup] mulai lagi dari kosong.
  int _attempt = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(String pin) async {
    final problem = widget.store.conflict(pin);
    if (problem != null) {
      setState(() {
        _error = problem;
        _attempt++;
      });
      return;
    }
    final made = await widget.store.create(name: _name.text, pin: pin, days: _days);
    if (mounted) Navigator.of(context).pop(made);
  }

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Buat PIN guru',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: _askPin
          ? [
              Text('PIN untuk ${_name.text.trim()}', style: AppText.h3, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(teacherPinDurationLabel(_days), style: AppText.muted, textAlign: TextAlign.center),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.bodyStrong.copyWith(color: AppColors.coralText),
                ),
              ],
              const SizedBox(height: 16),
              Center(
                child: PinSetup(key: ValueKey(_attempt), onDone: _save),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(onPressed: () => setState(() => _askPin = false), child: const Text('Ubah nama atau masa berlaku')),
              ),
            ]
          : [
              TextField(
                controller: _name,
                maxLength: 30,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama', hintText: 'mis. Bu Rina (guru kelas)'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              const Text('BERLAKU SELAMA', style: AppText.eyebrow),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in teacherPinDurations)
                    ChoiceChip(label: Text(teacherPinDurationLabel(d)), selected: _days == d, onSelected: (_) => setState(() => _days = d)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _days == null
                    ? 'PIN berlaku sampai kamu mencabutnya.'
                    : 'PIN berhenti berlaku otomatis $_days hari lagi. Kamu bisa memperpanjang atau mencabutnya kapan saja.',
                style: AppText.cap,
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Lanjut, buat PIN',
                icon: Icons.pin_outlined,
                onPressed: _name.text.trim().isEmpty
                    ? null
                    : () => setState(() {
                        _askPin = true;
                        _error = null;
                      }),
              ),
            ],
    ),
  );
}
