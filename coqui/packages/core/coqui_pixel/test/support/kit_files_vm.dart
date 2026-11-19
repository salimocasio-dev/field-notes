import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// The bytes of a file under coqui/ref/sprites/kit/, by its name there.
Uint8List kitFile(String name) {
  for (final base in const ['../../../ref', '../ref', 'ref']) {
    final f = File('$base/sprites/kit/$name');
    if (f.existsSync()) return f.readAsBytesSync();
  }
  throw StateError(
    'coqui/ref/sprites/kit/$name not found from ${Directory.current.path}: '
    'run the tests in coqui/packages/core/coqui_pixel',
  );
}

/// A text file under coqui/ref/sprites/kit/, as a string.
String kitFileText(String name) => utf8.decode(kitFile(name));
