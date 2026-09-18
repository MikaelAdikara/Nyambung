import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/app_state.dart';
import '../../core/time.dart';

class ExportService {
  const ExportService(this.app);

  final AppState app;

  Future<File> createJson({bool illustrative = false}) async {
    final events = await app.eventDao.all();
    final missionLogs = await app.missionDao.logs();
    final targets = await app.targetDao.all();
    final payload = <String, Object?>{
      'illustrative': illustrative,
      'exported_at': nowIso(),
      'utterance_event': events.map((event) => event.toRow()).toList(),
      'mission_log': missionLogs
          .map((log) => {'mission_id': log.missionId, 'date': log.date, 'status': log.status, 'reps_counted': log.repsCounted})
          .toList(),
      'vocab_target': targets
          .map(
            (target) => {
              'target_id': target.targetId,
              'words': target.words,
              'note': target.note,
              'week_index': target.weekIndex,
              'status': target.status,
              'received_at': target.receivedAt,
            },
          )
          .toList(),
    };
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(RegExp('[:.]'), '-');
    final file = File('${dir.path}${Platform.pathSeparator}nyambung-export-$stamp.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload), flush: true);
  }

  Future<ShareResult> share({bool illustrative = false}) async {
    final file = await createJson(illustrative: illustrative);
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: illustrative ? 'Ekspor Nyambung — data ilustratif' : 'Ekspor catatan Nyambung',
        subject: 'Catatan Nyambung',
      ),
    );
  }
}
