// The layout arithmetic (lib/src/ui/block_layout.dart) against the old page's own functions run in Node: juego.js
// `fit`, cual.js `cualSize` / `placeOpts` / `cualGrid`, for 16 phone sizes (made by tool/diff/make_fixture.mjs).
// Also nivel.js `nivelFrontera` on 405 answer logs (the page's own function, called from Node).
import 'package:coqui_testing/coqui_testing.dart' show FakeClock;
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_catalog.dart';

double px(String s) => double.parse(s.replaceAll('px', ''));

Map<String, double> style(String css) => {
  for (final part in css.split(';'))
    part.split(':')[0]: px(part.split(':')[1]),
};

void main() {
  final cases = [
    for (final c in readFixture('layout.json')['cases'] as List)
      c as Map<String, dynamic>,
  ];

  test('the fixture has the phones', () {
    expect(cases.where((c) => c['grid'] != null).length, 16);
    expect(cases.where((c) => c['block'] != null).length, 32);
  });

  test(
    'juego.js fit(): the whole-number scale, the gap, the block, the room under it and each frame, on 16 phones (both blocks)',
    () {
      for (final c in cases.where((c) => c['block'] != null)) {
        final ph = c['phone'] as Map<String, dynamic>;
        final b = c['block'] as Map<String, dynamic>;
        final land = c['land'] as bool;
        final w = (ph['w'] as num).toDouble();
        final h = (ph['h'] as num).toDouble();
        final left = (ph['left'] as num).toDouble();
        final right = (ph['right'] as num).toDouble();
        final top = (ph['top'] as num).toDouble();
        final bottom = (ph['bottom'] as num).toDouble();
        final double mw;
        final double mh;
        if (land) {
          mw = w - left - right;
          mh = h - top - bottom;
        } else {
          mw = w - left - right;
          mh = h - bottom - (56 + top);
        }
        final spec = BlockSpec(
          b['cols'] as int,
          b['rows'] as int,
          b['pw'] as int,
          b['ph'] as int,
        );
        final f = fitBlock(
          spec,
          dpr: (ph['dpr'] as num).toDouble(),
          mainWidth: mw,
          mainHeight: mh,
          landscape: land,
        );
        final why = '${ph['w']}x${ph['h']} @${ph['dpr']} block ${b['cols']}x${b['rows']}';
        expect(f.gap, c['gap'], reason: '$why: GAP');
        expect(f.width, px(c['width'] as String), reason: '$why: width');
        expect(f.height, px(c['height'] as String), reason: '$why: height');
        final mb = c['marginBottom'] as String; // '' on its side (the page clears it)
        expect(f.marginBottom, mb.isEmpty ? 0 : px(mb), reason: '$why: margin under');
        final rects = (c['rects'] as List).cast<String>();
        expect(f.cells.length, rects.length);
        for (var k = 0; k < rects.length; k++) {
          final s = style(rects[k]);
          expect(f.cells[k].left, s['left'], reason: '$why: frame $k left');
          expect(f.cells[k].top, s['top'], reason: '$why: frame $k top');
          expect(f.cells[k].width, s['width'], reason: '$why: frame $k width');
          expect(f.cells[k].height, s['height'], reason: '$why: frame $k height');
        }
      }
    },
  );

  test('cual.js cualGrid(): columns and scale of the end screen on 16 phones', () {
    for (final c in cases.where((c) => c['grid'] != null)) {
      final ph = c['phone'] as Map<String, dynamic>;
      final dpr = (ph['dpr'] as num).toDouble();
      final g = endGridFor(
        clientWidth: (ph['w'] as num).toDouble() - (ph['left'] as num) - (ph['right'] as num),
        padding: 32,
        dpr: dpr,
      );
      final e = c['grid'] as Map<String, dynamic>;
      final why = '${ph['w']}x${ph['h']} @${ph['dpr']}';
      expect(g.columns, e['--c'], reason: '$why: columns');
      expect(g.cellWidth, px(e['--pw'] as String), reason: '$why: picture width');
      expect(g.width, px(e['--gw'] as String), reason: '$why: grid width');
    }
  });

  test('nivel.js nivelFrontera(): the same S0 as the old function on 405 answer logs (the edges at three in four too)', () {
    final fixture = readFixture('frontier.json');
    final course = FixtureCatalog();
    var positive = 0;
    for (final c in fixture['cases'] as List) {
      final m = c as Map<String, dynamic>;
      final log = [
        for (final x in m['h'] as List)
          LevelAnswer(
            i: (x as Map)['i'] as int,
            word: x['w'] as String,
            story: x['s'] as int,
            ok: x['ok'] as bool,
            ms: x['ms'] as int,
          ),
      ];
      final s0 = LevelCheckSession.frontier(log, course.levelItems);
      expect(s0, m['S0'], reason: jsonOf(m['h']));
      if (s0 > 0) positive++;
    }
    expect(positive, greaterThan(100));
    expect(FakeClock().nowMs(), isNonZero); // (keeps the import honest)
    expect(Mulberry32(1).next(), isNotNull);
  });
}

String jsonOf(Object? x) => x.toString();
