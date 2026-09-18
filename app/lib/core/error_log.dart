import 'package:flutter/foundation.dart';

/// Satu kesalahan yang tertangkap.
class ErrorEntry {
  const ErrorEntry(this.at, this.source, this.message, this.stack);

  final DateTime at;
  final String source;
  final String message;
  final String stack;

  @override
  String toString() => '[${at.toIso8601String()}] $source: $message\n$stack';
}

/// Menyimpan 20 kesalahan terakhir di memori, ditampilkan C6 "Diagnosa".
class ErrorLog {
  ErrorLog._();

  static const capacity = 20;
  static final List<ErrorEntry> _entries = [];

  static List<ErrorEntry> get entries => List.unmodifiable(_entries.reversed);

  static void record(String source, Object error, [StackTrace? stack]) {
    final lines = (stack ?? StackTrace.empty).toString().split('\n').take(8).join('\n');
    _entries.add(ErrorEntry(DateTime.now(), source, error.toString(), lines));
    if (_entries.length > capacity) _entries.removeAt(0);
    debugPrint('ErrorLog[$source]: $error');
  }

  /// Teks siap salin untuk C6.
  static String asText() => entries.map((e) => e.toString()).join('\n\n');
}
