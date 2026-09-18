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
            ? 'Diterima. Misi berganti ke ${widget.state.wordLabel(target.words.first)}.'
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
    const Text('Masukkan kode undangan dari terapis. Akses bisa dicabut kapan saja tanpa alasan.', style: companionBodyStyle),
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
    const SizedBox(height: 20),
    ..._privacyLists(),
  ];

  List<Widget> _linked(BuildContext context) {
    final state = widget.state;
    final link = state.activeLink;
    final name = state.therapistName ?? 'Terapis';
    final pending = state.targets.where((target) => target.status == TargetStatus.usulan && target.words.isNotEmpty).firstOrNull;
    final weeks = link?.linkedAt == null ? null : DateTime.now().difference(DateTime.parse(link!.linkedAt!)).inDays ~/ 7;
    return [
      CompanionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CompanionColors.navySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA9BED6)),
                  ),
                  child: Text(
                    _initials(name),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: CompanionColors.navy),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      Text(
                        weeks == null ? 'Terapis wicara' : 'Terapis wicara · terhubung ${weeks == 0 ? 'pekan ini' : '$weeks pekan'}',
                        style: companionMutedStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: CompanionColors.line),
            Text.rich(
              TextSpan(
                style: companionBodyStyle,
                children: [
                  const TextSpan(text: 'Terhubung memakai kode undangan '),
                  TextSpan(
                    text: link?.inviteCode ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(
                    text:
                        ' sejak ${formatTanggal(link?.linkedAt ?? '')}. Kode tidak berisi data apa pun tentang '
                        '${state.child?.nickname ?? 'anak'}.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (_connectionMessage != null) ...[const SizedBox(height: 12), Text(_connectionMessage!, style: companionBodyStyle)],
      if (pending != null) ...[
        const SizedBox(height: 20),
        const _Eyebrow('USULAN TARGET DARI TERAPIS'),
        const SizedBox(height: 8),
        CompanionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Usulan kata: ${pending.words.map(state.wordLabel).join(', ')}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              if (pending.note != null) ...[const SizedBox(height: 8), Text(pending.note!, style: companionBodyStyle)],
              const SizedBox(height: 8),
              Text(
                '${pending.receivedAt == null ? '' : 'Dikirim ${formatTanggal(pending.receivedAt!)} · '}berstatus usulan. '
                'Keluarga boleh menolak tanpa alasan.',
                style: companionMutedStyle,
              ),
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
      if (state.summaries.isNotEmpty) ...[
        const SizedBox(height: 20),
        const _Eyebrow('RINGKASAN SESI DARI TERAPIS'),
        const SizedBox(height: 8),
        for (final summary in state.summaries.take(3)) ...[_SummaryCard(summary: summary), const SizedBox(height: 8)],
      ],
      const SizedBox(height: 20),
      ..._privacyLists(),
      const SizedBox(height: 16),
      const CompanionCard(
        color: CompanionColors.sand,
        child: Text(
          'Kamu berhak menarik izin ini kapan saja tanpa alasan, sesuai Undang-Undang Nomor 27 Tahun 2022 tentang '
          'Pelindungan Data Pribadi. Setelah dicabut, terapis tidak bisa lagi membuka catatan anak dan HP ini berhenti '
          'mengirim catatan.',
          style: companionBodyStyle,
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: _revoke,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9B2C2C),
            side: const BorderSide(color: Color(0xFF9B2C2C), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          child: const Text('Cabut akses terapis'),
        ),
      ),
    ];
  }

  /// Apa yang dibagikan dan apa yang tidak pernah direkam atau dikirim (invarian 17, 18, 20).
  List<Widget> _privacyLists() => const [
    _PrivacyCard(
      title: 'YANG DIBAGIKAN',
      fill: Color(0xFFDDE8DD),
      border: Color(0xFFA9C4A9),
      text: Color(0xFF244B2C),
      marker: _Marker.square,
      items: [
        'Simbol apa yang ditekan dan jam berapa',
        'Rutinitas saat itu, misalnya makan sore',
        'Ketukan itu spontan atau setelah dipancing',
        'Konfirmasi misi dan jawaban atas usulan kata',
        'Label kartu personal, misalnya GELAS',
      ],
    ),
    SizedBox(height: 12),
    _PrivacyCard(
      title: 'YANG TIDAK PERNAH DIREKAM DAN TIDAK PERNAH DIKIRIM',
      fill: Color(0xFFF2E0D6),
      border: Color(0xFFD9A98E),
      text: Color(0xFF7A3413),
      marker: _Marker.diamond,
      items: [
        'Suara ruangan dan rekaman suara keluarga',
        'Video dan foto kartu personal',
        'Lokasi dan daftar kontak',
        'Diagnosis, skor, atau penilaian kemampuan',
      ],
    ),
  ];

  static String _initials(String name) {
    final words = name.replaceAll(RegExp(r'\(.*?\)'), '').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.where((w) => !const {'bu', 'pak', 'ibu', 'bapak'}.contains(w.toLowerCase())).map((w) => w[0].toUpperCase());
    final out = letters.take(2).join();
    return out.isEmpty ? '?' : out;
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: CompanionColors.muted),
  );
}

enum _Marker { square, diamond }

/// Daftar dengan penanda bentuk (kotak = dibagikan, belah ketupat = tidak pernah), bukan hanya warna (invarian 10).
class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.title,
    required this.fill,
    required this.border,
    required this.text,
    required this.marker,
    required this.items,
  });

  final String title;
  final Color fill;
  final Color border;
  final Color text;
  final _Marker marker;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: text),
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Transform.rotate(
                    angle: marker == _Marker.diamond ? 0.785398 : 0,
                    child: Container(width: 10, height: 10, color: text),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item, style: companionBodyStyle)),
              ],
            ),
          ),
      ],
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final TherapistSummary summary;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sesi ${formatTanggal(summary.sessionDate)}', style: companionMutedStyle),
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
      _Eyebrow(label),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
    ],
  );
}
