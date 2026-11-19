// The small pieces of engine.js that the 445 sprites do not show one by one: the hash and the dither matrix against
// the old functions' values (made in node), the sprite cache and its keys, the glyph tables that scenes add to, and Buf.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/hs_bay_values.dart';

void main() {
  group('hs and bay', () {
    test('hs: 784 points from -6 to 21, as node gives them', () {
      var i = 0, bad = 0;
      for (var x = -6; x <= 21; x++) {
        for (var y = -6; y <= 21; y++) {
          final want = int.parse(hsGrid.substring(i * 2, i * 2 + 2));
          if (hs(x, y) != want) bad++;
          i++;
        }
      }
      expect(bad, 0);
    });

    test('hs: fractions, negatives and numbers past 32 bits', () {
      for (final (x, y, want) in hsExtra) {
        expect(hs(x, y), want, reason: 'hs($x, $y)');
      }
    });

    test('bay: 361 points from -9 to 9, as node gives them', () {
      var i = 0, bad = 0;
      for (var x = -9; x <= 9; x++) {
        for (var y = -9; y <= 9; y++) {
          final want = (int.parse(bayGrid[i], radix: 16) + .5) / 16;
          if (bay(x, y) != want) bad++;
          i++;
        }
      }
      expect(bad, 0);
    });

    test('bay: fractions, negatives and a number past 32 bits', () {
      for (final (x, y, want) in bayExtra) {
        expect(bay(x, y), want, reason: 'bay($x, $y)');
      }
    });
  });

  group('the sprite cache', () {
    test('spr makes a sprite once for a key', () {
      final lib = SpriteLib();
      var made = 0;
      Sprite make() {
        made++;
        return mkBall();
      }

      final a = lib.spr('ball', make), b = lib.spr('ball', make);
      expect(identical(a, b), isTrue);
      expect(made, 1);
      expect(lib.SP.keys, ['ball']);
    });

    test('coqui keys the way the old code does: "cq" + s + blink + open', () {
      final lib = SpriteLib();
      // 19 is a frame that blinks (f % 19 === 0), 1 is not
      lib.coqui(1, 0, false);
      lib.coqui(.7, 0, true);
      lib.coqui(.7, 1, false);
      lib.coqui(.42, 19, false);
      lib.coqui(0.86, 38, true);
      lib.coqui(1 - .14 * (3 / 20), 5, false);
      expect(lib.SP.keys.toSet(), {
        'cq110', // s 1, frame 0 blinks, mouth shut
        'cq0.711', // frame 0 blinks, mouth open
        'cq0.700',
        'cq0.4210',
        'cq0.8611',
        'cq0.97900',
      });
    });

    test(
      'coqui gives mkCoqui(s, blink, open) (frame 19 blinks, 20 does not)',
      () {
        final lib = SpriteLib();
        expect(lib.coqui(.6, 19, false).px, mkCoqui(.6, 1, false).px);
        expect(lib.coqui(.6, 20, true).px, mkCoqui(.6, 0, true).px);
        expect(lib.coqui(.6, 19, false).px, isNot(mkCoqui(.6, 0, false).px));
      },
    );

    test('two libraries do not share a cache', () {
      final a = SpriteLib(), b = SpriteLib();
      a.spr('x', mkBall);
      expect(b.SP, isEmpty);
    });
  });

  group('the glyph tables', () {
    test('a glyph a scene adds is drawn with its own colour', () {
      final lib = SpriteLib();
      // juego.js: GL.gota=[...];GC.gota="#3A86E6"
      lib.GL['gota'] = ['..#..', '.###.', '#####'];
      lib.GC['gota'] = 0xFFE6863A;
      final sp = Sprite(8, 8, Uint32List(64));
      lib.glyph(Ctx(sp.px, 8, 8), 'gota', 1, 2);
      expect(
        sp.px[2 * 8 + 3],
        0xFFE6863A,
      ); // the top of the drop, at (1 + 2, 2)
      expect(sp.px[3 * 8 + 2], 0xFFE6863A);
      expect(sp.px[2 * 8 + 1], 0); // a '.'
      expect(SpriteLib().GL.containsKey('gota'), isFalse);
    });

    test('bubble widens with its icons: ok and sad are 7, a glyph its width, 3 between', () {
      final lib = SpriteLib();
      final one = Sprite(64, 48, Uint32List(64 * 48));
      lib.bubble(Ctx(one.px, 64, 48), ['ok'], 32, 40, 0);
      final two = Sprite(64, 48, Uint32List(64 * 48));
      lib.bubble(Ctx(two.px, 64, 48), ['ok', 'sad'], 32, 40, 0);
      int dark(Sprite s) => s.px.where((p) => p == 0xFF10182A).length;
      expect(dark(two), greaterThan(dark(one)));
    });

    test('an unknown glyph throws, as GL[k].forEach does', () {
      final sp = Sprite(8, 8, Uint32List(64));
      expect(
        () => SpriteLib().glyph(Ctx(sp.px, 8, 8), 'nope', 0, 0),
        throwsA(anything),
      );
    });
  });

  group('Buf', () {
    test('px floors, ignores what is outside, and always writes alpha 255', () {
      final b = Buf(4, 3);
      b.px(1.9, 2.1, 0x00112233);
      b.px(-1, 0, 0xFFFFFFFF);
      b.px(4, 0, 0xFFFFFFFF);
      b.px(0, 3, 0xFFFFFFFF);
      b.px(-0.5, 0, 0xFFFFFFFF); // floors to -1: out
      expect(b.d[2 * 4 + 1], 0xFF112233);
      expect(b.d.where((p) => p != 0).length, 1);
    });

    test('has is false outside and on an empty pixel', () {
      final b = Buf(3, 3)..px(1, 1, 0xFF000000);
      expect(b.has(1, 1), isTrue);
      expect(b.has(0, 0), isFalse);
      expect(b.has(-1, 1), isFalse);
      expect(b.has(3, 1), isFalse);
    });

    test('outline puts the colour on the empty pixels next to a pixel, and returns the Buf', () {
      final b = Buf(5, 5)..px(2, 2, 0xFF0000FF);
      expect(identical(b.outline(0xFF00FF00), b), isTrue);
      expect([
        b.d[1 * 5 + 2],
        b.d[3 * 5 + 2],
        b.d[2 * 5 + 1],
        b.d[2 * 5 + 3],
      ], everyElement(0xFF00FF00));
      expect(b.d[1 * 5 + 1], 0); // a corner is not next to it
      expect(b.d[2 * 5 + 2], 0xFF0000FF);
    });

    test('done puts the image data on the canvas and the canvas keeps what is drawn on it after', () {
      final b = Buf(4, 4)..rect(0, 0, 2, 2, 0xFF010203);
      final cv = b.done();
      expect(cv.px[0], 0xFF010203);
      expect(cv.px[3 * 4 + 3], 0);
      b.cx.fillStyle = 0xFF0000FF;
      b.cx.fillRect(3, 3, 1, 1);
      expect(cv.px[3 * 4 + 3], 0xFF0000FF); // the same picture
      expect(b.d[3 * 4 + 3], 0); // the image data is not touched
    });

    test('rect rounds its corner, grad and ell paint inside their box', () {
      final b = Buf(10, 10)
        ..rect(1.5, 1.5, 2, 2, 0xFF111111) // rounds to (2, 2)
        ..grad(5, 5, 4, 4, const [0xFF000001, 0xFF000002]);
      expect(b.d[2 * 10 + 2], 0xFF111111);
      expect(b.d[3 * 10 + 3], 0xFF111111);
      expect(b.d[1 * 10 + 1], 0);
      expect(b.d[4 * 10 + 4], 0);
      expect(b.d[8 * 10 + 8], isNonZero);
    });
  });

  group('rgb', () {
    test('"#RRGGBB" as [r, g, b], from the cache the second time', () {
      final lib = SpriteLib();
      expect(lib.rgb('#2A1810'), [42, 24, 16]);
      expect(identical(lib.rgb('#2A1810'), lib.rgb('#2A1810')), isTrue);
    });
  });
}
