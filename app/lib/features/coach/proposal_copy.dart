/// Istilah bersama untuk dua kiriman terapis yang hasil akhirnya berbeda.
abstract final class ProposalCopy {
  static const targetTitle = 'Target kata';
  static const targetAccept = 'Terima sebagai misi';
  static const phraseTitle = 'Frasa audio';
  static const phraseAccept = 'Tambah ke papan';
  static const reject = 'Tidak dipakai';

  static String targetWaiting(int count) =>
      '$count target kata dari terapis menunggu keputusan';

  static String phraseWaiting(int count, String from) => count == 1
      ? 'Frasa audio dari $from menunggu keputusan'
      : '$count frasa audio menunggu keputusan';
}
