// What each part of Los estantes' bake costs (estantes-set.html's buildSet, step by step, on the vm), as El mostrador's
// tool/mostrador_bake_parts_test.dart: the floor pass, each part of the room (walls, shelves with the ladder, the rings
// and the table, counter, chair), the shadows and the occlusion, the light, the sky; and what recording the ladder's
// pixels (the part tags, front.after) adds to a whole bake. Five runs of each state; the median.
//
//   flutter test tool/estantes_bake_parts_test.dart
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/estantes/estantes_set.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Los estantes: the bake by parts', () {
    final out = <String, List<double>>{};
    void time(String k, void Function() f) {
      final sw = Stopwatch()..start();
      f();
      (out[k] ??= []).add(sw.elapsedMicroseconds / 1000);
    }

    for (var run = 0; run < 5; run++) {
      for (final st in const [
        EstantesState(anillos: true),
        EstantesState(mesa: true),
      ]) {
        final e = estantesEngine(),
            k = SetKit(e, PpBuild(e)),
            cd = ColmadoDentro(k);
        final o = st.opt;
        final pre = st.key;
        time('$pre floor', () {
          for (var iy = 0; iy < e.H; iy++) {
            for (var ix = 0; ix < e.W; ix++) {
              final g = e.unproject(ix + .5, iy + .5),
                  i = iy * e.W + ix,
                  c = cd.floorAt(g.x, g.y, ix, iy, i);
              if (c == 0) continue;
              e.pix[i] = c;
              e.ground[i] = 1;
              e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
            }
          }
          e.groundZ.setAll(0, e.zb);
        });
        time('$pre walls', () => cd.walls(o));
        time('$pre shelves, ladder, rings, table', () => cd.shelves(o));
        time('$pre counter', () => cd.counter(o));
        time('$pre chair', () => cd.chairs());
        time('$pre shadows+occlusion+edges', () {
          e.flushShadows();
          e.bakeOcclusion();
          k.joinSlabs();
          e.staticShadow.setAll(0, e.shadowMask);
          e.applyShadows(e.groundZ);
          e.shadeEdges();
        });
        time('$pre light', () => cd.light(o));
        time('$pre sky', () => k.skyFill((_, _) => e.rgb(46, 38, 40)));
        final e2 = estantesEngine(), set = EstantesSet(e2, PpBuild(e2));
        time('$pre whole bake, no tags', () => set.buildSet(st));
        set.tags = true;
        time('$pre whole bake, with the part tags', () => set.buildSet(st));
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
