// The fixtures the sprite tests read in a browser: each sprite a converted scene's old file makes for itself
// (coqui/ref/sprites/escenas/<id>/index.json), its key, size, the call that made it, and the hash of its RGBA bytes. On
// the vm the tests compare the bytes themselves; in a browser, the hashes.
//
//   dart run tool/make_sprite_fixture.dart          (in this package) writes test/support/fixtures/sprite_refs.dart
//                                                  (frente.js), test/support/fixtures/balcon_sprite_refs.dart (balcon.js)
//                                                  test/support/fixtures/sala_sprite_refs.dart (sala.js),
//                                                  test/support/fixtures/patio_sprite_refs.dart (patio.js),
//                                                  test/support/fixtures/camino_sprite_refs.dart (camino.js),
//                                                  test/support/fixtures/campo_sprite_refs.dart (campo.js),
//                                                  test/support/fixtures/lago_sprite_refs.dart (lago.js) and
//                                                  test/support/fixtures/banco_sprite_refs.dart (banco.js)
//   dart run tool/make_sprite_fixture.dart --check  fails when a file is not what the reference gives
import 'dart:convert';
import 'dart:io';

import '../test/support/hash.dart';

void main(List<String> args) {
  const scenes = {
    'frente': (file: 'sprite_refs.dart', constant: 'spriteRefs'),
    'balcon': (file: 'balcon_sprite_refs.dart', constant: 'balconSpriteRefs'),
    'sala': (file: 'sala_sprite_refs.dart', constant: 'salaSpriteRefs'),
    'patio': (file: 'patio_sprite_refs.dart', constant: 'patioSpriteRefs'),
    'camino': (file: 'camino_sprite_refs.dart', constant: 'caminoSpriteRefs'),
    'campo': (file: 'campo_sprite_refs.dart', constant: 'campoSpriteRefs'),
    'lago': (file: 'lago_sprite_refs.dart', constant: 'lagoSpriteRefs'),
    'banco': (file: 'banco_sprite_refs.dart', constant: 'bancoSpriteRefs'),
  };
  var stale = 0;
  for (final sc in scenes.entries) {
    final id = sc.key;
    final dir = Directory('../../../ref/sprites/escenas/$id');
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
          // a key with more than one file (sala.js's scratch canvas `bor`): which one
          if (s['file'] != '${s['key']}.rgba') 'file': s['file'],
          'w': s['w'],
          'h': s['h'],
          'caller': s['caller'],
          'maker': s['maker'],
          'hash': hashBytes(File('${dir.path}/${s['file']}').readAsBytesSync()),
        },
    ];
    final made = [
      '// Made by tool/make_sprite_fixture.dart from coqui/ref/sprites/escenas/$id/. Do not edit.',
      '// ignore_for_file: lines_longer_than_80_chars',
      '',
      '/// The sprites $id.js makes for itself: key, size, the call (caller and maker, as V8 reported them) and the hash',
      '/// (test/support/hash.dart) of the RGBA bytes.',
      "const String ${sc.value.constant} = r'''${const JsonEncoder.withIndent(' ').convert(out)}''';",
      '',
    ].join('\n');
    final file = File('test/support/fixtures/${sc.value.file}');
    if (args.contains('--check')) {
      final same = file.existsSync() && file.readAsStringSync() == made;
      stdout.writeln(
        same
            ? 'the $id sprite fixture is current'
            : 'the $id sprite fixture is NOT current: run tool/make_sprite_fixture.dart',
      );
      if (!same) stale++;
      continue;
    }
    file.writeAsStringSync(made);
    stdout.writeln('wrote ${file.path}: ${out.length} sprites');
  }
  if (stale > 0) exit(1);
}
