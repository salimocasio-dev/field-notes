import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:coqui_ui/src/pixel_view.dart' show RenderPixelView;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 0xAABBGGRR
const red = 0xFF0000FF;
const green = 0xFF00FF00;
const blue = 0xFFFF0000;
const yellow = 0xFF00FFFF;

Uint32List _picture(int w, int h, int Function(int x, int y) at) {
  final p = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      p[y * w + x] = at(x, y);
    }
  }
  return p;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 120)),
  );
  await tester.pump();
}

/// The boundary's pixels as 0xAABBGGRR values, width x height in device pixels.
Future<({int w, int h, Uint32List px})> _capture(
  WidgetTester tester,
  GlobalKey key,
  double ratio,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData();
    final bytes = data!.buffer.asUint8List();
    final px = Uint32List(image.width * image.height);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < px.length; i++) {
      px[i] = view.getUint32(i * 4, Endian.little);
    }
    final r = (w: image.width, h: image.height, px: px);
    image.dispose();
    return r;
  });
  return result!;
}

RenderPixelView _ro(WidgetTester tester) {
  RenderPixelView? found;
  void visit(Element e) {
    final r = e.renderObject;
    if (r is RenderPixelView) {
      found = r;
      return;
    }
    e.visitChildren(visit);
  }

  visit(tester.element(find.byType(PixelView)));
  return found!;
}

void main() {
  group('pixelViewScale', () {
    test('196 wide in 412 at 2.625 is 5', () {
      expect(
        pixelViewScale(
          availableWidth: 412,
          devicePixelRatio: 2.625,
          width: 196,
        ),
        5,
      );
    });
    test('a hair of floating point noise does not lose a whole step', () {
      expect(
        pixelViewScale(
          availableWidth: 980 / 2.625,
          devicePixelRatio: 2.625,
          width: 196,
        ),
        5,
      );
    });
    test('never below 1', () {
      for (final w in [0.0, 1.0, 50.0, 74.0]) {
        expect(
          pixelViewScale(
            availableWidth: w,
            devicePixelRatio: 2.625,
            width: 196,
          ),
          1,
        );
      }
    });
    test('whole numbers at other ratios', () {
      expect(
        pixelViewScale(availableWidth: 380, devicePixelRatio: 3, width: 196),
        5,
      );
      expect(
        pixelViewScale(availableWidth: 390, devicePixelRatio: 3, width: 196),
        5,
      );
      expect(
        pixelViewScale(availableWidth: 800, devicePixelRatio: 1, width: 196),
        4,
      );
    });
  });

  group('PixelView layout', () {
    testWidgets(
      '196 x 216 in a 412 wide screen at 2.625: 5 device pixels a pixel, '
      '980 x 1080 device pixels',
      (tester) async {
        tester.view.devicePixelRatio = 2.625;
        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        addTearDown(tester.view.reset);
        final pixels = Uint32List(196 * 216);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: PixelView(pixels: pixels, width: 196, height: 216),
            ),
          ),
        );
        final ro = _ro(tester);
        expect(ro.scale, 5);
        expect(ro.deviceSize, const Size(980, 1080));
        final size = tester.getSize(find.byType(PixelView));
        expect(size.width * 2.625, closeTo(980, 1e-6));
        expect(size.height * 2.625, closeTo(1080, 1e-6));
      },
    );

    testWidgets('a narrow box gives scale 1, never 0', (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      addTearDown(tester.view.reset);
      for (final w in [60.0, 40.0, 1.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: w,
                child: PixelView(
                  pixels: Uint32List(196 * 216),
                  width: 196,
                  height: 216,
                ),
              ),
            ),
          ),
        );
        final ro = _ro(tester);
        expect(ro.scale, 1, reason: 'box $w');
        expect(
          tester.getSize(find.byType(PixelView)).width,
          lessThanOrEqualTo(w),
        );
      }
    });

    testWidgets('with no width limit it takes the picture\'s own width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: UnconstrainedBox(
            alignment: Alignment.topLeft,
            child: PixelView(pixels: Uint32List(4 * 4), width: 4, height: 4),
          ),
        ),
      );
      final ro = _ro(tester);
      expect(ro.scale, 2);
      expect(_ro(tester).size, const Size(4, 4));
    });
  });

  group('PixelView drawing', () {
    // A 4 x 2 picture: red green / blue yellow, twice over.
    final quad = _picture(
      4,
      2,
      (x, y) => [red, green, blue, yellow][(x ~/ 2) + 2 * (y)],
    );

    testWidgets('blocks of whole device pixels, nothing in between, on a '
        'fractional ratio and a fractional position', (tester) async {
      const ratio = 2.625;
      tester.view.devicePixelRatio = ratio;
      tester.view.physicalSize = const Size(412 * ratio, 915 * ratio);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      // 4 picture pixels, available 8 logical = 21 device pixels: scale 5.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0.3, 0.7, 0, 0),
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 8,
                  child: PixelView(pixels: quad, width: 4, height: 2),
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      final img = await _capture(tester, key, ratio);
      // The boundary is at a fractional place, so find the drawn block.
      var minX = img.w, minY = img.h, maxX = -1, maxY = -1;
      final colours = <int>{};
      for (var y = 0; y < img.h; y++) {
        for (var x = 0; x < img.w; x++) {
          final c = img.px[y * img.w + x];
          if (c >>> 24 != 0) {
            colours.add(c);
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
      expect(colours, {red, green, blue, yellow}, reason: 'no blended colours');
      // 4 x 2 picture pixels at 5 device pixels each, give or take the
      // boundary's own rounding of its fractional edge (one device pixel).
      final w = maxX - minX + 1;
      final h = maxY - minY + 1;
      expect(w, inInclusiveRange(20, 21));
      expect(h, inInclusiveRange(10, 11));
      // Inside the block, each run of one colour is whole blocks of 5.
      final row = <int>[];
      for (var x = minX; x <= maxX; x++) {
        row.add(img.px[minY * img.w + x]);
      }
      final runs = <int>[];
      var run = 1;
      for (var i = 1; i < row.length; i++) {
        if (row[i] == row[i - 1]) {
          run++;
        } else {
          runs.add(run);
          run = 1;
        }
      }
      runs.add(run);
      expect(runs.every((r) => r >= 5), isTrue, reason: 'runs: $runs');
    });

    testWidgets(
      '196 x 216 in a 412 wide screen at 2.625 is drawn as 980 x 1080 '
      'device pixels, each picture pixel a block of 5, unsmoothed',
      (tester) async {
        const ratio = 2.625;
        tester.view.devicePixelRatio = ratio;
        tester.view.physicalSize = const Size(412 * ratio, 915 * ratio);
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        // A checker of the four colours, so every picture pixel differs from its neighbours.
        final pic = _picture(
          196,
          216,
          (x, y) => [red, green, blue, yellow][(x & 1) + 2 * (y & 1)],
        );
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: 412,
                  height: 500,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: PixelView(pixels: pic, width: 196, height: 216),
                  ),
                ),
              ),
            ),
          ),
        );
        await _settle(tester);
        final img = await _capture(tester, key, ratio);
        var maxX = -1;
        var maxY = -1;
        for (var y = 0; y < img.h; y++) {
          for (var x = 0; x < img.w; x++) {
            final c = img.px[y * img.w + x];
            if (c >>> 24 != 0) {
              if (x > maxX) maxX = x;
              if (y > maxY) maxY = y;
            }
          }
        }
        expect(maxX + 1, 980, reason: 'drawn width in device pixels');
        expect(maxY + 1, 1080, reason: 'drawn height in device pixels');
        var wrong = 0;
        for (var y = 0; y < 1080; y++) {
          for (var x = 0; x < 980; x++) {
            if (img.px[y * img.w + x] != pic[(y ~/ 5) * 196 + (x ~/ 5)])
              wrong++;
          }
        }
        expect(
          wrong,
          0,
          reason: 'device pixels that are not their picture pixel',
        );
      },
    );

    testWidgets('exact block edges at a whole ratio', (tester) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(400, 400);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 10, // 20 device pixels for 4 picture pixels: scale 5
                child: PixelView(pixels: quad, width: 4, height: 2),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      final img = await _capture(tester, key, 2.0);
      expect(img.w, 20);
      expect(img.h, 10);
      for (var y = 0; y < 10; y++) {
        for (var x = 0; x < 20; x++) {
          final px = x ~/ 5;
          final py = y ~/ 5;
          final want = [red, green, blue, yellow][(px ~/ 2) + 2 * py];
          expect(img.px[y * 20 + x], want, reason: 'device pixel ($x, $y)');
        }
      }
    });

    testWidgets('repaints when its repaint fires, and not otherwise', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 2.0;
      tester.view.physicalSize = const Size(400, 400);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      final tick = ChangeNotifier();
      addTearDown(tick.dispose);
      final pixels = _picture(2, 2, (x, y) => red);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: 2,
                child: PixelView(
                  pixels: pixels,
                  width: 2,
                  height: 2,
                  repaint: tick,
                ),
              ),
            ),
          ),
        ),
      );
      await _settle(tester);
      final ro = _ro(tester);
      var img = await _capture(tester, key, 2.0);
      expect(img.px.every((c) => c == red), isTrue, reason: 'first picture');

      // The game draws into the list but does not tick: nothing is redrawn.
      pixels.fillRange(0, pixels.length, green);
      final before = ro.paintCount;
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        await _settle(tester);
      }
      expect(ro.paintCount, before, reason: 'no tick, no paint');
      img = await _capture(tester, key, 2.0);
      expect(
        img.px.every((c) => c == red),
        isTrue,
        reason: 'still the old one',
      );

      // The tick: the new pixels are drawn.
      tick.notifyListeners();
      await _settle(tester);
      expect(ro.paintCount, greaterThan(before), reason: 'the tick repaints');
      img = await _capture(tester, key, 2.0);
      expect(
        img.px.every((c) => c == green),
        isTrue,
        reason: 'the new picture',
      );

      // And then it is still again.
      final after = ro.paintCount;
      await tester.pump(const Duration(milliseconds: 16));
      await _settle(tester);
      expect(ro.paintCount, after);
    });

    testWidgets('a different pixel list is a new picture', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(100, 100);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Widget build(Uint32List p) => Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: 2,
              child: PixelView(pixels: p, width: 2, height: 2),
            ),
          ),
        ),
      );
      await tester.pumpWidget(build(_picture(2, 2, (x, y) => red)));
      await _settle(tester);
      await tester.pumpWidget(build(_picture(2, 2, (x, y) => blue)));
      await _settle(tester);
      final img = await _capture(tester, key, 1.0);
      expect(img.px.every((c) => c == blue), isTrue);
    });
  });

  group('PixelView taps', () {
    testWidgets('onTapPixel returns the picture pixel at the corners and the '
        'centre', (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      addTearDown(tester.view.reset);
      final taps = <(int, int)>[];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: PixelView(
              pixels: Uint32List(196 * 216),
              width: 196,
              height: 216,
              onTapPixel: (x, y) => taps.add((x, y)),
            ),
          ),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(PixelView));
      // One device pixel is 1/2.625 logical; a picture pixel is 5 device pixels.
      Offset dev(double dx, double dy) =>
          topLeft + Offset(dx / 2.625, dy / 2.625);
      await tester.tapAt(dev(0.5, 0.5)); // the first device pixel
      await tester.tapAt(dev(979.5, 1079.5)); // the last device pixel
      await tester.tapAt(dev(979.5, 0.5)); // top right
      await tester.tapAt(dev(0.5, 1079.5)); // bottom left
      await tester.tapAt(dev(490, 540)); // the centre: 98, 108
      await tester.tapAt(dev(4.5, 4.5)); // still pixel 0, 0
      await tester.tapAt(dev(5.5, 5.5)); // 1, 1
      expect(taps, [
        (0, 0),
        (195, 215),
        (195, 0),
        (0, 215),
        (98, 108),
        (0, 0),
        (1, 1),
      ]);
    });

    testWidgets('no onTapPixel: a tap does nothing and nothing breaks', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PixelView(pixels: Uint32List(4), width: 2, height: 2),
        ),
      );
      await tester.tap(find.byType(PixelView));
    });
  });
}
