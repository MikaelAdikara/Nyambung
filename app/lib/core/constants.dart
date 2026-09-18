/// Konstanta bersama. Kode `method` dan `actor` mengikuti kontrak §3.
library;

abstract final class Method {
  static const sel = 'SEL'; // pilih simbol di halaman kata inti
  static const kat = 'KAT'; // pilih simbol di halaman kategori (termasuk sel cermin)
  static const prs = 'PRS'; // kartu personal keluarga
  static const hap = 'HAP'; // hapus satu langkah di bilah ujaran
  static const ucp = 'UCP'; // tekan UCAPKAN
  static const mis = 'MIS'; // konfirmasi misi harian
  static const tgt = 'TGT'; // jawaban keluarga atas usulan terapis

  /// Metode yang dihitung sebagai "ketukan" (kontrak §5).
  static const taps = {sel, kat, prs};
}

abstract final class Actor {
  static const anak = 'anak';
  static const pendamping = 'pendamping';
}

abstract final class PromptLevel {
  static const spontan = 'spontan';
  static const terpancing = 'terpancing';
}

abstract final class MissionStatus {
  static const selesai = 'selesai';
  static const belumSempat = 'belum_sempat';
}

abstract final class TargetStatus {
  static const usulan = 'usulan';
  static const diterima = 'diterima';
  static const ditolak = 'ditolak';
}

abstract final class Routine {
  static const makan = 'makan';
  static const mandi = 'mandi';
  static const main = 'main';
  static const all = [makan, mandi, main];
}

abstract final class Limits {
  /// Ukuran batch sinkron (kontrak §4: aplikasi kirim per batch 40).
  static const syncBatch = 40;

  /// Ketukan anak dihitung `terpancing` bila ada ketukan pendamping ≤ 60 detik sebelumnya.
  static const promptWindow = Duration(seconds: 60);

  /// Lama tahan tombol kunci mode anak.
  static const lockHold = Duration(milliseconds: 1500);

  /// Batas waktu setiap panggilan plugin saat bootstrap.
  static const pluginTimeout = Duration(seconds: 3);

  /// Batas tunggu satu klip kata selesai diputar saat UCAPKAN (klip terpanjang ± 1,2 detik).
  static const clipTimeout = Duration(seconds: 3);

  /// Pilihan "Tahan untuk memilih" di C6.
  static const holdMsOptions = [0, 300, 500, 800];
}

/// Alamat server. Bawaan ditanam saat build (`--dart-define=NYAMBUNG_SERVER=http://192.168.1.10:8000`, nanti alamat
/// VPS), jadi HP keluarga tersambung tanpa mengetik apa pun. Isian "Alamat server" di Atur hanya menimpa bila diisi.
abstract final class ServerConfig {
  static const defaultUrl = String.fromEnvironment('NYAMBUNG_SERVER', defaultValue: 'http://127.0.0.1:8000');

  /// Alamat tersimpan bila ada, selain itu bawaan build. `localhost` diganti `127.0.0.1` (di Windows mencoba IPv6
  /// dulu), garis miring akhir dibuang.
  static String resolve(String? saved) {
    final trimmed = saved?.trim() ?? '';
    final value = trimmed.isEmpty ? defaultUrl.trim() : trimmed;
    final normalized = value.replaceFirst('://localhost', '://127.0.0.1');
    return normalized.endsWith('/') ? normalized.substring(0, normalized.length - 1) : normalized;
  }
}

/// Kunci `shared_preferences`.
abstract final class PrefKeys {
  static const vocabLoaded = 'vocab_loaded_v1';
  static const holdMs = 'hold_ms';
  static const serverUrl = 'server_url';
  static const deviceToken = 'device_token';
  static const voiceSet = 'voice_set';

  /// Kunci mode anak (screen pinning) saat papan anak dibuka. Bawaan: aktif.
  static const childLock = 'child_lock';
}
