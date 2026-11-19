// The camera (page 12, section 5, as corrected on Nov 19): a view is a centre and a zoom of 1 or 2; the two mappings
// between the picture and the display; camGo as a slide between views of one zoom and a cut between two zooms (its
// frame counts and, for a slide, its positions, against juego.js's camGo run in node: tool/make_kit_ref.mjs); the
// review and level-check crop.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:test/test.dart';

import 'support/fixtures/ref_kit_logic.dart';

void main() {
  // the corners, edges and middle of the picture, and points past it
  final centres = <List<num>>[
    for (final x in [
      -30,
      0,
      1,
      49,
      50,
      98,
      100.5,
      120,
      190,
      191,
      239,
      240,
      300,
    ])
      for (final y in [-30, 0, 1, 53, 54, 100, 108, 163, 164, 215, 216, 300])
        [x, y],
  ];

  group('viewAt: the view centred on a point, kept inside the picture', () {
    test('zoom 1: the 196 x 216 window', () {
      expect(viewAt(120, 108, 1), [22, 0, 196, 216]);
      expect(viewAt(0, 0, 1), [0, 0, 196, 216]);
      expect(viewAt(240, 216, 1), [44, 0, 196, 216]);
      expect(viewAt(0, 216, 1), [0, 0, 196, 216]);
      expect(viewAt(240, 0, 1), [44, 0, 196, 216]);
      expect(viewAt(98, 108, 1), [0, 0, 196, 216]);
      expect(viewAt(99, 108, 1), [1, 0, 196, 216]);
      expect(viewAt(142, 108, 1), [44, 0, 196, 216]);
      expect(viewAt(143, 108, 1), [44, 0, 196, 216]);
    });
    test('zoom 2: the 98 x 108 region', () {
      expect(viewAt(120, 108, 2), [71, 54, 98, 108]);
      expect(viewAt(0, 0, 2), [0, 0, 98, 108]);
      expect(viewAt(240, 216, 2), [142, 108, 98, 108]);
      expect(viewAt(0, 216, 2), [0, 108, 98, 108]);
      expect(viewAt(240, 0, 2), [142, 0, 98, 108]);
      expect(viewAt(49, 54, 2), [0, 0, 98, 108]);
      expect(viewAt(50, 55, 2), [1, 1, 98, 108]);
      expect(viewAt(191, 162, 2), [142, 108, 98, 108]);
    });
    test(
      'odd and fractional centres round to a whole pixel (x + 0.5, floored)',
      () {
        expect(viewAt(101, 108, 1)[0], 3);
        expect(viewAt(100.5, 108, 1)[0], 3);
        expect(viewAt(100.49, 108, 1)[0], 2);
        expect(viewAt(100.5, 107.5, 2), [52, 54, 98, 108]);
        expect(viewAt(121, 109, 2), [72, 55, 98, 108]);
      },
    );
    test('every centre, both zooms: whole numbers, the right size, inside the picture', () {
      for (final zoom in [1, 2]) {
        for (final c in centres) {
          final v = viewAt(c[0], c[1], zoom);
          expect(v.length, 4);
          expect(v[2], 196 ~/ zoom);
          expect(v[3], 216 ~/ zoom);
          expect(
            v[0],
            inInclusiveRange(0, 240 - v[2]),
            reason: '$c zoom $zoom',
          );
          expect(
            v[1],
            inInclusiveRange(0, 216 - v[3]),
            reason: '$c zoom $zoom',
          );
          // a centre inside the part where the window fits is the centre
          if (c[0] >= v[2] / 2 &&
              c[0] <= 240 - v[2] / 2 &&
              c[0] == c[0].roundToDouble()) {
            expect(v[0] + v[2] / 2, c[0], reason: '$c zoom $zoom: centred');
          }
          if (c[1] >= v[3] / 2 &&
              c[1] <= 216 - v[3] / 2 &&
              c[1] == c[1].roundToDouble()) {
            expect(v[1] + v[3] / 2, c[1], reason: '$c zoom $zoom: centred');
          }
        }
      }
    });
    test('no other zoom exists', () {
      for (final z in [0, 3, -1]) {
        expect(() => viewAt(120, 108, z), throwsArgumentError);
      }
    });
  });

  group('zoomOf', () {
    test('196 x 216 is 1, 98 x 108 is 2, nothing else is', () {
      expect(zoomOf([22, 0, 196, 216]), 1);
      expect(zoomOf([22.0, 0.0, 196.0, 216.0]), 1);
      expect(zoomOf([71, 54, 98, 108]), 2);
      for (final bad in [
        [0, 0, 170, 187.3],
        [0, 0, 127, 140],
        [0, 0, 196, 104],
        [0, 0, 98, 216],
        [0, 0, 195.9, 216],
      ]) {
        expect(() => zoomOf(bad), throwsArgumentError, reason: '$bad');
      }
    });
  });

  group('picture point <-> display point', () {
    final cams = <List<int>>[
      for (final zoom in [1, 2])
        for (final c in [
          [0, 0],
          [240, 0],
          [0, 216],
          [240, 216],
          [120, 108],
          [97, 53],
          [150, 60],
        ])
          viewAt(c[0], c[1], zoom),
    ];

    test('the view\'s own corners and the picture\'s edges', () {
      final z1 = viewAt(0, 0, 1), z1r = viewAt(240, 0, 1);
      expect(pictureToDisplay(z1, 0, 0), (x: 0.0, y: 0.0));
      expect(displayToPicture(z1, 0, 0), (x: 0.0, y: 0.0));
      expect(displayToPicture(z1, 195, 215), (x: 195.0, y: 215.0));
      expect(displayToPicture(z1r, 195, 215), (x: 239.0, y: 215.0));
      expect(pictureToDisplay(z1r, 239, 215), (x: 195.0, y: 215.0));
      final z2 = viewAt(0, 0, 2), z2r = viewAt(240, 216, 2);
      expect(pictureToDisplay(z2, 0, 0), (x: 0.0, y: 0.0));
      expect(pictureToDisplay(z2, 97, 107), (x: 194.0, y: 214.0));
      expect(displayToPicture(z2, 195, 215), (x: 97.5, y: 107.5));
      expect(pictureToDisplay(z2r, 142, 108), (x: 0.0, y: 0.0));
      expect(pictureToDisplay(z2r, 239, 215), (x: 194.0, y: 214.0));
      expect(displayToPicture(z2r, 195, 215), (x: 239.5, y: 215.5));
      // the hand sign's arithmetic (juego.js: (p - cam) * z): a half pixel of the picture is a whole one of the display
      expect(pictureToDisplay([10, 20, 98, 108], 15.5, 30.5), (
        x: 11.0,
        y: 21.0,
      ));
    });

    test('on the pixel grid they are inverse: every picture pixel of the view, every display pixel', () {
      for (final cam in cams) {
        final z = zoomOf(cam);
        for (var py = cam[1]; py < cam[1] + cam[3]; py++) {
          for (var px = cam[0]; px < cam[0] + cam[2]; px++) {
            final d = pictureToDisplay(cam, px, py);
            // a whole picture pixel is the top-left display pixel of its block, inside the display
            expect(d.x, d.x.roundToDouble());
            expect(d.y, d.y.roundToDouble());
            expect(d.x, inInclusiveRange(0, 195));
            expect(d.y, inInclusiveRange(0, 215));
            expect(d.x % z, 0);
            expect(d.y % z, 0);
            // and back is the same pixel, exactly
            expect(displayToPicture(cam, d.x, d.y), (
              x: px.toDouble(),
              y: py.toDouble(),
            ), reason: '$cam $px,$py');
          }
        }
        for (var dy = 0; dy < 216; dy++) {
          for (var dx = 0; dx < 196; dx++) {
            final p = displayToPicture(cam, dx, dy);
            final fx = p.x.floor(), fy = p.y.floor();
            expect(fx, cam[0] + dx ~/ z);
            expect(fy, cam[1] + dy ~/ z);
            expect(fx, inInclusiveRange(0, 239), reason: 'inside the picture');
            expect(fy, inInclusiveRange(0, 215), reason: 'inside the picture');
            // the picture pixel's block starts at this display pixel cut down to a block
            final back = pictureToDisplay(cam, fx, fy);
            expect(back, (
              x: (dx - dx % z).toDouble(),
              y: (dy - dy % z).toDouble(),
            ));
          }
        }
      }
    });

    test('a tap between pixels is between pixels (a display point of a half is a quarter of a block)', () {
      final cam = viewAt(120, 108, 2);
      final p = displayToPicture(cam, 100.5, 50.5);
      expect(p, (x: cam[0] + 50.25, y: cam[1] + 25.25));
      expect(pictureToDisplay(cam, p.x, p.y), (x: 100.5, y: 50.5));
    });
  });

  group('camGo against the old camGo in node', () {
    final ref = jsonDecode(kitLogicRef) as Map<String, dynamic>;
    final moves = (ref['camgo'] as List<dynamic>).cast<Map<String, dynamic>>();

    test('9 moves were run', () => expect(moves.length, 9));

    for (final m in moves) {
      final from = [for (final v in m['from'] as List<dynamic>) v as num];
      final to = [for (final v in m['to'] as List<dynamic>) v as num];
      final n = m['n'] as int?;
      final steps = m['steps'] as int;
      final old = (m['positions'] as List<dynamic>)
          .map((p) => [for (final v in p as List<dynamic>) v as num])
          .toList();
      test(m['title'] as String, () {
        if (steps == 0) {
          // already there: camGo returns at once, the host's `at` says so
          expect(atView(from, to), isTrue);
          return;
        }
        expect(atView(from, to), isFalse);
        final slide = CamSlide(from: from, to: to, f0: 40, n: n);
        // the same number of frames as the old one: it is over on the frame the old one was over
        expect(slide.n, steps);
        final got = slide.steps();
        expect(got.length, steps);
        for (var k = 1; k <= steps; k++) {
          final r = slide.at(40 + k);
          expect(r.done, k == steps, reason: 'done at frame $k');
        }
        expect(slide.at(40 + steps - 1).done, isFalse);
        // ends exactly on its target
        expect(got.last, [for (final v in to) v.round()]);
        for (final cam in got) {
          for (final v in cam) {
            expect(v, isA<int>());
          }
        }
        if (!slide.cut) {
          // the same ease and the same frames: the old position, rounded (the old one also moved w and h; here they stay)
          for (var k = 0; k < steps; k++) {
            expect(
              got[k][0],
              (old[k][0] + 0.5).floor(),
              reason: 'x at frame ${k + 1}',
            );
            expect(
              got[k][1],
              (old[k][1] + 0.5).floor(),
              reason: 'y at frame ${k + 1}',
            );
            expect(got[k][2], from[2]);
            expect(got[k][3], from[3]);
          }
          // a slide never leaves the two places
          final x0 = from[0] < to[0] ? from[0] : to[0],
              x1 = from[0] > to[0] ? from[0] : to[0];
          for (final cam in got) {
            expect(cam[0], inInclusiveRange(x0, x1));
          }
        } else {
          // a cut: at the target from the first step, and at every step after
          for (final cam in got) {
            expect(cam, [for (final v in to) v.round()]);
          }
          expect(slide.at(40).cam, [for (final v in to) v.round()]);
          // never a view of another size on the way: no fractional scale, not for one frame
          for (final cam in got) {
            expect(zoomOf(cam), anyOf(1, 2));
          }
        }
      });
    }

    test('a slide passes only whole pixels, in order, whatever the ends', () {
      for (final a in [0, 7, 44]) {
        for (final b in [0, 13, 44]) {
          for (final n in [null, 1, 2, 5, 9, 30]) {
            final s = CamSlide(
              from: [a, 0, 196, 216],
              to: [b, 0, 196, 216],
              f0: 3,
              n: n,
            );
            final steps = s.steps();
            var last = a;
            for (final cam in steps) {
              expect(cam[0], isA<int>());
              expect(
                cam[0],
                b >= a ? greaterThanOrEqualTo(last) : lessThanOrEqualTo(last),
              );
              last = cam[0];
            }
            expect(steps.last, [b, 0, 196, 216]);
          }
        }
      }
    });

    test('a slide of 2x views moves in whole picture pixels too', () {
      final s = CamSlide(
        from: viewAt(0, 0, 2),
        to: viewAt(240, 216, 2),
        f0: 0,
        n: 12,
      );
      final steps = s.steps();
      expect(steps.length, 12);
      expect(steps.first[2], 98);
      expect(steps.last, [142, 108, 98, 108]);
    });
  });

  group('the review and level-check crop', () {
    // a picture whose every pixel says where it is: y * 240 + x + 1
    final pic = Uint32List.fromList([
      for (var i = 0; i < 240 * 216; i++) i + 1,
    ]);

    test('zoom 1: the 196 x 104 window, zoom 2: the 98 x 52 region', () {
      expect(reviewRegion(120, 108, 1), (x: 22, y: 56, w: 196, h: 104));
      expect(reviewRegion(120, 108, 2), (x: 71, y: 82, w: 98, h: 52));
    });
    test('edges and corners stay inside the picture', () {
      expect(reviewRegion(0, 0, 1), (x: 0, y: 0, w: 196, h: 104));
      expect(reviewRegion(240, 216, 1), (x: 44, y: 112, w: 196, h: 104));
      expect(reviewRegion(0, 216, 1), (x: 0, y: 112, w: 196, h: 104));
      expect(reviewRegion(240, 0, 1), (x: 44, y: 0, w: 196, h: 104));
      expect(reviewRegion(0, 0, 2), (x: 0, y: 0, w: 98, h: 52));
      expect(reviewRegion(240, 216, 2), (x: 142, y: 164, w: 98, h: 52));
      expect(reviewRegion(0, 216, 2), (x: 0, y: 164, w: 98, h: 52));
      expect(reviewRegion(240, 0, 2), (x: 142, y: 0, w: 98, h: 52));
      for (final zoom in [1, 2]) {
        for (final c in centres) {
          final r = reviewRegion(c[0], c[1], zoom);
          expect(r.w, 196 ~/ zoom);
          expect(r.h, 104 ~/ zoom);
          expect(r.x, inInclusiveRange(0, 240 - r.w));
          expect(r.y, inInclusiveRange(0, 216 - r.h));
        }
      }
    });
    test('odd and fractional centres round to a whole pixel', () {
      expect(reviewRegion(101, 109, 1), (x: 3, y: 57, w: 196, h: 104));
      expect(reviewRegion(100.5, 108.5, 1), (x: 3, y: 57, w: 196, h: 104));
      expect(reviewRegion(101, 109, 2), (x: 52, y: 83, w: 98, h: 52));
      expect(reviewRegion(100.49, 108.49, 2), (x: 51, y: 82, w: 98, h: 52));
    });
    test('zoom 1 copies the pixels as they are', () {
      final s = reviewCrop(pic, 240, 216, 120, 108, 1);
      expect([s.w, s.h, s.px.length], [196, 104, 196 * 104]);
      for (var j = 0; j < 104; j++) {
        for (var i = 0; i < 196; i++) {
          expect(s.px[j * 196 + i], pic[(56 + j) * 240 + 22 + i]);
        }
      }
    });
    test('zoom 2 draws each pixel as a 2 x 2 block', () {
      final s = reviewCrop(pic, 240, 216, 240, 216, 2);
      expect([s.w, s.h], [196, 104]);
      for (var j = 0; j < 104; j++) {
        for (var i = 0; i < 196; i++) {
          expect(s.px[j * 196 + i], pic[(164 + j ~/ 2) * 240 + 142 + i ~/ 2]);
        }
      }
      // the blocks: a pixel and its right and lower neighbours inside the block are the same
      expect(s.px[0], s.px[1]);
      expect(s.px[0], s.px[196]);
      expect(s.px[0], s.px[197]);
      expect(s.px[0], isNot(s.px[2]));
    });
    test('no other zoom exists', () {
      for (final z in [0, 3, 4]) {
        expect(() => reviewRegion(120, 108, z), throwsArgumentError);
        expect(
          () => reviewCrop(pic, 240, 216, 120, 108, z),
          throwsArgumentError,
        );
      }
    });
  });
}
