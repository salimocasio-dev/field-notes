// Port of docs/proyecto/pixel/casa-base.js: La casa's shared kit (`CS`), call for call: what the four scene sets of
// place 9 share (cuarto, bano, sala_dia, noche). Built on top of La fonda's helpers (lib/src/fonda/fonda_base.dart:
// FD.inside, FD.onFrame), La plaza's painters (lib/src/plaza/plaza_base.dart: PZ.box, PZ.wall, PZ.flat, PZ.post,
// PZ.shadow, PZ.xy), SetKit, PpEngine, and PpBuild. Indoor sets, as La fonda's: a floor (v >= 0) and a back wall that
// faces the camera at v = 0, painted pixel by pixel. No side walls, no ceiling. A bed stands with its head to the back
// wall and runs towards the camera, so that whoever lies in it is seen whole, head at the top; a sofa and an armchair
// face the camera. Everything that moves or changes is a sprite.
//
// First writer: #272 (La casa, before orders 70-73). The file's names are kept, capitals included, so the port reads
// line for line against casa-base.js (page 12, section 6).
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:math' as math;

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/fonda/fonda_base.dart';
import 'package:coqui_scenes/src/plaza/plaza_base.dart';
import 'package:coqui_scenes/src/set_kit.dart';

/// Port of casa-base.js (`CS`).
class CasaBase {
  CasaBase(this.FD) : PZ = FD.PZ, k = FD.k, e = FD.e, b = FD.b;

  final FondaBase FD;
  final PlazaBase PZ;
  final SetKit k;
  final PpEngine e;
  final PpBuild b;

  int _rgb(List<num> c) => e.rgb(c[0], c[1], c[2]);

  // casa-base.js: boards
  /// A wooden floor: boards that run across the picture.
  int boards(
    num u,
    num v,
    int ix,
    int iy, [
    List<num> c = const [202, 160, 112],
  ]) {
    final kk = ((v + 60) / .46).floor(), a = jsMod(v + 60, .46) / .46;
    if (a < .1) return e.rgb(c[0] - 62, c[1] - 58, c[2] - 50);
    final n = e.hash(kk * 5, 3) * 12,
        j = jsMod(u + kk * 1.37 + 60, 3.1) < .05 ? 22 : 0;
    return e.rgb(c[0] - n - j, c[1] - n - j, c[2] - n - j);
  }

  // casa-base.js: paint
  /// The wall's paint: a skirting board, a plain colour, a pale line near the top.
  int paint(num u, num z, [List<num> c = const [232, 222, 196]]) {
    if (z < .14) return e.rgb(250, 246, 236);
    if (z > 2.62 && z < 2.68) return e.rgb(c[0] - 26, c[1] - 26, c[2] - 26);
    return b.shade(c, 2.5, u * 1.5, z * 1.5, .18);
  }

  // casa-base.js: tiles
  /// White tiles with a coloured band (a bathroom's wall).
  int tiles(num u, num z, [List<num> band = const [96, 176, 190]]) {
    if (jsMod(u + 60, .34) < .03 || jsMod(z, .3) < .035) {
      return e.rgb(196, 210, 216);
    }
    if (z > 1.2 && z < 1.5) return _rgb(band);
    return e.rgb(244, 248, 248);
  }

  // casa-base.js: sky
  /// What a window shows by the hour: `'alba'` | `'manana'` | `'tarde'` | `'noche'`.
  /// `(a, bb)` run 0 to 1 across and up the pane.
  int sky(String hora, num a, num bb, int ix, int iy) {
    if (hora == 'alba') {
      return bb < .35
          ? e.rgb(250, 190, 150)
          : bb < .55
          ? e.rgb(226, 170, 176)
          : e.rgb(150, 150, 200);
    }
    if (hora == 'manana') {
      if (jsHypot((a - .72) * 30, (bb - .68) * 22) < 5) {
        return e.rgb(255, 240, 150);
      }
      return e.rgb(150 + (1 - bb) * 60, 206 + (1 - bb) * 30, 250);
    }
    if (hora == 'tarde') {
      if (jsHypot((a - .3) * 30, (bb - .45) * 22) < 5.5) {
        return e.rgb(255, 214, 120);
      }
      return e.rgb(250 - bb * 40, 196 - bb * 20, 130 + bb * 60);
    }
    if (jsHypot((a - .66) * 30, (bb - .64) * 22) < 5) {
      return e.rgb(250, 250, 236);
    }
    return e.hash(ix * 7, iy * 13) < .04
        ? e.rgb(240, 240, 255)
        : e.rgb(24, 30, 76);
  }

  // casa-base.js: windowAt
  /// A window in the wall paint: returns a colour for `(u, z)` inside `r = [u0, u1, z0, z1]` or its frame, else 0.
  int windowAt(num u, num z, List<num> r, String hora) {
    if (FD.onFrame(u, z, r, .08)) return e.rgb(250, 246, 236);
    if (!FD.inside(u, z, r)) return 0;
    final a = (u - r[0]) / (r[1] - r[0]), bb = (z - r[2]) / (r[3] - r[2]);
    if ((a - .5).abs() < .025 || (bb - .5).abs() < .035) {
      return e.rgb(250, 246, 236);
    }
    return sky(hora, a, bb, jsRoundN(u * 26), jsRoundN(z * 22.5));
  }

  // casa-base.js: clockAt
  /// A round wall clock with no hands (the hands are sprites): colour for `(u, z)` or 0.
  int clockAt(num u, num z, num cu, num cz) {
    final d = jsHypot((u - cu) * 26, (z - cz) * 22.5);
    if (d > 7.5) return 0;
    if (d > 6) return e.rgb(120, 84, 56);
    for (var kk = 0; kk < 12; kk++) {
      final an = kk * math.pi / 6;
      if (jsHypot(
            (u - cu) * 26 - math.sin(an) * 4.6,
            (z - cz) * 22.5 - math.cos(an) * 4.6,
          ) <
          .7) {
        return e.rgb(70, 60, 60);
      }
    }
    return e.rgb(252, 250, 240);
  }

  // casa-base.js: doorAt
  /// A door in the wall paint: a leaf with two panels and a knob; [open] = a dark opening with a pale floor strip.
  int doorAt(
    num u,
    num z,
    List<num> r,
    bool open, [
    List<num> c = const [176, 122, 76],
  ]) {
    if (FD.onFrame(u, z, r, .08)) return e.rgb(250, 246, 236);
    if (!FD.inside(u, z, r)) return 0;
    if (open) return z < .5 ? e.rgb(150, 124, 100) : e.rgb(84, 70, 70);
    final a = (u - r[0]) / (r[1] - r[0]), bb = (z - r[2]) / (r[3] - r[2]);
    if (jsHypot(
          (a - .84) * (r[1] - r[0]) * 26,
          (bb - .48) * (r[3] - r[2]) * 22.5,
        ) <
        1.5) {
      return e.rgb(240, 206, 110);
    }
    if (a > .14 &&
        a < .86 &&
        ((bb > .08 && bb < .44) || (bb > .54 && bb < .92))) {
      return e.rgb(c[0] + 16, c[1] + 16, c[2] + 16);
    }
    return _rgb(c);
  }

  // casa-base.js: bed
  /// A bed: its head to the wall at [v0], its foot at [v1]; whoever lies in it has his head on the pillow, at the top.
  void bed(
    num u,
    num v0,
    num v1,
    num hw, [
    List<num> c = const [110, 150, 220],
  ]) {
    final mid = (v0 + v1) / 2, hd = (v1 - v0) / 2;
    const W1 = [176, 122, 76], SH = [250, 248, 240];
    PZ.wall(
      u - hw,
      u + hw,
      v0 + .02,
      0,
      1.15,
      (a, bb) => ((a - u).abs() > hw - .08 || bb > 1.05)
          ? e.rgb(W1[0] - 30, W1[1] - 30, W1[2] - 30)
          : b.shade(W1, 2.5, a * 3, bb * 3, .2),
    );
    PZ.box(u, mid + .06, 0, .34, hw, hd - .06, W1);
    PZ.box(
      u,
      mid + .06,
      .34,
      .5,
      hw - .04,
      hd - .08,
      SH,
      (s, t, z, face) => face == 'top'
          ? (t > -hd + .75 ? _rgb(c) : _rgb(SH))
          : (face == 'front' ? e.rgb(c[0] - 30, c[1] - 30, c[2] - 30) : 0),
    );
    PZ.box(u, v0 + .42, .5, .6, hw - .2, .22, const [255, 255, 250]);
    for (double dv = -hd.toDouble(); dv <= hd; dv += .3) {
      PZ.shadow(u, mid + dv, .3, hw);
    }
  }

  // casa-base.js: armchair
  /// An armchair that faces the camera (its seat's top is z .44).
  void armchair(num u, num v, [List<num> c = const [176, 96, 80]]) {
    final D = <num>[c[0] - 34, c[1] - 34, c[2] - 34];
    PZ.box(
      u,
      v - .3,
      0,
      1.15,
      .46,
      .1,
      c,
      (s, t, z, face) =>
          face == 'front' ? b.shade(c, 2.3, s * 3, z * 2, .2) : 0,
    );
    PZ.box(
      u,
      v,
      0,
      .44,
      .46,
      .3,
      c,
      (s, t, z, face) =>
          face == 'top' ? e.rgb(c[0] + 22, c[1] + 22, c[2] + 22) : 0,
    );
    for (final s in const [-1, 1]) {
      PZ.box(u + s * .5, v - .02, 0, .7, .09, .32, D);
    }
    PZ.shadow(u, v, .4, .6);
  }

  // casa-base.js: sofa
  /// A sofa that faces the camera.
  void sofa(num u, num v, num hw, [List<num> c = const [96, 150, 140]]) {
    final D = <num>[c[0] - 34, c[1] - 34, c[2] - 34];
    PZ.box(
      u,
      v - .32,
      0,
      1.1,
      hw,
      .1,
      c,
      (s, t, z, face) =>
          face == 'front' ? b.shade(c, 2.3, s * 2, z * 2, .2) : 0,
    );
    PZ.box(
      u,
      v,
      0,
      .44,
      hw,
      .32,
      c,
      (s, t, z, face) => face == 'top'
          ? ((jsMod(s + hw, .98) - .02).abs() < .03
                ? _rgb(D)
                : e.rgb(c[0] + 22, c[1] + 22, c[2] + 22))
          : 0,
    );
    for (final s in const [-1, 1]) {
      PZ.box(u + s * (hw + .1), v - .02, 0, .72, .12, .34, D);
    }
    for (double du = -hw.toDouble(); du <= hw; du += .3) {
      PZ.shadow(u + du, v, .4, .5);
    }
  }

  // casa-base.js: rug
  /// A rug on the floor.
  void rug(
    num u0,
    num v0,
    num u1,
    num v1, [
    List<num> c = const [196, 76, 70],
    List<num> c2 = const [240, 206, 120],
  ]) {
    PZ.flat(
      u0,
      v0,
      u1,
      v1,
      .012,
      (u, v) => (u - u0 < .12 || u1 - u < .12 || v - v0 < .2 || v1 - v < .2)
          ? _rgb(c2)
          : b.shade(c, 3.2, u * 2, v, .1),
    );
  }

  // casa-base.js: glowBox
  /// Lamps: lit ones glow.
  void glowBox(
    num u,
    num v,
    num z0,
    num z1,
    num hw,
    bool lit, [
    List<num> c = const [250, 232, 170],
  ]) {
    final p = PZ.xy(u, v), x = p[0], y = p[1];
    for (double z = z0.toDouble(); z <= z1; z += .03) {
      final w = hw * (.55 + .45 * (z1 - z) / (z1 - z0));
      for (double a = -w; a <= w; a += .03) {
        final col = lit
            ? e.rgb(255, 236, 150)
            : e.rgb(c[0] - 70, c[1] - 70, c[2] - 70);
        if (lit) {
          k.plotGlow(x + a * .7, y - a * .7, z, col);
        } else {
          e.plot(x + a * .7, y - a * .7, z, col);
        }
      }
    }
  }

  // casa-base.js: lampStanding
  void lampStanding(num u, num v, bool lit) {
    PZ.box(u, v, 0, .06, .16, .16, const [90, 80, 80]);
    PZ.post(u, v, 0, 1.62, .035, const [90, 80, 80]);
    glowBox(u, v, 1.6, 2.05, .3, lit);
  }

  // casa-base.js: lampSmall
  void lampSmall(num u, num v, num z, bool lit) {
    PZ.box(u, v, z, z + .2, .07, .07, const [150, 96, 70]);
    glowBox(u, v, z + .2, z + .52, .2, lit);
  }

  // casa-base.js: lampWall
  void lampWall(num u, num z, bool lit) {
    PZ.box(u, .07, z - .1, z - .04, .04, .07, const [90, 80, 80]);
    glowBox(u, .13, z, z + .3, .16, lit);
  }
}
