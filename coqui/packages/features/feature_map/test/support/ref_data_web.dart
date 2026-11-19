import 'dart:convert';
import 'dart:typed_data';

import 'fixtures/ref_map.dart';

/// The bytes of a file under coqui/ref/pp/ as the fixture holds them.
Uint8List refBytes(String path) {
  final pieces = refMapFixture[path];
  if (pieces == null) {
    throw StateError(
      'coqui/ref/pp/$path is not in the fixture: add it to tool/make_fixtures.dart',
    );
  }
  return base64Decode(pieces.join());
}

/// A text file under coqui/ref/pp/, as a string.
String refText(String path) => utf8.decode(refBytes(path));
