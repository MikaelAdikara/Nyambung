import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Permintaan membuka tab Terapis di beranda orang tua. Dinaikkan dari layar mana pun; [HomeScreen] mendengarkan.
final openTherapistTab = ValueNotifier<int>(0);

/// Penjelasan saat fitur daring (bantuan AI foto, frasa bersuara, suara keluarga) dipakai sebelum perangkat
/// ditautkan lewat kode undangan terapis. Token perangkat hanya keluar saat kode itu ditebus.
Future<void> showLinkRequiredDialog(BuildContext context, {required String feature}) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Butuh kode dari terapis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$feature memakai server Nyambung. Server hanya melayani HP yang sudah ditautkan dengan kode undangan '
              'dari terapis, supaya data anak tidak bisa diminta sembarang perangkat.',
              style: AppText.body,
            ),
            const SizedBox(height: 14),
            const Text('Cara menautkan', style: AppText.bodyStrong),
            const SizedBox(height: 6),
            for (final (i, step) in const [
              'Terapis membuat kode undangan di papan pantau Nyambung.',
              'Pastikan Atur → Alamat server sudah benar dan tombol Uji berhasil.',
              'Buka tab Terapis di bawah, masukkan kodenya, lalu kirim.',
            ].indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${i + 1}. $step', style: AppText.body),
              ),
            const SizedBox(height: 10),
            const Text('Papan bicara, misi, dan papan yang sudah tersimpan tetap jalan tanpa kode ini.', style: AppText.cap),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nanti')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Buka tab Terapis')),
      ],
    ),
  );
  if (open == true && context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    openTherapistTab.value++;
  }
}
