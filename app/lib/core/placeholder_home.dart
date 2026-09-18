import 'package:flutter/material.dart';

import 'app_state.dart';
import 'constants.dart';
import 'theme.dart';

/// Pengganti sementara A1 (pemasangan, milik jalur 2). Hanya untuk uji jalur 1 sebelum A1–A6 ada.
class PlaceholderOnboarding extends StatelessWidget {
  const PlaceholderOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Nyambung', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Pemasangan A1–A6 menyusul (jalur 2).'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => app.createChild(nickname: 'Arka (ilustratif)', ageYears: 5, routine: Routine.makan),
                child: const Text('Buat anak contoh'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pengganti sementara B1 (beranda, milik jalur 2).
class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Halo, keluarga ${app.child?.nickname ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListenableBuilder(
                listenable: app,
                builder: (context, _) => Text(
                  'Beranda sementara (B1 menyusul dari jalur 2).\n'
                  'Kosakata: ${app.allSymbols.length} kata di ${app.pages.length} halaman.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Nyambung bukan alat diagnosis.', style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
