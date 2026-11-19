// The engine's functions that El frente's set and the island do not reach: growTree and the capture mode of sphere,
// drawLeaves, box, figure (through person and through dynamicAdd), flushShadows with bones, flatRoof, windowOn lit
// and with its defaults, drawDots,
// haloDots, drawArrow and its clipping. The scene is drawn with the OLD code by tool/make_extra_ref.mjs (node) and
// again here, call for call (test/support/extra_build.dart); the picture after each of three stages is compared,
// with the same limit as the island: up to 0.5% of the pixels (page 11-pixel-engine, decision 2).
//
// The build runs once, when the file loads, so each test's name can carry its measured number.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/compare.dart';
import 'support/extra_build.dart';
import 'support/fixture_decode.dart';

void main() {
  final bytes = decodeExtra;
  final meta =
      jsonDecode(utf8.decode(bytes('meta.json'))) as Map<String, dynamic>;
  final e = extraEngine();
  final b = PpBuild(e);
  final drawn = drawExtraScene(e, b);

  Diff pix(String stage) =>
      diffExact(drawn.stages[stage]!.pix, readU32(bytes('$stage/pix.bin')));
  Diff zb(String stage) =>
      diffExact(drawn.stages[stage]!.zb, readF32(bytes('$stage/zb.bin')));
  final objectsPix = pix('objects'), objectsZb = zb('objects');
  final objectsKinds = diffExact(
    drawn.stages['objects']!.kinds!,
    bytes('objects/kinds.bin'),
  );
  final bakedPix = pix('baked'), bakedZb = zb('baked');
  final framePix = pix('frame'), frameZb = zb('frame');

  test('the scene counts what the old one counted', () {
    expect(
      [e.W, e.H, e.S, e.OX, e.OY],
      [meta['W'], meta['H'], meta['S'], meta['OX'], meta['OY']],
    );
    expect(e.tufts, hasLength(meta['tufts'] as int));
    expect(e.leaves, hasLength(meta['leaves'] as int));
    final want = (meta['leafList'] as List).cast<Map<String, dynamic>>();
    for (var n = 0; n < want.length; n++) {
      final l = e.leaves[n], w = want[n];
      // hash() uses Math.sin, which differs between engines in its last digits
      expect(
        [l.x, l.y, l.z, l.r, l.k],
        [
          for (final v in ['x', 'y', 'z', 'r']) closeTo(w[v] as num, 1e-9),
          w['k'],
        ],
        reason: 'leaf $n',
      );
      expect(l.pixels, hasLength(w['n'] as int), reason: 'leaf $n pixels');
    }
    final hand = (meta['hand'] as List).cast<num>();
    expect(drawn.hand, [for (final v in hand) closeTo(v, 1e-12)]);
  });

  test('with still (reduced motion) the arrow does not bob', () {
    // drawArrow: bob = STILL ? 0 : Math.floor(time * 3) % 2 * 2
    Uint32List arrow(bool still, num time) {
      final e = PpEngine(w: 40, h: 40, s: 8, still: still)
        ..drawArrow(20, 30, time);
      return e.pix;
    }

    expect(arrow(true, .4), arrow(true, 0));
    expect(arrow(false, .4), isNot(arrow(false, 0)));
    expect(arrow(false, .7), arrow(false, 0)); // floor(2.1) is even
  });

  const limit = 0.5;
  void within(String what, Diff d) =>
      test('$what: ${d.text} differ, limit $limit%', () {
        expect(
          d.percent,
          lessThanOrEqualTo(limit),
          reason: 'first ones:\n${d.first.join('\n')}',
        );
      });
  within(
    'objects pix (growTree trunks, box, flatRoof, palm, person, shadows)',
    objectsPix,
  );
  within('objects zb', objectsZb);
  within('objects kinds', objectsKinds);
  within('baked pix (bakeOcclusion, applyShadows, shadeEdges)', bakedPix);
  within('baked zb', bakedZb);
  within(
    'frame pix (drawLeaves, drawTufts, figure with dynamicAdd, drawDots, haloDots, drawArrow)',
    framePix,
  );
  within('frame zb', frameZb);
}
