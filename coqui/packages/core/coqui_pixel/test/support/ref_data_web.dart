import 'dart:convert';
import 'dart:typed_data';

import 'fixture_decode.dart';

/// The bytes of a file under coqui/ref/pp/, by its path there, e.g. `island/pix.bin`.
Uint8List refBytes(String path) => decodeFixture(path);

/// A text file under coqui/ref/pp/, as a string.
String refText(String path) => utf8.decode(refBytes(path));
