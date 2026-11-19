// A port of pixel/mapa.js and the picture part of pixel/mapa.html: the island map on the Pixel Plays engine.
// Pure Dart (no Flutter, no dart:ui), so the same code runs in the golden tests on the VM and in a browser.
//
// The names of the old file are kept, capitals included, so the port reads line for line against it (page 12,
// section 6): the lints on names are off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_places.dart';

/// mapa.js: STATE. Which places are done and open, and which one the frog is at ([aqui]). Both lists have one
/// entry for each of the ten places.
class MapState {
  MapState({
    required List<bool> hecho,
    required List<bool> abierto,
    this.aqui = 0,
  }) : hecho = List<bool>.generate(
         placeCount,
         (k) => k < hecho.length && hecho[k],
       ),
       abierto = List<bool>.generate(
         placeCount,
         (k) => k < abierto.length && abierto[k],
       );

  /// A place is done: a yellow plate and a waving red flag.
  final List<bool> hecho;

  /// A place is open: a white plate. Not open: the place goes grey.
  final List<bool> abierto;

  /// The place the frog stands at, with the bouncing arrow over him.
  final int aqui;

  @override
  bool operator ==(Object other) =>
      other is MapState &&
      other.aqui == aqui &&
      _same(other.hecho, hecho) &&
      _same(other.abierto, abierto);

  @override
  int get hashCode =>
      Object.hash(aqui, Object.hashAll(hecho), Object.hashAll(abierto));

  static bool _same(List<bool> a, List<bool> b) {
    for (var k = 0; k < a.length; k++) {
      if (a[k] != b[k]) return false;
    }
    return true;
  }
}

/// mapa.js: FROG. Where the frog is and what he is doing. `path` is the hops still to make, or null.
class Frog {
  int at = 0;
  double x = 0, y = 0, z = 0, yaw = math.pi / 4;
  List<Hop>? path;
  double t = 0;
  double squash = 0;
  int target = 0;
  void Function()? onArrive;
}

/// One hop of the frog, from (x0, y0) to (x1, y1) in world x, y.
class Hop {
  Hop(this.x0, this.y0, this.x1, this.y1);
  final double x0, y0, x1, y1;
}

/// The island map: `bake` it once, `setState` it, then call `tick` for each frame. [pix] is the picture
/// (`mapW` x `mapH`, each pixel `0xAABBGGRR`).
class MapPicture {
  MapPicture({bool still = false, this.onHop})
    : e = PpEngine(
        w: mapW,
        h: mapH,
        s: mapS,
        originY: mapOriginY,
        shadowX: mapShadowX,
        shadowY: mapShadowY,
        still: still,
      ) {
    b = PpBuild(e);
    places = MapPlaces(e, b, _addPatch, waterPix);
  }

  final PpEngine e;
  late final PpBuild b;
  late final MapPlaces places;

  /// Called at each landing of the frog (mapa.js: `sfxHop`).
  final void Function()? onHop;

  /// mapa.js: patches. The ground the dioramas lay down.
  final List<Patch> patches = [];

  /// mapa.js: waterPix, i, u, v, sd four entries a pixel
  final List<num> waterPix = [];

  /// mapa.js: owner. For each pixel the place that drew it, or -1.
  final Int8List owner = Int8List(mapW * mapH)..fillRange(0, mapW * mapH, -1);

  /// mapa.js: colourPix. The baked picture before any place goes grey.
  Uint32List? colourPix;

  /// mapa.js: STATE
  MapState STATE = MapState(hecho: const [], abierto: const []);

  /// mapa.js: FROG
  final Frog FROG = Frog();

  /// mapa.js: time
  double time = 0;

  /// The picture the engine draws into.
  Uint32List get pix => e.pix;

  /// Whether `bake` has run.
  bool get baked => colourPix != null;

  // mapa.js: PATCH_ONLY. In the patch pass each place runs once to register its ground, and what it drew is
  // taken back; in the real pass `patches.push` does nothing.
  bool _patchPass = false;
  bool _pushOn = true;

  void _addPatch(Patch p) {
    if (_pushOn) patches.add(p);
  }

  // ---------- ground ----------
  // mapa.js: groundColor
  int groundColor(double x, double y, int ix, int iy, int i) {
    final uv = UV(x, y), u = uv.u, v = uv.v;
    final sd = islandSd(e, u, v);
    if (sd > 0) return 0;
    if (sd > -.5 && e.hash(ix, iy) < (sd + .5) / .5 * .8) return 0;
    if (sd > -2.7) {
      e.kinds[i] = KIND_WATER;
      waterPix.addAll([i, u, v, sd]);
      return b.toneOf(
        b.C.sea,
        .15 +
            e.clamp<double>((-sd) / 2.7, 0, 1) * .75 +
            (e.noise(u * .5, v * .3) - .5) * .3,
        ix,
        iy,
      );
    }
    final beach = -3.9 - e.noise(u * .6, v * .6) * 1.1;
    for (final p in patches) {
      if (p.hit(x, y)) {
        final c = p.color(x, y, ix, iy, i);
        if (c != 0) return c;
      }
    }
    for (var k = 0; k < PADS.length; k++) {
      final d = hypot(u - PADS[k][0], v - PADS[k][1]);
      if (d < 1.55) {
        e.kinds[i] = KIND_ROAD;
        return d > 1.25
            ? e.rgb(b.C.stone[0] * .62, b.C.stone[1] * .62, b.C.stone[2] * .62)
            : b.toneOf(b.C.pave, .55 + e.noise(u * 3, v * 3) * .45, ix, iy);
      }
    }
    if (sd > beach) {
      e.kinds[i] = KIND_SAND;
      return b.toneOf(b.C.sand, .2 + e.noise(u * 2, v * 2) * .8, ix, iy);
    }
    final rd = roadDist(u, v);
    if (rd < .72) {
      e.kinds[i] = KIND_ROAD;
      final edge = rd > .56;
      return edge
          ? b.toneOf(b.C.path, .05, ix, iy)
          : b.toneOf(
              b.C.path,
              .35 + e.noise(u * 2.5, v * 2.5) * .6 + (e.hash(ix, iy) - .5) * .3,
              ix,
              iy,
            );
    }
    e.kinds[i] = e.KIND_GRASS;
    final t = e.noise(u * .5, v * .5) * 1.15 + (e.hash(ix, iy) - .5) * .5 - .05;
    final g = e.GRASS[e.clamp((t * 4.2).floor(), 0, 3)];
    return e.rgb(g[0], g[1], g[2]);
  }

  // mapa.js: slabSides. The island floats: under its front edges, a band of deep water and then layered earth
  void slabSides() {
    const T = 14;
    for (var ix = 0; ix < e.W; ix++) {
      var last = -1;
      for (var iy = 0; iy < e.H; iy++) {
        final i = iy * e.W + ix;
        if (e.ground[i] != 0) {
          last = iy;
          continue;
        }
        if (last < 0 || iy - last > T || e.pix[i] != 0) continue;
        final k = iy - last,
            g = e.unproject(ix + .5, last + .5),
            right = UV(g.x, g.y).u > 0;
        int c;
        if (k <= 3) {
          c = e.rampOf(const [30, 90, 120])[right ? 1 : 2];
        } else {
          final layer = k + _round(math.sin(ix * .35) * 1.2);
          final base = layer < 7
              ? const [150, 112, 74]
              : layer < 11
              ? const [120, 88, 62]
              : const [92, 70, 58];
          c =
              e.rampOf(base)[e.clamp(
                (right ? 1 : 2) +
                    (e.bayerAt(ix, iy) > .8 ? 1 : 0) -
                    (e.hash(ix, iy) > .93 ? 1 : 0) -
                    (k == T ? 1 : 0),
                0,
                4,
              )];
        }
        e.pix[i] = c;
      }
    }
  }

  // mapa.js: decorate. Palms on the beach, bushes in the grass
  void decorate() {
    for (var k = 0; k < 220; k++) {
      final u = (e.hash(k, 61) - .5) * 30,
          v = -58 + e.hash(k, 62) * 106,
          sd = islandSd(e, u, v);
      if (sd > -3.8) continue;
      final xy = XY(u, v), x = xy.x, y = xy.y;
      if (sd > -5.6) {
        if (e.hash(k, 63) < .35 && freeSpot(u, v, .8)) {
          b.palm(
            x,
            y,
            2.6 + e.hash(k, 64) * 1,
            (u > 0 ? 1 : -1) * (.5 + e.hash(k, 65) * .4) * .7,
            k,
          );
        }
        continue;
      }
      if (e.hash(k, 66) < .5 && freeSpot(u, v, .5)) {
        b.bush(
          x,
          y,
          .3 + e.hash(k, 67) * .35,
          e.hash(k, 68) > .5 ? b.C.leaf : const [96, 150, 70],
        );
      } else if (e.hash(k, 69) < .3 && freeSpot(u, v, .3)) {
        for (var f = 0; f < 5; f++) {
          e.sphere(
            x + (e.hash(k, f) - .5) * .8,
            y + (e.hash(f, k) - .5) * .8,
            .06,
            .08,
            f.remainder(2) != 0 ? const [244, 120, 140] : const [250, 230, 120],
            'solid',
          );
        }
      }
    }
  }

  // ---------- bake ----------
  // mapa.js: bake
  void bake() {
    final W = e.W, H = e.H;
    e.zb.fillRange(0, e.zb.length, -1e9);
    e.pix.fillRange(0, e.pix.length, 0);
    e.kinds.fillRange(0, e.kinds.length, 0);
    waterPix.clear();
    final builds = places.builders;
    final cxy = [
      for (var k = 0; k < builds.length; k++) XY(DIO[k][0], DIO[k][1]),
    ];
    // register ground patches by running each place once into a throwaway pass: patches are pushed at build
    // time, so build order is: patches (cheap) -> ground -> buildings
    _patchPass = true;
    for (var k = 0; k < builds.length; k++) {
      _build(k, cxy[k]);
    }
    _patchPass = false;
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = e.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = groundColor(g.x, g.y, ix, iy, i);
        if (c == 0) continue;
        e.pix[i] = c;
        e.ground[i] = 1;
        e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
      }
    }
    slabSides();
    e.growGrass();
    e.groundZ.setAll(0, e.zb);
    decorate();
    // buildings, back to front, recording which pixels each place owns so locked places can be greyed
    final order = [for (var k = 0; k < builds.length; k++) k]
      ..sort((a, c) {
        final d = DIO[a][1].compareTo(DIO[c][1]);
        return d != 0 ? d : a.compareTo(c); // JavaScript's sort is stable
      });
    for (final k in order) {
      final zBefore = Float32List.fromList(e.zb);
      final l0 = e.leaves.length;
      _build(k, cxy[k]);
      for (var j = l0; j < e.leaves.length; j++) {
        e.leaves[j].owner = k;
        e.leaves[j].orig = [...e.leaves[j].pixels];
      }
      e.flushShadows();
      e.pendingShadows.clear();
      for (var i = 0; i < e.pix.length; i++) {
        if (e.zb[i] != zBefore[i]) owner[i] = k;
      }
    }
    // the ground a place laid down belongs to it too
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final i = iy * W + ix;
        if (owner[i] >= 0 || e.ground[i] == 0) continue;
        final g = e.unproject(ix + .5, iy + .5), uv = UV(g.x, g.y);
        for (var k = 0; k < DIO.length; k++) {
          if ((uv.u - DIO[k][0]).abs() < 3.4 &&
              (uv.v - DIO[k][1]).abs() < 3.8 &&
              patches.any((p) => p.owner == k && p.hit(g.x, g.y))) {
            owner[i] = k;
          }
        }
      }
    }
    e.bakeOcclusion();
    e.staticShadow.setAll(0, e.shadowMask);
    e.applyShadows(e.groundZ);
    e.shadeEdges();
    colourPix = Uint32List.fromList(e.pix);
    e.bakedZ.setAll(0, e.zb);
  }

  // mapa.js: the PLACES wrapper of the block after `slabSides`: what a place does in the patch pass and in the
  // real one
  void _build(int k, ({double x, double y}) c) {
    final real = places.builders[k];
    if (!_patchPass) {
      // `patches.push = () => n; real(x, y); delete patches.push`
      _pushOn = false;
      real(c.x, c.y);
      _pushOn = true;
      return;
    }
    final n = patches.length;
    final pixSave = Uint32List.fromList(e.pix),
        zbSave = Float32List.fromList(e.zb),
        maskSave = Uint8List.fromList(e.shadowMask),
        leavesN = e.leaves.length,
        pendN = e.pendingShadows.length;
    real(c.x, c.y);
    e.pix.setAll(0, pixSave);
    e.zb.setAll(0, zbSave);
    e.shadowMask.setAll(0, maskSave);
    e.leaves.length = leavesN;
    e.pendingShadows.length = pendN;
    for (var j = n; j < patches.length; j++) {
      patches[j].owner = k;
    }
  }

  // ---------- state: which places are open, done, and where the frog is ----------
  // mapa.js: setState. Locked places drop to a cool grey, like a model not yet painted
  void setState(MapState st) {
    STATE = st;
    e.pix.setAll(0, colourPix!);
    for (var i = 0; i < e.pix.length; i++) {
      final k = owner[i];
      if (k < 0 || STATE.abierto[k]) continue;
      e.pix[i] = greyOf(e.pix[i]);
    }
    e.bakedPix.setAll(0, e.pix);
    for (final leaf in e.leaves) {
      if (leaf.owner == null) continue;
      final src = leaf.orig!,
          dst = leaf.pixels,
          lock = !STATE.abierto[leaf.owner!];
      for (var n = 3; n < src.length; n += 4) {
        dst[n] = lock ? greyOf(src[n] as int) : src[n];
      }
    }
  }

  // mapa.js: greyOf
  int greyOf(int c) {
    final r = c & 255, g = c >> 8 & 255, bl = c >> 16 & 255;
    final l = r * .3 + g * .55 + bl * .15;
    return e.rgb(l * .72 + 38, l * .74 + 42, l * .8 + 56);
  }

  // ---------- the frog ----------
  static const List<int> TAN = [200, 133, 60],
      CREAM = [238, 220, 176],
      EYE = [250, 250, 245],
      PUPIL = [32, 20, 10];

  // mapa.js: drawFrog
  void drawFrog(double x, double y, double z, double yaw, [double squash = 0]) {
    final fx = math.cos(yaw), fy = math.sin(yaw), sx = -fy, sy = fx, k = 1.5;
    List<double> P(num a, num bb, num c) => [
      x + (fx * a + sx * bb) * k,
      y + (fy * a + sy * bb) * k,
      z + c * k,
    ];
    final s = 1 - squash * .25;
    void frogAdd(List<num> a, List<num> bb, num r0, num r1, List<int> col) =>
        b.bakeAdd(a, bb, r0 * k, r1 * k, (_) => col);
    frogAdd(P(-.15, 0, .3 * s), P(.15, 0, .34 * s), .3, .28, TAN);
    frogAdd(P(.22, 0, .2 * s), P(.22, 0, .22 * s), .16, .16, CREAM);
    for (final side in const [-1, 1]) {
      frogAdd(P(-.18, side * .3, .1), P(.05, side * .36, .06), .12, .09, TAN);
      frogAdd(P(.2, side * .22, .06), P(.3, side * .26, .04), .07, .06, TAN);
      frogAdd(
        P(.2, side * .17, .58 * s),
        P(.2, side * .17, .58 * s),
        .14,
        .14,
        TAN,
      );
      frogAdd(
        P(.27, side * .17, .6 * s),
        P(.27, side * .17, .6 * s),
        .1,
        .1,
        EYE,
      );
      frogAdd(
        P(.34, side * .17, .6 * s),
        P(.34, side * .17, .6 * s),
        .05,
        .05,
        PUPIL,
      );
    }
  }

  // mapa.js: placeFrog
  void placeFrog(int k) {
    final xy = XY(PADS[k][0], PADS[k][1]);
    FROG
      ..at = k
      ..x = xy.x
      ..y = xy.y
      ..z = 0
      ..path = null;
  }

  // mapa.js: hopTo. [done] is called when the frog has arrived. A hop to the stop he is at has no hops: it is
  // done at once (the old page never asks for one)
  void hopTo(int k, [void Function()? done]) {
    final pts = [for (final p in route(FROG.at, k)) XY(p[0], p[1])];
    // break long legs into hops of about 2.2 units
    final hops = <Hop>[];
    for (var n = 1; n < pts.length; n++) {
      final a = pts[n - 1], bb = pts[n];
      final d = hypot(bb.x - a.x, bb.y - a.y);
      final m = math.max(1, _round(d / 2.2));
      for (var j = 1; j <= m; j++) {
        hops.add(
          Hop(
            e.lerp(a.x, bb.x, (j - 1) / m),
            e.lerp(a.y, bb.y, (j - 1) / m),
            e.lerp(a.x, bb.x, j / m),
            e.lerp(a.y, bb.y, j / m),
          ),
        );
      }
    }
    if (hops.isEmpty) {
      done?.call();
      return;
    }
    FROG
      ..path = hops
      ..t = 0
      ..target = k
      ..onArrive = done;
  }

  // mapa.js: updateFrog
  void updateFrog(double dt) {
    final path = FROG.path;
    if (path == null) {
      FROG.squash = math.max(0, FROG.squash - dt * 4);
      return;
    }
    FROG.t += dt / .2;
    final h = path[0], t = math.min(1.0, FROG.t);
    FROG.x = e.lerp(h.x0, h.x1, t);
    FROG.y = e.lerp(h.y0, h.y1, t);
    FROG.z = math.sin(t * math.pi) * .9;
    FROG.yaw = math.atan2(h.y1 - h.y0, h.x1 - h.x0);
    if (t >= 1) {
      path.removeAt(0);
      FROG.t = 0;
      FROG.squash = 1;
      onHop?.call();
      if (path.isEmpty) {
        FROG.path = null;
        FROG.at = FROG.target;
        FROG.yaw = b.FACE;
        FROG.onArrive?.call();
      }
    }
  }

  // ---------- per frame ----------
  static const Map<String, String> DIGITS = {
    '0': '111101101101111',
    '1': '010110010010111',
    '2': '111001111100111',
    '3': '111001111001111',
    '4': '101101111001001',
    '5': '111100111001111',
    '6': '111100111101111',
    '7': '111001010010010',
    '8': '111101111101111',
    '9': '111101111001111',
  };

  // mapa.js: rect
  void rect(int x, int y, int w, int h, int c) {
    for (var j = 0; j < h; j++) {
      for (var i = 0; i < w; i++) {
        final X = x + i, Y = y + j;
        if (X >= 0 && Y >= 0 && X < e.W && Y < e.H) e.pix[Y * e.W + X] = c;
      }
    }
  }

  // mapa.js: plate. The number plate of a stop: yellow when done, white when open, grey when not
  void plate(int k, double sx, double sy) {
    final n = '${k + 1}', w = n.length * 4 + 3;
    final x = _round(sx - w / 2), y = _round(sy);
    final fill = STATE.hecho[k]
        ? e.rgb(255, 214, 10)
        : STATE.abierto[k]
        ? e.rgb(255, 255, 255)
        : e.rgb(150, 154, 166);
    rect(x - 1, y - 1, w + 2, 9, e.INK);
    rect(x, y, w, 7, fill);
    for (var j = 0; j < n.length; j++) {
      final d = DIGITS[n[j]]!;
      for (var r = 0; r < 5; r++) {
        for (var q = 0; q < 3; q++) {
          if (d[r * 3 + q] == '1') {
            e.pix[(y + 1 + r) * e.W + x + 2 + j * 4 + q] = e.INK;
          }
        }
      }
    }
  }

  // mapa.js: drawFlag
  void drawFlag(double x, double y, double z, double t, List<num> col) {
    e.capsule([x, y, z], [x, y, z + 1.6], .04, .04, (_) => b.C.white, 'solid');
    for (num a = 0; a <= .9; a += .03) {
      for (num bb = 0; bb <= .5; bb += .03) {
        final wave = math.sin(a * 6 - t * 6) * .1 * a;
        e.plot(
          x + a * .7,
          y - a * .7 + wave,
          z + 1.6 - bb,
          e.rampOf(col)[e.clamp(_round(3 + math.sin(a * 6 - t * 6)), 1, 4)],
        );
      }
    }
  }

  // mapa.js: drawSea
  void drawSea(double t) {
    final lit = e.rgb(176, 222, 214),
        soft = e.rgb(120, 190, 186),
        foam = e.rgb(244, 248, 240);
    final W = e.W;
    for (var n = 0; n < waterPix.length; n += 4) {
      final i = waterPix[n].toInt(),
          u = waterPix[n + 1].toDouble(),
          v = waterPix[n + 2].toDouble(),
          sd = waterPix[n + 3].toDouble();
      if (e.zb[i] != e.groundZ[i]) continue;
      if (sd > -2.7 &&
          sd < -2.35 &&
          math.sin(u * 1.7 + v * .9 + t * 2.4) > -.2) {
        e.pix[i] = foam;
        continue;
      }
      // JavaScript's % keeps the sign of the left side: remainder, not Dart's %
      final ph = (v * .8 + math.sin(u * .6) * 1.4 + t * .7).remainder(3.2);
      if (ph > 0 && ph < .22 && e.hash(i.remainder(W) >> 1, i ~/ W) > .4) {
        e.pix[i] = e.staticShadow[i] != 0 ? soft : lit;
      }
    }
  }

  // mapa.js: FLAG_POLE
  List<double> flagPole() {
    final xy = XY(DIO[9][0], DIO[9][1]);
    return [xy.x - .6, xy.y - .6, 2 + 3.6];
  }

  // mapa.js: draw
  void draw() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.pendingShadows.clear();
    final windT = e.STILL ? 0.0 : (time * e.WIND_FPS).floor() / e.WIND_FPS;
    drawSea(windT);
    e.drawLeaves(windT);
    e.drawTufts(windT);
    for (var k = 0; k < PADS.length; k++) {
      if (STATE.hecho[k]) {
        final xy = XY(PADS[k][0] + .9, PADS[k][1] - .9);
        drawFlag(xy.x, xy.y, 0, windT, b.C.red);
      }
    }
    {
      final p = flagPole();
      drawFlag(
        p[0],
        p[1],
        p[2],
        windT,
        STATE.abierto[9] ? b.C.red : const [150, 150, 160],
      );
    }
    drawFrog(FROG.x, FROG.y, FROG.z, FROG.yaw, FROG.squash);
    e.flushShadows();
    e.applyShadows(e.groundZ);
    for (var k = 0; k < PADS.length; k++) {
      final xy = XY(PADS[k][0], PADS[k][1]), p = e.project(xy.x, xy.y, 0);
      plate(k, p.sx, p.sy + 7);
    }
    if (FROG.path == null) {
      final p = e.project(FROG.x, FROG.y, 1.2 + FROG.z);
      e.drawArrow(p.sx, p.sy - 2, time);
    }
  }

  // mapa.js: tick
  void tick(double dt) {
    time += dt;
    updateFrog(dt);
    draw();
  }

  // ---------- tap: nearest stop or place ----------
  // mapa.js: stopAt. The stop or place nearest to (cx, cy) in picture pixels, within 22 of them; -1 for none
  int stopAt(double cx, double cy) {
    var best = -1;
    var bd = 22.0;
    for (var k = 0; k < PADS.length; k++) {
      for (final isDio in const [false, true]) {
        final p = isDio ? DIO[k] : PADS[k];
        final xy = XY(p[0], p[1]), s = e.project(xy.x, xy.y, isDio ? 1 : 0);
        final d = hypot(s.sx - cx, s.sy - cy);
        if (d < bd) {
          bd = d;
          best = k;
        }
      }
    }
    return best;
  }

  /// Where a stop is on the picture, in picture pixels (mapa.html: the scroll that opens on the frog).
  ({double sx, double sy}) stopOnPicture(int k) {
    final xy = XY(PADS[k][0], PADS[k][1]), p = e.project(xy.x, xy.y, 0);
    return (sx: p.sx, sy: p.sy);
  }

  // Math.round (page 12, section 6)
  static int _round(num x) => (x + .5).floor();
}
