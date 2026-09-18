import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyambung/data/scene.dart';
import 'package:nyambung/features/scenes/scene_geometry.dart';

void main() {
  test('scene box menolak koordinat tidak finite dan di luar foto', () {
    expect(() => SceneBox.checked(x: -0.1, y: 0, width: 0.2, height: 0.2), throwsArgumentError);
    expect(() => SceneBox.checked(x: 0.9, y: 0, width: 0.2, height: 0.2), throwsArgumentError);
    expect(() => SceneBox.checked(x: 0, y: 0, width: double.nan, height: 0.2), throwsArgumentError);
  });

  test('payload final hanya menerima satu sampai enam hotspot dengan id unik', () {
    final hotspot = SceneHotspot(id: 'h1', box: const SceneBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4), wordId: 'mobil');
    expect(ScenePayload(hotspots: [hotspot]).toJson()['schema_version'], 1);
    expect(() => ScenePayload(hotspots: const []), throwsArgumentError);
    expect(() => ScenePayload(hotspots: List.filled(7, hotspot)), throwsArgumentError);
    expect(() => ScenePayload(hotspots: [hotspot, hotspot]), throwsArgumentError);
  });

  test('payload round trip mempertahankan kotak dan word id', () {
    final payload = ScenePayload(
      hotspots: [SceneHotspot(id: 'h1', box: const SceneBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4), wordId: 'mobil')],
    );
    expect(ScenePayload.fromJson(payload.toJson()).toJson(), payload.toJson());
  });

  test('BoxFit contain memetakan koordinat gambar tanpa memasukkan letterbox', () {
    final rect = containedImageRect(const Size(1000, 500), const Size(300, 300));
    expect(rect, const Rect.fromLTWH(0, 75, 300, 150));
    final mapped = sceneBoxToRect(const SceneBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4), rect);
    expect(mapped, const Rect.fromLTWH(30, 105, 90, 60));
    expect(pointToNormalized(const Offset(30, 105), rect), const Offset(0.1, 0.2));
    expect(pointToNormalized(const Offset(10, 20), rect), isNull);
  });
}
