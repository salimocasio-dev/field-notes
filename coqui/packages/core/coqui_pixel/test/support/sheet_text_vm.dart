import 'dart:io';

/// The text of El frente's sheet, read from the file.
String frenteSheetText() {
  for (final base in const ['../../../..', '../..', '..', '.']) {
    final f = File('$base/docs/proyecto/pixel/frente-sheet.json');
    if (f.existsSync()) return f.readAsStringSync();
  }
  throw StateError(
    'docs/proyecto/pixel/frente-sheet.json not found from ${Directory.current.path}: '
    'run the tests in coqui/packages/core/coqui_pixel',
  );
}
