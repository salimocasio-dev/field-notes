import 'dart:io';
import 'dart:typed_data';

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return (c ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// A picture (`0xAABBGGRR` pixels) as PNG bytes, each pixel [scale] × [scale] (nearest neighbour). On the vm only.
Uint8List encodePng(Uint32List pixels, int w, int h, {int scale = 1}) {
  final W = w * scale, H = h * scale;
  final raw = BytesBuilder();
  for (var y = 0; y < H; y++) {
    raw.addByte(0);
    final row = Uint8List(W * 4);
    for (var x = 0; x < W; x++) {
      final p = pixels[(y ~/ scale) * w + x ~/ scale];
      row[x * 4] = p & 255;
      row[x * 4 + 1] = (p >> 8) & 255;
      row[x * 4 + 2] = (p >> 16) & 255;
      row[x * 4 + 3] = (p >> 24) & 255;
    }
    raw.add(row);
  }
  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);
  void chunk(String type, List<int> data) {
    final len = ByteData(4)..setUint32(0, data.length);
    out.add(len.buffer.asUint8List());
    final td = [...type.codeUnits, ...data];
    out.add(td);
    final crc = ByteData(4)..setUint32(0, _crc(td));
    out.add(crc.buffer.asUint8List());
  }

  final ihdr = ByteData(13)
    ..setUint32(0, W)
    ..setUint32(4, H)
    ..setUint8(8, 8)
    ..setUint8(9, 6)
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  chunk('IHDR', ihdr.buffer.asUint8List());
  chunk('IDAT', ZLibEncoder(level: 9).convert(raw.toBytes()));
  chunk('IEND', const []);
  return out.toBytes();
}

/// Writes [pixels] as a PNG file.
void writePng(String path, Uint32List pixels, int w, int h, {int scale = 1}) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(encodePng(pixels, w, h, scale: scale));
}
