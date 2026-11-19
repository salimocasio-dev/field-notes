import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The bytes of a file under coqui/ref/, by its path there.
Uint8List refFile(String path) {
  for (final base in const ['../../../ref', '../ref', 'ref']) {
    final f = File('$base/$path');
    if (f.existsSync()) return f.readAsBytesSync();
  }
  throw StateError(
    'coqui/ref/$path not found from ${Directory.current.path}: '
    'run the tests in coqui/packages/core/coqui_pixel',
  );
}

/// A text file under coqui/ref/, as a string.
String refFileText(String path) => utf8.decode(refFile(path));
