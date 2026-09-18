package id.nyambung.nyambung

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Kunci layar papan anak (screen pinning). Aplikasi bukan device owner, jadi Android meminta
 * konfirmasi sekali saat pertama dipasang; setelahnya tombol Home tidak mengeluarkan anak dari papan.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "id.nyambung/kunci_anak").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "start" -> { startLockTask(); result.success(true) }
                    "stop" -> { stopLockTask(); result.success(true) }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("kunci_anak", e.message, null)
            }
        }
    }
}
