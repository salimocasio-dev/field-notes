// Every sprite of historia/escenas/kit.js in coqui/ref/sprites/kit/ (469 of them, 8 functions), made again by the
// recorded call and compared pixel for pixel. A sprite that differs in one pixel is a porting error, not a tolerance.
// On the vm the reference is read from the files, in a browser from the fixture made from them.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/compare.dart';
import 'support/kit_replay.dart';

void main() {
  final entries = loadKitEntries();
  final byFn = <String, List<dynamic>>{};
  for (final e in entries) {
    byFn.putIfAbsent(e.fn, () => []).add(e);
  }

  test('the reference holds the 469 sprites of 8 functions', () {
    expect(entries.length, 469);
    expect(byFn.keys.toSet(), {
      'mkAve',
      'mkAbuelaS',
      'mkPersona',
      'mkBebe',
      'mkPerro',
      'mkCesta',
      'tarjeta',
      'mano',
    });
    expect(
      {for (final k in byFn.keys) k: byFn[k]!.length},
      {
        'mkAve': 8,
        'mkAbuelaS': 24,
        'mkPersona': 396,
        'mkBebe': 16,
        'mkPerro': 16,
        'mkCesta': 1,
        'tarjeta': 7,
        'mano': 1,
      },
    );
  });

  var total = 0;
  for (final fn in byFn.keys) {
    final list = byFn[fn]!;
    test('$fn: ${list.length} sprites, every pixel', () {
      var bad = 0;
      final report = StringBuffer();
      for (final e in list) {
        final made = replayKitSprite(e);
        expect(made.w, e.w, reason: '${e.id} width');
        expect(made.h, e.h, reason: '${e.id} height');
        final diff = diffExact(made.px, kitReferencePixels(e));
        if (diff.count > 0) {
          bad++;
          report.writeln(
            '${e.id} (${e.call}): ${diff.text}; first '
            '${diff.first.take(20).map((d) => '#${d.index} ref ${d.ref.toInt().toRadixString(16)} dart ${d.dart.toInt().toRadixString(16)}').join(', ')}',
          );
        }
      }
      expect(bad, 0, reason: report.toString());
      total += list.length;
    });
  }

  test('469 sprites in all', () {
    expect(total, entries.length);
  });

  test('FAM is the reference\'s FAM, every field', () {
    final ref = loadKitFam();
    expect(FAM.keys.toSet(), ref.keys.toSet());
    List<int> ramp(Object? v) => [
      for (final h in v as List<dynamic>) hexColour(h as String),
    ];
    ref.forEach((name, v) {
      final r = v as Map<String, dynamic>, w = FAM[name]!;
      reason(String f) => '$name.$f';
      expect(w.piel, ramp(r['piel']), reason: reason('piel'));
      expect(w.pelo, ramp(r['pelo']), reason: reason('pelo'));
      expect(w.ropa, ramp(r['ropa']), reason: reason('ropa'));
      expect(
        w.abajo,
        r['abajo'] == null ? isNull : ramp(r['abajo']),
        reason: reason('abajo'),
      );
      expect(w.peinado, r['peinado'], reason: reason('peinado'));
      expect(w.nino, r['nino'] != null, reason: reason('nino'));
      expect(w.falda, r['falda'] != null, reason: reason('falda'));
      expect(w.bigote, r['bigote'] != null, reason: reason('bigote'));
      expect(w.gafas, r['gafas'], reason: reason('gafas'));
      expect(
        w.lazo,
        r['lazo'] == null ? isNull : hexColour(r['lazo'] as String),
        reason: reason('lazo'),
      );
      expect(
        w.zapato,
        r['zapato'] == null ? isNull : hexColour(r['zapato'] as String),
        reason: reason('zapato'),
      );
      expect(
        w.detalle != null,
        r['detalle'] != null,
        reason: reason('detalle'),
      );
      expect(w.dormido, isFalse, reason: reason('dormido'));
    });
  });
}
