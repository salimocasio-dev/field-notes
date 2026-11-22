// What each part of El mostrador's bake costs (mostrador-set.html's buildSet, step by step, on the vm): the floor pass,
// each part of the room (walls, shelves, counter, chair), the shadows and the occlusion, the light, the sky; or, in the
// street, the ground, the building, the stand, the extras, the occlusion and the sky. Five runs of each state; the median.
//
//   flutter test tool/mostrador_bake_parts_test.dart
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/colmado/colmado_fuera.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_set.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('El mostrador: the bake by parts', () {
    final out = <String, List<double>>{};
    void time(String k, void Function() f) {
      final sw = Stopwatch()..start();
      f();
      (out[k] ??= []).add(sw.elapsedMicroseconds / 1000);
    }

    for (var run = 0; run < 5; run++) {
      for (final st in const [
        MostradorState(),
        MostradorState(hora: 'tarde', atras: 'open', nevera: true),
      ]) {
        final e = mostradorEngine(),
            k = SetKit(e, PpBuild(e)),
            cd = ColmadoDentro(k);
        final o = CdOpt(hora: st.hora, atras: st.atras, nevera: st.nevera);
        final pre = 'dentro ${st.key}';
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
        time('$pre shelves', () => cd.shelves(o));
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
      }
      final e = mostradorCalleEngine(),
          k = SetKit(e, PpBuild(e)),
          cf = ColmadoFuera(k);
      const o = CfOpt(solX: 206);
      final hz = cf.skyPlan(o).HZ;
      time('calle ground', () {
        for (var iy = 0; iy < e.H; iy++) {
          for (var ix = 0; ix < e.W; ix++) {
            final g = e.unproject(ix + .5, iy + .5),
                i = iy * e.W + ix,
                c = cf.groundAt(g.x, g.y, ix, iy, i, hz);
            if (c == 0) continue;
            e.pix[i] = c;
            e.ground[i] = 1;
            e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
          }
        }
        e.groundZ.setAll(0, e.zb);
      });
      time('calle building', () => cf.building(o));
      time('calle stand', () => cf.stand(o));
      time('calle extras+shade', () => cf.extras(o));
      time('calle occlusion+edges', () {
        e.flushShadows();
        e.bakeOcclusion();
        e.applyShadows(e.groundZ);
        e.shadeEdges();
      });
      time('calle sky', () => k.skyFill(cf.sky(o, hz)));
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
