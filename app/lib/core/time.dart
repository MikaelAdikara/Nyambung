/// Waktu lokal ISO-8601 **dengan** offset zona waktu, mis. `2026-09-18T10:15:00+07:00`.
/// Server menolak `ts_device` tanpa zona (422).
String isoWithOffset(DateTime t) {
  final local = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final off = local.timeZoneOffset;
  final sign = off.isNegative ? '-' : '+';
  final mins = off.inMinutes.abs();
  return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}'
      'T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$sign${two(mins ~/ 60)}:${two(mins % 60)}';
}

/// Waktu sekarang dalam format [isoWithOffset].
String nowIso() => isoWithOffset(DateTime.now());

/// Tanggal lokal `YYYY-MM-DD`.
String localDate(DateTime t) {
  final l = t.toLocal();
  return '${l.year.toString().padLeft(4, '0')}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}
