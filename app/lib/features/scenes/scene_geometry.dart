import 'dart:math' as math;
import 'dart:ui';

import '../../data/scene.dart';

Rect containedImageRect(Size image, Size viewport) {
  if (image.isEmpty || viewport.isEmpty) return Rect.zero;
  final scale = math.min(viewport.width / image.width, viewport.height / image.height);
  final width = image.width * scale;
  final height = image.height * scale;
  return Rect.fromLTWH((viewport.width - width) / 2, (viewport.height - height) / 2, width, height);
}

Rect sceneBoxToRect(SceneBox box, Rect imageRect) => Rect.fromLTWH(
  imageRect.left + box.x * imageRect.width,
  imageRect.top + box.y * imageRect.height,
  box.width * imageRect.width,
  box.height * imageRect.height,
);

Offset? pointToNormalized(Offset point, Rect imageRect) {
  if (!imageRect.contains(point) || imageRect.isEmpty) return null;
  return Offset((point.dx - imageRect.left) / imageRect.width, (point.dy - imageRect.top) / imageRect.height);
}
