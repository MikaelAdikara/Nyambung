import 'package:flutter/foundation.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../../data/sync/sync_service.dart';
import 'mission_rules.dart';

@immutable
class CompanionMission {
  const CompanionMission({
    required this.id,
    required this.targetWord,
    required this.routine,
    required this.repsCounted,
    required this.repsTarget,
    required this.lessonKey,
  });

  final String id;
  final String targetWord;
  final String routine;
  final int repsCounted;
  final int repsTarget;
  final String lessonKey;
}

/// Read model for the companion screens, backed entirely by lane 1's AppState
/// and DAOs. It owns no duplicate source of truth.
class CompanionController extends ChangeNotifier {
  CompanionController(this.app) : sync = SyncService(app);

  final AppState app;
  final SyncService sync;

  CompanionMission? _mission;
  CompanionMission get mission => _mission!;
  bool get hasMission => _mission != null;

  Child? get child => app.child;
  int outboxCount = 0;
  TherapistLink? activeLink;
  List<VocabTarget> targets = const [];
  MissionLog? todayLog;
  int parentMissionTaps = 0;
  int childMissionTaps = 0;
  String? weeklyTopWord;
  int weeklyTopCount = 0;
  int weeklyOtherWords = 0;
  int currentWeek = 1;
  List<String> weeklyWords = const [];
  bool loading = false;
  SyncReport? lastSyncReport;

  bool get linkedToTherapist => activeLink != null;
  String? get therapistName => activeLink?.therapist;
  String get routineLabel => routineDisplayLabel(mission.routine);

  String get weeklySummary {
    final name = child?.nickname ?? 'anak';
    final word = weeklyTopWord;
    if (word == null) return 'Papan belum dipakai $name pekan ini. Tidak apa-apa; contoh dari Ibu dan Ayah tetap berarti.';
    final others = weeklyOtherWords == 0 ? '' : ', dan $weeklyOtherWords kata lain';
    return 'Pekan ini $name menekan ${word.toUpperCase()} $weeklyTopCount kali$others.';
  }

  Future<void> load() async {
    final currentChild = app.child;
    if (currentChild == null) {
      _mission = null;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    final now = DateTime.now();
    final week = missionWeek(DateTime.parse(currentChild.createdAt), now);
    currentWeek = week;
    targets = await app.targetDao.all();
    final accepted = targets.where((target) {
      final eligibleWeek = target.weekIndex == null || target.weekIndex! >= week;
      return target.status == TargetStatus.diterima && target.words.isNotEmpty && eligibleWeek;
    }).firstOrNull;
    final targetWord = accepted?.words.first ?? defaultTargetForWeek(week);
    final model = Mission(
      missionId: missionIdForWeek(week),
      weekIndex: week,
      targetWord: targetWord,
      routine: currentChild.routine,
      lessonKey: lessonForWeek(week),
    );
    await app.missionDao.upsert(model);
    final today = localDate(now);
    final reps = await app.missionReps(model.missionId, today);
    todayLog = await app.missionDao.logFor(model.missionId, today);
    parentMissionTaps = await app.eventDao.countOnDate(
      currentChild.childId,
      today,
      actor: Actor.pendamping,
      methods: Method.taps,
      context: model.missionId,
    );
    childMissionTaps = await app.eventDao.countOnDate(
      currentChild.childId,
      today,
      actor: Actor.anak,
      methods: Method.taps,
      context: model.missionId,
    );
    outboxCount = await app.eventDao.outboxCount();
    activeLink = await app.linkDao.active();
    final weekStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final weeklyEvents = await app.eventDao.since(currentChild.childId, isoWithOffset(weekStart));
    final counts = <String, int>{};
    for (final event in weeklyEvents) {
      if (event.actor == Actor.anak && Method.taps.contains(event.method)) {
        counts.update(event.content, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    weeklyTopWord = ranked.firstOrNull?.key;
    weeklyTopCount = ranked.firstOrNull?.value ?? 0;
    weeklyOtherWords = counts.isEmpty ? 0 : counts.length - 1;
    weeklyWords = ranked.map((entry) => entry.key).toList(growable: false);
    _mission = CompanionMission(
      id: model.missionId,
      targetWord: model.targetWord,
      routine: model.routine,
      repsCounted: reps,
      repsTarget: model.repsTarget,
      lessonKey: model.lessonKey ?? lessonForWeek(week),
    );
    loading = false;
    notifyListeners();
  }

  Future<void> logTap({required String content, required String method, required bool byParent, String? context}) async {
    await app.logTap(content: content, method: method, byParent: byParent, context: context);
    await load();
  }

  Future<void> logMission(String missionId, String status) async {
    await app.logMission(missionId, status);
    await load();
  }

  Future<void> logTargetAnswer(String targetId, bool accepted) async {
    await app.logTargetAnswer(targetId, accepted);
    await load();
  }

  Future<void> revokeLocally() async {
    final link = activeLink;
    if (link == null) return;
    await app.linkDao.markRevoked(link.linkId, nowIso());
    app.markDataChanged();
    await load();
  }

  Future<void> syncNow() async {
    final currentChild = child;
    if (currentChild == null) return;
    lastSyncReport = await sync.push(currentChild.childId);
    await load();
  }

  @override
  void dispose() {
    sync.close();
    super.dispose();
  }
}
