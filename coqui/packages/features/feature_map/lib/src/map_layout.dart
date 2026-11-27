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

/// Maximum number of hops for a single map trip; trips longer than
/// [maxHopLegs] legs use a fade-and-travel transition instead of hopping.
const int maxTripHops = 6;
const int maxHopLegs = 6;

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

class _RoadGraph {
  _RoadGraph(this.vertices, this.adj, this.padVertex);

  final List<List<double>> vertices;
  final List<List<({int to, double weight})>> adj;
  final List<int> padVertex;
}

const double _coordEps = 1e-9;

bool _samePoint(List<double> a, List<double> b) =>
    (a[0] - b[0]).abs() <= _coordEps && (a[1] - b[1]).abs() <= _coordEps;

_RoadGraph _buildRoadGraph() {
  final vertices = <List<double>>[];
  for (final seg in SEGS) {
    for (final pt in seg) {
      if (!vertices.any((v) => _samePoint(v, pt))) {
        vertices.add([pt[0], pt[1]]);
      }
    }
  }
  vertices.sort((a, b) {
    final du = a[0].compareTo(b[0]);
    return du != 0 ? du : a[1].compareTo(b[1]);
  });

  final n = vertices.length;
  final edgeMaps = List<Map<int, double>>.generate(n, (_) => <int, double>{});

  for (final seg in SEGS) {
    final p0 = seg[0], p1 = seg[1];
    final du = p1[0] - p0[0], dv = p1[1] - p0[1];
    assert(
      du.abs() <= _coordEps || dv.abs() <= _coordEps,
      'SEGS must be axis-aligned: $p0 -> $p1',
    );
    final minU = math.min(p0[0], p1[0]) - _coordEps;
    final maxU = math.max(p0[0], p1[0]) + _coordEps;
    final minV = math.min(p0[1], p1[1]) - _coordEps;
    final maxV = math.max(p0[1], p1[1]) + _coordEps;

    final onSeg = <int>[];
    for (var i = 0; i < n; i++) {
      final v = vertices[i];
      if (du.abs() <= _coordEps) {
        if ((v[0] - p0[0]).abs() <= _coordEps && v[1] >= minV && v[1] <= maxV) {
          onSeg.add(i);
        }
      } else if (dv.abs() <= _coordEps) {
        if ((v[1] - p0[1]).abs() <= _coordEps && v[0] >= minU && v[0] <= maxU) {
          onSeg.add(i);
        }
      }
    }
    onSeg.sort((ia, ib) {
      final va = vertices[ia], vb = vertices[ib];
      final pa = (va[0] - p0[0]) * du + (va[1] - p0[1]) * dv;
      final pb = (vb[0] - p0[0]) * du + (vb[1] - p0[1]) * dv;
      final c = pa.compareTo(pb);
      return c != 0 ? c : ia.compareTo(ib);
    });
    for (var j = 1; j < onSeg.length; j++) {
      final uIdx = onSeg[j - 1], vIdx = onSeg[j];
      final va = vertices[uIdx], vb = vertices[vIdx];
      final w = hypot(vb[0] - va[0], vb[1] - va[1]);
      if (w <= _coordEps) continue;
      final prevW = edgeMaps[uIdx][vIdx];
      if (prevW == null || w < prevW) {
        edgeMaps[uIdx][vIdx] = w;
        edgeMaps[vIdx][uIdx] = w;
      }
    }
  }

  final adj = [
    for (var i = 0; i < n; i++)
      [
        for (final to in edgeMaps[i].keys.toList()..sort())
          (to: to, weight: edgeMaps[i][to]!),
      ],
  ];
  final padVertex = [
    for (final pad in PADS) vertices.indexWhere((v) => _samePoint(v, pad)),
  ];
  assert(
    padVertex.every((v) => v >= 0),
    'Every stop in PADS must match a vertex in SEGS',
  );
  return _RoadGraph(vertices, adj, padVertex);
}

final _RoadGraph _roadGraph = _buildRoadGraph();

/// Shortest path on the road-junction graph (built from [SEGS], which derives
/// from [ROAD] and [legs]) from stop [a] to stop [b]: road corners and
/// junctions in between, as `[u, v]`.
List<List<double>> route(int a, int b) {
  if (a == b) return [PADS[a]];
  final g = _roadGraph;
  final n = g.vertices.length;
  final start = g.padVertex[a];
  final goal = g.padVertex[b];

  final dist = List<double>.filled(n, double.infinity);
  final edges = List<int>.filled(n, 1 << 30);
  final prev = List<int>.filled(n, -1);
  final visited = List<bool>.filled(n, false);
  dist[start] = 0;
  edges[start] = 0;

  bool isBetter(double d1, int e1, int i1, double d2, int e2, int i2) {
    if ((d1 - d2).abs() > _coordEps) return d1 < d2;
    if (e1 != e2) return e1 < e2;
    return i1 < i2;
  }

  for (var step = 0; step < n; step++) {
    var u = -1;
    for (var i = 0; i < n; i++) {
      if (visited[i] || dist[i].isInfinite) continue;
      if (u == -1 || isBetter(dist[i], edges[i], i, dist[u], edges[u], u)) {
        u = i;
      }
    }
    if (u == -1 || u == goal) break;
    visited[u] = true;
    for (final e in g.adj[u]) {
      if (visited[e.to]) continue;
      final nd = dist[u] + e.weight;
      final ne = edges[u] + 1;
      final v = e.to;
      final better = (nd - dist[v]).abs() > _coordEps
          ? nd < dist[v]
          : (ne != edges[v] ? ne < edges[v] : (prev[v] == -1 || u < prev[v]));
      if (better) {
        dist[v] = nd;
        edges[v] = ne;
        prev[v] = u;
      }
    }
  }

  final chain = <int>[];
  for (var cur = goal; cur != -1; cur = prev[cur]) {
    chain.add(cur);
    if (cur == start) break;
  }
  assert(
    chain.isNotEmpty && chain.last == start,
    'Road graph disconnected between stop $a and stop $b',
  );
  final pts = <List<double>>[];
  for (var i = chain.length - 1; i >= 0; i--) {
    final idx = chain[i];
    if (idx == start) {
      pts.add(PADS[a]);
    } else if (idx == goal) {
      pts.add(PADS[b]);
    } else {
      pts.add(g.vertices[idx]);
    }
  }
  return pts;
}

int _roundHop(num x) => (x + .5).floor();

/// Computes per-leg hop counts for [legLengths], capping total hops at
/// [maxTripHops] and returning an empty list for empty routes or routes with
/// more than [maxHopLegs] legs.
List<int> legHopCountsForLengths(List<double> legLengths) {
  if (legLengths.isEmpty || legLengths.length > maxHopLegs) return const [];
  final raw = [for (final d in legLengths) math.max(1, _roundHop(d / 2.2))];
  final rawSum = raw.fold<int>(0, (s, c) => s + c);
  if (rawSum <= maxTripHops) return raw;

  final totalLen = legLengths.fold<double>(0, (s, d) => s + d);
  if (totalLen <= 0) {
    return List<int>.filled(legLengths.length, 1);
  }
  final exact = [for (final d in legLengths) maxTripHops * d / totalLen];
  final counts = [for (final x in exact) math.max(1, x.floor())];
  var sum = counts.fold<int>(0, (s, c) => s + c);

  while (sum < maxTripHops) {
    var best = 0;
    var bestRem = exact[0] - counts[0];
    for (var i = 1; i < counts.length; i++) {
      final rem = exact[i] - counts[i];
      if (rem > bestRem + _coordEps) {
        bestRem = rem;
        best = i;
      }
    }
    counts[best]++;
    sum++;
  }
  while (sum > maxTripHops) {
    var best = 0;
    for (var i = 1; i < counts.length; i++) {
      if (counts[i] >= counts[best]) {
        best = i;
      }
    }
    counts[best]--;
    sum--;
  }
  return counts;
}

/// Computes per-leg hop counts for a polyline of `[u, v]` [routePoints].
List<int> legHopCounts(List<List<double>> routePoints) {
  if (routePoints.length <= 1) return const [];
  final lengths = [
    for (var i = 1; i < routePoints.length; i++)
      hypot(
        routePoints[i][0] - routePoints[i - 1][0],
        routePoints[i][1] - routePoints[i - 1][1],
      ),
  ];
  return legHopCountsForLengths(lengths);
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
