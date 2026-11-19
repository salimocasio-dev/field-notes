// Pictures for the dev entry: a synthetic 196-wide picture (bands and a block, from the scene's name) drawn by
// PixelView at the largest whole-number scale the room allows, as the real source will draw a word's picture.
import 'dart:typed_data';

import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The fake picture source with [syntheticFrame] for every picture.
FakePictureSource devPictures() => FakePictureSource(frames: syntheticFrame);

/// `0xAABBGGRR`.
int _rgb(int r, int g, int b) => 0xFF000000 | (b << 16) | (g << 8) | r;

/// A [width] x [height] picture of bands (sky, wall, floor) and a block that moves with the scene's name and the camera.
Widget? syntheticFrame(
  PictureRef ref, {
  required int width,
  required int height,
}) {
  final w = width;
  final seed =
      ref.scene.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0xFFFF) +
      ref.cam.fold<int>(0, (a, c) => a + c.toInt());
  final px = Uint32List(w * height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < w; x++) {
      final int c;
      if (y < height * 0.35) {
        c = _rgb(150, 200, 235);
      } else if (y < height * 0.75) {
        c = _rgb(240, 225, 180);
      } else {
        c = _rgb(190, 150, 100);
      }
      px[y * w + x] = c;
    }
  }
  final bx = 20 + seed % 100;
  for (var y = height ~/ 3; y < height * 0.8; y++) {
    for (var x = bx; x < bx + 40 && x < w; x++) {
      px[y * w + x] = _rgb(60 + seed % 120, 140, 90);
    }
  }
  return PixelView(pixels: px, width: w, height: height);
}
