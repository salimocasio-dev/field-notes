import 'dart:io';

/// The text of a file under historia/ by its path there (`datos/nivel.json`), or null when it is not there.
String? historiaFile(String path) {
  for (final base in const [
    '../../../../historia',
    '../../historia',
    'historia',
  ]) {
    final f = File('$base/$path');
    if (f.existsSync()) return f.readAsStringSync();
  }
  return null;
}
