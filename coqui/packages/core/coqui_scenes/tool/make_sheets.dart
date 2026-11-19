// Copies each converted scene's sheet into this package's assets, from the set reference's own file.
//
//   dart run tool/make_sheets.dart          (in this package) writes assets/sheets/<id>-sheet.json
//   dart run tool/make_sheets.dart --check  fails when a copy is not the file it is copied from
//
// The sheet is data (page 12, section 5): the scene reads it as an asset and never retypes its numbers. Its one source
// is docs/proyecto/pixel/<id>-sheet.json, made by the set reference's maker (node docs/proyecto/pixel/<id>-sheet-make.js).
// Copy it again when that file changes; the check (run by test/sheets_test.dart) says when it has.
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
  for (final id in converted) {
    final from = File('${docs.path}/$id-sheet.json');
    final to = File('assets/sheets/$id-sheet.json');
    final want = from.readAsStringSync();
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
  if (stale > 0) exit(1);
}
