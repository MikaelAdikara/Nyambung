import 'package:flutter/foundation.dart';

import 'mission_rules.dart';

@immutable
class FakeChild {
  const FakeChild({required this.nickname, required this.ageYears, required this.routine});

  final String nickname;
  final int? ageYears;
  final String routine;
}

@immutable
class FakeMission {
  const FakeMission({
    required this.id,
    required this.targetWord,
    required this.routine,
    required this.repsCounted,
    this.repsTarget = 5,
    this.lessonKey = 'modeling_dasar',
  });

  final String id;
  final String targetWord;
  final String routine;
  final int repsCounted;
  final int repsTarget;
  final String lessonKey;

  FakeMission copyWith({int? repsCounted}) => FakeMission(
    id: id,
    targetWord: targetWord,
    routine: routine,
    repsCounted: repsCounted ?? this.repsCounted,
    repsTarget: repsTarget,
    lessonKey: lessonKey,
  );
}

/// Temporary in-memory stand-in for the public AppState API promised by lane 1.
/// Delete this file when `j1-kerangka` is available.
class FakeAppState extends ChangeNotifier {
  FakeChild? child = const FakeChild(nickname: 'Arka', ageYears: 5, routine: 'makan');
  FakeMission mission = const FakeMission(id: 'misi-w1', targetWord: 'mau', routine: 'makan', repsCounted: 2);
  int dataVersion = 0;
  int outboxCount = 3;
  bool isOnline = false;
  bool linkedToTherapist = false;
  String? therapistName;
  String? missionStatus;
  String targetStatus = 'usulan';

  String get routineLabel => routineLabelFor(mission.routine);

  String routineLabelFor(String routine) => routineDisplayLabel(routine);

  Future<void> createChild({required String nickname, int? ageYears, required String routine}) async {
    child = FakeChild(nickname: nickname, ageYears: ageYears, routine: routine);
    mission = FakeMission(id: 'misi-w1', targetWord: 'mau', routine: routine, repsCounted: 0);
    _changed();
  }

  Future<void> logTap({required String content, required String method, required bool byParent, String? context}) async {
    if (byParent && context == mission.id && content == mission.targetWord && (method == 'SEL' || method == 'KAT')) {
      mission = mission.copyWith(repsCounted: mission.repsCounted + 1);
    }
    outboxCount += 1;
    _changed();
  }

  Future<void> logMission(String missionId, String status) async {
    missionStatus = status;
    outboxCount += 1;
    _changed();
  }

  Future<void> connectTherapist(String inviteCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    linkedToTherapist = true;
    therapistName = 'Bu Rina (ilustratif)';
    _changed();
  }

  Future<void> logTargetAnswer(String targetId, bool accepted) async {
    targetStatus = accepted ? 'diterima' : 'ditolak';
    if (accepted) {
      mission = FakeMission(id: mission.id, targetWord: 'berhenti', routine: mission.routine, repsCounted: 0, lessonKey: mission.lessonKey);
    }
    outboxCount += 1;
    _changed();
  }

  Future<void> revokeTherapist() async {
    linkedToTherapist = false;
    therapistName = null;
    _changed();
  }

  Future<void> syncNow() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  void _changed() {
    dataVersion += 1;
    notifyListeners();
  }
}
