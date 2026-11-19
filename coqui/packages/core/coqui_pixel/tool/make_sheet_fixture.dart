// Makes the Dart fixture the chrome tests read of El frente's sheet, from docs/proyecto/pixel/frente-sheet.json.
//
//   dart run tool/make_sheet_fixture.dart          (in this package) writes test/support/fixtures/frente_sheet.dart
//   dart run tool/make_sheet_fixture.dart --check  says whether that file is the one the sheet gives
//
// A test in a browser cannot read files, so the sheet goes into a Dart file as a raw string. The vm test reads the sheet
// itself, and test/fixtures_test.dart checks that the fixture holds the very same text, so both platforms parse one
// sheet. Remake it when order 07's sheet changes (node docs/proyecto/pixel/frente-sheet-make.js).
import 'dart:io';

void main(List<String> args) {
  final sheet = File('../../../../docs/proyecto/pixel/frente-sheet.json');
  if (!sheet.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_pixel: ../../../../docs/proyecto/pixel/frente-sheet.json is not there.',
    );
    exit(2);
  }
  final json = sheet.readAsStringSync();
  if (json.contains("'''")) {
    stderr.writeln("the sheet holds three quotes in a row: ''' ");
    exit(2);
  }
  final made = [
    "// Made by tool/make_sheet_fixture.dart from docs/proyecto/pixel/frente-sheet.json. Do not edit.",
    '// ignore_for_file: lines_longer_than_80_chars',
    '',
    "/// El frente's sheet (order 07), the text of the file, for the tests that run in a browser.",
    "const String frenteSheetJson = r'''$json''';",
    '',
  ].join('\n');
  final out = File('test/support/fixtures/frente_sheet.dart');
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same ? 'the sheet fixture is current' : 'the sheet fixture is NOT current: run tool/make_sheet_fixture.dart',
    );
    exit(same ? 0 : 1);
  }
  out.writeAsStringSync(made);
  stdout.writeln('wrote ${out.path}: ${made.length} characters');
}
