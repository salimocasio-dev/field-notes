// Every sprite of historia/engine.js in coqui/ref/sprites/engine/ (445 of them, 20 functions), made again by the
// recorded call and compared pixel for pixel. A sprite that differs in one pixel is a porting error, not a tolerance.
// On the vm the reference is read from the files, in a browser from the fixture made from them.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/compare.dart';
import 'support/sprite_replay.dart';

void main() {
  final entries = loadSpriteEntries();
  final byFn = <String, List<SpriteEntry>>{};
  for (final e in entries) {
    byFn.putIfAbsent(e.fn, () => []).add(e);
  }

  test('the reference holds the 445 sprites of 20 functions', () {
    expect(entries.length, 445);
    expect(byFn.length, 20);
  });

  // one library for the whole run: bgCasa and bgParque draw cached sprites, and a cache that hands out a sprite
  // another call made must still give the same pixels
  final lib = SpriteLib();
  var total = 0;
  for (final fn in byFn.keys) {
    final list = byFn[fn]!;
    test('$fn: ${list.length} sprites, every pixel', () {
      var bad = 0;
      final report = StringBuffer();
      for (final e in list) {
        final made = replaySprite(lib, e);
        expect(made.w, e.w, reason: '${e.id} width');
        expect(made.h, e.h, reason: '${e.id} height');
        final diff = diffExact(made.px, referencePixels(e));
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

  test('445 sprites in all', () {
    expect(total, entries.length);
  });
}
