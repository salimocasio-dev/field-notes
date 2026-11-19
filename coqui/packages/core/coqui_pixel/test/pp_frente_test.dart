// A test of PpBuild's helpers at S = 26: El frente's Nov 14 one-state set (door open, shutters open, a porch lamp lit),
// built with that frente-set.html's calls in order at S = 26, originX = -30, originY = 40, against the picture the old
// page made in Chrome. That picture is no longer in coqui/ref/pp/ (order 07 replaced it with El frente's 25 states); its
// bytes are kept in test/support/fixtures/frente_nov14.dart and are read from there on every platform, the vm too.
// The same limit as the island: up to 0.5% of the pixels (page 11-pixel-engine, decision 2). It covers the helpers the
// island does not: block, onWall, windowOn, gable, shadowBox, bush, sphere in its modes, and the shading passes.
//
// The build runs once, when the file loads, so each test's name can carry its measured number.
import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/compare.dart';
import 'support/frente_build.dart';
import 'support/fixture_decode.dart';

void main() {
  final info = jsonDecode(
    utf8.decode(decodeFrenteNov14('state.json')),
  ) as Map<String, dynamic>;
  final e = frenteEngine();
  final b = PpBuild(e);
  final set = FrenteBuild(e, b);
  set.run();

  final pix = diffExact(e.pix, readU32(decodeFrenteNov14('pix.bin')));
  final zb = diffExact(e.zb, readF32(decodeFrenteNov14('zb.bin')));
  final kinds = diffExact(e.kinds, decodeFrenteNov14('kinds.bin'));

  test('the engine has the settings the page had', () {
    final eng = info['engine'] as Map<String, dynamic>;
    expect(
      [e.W, e.H, e.S, e.OX, e.OY],
      [eng['W'], eng['H'], eng['S'], eng['OX'], eng['OY']],
    );
    expect([e.SHADOW_X, e.SHADOW_Y], [eng['SHADOW_X'], eng['SHADOW_Y']]);
    expect(b.ST, .36 / 26);
  });

  test('the build counts what the old one counted', () {
    final counts = info['counts'] as Map<String, dynamic>;
    expect(e.tufts, hasLength(counts['tufts'] as int));
    expect(e.leaves, hasLength(counts['leaves'] as int));
  });

  test('the characters stand where the page put them', () {
    final spots = info['spots'] as Map<String, dynamic>;
    final screen = info['screen'] as Map<String, dynamic>;
    for (final who in ['abuela', 'coqui']) {
      final s = FrenteBuild.SPOTS[who]!,
          want = (spots[who] as List).cast<num>();
      expect(s, [for (final v in want) closeTo(v, 1e-12)]);
      final p = e.project(s[0], s[1], s[2]),
          at = (screen[who] as List).cast<num>();
      expect([p.sx, p.sy], [closeTo(at[0], 1e-9), closeTo(at[1], 1e-9)]);
    }
  });

  // Page 11-pixel-engine, decision 2: "up to 0.5% of pixels"
  const limit = 0.5;
  test('pix: ${pix.text} differ, limit $limit%', () {
    expect(
      pix.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${pix.first.join('\n')}',
    );
  });
  test('zb: ${zb.text} differ, limit $limit%', () {
    expect(
      zb.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${zb.first.join('\n')}',
    );
  });
  test('kinds: ${kinds.text} differ, limit $limit%', () {
    expect(
      kinds.percent,
      lessThanOrEqualTo(limit),
      reason: 'first ones:\n${kinds.first.join('\n')}',
    );
  });
}
