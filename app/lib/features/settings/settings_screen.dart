import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/error_log.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
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
  }

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
  Widget build(BuildContext context) => CompanionPage(
    title: 'Pengaturan',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
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
            ],
          ),
        ),
        const SizedBox(height: 12),
        CompanionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Uji suara', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Suara Bahasa Indonesia: ${_app?.speech.ttsIdAvailable == true ? 'tersedia' : 'tidak tersedia'} · '
                'jeda ${_app?.speech.firstUtteranceLatencyMs ?? '-'} ms',
                style: companionMutedStyle,
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _testVoice, child: const Text('Uji suara')),
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
                items: const [
                  0,
                  300,
                  500,
                  800,
                ].map((value) => DropdownMenuItem(value: value, child: Text(value == 0 ? 'Tidak ditahan' : '$value ms'))).toList(),
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
                groupValue: _app?.child?.routine,
                onChanged: (value) => value == null ? null : _changeRoutine(value),
                child: Column(
                  children: [
                    for (final routine in const ['makan', 'mandi', 'main'])
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
        ListTile(title: const Text('Ekspor catatan'), trailing: const Icon(Icons.chevron_right), onTap: _export),
        ListTile(title: const Text('Diagnosa'), trailing: const Icon(Icons.chevron_right), onTap: _showDiagnostics),
        ListTile(title: const Text('Hapus semua data'), trailing: const Icon(Icons.chevron_right), onTap: _deleteAllData),
        const Divider(),
        const Text('Simbol: Mulberry Symbols © Steve Lee, CC BY-SA 4.0, https://mulberrysymbols.org', style: companionMutedStyle),
        const SizedBox(height: 8),
        const Text('Nyambung bukan alat diagnosis.', style: companionMutedStyle),
      ],
    ),
  );
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
