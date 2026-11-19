import 'dart:io';
import 'dart:typed_data';

/// The bytes of a file under coqui/ref/ by its path there (`pp/frente/<state>/pix.bin`), or null when it is not there.
Uint8List? refFile(String path) {
  for (final base in const ['../../../ref', '../ref', 'ref']) {
    final f = File('$base/$path');
    if (f.existsSync()) return f.readAsBytesSync();
  }
  return null;
}
