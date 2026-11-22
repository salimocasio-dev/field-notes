// La calle's things that drive as sprites: the red car, the blue car and the guagua, each baked ONCE from calle-base.js
// `vehicle(kind, x, y, heading, board)` (calle_base.dart's port), so that the game's sprites and the readers' pictures
// (the sets' `autos=`) come from one drawing (page 13, orders 54 to 57). Shared by the four scenes of La calle (esquina,
// parada, tiendas, cruce). First writer: order 54b (La esquina); the other builders copy it and add to it only by adding.
//
// The bake, the same in Dart and in the JavaScript (tool/make_calle_vehicles_ref.mjs, test/calle_vehicles_test.dart):
//   1. an engine of 240 x 216, S 26, origin (0, 0), shadows (.9, -.1), its buffers empty;
//   2. a flat ground under every pixel (ground 1, its depth (x + y) / R2 * COS as every set's ground pass);
//   3. vehicle(kind, 3, 3, heading, board) at the bake's point [BAKE_X], [BAKE_Y] (its floor's middle on the
//      picture's middle column);
//   4. shadeEdges(), as every set does after building (a vehicle darkens its own outline against the ground);
//   5. the sprite: every pixel whose depth is not the ground's, cropped to their box; its depth kept per pixel, less the
//      depth of the bake's point (so that at any place the pixel's depth is that place's depth plus its own).
// A set that lights its picture after the shadows (esquina-set.html at tarde: lightPass) gives its vehicles the same light
// ([litVehicle]: the pass's colour sum on the sprite's pixels, as lightPass does them). The ground's occlusion round a
// vehicle a set bakes with `autos=` (bakeOcclusion) and its cast shadow are not the sprite's: the shadow is cast each
// frame at the vehicle's place ([vehicleShadows]: the casts vehicle() makes), the occlusion is not drawn.
//
// The new looks (not in calle-base.js, drawn here on the engine over the baked vehicle, in its way): a guagua with its
// front door open (`puerta`), a car with its front side window down (`ventana`, with the window's pixels as a mask: a
// face is drawn in it, [vehicleWithFace]) and a car with its front door open (`puerta`).
//
// Driving: a vehicle in W is a map ({k, kind, heading, board, look, x, y, vis}); [drive] moves it along its lane (x) in
// whole ticks; [placeVehicle] puts the sprite on the picture by the world point of its floor's middle (the sheets' rule:
// "a thing that drives: its spot is the middle of its floor"); [putVehicle] composes it into a sprite layer with its
// per-pixel depth: a set pixel nearer than the vehicle's hides it; a person is drawn over it where the person's plane
// (the sheets' front.plane) plus front.bias is nearer than the vehicle's pixel (the sheets' rule for a vehicle baked
// into the set: "a car or a guagua baked into the set hides whoever stands behind it").
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// The bake's point: the middle of the vehicle's floor (world, z 0) on the bake's engine.
const double BAKE_X = 3, BAKE_Y = 3;

/// The kinds that drive: the red car, the blue car, the guagua.
const List<String> VEHICLE_KINDS = ['carro', 'azul', 'guagua'];

/// The headings: `i` towards -x (its right side faces the camera), `d` towards +x.
const List<String> VEHICLE_HEADINGS = ['i', 'd'];

/// The guagua's roof pictures (calle-base.js BOARDS): the park, the colmado's basket, a house.
const List<String> GUAGUA_BOARDS = ['arbol', 'toldo', 'casa'];

/// One baked vehicle: its picture, each pixel's depth less the depth of its floor's middle, the column and row of its
/// floor's middle on the picture ([ax], [ay]: the projection of the bake's point, rounded), and the pixels of an opened
/// window (`ventana`; null otherwise).
class VehicleSprite {
  VehicleSprite(this.key, this.s, this.z, this.ax, this.ay, [this.window]);

  /// `kind.heading[.board][.look]`.
  final String key;
  final Sprite s;
  final Float32List z;
  final int ax, ay;
  final Uint8List? window;
}

/// The key of a look.
String vehicleKey(
  String kind,
  String heading, {
  String? board,
  String look = '',
}) =>
    '$kind.$heading${board == null ? '' : '.$board'}${look.isEmpty ? '' : '.$look'}';

PpEngine _bakeEngine() => PpEngine(
  w: 240,
  h: 216,
  s: 26,
  originX: 0,
  originY: 0,
  shadowX: .9,
  shadowY: -.1,
);

final Map<String, VehicleSprite> _baked = {};

/// The vehicle [kind] ('carro', 'azul', 'guagua') heading [heading] ('i', 'd'), a guagua with its roof picture [board]
/// (or none), in [look] ('' as calle-base.js draws it; `puerta` a door open; `ventana` a car's window down), baked once.
VehicleSprite vehicleSprite(
  String kind,
  String heading, {
  String? board,
  String look = '',
}) {
  final key = vehicleKey(kind, heading, board: board, look: look);
  return _baked[key] ??= _bake(kind, heading, board, look, key);
}

VehicleSprite _bake(
  String kind,
  String heading,
  String? board,
  String look,
  String key,
) {
  final e = _bakeEngine(), k = SetKit(e, PpBuild(e)), cl = CalleBase(k);
  final W = e.W, H = e.H;
  for (var iy = 0; iy < H; iy++) {
    for (var ix = 0; ix < W; ix++) {
      final g = e.unproject(ix + .5, iy + .5), i = iy * W + ix;
      e.pix[i] = e.rgb(128, 128, 128);
      e.ground[i] = 1;
      e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
    }
  }
  e.groundZ.setAll(0, e.zb);
  cl.vehicle(kind, BAKE_X, BAKE_Y, heading, board);
  Uint8List? mask;
  if (look.isNotEmpty) mask = _paintLook(cl, kind, heading, look);
  e.shadeEdges();
  var x0 = W, y0 = H, x1 = -1, y1 = -1;
  for (var i = 0; i < W * H; i++) {
    if (e.zb[i] == e.groundZ[i]) continue;
    final x = i % W, y = i ~/ W;
    if (x < x0) x0 = x;
    if (x > x1) x1 = x;
    if (y < y0) y0 = y;
    if (y > y1) y1 = y;
  }
  final w = x1 - x0 + 1, h = y1 - y0 + 1;
  final px = Uint32List(w * h), z = Float32List(w * h);
  final win = mask == null ? null : Uint8List(w * h);
  final d0 = e.project(BAKE_X, BAKE_Y, 0).d;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y0 + y) * W + x0 + x, j = y * w + x;
      if (e.zb[i] == e.groundZ[i]) continue;
      px[j] = e.pix[i];
      z[j] = e.zb[i] - d0;
      if (win != null) win[j] = mask![i];
    }
  }
  final p = e.project(BAKE_X, BAKE_Y, 0);
  return VehicleSprite(
    key,
    Sprite(w, h, px),
    z,
    (p.sx + .5).floor() - x0,
    (p.sy + .5).floor() - y0,
    win,
  );
}

// the new looks, drawn on the engine over the baked vehicle (a face a hair in front of the one it opens). Returns the
// pixels the look drew (a car's window: where a face is drawn)
Uint8List _paintLook(CalleBase cl, String kind, String heading, String look) {
  final e = cl.e, before = Float32List.fromList(e.zb);
  final bus = kind == 'guagua', L = bus ? 4.4 : 2.2, Wd = bus ? 1.3 : 1.1;
  final x0 = BAKE_X - L / 2, x1 = BAKE_X + L / 2, y1 = BAKE_Y + Wd / 2;
  final front = heading == 'd';
  if (bus && look == 'puerta') {
    // the front door open: its two leaves folded back to the jambs, the dark inside, two steps up
    const H1 = 2.15;
    cl.faceY(y1 + .004, x0, x1, .3, H1 - .2, (a, z) {
      final dn = front ? (x1 - a) : a - x0, d = dn - .35;
      if (!(d > 0 && d < .8)) return 0;
      if (d < .07 || d > .73) return e.rgb(86, 96, 110); // a folded leaf
      if (z < .42) return e.rgb(150, 146, 140); // the lower step
      if (z < .56) return e.rgb(120, 116, 112); // the upper step
      return e.rgb(48, 46, 56); // the inside
    }, CalleBase.PP);
  } else if (!bus) {
    const H1 = .78, H2 = 1.22;
    final C0 = x0 + (front ? .45 : .6), C1 = x1 - (front ? .6 : .45);
    final mid = (C0 + C1) / 2;
    if (look == 'ventana') {
      // the front side window down: the cabin's inside where its glass was
      cl.faceY(y1 - .06 + .004, C0, C1, H1, H2, (a, z) {
        final inFront = front ? a > mid + .04 : a < mid - .04;
        if (!inFront || a <= C0 + .1 || a >= C1 - .1 || z >= H2 - .08) {
          return 0;
        }
        return e.rgb(70, 58, 54);
      }, CalleBase.PP);
    } else if (look == 'puerta') {
      // the front door open: a dark gap in the body's side under the front window
      cl.faceY(y1 + .004, x0, x1, .26, H1 - .04, (a, z) {
        final inFront = front ? a > mid + .04 : a < mid - .04;
        if (!inFront || a <= C0 + .06 || a >= C1 - .06) return 0;
        return e.rgb(52, 44, 44);
      }, CalleBase.PP);
    }
  }
  final m = Uint8List(e.W * e.H);
  for (var i = 0; i < m.length; i++) {
    if (e.zb[i] != before[i]) m[i] = 1;
  }
  return m;
}

final Expando<Map<String, VehicleSprite>> _lit = Expando();

/// [v] under a set's light (set-kit.js lightPass: each colour times [m] plus [a]); the same sprite with no light.
VehicleSprite litVehicle(VehicleSprite v, List<double>? m, List<double>? a) {
  if (m == null || a == null) return v;
  final cache = _lit[v] ??= {};
  return cache['$m$a'] ??= () {
    final px = Uint32List(v.s.px.length);
    for (var i = 0; i < px.length; i++) {
      final c = v.s.px[i];
      if (c >>> 24 == 0) continue;
      px[i] = _rgbE.rgb(
        (c & 255) * m[0] + a[0],
        (c >> 8 & 255) * m[1] + a[1],
        (c >> 16 & 255) * m[2] + a[2],
      );
    }
    return VehicleSprite(
      v.key,
      Sprite(v.s.w, v.s.h, px),
      v.z,
      v.ax,
      v.ay,
      v.window,
    );
  }();
}

// an engine for its rgb (pp-engine.js rgb, as lightPass calls it)
final PpEngine _rgbE = _bakeEngine();

/// A car [kind] heading [heading] with its front window down and [face] in it: the face's middle column [faceAx] on the
/// window's middle, its row [faceBottom] on the window's bottom row, drawn only on the window's pixels.
VehicleSprite vehicleWithFace(
  String kind,
  String heading,
  String who,
  Sprite face,
  int faceAx,
  int faceBottom,
) {
  final key = '${vehicleKey(kind, heading, look: 'ventana')}.$who';
  return _baked[key] ??= () {
    final v = vehicleSprite(kind, heading, look: 'ventana');
    final win = v.window!, w = v.s.w;
    var x0 = w, x1 = -1, y1 = -1;
    for (var i = 0; i < win.length; i++) {
      if (win[i] == 0) continue;
      final x = i % w, y = i ~/ w;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y > y1) y1 = y;
    }
    final px = Uint32List.fromList(v.s.px);
    if (x1 >= 0) {
      final cx = (x0 + x1) ~/ 2, ox = cx - faceAx, oy = y1 + 1 - faceBottom;
      for (var y = 0; y < face.h; y++) {
        for (var x = 0; x < face.w; x++) {
          final c = face.px[y * face.w + x];
          if (c >>> 24 == 0) continue;
          final X = ox + x, Y = oy + y;
          if (X < 0 || Y < 0 || X >= w || Y >= v.s.h) continue;
          if (win[Y * w + X] == 0) continue;
          px[Y * w + X] = c;
        }
      }
    }
    return VehicleSprite(key, Sprite(w, v.s.h, px), v.z, v.ax, v.ay, win);
  }();
}

/// The shadows vehicle() casts (calle-base.js: a guagua `for (a = x0; a <= x1; a += .5) castShadow(a, y, 1.2, .8)`, a car
/// `for (a = x0 + .3; a <= x1; a += .5) castShadow(a, y, .5, .65)`), at the place (x, y) of its floor's middle.
List<ShadowCast> vehicleShadows(String kind, num x, num y) {
  final bus = kind == 'guagua', L = bus ? 4.4 : 2.2;
  final x0 = x - L / 2, x1 = x + L / 2;
  return [
    if (bus)
      for (num a = x0; a <= x1; a += .5)
        (x: a.toDouble(), y: y.toDouble(), z: 1.2, r: .8)
    else
      for (num a = x0 + .3; a <= x1; a += .5)
        (x: a.toDouble(), y: y.toDouble(), z: .5, r: .65),
  ];
}

/// Where [v] stands on the picture of [e] with its floor's middle at the world point (x, y, 0): its top left and the
/// depth of that point (each pixel's depth is this plus its own, [VehicleSprite.z]).
({int left, int top, double d, int sx, int sy}) placeVehicle(
  PpEngine e,
  VehicleSprite v,
  num x,
  num y,
) {
  final p = e.project(x, y, 0);
  final sx = (p.sx + .5).floor(), sy = (p.sy + .5).floor();
  return (left: sx - v.ax, top: sy - v.ay, d: p.d, sx: sx, sy: sy);
}

/// Composes [v] at ([left], [top]) with base depth [d] into a 240-wide sprite layer ([layer], its depths [lz]): a pixel
/// is hidden where the set's depth [setZ] is nearer than its own, or where the layer already holds a nearer pixel. The
/// layer's [isVehicle] marks what a vehicle drew (a person's pixel is tested against it with front.bias: [personOver]).
void putVehicle(
  VehicleSprite v,
  int left,
  int top,
  double d,
  Uint32List layer,
  Float32List lz,
  Uint8List isVehicle,
  Float32List? setZ, {
  int W0 = 240,
  int H0 = 216,
}) {
  final s = v.s;
  for (var y = 0; y < s.h; y++) {
    final Y = top + y;
    if (Y < 0 || Y >= H0) continue;
    for (var x = 0; x < s.w; x++) {
      final c = s.px[y * s.w + x];
      if (c >>> 24 == 0) continue;
      final X = left + x;
      if (X < 0 || X >= W0) continue;
      final i = Y * W0 + X, z = d + v.z[y * s.w + x];
      if (setZ != null && setZ[i] > z) continue;
      if (lz[i] > z) continue;
      lz[i] = z;
      layer[i] = c;
      isVehicle[i] = 1;
    }
  }
}

/// Whether a person's pixel on a plane of depth [plane] may be drawn over the layer's pixel [i]: not where a vehicle's
/// pixel is nearer than the plane plus [bias] (the sheets' front rule, the vehicle as if baked into the set), not where
/// another sprite's pixel is nearer than the plane.
bool personOver(
  int i,
  double plane,
  double bias,
  Float32List lz,
  Uint8List isVehicle,
) {
  if (isVehicle[i] == 1) return !(lz[i] > plane + bias);
  return !(lz[i] > plane);
}

/// Moves vehicle [v] (a map with a world `x`) to [toX] along its lane, [step] world units a tick at most, slowing over
/// the last [ease] units when it is to stop there, calling [tick] (the host's wait of one tick) between steps.
Future<void> drive(
  Map<String, dynamic> v,
  num toX,
  Future<void> Function() tick, {
  double step = .34,
  double ease = 1.6,
  bool stop = true,
}) async {
  var x = (v['x'] as num).toDouble();
  final to = toX.toDouble(), dir = to > x ? 1 : -1;
  while ((to - x).abs() > 1e-9) {
    final left = (to - x).abs();
    var s = step;
    if (stop && left < ease) s = step * (.25 + .75 * left / ease);
    x = left <= s ? to : x + dir * s;
    v['x'] = x;
    await tick();
  }
  v['x'] = to;
}

/// Every look the four scenes share, in the order of the sprite sheet picture (calle-sprites.png): each kind in both
/// headings, the guagua with each roof picture, and the new looks.
List<VehicleSprite> calleVehicleSheet() => [
  for (final k in VEHICLE_KINDS)
    for (final h in VEHICLE_HEADINGS) vehicleSprite(k, h),
  for (final b in GUAGUA_BOARDS)
    for (final h in VEHICLE_HEADINGS) vehicleSprite('guagua', h, board: b),
  for (final h in VEHICLE_HEADINGS) vehicleSprite('guagua', h, look: 'puerta'),
  for (final k in const ['carro', 'azul'])
    for (final h in VEHICLE_HEADINGS) ...[
      vehicleSprite(k, h, look: 'ventana'),
      vehicleSprite(k, h, look: 'puerta'),
    ],
];
