import 'package:flutter/material.dart';

import '../coach/companion_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _server = TextEditingController(text: 'http://127.0.0.1:8000');
  int _holdMs = 0;
  String? _connectionResult;

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
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
                child: OutlinedButton(onPressed: () => setState(() => _connectionResult = 'Tersambung.'), child: const Text('Uji')),
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
              const Text('Suara Bahasa Indonesia: tersedia · jeda 180 ms', style: companionMutedStyle),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () {}, child: const Text('Uji suara')),
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
                onChanged: (value) => setState(() => _holdMs = value ?? 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final label in const ['Ekspor catatan', 'Diagnosa', 'Hapus semua data'])
          ListTile(title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: () {}),
        const Divider(),
        const Text('Simbol: Mulberry Symbols © Steve Lee, CC BY-SA 4.0, https://mulberrysymbols.org', style: companionMutedStyle),
        const SizedBox(height: 8),
        const Text('Nyambung bukan alat diagnosis.', style: companionMutedStyle),
      ],
    ),
  );
}
