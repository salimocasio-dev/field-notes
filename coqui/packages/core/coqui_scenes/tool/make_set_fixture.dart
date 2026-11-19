// The fixture the set test reads in a browser (test/support/fixtures/set_refs.dart): for each of El frente's baked
// states in coqui/ref/pp/frente/, its query and the hashes of its three buffers (pix, zb, kinds). On the vm the test
// reads the buffers themselves and counts the differing elements; in a browser it compares the hashes: equal hashes,
// equal buffers (0 elements differ).
//
//   dart run tool/make_set_fixture.dart          (in this package) writes test/support/fixtures/set_refs.dart
//   dart run tool/make_set_fixture.dart --check  fails when that file is not what coqui/ref/pp/frente/ gives
import 'dart:convert';
import 'dart:io';

import '../test/support/hash.dart';

void main(List<String> args) {
  final dir = Directory('../../../ref/pp/frente');
  if (!dir.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_scenes: ${dir.path} is not there.',
    );
    exit(2);
  }
  final states = dir.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final out = <Map<String, Object>>[];
  for (final d in states) {
    final st = jsonDecode(
      File('${d.path}/state.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    out.add({
      'id': d.path.split('/').last,
      'query': (st['source'] as String).split('?')[1],
      for (final b in const ['pix', 'zb', 'kinds'])
        b: hashBytes(File('${d.path}/$b.bin').readAsBytesSync()),
    });
  }
  final made = [
    '// Made by tool/make_set_fixture.dart from coqui/ref/pp/frente/. Do not edit.',
    '// ignore_for_file: lines_longer_than_80_chars',
    '',
    "/// El frente's baked states: the folder, the set page's query, and the hashes (test/support/hash.dart) of pix, zb, kinds.",
    "const String setRefs = r'''${const JsonEncoder.withIndent(' ').convert(out)}''';",
    '',
  ].join('\n');
  final file = File('test/support/fixtures/set_refs.dart');
  if (args.contains('--check')) {
    final same = file.existsSync() && file.readAsStringSync() == made;
    stdout.writeln(
      same
          ? 'the set fixture is current'
          : 'the set fixture is NOT current: run tool/make_set_fixture.dart',
    );
    exit(same ? 0 : 1);
  }
  file.writeAsStringSync(made);
  stdout.writeln('wrote ${file.path}: ${out.length} states');
}
