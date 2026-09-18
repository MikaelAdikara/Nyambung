import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/time.dart';
import '../../data/models.dart';

enum LinkResult { connected, unknownCode, expiredCode, offline, invalidResponse }

class LinkService {
  LinkService(this.app, {http.Client? client}) : _client = client ?? http.Client();

  static const pendingRevokeLinkKey = 'pending_revoke_link_id';
  static const _requestTimeout = Duration(seconds: 10);

  final AppState app;
  final http.Client _client;

  String get _baseUrl => ServerConfig.resolve(app.prefs.getString(PrefKeys.serverUrl));

  Future<LinkResult> redeem(String inviteCode) async {
    final child = app.child;
    if (child == null) return LinkResult.invalidResponse;
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/v1/link/redeem'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'invite_code': inviteCode.trim().toUpperCase(),
              'child_id': child.childId,
              'nickname': child.nickname,
              'age_years': child.ageYears,
              'routine': child.routine,
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode == 404) return LinkResult.unknownCode;
      if (response.statusCode == 410) return LinkResult.expiredCode;
      if (response.statusCode != 201) return LinkResult.invalidResponse;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final linkId = body['link_id'] as String?;
      final therapist = body['therapist'] as String?;
      final linkedAt = body['linked_at'] as String?;
      final token = body['device_token'] as String?;
      if (linkId == null || therapist == null || linkedAt == null || token == null) return LinkResult.invalidResponse;
      await app.linkDao.insert(
        TherapistLink(linkId: linkId, inviteCode: inviteCode.trim().toUpperCase(), therapist: therapist, linkedAt: linkedAt),
      );
      await app.prefs.setString(PrefKeys.deviceToken, token);
      app.markDataChanged();
      return LinkResult.connected;
    } catch (_) {
      return LinkResult.offline;
    }
  }

  Future<void> revoke(TherapistLink link) async {
    final token = app.prefs.getString(PrefKeys.deviceToken);
    if (token == null || token.isEmpty) {
      await _markPending(link.linkId);
      return;
    }
    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/v1/link/${link.linkId}'), headers: {'Authorization': 'Bearer $token'})
          .timeout(_requestTimeout);
      if (response.statusCode == 204 || response.statusCode == 401) {
        await app.linkDao.markRevoked(link.linkId, nowIso());
        await app.prefs.remove(PrefKeys.deviceToken);
        await app.prefs.remove(pendingRevokeLinkKey);
        app.markDataChanged();
        return;
      }
    } catch (_) {}
    await _markPending(link.linkId);
  }

  Future<bool> retryPendingRevocation() async {
    final linkId = app.prefs.getString(pendingRevokeLinkKey);
    final token = app.prefs.getString(PrefKeys.deviceToken);
    if (linkId == null) return true;
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/v1/link/$linkId'), headers: {'Authorization': 'Bearer $token'})
          .timeout(_requestTimeout);
      if (response.statusCode != 204 && response.statusCode != 401) return false;
      await app.prefs.remove(pendingRevokeLinkKey);
      await app.prefs.remove(PrefKeys.deviceToken);
      app.markDataChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _markPending(String linkId) async {
    await app.linkDao.markRevoked(linkId, nowIso());
    await app.prefs.setString(pendingRevokeLinkKey, linkId);
    app.markDataChanged();
  }

  void close() => _client.close();
}
