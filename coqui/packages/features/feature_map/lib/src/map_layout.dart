// A port of the layout of pixel/mapa.js: the world's two axes, the ten stops (`PADS`), the ten places' own spots
// (`DIO`), the roads (`ROAD`, `legs`), the island's shape (`islandSd`) and the path the frog hops. Pure Dart.
//
// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';

/// mapa.js: the buffer's size and the engine's settings (`PP_SCENE` of mapa.html).
const int mapW = 256, mapH = 480;
const double mapS = 8, mapOriginY = 36, mapShadowX = .9, mapShadowY = -.1;

/// mapa.js: KIND_SAND, KIND_WATER, KIND_ROAD (the engine has KIND_NONE and KIND_GRASS)
const int KIND_SAND = 1, KIND_WATER = 2, KIND_ROAD = 4;

/// mapa.js: PADS. The ten stops, [u, v].
const List<List<double>> PADS = [
  [0, 40],
  [-5, 25],
  [5, 25],
  [0, 10],
  [-5, -5],
  [5, -5],
  [-5, -20],
  [5, -20],
  [0, -34],
  [0, -46],
];

/// mapa.js: DIO. Where each place's own picture stands, [u, v].
const List<List<double>> DIO = [
  [0, 34.6],
  [-9.7, 25],
  [9.7, 25],
  [0, 4.8],
  [-9.7, -5],
  [9.7, -5],
  [-9.7, -20],
  [9.7, -20],
  [-6.8, -34.5],
  [0, -51.6],
];

/// mapa.js: ROAD. The roads, as pairs of stops.
const List<List<int>> ROAD = [
  [0, 1],
  [0, 2],
  [1, 3],
  [2, 3],
  [3, 4],
  [3, 5],
  [4, 5],
  [4, 6],
  [5, 7],
  [6, 7],
  [6, 8],
  [7, 8],
  [8, 9],
];

/// mapa.js: the ten places' PLACES builders are in the order of the course's places.
const int placeCount = 10;

/// mapa.js: XY
({double x, double y}) XY(double u, double v) {
  const r2 = math.sqrt2;
  return (x: (v + u) / r2, y: (v - u) / r2);
}

/// mapa.js: UV
({double u, double v}) UV(double x, double y) {
  const r2 = math.sqrt2;
  return (u: (x - y) / r2, v: (x + y) / r2);
}

/// mapa.js: legs. A road leaves the lower stop sideways, then climbs straight up to the higher one, like a
/// board-game map
List<List<List<double>>> legs(int a, int b) {
  final A = PADS[a], B = PADS[b];
  if (A[0] == B[0] || A[1] == B[1]) {
    return [
      [A, B],
    ];
  }
  return [
    [
      A,
      [B[0], A[1]],
    ],
    [
      [B[0], A[1]],
      B,
    ],
  ];
}

/// mapa.js: SEGS
final List<List<List<double>>> SEGS = [
  for (final r in ROAD) ...legs(r[0], r[1]),
];

// Math.hypot of two numbers (page 12, section 6)
double hypot(num a, num b) => math.sqrt(a * a + b * b);

/// mapa.js: segDist
double segDist(double u, double v, List<List<double>> s) {
  final u0 = s[0][0], v0 = s[0][1], u1 = s[1][0], v1 = s[1][1];
  final du = u1 - u0, dv = v1 - v0, l = du * du + dv * dv;
  final t = l != 0
      ? math.max(0.0, math.min(1.0, ((u - u0) * du + (v - v0) * dv) / l))
      : 0.0;
  return hypot(u - u0 - du * t, v - v0 - dv * t);
}

/// mapa.js: roadDist
double roadDist(double u, double v) =>
    SEGS.map((s) => segDist(u, v, s)).reduce(math.min);

/// mapa.js: route. The path the frog hops from stop a to stop b: road corners in between, as [u, v].
List<List<double>> route(int a, int b) {
  if (a == b) return [PADS[a]];
  // breadth-first over the road graph
  final prev = <int, int>{a: -1}, q = <int>[a];
  while (q.isNotEmpty) {
    final n = q.removeAt(0);
    if (n == b) break;
    for (final r in ROAD) {
      final p = r[0], s = r[1];
      final m = p == n
          ? s
          : s == n
          ? p
          : -1;
      if (m >= 0 && !prev.containsKey(m)) {
        prev[m] = n;
        q.add(m);
      }
    }
  }
  final chain = <int>[];
  for (var n = b; n != -1; n = prev[n]!) {
    chain.insert(0, n);
  }
  final pts = <List<double>>[PADS[chain[0]]];
  for (var k = 1; k < chain.length; k++) {
    final p = chain[k - 1], n = chain[k], up = PADS[n][1] < PADS[p][1];
    final ls = up
        ? legs(p, n)
        : [
            for (final s in legs(n, p)) [s[1], s[0]],
          ].reversed.toList();
    for (final s in ls) {
      pts.add(s[1]);
    }
  }
  return pts;
}

/// mapa.js: islandSd
double islandSd(PpEngine e, double u, double v) {
  const A = 15.4, B = 52.6, vc = -5.5, r = 7;
  final qx = u.abs() - (A - r), qy = (v - vc).abs() - (B - r);
  return hypot(math.max(qx, 0), math.max(qy, 0)) +
      math.min(math.max(qx, qy), 0) -
      r +
      (e.noise(u * .33 + 4, v * .33) - .5) * 1.8;
}

/// mapa.js: inBox
bool inBox(double x, double y, double x0, double y0, double x1, double y1) =>
    x >= x0 && x <= x1 && y >= y0 && y <= y1;

/// mapa.js: freeSpot
bool freeSpot(double u, double v, double r) {
  if (roadDist(u, v) < r + 1) return false;
  for (final p in PADS) {
    if (hypot(u - p[0], v - p[1]) < r + 2) return false;
  }
  for (final d in DIO) {
    if ((u - d[0]).abs() < r + 3.6 && (v - d[1]).abs() < r + 4.2) return false;
  }
  return true;
}
