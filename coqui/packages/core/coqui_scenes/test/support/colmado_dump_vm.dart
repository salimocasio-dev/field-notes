import 'dart:io';
import 'dart:typed_data';

/// The bytes of `<name>` in the folder COLMADO_KIT_DUMP names, or null when it is not set or the file is not there.
Uint8List? colmadoDump(String name) {
  final dir = Platform.environment['COLMADO_KIT_DUMP'];
  if (dir == null) return null;
  final f = File('$dir/$name');
  return f.existsSync() ? f.readAsBytesSync() : null;
}
