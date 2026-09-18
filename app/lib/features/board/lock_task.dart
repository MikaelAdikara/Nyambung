import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../core/error_log.dart';

/// Screen pinning Android untuk papan anak (`startLockTask`/`stopLockTask` di `MainActivity.kt`).
/// Gagal tidak pernah menghalangi papan terbuka; kunci layar hanya lapisan tambahan di atas PopScope.
abstract final class LockTask {
  static const _channel = MethodChannel('id.nyambung/kunci_anak');

  static Future<void> start() => _call('start');

  static Future<void> stop() => _call('stop');

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<bool>(method).timeout(Limits.pluginTimeout);
    } catch (e, st) {
      ErrorLog.record('kunci_anak:$method', e, st);
    }
  }
}
