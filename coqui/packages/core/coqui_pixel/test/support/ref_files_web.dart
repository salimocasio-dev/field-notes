import 'dart:convert';
import 'dart:typed_data';

import 'fixtures/ref_ctx.dart';
import 'fixtures/ref_sprites.dart';

/// The bytes of a file under coqui/ref/, by its path there, as the fixtures hold it.
Uint8List refFile(String path) {
  final pieces = refSpritesFixture[path] ?? refCtxFixture[path];
  if (pieces == null) {
    throw StateError(
      'coqui/ref/$path is not in the fixtures: add it to tool/make_sprite_fixtures.dart',
    );
  }
  return base64Decode(pieces.join());
}

/// A text file under coqui/ref/, as a string.
String refFileText(String path) => utf8.decode(refFile(path));
