/// Stand-in pictures for the gallery: the real scenes are drawn by another package.
/// Pixels are `0xAABBGGRR`.
library;

import 'dart:typed_data';

int rgb(int r, int g, int b) => 0xFF000000 | (b << 16) | (g << 8) | r;

void _rect(Uint32List p, int w, int x, int y, int rw, int rh, int c) {
  for (var j = y; j < y + rh; j++) {
    for (var i = x; i < x + rw; i++) {
      if (i >= 0 && i < w && j >= 0 && j * w + i < p.length) p[j * w + i] = c;
    }
  }
}

/// A little scene: sky, a green field, a house with a roof and a door. [variant]
/// moves things so that several pictures differ.
Uint32List sampleScene(int w, int h, {int variant = 0}) {
  final p = Uint32List(w * h);
  final skyTop = rgb(90, 160, 240);
  final skyLow = rgb(170, 210, 250);
  final horizon = (h * 0.62).round();
  for (var y = 0; y < horizon; y++) {
    final t = y / horizon;
    final c = rgb(
      (90 + 80 * t).round(),
      (160 + 50 * t).round(),
      (240 + 10 * t).round(),
    );
    _rect(p, w, 0, y, w, 1, c);
  }
  _rect(p, w, 0, 0, w, 1, skyTop);
  _rect(p, w, 0, horizon - 1, w, 1, skyLow);
  for (var y = horizon; y < h; y++) {
    final dither = ((y ~/ 2) & 1) == 0;
    _rect(p, w, 0, y, w, 1, dither ? rgb(70, 190, 80) : rgb(60, 170, 70));
  }
  final hx = 36 + variant * 11 % 50;
  final hw = (w * 0.5).round();
  final hy = horizon - (h * 0.36).round();
  _rect(p, w, hx, hy, hw, (h * 0.36).round(), rgb(40, 170, 170));
  _rect(p, w, hx - 6, hy - 14, hw + 12, 14, rgb(214, 70, 60));
  _rect(p, w, hx + hw ~/ 2 - 6, horizon - 26, 12, 26, rgb(150, 90, 40));
  _rect(p, w, hx + 8, hy + 10, 18, 14, rgb(240, 240, 240));
  _rect(p, w, w - 38, 10, 16, 16, rgb(250, 220, 90));
  return p;
}

/// A picture with a coloured border and a diagonal, to see exact pixel edges.
Uint32List sampleGrid(int w, int h) {
  final p = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var c = ((x ~/ 4 + y ~/ 4) & 1) == 0
          ? rgb(236, 232, 214)
          : rgb(214, 206, 180);
      if (x == 0 || y == 0 || x == w - 1 || y == h - 1) c = rgb(200, 40, 40);
      if ((x - y).abs() < 2) c = rgb(40, 90, 200);
      if ((x + y - w).abs() < 2) c = rgb(40, 150, 60);
      p[y * w + x] = c;
    }
  }
  return p;
}

/// A stand-in for the map (240 x 352): water, an island, a road and tiles.
Uint32List sampleMap() {
  const w = 240;
  const h = 352;
  final p = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      p[y * w + x] = ((x ~/ 3 + y ~/ 3) & 1) == 0
          ? rgb(92, 148, 252)
          : rgb(80, 134, 236);
    }
  }
  _rect(p, w, 12, 20, 216, 316, rgb(250, 220, 130));
  for (var y = 22; y < 334; y++) {
    for (var x = 14; x < 226; x++) {
      p[y * w + x] = ((x ~/ 6 + y ~/ 6) & 1) == 0
          ? rgb(88, 216, 84)
          : rgb(70, 200, 70);
    }
  }
  _rect(p, w, 112, 60, 16, 270, rgb(252, 216, 168));
  _rect(p, w, 52, 160, 136, 16, rgb(252, 216, 168));
  _rect(p, w, 52, 264, 136, 16, rgb(252, 216, 168));
  const stops = [
    [120, 326],
    [56, 270],
    [184, 270],
    [120, 218],
    [56, 166],
    [184, 166],
    [56, 114],
    [184, 114],
    [120, 66],
    [120, 20],
  ];
  for (var i = 0; i < stops.length; i++) {
    final s = stops[i];
    _rect(
      p,
      w,
      s[0] - 8,
      s[1] - 8,
      16,
      16,
      i == 0 ? rgb(23, 128, 63) : rgb(130, 130, 130),
    );
  }
  return p;
}
