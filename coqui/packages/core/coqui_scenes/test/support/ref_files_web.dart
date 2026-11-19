import 'dart:typed_data';

/// A browser cannot read files: always null.
Uint8List? refFile(String path) => null;
