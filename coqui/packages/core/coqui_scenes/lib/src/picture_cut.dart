import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/picture_error.dart';

/// A region of a scene's picture: top-left `x`, `y` and size `w`, `h`, all whole picture pixels.
typedef PictureRegion = ({int x, int y, int w, int h});

// JavaScript: Math.round
int _round(num v) => (v + 0.5).floor();

/// The size rule of a review or level-check picture (page 12, section 3: `PictureSource.of`; section 5, "The camera").
///
/// The picture is [width] x [height] picture pixels. It shows a region of the scene's picture of `width / zoom` x
/// `height / zoom` pixels, each drawn as a [zoom] x [zoom] block (zoom 1 or 2, from the sheet's entry for the picture).
/// The region is centred on the centre of the sheet's [crop] for the picture and kept inside the scene's picture
/// ([picW] x [picH], 240 x 216), in whole pixels. At the default 196 x 104 the region is the sheet's [crop] itself; for a
/// cell of the level check (96 x 106) it is 96 x 106 at zoom 1 and 48 x 53 at zoom 2.
///
/// Throws [PictureError] when [zoom] is not 1 or 2, when [width] or [height] is not a whole number of [zoom] blocks (a
/// picture is never stretched by a fraction), or when the region does not fit in the scene's picture.
PictureRegion pictureRegion({
  required List<num> crop,
  required int zoom,
  required int width,
  required int height,
  int picW = pictureW,
  int picH = pictureH,
}) {
  if (zoom != 1 && zoom != 2) {
    throw PictureError('a picture has zoom 1 or 2, not $zoom');
  }
  if (width <= 0 || height <= 0) {
    throw PictureError('a picture is at least 1 x 1, not $width x $height');
  }
  if (width % zoom != 0 || height % zoom != 0) {
    throw PictureError(
      'a $width x $height picture at zoom $zoom would show a region of '
      '${width / zoom} x ${height / zoom} pixels: not whole numbers, and a '
      'picture is never stretched by a fraction',
    );
  }
  final w = width ~/ zoom, h = height ~/ zoom;
  if (w > picW || h > picH) {
    throw PictureError(
      'a $width x $height picture at zoom $zoom needs a region of $w x $h '
      'pixels; the scene\'s picture is only $picW x $picH',
    );
  }
  final cx = crop[0] + crop[2] / 2, cy = crop[1] + crop[3] / 2;
  return (
    x: math.max(0, math.min(_round(cx - w / 2), picW - w)),
    y: math.max(0, math.min(_round(cy - h / 2), picH - h)),
    w: w,
    h: h,
  );
}

/// The picture itself: [width] x [height] pixels cut from [picture] (`picW` x `picH`) as [pictureRegion] says, each pixel
/// of the region drawn [zoom] x [zoom]. No stretch.
Uint32List cutPicture(
  Uint32List picture, {
  required List<num> crop,
  required int zoom,
  required int width,
  required int height,
  int picW = pictureW,
  int picH = pictureH,
}) {
  final r = pictureRegion(
    crop: crop,
    zoom: zoom,
    width: width,
    height: height,
    picW: picW,
    picH: picH,
  );
  final out = Uint32List(width * height);
  for (var j = 0; j < height; j++) {
    final row = (r.y + j ~/ zoom) * picW + r.x;
    for (var i = 0; i < width; i++) {
      out[j * width + i] = picture[row + i ~/ zoom];
    }
  }
  return out;
}
