import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../scene.dart';

class SceneDao {
  const SceneDao(this.db);
  final Database db;

  Future<List<SceneBoard>> list(String childId) async {
    final rows = await db.query(
      'scene_board',
      where: 'child_id = ? AND archived_at IS NULL',
      whereArgs: [childId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(SceneBoard.fromRow).toList();
  }

  Future<SceneBoard?> get(String sceneId) async {
    final rows = await db.query('scene_board', where: 'scene_id = ?', whereArgs: [sceneId], limit: 1);
    return rows.isEmpty ? null : SceneBoard.fromRow(rows.first);
  }

  Future<void> save(SceneBoard board, {String? deleteDraftId}) async {
    await db.transaction((txn) async {
      await txn.insert('scene_board', board.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);
      if (deleteDraftId != null) {
        await txn.delete('scene_draft', where: 'draft_id = ?', whereArgs: [deleteDraftId]);
      }
    });
  }

  Future<void> archive(String sceneId, String at) =>
      db.update('scene_board', {'archived_at': at, 'updated_at': at}, where: 'scene_id = ?', whereArgs: [sceneId]);

  Future<void> saveDraft(SceneDraft draft) => db.insert('scene_draft', draft.toRow(), conflictAlgorithm: ConflictAlgorithm.replace);

  Future<SceneDraft?> getDraft(String draftId) async {
    final rows = await db.query('scene_draft', where: 'draft_id = ?', whereArgs: [draftId], limit: 1);
    return rows.isEmpty ? null : SceneDraft.fromRow(rows.first);
  }

  Future<SceneDraft?> latestDraft(String childId, {String? sceneId}) async {
    final rows = await db.query(
      'scene_draft',
      where: sceneId == null ? 'child_id = ? AND scene_id IS NULL' : 'child_id = ? AND scene_id = ?',
      whereArgs: sceneId == null ? [childId] : [childId, sceneId],
      orderBy: 'updated_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : SceneDraft.fromRow(rows.first);
  }

  Future<void> deleteDraft(String draftId) => db.delete('scene_draft', where: 'draft_id = ?', whereArgs: [draftId]);

  Future<Set<String>> referencedImagePaths(String childId) async {
    final boards = await db.query('scene_board', columns: ['image_path'], where: 'child_id = ?', whereArgs: [childId]);
    final drafts = await db.query(
      'scene_draft',
      columns: ['image_path'],
      where: 'child_id = ? AND image_path IS NOT NULL',
      whereArgs: [childId],
    );
    return {
      for (final row in [...boards, ...drafts])
        if (row['image_path'] case final String path) p.normalize(p.absolute(path)),
    };
  }
}
