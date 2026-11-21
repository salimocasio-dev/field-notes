// Makes the Dart fixtures the chrome tests read of the scenes' sheets: El frente's from docs/proyecto/pixel/frente-sheet.json,
// El balcón's from docs/proyecto/pixel/balcon-sheet.json, La sala's from docs/proyecto/pixel/sala-sheet.json, El patio's
// from docs/proyecto/pixel/patio-sheet.json, El camino's from docs/proyecto/pixel/camino-sheet.json, El campo's from
// docs/proyecto/pixel/campo-sheet.json, El lago's from docs/proyecto/pixel/lago-sheet.json and La estufa's from
// docs/proyecto/pixel/estufa-sheet.json.
//
//   dart run tool/make_sheet_fixture.dart          (in this package) writes test/support/fixtures/frente_sheet.dart,
//                                                  test/support/fixtures/balcon_sheet.dart, sala_sheet.dart,
//                                                  patio_sheet.dart, camino_sheet.dart, campo_sheet.dart, lago_sheet.dart
//                                                  and estufa_sheet.dart
//   dart run tool/make_sheet_fixture.dart --check  says whether those files are the ones the sheets give
//
// A test in a browser cannot read files, so each sheet goes into a Dart file as a raw string. The vm test reads the sheet
// itself, and test/fixtures_test.dart checks that the fixture holds the very same text, so both platforms parse one
// sheet. Remake it when a sheet changes (node docs/proyecto/pixel/<id>-sheet-make.js).
import 'dart:io';

void main(List<String> args) {
  const sheets = {
    'frente': (
      constant: 'frenteSheetJson',
      what: "El frente's sheet (order 07)",
    ),
    'balcon': (
      constant: 'balconSheetJson',
      what: "El balcón's sheet (order 30a)",
    ),
    'sala': (constant: 'salaSheetJson', what: "La sala's sheet (order 31a)"),
    'patio': (constant: 'patioSheetJson', what: "El patio's sheet (order 32a)"),
    'camino': (
      constant: 'caminoSheetJson',
      what: "El camino's sheet (order 33a)",
    ),
    'campo': (constant: 'campoSheetJson', what: "El campo's sheet (order 34a)"),
    'lago': (constant: 'lagoSheetJson', what: "El lago's sheet (order 35a)"),
    'estufa': (
      constant: 'estufaSheetJson',
      what: "La estufa's sheet (order 38a)",
    ),
  };
  var stale = 0;
  for (final e in sheets.entries) {
    final id = e.key;
    final sheet = File('../../../../docs/proyecto/pixel/$id-sheet.json');
    if (!sheet.existsSync()) {
      stderr.writeln(
        'Run this in coqui/packages/core/coqui_pixel: ../../../../docs/proyecto/pixel/$id-sheet.json is not there.',
      );
      exit(2);
    }
    final json = sheet.readAsStringSync();
    if (json.contains("'''")) {
      stderr.writeln("the sheet $id holds three quotes in a row: ''' ");
      exit(2);
    }
    final made = [
      "// Made by tool/make_sheet_fixture.dart from docs/proyecto/pixel/$id-sheet.json. Do not edit.",
      '// ignore_for_file: lines_longer_than_80_chars',
      '',
      '/// ${e.value.what}, the text of the file, for the tests that run in a browser.',
      "const String ${e.value.constant} = r'''$json''';",
      '',
    ].join('\n');
    final out = File('test/support/fixtures/${id}_sheet.dart');
    if (args.contains('--check')) {
      final same = out.existsSync() && out.readAsStringSync() == made;
      stdout.writeln(
        same
            ? 'the $id sheet fixture is current'
            : 'the $id sheet fixture is NOT current: run tool/make_sheet_fixture.dart',
      );
      if (!same) stale++;
      continue;
    }
    out.writeAsStringSync(made);
    stdout.writeln('wrote ${out.path}: ${made.length} characters');
  }
  if (stale > 0) exit(1);
}
