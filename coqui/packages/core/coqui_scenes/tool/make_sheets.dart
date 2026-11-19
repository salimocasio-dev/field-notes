// Copies each converted scene's sheet into this package's assets, from the set reference's own file.
//
//   dart run tool/make_sheets.dart          (in this package) writes assets/sheets/<id>-sheet.json
//   dart run tool/make_sheets.dart --check  fails when a copy is not the file it is copied from
//
// The sheet is data (page 12, section 5): the scene reads it as an asset and never retypes its numbers. Its one source
// is docs/proyecto/pixel/<id>-sheet.json, made by the set reference's maker (node docs/proyecto/pixel/<id>-sheet-make.js).
// Copy it again when that file changes; the check says when it has.
//
// It also writes test/support/fixtures/sheets.dart, the same text as a Dart string: a test in a browser cannot read
// the package's assets through the root bundle (it never answers), so it is given a bundle that answers from there.
import 'dart:io';

/// The scenes converted so far, by id: each has `docs/proyecto/pixel/<id>-sheet.json`.
const converted = ['frente'];

void main(List<String> args) {
  final check = args.contains('--check');
  final docs = Directory('../../../../docs/proyecto/pixel');
  if (!docs.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_scenes: ${docs.path} is not there.',
    );
    exit(2);
  }
  var stale = 0;
  final fixture = StringBuffer()
    ..writeln(
      '// Made by tool/make_sheets.dart from docs/proyecto/pixel/<id>-sheet.json. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// The sheets of the converted scenes, by id: the text of each file, for the tests that run in a browser.',
    )
    ..writeln('const Map<String, String> sheetTexts = {');
  for (final id in converted) {
    final from = File('${docs.path}/$id-sheet.json');
    final to = File('assets/sheets/$id-sheet.json');
    final want = from.readAsStringSync();
    if (want.contains("'''")) {
      stderr.writeln('${from.path} holds three quotes in a row');
      exit(2);
    }
    fixture.writeln("  '$id': r'''$want''',");
    if (check) {
      final same = to.existsSync() && to.readAsStringSync() == want;
      stdout.writeln(
        same
            ? '${to.path} is current'
            : '${to.path} is NOT current: run dart run tool/make_sheets.dart',
      );
      if (!same) stale++;
    } else {
      to.writeAsStringSync(want);
      stdout.writeln('wrote ${to.path}: ${want.length} characters');
    }
  }
  fixture.writeln('};');
  final fx = File('test/support/fixtures/sheets.dart'),
      made = fixture.toString();
  if (check) {
    final same = fx.existsSync() && fx.readAsStringSync() == made;
    stdout.writeln(
      same
          ? '${fx.path} is current'
          : '${fx.path} is NOT current: run dart run tool/make_sheets.dart',
    );
    if (!same) stale++;
  } else {
    fx.writeAsStringSync(made);
    stdout.writeln('wrote ${fx.path}');
  }
  if (stale > 0) exit(1);
}
