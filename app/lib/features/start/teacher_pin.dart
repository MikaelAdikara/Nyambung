import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent_pin.dart';

/// Pilihan masa berlaku PIN guru. `null` = tidak kedaluwarsa.
const teacherPinDurations = <int?>[1, 3, 5, 7, null];

String teacherPinDurationLabel(int? days) => days == null ? 'Tidak kedaluwarsa' : '$days hari';

/// PIN guru: orang tua menitipkan akses "buat frasa dengan suara keluarga" ke satu orang (guru, pengasuh) lewat
/// PIN 4 angka. Satu PIN per orang, supaya setiap frasa tercatat atas nama pembuatnya dan satu PIN bisa dicabut
/// tanpa mengganggu yang lain. Seperti PIN orang tua, disimpan sebagai SHA-256 bergaram dan tidak pernah ke server.
class TeacherPin {
  const TeacherPin({required this.id, required this.name, required this.salt, required this.hash, required this.createdAt, this.expiresAt});

  final String id;
  final String name;
  final String salt;
  final String hash;
  final DateTime createdAt;

  /// null = tidak kedaluwarsa.
  final DateTime? expiresAt;

  bool isExpired(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);

  bool matches(String pin) => _hash(salt, pin) == hash;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'salt': salt,
    'hash': hash,
    'created_at': createdAt.toIso8601String(),
    'expires_at': expiresAt?.toIso8601String(),
  };

  factory TeacherPin.fromJson(Map<String, dynamic> j) => TeacherPin(
    id: j['id'] as String,
    name: j['name'] as String,
    salt: j['salt'] as String,
    hash: j['hash'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    expiresAt: j['expires_at'] == null ? null : DateTime.parse(j['expires_at'] as String),
  );
}

/// Satu frasa yang dibuat seseorang lewat mode guru. Orang tua melihat daftarnya di Kelola PIN guru.
class TeacherPhraseLog {
  const TeacherPhraseLog({
    required this.phraseId,
    required this.pinId,
    required this.teacher,
    required this.text,
    required this.voice,
    required this.at,
  });

  final String phraseId;
  final String pinId;
  final String teacher;
  final String text;
  final String voice;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'phrase_id': phraseId,
    'pin_id': pinId,
    'teacher': teacher,
    'text': text,
    'voice': voice,
    'at': at.toIso8601String(),
  };

  factory TeacherPhraseLog.fromJson(Map<String, dynamic> j) => TeacherPhraseLog(
    phraseId: j['phrase_id'] as String,
    pinId: j['pin_id'] as String,
    teacher: j['teacher'] as String,
    text: j['text'] as String,
    voice: j['voice'] as String,
    at: DateTime.parse(j['at'] as String),
  );
}

String _hash(String salt, String pin) => sha256.convert(utf8.encode('guru:$salt:$pin')).toString();

class TeacherPinStore {
  TeacherPinStore(this.prefs);

  final SharedPreferences prefs;

  static const _pinsKey = 'teacher_pins_v1';
  static const _logKey = 'teacher_phrase_log_v1';

  List<TeacherPin> all() {
    final raw = prefs.getString(_pinsKey);
    if (raw == null) return [];
    try {
      return [for (final j in jsonDecode(raw) as List) TeacherPin.fromJson(Map<String, dynamic>.from(j as Map))];
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<TeacherPin> pins) => prefs.setString(_pinsKey, jsonEncode([for (final p in pins) p.toJson()]));

  bool get hasActive => all().any((p) => !p.isExpired(DateTime.now()));

  /// Alasan PIN ini tidak boleh dipakai, atau null bila boleh. PIN harus beda dari PIN orang tua dan dari PIN guru
  /// lain yang masih aktif, supaya satu PIN selalu menunjuk satu orang.
  String? conflict(String pin) {
    if (!ParentPin.valid(pin)) return 'PIN harus 4 angka.';
    if (ParentPin.check(prefs, pin)) return 'PIN ini sama dengan PIN orang tua. Pilih angka lain.';
    final now = DateTime.now();
    if (all().any((p) => !p.isExpired(now) && p.matches(pin))) return 'PIN ini sudah dipakai orang lain. Pilih angka lain.';
    return null;
  }

  Future<TeacherPin> create({required String name, required String pin, required int? days, DateTime? now}) async {
    final problem = conflict(pin);
    if (problem != null) throw ArgumentError(problem);
    final at = now ?? DateTime.now();
    final r = math.Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
    final item = TeacherPin(
      id: base64Url.encode(List<int>.generate(9, (_) => r.nextInt(256))),
      name: name.trim(),
      salt: salt,
      hash: _hash(salt, pin),
      createdAt: at,
      expiresAt: days == null ? null : at.add(Duration(days: days)),
    );
    await _save([...all(), item]);
    return item;
  }

  /// Perpanjang dari sekarang (atau jadikan tidak kedaluwarsa). PIN yang sudah kedaluwarsa ikut hidup lagi.
  Future<void> extend(String id, int? days) async {
    final now = DateTime.now();
    await _save([
      for (final p in all())
        p.id == id
            ? TeacherPin(
                id: p.id,
                name: p.name,
                salt: p.salt,
                hash: p.hash,
                createdAt: p.createdAt,
                expiresAt: days == null ? null : now.add(Duration(days: days)),
              )
            : p,
    ]);
  }

  Future<void> revoke(String id) => _save([
    for (final p in all())
      if (p.id != id) p,
  ]);

  /// PIN aktif yang cocok, atau null. PIN kedaluwarsa tidak pernah cocok.
  TeacherPin? unlock(String pin, {DateTime? now}) {
    final at = now ?? DateTime.now();
    for (final p in all()) {
      if (!p.isExpired(at) && p.matches(pin)) return p;
    }
    return null;
  }

  /// Masih aktif? Dicek ulang sebelum setiap frasa, karena PIN bisa kedaluwarsa saat guru masih di mode guru.
  bool isActive(String id) => all().any((p) => p.id == id && !p.isExpired(DateTime.now()));

  List<TeacherPhraseLog> log() {
    final raw = prefs.getString(_logKey);
    if (raw == null) return [];
    try {
      return [for (final j in jsonDecode(raw) as List) TeacherPhraseLog.fromJson(Map<String, dynamic>.from(j as Map))];
    } catch (_) {
      return [];
    }
  }

  Future<void> addLog(TeacherPhraseLog entry) => prefs.setString(
    _logKey,
    jsonEncode([
      for (final e in [entry, ...log()]) e.toJson(),
    ]),
  );

  Future<void> removeLog(String phraseId) => prefs.setString(
    _logKey,
    jsonEncode([
      for (final e in log())
        if (e.phraseId != phraseId) e.toJson(),
    ]),
  );
}
