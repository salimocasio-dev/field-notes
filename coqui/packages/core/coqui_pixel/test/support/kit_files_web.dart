import 'dart:convert';
import 'dart:typed_data';

import 'fixtures/ref_kit.dart';

final Map<String, Uint8List> _decoded = {};

/// The bytes of a file under coqui/ref/sprites/kit/, by its name there, as the fixture holds it (decoded once).
Uint8List kitFile(String name) => _decoded[name] ??= _decode(name);

Uint8List _decode(String name) {
  final pieces = refKitFixture['sprites/kit/$name'];
  if (pieces == null) {
    throw StateError(
      'coqui/ref/sprites/kit/$name is not in the fixtures: add it to tool/make_sprite_fixtures.dart',
    );
  }
  return base64Decode(pieces.join());
}

/// A text file under coqui/ref/sprites/kit/, as a string.
String kitFileText(String name) => utf8.decode(kitFile(name));
