/// Model data perangkat, satu kelas per tabel kontrak §1.
/// Nama `WordSymbol` (bukan `Symbol`) supaya tidak bertabrakan dengan `dart:core`.
library;

import 'dart:convert';

class Child {
  const Child({
    required this.childId,
    required this.nickname,
    required this.ageYears,
    required this.gridCols,
    required this.routine,
    required this.createdAt,
  });

  final String childId;
  final String nickname;
  final int? ageYears;
  final int gridCols;
  final String routine;
  final String createdAt;

  factory Child.fromRow(Map<String, Object?> r) => Child(
    childId: r['child_id']! as String,
    nickname: r['nickname']! as String,
    ageYears: r['age_years'] as int?,
    gridCols: r['grid_cols']! as int,
    routine: r['routine']! as String,
    createdAt: r['created_at']! as String,
  );

  Map<String, Object?> toRow() => {
    'child_id': childId,
    'nickname': nickname,
    'age_years': ageYears,
    'grid_cols': gridCols,
    'routine': routine,
    'created_at': createdAt,
  };
}

class WordSymbol {
  const WordSymbol({
    required this.wordId,
    required this.labelDisplay,
    required this.labelSpeech,
    required this.pos,
    required this.category,
    required this.page,
    required this.positionIndex,
    required this.symbolPath,
    this.audioPath,
    this.familyAudio,
    this.isHidden = false,
    this.isCustom = false,
  });

  final String wordId;
  final String labelDisplay;
  final String labelSpeech;
  final String pos;
  final String category;
  final int page;
  final int positionIndex;

  /// Jalur aset, mis. `assets/symbols/png/mau.png` atau `assets/symbols/custom/aku.png`.
  final String symbolPath;
  final String? audioPath;

  /// Rekaman keluarga. Tidak pernah disinkronkan dan tidak pernah meninggalkan perangkat.
  final String? familyAudio;
  final bool isHidden;
  final bool isCustom;

  factory WordSymbol.fromRow(Map<String, Object?> r) => WordSymbol(
    wordId: r['word_id']! as String,
    labelDisplay: r['label_display']! as String,
    labelSpeech: r['label_speech']! as String,
    pos: r['pos']! as String,
    category: r['category']! as String,
    page: r['page']! as int,
    positionIndex: r['position_index']! as int,
    symbolPath: r['symbol_path']! as String,
    audioPath: r['audio_path'] as String?,
    familyAudio: r['family_audio'] as String?,
    isHidden: (r['is_hidden'] as int? ?? 0) != 0,
    isCustom: (r['is_custom'] as int? ?? 0) != 0,
  );

  Map<String, Object?> toRow() => {
    'word_id': wordId,
    'label_display': labelDisplay,
    'label_speech': labelSpeech,
    'pos': pos,
    'category': category,
    'page': page,
    'position_index': positionIndex,
    'symbol_path': symbolPath,
    'audio_path': audioPath,
    'family_audio': familyAudio,
    'is_hidden': isHidden ? 1 : 0,
    'is_custom': isCustom ? 1 : 0,
  };

  @override
  String toString() => 'WordSymbol($wordId @$page:$positionIndex)';
}

/// Satu baris `utterance_event`. Isinya tidak pernah diubah; hanya `syncedAt` yang boleh diisi.
class UtteranceEvent {
  const UtteranceEvent({
    required this.eventId,
    required this.childId,
    required this.tsDevice,
    required this.content,
    required this.method,
    required this.actor,
    required this.promptLevel,
    required this.context,
    required this.sessionId,
    this.syncedAt,
  });

  final String eventId;
  final String childId;
  final String tsDevice;
  final String content;
  final String method;
  final String actor;
  final String promptLevel;
  final String? context;
  final String sessionId;
  final String? syncedAt;

  factory UtteranceEvent.fromRow(Map<String, Object?> r) => UtteranceEvent(
    eventId: r['event_id']! as String,
    childId: r['child_id']! as String,
    tsDevice: r['ts_device']! as String,
    content: r['content']! as String,
    method: r['method']! as String,
    actor: r['actor']! as String,
    promptLevel: r['prompt_level']! as String,
    context: r['context'] as String?,
    sessionId: r['session_id']! as String,
    syncedAt: r['synced_at'] as String?,
  );

  Map<String, Object?> toRow() => {
    'event_id': eventId,
    'child_id': childId,
    'ts_device': tsDevice,
    'content': content,
    'method': method,
    'actor': actor,
    'prompt_level': promptLevel,
    'context': context,
    'session_id': sessionId,
    'synced_at': syncedAt,
  };

  /// Bentuk JSON untuk `POST /v1/sync/events` (kontrak §4). Tanpa `child_id` dan `synced_at`:
  /// `child_id` ada di amplop, `synced_at` hanya urusan perangkat.
  Map<String, Object?> toSyncJson() => {
    'event_id': eventId,
    'ts_device': tsDevice,
    'content': content,
    'method': method,
    'actor': actor,
    'prompt_level': promptLevel,
    'context': context,
    'session_id': sessionId,
  };
}

class Mission {
  const Mission({
    required this.missionId,
    required this.weekIndex,
    required this.targetWord,
    required this.routine,
    this.repsTarget = 5,
    this.lessonKey,
  });

  final String missionId;
  final int weekIndex;
  final String targetWord;
  final String routine;
  final int repsTarget;
  final String? lessonKey;

  factory Mission.fromRow(Map<String, Object?> r) => Mission(
    missionId: r['mission_id']! as String,
    weekIndex: r['week_index']! as int,
    targetWord: r['target_word']! as String,
    routine: r['routine']! as String,
    repsTarget: r['reps_target']! as int,
    lessonKey: r['lesson_key'] as String?,
  );

  Map<String, Object?> toRow() => {
    'mission_id': missionId,
    'week_index': weekIndex,
    'target_word': targetWord,
    'routine': routine,
    'reps_target': repsTarget,
    'lesson_key': lessonKey,
  };
}

class MissionLog {
  const MissionLog({required this.missionId, required this.date, required this.status, required this.repsCounted});

  final String missionId;
  final String date;
  final String status;
  final int repsCounted;

  factory MissionLog.fromRow(Map<String, Object?> r) => MissionLog(
    missionId: r['mission_id']! as String,
    date: r['date']! as String,
    status: r['status']! as String,
    repsCounted: r['reps_counted']! as int,
  );
}

class VocabTarget {
  const VocabTarget({
    required this.targetId,
    required this.words,
    required this.note,
    required this.weekIndex,
    required this.status,
    required this.receivedAt,
  });

  final String targetId;
  final List<String> words;
  final String? note;
  final int? weekIndex;
  final String status;
  final String? receivedAt;

  factory VocabTarget.fromRow(Map<String, Object?> r) => VocabTarget(
    targetId: r['target_id']! as String,
    words: (jsonDecode(r['words']! as String) as List).cast<String>(),
    note: r['note'] as String?,
    weekIndex: r['week_index'] as int?,
    status: r['status']! as String,
    receivedAt: r['received_at'] as String?,
  );

  Map<String, Object?> toRow() => {
    'target_id': targetId,
    'words': jsonEncode(words),
    'note': note,
    'week_index': weekIndex,
    'status': status,
    'received_at': receivedAt,
  };
}

class TherapistLink {
  const TherapistLink({required this.linkId, required this.inviteCode, this.therapist, this.linkedAt, this.revokedAt});

  final String linkId;
  final String inviteCode;
  final String? therapist;
  final String? linkedAt;
  final String? revokedAt;

  bool get isActive => revokedAt == null && linkedAt != null;

  factory TherapistLink.fromRow(Map<String, Object?> r) => TherapistLink(
    linkId: r['link_id']! as String,
    inviteCode: r['invite_code']! as String,
    therapist: r['therapist'] as String?,
    linkedAt: r['linked_at'] as String?,
    revokedAt: r['revoked_at'] as String?,
  );

  Map<String, Object?> toRow() => {
    'link_id': linkId,
    'invite_code': inviteCode,
    'therapist': therapist,
    'linked_at': linkedAt,
    'revoked_at': revokedAt,
  };
}
