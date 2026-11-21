// El colmado's two kits in Dart (lib/src/colmado/colmado_dentro.dart and colmado_fuera.dart) against the JavaScript
// (docs/proyecto/pixel/colmado-dentro.js and colmado-fuera.js): each piece drawn on its own from empty buffers, then whole
// sets built as the set pages build them, on engines with the origins of the place's sets, in the order
// tool/make_colmado_kit_ref.mjs ran them in headless Chrome. Each case's pix, zb, kinds, ground and shadowMask are the
// JavaScript's (equal hashes: 0 elements differ), and the numbers the pieces give back are the same.
//
// With COLMADO_KIT_DUMP=DIR (the tool's --dump DIR) a case that differs says which pixels (the vm only).
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_dentro.dart';
import 'package:coqui_scenes/src/colmado/colmado_fuera.dart';
import 'package:coqui_scenes/src/set_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/colmado_dump.dart';
import 'support/fixtures/colmado_kit_refs.dart';
import 'support/hash.dart';

const Map<String, List<double>> _origins = {
  'dentro': [-7, -32],
  'estantes': [-222, -95],
  'caja': [11, -30],
  'calle': [-46, -6],
  'frutas': [-68, -10],
};

Object? _plain(Object? v) => switch (v) {
  final List l => [for (final x in l) _plain(x)],
  final Map m => {for (final e in m.entries) '${e.key}': _plain(e.value)},
  final CfDisc d => {'x': d.x, 'y': d.y, 'z': d.z, 'r': d.r},
  final CfSkyPlan p => {'HZ': p.HZ, 'sun': p.sun},
  final double d when d == d.truncateToDouble() && d.abs() < 1e15 => d.toInt(),
  _ => v,
};

String? _where(String engine, String name, Uint32List pix, Float32List zb) {
  final p = colmadoDump('$engine.$name.pix.bin'),
      z = colmadoDump('$engine.$name.zb.bin');
  if (p == null || z == null) return null;
  final ref = Uint32List.view(p.buffer), refZ = Float32List.view(z.buffer);
  final out = <String>[];
  var n = 0;
  for (var i = 0; i < pix.length; i++) {
    if (pix[i] != ref[i] || zb[i] != refZ[i]) {
      n++;
      if (out.length < 12) {
        out.add(
          '(${i % 240},${i ~/ 240}) dart ${pix[i].toRadixString(16)}/${zb[i]} js ${ref[i].toRadixString(16)}/${refZ[i]}',
        );
      }
    }
  }
  return '$n differ: ${out.join('; ')}';
}

void main() {
  final refs = (jsonDecode(colmadoKitRefs) as List)
      .cast<Map<String, dynamic>>();

  for (final en in _origins.entries) {
    final e = PpEngine(
      w: 240,
      h: 216,
      s: 26,
      originX: en.value[0],
      originY: en.value[1],
      shadowX: .9,
      shadowY: -.1,
    );
    final k = SetKit(e, PpBuild(e)),
        cd = ColmadoDentro(k),
        cf = ColmadoFuera(k);

    void reset() {
      e.zb.fillRange(0, e.zb.length, -1e9);
      e.pix.fillRange(0, e.pix.length, 0);
      e.kinds.fillRange(0, e.kinds.length, 0);
      e.ground.fillRange(0, e.ground.length, 0);
      e.shadowMask.fillRange(0, e.shadowMask.length, 0);
      e.staticShadow.fillRange(0, e.staticShadow.length, 0);
      e.groundZ.fillRange(0, e.groundZ.length, -1e9);
      e.tufts.clear();
      e.leaves.clear();
      e.pendingShadows.clear();
      k.slabTops.clear();
    }

    void floor() {
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
    }

    // mostrador-set.html's buildSet, inside and in the street
    void inside(CdOpt o) {
      floor();
      cd.build(o);
      e.flushShadows();
      e.pendingShadows.clear();
      e.bakeOcclusion();
      k.joinSlabs();
      e.staticShadow.setAll(0, e.shadowMask);
      e.applyShadows(e.groundZ);
      e.shadeEdges();
      cd.light(o);
      k.skyFill((_, _) => e.rgb(46, 38, 40));
    }

    int street(CfOpt o) {
      final HZ = cf.skyPlan(o).HZ;
      for (var iy = 0; iy < e.H; iy++) {
        for (var ix = 0; ix < e.W; ix++) {
          final g = e.unproject(ix + .5, iy + .5),
              i = iy * e.W + ix,
              c = cf.groundAt(g.x, g.y, ix, iy, i, HZ);
          if (c == 0) continue;
          e.pix[i] = c;
          e.ground[i] = 1;
          e.zb[i] = (g.x + g.y) / e.R2 * e.COS;
        }
      }
      e.groundZ.setAll(0, e.zb);
      cf.build(o);
      e.flushShadows();
      e.pendingShadows.clear();
      e.bakeOcclusion();
      k.joinSlabs();
      e.staticShadow.setAll(0, e.shadowMask);
      e.applyShadows(e.groundZ);
      e.shadeEdges();
      k.skyFill(cf.sky(o, HZ));
      return HZ;
    }

    void surtido(String s) {
      cf.BINS = ColmadoFuera.SURTIDOS[s] ?? ColmadoFuera.SURTIDOS['verduras']!;
      cf.BW = (ColmadoFuera.TX1 - ColmadoFuera.TX0) / cf.BINS.length;
    }

    const spots = {
      'leche': [1.95, .19, 1.36],
      'pan': [2.75, .19, 1.36],
      'mantequilla': [3.55, .19, 1.36],
      'queso': [4.35, .19, 1.36],
      'cafe': [5.1, .19, 1.36],
      'arroz': [2.2, .19, 2.01],
      'azucar': [3.1, .19, 2.01],
      'jugo': [4.0, .19, 2.01],
      'habichuelas': [4.9, .19, 2.01],
    };

    final cases = <String, dynamic Function()>{
      if (en.key == 'dentro') ...{
        'floorAt': () => floor(),
        'walls': () => cd.walls(const CdOpt()),
        'walls.tarde.open': () =>
            cd.walls(const CdOpt(hora: 'tarde', atras: 'open')),
        'walls.novitrina.reloj': () =>
            cd.walls(const CdOpt(vitrina: false, reloj: true)),
        'storeRoom': () => cd.storeRoom(),
        'counter': () => cd.counter(const CdOpt()),
        'counter.nevera': () => cd.counter(const CdOpt(nevera: true)),
        'counter.nocaja': () =>
            cd.counter(const CdOpt(caja: false, nevera: true)),
        'shelves': () => cd.shelves(const CdOpt()),
        'shelves.all': () => cd.shelves(
          const CdOpt(props: true, anillos: true, escalera: true, mesa: true),
        ),
        'standIn': () {
          for (final s in spots.entries) {
            cd.standIn(s.key, s.value[0], s.value[1], s.value[2]);
          }
          cd.standIn('nada', 3, 1, 1);
        },
        'chairs': () => cd.chairs(),
        'stampY': () => cd.stampY(
          2,
          3,
          1.5,
          const ['#.#', '.#.', '#.#', '##'],
          {'#': e.rgb(200, 20, 20)},
        ),
        'pixelsX': () => cd.pixelsX(
          .08,
          3,
          3.8,
          1.5,
          2.4,
          (bb, z) => ((bb * 10).floor() + (z * 10).floor()) % 2 != 0
              ? e.rgb(10, 200, 10)
              : 0,
        ),
        'light': () {
          floor();
          cd.walls(const CdOpt());
          cd.light(const CdOpt());
        },
        'light.tarde': () {
          floor();
          cd.walls(const CdOpt(hora: 'tarde'));
          cd.light(const CdOpt(hora: 'tarde'));
        },
        'build': () => inside(const CdOpt()),
        'build.tarde.open.nevera': () =>
            inside(const CdOpt(hora: 'tarde', atras: 'open', nevera: true)),
        'build.props': () => inside(const CdOpt(props: true)),
      },
      if (en.key == 'estantes') ...{
        'build': () =>
            inside(const CdOpt(escalera: true, anillos: true, mesa: true)),
        'shelves.all': () => cd.shelves(
          const CdOpt(props: true, anillos: true, escalera: true, mesa: true),
        ),
      },
      if (en.key == 'caja') ...{
        'build': () => inside(const CdOpt()),
        'build.tarde': () => inside(const CdOpt(hora: 'tarde', reloj: true)),
      },
      if (en.key == 'calle') ...{
        'groundAt': () {
          const o = CfOpt(solX: 206);
          final HZ = cf.skyPlan(o).HZ;
          for (var iy = 0; iy < e.H; iy++) {
            for (var ix = 0; ix < e.W; ix++) {
              final g = e.unproject(ix + .5, iy + .5),
                  i = iy * e.W + ix,
                  c = cf.groundAt(g.x, g.y, ix, iy, i, HZ);
              if (c != 0) e.pix[i] = c;
            }
          }
          return HZ;
        },
        'building': () => cf.building(const CfOpt()),
        'building.open': () => cf.building(const CfOpt(puerta: 'open')),
        'stand.verduras': () {
          surtido('verduras');
          cf.stand(const CfOpt());
        },
        'stand.frutas': () {
          surtido('frutas');
          cf.stand(const CfOpt(aguja: 'medio'));
        },
        'scale.libra': () => cf.scale(const CfOpt(aguja: 'libra')),
        'scale.0': () => cf.scale(const CfOpt(aguja: '0')),
        'cart': () => cf.cart(),
        'extras': () => cf.extras(const CfOpt(carro: true)),
        'sky': () => k.skyFill(
          cf.sky(const CfOpt(solX: 206), cf.skyPlan(const CfOpt(solX: 206)).HZ),
        ),
        'sky.tarde': () => k.skyFill(
          cf.sky(
            const CfOpt(hora: 'tarde'),
            cf.skyPlan(const CfOpt(hora: 'tarde')).HZ,
          ),
        ),
        'build': () => street(const CfOpt(solX: 206)),
        'build.tarde.open': () =>
            street(const CfOpt(hora: 'tarde', puerta: 'open', solX: 206)),
        'build.sinpuesto': () =>
            street(const CfOpt(puesto: false, carro: true)),
      },
      if (en.key == 'frutas') ...{
        'build': () =>
            street(const CfOpt(carro: true, surtido: 'frutas', aguja: 'libra')),
        'build.verduras': () =>
            street(const CfOpt(hora: 'tarde', puerta: 'open')),
        'build.otro': () => street(const CfOpt(surtido: 'otro', aguja: 'nada')),
      },
    };
    final mine = [
      for (final r in refs)
        if (r['engine'] == en.key && r['name'] != 'numbers') r,
    ];
    test('${en.key}: the cases are the JavaScript\'s, in its order', () {
      expect(cases.keys.toList(), [for (final r in mine) r['name']]);
    });
    for (final r in mine) {
      test('${en.key}: ${r['name']} draws the JavaScript\'s pixels', () {
        reset();
        final got = cases[r['name']]!();
        final hashes = {
          'pix': hashOf(e.pix),
          'zb': hashOf(e.zb),
          'kinds': hashOf(e.kinds),
          'ground': hashOf(e.ground),
          'shadow': hashOf(e.shadowMask),
        };
        final where = _where(en.key, r['name'] as String, e.pix, e.zb);
        for (final key in hashes.keys) {
          expect(
            hashes[key],
            r[key],
            reason: '$key differs${where == null ? '' : ': $where'}',
          );
        }
        expect(_plain(got), r['result']);
      });
    }
    if (en.key == 'calle') {
      test('calle: the numbers the kits give back are the JavaScript\'s', () {
        final n = refs.firstWhere((r) => r['name'] == 'numbers')['result'];
        surtido('verduras');
        final v = [
          for (final kk in const ['tomates', 'cebollas', 'papas', 'platanos'])
            [cf.binX(kk), cf.binBox(kk)],
        ];
        surtido('frutas');
        final f = [
          for (final kk in const ['aguacates', 'pinas', 'limones'])
            [cf.binX(kk), cf.binBox(kk)],
        ];
        expect(
          _plain({
            'skyPlan': [
              cf.skyPlan(const CfOpt()),
              cf.skyPlan(const CfOpt(hora: 'tarde')),
              cf.skyPlan(const CfOpt(solX: 206)),
              cf.skyPlan(const CfOpt(hora: 'tarde', solX: 120)),
            ],
            'bins': {'verduras': v, 'frutas': f},
            'tableZ': [
              for (final y in const [-1, .95, 1.2, 1.5, 2, 3]) cf.tableZ(y),
            ],
            'dial': ColmadoFuera.PESA_DIAL,
            'plato': ColmadoFuera.PESA_PLATO,
            'dentro': {
              'ESCALERA_PIE': ColmadoDentro.ESCALERA_PIE,
              'ESCALERA_ALTO': ColmadoDentro.ESCALERA_ALTO,
              'CAJA_VENTANA': ColmadoDentro.CAJA_VENTANA,
              'CAJA_GAVETA': ColmadoDentro.CAJA_GAVETA,
              'CAJA_REPISA': ColmadoDentro.CAJA_REPISA,
              'NEVERA': ColmadoDentro.NEVERA,
              'MESA': ColmadoDentro.MESA,
              'SILLA': ColmadoDentro.SILLA,
            },
          }),
          _plain(n),
        );
      });
    }
  }
}
