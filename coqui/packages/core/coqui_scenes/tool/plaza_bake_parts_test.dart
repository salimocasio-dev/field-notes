// What each part of El banco de la plaza's bake costs (plaza-set.html's buildSet, step by step, on the vm): the ground
// pass, each part (fondo: the trees and the hedge behind the wall; muro; flores; arbol; farol; banco; tablero; carrito),
// the shadows and the occlusion, the light, the sky. Five runs of the state with the board and the cart (the most drawn)
// and of the morning's bare one; the median.
//
//   flutter test tool/plaza_bake_parts_test.dart
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/plaza/plaza_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('El banco de la plaza: the bake by parts', () {
    final out = <String, List<double>>{};
    void time(String k, void Function() f) {
      final sw = Stopwatch()..start();
      f();
      (out[k] ??= []).add(sw.elapsedMicroseconds / 1000);
    }

    for (var run = 0; run < 5; run++) {
      for (final st in const [
        PlazaState(),
        PlazaState(hora: 'tarde', tablero: true, carrito: true),
      ]) {
        final e = plazaEngine(), set = PlazaSet(e, PpBuild(e)), pz = set.PZ;
        final k = set.k, pre = st.key;
        time('$pre ground', () {
          for (var iy = 0; iy < e.H; iy++) {
            for (var ix = 0; ix < e.W; ix++) {
              final g = e.unproject(ix + .5, iy + .5),
                  i = iy * e.W + ix,
                  c = set.groundAt(g.x, g.y, ix, iy);
              if (c == 0) continue;
              e.pix[i] = c;
              e.ground[i] = 1;
              e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
            }
          }
          e.groundZ.setAll(0, e.zb);
        });
        time('$pre fondo', () {
          for (final t in const [
            [-3.9, 1.5, .95],
            [-1.9, 1.2, .8],
            [4.7, 1.4, .9],
          ]) {
            pz.tree(t[0], E.WALL - .9, t[1], t[2]);
          }
          pz.hedge(-5, E.BACK + .25, 5, E.BACK + .25);
        });
        time(
          '$pre muro',
          () => pz.box(0, E.WALL, 0, .55, 5.4, .13, const [214, 204, 186]),
        );
        time('$pre flores', () {
          pz.bed(-1.2, E.WALL + .35, -.1, E.WALL + 1.0);
          pz.bed(2.4, E.WALL + .35, 4.6, E.WALL + 1.0);
        });
        time(
          '$pre arbol',
          () => pz.tree(E.TREE[0], E.TREE[1], E.TREE[2], E.TREE[3]),
        );
        time('$pre farol', () => pz.lamp(-3.95, E.WALL + .7));
        time('$pre banco', () => pz.seat(E.SEAT.u, E.SEAT.v, E.SEAT.hw));
        if (st.tablero) time('$pre tablero', set.board);
        if (st.carrito) time('$pre carrito', set.cart);
        time('$pre shadows+occlusion+edges', () {
          e.flushShadows();
          e.bakeOcclusion();
          k.joinSlabs();
          e.staticShadow.setAll(0, e.shadowMask);
          e.applyShadows(e.groundZ);
          e.shadeEdges();
        });
        time('$pre light', () => pz.light(st.hora));
        time(
          '$pre sky',
          () =>
              k.skyFill(pz.sky(st.hora, [pz.farTower(E.TOWER[0], E.TOWER[1])])),
        );
      }
    }
    final lines = [
      for (final en in out.entries)
        () {
          final v = [...en.value]..sort();
          return '${en.key}: median ${v[2].toStringAsFixed(1)} ms (of 5: ${v.map((x) => x.toStringAsFixed(1)).join(', ')})';
        }(),
    ];
    // ignore: avoid_print
    print(lines.join('\n'));
  });
}
