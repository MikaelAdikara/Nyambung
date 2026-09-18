import 'dart:convert';

class SceneBox {
  const SceneBox({required this.x, required this.y, required this.width, required this.height})
    : assert(x >= 0 && y >= 0 && width > 0 && height > 0 && x + width <= 1 && y + height <= 1);

  factory SceneBox.checked({required double x, required double y, required double width, required double height}) {
    final values = [x, y, width, height];
    if (values.any((value) => !value.isFinite) || x < 0 || y < 0 || width <= 0 || height <= 0 || x + width > 1 || y + height > 1) {
      throw ArgumentError('Kotak harus finite dan berada di dalam foto.');
    }
    return SceneBox(x: x, y: y, width: width, height: height);
  }

  factory SceneBox.fromJson(Map<String, Object?> json) => SceneBox.checked(
    x: (json['x']! as num).toDouble(),
    y: (json['y']! as num).toDouble(),
    width: (json['width']! as num).toDouble(),
    height: (json['height']! as num).toDouble(),
  );

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, Object> toJson() => {'x': x, 'y': y, 'width': width, 'height': height};
}

class SceneHotspot {
  const SceneHotspot({required this.id, required this.box, required this.wordId});

  factory SceneHotspot.fromJson(Map<String, Object?> json) => SceneHotspot(
    id: json['id']! as String,
    box: SceneBox.fromJson(Map<String, Object?>.from(json['box']! as Map)),
    wordId: json['word_id']! as String,
  );

  final String id;
  final SceneBox box;
  final String wordId;

  Map<String, Object> toJson() => {'id': id, 'box': box.toJson(), 'word_id': wordId};
}

class DraftHotspot {
  const DraftHotspot({required this.id, required this.box, this.wordId, this.observedLabel});

  factory DraftHotspot.fromJson(Map<String, Object?> json) => DraftHotspot(
    id: json['id']! as String,
    box: SceneBox.fromJson(Map<String, Object?>.from(json['box']! as Map)),
    wordId: json['word_id'] as String?,
    observedLabel: json['observed_label'] as String?,
  );

  final String id;
  final SceneBox box;
  final String? wordId;
  final String? observedLabel;

  DraftHotspot copyWith({SceneBox? box, String? wordId, bool clearWord = false}) =>
      DraftHotspot(id: id, box: box ?? this.box, wordId: clearWord ? null : wordId ?? this.wordId, observedLabel: observedLabel);

  Map<String, Object?> toJson() => {'id': id, 'box': box.toJson(), 'word_id': wordId, 'observed_label': observedLabel};
}

class ScenePayload {
  ScenePayload({required this.hotspots, this.schemaVersion = 1}) {
    if (schemaVersion != 1 || hotspots.isEmpty || hotspots.length > 6) throw ArgumentError('Payload scene tidak sah.');
    if (hotspots.map((item) => item.id).toSet().length != hotspots.length) throw ArgumentError('ID hotspot harus unik.');
  }

  factory ScenePayload.fromJson(Map<String, Object?> json) {
    final version = json['schema_version'] as int? ?? 0;
    final rows = (json['hotspots'] as List? ?? const []).cast<Map>();
    return ScenePayload(
      schemaVersion: version,
      hotspots: rows.map((row) => SceneHotspot.fromJson(Map<String, Object?>.from(row))).toList(),
    );
  }

  final int schemaVersion;
  final List<SceneHotspot> hotspots;
  Map<String, Object> toJson() => {'schema_version': schemaVersion, 'hotspots': hotspots.map((item) => item.toJson()).toList()};
}

class DraftPayload {
  DraftPayload({required this.hotspots, required this.source, this.schemaVersion = 1}) {
    if (schemaVersion != 1 || hotspots.length > 6 || !{'manual', 'ai'}.contains(source)) throw ArgumentError('Draft scene tidak sah.');
    if (hotspots.map((item) => item.id).toSet().length != hotspots.length) throw ArgumentError('ID hotspot harus unik.');
  }

  factory DraftPayload.fromJson(Map<String, Object?> json) => DraftPayload(
    schemaVersion: json['schema_version'] as int? ?? 0,
    source: json['source'] as String? ?? 'manual',
    hotspots: ((json['hotspots'] as List?) ?? const [])
        .cast<Map>()
        .map((row) => DraftHotspot.fromJson(Map<String, Object?>.from(row)))
        .toList(),
  );

  final int schemaVersion;
  final String source;
  final List<DraftHotspot> hotspots;
  Map<String, Object> toJson() => {
    'schema_version': schemaVersion,
    'source': source,
    'hotspots': hotspots.map((item) => item.toJson()).toList(),
  };
}

class SceneBoard {
  const SceneBoard({
    required this.sceneId,
    required this.childId,
    required this.title,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.revision,
    required this.payload,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  factory SceneBoard.fromRow(Map<String, Object?> row) => SceneBoard(
    sceneId: row['scene_id']! as String,
    childId: row['child_id']! as String,
    title: row['title']! as String,
    imagePath: row['image_path']! as String,
    imageWidth: row['image_width']! as int,
    imageHeight: row['image_height']! as int,
    revision: row['revision']! as int,
    payload: ScenePayload.fromJson(jsonDecode(row['payload_json']! as String) as Map<String, Object?>),
    source: row['source']! as String,
    createdAt: row['created_at']! as String,
    updatedAt: row['updated_at']! as String,
    archivedAt: row['archived_at'] as String?,
  );

  final String sceneId;
  final String childId;
  final String title;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final int revision;
  final ScenePayload payload;
  final String source;
  final String createdAt;
  final String updatedAt;
  final String? archivedAt;

  Map<String, Object?> toRow() => {
    'scene_id': sceneId,
    'child_id': childId,
    'title': title,
    'image_path': imagePath,
    'image_width': imageWidth,
    'image_height': imageHeight,
    'revision': revision,
    'payload_json': jsonEncode(payload.toJson()),
    'source': source,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'archived_at': archivedAt,
  };
}

class SceneDraft {
  const SceneDraft({
    required this.draftId,
    required this.childId,
    required this.title,
    required this.payload,
    required this.updatedAt,
    this.sceneId,
    this.imagePath,
  });

  factory SceneDraft.fromRow(Map<String, Object?> row) => SceneDraft(
    draftId: row['draft_id']! as String,
    childId: row['child_id']! as String,
    sceneId: row['scene_id'] as String?,
    title: row['title']! as String,
    imagePath: row['image_path'] as String?,
    payload: DraftPayload.fromJson(jsonDecode(row['payload_json']! as String) as Map<String, Object?>),
    updatedAt: row['updated_at']! as String,
  );

  final String draftId;
  final String childId;
  final String? sceneId;
  final String title;
  final String? imagePath;
  final DraftPayload payload;
  final String updatedAt;

  Map<String, Object?> toRow() => {
    'draft_id': draftId,
    'child_id': childId,
    'scene_id': sceneId,
    'title': title,
    'image_path': imagePath,
    'payload_json': jsonEncode(payload.toJson()),
    'updated_at': updatedAt,
  };
}
