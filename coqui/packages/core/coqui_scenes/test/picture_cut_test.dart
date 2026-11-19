// The size rule of a review or level picture (lib/src/picture_cut.dart): the picture is `width` x `height` picture
// pixels; it shows the region of `width / zoom` x `height / zoom` pixels centred on the centre of the sheet's `crop` for
// it, kept inside the 240 x 216 picture, each region pixel drawn as a zoom x zoom block.
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/picture_cut.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures/sheets.dart';

void main() {
  final sheet = Sheet.parse(sheetTexts['frente']!);

  test('at 196 x 104 the region is the sheet\'s crop, for all 24 pictures', () {
    expect(sheet.pictures, hasLength(24));
    for (final e in sheet.pictures.entries) {
      final r = pictureRegion(
        crop: e.value.crop,
        zoom: e.value.zoom,
        width: 196,
        height: 104,
      );
      expect([r.x, r.y, r.w, r.h], e.value.crop, reason: e.key);
      expect(
        [r.w, r.h],
        [196 ~/ e.value.zoom, 104 ~/ e.value.zoom],
        reason: e.key,
      );
    }
  });

  test('a cell of the level check is 96 x 106: 96 x 106 at zoom 1, 48 x 53 at zoom 2', () {
    // the 9 cells of El frente: [x, y, w, h] of the region, by `<word> <index>`
    const want = {
      'abuela 0': [94, 48, 96, 106],
      'puerta 0': [147, 65, 48, 53],
      'puerta 1': [49, 49, 48, 53],
      'abre 0': [49, 49, 48, 53],
      'abre 1': [49, 49, 48, 53],
      'abre 2': [147, 65, 48, 53],
      'hola 0': [86, 60, 96, 106],
      'hola 1': [86, 60, 96, 106],
      'silla 3': [49, 49, 48, 53],
    };
    expect(sheet.level, hasLength(want.length));
    for (final l in sheet.level) {
      final r = pictureRegion(
        crop: l.crop,
        zoom: l.zoom,
        width: 96,
        height: 106,
      );
      final key = '${l.word} ${l.index}';
      expect([r.x, r.y, r.w, r.h], want[key], reason: key);
      // centred on the centre of the crop, to the half pixel (the odd height of a zoom-2 cell has no middle row)
      final cx = l.crop[0] + l.crop[2] / 2, cy = l.crop[1] + l.crop[3] / 2;
      expect((r.x + r.w / 2 - cx).abs(), lessThanOrEqualTo(.5), reason: key);
      expect((r.y + r.h / 2 - cy).abs(), lessThanOrEqualTo(.5), reason: key);
    }
  });

  test('the region is kept inside the scene\'s picture', () {
    ({int x, int y, int w, int h}) at(int x, int y, int zoom) => pictureRegion(
      crop: [x, y, 196 ~/ zoom, 104 ~/ zoom],
      zoom: zoom,
      width: 196,
      height: 104,
    );
    expect(at(0, 0, 2), (x: 0, y: 0, w: 98, h: 52));
    expect(at(200, 190, 2), (x: 142, y: 164, w: 98, h: 52));
    expect(at(0, 0, 1), (x: 0, y: 0, w: 196, h: 104));
    expect(at(200, 190, 1), (x: 44, y: 112, w: 196, h: 104));
    // a crop that sticks out (its centre near the edge) is pulled in, whatever the size
    final r = pictureRegion(
      crop: [230, 210, 98, 52],
      zoom: 2,
      width: 96,
      height: 106,
    );
    expect(r, (x: 192, y: 163, w: 48, h: 53));
  });

  test('a size that is not whole blocks fails, and so does a zoom that is not 1 or 2', () {
    PictureError? failure(void Function() f) {
      try {
        f();
      } on PictureError catch (e) {
        return e;
      }
      return null;
    }

    void region(int zoom, int width, int height) => pictureRegion(
      crop: [24, 49, 98, 52],
      zoom: zoom,
      width: width,
      height: height,
    );
    expect(failure(() => region(2, 97, 106)), isNotNull);
    expect(failure(() => region(2, 96, 105)), isNotNull);
    expect(
      failure(() => region(2, 97, 106))!.message,
      allOf(contains('97 x 106'), contains('not whole numbers')),
    );
    expect(
      failure(() => region(1, 97, 105)),
      isNull,
      reason: 'zoom 1: any whole size',
    );
    expect(failure(() => region(3, 96, 108)), isNotNull);
    expect(failure(() => region(0, 96, 108)), isNotNull);
    expect(failure(() => region(1, 0, 104)), isNotNull);
    expect(failure(() => region(1, 196, -2)), isNotNull);
    expect(
      failure(() => region(1, 300, 104))!.message,
      contains('only 240 x 216'),
      reason: 'a region wider than the scene\'s picture does not fit',
    );
    expect(failure(() => region(2, 480, 216)), isNull);
    expect(failure(() => region(2, 482, 216)), isNotNull);
  });

  test('cutPicture draws each region pixel as a zoom x zoom block', () {
    // a picture whose every pixel is its own number
    final pic = Uint32List(pictureW * pictureH);
    for (var i = 0; i < pic.length; i++) {
      pic[i] = i;
    }
    for (final zoom in [1, 2]) {
      const w = 12, h = 8;
      final out = cutPicture(
        pic,
        crop: [100, 60, 20, 16],
        zoom: zoom,
        width: w,
        height: h,
      );
      expect(out, hasLength(w * h));
      // the region is w/zoom x h/zoom, centred on (110, 68)
      final rw = w ~/ zoom, rh = h ~/ zoom;
      final rx = 110 - rw ~/ 2, ry = 68 - rh ~/ 2;
      for (var j = 0; j < h; j++) {
        for (var i = 0; i < w; i++) {
          expect(
            out[j * w + i],
            (ry + j ~/ zoom) * pictureW + rx + i ~/ zoom,
            reason: 'zoom $zoom, ($i, $j)',
          );
        }
      }
    }
  });
}
