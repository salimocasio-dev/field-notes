// The placeholder icons of the web app. A plain flat square in the theme colour with a white "C".
// Made here, from nothing: no artwork is copied from anywhere. The real coquí icon comes after
// order 11 and replaces these files.
//
//   dart run tool/make_icons.dart            (at coqui/; writes into app/web/)
//
// Writes app/web/favicon.png (32), app/web/icons/Icon-192.png, Icon-512.png and the maskable
// pair Icon-maskable-192.png, Icon-maskable-512.png. The output is the same on every run.
//
// Pure Dart, dart:io only. The colour is the old app's `theme-color` (historia/app.html).
// The "C" fits inside a circle of 0.30 of the icon's width around its middle, so the maskable
// icons stay whole when a phone crops them (the safe zone is a circle of 0.40).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// #5C94FC, the old app's `theme-color`.
const _square = [0x5C, 0x94, 0xFC];

/// White.
const _letter = [0xFF, 0xFF, 0xFF];

void main(List<String> args) {
  final web = Directory('app/web');
  if (!web.existsSync()) {
    stderr.writeln('Run this at coqui/: app/web was not found.');
    exit(1);
  }
  Directory('app/web/icons').createSync(recursive: true);
  _write('app/web/favicon.png', 32);
  _write('app/web/icons/Icon-192.png', 192);
  _write('app/web/icons/Icon-512.png', 512);
  // The art is full-bleed in every file; the maskable files are the same picture under the names
  // the manifest gives them the "maskable" purpose.
  _write('app/web/icons/Icon-maskable-192.png', 192);
  _write('app/web/icons/Icon-maskable-512.png', 512);
}

void _write(String path, int size) {
  File(path).writeAsBytesSync(_png(size, _pixels(size)));
  stdout.writeln('$path ${size}x$size');
}

/// RGB bytes, row by row. The C is a ring with its right side opened, drawn with 4 x 4 samples
/// per pixel so its edge is smooth.
Uint8List _pixels(int size) {
  const samples = 4;
  final centre = size / 2;
  final outer = 0.30 * size;
  final inner = 0.19 * size;
  const opening = 0.70; // radians either side of "straight right"
  final out = Uint8List(size * size * 3);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      var inside = 0;
      for (var sy = 0; sy < samples; sy++) {
        for (var sx = 0; sx < samples; sx++) {
          final dx = x + (sx + 0.5) / samples - centre;
          final dy = y + (sy + 0.5) / samples - centre;
          final d = math.sqrt(dx * dx + dy * dy);
          if (d < inner || d > outer) continue;
          if (math.atan2(dy, dx).abs() < opening) continue;
          inside++;
        }
      }
      final cover = inside / (samples * samples);
      final i = (y * size + x) * 3;
      for (var c = 0; c < 3; c++) {
        out[i + c] = (_square[c] + (_letter[c] - _square[c]) * cover).round();
      }
    }
  }
  return out;
}

/// A PNG of 8-bit RGB. No dependency: the chunks, the CRC and zlib from dart:io.
Uint8List _png(int size, Uint8List rgb) {
  final raw = BytesBuilder();
  for (var y = 0; y < size; y++) {
    raw.addByte(0); // filter: none
    raw.add(Uint8List.sublistView(rgb, y * size * 3, (y + 1) * size * 3));
  }
  final ihdr = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2); // colour type: RGB
  final png = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', ihdr.buffer.asUint8List()))
    ..add(_chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes())))
    ..add(_chunk('IEND', const []));
  return png.toBytes();
}

Uint8List _chunk(String type, List<int> data) {
  final body = BytesBuilder()
    ..add(type.codeUnits)
    ..add(data);
  final bytes = body.toBytes();
  final out = ByteData(8 + data.length + 4);
  out.setUint32(0, data.length);
  Uint8List.sublistView(out).setRange(4, 4 + bytes.length, bytes);
  out.setUint32(8 + data.length, _crc32(bytes));
  return Uint8List.sublistView(out);
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
