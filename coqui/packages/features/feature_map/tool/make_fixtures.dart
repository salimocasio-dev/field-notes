// Makes the Dart fixture the chrome tests read, from the reference data in coqui/ref/pp/map/.
//
//   dart run tool/make_fixtures.dart          (in this package) writes test/support/fixtures/ref_map.dart
//   dart run tool/make_fixtures.dart --check  says whether that file is the one the reference data gives
//
// A test in a browser cannot read files, so the reference data goes into a Dart file: each file below as
// base64, in pieces. The vm tests read the files themselves, and test/fixtures_test.dart checks that the
// fixture holds the very same bytes, so the two platforms compare against one reference.
import 'dart:convert';
import 'dart:io';

/// The files of coqui/ref/pp/ the tests read, as the path under that folder.
const files = [
  'map/hecho-0/pix.bin',
  'map/hecho-0/kinds.bin',
  'map/hecho-0/state.json',
  'map/hecho-3/pix.bin',
  'map/hecho-3/state.json',
  'map/hecho-10/pix.bin',
  'map/hecho-10/state.json',
];

const piece = 4000;

String render(Directory refPp) {
  final b = StringBuffer()
    ..writeln(
      '// Made by tool/make_fixtures.dart from coqui/ref/pp/. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// Each file of coqui/ref/pp/ the tests read, as base64 in pieces.',
    )
    ..writeln('const Map<String, List<String>> refMapFixture = {');
  for (final f in files) {
    final bytes = File('${refPp.path}/$f').readAsBytesSync();
    final text = base64Encode(bytes);
    b.writeln("  '$f': [");
    for (var i = 0; i < text.length; i += piece) {
      final end = i + piece < text.length ? i + piece : text.length;
      b.writeln("    '${text.substring(i, end)}',");
    }
    b.writeln('  ],');
  }
  b.writeln('};');
  return b.toString();
}

void main(List<String> args) {
  final refPp = Directory('../../../ref/pp');
  if (!refPp.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/features/feature_map: ../../../ref/pp is not there.',
    );
    exit(2);
  }
  final out = File('test/support/fixtures/ref_map.dart');
  final made = render(refPp);
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same
          ? 'the fixture is current'
          : 'the fixture is NOT current: run tool/make_fixtures.dart',
    );
    exit(same ? 0 : 1);
  }
  out.writeAsStringSync(made);
  stdout.writeln('wrote ${out.path}: ${made.length} characters');
}
