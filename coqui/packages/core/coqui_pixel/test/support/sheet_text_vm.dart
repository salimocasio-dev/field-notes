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

/// The text of El camino's sheet, read from the file.
String caminoSheetText() => _sheetText('camino');

/// The text of El campo's sheet, read from the file.
String campoSheetText() => _sheetText('campo');

/// The text of El lago's sheet, read from the file.
String lagoSheetText() => _sheetText('lago');

/// The text of La estufa's sheet, read from the file.
String estufaSheetText() => _sheetText('estufa');
