import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/core/speech_service.dart';
import 'package:nyambung/data/models.dart';

WordSymbol symbol({String? audioPath, String? familyAudio}) => WordSymbol(
  wordId: 'mobil',
  labelDisplay: 'MOBIL',
  labelSpeech: 'mobil',
  pos: 'benda',
  category: 'main',
  page: 1,
  positionIndex: 6,
  symbolPath: '',
  audioPath: audioPath,
  familyAudio: familyAudio,
);

void main() {
  test('scene menerima klip perangkat yang benar-benar tersedia', () async {
    final dir = await Directory.systemTemp.createTemp('nyambung-scene-audio-');
    addTearDown(() => dir.delete(recursive: true));
    final clip = File('${dir.path}${Platform.pathSeparator}mobil.ogg');
    await clip.writeAsBytes([1, 2, 3]);

    expect(await SpeechService().hasOfflineChildAudio(symbol(audioPath: clip.path)), isTrue);
  });

  test('rekaman keluarga saja bukan audio luring untuk giliran anak', () async {
    final dir = await Directory.systemTemp.createTemp('nyambung-family-audio-');
    addTearDown(() => dir.delete(recursive: true));
    final clip = File('${dir.path}${Platform.pathSeparator}family.m4a');
    await clip.writeAsBytes([1, 2, 3]);

    expect(await SpeechService().hasOfflineChildAudio(symbol(familyAudio: clip.path)), isFalse);
  });
}
