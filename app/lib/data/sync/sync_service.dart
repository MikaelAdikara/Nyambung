import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import 'link_service.dart';
import 'phrase_service.dart';

enum SyncState { notLinked, offline, linkedRevoked, complete }

class SyncReport {
  const SyncReport(this.state, {this.accepted = 0, this.duplicates = 0});

  final SyncState state;
  final int accepted;
  final int duplicates;
}

class SyncService {
  SyncService(this.app, {http.Client? client}) : _client = client ?? http.Client();

  static const _healthTimeout = Duration(seconds: 3);
  static const _requestTimeout = Duration(seconds: 10);

  final AppState app;
  final http.Client _client;

  String get _baseUrl => serverBaseUrl(app);

  /// Alamat server: isian di Atur bila ada, selain itu alamat yang ditanam saat build.
  static String serverBaseUrl(AppState app) => ServerConfig.resolve(app.prefs.getString(PrefKeys.serverUrl));

  Future<SyncReport> push(String childId) async {
    if (app.prefs.getString(LinkService.pendingRevokeLinkKey) != null) {
      final revoked = await LinkService(app, client: _client).retryPendingRevocation();
      if (!revoked) return const SyncReport(SyncState.offline);
    }
    final link = await app.linkDao.active();
    final token = app.prefs.getString(PrefKeys.deviceToken);
    if (link == null || token == null || token.isEmpty) return const SyncReport(SyncState.notLinked);

    try {
      final health = await _client.get(Uri.parse('$_baseUrl/v1/health')).timeout(_healthTimeout);
      if (health.statusCode != 200) return const SyncReport(SyncState.offline);
      final healthBody = jsonDecode(health.body);
      if (healthBody is! Map<String, dynamic> || healthBody['ok'] != true) return const SyncReport(SyncState.offline);
    } catch (_) {
      return const SyncReport(SyncState.offline);
    }

    var accepted = 0;
    var duplicates = 0;
    while (true) {
      final batch = await app.eventDao.pendingBatch(limit: Limits.syncBatch);
      if (batch.isEmpty) break;
      final ids = batch.map((event) => event.eventId).toList(growable: false);
      http.Response response;
      try {
        response = await _client
            .post(
              Uri.parse('$_baseUrl/v1/sync/events'),
              headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode({'child_id': childId, 'events': batch.map((event) => event.toSyncJson()).toList()}),
            )
            .timeout(_requestTimeout);
      } catch (_) {
        await app.eventDao.defer(ids);
        return SyncReport(SyncState.offline, accepted: accepted, duplicates: duplicates);
      }
      if (response.statusCode == 401) {
        await _markRevoked(link.linkId);
        return SyncReport(SyncState.linkedRevoked, accepted: accepted, duplicates: duplicates);
      }
      if (response.statusCode != 200) {
        await app.eventDao.defer(ids);
        return SyncReport(SyncState.offline, accepted: accepted, duplicates: duplicates);
      }
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        accepted += body['accepted'] as int? ?? 0;
        duplicates += body['duplicates'] as int? ?? 0;
      } catch (_) {
        await app.eventDao.defer(ids);
        return SyncReport(SyncState.offline, accepted: accepted, duplicates: duplicates);
      }
      await app.eventDao.markSynced(ids, nowIso());
    }
    await pullTargets(childId, token: token);
    await pullSummaries(childId, token: token);
    await PhraseService(app, client: _client).pull(childId);
    app.markDataChanged();
    return SyncReport(SyncState.complete, accepted: accepted, duplicates: duplicates);
  }

  Future<void> pullTargets(String childId, {String? token}) async {
    final deviceToken = token ?? app.prefs.getString(PrefKeys.deviceToken);
    if (deviceToken == null || deviceToken.isEmpty || await app.linkDao.active() == null) return;
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/v1/children/$childId/targets'), headers: {'Authorization': 'Bearer $deviceToken'})
          .timeout(_requestTimeout);
      if (response.statusCode == 401) {
        final link = await app.linkDao.active();
        if (link != null) await _markRevoked(link.linkId);
        return;
      }
      if (response.statusCode != 200) return;
      final rows = jsonDecode(response.body) as List<dynamic>;
      for (final raw in rows) {
        final row = raw as Map<String, dynamic>;
        await app.targetDao.upsertFromServer(
          VocabTarget(
            targetId: row['target_id']! as String,
            words: (row['words']! as List<dynamic>).cast<String>(),
            note: row['note'] as String?,
            weekIndex: row['week_index'] as int?,
            status: row['status']! as String,
            receivedAt: row['created_at'] as String?,
          ),
        );
      }
      app.markDataChanged();
    } catch (_) {
      // Pull is best-effort. Local data remains the source of truth.
    }
  }

  /// Ringkasan sesi yang dikirim terapis ke keluarga (C5). Tarik terbaik-usaha, sama seperti target.
  Future<void> pullSummaries(String childId, {String? token}) async {
    final deviceToken = token ?? app.prefs.getString(PrefKeys.deviceToken);
    if (deviceToken == null || deviceToken.isEmpty || await app.linkDao.active() == null) return;
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/v1/children/$childId/shared-summaries'), headers: {'Authorization': 'Bearer $deviceToken'})
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return;
      for (final raw in jsonDecode(response.body) as List<dynamic>) {
        final row = raw as Map<String, dynamic>;
        await app.summaryDao.upsert(
          TherapistSummary(
            summaryId: row['summary_id']! as String,
            therapist: row['therapist'] as String?,
            sessionDate: row['session_date']! as String,
            familyText: row['family_text']! as String,
            focus: row['focus'] as String?,
            nextSession: row['next_session'] as String?,
            sharedAt: row['shared_at']! as String,
          ),
        );
      }
    } catch (_) {
      // Tarik terbaik-usaha. Data lokal tetap sumber kebenaran.
    }
  }

  Future<void> _markRevoked(String linkId) async {
    await app.linkDao.markRevoked(linkId, nowIso());
    await app.prefs.remove(PrefKeys.deviceToken);
    app.markDataChanged();
  }

  void close() => _client.close();
}
