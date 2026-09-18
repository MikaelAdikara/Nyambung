import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models.dart';
import '../../data/sync/link_service.dart';
import '../coach/companion_controller.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';

class TherapistScreen extends StatefulWidget {
  const TherapistScreen({super.key, required this.state});

  final CompanionController state;

  @override
  State<TherapistScreen> createState() => _TherapistScreenState();
}

class _TherapistScreenState extends State<TherapistScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _connectionMessage;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_code.text.trim().length != 8) return;
    setState(() => _busy = true);
    final result = await widget.state.connectTherapist(_code.text.trim().toUpperCase());
    // Catatan yang sudah ada langsung dicoba kirim setelah keluarga setuju terhubung.
    if (result == LinkResult.connected) await widget.state.syncNow();
    if (mounted) {
      setState(() {
        _busy = false;
        _connectionMessage = switch (result) {
          LinkResult.connected => 'Terhubung dengan ${widget.state.therapistName}.',
          LinkResult.unknownCode => 'Kode tidak dikenal. Periksa lagi hurufnya.',
          LinkResult.expiredCode => 'Kode sudah dipakai atau kedaluwarsa. Minta kode baru ke terapis.',
          LinkResult.offline => 'Belum ada jaringan. Coba lagi saat tersambung.',
          LinkResult.invalidResponse => 'Belum ada jaringan. Coba lagi saat tersambung.',
        };
      });
    }
  }

  Future<void> _answer(VocabTarget target, bool accepted) async {
    await widget.state.logTargetAnswer(target.targetId, accepted);
    if (mounted) {
      setState(() {
        _connectionMessage = accepted
            ? 'Diterima. Misi berganti ke ${target.words.first.toUpperCase()}.'
            : 'Ditolak. Terapis akan melihat jawaban ini.';
      });
    }
    // Jawaban (peristiwa TGT) langsung dicoba kirim; bila luring, tetap di outbox.
    await widget.state.syncNow();
  }

  Future<void> _revoke() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cabut akses ${widget.state.therapistName}?'),
        content: const Text('Catatan baru tidak akan dikirim lagi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cabut')),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.state.revokeTherapist();
      if (mounted) {
        setState(() {
          _connectionMessage = 'Akses dicabut. Kalau sedang tidak ada jaringan, pencabutan sampai ke server saat berikutnya terhubung.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => CompanionPage(
      title: 'Terapis',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: widget.state.linkedToTherapist ? _linked(context) : _unlinked(),
      ),
    ),
  );

  List<Widget> _unlinked() => [
    const Text(
      'Masukkan kode undangan dari terapis. Setelah terhubung, yang dikirim hanya catatan ketukan simbol dan konfirmasi misi. Tidak ada rekaman suara, video, foto, atau lokasi. Akses bisa dicabut kapan saja.',
      style: companionBodyStyle,
    ),
    const SizedBox(height: 20),
    TextField(
      controller: _code,
      maxLength: 8,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(labelText: 'Kode undangan', border: OutlineInputBorder()),
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 12),
    PrimaryButton(label: _busy ? 'Menghubungkan…' : 'Hubungkan', onPressed: _busy || _code.text.trim().length != 8 ? null : _connect),
    if (_connectionMessage != null) ...[const SizedBox(height: 8), Text(_connectionMessage!, style: companionMutedStyle)],
  ];

  List<Widget> _linked(BuildContext context) {
    final pending = widget.state.targets.where((target) => target.status == TargetStatus.usulan && target.words.isNotEmpty).firstOrNull;
    return [
      CompanionCard(
        child: Text.rich(
          TextSpan(
            style: companionBodyStyle,
            children: [
              const TextSpan(text: 'Terhubung dengan '),
              TextSpan(
                text: widget.state.therapistName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: ' sejak ${formatTanggal(widget.state.activeLink?.linkedAt ?? '')}.'),
            ],
          ),
        ),
      ),
      if (_connectionMessage != null) ...[const SizedBox(height: 12), Text(_connectionMessage!, style: companionBodyStyle)],
      if (pending != null) ...[
        const SizedBox(height: 16),
        CompanionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usulan kata pekan ini: ${pending.words.first.toUpperCase()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (pending.note != null) ...[const SizedBox(height: 8), Text(pending.note!, style: companionBodyStyle)],
              const SizedBox(height: 8),
              const Text('Keluarga boleh menolak tanpa alasan.', style: companionMutedStyle),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: EqualOutlineButton(label: 'Tolak', onPressed: () => _answer(pending, false)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EqualOutlineButton(label: 'Terima', onPressed: () => _answer(pending, true)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: _revoke, child: const Text('Cabut akses')),
      ),
    ];
  }
}
