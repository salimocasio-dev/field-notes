// A baked set state is everything the frame needs that a bake leaves behind (BakedSet): the baked picture and depth,
// the ground, its depth, the kinds, the static shadow, the tufts and the leaves. Two tiny sets are baked on one engine
// and their frames drawn alternately; each frame must equal the frame of an engine that only ever baked that one set.
// Set A has ground on the left, a tree (leaves) and a patch of static shadow; set B has ground on the right and nothing
// else. A shadow cast on ground that exists in only one of them shows in that one only.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/signs_replay.dart' show SignScene;

const w = 60, h = 48, n = w * h;

PpEngine tinyEngine() => PpEngine(w: w, h: h, s: 10);

/// Bakes set [which] ('a' or 'b') on [e], from nothing: every buffer is written, the lists start empty, as a builder
/// that makes a state from scratch does. It ends the way every set builder does: `bakedPix.set(pix); bakedZ.set(zb)`.
void bake(PpEngine e, String which) {
  final a = which == 'a';
  for (final l in [e.pix, e.bakedPix]) {
    l.fillRange(0, n, 0);
  }
  for (final l in [e.zb, e.bakedZ, e.groundZ]) {
    l.fillRange(0, n, 0);
  }
  for (final l in [e.ground, e.kinds, e.staticShadow, e.shadowMask]) {
    l.fillRange(0, n, 0);
  }
  e.tufts.clear();
  e.leaves.clear();
  final sky = e.rgb(120, 170, 230),
      grass = a ? e.rgb(60, 150, 60) : e.rgb(140, 160, 50);
  for (var iy = 0; iy < h; iy++) {
    for (var ix = 0; ix < w; ix++) {
      final i = iy * w + ix;
      final onGround = iy >= 20 && (a ? ix < 36 : ix >= 24);
      if (!onGround) {
        e.pix[i] = sky;
        continue;
      }
      final g = e.unproject(ix + .5, iy + .5);
      final depth = (g.x + g.y) / e.R2 * e.COS;
      e.kinds[i] = e.KIND_GRASS;
      e.ground[i] = 1;
      e.pix[i] = grass;
      e.zb[i] = depth;
      e.groundZ[i] = depth;
    }
  }
  e.growGrass();
  if (a) {
    // a tree, which has leaves, and a patch of static shadow
    final t = e.unproject(20, 40);
    e.growTree(t.x, t.y, .4, 40, 7);
    for (var iy = 30; iy < 40; iy++) {
      for (var ix = 4; ix < 9; ix++) {
        e.staticShadow[iy * w + ix] = 1;
      }
    }
  }
  e.bakedPix.setAll(0, e.pix);
  e.bakedZ.setAll(0, e.zb);
}

/// One frame of [set] on [e] at frame count [F]: the shadow of a character on the ground only A has (the left), and of
/// one on the ground only B has (the right). Returns the picture.
Uint32List frame(PpEngine e, BakedSet set, int F, {bool shadows = true}) {
  final left = e.unproject(8, 42), right = e.unproject(50, 42);
  final scene = SignScene(
    <String, dynamic>{
      'box': <String, dynamic>{},
      'handAt': <String, dynamic>{},
      'heartAt': [0, 0],
    },
    w,
    h,
  );
  final display = Uint32List(196 * 216);
  drawFrame(
    engine: e,
    baked: set,
    scene: scene,
    W: {},
    F: F,
    tick: 70,
    cam: viewAt(30, 24, 1),
    shadows: shadows
        ? [
            (x: left.x, y: left.y, z: 0.0, r: .8),
            (x: right.x, y: right.y, z: 0.0, r: .8),
          ]
        : const [],
    c: Ctx(e.pix, w, h),
    display: display,
    dc: Ctx(display, 196, 216),
    signs: (c, a) {},
  );
  return Uint32List.fromList(e.pix);
}

void main() {
  // one engine for both sets, and one engine for each that only ever baked its own
  final shared = tinyEngine();
  bake(shared, 'a');
  final setA = BakedSet.capture(shared);
  bake(shared, 'b');
  final setB = BakedSet.capture(shared);
  final soloA = tinyEngine()..also((e) => bake(e, 'a'));
  final soloB = tinyEngine()..also((e) => bake(e, 'b'));
  final soloSetA = BakedSet.capture(soloA), soloSetB = BakedSet.capture(soloB);

  group('BakedSet', () {
    test('the two sets are not the same thing', () {
      expect(setA.leaves, isNotEmpty);
      expect(setB.leaves, isEmpty);
      expect(setA.tufts, isNotEmpty);
      expect(setB.tufts, isNotEmpty);
      expect(setA.ground, isNot(setB.ground));
      expect(setA.groundZ, isNot(setB.groundZ));
      expect(setA.pix, isNot(setB.pix));
      expect(setA.staticShadow.contains(1), isTrue);
      expect(setB.staticShadow.contains(1), isFalse);
    });

    test('capture takes a copy: the engine can go on and the set stays', () {
      final e = tinyEngine();
      bake(e, 'a');
      final set = BakedSet.capture(e);
      final ground = Uint8List.fromList(e.ground);
      final tufts = e.tufts.length, leaves = e.leaves.length;
      bake(e, 'b');
      expect(set.ground, ground);
      expect(set.tufts, hasLength(tufts));
      expect(set.leaves, hasLength(leaves));
      expect(e.leaves, isEmpty);
    });

    test('restoreInto puts back every buffer and both lists', () {
      final e = tinyEngine();
      bake(e, 'b');
      setA.restoreInto(e);
      expect(e.ground, setA.ground);
      expect(e.groundZ, setA.groundZ);
      expect(e.kinds, setA.kinds);
      expect(e.staticShadow, setA.staticShadow);
      expect(e.bakedPix, setA.pix);
      expect(e.bakedZ, setA.zb);
      expect(e.pix, setA.pix);
      expect(e.zb, setA.zb);
      expect(e.tufts, orderedEquals(setA.tufts));
      expect(e.leaves, orderedEquals(setA.leaves));
      setB.restoreInto(e);
      expect(e.leaves, isEmpty);
      expect(e.ground, setB.ground);
    });

    test('the blades\' colours of a bake come back with it (a set that lights its blades by its hour, El patio)', () {
      final e = tinyEngine();
      final lit0 = List.of(e.tuftLit), dark0 = List.of(e.tuftDark);
      bake(e, 'a');
      final day = BakedSet.capture(e);
      bake(e, 'b');
      for (var k = 0; k < e.tuftLit.length; k++) {
        e.tuftLit[k] = e.rgb(10 * k, 20, 30);
        e.tuftDark[k] = e.rgb(5 * k, 10, 15);
      }
      final dusk = BakedSet.capture(e);
      final litDusk = List.of(e.tuftLit), darkDusk = List.of(e.tuftDark);
      day.restoreInto(e);
      expect([e.tuftLit, e.tuftDark], [lit0, dark0]);
      dusk.restoreInto(e);
      expect([e.tuftLit, e.tuftDark], [litDusk, darkDusk]);
      // a BakedSet made without them leaves the engine's as they are
      BakedSet(
        pix: day.pix,
        zb: day.zb,
        ground: day.ground,
        groundZ: day.groundZ,
        kinds: day.kinds,
        staticShadow: day.staticShadow,
      ).restoreInto(e);
      expect([e.tuftLit, e.tuftDark], [litDusk, darkDusk]);
    });

    test('the captures of the shared engine are the solo engines\'', () {
      expect(setA.pix, soloSetA.pix);
      expect(setA.ground, soloSetA.ground);
      expect(setA.groundZ, soloSetA.groundZ);
      expect(setA.staticShadow, soloSetA.staticShadow);
      expect(setA.tufts.length, soloSetA.tufts.length);
      expect(setA.leaves.length, soloSetA.leaves.length);
      expect(setB.pix, soloSetB.pix);
      expect(setB.ground, soloSetB.ground);
      expect(setB.tufts.length, soloSetB.tufts.length);
    });
  });

  group('frames drawn alternately from two sets on one engine', () {
    final frames = [0, 9, 30, 77, 2];
    test(
      'each frame equals the frame of an engine that only ever baked that set',
      () {
        for (final F in frames) {
          final a = frame(shared, setA, F), b = frame(shared, setB, F);
          expect(a, frame(soloA, soloSetA, F), reason: 'A, frame $F');
          expect(b, frame(soloB, soloSetB, F), reason: 'B, frame $F');
          expect(a, isNot(b));
        }
        // and again, in the other order, and A twice running
        for (final F in frames.reversed) {
          final b = frame(shared, setB, F), a = frame(shared, setA, F);
          final a2 = frame(shared, setA, F);
          expect(b, frame(soloB, soloSetB, F), reason: 'B, frame $F');
          expect(a, frame(soloA, soloSetA, F), reason: 'A, frame $F');
          expect(a2, a);
        }
      },
    );

    test('a cast shadow shows on ground that is in one set only', () {
      final left = shared.project(
        shared.unproject(8, 42).x,
        shared.unproject(8, 42).y,
        0,
      );
      final right = shared.project(
        shared.unproject(50, 42).x,
        shared.unproject(50, 42).y,
        0,
      );
      final atL = left.sy.floor() * w + left.sx.floor();
      final atR = right.sy.floor() * w + right.sx.floor();
      // the ground at the left is A's, at the right B's
      expect([setA.ground[atL], setA.ground[atR]], [1, 0]);
      expect([setB.ground[atL], setB.ground[atR]], [0, 1]);
      final aWith = frame(shared, setA, 4),
          aWithout = frame(shared, setA, 4, shadows: false);
      final bWith = frame(shared, setB, 4),
          bWithout = frame(shared, setB, 4, shadows: false);
      // A: dark at the left, nothing at the right (the pixel there is not ground)
      expect(aWith[atL], isNot(aWithout[atL]));
      expect(aWith[atR], aWithout[atR]);
      // B: the other way round
      expect(bWith[atR], isNot(bWithout[atR]));
      expect(bWith[atL], bWithout[atL]);
    });

    test('without the whole set, the frames of the second set are wrong (the old recipe that copied pix and zb only)', () {
      // the engine has baked B last; drawing A from A's picture and depth alone leaves B's ground, tufts and leaves
      final e = tinyEngine();
      bake(e, 'a');
      final a = BakedSet.capture(e);
      bake(e, 'b');
      e.pix.setAll(0, a.pix);
      e.zb.setAll(0, a.zb);
      e.drawLeaves(0);
      e.drawTufts(0);
      final left = e.unproject(8, 42);
      e.castShadow(left.x, left.y, 0, .8);
      e.applyShadows(e.groundZ);
      final partial = Uint32List.fromList(e.pix);
      expect(partial, isNot(frame(soloA, soloSetA, 0)));
    });
  });
}

extension<T> on T {
  void also(void Function(T) f) => f(this);
}
