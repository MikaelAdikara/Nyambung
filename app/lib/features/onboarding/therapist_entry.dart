import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../coach/companion_widgets.dart';

/// Pintu terapis dari A1. Aplikasi ini untuk keluarga; terapis bekerja di papan pantau web dengan
/// email + kata sandi. Di sini tidak dibuat profil anak dan tidak ada yang tersimpan.
Future<void> showTherapistEntry(BuildContext context) {
  final app = AppScope.of(context);
  final url = dashboardUrlFor(ServerConfig.resolve(app.prefs.getString(PrefKeys.serverUrl)));
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CompanionColors.bg,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Untuk terapis', style: AppText.h1),
            const SizedBox(height: 12),
            const Text('Terapis memantau keluarga lewat papan pantau di browser.', style: companionBodyStyle),
            const SizedBox(height: 16),
            CompanionCard(
              padding: const EdgeInsets.all(16),
              child: SelectableText(url, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Salin alamat',
              icon: Icons.copy,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat disalin.')));
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('Buat kode undangan di papan pantau, lalu keluarga memasukkannya di tab Terapis.', style: companionMutedStyle),
          ],
        ),
      ),
    ),
  );
}

/// Papan pantau berjalan di mesin yang sama dengan server, port 5173 (README). Alamat server
/// diambil dari pengaturan; belum diatur → alamat bawaan.
String dashboardUrlFor(String? serverUrl) {
  final uri = Uri.tryParse((serverUrl ?? '').trim());
  final host = (uri != null && uri.host.isNotEmpty) ? uri.host : '127.0.0.1';
  return 'http://$host:5173';
}
