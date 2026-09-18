import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/constants.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/sync/link_service.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_controller.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import '../coach/proposal_copy.dart';

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
            ? 'Diterima sebagai misi. Jika ada beberapa kata, target akan bergilir setiap hari.'
            : 'Tidak dipakai. Terapis akan melihat keputusan ini.';
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
          _connectionMessage = 'Akses dicabut. Bila sedang luring, pencabutan terkirim saat tersambung.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) => CompanionPage(
      title: 'Terapis',
      body: AnimatedSwitcher(
        duration: Motion.of(context, Motion.resize),
        child: ListView(
          key: ValueKey(widget.state.linkedToTherapist),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: widget.state.linkedToTherapist ? _linked(context) : _unlinked(),
        ),
      ),
    ),
  );

  Widget _message() => SmoothReveal(
    child: _connectionMessage == null
        ? null
        : Padding(
            key: ValueKey(_connectionMessage),
            padding: const EdgeInsets.only(top: 12),
            child: CompanionCard(
              color: CompanionColors.sand,
              borderColor: CompanionColors.sand,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Text(_connectionMessage!, style: AppText.body.copyWith(fontSize: 15)),
            ),
          ),
  );

  List<Widget> _unlinked() => [
    const Text('Masukkan kode undangan dari terapis.', style: companionBodyStyle),
    const SizedBox(height: 16),
    CompanionCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Kode undangan'),
          TextField(
            controller: _code,
            maxLength: 8,
            textCapitalization: TextCapitalization.characters,
            style: AppText.h2.copyWith(letterSpacing: 6),
            decoration: InputDecoration(
              hintText: 'RANI26WB',
              hintStyle: AppText.h2.copyWith(letterSpacing: 6, color: CompanionColors.sandDeep),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    PrimaryButton(label: _busy ? 'Menghubungkan…' : 'Hubungkan', onPressed: _busy || _code.text.trim().length != 8 ? null : _connect),
    _message(),
    const SizedBox(height: 20),
    const CompanionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckRow(text: 'Ketukan simbol, waktu, konteks rutinitas'),
          CheckRow(text: 'Tidak pernah audio ruangan, video, atau lokasi', ok: false),
        ],
      ),
    ),
  ];

  List<Widget> _linked(BuildContext context) {
    final state = widget.state;
    final link = state.activeLink;
    final name = state.therapistName ?? 'Terapis';
    final pending = state.targets.where((target) => target.status == TargetStatus.usulan && target.words.isNotEmpty).firstOrNull;
    final firstWord = pending == null ? null : state.app.symbolById(pending.words.first);
    return [
      HeroCard(
        colors: HeroCard.heroLavender,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Text(_initials(name), style: AppText.h3.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppText.h3.copyWith(color: Colors.white)),
                  Text('Terhubung sejak ${formatTanggal(link?.linkedAt ?? '')}', style: AppText.cap.copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
      _message(),
      if (pending != null) ...[
        const SizedBox(height: 16),
        PopIn(
          key: ValueKey(pending.targetId),
          child: CompanionCard(
            color: CompanionColors.lavenderTint,
            borderColor: const Color(0xFFB7B4E8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow(ProposalCopy.targetTitle, color: CompanionColors.lavenderDeep),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (firstWord != null) ...[
                      SymbolFace(symbol: firstWord, width: 52, height: 52, compact: true),
                      const SizedBox(width: 12),
                    ],
                    Expanded(child: Text(pending.words.map(state.wordLabel).join(', '), style: AppText.h2)),
                  ],
                ),
                if (pending.note != null) ...[const SizedBox(height: 10), Text('"${pending.note!}"', style: companionBodyStyle)],
                const SizedBox(height: 6),
                const Text('Kata yang diterima menjadi misi harian dan bergilir jika jumlahnya lebih dari satu.', style: AppText.cap),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: EqualOutlineButton(label: ProposalCopy.reject, onPressed: () => _answer(pending, false)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PressScale(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: () => _answer(pending, true),
                            style: FilledButton.styleFrom(backgroundColor: CompanionColors.coralDeep),
                            child: const FittedBox(fit: BoxFit.scaleDown, child: Text(ProposalCopy.targetAccept)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      if (state.summaries.isNotEmpty) ...[
        const SizedBox(height: 20),
        const Eyebrow('Ringkasan sesi dari terapis'),
        const SizedBox(height: 8),
        for (final summary in state.summaries.take(3)) ...[_SummaryCard(summary: summary), const SizedBox(height: 8)],
      ],
      const SizedBox(height: 20),
      const CompanionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow('Yang dibagikan'),
            SizedBox(height: 6),
            CheckRow(text: 'Ketukan simbol & waktu'),
            CheckRow(text: 'Konteks rutinitas & ringkasan misi'),
            CheckRow(text: 'Label kartu personal'),
            SizedBox(height: 10),
            Eyebrow('Tidak pernah dikirim'),
            SizedBox(height: 6),
            CheckRow(text: 'Audio ruangan · rekaman keluarga · video', ok: false),
            CheckRow(text: 'Foto kartu · lokasi · diagnosis', ok: false),
          ],
        ),
      ),
      const SizedBox(height: 16),
      EqualOutlineButton(label: 'Cabut akses', color: CompanionColors.caution, onPressed: _revoke),
    ];
  }

  static String _initials(String name) {
    final words = name.replaceAll(RegExp(r'\(.*?\)'), '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.where((w) => !const {'bu', 'pak', 'ibu', 'bapak'}.contains(w.toLowerCase())).map((w) => w[0].toUpperCase());
    final out = letters.take(2).join();
    return out.isEmpty ? '?' : out;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TherapistSummary summary;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow('Sesi ${formatTanggal(summary.sessionDate)}'),
        const SizedBox(height: 6),
        Text(summary.familyText, style: companionBodyStyle),
        if (summary.focus != null || summary.nextSession != null) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              if (summary.focus != null) _Fact(label: 'FOKUS PEKAN DEPAN', value: summary.focus!),
              if (summary.nextSession != null) _Fact(label: 'SESI BERIKUTNYA', value: formatJadwal(summary.nextSession!)),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(label),
      const SizedBox(height: 2),
      Text(value, style: AppText.bodyStrong),
    ],
  );
}
