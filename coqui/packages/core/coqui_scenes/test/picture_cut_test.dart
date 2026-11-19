// The size rule of a review or level picture (lib/src/picture_cut.dart): the picture is `width` x `height` picture
// pixels; a review picture shows the region of `width / zoom` x `height / zoom` pixels (the sheet's zoom, 1 or 2) centred
// on the centre of the sheet's `crop` for it, kept inside the 240 x 216 picture, each region pixel drawn as a zoom x zoom
// block. A cell of the level check is always zoom 1: a `width` x `height` region at the centre of its entry's crop.
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

  test('a cell of the level check is always zoom 1: a 96 x 106 region at the centre of its entry\'s crop', () {
    // the 9 cells of El frente: [x, y, w, h] of the region, by `<word> <index>`, whatever the zoom of their pair picture
    const want = {
      'abuela 0': [94, 48, 96, 106],
      'puerta 0': [123, 38, 96, 106],
      'puerta 1': [25, 22, 96, 106],
      'abre 0': [25, 22, 96, 106],
      'abre 1': [25, 22, 96, 106],
      'abre 2': [123, 38, 96, 106],
      'hola 0': [86, 60, 96, 106],
      'hola 1': [86, 60, 96, 106],
      'silla 3': [25, 22, 96, 106],
    };
    expect(sheet.level, hasLength(want.length));
    expect(
      {for (final l in sheet.level) l.zoom},
      {1, 2},
      reason: 'both zooms among the pair pictures',
    );
    for (final l in sheet.level) {
      final r = pictureRegion(
        crop: l.crop,
        zoom: l.zoom,
        level: true,
        width: 96,
        height: 106,
      );
      final key = '${l.word} ${l.index}';
      expect([r.x, r.y, r.w, r.h], want[key], reason: key);
      // inside the picture
      expect(r.x, inInclusiveRange(0, 240 - 96), reason: key);
      expect(r.y, inInclusiveRange(0, 216 - 106), reason: key);
      // its centre is the crop's centre, unless the region was pulled in to stay inside the picture
      final cx = l.crop[0] + l.crop[2] / 2, cy = l.crop[1] + l.crop[3] / 2;
      final clampedX = r.x == 0 || r.x == 240 - 96,
          clampedY = r.y == 0 || r.y == 216 - 106;
      if (!clampedX) expect(r.x + r.w / 2, cx, reason: '$key: x centre');
      if (!clampedY) expect(r.y + r.h / 2, cy, reason: '$key: y centre');
    }
  });

  test('a level cell ignores the zoom; a review picture keeps it', () {
    for (final zoom in [1, 2]) {
      final cell = pictureRegion(
        crop: [24, 49, 98, 52],
        zoom: zoom,
        level: true,
        width: 96,
        height: 106,
      );
      expect(cell, (x: 25, y: 22, w: 96, h: 106), reason: 'zoom $zoom');
    }
    // not even a zoom the sheet cannot have matters to a cell
    expect(
      pictureRegion(
        crop: [24, 49, 98, 52],
        zoom: 3,
        level: true,
        width: 96,
        height: 106,
      ),
      (x: 25, y: 22, w: 96, h: 106),
    );
    // the same crop as a review picture: 98 x 52 at zoom 2
    expect(
      pictureRegion(crop: [24, 49, 98, 52], zoom: 2, width: 196, height: 104),
      (x: 24, y: 49, w: 98, h: 52),
    );
    // a cell's size need not be even: at zoom 1 any whole size
    expect(
      pictureRegion(
        crop: [24, 49, 98, 52],
        zoom: 2,
        level: true,
        width: 97,
        height: 105,
      ).w,
      97,
    );
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
    // a crop that sticks out (its centre near the edge) is pulled in, whatever the size: a cell, and a review picture
    expect(
      pictureRegion(
        crop: [230, 210, 98, 52],
        zoom: 2,
        level: true,
        width: 96,
        height: 106,
      ),
      (x: 144, y: 110, w: 96, h: 106),
    );
    expect(
      pictureRegion(crop: [230, 210, 98, 52], zoom: 2, width: 96, height: 106),
      (x: 192, y: 163, w: 48, h: 53),
    );
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

  test('cutPicture draws a level cell one picture pixel per pixel, whatever the entry\'s zoom', () {
    final pic = Uint32List(pictureW * pictureH);
    for (var i = 0; i < pic.length; i++) {
      pic[i] = i;
    }
    final out = cutPicture(
      pic,
      crop: [24, 49, 98, 52],
      zoom: 2,
      level: true,
      width: 96,
      height: 106,
    );
    expect(out, hasLength(96 * 106));
    for (var j = 0; j < 106; j++) {
      for (var i = 0; i < 96; i++) {
        expect(
          out[j * 96 + i],
          (22 + j) * pictureW + 25 + i,
          reason: '($i, $j)',
        );
      }
    }
  });
}
