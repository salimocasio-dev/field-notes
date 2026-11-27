// Port of docs/proyecto/pixel/fonda-base.js: La fonda's shared kit (`FD`), call for call: what the four scene sets of
// place 8 share (entrada, pedido, comida, cuenta). Built on top of La plaza's painters (lib/src/plaza/plaza_base.dart:
// PZ.box, PZ.wall, PZ.post, PZ.shadow, PZ.xy), SetKit, PpEngine, and PpBuild. Laid out square to the picture, in u, v:
// u across, v down towards the camera, z up. An indoor set is a floor (v >= 0) and a back wall that faces the camera
// at v = 0, painted pixel by pixel: doors, windows and a hatch are holes or pictures in it. Tables are long across the
// picture; whoever sits at one sits along its far side, facing us, or at one of its ends.
//
// First writer: #271 (La fonda, before orders 66-69). The file's names are kept, capitals included, so the port reads
// line for line against fonda-base.js (page 12, section 6).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// Port of fonda-base.js (`FD`).
class FondaBase {
  FondaBase(this.PZ) : k = PZ.k, e = PZ.e, b = PZ.b;

  final PlazaBase PZ;
  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  // fonda-base.js: CREAM, GREEN, GREEN_D, WOOD, WOOD_D, WOOD_L, CLOTH, BRASS, RED
  static const List<int> CREAM = [246, 232, 204],
      GREEN = [70, 132, 122],
      GREEN_D = [50, 104, 98],
      WOOD = [156, 106, 64],
      WOOD_D = [108, 72, 46],
      WOOD_L = [198, 150, 98],
      CLOTH = [250, 246, 236],
      BRASS = [222, 178, 82],
      RED = [196, 60, 54];

  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // fonda-base.js: tiles
  /// The floor of the room: clay tiles, every other one a shade darker, pale joints.
  int tiles(num u, num v, int ix, int iy) {
    final a = jsMod(u + 60.25, 1), bb = jsMod(v + 60, 1);
    if (a < .05 || bb < .09) return e.rgb(206, 178, 150);
    final cu = (u + 60.25).floor(),
        cv = (v + 60).floor(),
        n = e.hash(cu * 7, cv * 13) * 8;
    final c = ((cu + cv) & 1) != 0
        ? const [196, 112, 80]
        : const [212, 130, 92];
    return e.rgb(c[0] - n, c[1] - n, c[2] - n);
  }

  // fonda-base.js: planks
  /// The floor of the terrace: boards that run down the picture.
  int planks(num u, num v, int ix, int iy) {
    final a = jsMod(u + 60, .5) / .5, kk = ((u + 60) / .5).floor();
    if (a < .07) return e.rgb(104, 72, 50);
    final n = e.hash(kk * 5, 3) * 14,
        j = jsMod(v + kk * .37 + 60, 2.6) < .07 ? 18 : 0;
    return e.rgb(182 - n - j, 132 - n - j, 88 - n - j);
  }

  // fonda-base.js: paint
  /// The back wall's paint: boards to the height of a chair's back, a rail, plaster above. Returns a colour for (u, z).
  int paint(num u, num z, [List<num> low = GREEN, List<num> high = CREAM]) {
    if (z < .08) return _rgb(WOOD_D);
    if (z < .95) {
      return jsMod(u + 60, .34) < .035
          ? (identical(low, GREEN)
                ? _rgb(GREEN_D)
                : e.rgb(low[0] - 22, low[1] - 22, low[2] - 22))
          : b.shade(low, 2.2, u * 3, z * 2, .25);
    }
    if (z < 1.03) return _rgb(WOOD);
    return b.shade(high, 2.5, u * 1.5, z * 1.5, .22);
  }

  // fonda-base.js: inside
  bool inside(num u, num z, List<num> r) =>
      u >= r[0] && u <= r[1] && z >= r[2] && z <= r[3];

  // fonda-base.js: onFrame
  /// A frame round a hole or a picture in the wall: true on the frame's own pixels.
  bool onFrame(num u, num z, List<num> r, [num w = .07]) =>
      inside(u, z, [
        r[0] - w,
        r[1] + w,
        r[2] - (r[2] > .1 ? w : 0),
        r[3] + w,
      ]) &&
      !inside(u, z, r);

  // fonda-base.js: outside
  /// What is seen through a door or a window, by the hour: `'ocaso'` | `'noche'` | `'tarde_noche'`.
  /// `(a, bb)` run 0 to 1 across and up the opening.
  int outside(String hora, num a, num bb, int ix, int iy) {
    if (hora == 'ocaso') {
      if (bb < .28) return e.rgb(150, 118, 110);
      if (bb < .36) return e.rgb(96, 84, 96);
      final t = (bb - .36) / .64;
      return e.rgb(250 - t * 90, 170 - t * 40, 120 + t * 70);
    }
    final deep = hora == 'tarde_noche';
    if (bb < .28) return deep ? e.rgb(34, 36, 60) : e.rgb(52, 54, 84);
    if (bb < .34) return deep ? e.rgb(22, 24, 44) : e.rgb(36, 38, 64);
    if (e.hash(ix * 7, iy * 13) < (deep ? .05 : .025)) {
      return e.rgb(240, 240, 255);
    }
    return deep ? e.rgb(16, 20, 52) : e.rgb(34, 44, 96);
  }

  // fonda-base.js: sconce
  /// A wall lamp that glows (a small shade on a bracket), on the wall at v.
  void sconce(num u, num v, num z) {
    PZ.box(u, v + .06, z - .1, z - .04, .03, .06, WOOD_D);
    final p = PZ.xy(u, v + .12), x = p[0], y = p[1];
    for (double dz = 0; dz <= .22; dz += .03) {
      for (double a = -.1; a <= .1; a += .03) {
        k.plotGlow(x + a * .7, y - a * .7, z + dz, e.rgb(255, 232, 150));
      }
    }
  }

  // fonda-base.js: table
  /// A table, long across the picture: its cloth hangs half way down. [c]: the cloth's colour.
  void table(num u, num v, num hw, [num hd = .45, List<num> c = CLOTH]) {
    for (final p in [
      [-hw + .1, -hd + .1],
      [hw - .1, -hd + .1],
      [-hw + .1, hd - .1],
      [hw - .1, hd - .1],
    ]) {
      PZ.post(u + p[0], v + p[1], 0, .4, .045, WOOD_D);
    }
    PZ.box(
      u,
      v,
      .36,
      .74,
      hw,
      hd,
      c,
      (s, t, z, face) => face == 'top'
          ? _rgb(c)
          : z < .42
          ? e.rgb(c[0] - 44, c[1] - 44, c[2] - 44)
          : e.rgb(c[0] - 18, c[1] - 18, c[2] - 18),
    );
    for (double du = -hw.toDouble(); du <= hw; du += .3) {
      PZ.shadow(u + du, v, .5, .5);
    }
  }

  // fonda-base.js: chair
  /// A chair at a table's far side: its back is behind whoever sits on it.
  void chair(num u, num v) {
    PZ.box(u, v, .36, .44, .2, .2, WOOD_L);
    for (final du in const [-.17, .17]) {
      PZ.post(u + du, v - .18, 0, 1.08, .028, WOOD);
      PZ.post(u + du, v + .16, 0, .36, .028, WOOD);
    }
    for (final z in const [.66, .88]) {
      PZ.wall(
        u - .17,
        u + .17,
        v - .18,
        z,
        z + .13,
        (a, bb) => b.shade(WOOD_L, 2.5, a * 4, bb * 8, .3),
      );
    }
  }

  // fonda-base.js: chairEnd
  /// A chair at a table's end: [side] = -1 at the left end (its back at the left), 1 at the right end.
  void chairEnd(num u, num v, num side) {
    PZ.box(u, v, .36, .44, .2, .2, WOOD_L);
    PZ.box(u + side * .2, v, .44, 1.08, .025, .2, WOOD_L);
    for (final dv in const [-.17, .17]) {
      PZ.post(u - side * .16, v + dv, 0, .36, .028, WOOD);
    }
  }

  // fonda-base.js: setTable
  /// A set table with its chairs: [seats] = how many along the far side; [ends] = chairs at the ends too.
  /// Returns the seats' places `[[u, v], ...]`.
  List<List<double>> setTable(
    num u,
    num v,
    num hw, {
    num? hd,
    int? seats,
    num? span,
    bool ends = false,
    List<num>? cloth,
  }) {
    final hdVal = (hd == null || hd == 0) ? .45 : hd;
    final n = (seats == null || seats == 0) ? 2 : seats;
    final spanVal = (span == null || span == 0) ? (2 * hw - .9) : span;
    final out = <List<double>>[];
    for (var kk = 0; kk < n; kk++) {
      final cu = (u + (n == 1 ? 0 : (kk / (n - 1) - .5) * spanVal)).toDouble();
      final cv = (v - hdVal - .26).toDouble();
      chair(cu, cv);
      out.add([cu, cv]);
    }
    if (ends) {
      final lu = (u - hw - .4).toDouble();
      final ru = (u + hw + .4).toDouble();
      chairEnd(lu, v, -1);
      chairEnd(ru, v, 1);
      out.add([lu, v.toDouble()]);
      out.add([ru, v.toDouble()]);
    }
    table(u, v, hw, hdVal, cloth ?? CLOTH);
    return out;
  }
}
