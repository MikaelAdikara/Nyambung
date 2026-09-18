/// Frasa bersuara: teks bebas (mis. "Jangan nyontek") dengan klip suara yang dibuat sekali di server, lalu diunduh
/// dan diputar luring. Di papan, frasa menjadi kartu personal dengan `word_id` `frs-<slug>-<8 hex phrase_id>`.
/// Rumus yang sama ada di server (`server/app/services/voice.py`), supaya ketukan kartu frasa bisa dihitung di sana.
library;

const phrasePrefix = 'frs-';

/// Panjang teks frasa (sama dengan batas server).
const phraseTextMax = 60;

bool isPhraseWordId(String wordId) => wordId.startsWith(phrasePrefix);

String phraseWordId(String text, String phraseId) {
  var slug = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  if (slug.length > 24) slug = slug.substring(0, 24).replaceAll(RegExp(r'_+$'), '');
  return '$phrasePrefix${slug.isEmpty ? 'frasa' : slug}-${phraseId.replaceAll('-', '').substring(0, 8)}';
}

/// Rapikan spasi, sama seperti server.
String normalizePhraseText(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

abstract final class PhraseVoice {
  static const cowo = 'cowo';
  static const cewe = 'cewe';
  static const keluarga = 'keluarga';

  static String label(String voice) => switch (voice) {
    cowo => 'Suara papan (cowok)',
    cewe => 'Suara papan (cewek)',
    keluarga => 'Suara keluarga',
    _ => voice,
  };
}

abstract final class PhraseStatus {
  static const usulan = 'usulan';
  static const diterima = 'diterima';
  static const ditolak = 'ditolak';
}

class Phrase {
  const Phrase({
    required this.phraseId,
    required this.text,
    required this.voice,
    required this.createdBy,
    required this.createdAt,
    required this.status,
    this.audioPath,
  });

  final String phraseId;
  final String text;
  final String voice;

  /// `keluarga` atau nama terapis.
  final String createdBy;
  final String createdAt;
  final String status;

  /// Klip di folder aplikasi `phrases/`, null sampai terunduh.
  final String? audioPath;

  bool get fromFamily => createdBy == 'keluarga';
  String get wordId => phraseWordId(text, phraseId);

  factory Phrase.fromRow(Map<String, Object?> r) => Phrase(
    phraseId: r['phrase_id']! as String,
    text: r['text']! as String,
    voice: r['voice']! as String,
    createdBy: r['created_by']! as String,
    createdAt: r['created_at']! as String,
    status: r['status']! as String,
    audioPath: r['audio_path'] as String?,
  );

  factory Phrase.fromJson(Map<String, dynamic> j) => Phrase(
    phraseId: j['phrase_id']! as String,
    text: j['text']! as String,
    voice: j['voice']! as String,
    createdBy: j['created_by']! as String,
    createdAt: j['created_at']! as String,
    status: j['status']! as String,
  );

  Map<String, Object?> toRow() => {
    'phrase_id': phraseId,
    'text': text,
    'voice': voice,
    'created_by': createdBy,
    'created_at': createdAt,
    'status': status,
    'audio_path': audioPath,
  };
}
