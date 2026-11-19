// What Ctx does, one operation at a time, on small pictures whose right answer can be worked out by hand. The canvas
// sheet (ctx_test.dart) compares it with the browser; these check the rules the sheet does not reach: the clip stack,
// save and restore, the whole-pixel rule for a sprite, flips, scaling, the paths, snapshot. They run on the vm and
// in a browser, where whole-number maths differs (shifts of negative numbers, for one).
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

const black = 0xFF000000,
    white = 0xFFFFFFFF,
    red = 0xFF0000FF,
    blue = 0xFFFF0000;

/// A picture of `w` x `h` and the canvas on it.
class Pic {
  Pic(this.w, this.h) : px = Uint32List(w * h) {
    c = Ctx(px, w, h);
  }

  final int w, h;
  final Uint32List px;
  late final Ctx c;

  int at(int x, int y) => px[y * w + x];

  /// The pixels that are not transparent, as `x,y`.
  Set<String> painted() => {
    for (var i = 0; i < px.length; i++)
      if (px[i] != 0) '${i % w},${i ~/ w}',
  };

  /// The pixels of a rectangle `x .. x + rw - 1`, `y .. y + rh - 1`, as a set of `x,y`.
  static Set<String> box(int x, int y, int rw, int rh) => {
    for (var j = 0; j < rh; j++)
      for (var i = 0; i < rw; i++) '${x + i},${y + j}',
  };
}

/// A sprite of `w` x `h` whose pixels are the given colours.
Sprite sprite(int w, int h, List<int> colours) =>
    Sprite(w, h, Uint32List.fromList(colours));

void main() {
  group('state', () {
    test('a new canvas: transparent, black, alpha 1, line 1, no smoothing', () {
      final p = Pic(4, 4);
      expect(p.px.every((v) => v == 0), isTrue);
      expect(p.c.fillStyle, black);
      expect(p.c.strokeStyle, black);
      expect(p.c.globalAlpha, 1);
      expect(p.c.lineWidth, 1);
      expect(p.c.smoothing, isFalse);
    });

    test('the target must hold w x h pixels', () {
      expect(() => Ctx(Uint32List(5), 2, 3), throwsArgumentError);
    });

    test('save and restore bring back the colours, alpha, line, smoothing, transform and clip', () {
      final p = Pic(8, 8);
      p.c
        ..fillStyle = red
        ..globalAlpha = .5
        ..lineWidth = 3
        ..smoothing = true;
      p.c.save();
      p.c
        ..fillStyle = blue
        ..strokeStyle = blue
        ..globalAlpha = 1
        ..lineWidth = 1
        ..smoothing = false
        ..translate(4, 4);
      p.c
        ..beginPath()
        ..rect(0, 0, 1, 1)
        ..clip();
      p.c.restore();
      expect(p.c.fillStyle, red);
      expect(p.c.strokeStyle, black);
      expect(p.c.globalAlpha, .5);
      expect(p.c.lineWidth, 3);
      expect(p.c.smoothing, isTrue);
      // the transform and the clip are back: a rectangle at the origin is drawn, whole
      p.c.globalAlpha = 1;
      p.c.fillRect(0, 0, 8, 8);
      expect(p.painted().length, 64);
    });

    test('restore with nothing saved does nothing', () {
      final p = Pic(2, 2)..c.restore();
      p.c.fillStyle = red;
      p.c.restore();
      expect(p.c.fillStyle, red);
    });

    test('saves nest', () {
      final p = Pic(4, 4);
      p.c.fillStyle = red;
      p.c.save();
      p.c.fillStyle = blue;
      p.c.save();
      p.c.fillStyle = white;
      p.c.restore();
      expect(p.c.fillStyle, blue);
      p.c.restore();
      expect(p.c.fillStyle, red);
    });
  });

  group('the transform', () {
    test('translate then scale: the order the browser multiplies in', () {
      final p = Pic(20, 20);
      p.c
        ..fillStyle = red
        ..translate(10, 10)
        ..scale(2, 2)
        ..fillRect(0, 0, 3, 2);
      expect(p.painted(), Pic.box(10, 10, 6, 4));
    });

    test('scale then translate moves by the scaled amount', () {
      final p = Pic(20, 20);
      p.c
        ..fillStyle = red
        ..scale(2, 2)
        ..translate(3, 1)
        ..fillRect(0, 0, 1, 1);
      expect(p.painted(), Pic.box(6, 2, 2, 2));
    });

    test('a quarter turn about a corner', () {
      final p = Pic(20, 20);
      p.c
        ..fillStyle = red
        ..translate(10, 10)
        ..rotate(math.pi / 2)
        ..fillRect(0, 0, 4, 2);
      // x' = -y, y' = x: x from 8 to 10, y from 10 to 14
      expect(p.painted(), Pic.box(8, 10, 2, 4));
      expect(p.painted().every((k) => true), isTrue);
      for (final k in p.painted()) {
        final xy = k.split(',').map(int.parse).toList();
        expect(p.at(xy[0], xy[1]), red, reason: k);
      }
    });

    test('a negative scale flips', () {
      final p = Pic(10, 4);
      p.c
        ..fillStyle = red
        ..translate(8, 0)
        ..scale(-1, 1)
        ..fillRect(0, 0, 3, 1);
      expect(p.painted(), Pic.box(5, 0, 3, 1));
    });
  });

  group('fillRect and clearRect', () {
    test('a whole rectangle, opaque, is exact; a negative size is the same rectangle', () {
      final p = Pic(10, 10);
      p.c
        ..fillStyle = red
        ..fillRect(2, 3, 4, 2);
      expect(p.painted(), Pic.box(2, 3, 4, 2));
      expect(p.at(2, 3), red);
      final q = Pic(10, 10);
      q.c
        ..fillStyle = red
        ..fillRect(6, 5, -4, -2);
      expect(q.painted(), Pic.box(2, 3, 4, 2));
    });

    test('zero width or height draws nothing', () {
      final p = Pic(4, 4);
      p.c
        ..fillStyle = red
        ..fillRect(1, 1, 0, 2)
        ..fillRect(1, 1, 2, 0);
      expect(p.painted(), isEmpty);
    });

    test('outside the picture is cut off, at every edge', () {
      final p = Pic(4, 4);
      p.c
        ..fillStyle = red
        ..fillRect(-5, -5, 7, 7)
        ..fillRect(3, 3, 9, 9);
      expect(p.painted(), {...Pic.box(0, 0, 2, 2), '3,3'});
    });

    test('a half pixel edge covers half: the edge pixel is half transparent over nothing, half way over a colour', () {
      final p = Pic(6, 3);
      p.c
        ..fillStyle = white
        ..fillRect(1.5, 0, 3, 3);
      // column 1 and 4 are half covered (alpha 128), 2 and 3 whole
      expect(p.at(1, 1) >> 24, 128);
      expect(p.at(4, 1) >> 24, 128);
      expect(p.at(2, 1), white);
      expect(p.at(3, 1), white);
      expect(p.at(0, 1), 0);
      expect(p.at(5, 1), 0);
      // over a solid pixel it is the middle of the two
      final q = Pic(6, 3);
      q.c
        ..fillStyle = black
        ..fillRect(0, 0, 6, 3)
        ..fillStyle = white
        ..fillRect(1.5, 0, 3, 3);
      expect(q.at(1, 1), 0xFF808080);
    });

    test('a rectangle partly above and left of the picture (shifts of negative numbers) draws the same on the web', () {
      final p = Pic(8, 8);
      p.c
        ..fillStyle = white
        ..fillRect(-2.5, -3.25, 5, 5);
      expect(p.at(0, 0), white);
      expect(
        p.at(1, 1),
        0xC0FFFFFF,
      ); // the bottom edge, y to 1.75: three quarters
      expect(p.at(2, 0), 0x80FFFFFF); // the right edge, x to 2.5: half
      expect(p.at(2, 1), 0x60FFFFFF); // the corner: three quarters of a half
      expect(p.at(3, 0), 0);
      expect(p.at(0, 2), 0);
    });

    test('alpha: a colour with alpha 0x80 and a globalAlpha both lessen what is drawn', () {
      final p = Pic(2, 1);
      p.c
        ..fillStyle = black
        ..fillRect(0, 0, 2, 1)
        ..globalAlpha = .5
        ..fillStyle = white
        ..fillRect(0, 0, 1, 1);
      expect(p.at(0, 0), 0xFF808080);
      expect(p.at(1, 0), black);
      final q = Pic(1, 1);
      q.c
        ..fillStyle = black
        ..fillRect(0, 0, 1, 1)
        ..fillStyle = 0x80FFFFFF
        ..fillRect(0, 0, 1, 1);
      expect(q.at(0, 0), 0xFF808080);
    });

    test('a colour with alpha 0 draws nothing, and so does globalAlpha 0', () {
      final p = Pic(2, 1);
      p.c
        ..fillStyle = 0x00FFFFFF
        ..fillRect(0, 0, 2, 1)
        ..fillStyle = white
        ..globalAlpha = 0
        ..fillRect(0, 0, 2, 1);
      expect(p.painted(), isEmpty);
    });

    test(
      'a translucent colour over nothing keeps its colour and its alpha',
      () {
        final p = Pic(1, 1);
        p.c
          ..fillStyle =
              0x80FF0000 // blue at half
          ..fillRect(0, 0, 1, 1);
        expect(p.at(0, 0) >> 24, 128);
        expect((p.at(0, 0) >> 16) & 255, 255);
        expect(p.at(0, 0) & 255, 0);
      },
    );

    test('clearRect makes a rectangle transparent again, and only that', () {
      final p = Pic(6, 6);
      p.c
        ..fillStyle = red
        ..fillRect(0, 0, 6, 6)
        ..clearRect(1, 2, 3, 2);
      expect(p.painted().length, 36 - 6);
      expect(p.at(1, 2), 0);
      expect(p.at(3, 3), 0);
      expect(p.at(4, 3), red);
    });

    test('clearRect with an edge in a pixel leaves the rest of it', () {
      final p = Pic(4, 1);
      p.c
        ..fillStyle = white
        ..fillRect(0, 0, 4, 1)
        ..clearRect(1.5, 0, 1, 1);
      expect(p.at(1, 0) >> 24, 128);
      expect(p.at(2, 0) >> 24, 128);
      expect(p.at(0, 0), white);
      expect(p.at(3, 0), white);
    });
  });

  group('clip', () {
    test(
      'a rectangle clip holds what is drawn inside it, and restore lets it go',
      () {
        final p = Pic(10, 10);
        p.c.fillStyle = red;
        p.c.save();
        p.c
          ..beginPath()
          ..rect(2, 2, 4, 3)
          ..clip();
        p.c.fillRect(0, 0, 10, 10);
        p.c.restore();
        expect(p.painted(), Pic.box(2, 2, 4, 3));
        p.c.fillRect(8, 8, 2, 2);
        expect(p.painted().length, 12 + 4);
      },
    );

    test('clips intersect', () {
      final p = Pic(10, 10);
      p.c.fillStyle = red;
      p.c
        ..beginPath()
        ..rect(0, 0, 6, 6)
        ..clip()
        ..beginPath()
        ..rect(3, 3, 6, 6)
        ..clip();
      p.c.fillRect(0, 0, 10, 10);
      expect(p.painted(), Pic.box(3, 3, 3, 3));
    });

    test(
      'the clip is in picture coordinates, not moved by a later transform',
      () {
        final p = Pic(12, 12);
        p.c
          ..fillStyle = red
          ..save()
          ..translate(4, 4)
          ..scale(2, 2)
          ..beginPath()
          ..rect(0, 0, 2, 1)
          ..clip()
          ..translate(100, 100)
          ..translate(-100, -100)
          ..fillRect(-10, -10, 40, 40);
        expect(p.painted(), Pic.box(4, 4, 4, 2));
      },
    );

    test('a clip with an empty path clips everything', () {
      final p = Pic(4, 4);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..clip()
        ..fillRect(0, 0, 4, 4);
      expect(p.painted(), isEmpty);
    });

    test('a clip outside the picture clips everything', () {
      final p = Pic(4, 4);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..rect(10, 10, 3, 3)
        ..clip()
        ..fillRect(0, 0, 4, 4);
      expect(p.painted(), isEmpty);
    });

    test('a clip with an edge in a pixel lets that pixel half through', () {
      final p = Pic(6, 2);
      p.c
        ..fillStyle = white
        ..beginPath()
        ..rect(1.5, 0, 3, 2)
        ..clip()
        ..fillRect(0, 0, 6, 2);
      expect(p.at(2, 0), white);
      expect(p.at(3, 0), white);
      expect(p.at(1, 0) >> 24, inInclusiveRange(126, 130));
      expect(p.at(0, 0), 0);
      expect(p.at(5, 0), 0);
    });

    test('a mask and a rectangle clip together', () {
      final p = Pic(20, 20);
      p.c
        ..fillStyle = red
        ..save()
        ..translate(10, 2)
        ..rotate(math.pi / 4)
        ..beginPath()
        ..rect(0, 0, 8, 8)
        ..clip()
        ..restore();
      // restore dropped it: the picture is unclipped again
      p.c.fillRect(0, 0, 20, 20);
      expect(p.painted().length, 400);
    });

    test(
      'a turned square clip keeps its middle and drops the corners of the box',
      () {
        final p = Pic(30, 30);
        p.c
          ..fillStyle = red
          ..translate(15, 4)
          ..rotate(math.pi / 4)
          ..beginPath()
          ..rect(0, 0, 14, 14)
          ..clip();
        p.c.restore(); // nothing saved: the clip stays
        p.c
          ..translate(-15, -4)
          ..fillRect(0, 0, 30, 30);
        // the square, turned an eighth, stands on its corner at (15, 4) and reaches down to y = 4 + 14 * sqrt 2 = 23.8
        expect(p.at(15, 14), red); // its middle (15, 4 + 7 * sqrt 2 = 13.9)
        expect(p.at(15, 22), red);
        expect(p.at(3, 14), 0); // far to its left
        expect(p.at(15, 2), 0); // above its corner
        expect(p.at(15, 26), 0); // below it
        expect(p.at(5, 5), 0);
      },
    );
  });

  group('drawImage', () {
    final s = sprite(2, 2, [0xFF000001, 0xFF000002, 0xFF000003, 0xFF000004]);

    test('a sprite lands on its position', () {
      final p = Pic(6, 6);
      p.c.drawImage(s, 2, 3);
      expect(p.at(2, 3), 0xFF000001);
      expect(p.at(3, 3), 0xFF000002);
      expect(p.at(2, 4), 0xFF000003);
      expect(p.at(3, 4), 0xFF000004);
      expect(p.painted().length, 4);
    });

    test(
      'a fractional position lands on (x + 0.5).floor(), without smoothing',
      () {
        for (final (x, y, ex, ey) in <(double, double, int, int)>[
          (1.4, 1.6, 1, 2),
          (2.5, 0.5, 3, 1),
          (2.49, 0.49, 2, 0),
          (-0.5, 0, 0, 0),
          (-0.6, 2.9, -1, 3),
          (3.5, 3.5, 4, 4),
        ]) {
          final p = Pic(8, 8);
          p.c.drawImage(s, x, y);
          for (var j = 0; j < 2; j++) {
            for (var i = 0; i < 2; i++) {
              final px = ex + i, py = ey + j;
              if (px < 0 || py < 0 || px >= 8 || py >= 8) continue;
              expect(
                p.at(px, py),
                0xFF000001 + j * 2 + i,
                reason: 'at ($x, $y) pixel $i,$j',
              );
            }
          }
          // no soft edge: only what the sprite's own pixels cover
          expect(
            p.painted().length,
            lessThanOrEqualTo(4),
            reason: 'at ($x, $y)',
          );
        }
      },
    );

    test('the same under a fractional translate', () {
      final p = Pic(8, 8);
      p.c
        ..translate(.4, .6)
        ..drawImage(s, 1, 1);
      expect(p.at(1, 2), 0xFF000001); // (1.4, 1.6) -> (1, 2)
    });

    test(
      'a flip lands on a whole pixel too, and reads the sprite backwards',
      () {
        final p = Pic(8, 4);
        p.c
          ..translate(6.3, 0)
          ..scale(-1, 1)
          ..drawImage(s, 0, 0);
        // device x from 4.3 to 6.3, rounded to 4: pixel 4 is the sprite's last column
        expect(p.at(4, 0), 0xFF000002);
        expect(p.at(5, 0), 0xFF000001);
        expect(p.at(4, 1), 0xFF000004);
        expect(p.at(5, 1), 0xFF000003);
      },
    );

    test('a vertical flip', () {
      final p = Pic(4, 6);
      p.c
        ..translate(0, 4)
        ..scale(1, -1)
        ..drawImage(s, 1, 0);
      expect(p.at(1, 2), 0xFF000003);
      expect(p.at(2, 3), 0xFF000002);
    });

    test('dw and dh scale it, nearest neighbour', () {
      final p = Pic(8, 8);
      p.c.drawImage(s, 1, 1, 4, 4);
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 4; i++) {
          expect(p.at(1 + i, 1 + j), 0xFF000001 + (j ~/ 2) * 2 + (i ~/ 2));
        }
      }
      expect(p.painted().length, 16);
    });

    test('a scale of the canvas does the same', () {
      final p = Pic(8, 8);
      p.c
        ..scale(2, 2)
        ..drawImage(s, .5, .5);
      for (var j = 0; j < 4; j++) {
        for (var i = 0; i < 4; i++) {
          expect(p.at(1 + i, 1 + j), 0xFF000001 + (j ~/ 2) * 2 + (i ~/ 2));
        }
      }
    });

    test('drawImageRect takes a part', () {
      final p = Pic(4, 4);
      p.c.drawImageRect(s, 1, 0, 1, 2, 2, 1, 1, 2);
      expect(p.at(2, 1), 0xFF000002);
      expect(p.at(2, 2), 0xFF000004);
      expect(p.painted().length, 2);
    });

    test('a source rectangle partly outside the sprite is cut, and the destination with it', () {
      final p = Pic(6, 4);
      p.c.drawImageRect(s, 1, 0, 3, 2, 1, 1, 3, 2);
      // only the sprite's last column exists: the first column of the destination
      expect(p.at(1, 1), 0xFF000002);
      expect(p.at(1, 2), 0xFF000004);
      expect(p.painted().length, 2);
    });

    test('transparent pixels of a sprite leave what is there', () {
      final p = Pic(4, 4);
      p.c
        ..fillStyle = red
        ..fillRect(0, 0, 4, 4)
        ..drawImage(sprite(2, 1, [0, 0xFF00FF00]), 1, 1);
      expect(p.at(1, 1), red);
      expect(p.at(2, 1), 0xFF00FF00);
    });

    test('globalAlpha lessens a sprite', () {
      final p = Pic(2, 1);
      p.c
        ..fillStyle = black
        ..fillRect(0, 0, 2, 1)
        ..globalAlpha = .5
        ..drawImage(sprite(1, 1, [white]), 0, 0);
      expect(p.at(0, 0), 0xFF808080);
    });

    test('inside a clip, the sprite is cut', () {
      final p = Pic(6, 6);
      p.c
        ..beginPath()
        ..rect(0, 0, 3, 6)
        ..clip()
        ..drawImage(s, 2, 2);
      expect(p.painted(), {'2,2', '2,3'});
    });

    test('a turned sprite fills the pixels whose centre it covers', () {
      final big = sprite(4, 4, List.filled(16, white));
      final p = Pic(12, 12);
      p.c
        ..translate(6, 2)
        ..rotate(math.pi / 4)
        ..drawImage(big, 0, 0);
      // a square of 4 turned an eighth: a diamond, area 16, about 16 pixels, with its top corner at (6, 2)
      final n = p.painted().length;
      expect(n, inInclusiveRange(12, 20));
      expect(p.at(6, 5), white);
      expect(p.at(0, 5), 0);
      expect(p.at(6, 0), 0);
    });

    test(
      'with smoothing on, the sprite is drawn where it is told and blurred',
      () {
        // a 2 x 1 sprite, black then white, drawn half a pixel to the right: the edge between them goes grey
        final p = Pic(8, 1);
        p.c
          ..smoothing = true
          ..drawImage(sprite(2, 1, [black, white]), 2.5, 0);
        // the destination runs between the rounded edges: pixels 3 and 4 (round(2.5) = 3 to round(4.5) = 5)
        expect(p.at(2, 0), 0);
        // pixel 3's centre is the middle of the two texels: half way between black and white
        expect(p.at(3, 0) & 255, inInclusiveRange(120, 135));
        // pixel 4's centre is past the last texel's middle: the last texel
        expect(p.at(4, 0), white);
        expect(p.at(5, 0), 0);
      },
    );

    test('with smoothing on, a whole position is an exact copy', () {
      final p = Pic(6, 6);
      p.c
        ..smoothing = true
        ..drawImage(s, 2, 3);
      expect(p.at(2, 3), 0xFF000001);
      expect(p.at(3, 4), 0xFF000004);
      expect(p.painted().length, 4);
    });
  });

  group('paths', () {
    test('rect and fill is fillRect', () {
      final p = Pic(10, 10), q = Pic(10, 10);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..rect(2, 3, 4.5, 2.25)
        ..fill();
      q.c
        ..fillStyle = red
        ..fillRect(2, 3, 4.5, 2.25);
      expect(p.px, q.px);
    });

    test('moveTo and lineTo make a triangle, filled', () {
      final p = Pic(12, 12);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..moveTo(0, 0)
        ..lineTo(10, 0)
        ..lineTo(0, 10)
        ..fill();
      expect(p.at(1, 1), red);
      expect(p.at(8, 0), red);
      expect(p.at(8, 8), 0);
      expect(
        p.at(0, 9) >> 24,
        inInclusiveRange(100, 170),
      ); // the hypotenuse cuts it in half
      // the area is 50: coverage adds up to it
      var sum = 0.0;
      for (final v in p.px) {
        sum += (v >> 24) / 255;
      }
      expect(sum, closeTo(50, 1.5));
    });

    test('a full circle: its middle is solid, its area is pi r squared, nothing outside it', () {
      final p = Pic(30, 30);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..arc(15, 15, 10, 0, 7)
        ..fill();
      expect(p.at(15, 15), red);
      expect(p.at(15, 6), red);
      expect(p.at(15, 3), 0);
      expect(p.at(3, 3), 0);
      var sum = 0.0;
      for (final v in p.px) {
        sum += (v >> 24) / 255;
      }
      expect(sum, closeTo(math.pi * 100, 5));
    });

    test('arc(x, y, r, pi, 0) is the upper half', () {
      final p = Pic(30, 30);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..arc(15, 15, 10, math.pi, 0)
        ..fill();
      expect(p.at(15, 10), red);
      expect(p.at(15, 20), 0);
      var sum = 0.0;
      for (final v in p.px) {
        sum += (v >> 24) / 255;
      }
      expect(sum, closeTo(math.pi * 50, 4));
    });

    test('an ellipse', () {
      final p = Pic(40, 20);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..ellipse(20, 10, 15, 5, 0, 0, 7)
        ..fill();
      expect(p.at(20, 10), red);
      expect(p.at(33, 10), red);
      expect(p.at(20, 3), 0);
      expect(p.at(2, 10), 0);
      var sum = 0.0;
      for (final v in p.px) {
        sum += (v >> 24) / 255;
      }
      expect(sum, closeTo(math.pi * 75, 5));
    });

    test('an ellipse turned a quarter has its radii swapped', () {
      final p = Pic(40, 40);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..ellipse(20, 20, 15, 5, math.pi / 2, 0, 7)
        ..fill();
      expect(p.at(20, 33), red);
      expect(p.at(33, 20), 0);
    });

    test('a radius below zero is an error, as in the browser', () {
      final p = Pic(4, 4);
      expect(() => p.c.arc(2, 2, -1, 0, 7), throwsArgumentError);
    });

    test('a path is not drawn twice, and beginPath starts a new one', () {
      final p = Pic(10, 10);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..rect(0, 0, 2, 2)
        ..fill()
        ..beginPath()
        ..rect(5, 5, 2, 2)
        ..fill();
      expect(p.painted(), {...Pic.box(0, 0, 2, 2), ...Pic.box(5, 5, 2, 2)});
    });

    test('two shapes in one path are filled together', () {
      final p = Pic(12, 6);
      p.c
        ..fillStyle = red
        ..beginPath()
        ..rect(0, 0, 3, 3)
        ..rect(6, 0, 3, 3)
        ..fill();
      expect(p.painted(), {...Pic.box(0, 0, 3, 3), ...Pic.box(6, 0, 3, 3)});
    });

    test(
      'a horizontal line of width 2 on a whole row boundary is two rows',
      () {
        final p = Pic(12, 8);
        p.c
          ..strokeStyle = red
          ..lineWidth = 2
          ..beginPath()
          ..moveTo(1, 4)
          ..lineTo(9, 4)
          ..stroke();
        expect(p.painted(), Pic.box(1, 3, 8, 2));
        expect(p.at(5, 3), red);
      },
    );

    test('a line of width 1 along a pixel row (y = 3.5) is one row', () {
      final p = Pic(12, 8);
      p.c
        ..strokeStyle = red
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(1, 3.5)
        ..lineTo(9, 3.5)
        ..stroke();
      expect(p.painted(), Pic.box(1, 3, 8, 1));
    });

    test('a line of width 1 on a pixel boundary is two half rows', () {
      final p = Pic(12, 8);
      p.c
        ..strokeStyle = white
        ..lineWidth = 1
        ..beginPath()
        ..moveTo(1, 4)
        ..lineTo(9, 4)
        ..stroke();
      expect(p.at(4, 3) >> 24, inInclusiveRange(125, 130));
      expect(p.at(4, 4) >> 24, inInclusiveRange(125, 130));
    });

    test('stroke uses strokeStyle, fill uses fillStyle', () {
      final p = Pic(10, 10);
      p.c
        ..fillStyle = red
        ..strokeStyle = blue
        ..lineWidth = 2
        ..beginPath()
        ..moveTo(0, 5)
        ..lineTo(10, 5)
        ..stroke();
      expect(p.at(5, 4), blue);
    });

    test('a stroked rectangle has its corners joined', () {
      final p = Pic(12, 12);
      p.c
        ..strokeStyle = red
        ..lineWidth = 2
        ..beginPath()
        ..rect(3, 3, 6, 6)
        ..stroke();
      expect(p.at(2, 2), red); // the outer corner of the mitre
      expect(p.at(9, 9), red);
      expect(p.at(5, 5), 0); // inside
      expect(p.at(1, 1), 0);
    });

    test(
      'a stroke on the web and the vm: the same pixels as the area it covers',
      () {
        final p = Pic(20, 20);
        p.c
          ..strokeStyle = red
          ..lineWidth = 3
          ..beginPath()
          ..ellipse(10, 10, 6, 6, 0, 0, 7)
          ..stroke();
        var sum = 0.0;
        for (final v in p.px) {
          sum += (v >> 24) / 255;
        }
        // a ring of width 3 about the circle of radius 6: area 2 pi r w = 113
        expect(sum, closeTo(2 * math.pi * 6 * 3, 4));
      },
    );
  });

  group('snapshot', () {
    test('a copy of part of the picture, that does not change with it', () {
      final p = Pic(6, 6);
      p.c
        ..fillStyle = red
        ..fillRect(1, 1, 3, 3);
      final s = p.c.snapshot(2, 2, 3, 3);
      expect(s.w, 3);
      expect(s.h, 3);
      expect(s.px[0], red);
      expect(s.px[1], red);
      expect(s.px[2], 0);
      expect(s.px[3 * 2 + 2], 0);
      p.c
        ..fillStyle = blue
        ..fillRect(2, 2, 1, 1);
      expect(s.px[0], red);
    });

    test('what is outside the picture is transparent', () {
      final p = Pic(3, 3);
      p.c
        ..fillStyle = red
        ..fillRect(0, 0, 3, 3);
      final s = p.c.snapshot(-1, -1, 3, 3);
      expect(s.px[0], 0);
      expect(s.px[1], 0);
      expect(s.px[3], 0);
      expect(s.px[4], red);
      expect(s.px[8], red);
      final t = p.c.snapshot(2, 2, 3, 3);
      expect(t.px[0], red);
      expect(t.px[1], 0);
    });

    test('a snapshot can be drawn back', () {
      final p = Pic(8, 4);
      p.c
        ..fillStyle = red
        ..fillRect(0, 0, 2, 2);
      p.c.drawImage(p.c.snapshot(0, 0, 2, 2), 5, 1);
      expect(p.at(5, 1), red);
      expect(p.at(6, 2), red);
    });
  });
}
