import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

/// Two 32-bit hashes of a buffer's bytes (FNV-1a, and the same with another prime), as 8 hex digits each: the same on
/// the vm and in a browser (32-bit steps with `imul`). Two buffers with the same hashes hold the same bytes.
String hashBytes(Uint8List bytes) {
  var a = 0x811C9DC5, b = 0x01234567;
  for (final x in bytes) {
    a = imul(a ^ x, 0x01000193) & 0xFFFFFFFF;
    b = imul(b ^ x, 0x5BD1E995) & 0xFFFFFFFF;
  }
  return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}

/// [hashBytes] of a typed list's bytes, little endian as the reference files are.
String hashOf(TypedData t) =>
    hashBytes(t.buffer.asUint8List(t.offsetInBytes, t.lengthInBytes));
