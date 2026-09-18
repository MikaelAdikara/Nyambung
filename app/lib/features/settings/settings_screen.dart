import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/error_log.dart';
import '../../data/db/app_database.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import '../vocab/family_voice_screen.dart';
import '../vocab/manage_vocab_screen.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _Eyebrow('PAPAN BICARA'),
          CompanionCard(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Susunan sel', style: _rowTitle),
                  subtitle: const Text('Tetap, supaya letak kata tidak pernah berpindah', style: companionMutedStyle),
                  trailing: Text('${app?.child?.gridCols ?? 3} kolom', style: _rowValue),
                ),
                const Divider(height: 1, color: CompanionColors.line),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kunci mode anak', style: _rowTitle),
                  subtitle: const Text(
                    'Tombol Home dan kembali terkunci selama papan anak terbuka. Tahan tombol kunci 1,5 detik untuk keluar.',
                    style: companionMutedStyle,
                  ),
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
          const SizedBox(height: 12),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suara papan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Suara saat anak menekan kata. Klip tersimpan di aplikasi, jalan tanpa internet.', style: companionMutedStyle),
                RadioGroup<String>(
                  groupValue: app?.voiceSet,
                  onChanged: (value) => value == null ? null : _changeVoiceSet(value),
                  child: const Column(
                    children: [
                      RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'cowo', title: Text('Suara cowok')),
                      RadioListTile<String>(contentPadding: EdgeInsets.zero, value: 'cewe', title: Text('Suara cewek')),
                    ],
                  ),
                ),
                const Text(
                  'Saat Ibu atau Ayah memberi contoh, suara keluarga dipakai lebih dulu bila sudah direkam.',
                  style: companionMutedStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tahan untuk memilih', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Untuk anak yang tangannya sering menyenggol layar.', style: companionMutedStyle),
                DropdownButton<int>(
                  value: _holdMs,
                  isExpanded: true,
                  items: Limits.holdMsOptions
                      .map((value) => DropdownMenuItem(value: value, child: Text(value == 0 ? 'Tidak ditahan' : '$value ms')))
                      .toList(),
                  onChanged: (value) async {
                    final selected = value ?? 0;
                    await _app!.setHoldMs(selected);
                    if (mounted) setState(() => _holdMs = selected);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rutinitas misi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Text('Misi harian menempel pada kegiatan ini.', style: companionMutedStyle),
                RadioGroup<String>(
                  groupValue: app?.child?.routine,
                  onChanged: (value) => value == null ? null : _changeRoutine(value),
                  child: Column(
                    children: [
                      for (final routine in Routine.all)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: routine,
                          title: Text(_capitalize(routineDisplayLabel(routine))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanionCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Suara keluarga', style: _rowTitle),
                  subtitle: const Text('Rekam suara Ibu atau Ayah untuk kata inti dan kartu personal', style: companionMutedStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const FamilyVoiceScreen()),
                ),
                const Divider(height: 1, color: CompanionColors.line),
                ListTile(
                  title: const Text('Kelola kosakata', style: _rowTitle),
                  subtitle: const Text('Sembunyikan kata atau tambah kartu dari foto', style: companionMutedStyle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(const ManageVocabScreen()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Eyebrow('DATA DI HP INI'),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Seluruh catatan, rekaman, dan foto kartu tersimpan di HP ini.'
                  '${_dataMb == null ? '' : ' Ukurannya sekarang ${_dataMb!.toStringAsFixed(1).replaceAll('.', ',')} MB.'}'
                  ' Aplikasi tidak pernah menyalakan mikrofon sendiri.',
                  style: companionBodyStyle,
                ),
                const SizedBox(height: 16),
                EqualOutlineButton(label: 'Simpan salinan ke berkas', onPressed: _export),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _deleteAllData,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9B2C2C),
                      side: const BorderSide(color: Color(0xFF9B2C2C), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    child: Text('Hapus semua data $name'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Eyebrow('TENTANG'),
          CompanionCard(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Batas produk', style: _rowTitle),
                  trailing: const Text('Baca', style: _rowValue),
                  onTap: _showLimits,
                ),
                const Divider(height: 1, color: CompanionColors.line),
                const ListTile(
                  title: Text('Sumber simbol', style: _rowTitle),
                  subtitle: Text('Mulberry Symbols © Steve Lee, CC BY-SA 4.0, mulberrysymbols.org', style: companionMutedStyle),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const CompanionCard(
            color: CompanionColors.sand,
            child: Text(
              'Nyambung adalah alat bantu komunikasi dan pencatatan. Bukan alat diagnosis dan bukan pengganti terapi.',
              style: companionBodyStyle,
            ),
          ),
          const SizedBox(height: 20),
          const _Eyebrow('TEKNIS'),
          CompanionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alamat server', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: _server,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(onPressed: _testing ? null : _saveServer, child: Text(_testing ? 'Menguji…' : 'Uji')),
                ),
                if (_connectionResult != null) Text(_connectionResult!, style: companionMutedStyle),
                const Divider(height: 28, color: CompanionColors.line),
                Text(
                  'Suara Bahasa Indonesia: ${app?.speech.ttsIdAvailable == true ? 'tersedia' : 'tidak tersedia'} · '
                  'jeda ${app?.speech.firstUtteranceLatencyMs ?? '-'} ms',
                  style: companionMutedStyle,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(onPressed: _testVoice, child: const Text('Uji suara')),
                    OutlinedButton(onPressed: _showDiagnostics, child: const Text('Diagnosa')),
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

const _rowTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CompanionColors.ink);
const _rowValue = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: CompanionColors.muted);

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: CompanionColors.muted),
    ),
  );
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
