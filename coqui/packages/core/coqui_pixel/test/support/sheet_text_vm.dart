import 'dart:io';

/// The text of a scene's sheet (`docs/proyecto/pixel/<id>-sheet.json`), read from the file.
String _sheetText(String id) {
  for (final base in const ['../../../..', '../..', '..', '.']) {
    final f = File('$base/docs/proyecto/pixel/$id-sheet.json');
    if (f.existsSync()) return f.readAsStringSync();
  }
  throw StateError(
    'docs/proyecto/pixel/$id-sheet.json not found from ${Directory.current.path}: '
    'run the tests in coqui/packages/core/coqui_pixel',
  );
}

/// The text of El frente's sheet, read from the file.
String frenteSheetText() => _sheetText('frente');

/// The text of El balcón's sheet, read from the file.
String balconSheetText() => _sheetText('balcon');

/// The text of La sala's sheet, read from the file.
String salaSheetText() => _sheetText('sala');

/// The text of El patio's sheet, read from the file.
String patioSheetText() => _sheetText('patio');
