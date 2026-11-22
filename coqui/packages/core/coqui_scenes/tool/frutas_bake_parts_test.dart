// What each part of Las frutas' bake costs (frutas-set.html's buildSet, step by step, on the vm): the ground pass, the
// building (wall, door, sign, awning, window, pot), the stand (its body, bins, produce, scale, guineos, low crate,
// post), the extras (the cart when it is there), the shadows and the occlusion, the sky. Four states (the two
// assortments, with and without the cart), five runs each; the median. The awning's and the stand's shade, which
// colmado-fuera.js build() casts after the extras, are only queued there: their cost is in "shadows+occlusion+edges".
//
//   flutter test tool/frutas_bake_parts_test.dart
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_fuera.dart';
import 'package:coqui_scenes/src/frutas/frutas_set.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Las frutas: the bake by parts', () {
    final out = <String, List<double>>{};
    void time(String k, void Function() f) {
      final sw = Stopwatch()..start();
      f();
      (out[k] ??= []).add(sw.elapsedMicroseconds / 1000);
    }

    for (var run = 0; run < 5; run++) {
      for (final st in const [
        FrutasState(),
        FrutasState(surtido: 'frutas'),
        FrutasState(carro: true),
        FrutasState(
          hora: 'tarde',
          puerta: 'shut',
          carro: true,
          surtido: 'frutas',
        ),
      ]) {
        final e = frutasEngine(),
            k = SetKit(e, PpBuild(e)),
            cf = ColmadoFuera(k);
        final o = st.opt, hz = cf.skyPlan(o).HZ, pre = st.key;
        time('$pre ground', () {
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
        cf.BINS = ColmadoFuera.SURTIDOS[o.surtido]!;
        cf.BW = (ColmadoFuera.TX1 - ColmadoFuera.TX0) / cf.BINS.length;
        time('$pre building', () => cf.building(o));
        time('$pre stand', () => cf.stand(o));
        time('$pre extras', () => cf.extras(o));
        time('$pre shadows+occlusion+edges', () {
          e.flushShadows();
          e.pendingShadows.clear();
          e.bakeOcclusion();
          k.joinSlabs();
          e.staticShadow.setAll(0, e.shadowMask);
          e.applyShadows(e.groundZ);
          e.shadeEdges();
        });
        time('$pre sky', () => k.skyFill(cf.sky(o, hz)));
        // the whole bake, as the scene does it, on a fresh engine
        final e2 = frutasEngine();
        time(
          '$pre whole (FrutasSet.buildSet)',
          () => FrutasSet(e2, PpBuild(e2)).buildSet(st),
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
