import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/db/app_database.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import '../vocab/family_voice_screen.dart';
import '../vocab/manage_vocab_screen.dart';
import '../start/parent_pin.dart';
import '../vocab/phrase_screen.dart';
import 'export_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _server = TextEditingController(text: 'http://127.0.0.1:8000');
  int _holdMs = 0;
  String? _connectionResult;
  AppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_app == app) return;
    _app = app;
    _server.text = app.prefs.getString(PrefKeys.serverUrl) ?? 'http://127.0.0.1:8000';
    _holdMs = app.holdMs;
    _measureData();
  }

  /// Ukuran data di HP ini: berkas basis data + folder aplikasi (rekaman keluarga, foto kartu, ekspor).
  double? _dataMb;

  Future<void> _measureData() async {
    var bytes = 0;
    try {
      final db = File(await AppDatabase.path());
      if (db.existsSync()) bytes += db.lengthSync();
      final docs = await getApplicationDocumentsDirectory();
      await for (final e in docs.list(recursive: true, followLinks: false)) {
        if (e is File) bytes += await e.length();
      }
    } catch (e, st) {
      ErrorLog.record('c6:ukuran', e, st);
    }
    if (mounted) setState(() => _dataMb = bytes / (1024 * 1024));
  }

  Future<void> _showLimits() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Batas produk'),
      content: const SingleChildScrollView(
        child: Text(
          '• Nyambung alat bantu komunikasi dan pencatatan, bukan alat diagnosis dan bukan pengganti terapi.\n'
          '• Angka di aplikasi adalah pola pemakaian papan, bukan ukuran kemampuan anak.\n'
          '• "Spontan" berarti tidak ada contoh dari pendamping dalam 60 detik sebelumnya. Ini aturan tetap aplikasi, '
          'bukan kode resmi LAM.\n'
          '• Kosakata awal 120 kata, belum semuanya ditinjau terapis wicara.\n'
          '• Suara papan adalah klip sintetis. Rekaman keluarga dan foto kartu tidak pernah meninggalkan HP ini.\n'
          '• Catatan hanya sampai ke terapis bila keluarga menghubungkannya dengan kode undangan.',
          style: companionBodyStyle,
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
    ),
  );

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  bool _testing = false;

  /// Simpan alamat lalu uji `GET /v1/health` (harus `{"ok": true}`; port yang dijawab proses lain tidak dihitung).
  Future<void> _saveServer() async {
    var url = _server.text.trim().replaceFirst('://localhost', '://127.0.0.1');
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);
    if (url.isNotEmpty && !url.startsWith('http')) url = 'http://$url';
    _server.text = url;
    await _app!.prefs.setString(PrefKeys.serverUrl, url);
    setState(() => _testing = true);
    var ok = false;
    try {
      final r = await http.get(Uri.parse('$url/v1/health')).timeout(const Duration(seconds: 3));
      final body = jsonDecode(r.body);
      ok = r.statusCode == 200 && body is Map && body['ok'] == true;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _testing = false;
        _connectionResult = ok ? 'Tersambung.' : 'Tidak tersambung. Periksa Wi-Fi dan alamat.';
      });
    }
  }

  /// "mau" dua kali: nada anak lalu nada pendamping, dengan jeda supaya yang pertama tidak terpotong.
  Future<void> _testVoice() async {
    await _app!.speech.speakText('mau', byParent: false);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _app!.speech.speakText('mau', byParent: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  /// Ganti set klip suara papan lalu perdengarkan "mau" dengan suara baru itu (ketukan anak).
  Future<void> _changeVoiceSet(String set) async {
    final app = _app!;
    await app.setVoiceSet(set);
    if (mounted) setState(() {});
    final mau = app.symbolById('mau');
    if (mau != null) await app.speech.speakWord(mau, byParent: false);
  }

  void _open(Widget screen) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

  Future<void> _changeRoutine(String routine) async {
    await _app!.updateRoutine(routine);
    if (mounted) setState(() {});
  }

  Future<void> _showDiagnostics() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Diagnosa'),
      content: SingleChildScrollView(child: SelectableText(ErrorLog.asText())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
    ),
  );

  Future<void> _export() => ExportService(_app!).share();

  Future<void> _deleteAllData() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua data di perangkat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjut')),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final input = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ketik HAPUS'),
        content: TextField(controller: input, autofocus: true, textCapitalization: TextCapitalization.characters),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, input.text.trim().toUpperCase() == 'HAPUS'), child: const Text('Hapus')),
        ],
      ),
    );
    input.dispose();
    if (confirmed != true) return;
    await _app!.deleteAllData();
    // Kembali ke akar: tanpa anak, BootGate menampilkan pemasangan A1.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    final name = app?.child?.nickname ?? 'anak';
    return CompanionPage(
      title: 'Pengaturan',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const _Section('Papan bicara'),
          CompanionCard(
            padding: const EdgeInsets.fromLTRB(18, 6, 12, 6),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Susunan sel', style: _rowTitle),
                  trailing: Text('${app?.child?.gridCols ?? 3} kolom', style: _rowValue),
                ),
                const Divider(),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kunci mode anak', style: _rowTitle),
                  subtitle: const Text('Tahan tombol kunci 1,5 detik untuk keluar', style: AppText.cap),
                  value: app?.childLock ?? true,
                  onChanged: app == null
                      ? null
                      : (on) async {
                          await app.setChildLock(on);
                          if (mounted) setState(() {});
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _ChoiceCard(
            title: 'Suara papan',
            options: const [('cowo', 'Cowok'), ('cewe', 'Cewek')],
            value: app?.voiceSet,
            onChanged: _changeVoiceSet,
          ),
          const SizedBox(height: 10),
          _ChoiceCard(
            title: 'Tahan untuk memilih',
            subtitle: 'Untuk anak yang tangannya sering menyenggol layar.',
            options: [for (final v in Limits.holdMsOptions) (v, v == 0 ? 'Tidak' : '$v ms')],
            value: _holdMs,
            onChanged: (selected) async {
              await _app!.setHoldMs(selected);
              if (mounted) setState(() => _holdMs = selected);
            },
          ),
          const SizedBox(height: 10),
          _ChoiceCard(
            title: 'Rutinitas misi',
            options: [for (final r in Routine.all) (r, _capitalize(routineDisplayLabel(r)))],
            value: app?.child?.routine,
            onChanged: _changeRoutine,
          ),
          const SizedBox(height: 10),
          NavRow(
            icon: Icons.pin_outlined,
            title: 'Ganti PIN orang tua',
            subtitle: 'PIN menjaga layar orang tua dari ketukan anak',
            onTap: () => _open(ChangePinScreen(prefs: app!.prefs)),
          ),
          const SizedBox(height: 10),
          NavRow(
            icon: Icons.mic_rounded,
            title: 'Suara keluarga',
            tint: CompanionColors.coralTint,
            iconColor: CompanionColors.coralText,
            onTap: () => _open(const FamilyVoiceScreen()),
          ),
          const SizedBox(height: 10),
          NavRow(
            icon: Icons.graphic_eq_rounded,
            title: 'Frasa bersuara',
            subtitle: 'Kalimat pendek jadi kartu, suara papan atau suara keluarga',
            tint: CompanionColors.lavenderTint,
            iconColor: CompanionColors.lavenderDeep,
            onTap: () => _open(const PhraseScreen()),
          ),
          const SizedBox(height: 10),
          NavRow(
            icon: Icons.menu_book_rounded,
            title: 'Kelola kosakata',
            tint: CompanionColors.leafTint,
            iconColor: CompanionColors.leafText,
            onTap: () => _open(const ManageVocabScreen()),
          ),
          const _Section('Data di perangkat ini'),
          NavRow(
            icon: Icons.download_rounded,
            title: 'Ekspor catatan',
            subtitle: _dataMb == null ? null : '${_dataMb!.toStringAsFixed(1).replaceAll('.', ',')} MB tersimpan',
            tint: CompanionColors.skyTint,
            iconColor: CompanionColors.skyText,
            onTap: _export,
          ),
          const SizedBox(height: 10),
          EqualOutlineButton(label: 'Hapus semua data $name', color: CompanionColors.caution, onPressed: _deleteAllData),
          const _Section('Tentang'),
          NavRow(icon: Icons.info_outline_rounded, title: 'Batas produk', onTap: _showLimits),
          const SizedBox(height: 10),
          const CompanionCard(child: Text('Simbol: Mulberry Symbols © Steve Lee, CC BY-SA 4.0, mulberrysymbols.org', style: AppText.cap)),
          const _Section('Teknis'),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat server', style: _rowTitle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(controller: _server, keyboardType: TextInputType.url),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _testing ? null : _saveServer,
                      style: TextButton.styleFrom(backgroundColor: CompanionColors.sand, minimumSize: const Size(72, 52)),
                      child: Text(_testing ? '…' : 'Uji'),
                    ),
                  ],
                ),
                SmoothReveal(
                  child: _connectionResult == null
                      ? null
                      : Padding(
                          key: ValueKey(_connectionResult),
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_connectionResult!, style: AppText.cap),
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Suara Bahasa Indonesia ${app?.speech.ttsIdAvailable == true ? 'tersedia' : 'tidak tersedia'} · '
                  'jeda ${app?.speech.firstUtteranceLatencyMs ?? '-'} ms',
                  style: AppText.cap,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _testVoice,
                      style: TextButton.styleFrom(backgroundColor: CompanionColors.sand),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: const Text('Uji suara'),
                    ),
                    TextButton.icon(
                      onPressed: _showDiagnostics,
                      style: TextButton.styleFrom(backgroundColor: CompanionColors.sand),
                      icon: const Icon(Icons.bug_report_outlined),
                      label: const Text('Diagnosa'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _rowTitle = TextStyle(fontFamily: 'Nunito', fontSize: 16.5, fontWeight: FontWeight.w800, color: CompanionColors.ink);
const _rowValue = TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w700, color: CompanionColors.muted);

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(4, 22, 0, 10), child: Eyebrow(text));
}

/// Kartu pilihan tunggal berupa pil. Pil terpilih berlatar toska muda.
class _ChoiceCard<T> extends StatelessWidget {
  const _ChoiceCard({required this.title, required this.options, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final String? subtitle;
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => CompanionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _rowTitle),
        if (subtitle != null) Text(subtitle!, style: AppText.cap),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (v, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: v == value,
                onSelected: (_) => onChanged(v),
                labelStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: v == value ? CompanionColors.tealText : CompanionColors.ink,
                ),
                side: BorderSide(color: v == value ? CompanionColors.teal : CompanionColors.line, width: v == value ? 2 : 1),
              ),
          ],
        ),
      ],
    ),
  );
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
