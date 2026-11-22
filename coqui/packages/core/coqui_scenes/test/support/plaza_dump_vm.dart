import 'dart:io';
import 'dart:typed_data';

/// The bytes of `<name>` in the folder PLAZA_KIT_DUMP names, or null when it is not set or the file is not there.
Uint8List? plazaDump(String name) {
  final dir = Platform.environment['PLAZA_KIT_DUMP'];
  if (dir == null) return null;
  final f = File('$dir/$name');
  return f.existsSync() ? f.readAsBytesSync() : null;
}
