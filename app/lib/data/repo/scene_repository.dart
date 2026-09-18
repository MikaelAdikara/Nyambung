import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/speech_service.dart';
import '../db/scene_dao.dart';
import '../models.dart';
import '../scene.dart';

const _uuid = Uuid();

class ScenePublishException implements Exception {
  const ScenePublishException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SceneRepository {
  SceneRepository({required this.dao, required this.speech, required this.symbolById, this.documentsPath});

  final SceneDao dao;
  final SpeechService speech;
  final WordSymbol? Function(String) symbolById;
  final String? documentsPath;

  Future<String> _root() async => documentsPath ?? (await getApplicationDocumentsDirectory()).path;

  Future<List<SceneBoard>> list(String childId) => dao.list(childId);

  Future<void> cleanup(String childId) async {
    final root = Directory(p.join(await _root(), 'scenes'));
    if (!await root.exists()) return;
    final rootPath = p.normalize(p.absolute(root.path));
    final referenced = await dao.referencedImagePaths(childId);
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final path = p.normalize(p.absolute(entity.path));
      if (!p.isWithin(rootPath, path)) continue;
      if (p.basename(path).endsWith('.staging') || !referenced.contains(path)) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<String> stageDraftImage(String draftId, String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const ScenePublishException('Foto tidak ditemukan.');
    }
    final dir = Directory(p.join(await _root(), 'scenes', 'drafts', draftId));
    await dir.create(recursive: true);
    final staging = File(p.join(dir.path, 'photo.staging'));
    final destination = File(p.join(dir.path, 'photo.jpg'));
    await source.copy(staging.path);
    if (await destination.exists()) await destination.delete();
    await staging.rename(destination.path);
    return destination.path;
  }

  Future<SceneBoard> publish({
    required String childId,
    required String title,
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
    required List<DraftHotspot> hotspots,
    required String source,
    String? draftId,
    SceneBoard? existing,
  }) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 40) {
      throw const ScenePublishException('Judul wajib 1–40 karakter.');
    }
    if (hotspots.isEmpty || hotspots.length > 6) {
      throw const ScenePublishException('Pilih 1–6 area bicara.');
    }
    final finalHotspots = <SceneHotspot>[];
    for (final draft in hotspots) {
      final wordId = draft.wordId;
      final symbol = wordId == null ? null : symbolById(wordId);
      if (symbol == null || symbol.isHidden) {
        throw const ScenePublishException('Semua area harus memakai kata yang tersedia.');
      }
      if (!await speech.hasOfflineChildAudio(symbol)) {
        throw ScenePublishException('${symbol.labelDisplay} belum memiliki suara anak yang tersedia luring.');
      }
      finalHotspots.add(SceneHotspot(id: draft.id, box: draft.box, wordId: wordId!));
    }
    final sourceFile = File(imagePath);
    if (!await sourceFile.exists() || await sourceFile.length() == 0) {
      throw const ScenePublishException('Foto tidak ditemukan.');
    }
    final sceneId = existing?.sceneId ?? _uuid.v4();
    final revision = (existing?.revision ?? 0) + 1;
    final dir = Directory(p.join(await _root(), 'scenes', sceneId, 'r$revision'));
    await dir.create(recursive: true);
    final staging = File(p.join(dir.path, 'photo.staging'));
    final destination = File(p.join(dir.path, 'photo.jpg'));
    try {
      await sourceFile.copy(staging.path);
      await staging.rename(destination.path);
      final now = DateTime.now().toUtc().toIso8601String();
      final board = SceneBoard(
        sceneId: sceneId,
        childId: childId,
        title: cleanTitle,
        imagePath: destination.path,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        revision: revision,
        payload: ScenePayload(hotspots: finalHotspots),
        source: source,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await dao.save(board, deleteDraftId: draftId);
      return board;
    } catch (_) {
      try {
        if (await staging.exists()) await staging.delete();
      } catch (_) {}
      rethrow;
    }
  }
}
