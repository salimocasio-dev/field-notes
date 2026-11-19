import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The bytes of a file under coqui/ref/pp/, by its path there, e.g. `map/hecho-3/pix.bin`.
Uint8List refBytes(String path) {
  for (final base in const ['../../../ref/pp', '../ref/pp', 'ref/pp']) {
    final f = File('$base/$path');
    if (f.existsSync()) return f.readAsBytesSync();
  }
  throw StateError(
    'coqui/ref/pp/$path not found from ${Directory.current.path}: '
    'run the tests in coqui/packages/features/feature_map',
  );
}

/// A text file under coqui/ref/pp/, as a string.
String refText(String path) => utf8.decode(refBytes(path));
