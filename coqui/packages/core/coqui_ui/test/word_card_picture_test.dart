import 'dart:typed_data';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 0xAABBGGRR
const _colours = [0xFF0000FF, 0xFF00FF00, 0xFFFF0000, 0xFF00FFFF];

/// The card's own surface, white (`.wc{background:#fff}`, app.html:88): what shows round the picture.
const _back = 0xFFFFFFFF;

Uint32List _checker(int w, int h) {
  final p = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      p[y * w + x] = _colours[(x & 1) + 2 * (y & 1)];
    }
  }
  return p;
}

/// A word card [cardWidth] CSS px wide (v=39's grid cell on a phone), a 196 x 104
/// picture in it, taken at [ratio]. Checks the picture is at scale [scale], centred,
/// every device pixel its picture pixel, on the card's own surface.
Future<void> _check(
  WidgetTester tester, {
  required double ratio,
  required double screenWidth,
  required double cardWidth,
  required int scale,
}) async {
  tester.view.devicePixelRatio = ratio;
  tester.view.physicalSize = Size(screenWidth * ratio, 800 * ratio);
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  final pic = _checker(196, 104);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: SizedBox(
              width: cardWidth,
              child: WordCard(
                word: 'word',
                ear: 1,
                mouth: 0,
                picture: PixelView(pixels: pic, width: 196, height: 104),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final img = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = (await image.toByteData())!;
    final px = Uint32List(image.width * image.height);
    final view = ByteData.sublistView(data);
    for (var i = 0; i < px.length; i++) {
      px[i] = view.getUint32(i * 4, Endian.little);
    }
    final r = (w: image.width, h: image.height, px: px);
    image.dispose();
    return r;
  });
  final w = img!.w;
  final px = img.px;

  // The picture area is as wide as the card and 196:104.
  final areaH = cardWidth * 104 / 196 * ratio;
  var minX = w, minY = 1 << 30, maxX = -1, maxY = -1;
  for (var y = 0; y < areaH.floor(); y++) {
    for (var x = 0; x < w; x++) {
      if (_colours.contains(px[y * w + x])) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  final blockW = maxX - minX + 1;
  final blockH = maxY - minY + 1;
  expect(blockW, 196 * scale, reason: 'drawn width in device pixels');
  expect(blockH, 104 * scale, reason: 'drawn height in device pixels');

  // Centred: the bands each side differ by at most one device pixel (the origin is
  // snapped to the pixel grid), and the bands above and below likewise.
  final cardDeviceW = cardWidth * ratio;
  final left = minX.toDouble();
  final right = cardDeviceW - (maxX + 1);
  expect((left - right).abs(), lessThanOrEqualTo(1.0 + 1e-9));
  final top = minY.toDouble();
  final bottom = areaH - (maxY + 1);
  expect((top - bottom).abs(), lessThanOrEqualTo(1.0 + 1e-9));

  // Every device pixel of the block is its picture pixel.
  var wrong = 0;
  for (var y = 0; y < blockH; y++) {
    for (var x = 0; x < blockW; x++) {
      final want = pic[(y ~/ scale) * 196 + (x ~/ scale)];
      if (px[(minY + y) * w + (minX + x)] != want) wrong++;
    }
  }
  expect(wrong, 0, reason: 'device pixels that are not their picture pixel');

  // The bands are the card's own surface (white), not a stretch of the picture and not a frame.
  final midY = (minY + maxY) ~/ 2;
  expect(px[midY * w + (minX - 3)], _back);
  expect(px[midY * w + (maxX + 4)], _back);
  final midX = (minX + maxX) ~/ 2;
  expect(px[(minY - 3) * w + midX], _back);
  expect(px[(maxY + 4) * w + midX], _back);

  // The band each side, in CSS px, is what a whole scale leaves of the card's width.
  expect(
    left / ratio,
    closeTo((cardWidth - 196 * scale / ratio) / 2, 1 / ratio),
  );
}

void main() {
  testWidgets(
    'Android: a 196 x 104 picture in a 182 px card at ratio 2.625 is drawn at '
    'scale 2 (392 x 208 device pixels), centred, on the card surface',
    (tester) async {
      await _check(
        tester,
        ratio: 2.625,
        screenWidth: 412,
        cardWidth: 182,
        scale: 2,
      );
    },
  );

  testWidgets('iPhone: a 196 x 104 picture in a 171 px card at ratio 3 is drawn at scale 2 '
      '(392 x 208 device pixels), centred', (tester) async {
    await _check(tester, ratio: 3, screenWidth: 390, cardWidth: 171, scale: 2);
  });

  testWidgets(
    'the picture area keeps its height (card width x 104 / 196) whatever the scale',
    (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412 * 2.625, 800 * 2.625);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 182,
                child: WordCard(
                  word: 'word',
                  ear: 1,
                  mouth: 0,
                  picture: PixelView(
                    pixels: Uint32List(196 * 104),
                    width: 196,
                    height: 104,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final area = tester.getSize(find.byType(AspectRatio));
      expect(area.width, 182);
      expect(area.height, closeTo(182 * 104 / 196, 1e-9));
    },
  );
}
