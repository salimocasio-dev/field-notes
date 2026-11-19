// The fixture the sprite test reads in a browser (test/support/fixtures/sprite_refs.dart): each sprite frente.js makes for
// itself (coqui/ref/sprites/escenas/frente/index.json), its key, size, the call that made it, and the hash of its RGBA
// bytes. On the vm the test compares the bytes themselves; in a browser, the hashes.
//
//   dart run tool/make_sprite_fixture.dart          (in this package) writes test/support/fixtures/sprite_refs.dart
//   dart run tool/make_sprite_fixture.dart --check  fails when that file is not what the reference gives
import 'dart:convert';
import 'dart:io';

import '../test/support/hash.dart';

void main(List<String> args) {
  final dir = Directory('../../../ref/sprites/escenas/frente');
  if (!dir.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_scenes: ${dir.path} is not there.',
    );
    exit(2);
  }
  final index = jsonDecode(
    File('${dir.path}/index.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final out = [
    for (final s in (index['sprites'] as List).cast<Map<String, dynamic>>())
      {
        'key': s['key'],
        'w': s['w'],
        'h': s['h'],
        'caller': s['caller'],
        'maker': s['maker'],
        'hash': hashBytes(File('${dir.path}/${s['file']}').readAsBytesSync()),
      },
  ];
  final made = [
    '// Made by tool/make_sprite_fixture.dart from coqui/ref/sprites/escenas/frente/. Do not edit.',
    '// ignore_for_file: lines_longer_than_80_chars',
    '',
    '/// The sprites frente.js makes for itself: key, size, the call (caller and maker, as V8 reported them) and the hash',
    '/// (test/support/hash.dart) of the RGBA bytes.',
    "const String spriteRefs = r'''${const JsonEncoder.withIndent(' ').convert(out)}''';",
    '',
  ].join('\n');
  final file = File('test/support/fixtures/sprite_refs.dart');
  if (args.contains('--check')) {
    final same = file.existsSync() && file.readAsStringSync() == made;
    stdout.writeln(
      same ? 'the sprite fixture is current' : 'the sprite fixture is NOT current: run tool/make_sprite_fixture.dart',
    );
    exit(same ? 0 : 1);
  }
  file.writeAsStringSync(made);
  stdout.writeln('wrote ${file.path}: ${out.length} sprites');
}
