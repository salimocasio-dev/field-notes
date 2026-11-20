// The frame recipe (page 12, section 5, "The frame, every tick") as one function: the five steps happen in the order the
// page gives, the display picture is the view at `cam` (a 196 x 216 window, or a 98 x 108 region as 2 x 2 blocks),
// and `hud` and the hand sign are drawn on it after the crop. A recording engine and recording canvases show the order.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/signs_replay.dart' show SignScene, flatBaked;

/// The steps, in the order they happen, as the frame makes them.
class _Log {
  final List<String> steps = [];
}

class _RecEngine extends PpEngine {
  _RecEngine(this.log, this.baked, {super.still})
    : super(w: 240, h: 216, s: 26, originX: -30, originY: 40);

  final _Log log;
  final Uint32List baked;

  // the baked set is in the picture before the wind blows on it
  bool get _copied => pix.indexed.every((e) => e.$2 == baked[e.$1]);

  @override
  void drawLeaves(double t) =>
      log.steps.add('drawLeaves t=${jsNum(t)} copied=$_copied');
  @override
  void drawTufts(double t) =>
      log.steps.add('drawTufts t=${jsNum(t)} copied=$_copied');
  @override
  void castShadow(
    num x,
    num y,
    num z,
    num r, [
    int strength = 1,
    double dither = .4,
  ]) => log.steps.add(
    'castShadow ${jsNum(x)} ${jsNum(y)} ${jsNum(z)} ${jsNum(r)}',
  );
  @override
  void applyShadows(Float32List refZ) {
    log.steps.add('applyShadows groundZ=${identical(refZ, groundZ)}');
  }
}

/// A canvas that says which picture it is and what it fills.
class _RecCtx extends Ctx {
  _RecCtx(this.name, this.log, Uint32List target, int w, int h)
    : super(target, w, h);

  final String name;
  final _Log log;

  @override
  void fillRect(num x, num y, num w, num h) {
    log.steps.add('$name.fillRect ${fillStyle.toRadixString(16)}');
    super.fillRect(x, y, w, h);
  }
}

class _Scene extends SignScene {
  _Scene(this.log, this.display)
    : super(
        <String, dynamic>{
          'box': <String, dynamic>{},
          'handAt': <String, dynamic>{},
          'heartAt': [0, 0],
        },
        240,
        216,
      );

  final _Log log;
  final Uint32List display;
  late Ctx sceneCtx, hudCtx;
  Uint32List? displayAtHud;

  @override
  void draw(Ctx c, Map<String, dynamic> W, int a) {
    log.steps.add('scene.draw a=$a on ${identical(c, sceneCtx) ? 'c' : '?'}');
    // two marks in the picture: the top-left corner, and a pixel at (50, 30)
    c.fillStyle = 0xFF0000FF;
    c.fillRect(0, 0, 3, 3);
    c.fillRect(50, 30, 1, 1);
  }

  @override
  void hud(Ctx c, Map<String, dynamic> W, int a) {
    // the display already holds the crop when hud runs
    displayAtHud = Uint32List.fromList(display);
    log.steps.add('hud a=$a on ${identical(c, hudCtx) ? 'dc' : '?'}');
    c.fillStyle = 0xFF00FF00;
    c.fillRect(0, 0, 4, 4);
  }
}

/// A scene that draws part of the set again over its sprites (a sheet's `front.parts`): it is given the set as framed.
class _OverScene extends _Scene implements SetOverSprites {
  _OverScene(super.log, super.display);

  Uint32List? framed;
  BakedSet? bakedGiven;
  Map<String, dynamic>? wGiven;

  @override
  void setFramed(PpEngine engine, BakedSet baked, Map<String, dynamic> W) {
    log.steps.add('setFramed');
    framed = Uint32List.fromList(engine.pix);
    bakedGiven = baked;
    wGiven = W;
  }
}

/// A baked picture that says where each pixel is: opaque, `y * 240 + x` in the colour bits.
Uint32List _baked() => Uint32List.fromList([
  for (var i = 0; i < 240 * 216; i++) 0xFF000000 | (i & 0xFFFFFF),
]);

({
  _Log log,
  _RecEngine engine,
  _Scene scene,
  Uint32List display,
  Uint32List baked,
})
_run({
  required List<num> cam,
  int F = 25,
  int tick = 70,
  bool still = false,
  List<ShadowCast> shadows = const [],
  List<num>? handPoint,
  Float32List? bakedZ,
  bool over = false,
  BakedSet? bakedSet,
  Map<String, dynamic>? W,
}) {
  final log = _Log(), baked = _baked(), display = Uint32List(196 * 216);
  final engine = _RecEngine(log, baked, still: still);
  final scene = over ? _OverScene(log, display) : _Scene(log, display);
  final c = _RecCtx('c', log, engine.pix, 240, 216);
  final dc = _RecCtx('dc', log, display, 196, 216);
  scene
    ..sceneCtx = c
    ..hudCtx = dc;
  drawFrame(
    engine: engine,
    baked: bakedSet ?? flatBaked(baked, zb: bakedZ),
    scene: scene,
    W: W ?? {},
    F: F,
    tick: tick,
    cam: cam,
    shadows: shadows,
    c: c,
    display: display,
    dc: dc,
    signs: (c, a) => log.steps.add(
      'signs a=$a on ${identical(c, scene.sceneCtx) ? 'c' : '?'}',
    ),
    handPoint: handPoint,
  );
  return (
    log: log,
    engine: engine,
    scene: scene,
    display: display,
    baked: baked,
  );
}

void main() {
  group('the five steps happen in the order of page 12, section 5', () {
    test('baked set, wind, shadows, applyShadows, scene.draw, signs, crop, hud, hand', () {
      final r = _run(
        cam: viewAt(120, 108, 1),
        F: 25,
        shadows: [
          (x: 1.0, y: 2.0, z: .3, r: .45),
          (x: -1.5, y: 0.5, z: 1.0, r: .35),
        ],
        handPoint: [60, 40],
      );
      expect(r.log.steps.take(11).toList(), [
        'drawLeaves t=1.75 copied=true',
        'drawTufts t=1.75 copied=true',
        'castShadow 1 2 0.3 0.45',
        'castShadow -1.5 0.5 1 0.35',
        'applyShadows groundZ=true',
        'scene.draw a=12 on c',
        'c.fillRect ff0000ff', // the scene's two marks, on the picture
        'c.fillRect ff0000ff',
        'signs a=12 on c',
        'hud a=12 on dc',
        'dc.fillRect ff00ff00', // what hud drew
      ]);
      // then the hand, and only the hand: its outline colour and white (F >> 2 is 6, even: not pressed, no sparks)
      final after = r.log.steps.skip(11).toSet();
      expect(after, isNotEmpty);
      expect(
        after.difference({'dc.fillRect ffffffff', 'dc.fillRect ff10182a'}),
        isEmpty,
      );
      // the scene's drawing went to the picture, hud's and the hand's to the display
      expect(r.log.steps.where((s) => s.startsWith('c.fillRect')).length, 2);
    });

    test('a scene that draws the set again over its sprites is given the set as framed, just before its draw', () {
      final bakedSet = flatBaked(_baked());
      final W = <String, dynamic>{'door': 1};
      final r = _run(
        cam: viewAt(120, 108, 1),
        shadows: [(x: 1.0, y: 2.0, z: .3, r: .45)],
        over: true,
        bakedSet: bakedSet,
        W: W,
      );
      final steps = r.log.steps;
      expect(
        steps.indexOf('setFramed'),
        steps.indexOf('applyShadows groundZ=true') + 1,
      );
      expect(
        steps.indexOf('scene.draw a=12 on c'),
        steps.indexOf('setFramed') + 1,
      );
      final s = r.scene as _OverScene;
      // the set as the frame shows it before the sprites: the baked picture (the recording engine's shadows draw nothing)
      expect(s.framed, r.baked);
      expect(identical(s.bakedGiven, bakedSet), isTrue);
      expect(identical(s.wGiven, W), isTrue);
      // a scene that is not one is never asked
      expect(
        _run(cam: viewAt(120, 108, 1)).log.steps,
        isNot(contains('setFramed')),
      );
    });

    test(
      'the wind: 8 steps a second of the frame count, still when the engine is',
      () {
        List<String> winds(int F, {bool still = false, int tick = 70}) => _run(
          cam: viewAt(120, 108, 1),
          F: F,
          tick: tick,
          still: still,
        ).log.steps.where((s) => s.startsWith('drawLeaves')).toList();
        // floor(F * 70 / 1000 * 8) / 8
        expect(winds(0), ['drawLeaves t=0 copied=true']);
        expect(winds(1), ['drawLeaves t=0 copied=true']);
        expect(winds(2), ['drawLeaves t=0.125 copied=true']);
        expect(winds(25), ['drawLeaves t=1.75 copied=true']);
        expect(winds(26), ['drawLeaves t=1.75 copied=true']);
        expect(winds(27), ['drawLeaves t=1.875 copied=true']);
        expect(winds(1000), ['drawLeaves t=70 copied=true']);
        expect(winds(1000, still: true), ['drawLeaves t=0 copied=true']);
        expect(winds(25, tick: 140), ['drawLeaves t=3.5 copied=true']);
      },
    );

    test('the shadows really darken the ground, and the wind steps do not change a set with nothing to blow', () {
      final baked = Uint32List(240 * 216)..fillRange(0, 240 * 216, 0xFF808080);
      final log = _Log();
      final engine = PpEngine(w: 240, h: 216, s: 26, originX: -30, originY: 40);
      final zb = Float32List(240 * 216);
      // all ground, at the depth the baked picture has: nothing stands on it
      final bakedSet = BakedSet(
        pix: baked,
        zb: zb,
        ground: Uint8List(240 * 216)..fillRange(0, 240 * 216, 1),
        groundZ: zb,
        kinds: Uint8List(240 * 216),
        staticShadow: Uint8List(240 * 216),
      );
      final display = Uint32List(196 * 216);
      final scene = _Scene(log, display);
      void frame(List<ShadowCast> shadows) {
        drawFrame(
          engine: engine,
          baked: bakedSet,
          scene: scene..sceneCtx = Ctx(engine.pix, 240, 216),
          W: {},
          F: 3,
          tick: 70,
          cam: viewAt(120, 108, 1),
          shadows: shadows,
          c: Ctx(engine.pix, 240, 216),
          display: display,
          dc: scene.hudCtx = Ctx(display, 196, 216),
          signs: (c, a) {},
        );
      }

      frame(const []);
      final plain = Uint32List.fromList(engine.pix);
      final p = engine.project(0, 0, 0);
      final at = p.sy.floor() * 240 + p.sx.floor();
      frame([(x: 0.0, y: 0.0, z: 0.0, r: 1.0)]);
      // the pixel under the shadow's middle is darker in every channel (applyShadows tints it .54 .52 .72)
      int ch(int v, int s) => (v >> s) & 255;
      expect(ch(engine.pix[at], 0), lessThan(ch(plain[at], 0)));
      expect(ch(engine.pix[at], 8), lessThan(ch(plain[at], 8)));
      expect(ch(engine.pix[at], 16), lessThan(ch(plain[at], 16)));
      // the next frame, with no shadow, is the baked set again: nothing is left behind
      frame(const []);
      expect(
        engine.pix.sublist(100 * 240, 101 * 240),
        plain.sublist(100 * 240, 101 * 240),
      );
    });
  });

  group('the display picture is the view at cam', () {
    // the picture, as the frame leaves it: the baked set and the scene's two marks
    Uint32List picture(Uint32List baked) {
      final p = Uint32List.fromList(baked);
      p.fillRange(0, 3, 0xFF0000FF);
      for (var y = 1; y < 3; y++) {
        p.fillRange(y * 240, y * 240 + 3, 0xFF0000FF);
      }
      p[30 * 240 + 50] = 0xFF0000FF;
      return p;
    }

    for (final zoom in [1, 2]) {
      final label = zoom == 1
          ? '1x: a 196 x 216 window'
          : '2x: a 98 x 108 region, each pixel a 2 x 2 block';
      for (final c in [
        [120, 108],
        [0, 0],
        [240, 0],
        [0, 216],
        [240, 216],
        [50, 30],
        [97, 53],
      ]) {
        test('$label, centred on $c', () {
          final cam = viewAt(c[0], c[1], zoom);
          final r = _run(cam: cam);
          final pic = picture(r.baked);
          // the hud's square covers the display's corner: leave it out of the comparison
          final shown = Uint32List.fromList(r.scene.displayAtHud!);
          for (var j = 0; j < 216; j++) {
            for (var i = 0; i < 196; i++) {
              final want = pic[(cam[1] + j ~/ zoom) * 240 + cam[0] + i ~/ zoom];
              expect(shown[j * 196 + i], want, reason: 'display $i,$j');
            }
          }
          // and the hud was drawn over it, after
          expect(r.display[0], 0xFF00FF00);
          expect(r.display[3 * 196 + 3], 0xFF00FF00);
          expect(r.display[4 * 196 + 4], shown[4 * 196 + 4]);
          // the picture itself holds no hud
          expect(r.engine.pix.contains(0xFF00FF00), isFalse);
        });
      }
    }

    test('the hand is drawn after the crop and the hud, on the display, in the view\'s own scale', () {
      for (final zoom in [1, 2]) {
        final cam = viewAt(120, 108, zoom);
        // the same frame, with and without the hand
        final with_ = _run(
          cam: cam,
          F: 4,
          handPoint: [cam[0] + 40, cam[1] + 30],
        );
        final without = _run(cam: cam, F: 4);
        final changed = [
          for (var i = 0; i < 196 * 216; i++)
            if (with_.display[i] != without.display[i]) i,
        ];
        expect(changed, isNotEmpty);
        // juego.js: Math.round((p - cam) * z) less 4 hand pixels (k = 3) to the left; pressed (F >> 2 is odd), the hand has
        // three sparks above and beside it
        final x0 = 40 * zoom - 12, y0 = 30 * zoom;
        for (final i in changed) {
          final x = i % 196, y = i ~/ 196;
          expect(x, inInclusiveRange(x0 - 8, x0 + 12 * 3 + 8));
          expect(y, inInclusiveRange(y0 - 14, y0 + 15 * 3 + 1));
        }
        // and it is there: its first row of pixels is where (p - cam) * z puts it
        expect(
          changed.any(
            (i) => i % 196 >= x0 && i % 196 < x0 + 36 && i ~/ 196 >= y0,
          ),
          isTrue,
        );
        // the hand never covers the hud's mark... it can: but it is drawn after it, so it is the hand's colour there
        expect(handAfterHud(with_.log.steps), isTrue);
        // the picture is the same with and without the hand
        expect(with_.engine.pix, without.engine.pix);
      }
    });

    test(
      'any other size of view is refused: a fractional scale is never drawn',
      () {
        for (final bad in [
          [0, 0, 170, 187.3],
          [0, 0, 196, 104],
          [0, 0, 98, 216],
        ]) {
          expect(() => _run(cam: bad), throwsArgumentError, reason: '$bad');
        }
      },
    );
  });
}

/// hud comes before the hand's fills in the log.
bool handAfterHud(List<String> steps) {
  final hud = steps.indexWhere((s) => s.startsWith('hud'));
  final hand = steps.lastIndexWhere((s) => s == 'dc.fillRect ffffffff');
  return hud >= 0 && hand > hud;
}
