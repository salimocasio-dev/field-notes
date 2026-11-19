// Contact sheets for the pictures of `gate_a_frames_test.dart`: four pictures side by side in play order, each one halved
// (780 x 1688 to 390 x 844: every output pixel is the mean of a 2 x 2 block), a thin gap between, and the picture's number
// in digits above it. No other writing on a sheet.
//
// `makeSheets` needs the real event loop (`dart:ui` codecs): call it inside `tester.runAsync`.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Pictures to a sheet.
const int sheetPictures = 4;

/// One picture on a sheet, in pixels.
const int sheetPictureWidth = 390, sheetPictureHeight = 844;

const int _gap = 12, _margin = 12, _digitScale = 4, _labelHeight = 36;
const int _background = 0xFFE6E6E6, _ink = 0xFF202020;

// 3 x 5 digits, one row per string
const List<List<String>> _digits = [
  ['111', '101', '101', '101', '111'],
  ['010', '110', '010', '010', '111'],
  ['111', '001', '111', '100', '111'],
  ['111', '001', '111', '001', '111'],
  ['101', '101', '111', '001', '001'],
  ['111', '100', '111', '001', '111'],
  ['111', '100', '111', '101', '111'],
  ['111', '001', '010', '010', '010'],
  ['111', '101', '111', '101', '111'],
  ['111', '101', '111', '001', '111'],
];

class _Raw {
  _Raw(this.width, this.height, this.rgba);
  final int width, height;
  final Uint8List rgba;
}

Future<_Raw> _decode(File file) async {
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = (await image.toByteData())!;
  final raw = _Raw(
    image.width,
    image.height,
    Uint8List.fromList(data.buffer.asUint8List()),
  );
  image.dispose();
  codec.dispose();
  return raw;
}

Future<Uint8List> _png(Uint8List rgba, int width, int height) async {
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  final image = await done.future;
  final data = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  image.dispose();
  return Uint8List.fromList(data.buffer.asUint8List());
}

void _fill(Uint8List px, int w, int x, int y, int bw, int bh, int argb) {
  final r = (argb >> 16) & 255, g = (argb >> 8) & 255, b = argb & 255;
  for (var j = y; j < y + bh; j++) {
    for (var i = x; i < x + bw; i++) {
      final o = (j * w + i) * 4;
      px[o] = r;
      px[o + 1] = g;
      px[o + 2] = b;
      px[o + 3] = 255;
    }
  }
}

/// The picture [src] at 390 x 844 on [dst] (a sheet [dw] wide) with its top left at ([x], [y]): halved by the mean of
/// each 2 x 2 block when it is exactly twice the size, else the nearest pixel.
void _blit(Uint8List dst, int dw, int x, int y, _Raw src) {
  final exact =
      src.width == sheetPictureWidth * 2 &&
      src.height == sheetPictureHeight * 2;
  for (var j = 0; j < sheetPictureHeight; j++) {
    for (var i = 0; i < sheetPictureWidth; i++) {
      final o = ((y + j) * dw + x + i) * 4;
      if (exact) {
        for (var c = 0; c < 4; c++) {
          var s = 0;
          for (var dy = 0; dy < 2; dy++) {
            for (var dx = 0; dx < 2; dx++) {
              s += src.rgba[((2 * j + dy) * src.width + 2 * i + dx) * 4 + c];
            }
          }
          dst[o + c] = (s + 2) >> 2;
        }
      } else {
        final sx = i * src.width ~/ sheetPictureWidth,
            sy = j * src.height ~/ sheetPictureHeight;
        for (var c = 0; c < 4; c++) {
          dst[o + c] = src.rgba[(sy * src.width + sx) * 4 + c];
        }
      }
    }
  }
}

/// Writes [number]'s digits with their top left at ([x], [y]).
void _label(Uint8List px, int w, int x, int y, int number) {
  var cx = x;
  for (final ch in number.toString().split('')) {
    final rows = _digits[int.parse(ch)];
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 3; c++) {
        if (rows[r][c] == '1') {
          _fill(
            px,
            w,
            cx + c * _digitScale,
            y + r * _digitScale,
            _digitScale,
            _digitScale,
            _ink,
          );
        }
      }
    }
    cx += 4 * _digitScale;
  }
}

/// The pictures `NN-<kind>.png` of [dir], in number order, as `sheet-01.png`, `sheet-02.png` ... in [dir] (old sheets are
/// removed first). Returns how many sheets were written.
Future<int> makeSheets(Directory dir) async {
  for (final f in dir.listSync().whereType<File>()) {
    if (RegExp(r'sheet-\d+\.png$').hasMatch(f.path)) f.deleteSync();
  }
  final pictures = [
    for (final f in dir.listSync().whereType<File>())
      if (RegExp(r'/\d+-[a-z]+\.png$').hasMatch(f.path)) f,
  ]..sort((a, b) => a.path.compareTo(b.path));
  final sheetWidth =
      _margin * 2 +
      sheetPictures * sheetPictureWidth +
      (sheetPictures - 1) * _gap;
  final sheetHeight = _margin * 2 + _labelHeight + sheetPictureHeight;
  var sheets = 0;
  for (var from = 0; from < pictures.length; from += sheetPictures) {
    final px = Uint8List(sheetWidth * sheetHeight * 4);
    _fill(px, sheetWidth, 0, 0, sheetWidth, sheetHeight, _background);
    for (var slot = 0; slot < sheetPictures; slot++) {
      if (from + slot >= pictures.length) break;
      final file = pictures[from + slot];
      final number = int.parse(file.uri.pathSegments.last.split('-').first);
      final x = _margin + slot * (sheetPictureWidth + _gap);
      _label(px, sheetWidth, x, _margin + 8, number);
      _blit(px, sheetWidth, x, _margin + _labelHeight, await _decode(file));
    }
    sheets++;
    final name = sheets.toString().padLeft(2, '0');
    File('${dir.path}/sheet-$name.png')
        .writeAsBytesSync(await _png(px, sheetWidth, sheetHeight));
  }
  return sheets;
}
