import 'dart:convert';
import 'dart:typed_data';

import 'fixtures/extra_ref.dart';
import 'fixtures/frente_nov14.dart';
import 'fixtures/ref_pp.dart';

/// The bytes of a file under coqui/ref/pp/ as the fixture holds them.
Uint8List decodeFixture(String path) {
  final pieces = refPpFixture[path];
  if (pieces == null) {
    throw StateError(
      'coqui/ref/pp/$path is not in the fixture: add it to tool/make_fixtures.dart',
    );
  }
  return base64Decode(pieces.join());
}

/// The bytes of a file of the extra reference (tool/make_extra_ref.mjs), by its name there.
Uint8List decodeExtra(String name) {
  final pieces = extraRefFixture[name];
  if (pieces == null) throw StateError('$name is not in the extra reference');
  return base64Decode(pieces.join());
}

/// A file of the Nov 14 one-state El frente (`pix.bin`, `zb.bin`, `kinds.bin`, `state.json`): on every platform, the
/// fixture; it is no longer in coqui/ref/pp/.
Uint8List decodeFrenteNov14(String name) {
  final pieces = frenteNov14Fixture[name];
  if (pieces == null) throw StateError('$name is not in the Nov 14 El frente');
  return base64Decode(pieces.join());
}
