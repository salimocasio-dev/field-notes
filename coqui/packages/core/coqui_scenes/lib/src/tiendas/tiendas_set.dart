// Port of docs/proyecto/pixel/tiendas-set.html: Las tiendas' set, its states, call for call (order 56b). The pieces are
// La calle's kit (lib/src/calle/calle_base.dart). The page's names are kept, capitals included (page 12, section 6): the
// lints on names are off in this file.
//
// The page draws two pictures with their own origin: `fila=tiendas` (the row of four shops, origin (0, 24)) and
// `fila=altos` (story 55's two buildings, origin (6, 48)). As El mostrador's street, the state `altos` is built on an
// engine of its own origin and its buffers are then handed to the scene's engine: every buffer is the page's own.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// tiendas-set.html: ORIGIN, the row of four shops (`fila=tiendas`).
const List<double> ORIGIN_TIENDAS = [0, 24];

/// tiendas-set.html: ORIGIN, story 55's two buildings (`fila=altos`).
const List<double> ORIGIN_ALTOS = [6, 48];

PpEngine _engine(List<double> o, bool still) => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: o[0],
  originY: o[1],
  shadowX: .9,
  shadowY: -.1,
  still: still,
);

/// The engine Las tiendas' set is built on (`window.PP_SCENE` of `fila=tiendas`): 240 x 216, S 26, origin (0, 24),
/// shadows to (.9, -.1). The state `altos` is built on [tiendasAltosEngine] and handed over to this one.
PpEngine tiendasEngine({bool still = false}) => _engine(ORIGIN_TIENDAS, still);

/// The engine of the state `altos` (the page with `?fila=altos`: origin (6, 48)).
PpEngine tiendasAltosEngine({bool still = false}) =>
    _engine(ORIGIN_ALTOS, still);

/// One state of the set (tiendas-set.html: `SET`, from the address): `fila` tiendas or altos, `par` a or b and `lado`
/// izq or der (altos), `hora` manana or tarde, `nube` 0, 1 or 2 (the sky and the light).
class TiendasState {
  const TiendasState({
    this.fila = 'tiendas',
    this.par = 'a',
    this.lado = 'izq',
    this.hora = 'manana',
    this.nube = 0,
  });

  /// tiendas-set.html: `pick(...)` from a query; a value the page does not allow takes its default, as there.
  factory TiendasState.fromQuery(String query) {
    final q = Uri.splitQueryString(
      query.startsWith('?') ? query.substring(1) : query,
    );
    String pick(String k, List<String> allowed, String def) {
      final v = q[k];
      return v != null && allowed.contains(v) ? v : def;
    }

    return TiendasState(
      fila: pick('fila', const ['tiendas', 'altos'], 'tiendas'),
      par: pick('par', const ['a', 'b'], 'a'),
      lado: pick('lado', const ['izq', 'der'], 'izq'),
      hora: pick('hora', const ['manana', 'tarde'], 'manana'),
      nube: int.tryParse(q['nube'] ?? '') ?? 0,
    );
  }

  /// A key of the sheet's `setKey` read back: tiendas "hora + nube" (e.g. "manana-0"), altos "par + lado + hora" (e.g.
  /// "a-izq-manana").
  factory TiendasState.fromKey(String key) {
    final t = RegExp(r'^(manana|tarde)-([012])$').firstMatch(key);
    if (t != null) {
      return TiendasState(hora: t[1]!, nube: int.parse(t[2]!));
    }
    final a = RegExp(r'^([ab])-(izq|der)-(manana|tarde)$').firstMatch(key);
    if (a != null) {
      return TiendasState(fila: 'altos', par: a[1]!, lado: a[2]!, hora: a[3]!);
    }
    throw ArgumentError.value(key, 'key', "not a key of Las tiendas' set");
  }

  final String fila, par, lado, hora;
  final int nube;

  bool get altos => fila == 'altos';

  /// The sheet's key.
  String get key => altos ? '$par-$lado-$hora' : '$hora-$nube';

  /// The page's query for this state (as the sheet's `setKey.baked` writes it).
  String get query => altos
      ? '?fila=altos&par=$par&lado=$lado&hora=$hora'
      : '?fila=tiendas&hora=$hora&nube=$nube';
}

/// tiendas-set.html: E, the set's numbers.
abstract final class E {
  // the row starts at X0; a front's width and height; the pavement from y = 0 to PV; the street from S0
  static const double X0 = -4.5, FW = 2.25, H = 3.6, PV = 2.6, S0 = 2.8;
  static const List<String> FRONTS = ['tienda', 'banco', 'farmacia', 'correo'];
  static const Map<String, List<List<int>>> COLOR = {
    'tienda': [
      [250, 214, 120],
      [206, 150, 70],
    ],
    'banco': [
      [214, 214, 220],
      [130, 136, 150],
    ],
    'farmacia': [
      [226, 244, 226],
      [70, 150, 90],
    ],
    'correo': [
      [250, 232, 190],
      [60, 90, 170],
    ],
  };
  // a front's door: its left edge from the front's left edge, its width, its height
  static const double DOOR = .58, DW = 1.1, DH = 2.4;
  // the little horse (left of the tienda's door); the post box (right of the correo's door); the seat
  static const List<double> HORSE = [-4.15, 1.3],
      BUZON = [4.25, .5],
      SEAT = [.9, 1.95, .8];
  // story 55's buildings: heights, widths, and the two places' left edges
  static const ({double h, double w}) ALTO = (h: 4.6, w: 3.9),
      NUEVO = (h: 2.75, w: 3.9);
  static const List<double> AX = [-4.2, .4];

  static double frontX(String k) => X0 + FW * FRONTS.indexOf(k);
  static double doorX(String k) => frontX(k) + DOOR;
}

/// The light of the hours and the clouds (tiendas-set.html: the lightPass calls of buildSet), which the scene's own
/// pieces of the set (a door that opens) take too: the multiplier and the addend, or null (no pass).
({List<double> m, List<double> a})? tiendasLight(TiendasState SET) {
  if (SET.nube >= 1) {
    return SET.nube == 2
        ? (m: const [.82, .85, .9], a: const [-2, 0, 8])
        : (m: const [.92, .94, .96], a: const [0, 0, 4]);
  }
  if (SET.hora == 'tarde') {
    return (m: const [1.0, .93, .84], a: const [10, 2, -8]);
  }
  return null;
}

/// tiendas-set.html's buildSet on an engine [e] with the row's origin. The state `altos` is built, as the page builds it
/// with its own origin, on a second engine (made once per [TiendasSet]), and its buffers are then copied into [e].
class TiendasSet {
  TiendasSet(this.e, this.b) : k = SetKit(e, b) {
    cl = CalleBase(k);
  }

  final PpEngine e;
  final PpBuild b;
  final SetKit k;
  late final CalleBase cl;

  PpEngine? _altos;
  SetKit? _altosKit;
  CalleBase? _altosCl;

  /// The engine `altos` is built on (made on first use).
  PpEngine get altosEngine => _altos ??= tiendasAltosEngine(still: e.STILL);

  /// Record which part drew each pixel at the next bakes (tiendas-set.html `?tags=1`).
  bool tags = false;

  SetKit? _lastKit;

  /// The pixels each part drew last at the last bake, when [tags] is on.
  List<String?>? get partTags => _lastKit?.PART_TAGS;

  double _hyp(num a, num b) => math.sqrt(a * a + b * b);

  // the engine, kit and painters of the bake now
  late PpEngine _e;
  late SetKit _k;
  late CalleBase _cl;

  int _rgb(num r, num g, num b) => _e.rgb(r, g, b);
  int _shade(List<num> c, num base, num a, num bb) => _cl.shade(c, base, a, bb);

  // tiendas-set.html: PIC, the pictures of the four signs
  int _pic(String k, num u, num v) {
    switch (k) {
      case 'tienda':
        // toys: a ball and a teddy bear's head
        final X = (u - .5) * 2.0, Y = v - .5;
        if (_hyp(X + .52, Y) < .3) {
          return ((X + .52).abs() < .05 || Y.abs() < .04)
              ? _rgb(250, 250, 250)
              : (X + .52) * Y > 0
              ? _rgb(226, 60, 50)
              : _rgb(60, 120, 220);
        }
        final bx = X - .42;
        if (_hyp(bx, Y + .04) < .27 ||
            _hyp(bx - .22, Y - .24) < .11 ||
            _hyp(bx + .22, Y - .24) < .11) {
          return (_hyp(bx, Y + .1) < .1)
              ? _rgb(240, 214, 170)
              : (_hyp(bx - .1, Y - .02) < .035 || _hyp(bx + .1, Y - .02) < .035)
              ? _rgb(40, 30, 30)
              : _rgb(170, 110, 60);
        }
        return 0;
      case 'banco':
        // money: stacks of gold coins and one coin standing
        final X = (u - .5) * 2.0, Y = v - .5;
        for (final c in const [
          [-.5, -.2],
          [-.5, -.06],
          [-.5, .08],
          [.0, -.2],
          [.0, -.06],
          [.5, -.2],
        ]) {
          final ex = (X - c[0]) / .3, ey = (Y - c[1]) / .1;
          if (ex * ex + ey * ey < 1) {
            return ey > .35 ? _rgb(196, 150, 40) : _rgb(250, 210, 80);
          }
        }
        final r = _hyp(X - .5, Y - .16);
        if (r < .24) return r > .18 ? _rgb(196, 150, 40) : _rgb(250, 210, 80);
        return 0;
      case 'farmacia':
        // a green cross
        return (((u - .5).abs() < .07 && (v - .5).abs() < .34) ||
                ((u - .5).abs() < .21 && (v - .5).abs() < .12))
            ? _rgb(40, 160, 80)
            : 0;
      case 'correo':
        // a letter: a white envelope with its flap and a red stamp, on yellow
        if (u < .16 || u > .84 || v < .18 || v > .82) {
          return _rgb(250, 214, 90);
        }
        final t = (u - .16) / .68, flap = .82 - math.min(t, 1 - t) * .62;
        if (u > .68 && u < .8 && v > .56 && v < .78) return _rgb(226, 60, 50);
        return ((v - flap).abs() < .045 ||
                u < .2 ||
                u > .8 ||
                v < .23 ||
                v > .77)
            ? _rgb(40, 50, 90)
            : _rgb(255, 255, 255);
    }
    return 0;
  }

  // tiendas-set.html: groundAt
  int groundAt(num x, num y, int ix, int iy) {
    if (y < -3.2) return 0; // behind the row: sky
    if (y < 0) return _cl.slab(x, y, ix, iy);
    if (y <= E.PV) return _cl.slab(x, y, ix, iy);
    if (y < E.S0) return _cl.kerb();
    return ((y - 5.0).abs() < .06 && ((x + 40).remainder(1.6)) < 1.0)
        ? _cl.paint(CalleBase.LINE)
        : _cl.asphalt(ix, iy);
  }

  // tiendas-set.html: tiendas
  void tiendas() {
    for (final kk in E.FRONTS) {
      _k.part(kk, () {
        final x0 = E.frontX(kk),
            x1 = x0 + E.FW,
            d0 = x0 + E.DOOR,
            c = E.COLOR[kk]![0],
            trim = E.COLOR[kk]![1],
            h = E.H + (kk == 'banco' ? .25 : 0);
        // the sign: nearly as wide as the front
        final s0 = x0 + .22, s1 = x1 - .22, sz0 = E.DH + .18, sz1 = h - .06;
        final holes = <List<num>>[
          [d0 - .12, d0 + E.DW + .12, 0, E.DH + .12],
          [s0, s1, sz0, sz1],
        ];
        if (kk == 'tienda') holes.add([x0 + .1, x0 + .5, .7, 1.9]);
        _cl.top(x0, -1.0, x1, 0, h, (a, bb) => _shade(trim, 3.2, a, bb));
        _cl.wallAlongX(0, x0, x1, h, c, trim, holes);
        _cl.faceX(x1, -1.0, 0, 0, h, (bb, z) => _shade(c, 1.7, bb, z));
        _cl.doorX(
          0,
          d0,
          d0 + E.DW,
          E.DH,
          false,
          kk == 'banco'
              ? const [120, 130, 150]
              : kk == 'farmacia'
              ? const [236, 240, 236]
              : kk == 'correo'
              ? const [60, 90, 170]
              : CalleBase.WOOD,
          true,
        );
        _cl.signX(0, s0, s1, sz0, sz1, (u, v) => _pic(kk, u, v));
        if (kk == 'tienda') {
          // its window: a ball and a top
          _cl.faceY(.02, x0 + .1, x0 + .5, .7, 1.9, (a, z) {
            final u = (a - x0 - .1) / .4, v = (z - .7) / 1.2;
            if (u < .1 || u > .9 || v < .04 || v > .96) {
              return _rgb(244, 240, 228);
            }
            if (_hyp(u - .5, (v - .72) * 2.2) < .32) return _rgb(226, 60, 50);
            if ((u - .5).abs() < .3 - (v - .25).abs() * 1.6 && v < .44) {
              return _rgb(60, 150, 200);
            }
            return _rgb(170, 210, 222);
          }, CalleBase.PP);
        }
      });
    }
    _k.part('caballito', () {
      // the little horse: a red base, a brown horse with a white mane, a coin box
      final x = E.HORSE[0], y = E.HORSE[1];
      _cl.box(x - .32, y - .22, 0, x + .32, y + .22, .14, const [206, 60, 50]);
      // the body
      _cl.box(x - .26, y - .1, .42, x + .2, y + .1, .72, const [176, 120, 70]);
      // the neck and head
      _cl.box(
        x + .12,
        y - .09,
        .62,
        x + .28,
        y + .09,
        1.02,
        const [176, 120, 70],
      );
      _cl.box(x + .22, y - .08, .86, x + .44, y + .08, 1.0, const [
        196,
        140,
        86,
      ]);
      // the mane
      _cl.box(x + .08, y - .1, .98, x + .16, y + .1, 1.08, const [
        250,
        246,
        236,
      ]);
      for (final dx in const [-.2, .12]) {
        _cl.box(x + dx, y - .08, .14, x + dx + .08, y + .08, .42, const [
          150,
          100,
          60,
        ]);
      }
      // the coin box on its post
      _cl.box(x - .5, y - .1, 0, x - .38, y + .1, .8, const [70, 74, 84]);
      _cl.box(x - .52, y - .12, .8, x - .36, y + .12, .98, const [
        236,
        196,
        60,
      ]);
      _e.castShadow(x, y, .5, .45);
    });
    _k.part('buzon', () {
      // the post box: blue, a dark slot, a white envelope painted on its front
      final x = E.BUZON[0], y = E.BUZON[1];
      _cl.box(x - .12, y - .1, 0, x + .12, y + .1, .3, const [50, 60, 90]);
      _cl.box(x - .24, y - .2, .3, x + .24, y + .2, 1.2, const [60, 100, 200]);
      _cl.faceY(
        y + .21,
        x - .2,
        x + .2,
        .98,
        1.08,
        (_, _) => _rgb(20, 30, 60),
        CalleBase.PP,
      );
      _cl.faceY(y + .21, x - .17, x + .17, .48, .84, (a, z) {
        final t = (a - x + .17) / .34, fl = .84 - math.min(t, 1 - t) * .3;
        return (z - fl).abs() < .03 ? _rgb(60, 100, 200) : _rgb(255, 255, 255);
      }, CalleBase.PP);
      _e.castShadow(x, y, .6, .32);
    });
    _k.part('asiento', () => _cl.seat(E.SEAT[0], E.SEAT[1], E.SEAT[0] + 2.0));
  }

  // tiendas-set.html: altos
  void altos(TiendasState SET) {
    final tallLeft = SET.lado == 'izq', b = SET.par == 'b';
    void place(bool isTall, num x0) => _k.part(isTall ? 'alto' : 'nuevo', () {
      final B = isTall ? E.ALTO : E.NUEVO,
          x1 = x0 + B.w,
          d0 = x0 + B.w / 2 - .55;
      final List<int> c = isTall
              ? (b ? const [176, 96, 74] : const [168, 168, 172])
              : (b ? const [250, 216, 96] : const [120, 206, 220]),
          trim = isTall
              ? (b ? const [120, 66, 52] : const [116, 116, 124])
              : (b ? const [226, 150, 60] : const [250, 250, 250]);
      final holes = <List<num>>[
        [d0 - .12, d0 + 1.22, 0, 2.5],
      ];
      if (isTall) {
        for (var f = 0; f < 3; f++) {
          for (final wx in const [.45, 2.45]) {
            if (f == 0 && (x0 + wx - d0).abs() < 1.2) continue;
            holes.add([
              x0 + wx - .08,
              x0 + wx + 1.0,
              .95 + f * 1.45,
              2.05 + f * 1.45,
            ]);
          }
        }
      } else {
        holes.add([x0 + .4, x0 + 1.3, 1.0, 2.0]);
      }
      _cl.top(x0, -1.4, x1, 0, B.h, (a, bb) => _shade(trim, 3.2, a, bb));
      _cl.faceY(0, x0, x1, 0, B.h, (a, z) {
        if (holes.any((k) => a > k[0] && a < k[1] && z > k[2] && z < k[3])) {
          return 0;
        }
        // a crack up the old wall
        if (isTall &&
            !b &&
            (((a - x0) - 1.9 - math.sin(z * 2.1) * .12).abs() < .025 &&
                z > 2.0 &&
                z < 4.0)) {
          return _rgb(96, 96, 104);
        }
        // old brick
        if (isTall &&
            b &&
            (((z / .16).floor() +
                        ((a + ((z / .16).floor().remainder(2)) * .2) / .4)
                            .floor())
                    .remainder(7) ==
                0)) {
          return _shade(const [150, 80, 62], 2.4, a, z);
        }
        return z < .5
            ? _shade(trim, 2.2, a, z)
            : z > B.h - .22
            ? _shade(trim, 2.6, a, z)
            : _shade(c, isTall ? 2.2 : 2.5, a, z);
      });
      _cl.faceX(x1, -1.4, 0, 0, B.h, (bb, z) => _shade(c, 1.6, bb, z));
      _cl.doorX(
        0,
        d0,
        d0 + 1.1,
        2.4,
        false,
        isTall ? const [96, 70, 56] : const [250, 250, 250],
        false,
      );
      // the windows: old shutters, or new glass
      for (final kk in holes.skip(1)) {
        _cl.faceY(
          .02,
          kk[0],
          kk[1],
          kk[2],
          kk[3],
          (a, z) => isTall
              ? ((((z - kk[2]) / .09).floor().remainder(2)) != 0
                    ? _rgb(110, 124, 110)
                    : _rgb(84, 100, 90))
              : (((a * 1.4 + z).remainder(1.2)) < .18
                    ? _rgb(226, 244, 248)
                    : _rgb(150, 200, 214)),
          CalleBase.PP,
        );
      }
      if (isTall && b) {
        // the clock that has stopped
        final cx = x0 + B.w / 2, cz = 4.05;
        _cl.faceY(.03, cx - .42, cx + .42, cz - .42, cz + .42, (a, z) {
          final r = _hyp(a - cx, z - cz);
          return r > .42
              ? 0
              : r > .36
              ? _rgb(60, 50, 44)
              : ((a - cx).abs() < .025 && z > cz && z < cz + .28) ||
                    ((z - cz).abs() < .025 && a > cx && a < cx + .2)
              ? _rgb(40, 40, 50)
              : _rgb(250, 246, 232);
        }, CalleBase.PP);
      }
      if (!isTall && !b) {
        // the ladder and the paint pot
        _cl.box(x1 - .75, .2, 0, x1 - .65, .3, 1.7, const [196, 148, 92]);
        _cl.box(x1 - .35, .5, 0, x1 - .25, .6, 1.7, const [196, 148, 92]);
        for (num z = .3; z < 1.6; z += .32) {
          _cl.box(x1 - .72, .34, z, x1 - .28, .42, z + .05, const [
            176,
            128,
            76,
          ]);
        }
        _cl.box(x1 - 1.3, .5, 0, x1 - 1.0, .8, .3, const [250, 250, 250]);
        _cl.top(
          x1 - 1.27,
          .53,
          x1 - 1.03,
          .77,
          .31,
          (_, _) => _rgb(120, 206, 220),
        );
      }
      if (!isTall && b) {
        // the young tree tied to a stick
        final tx = x1 - .7, ty = .9;
        _cl.box(tx + .12, ty - .03, 0, tx + .18, ty + .03, 1.2, const [
          196,
          148,
          92,
        ]);
        for (num z = 0; z <= 1.0; z += CalleBase.PZ) {
          _e.plot(tx, ty, z, _rgb(120, 84, 56));
        }
        _e.sphere(tx, ty, 1.25, .34, CalleBase.LEAF_L, 'rough');
        _e.sphere(tx + .12, ty + .05, 1.5, .24, CalleBase.LEAF, 'rough');
        _e.castShadow(tx, ty, 1.2, .35);
      }
    });

    place(tallLeft, E.AX[0]);
    place(!tallLeft, E.AX[1]);
  }

  // tiendas-set.html: buildSet
  void buildSet(TiendasState SET) {
    final alt = SET.altos;
    _e = alt ? altosEngine : e;
    _k = alt ? (_altosKit ??= SetKit(_e, PpBuild(_e))) : k;
    _cl = alt ? (_altosCl ??= CalleBase(_k)) : cl;
    final en = _e, kit = _k;
    _lastKit = kit;
    kit.PART_TAGS = tags ? List<String?>.filled(en.W * en.H, null) : null;
    final W = en.W, H = en.H;
    en.zb.fillRange(0, en.zb.length, -1e9);
    en.pix.fillRange(0, en.pix.length, 0);
    en.kinds.fillRange(0, en.kinds.length, 0);
    en.ground.fillRange(0, en.ground.length, 0);
    en.shadowMask.fillRange(0, en.shadowMask.length, 0);
    en.staticShadow.fillRange(0, en.staticShadow.length, 0);
    en.tufts.clear();
    en.leaves.clear();
    en.pendingShadows.clear();
    kit.slabTops.clear();
    kit.glowReset();
    for (var iy = 0; iy < H; iy++) {
      for (var ix = 0; ix < W; ix++) {
        final g = en.unproject(ix + .5, iy + .5),
            i = iy * W + ix,
            c = groundAt(g.x, g.y, ix, iy);
        if (c == 0) continue;
        en.pix[i] = c;
        en.ground[i] = 1;
        en.zb[i] = (g.x + g.y) / en.R2 * en.COS;
        en.kinds[i] = KIND_ROAD;
      }
    }
    en.groundZ.setAll(0, en.zb);
    if (alt) {
      altos(SET);
    } else {
      tiendas();
    }
    en.flushShadows();
    en.pendingShadows.clear();
    en.bakeOcclusion();
    kit.joinSlabs();
    en.staticShadow.setAll(0, en.shadowMask);
    en.applyShadows(en.groundZ);
    en.shadeEdges();
    final light = tiendasLight(SET);
    if (light != null) kit.lightPass(light.m, light.a);
    final base = _cl.sky(SET.nube == 2 ? 'gris' : SET.hora, null);
    // the dark cloud: at the left edge, or over everything
    kit.skyFill((ix, iy) {
      if (SET.nube == 1) {
        final d =
            _hyp((ix - 40) / 60, (iy - 6) / 16) + math.sin(ix * .21) * .08;
        if (d < 1) {
          return d < .6 ? _rgb(86, 90, 108) : _rgb(112, 116, 132);
        }
      }
      if (SET.nube == 2) {
        // a bank of round dark clouds
        num m = 9;
        for (var kk = 0; kk < 9; kk++) {
          m = math.min(
            m,
            _hyp((ix - 14 - kk * 28) / 26, (iy - 10 - (kk % 2) * 9) / 15),
          );
        }
        if (m < 1) {
          return m < .55
              ? _rgb(70, 74, 94)
              : m < .85
              ? _rgb(96, 100, 120)
              : _rgb(150, 154, 170);
        }
      }
      return base(ix, iy);
    });
    en.bakedPix.setAll(0, en.pix);
    en.bakedZ.setAll(0, en.zb);
    if (alt) _handOver(en);
  }

  // the state altos' bake, handed to the scene's engine: everything a bake leaves (BakedSet.capture reads it from there)
  void _handOver(PpEngine from) {
    e.pix.setAll(0, from.pix);
    e.zb.setAll(0, from.zb);
    e.bakedPix.setAll(0, from.bakedPix);
    e.bakedZ.setAll(0, from.bakedZ);
    e.kinds.setAll(0, from.kinds);
    e.ground.setAll(0, from.ground);
    e.groundZ.setAll(0, from.groundZ);
    e.staticShadow.setAll(0, from.staticShadow);
    e.shadowMask.setAll(0, from.shadowMask);
    e.tufts
      ..clear()
      ..addAll(from.tufts);
    e.leaves
      ..clear()
      ..addAll(from.leaves);
    e.glints.clear();
  }

  // tiendas-set.html: frame (what the reference made: the bake at wind time 0, no casts)
  void frame() {
    e.pix.setAll(0, e.bakedPix);
    e.zb.setAll(0, e.bakedZ);
    e.applyShadows(e.groundZ);
  }
}
