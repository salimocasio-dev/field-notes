// The fixtures the set tests read in a browser: for each baked state of a converted scene's set in coqui/ref/pp/<id>/, its
// query and the hashes of its three buffers (pix, zb, kinds). On the vm the tests read the buffers themselves and count
// the differing elements; in a browser they compare the hashes: equal hashes, equal buffers (0 elements differ).
//
//   dart run tool/make_set_fixture.dart          (in this package) writes test/support/fixtures/set_refs.dart (El frente)
//                                                test/support/fixtures/balcon_set_refs.dart (El balcón),
//                                                test/support/fixtures/sala_set_refs.dart (La sala),
//                                                test/support/fixtures/patio_set_refs.dart (El patio),
//                                                test/support/fixtures/camino_set_refs.dart (El camino),
//                                                test/support/fixtures/campo_set_refs.dart (El campo),
//                                                test/support/fixtures/lago_set_refs.dart (El lago) and
//                                                test/support/fixtures/banco_set_refs.dart (El banco)
//   dart run tool/make_set_fixture.dart --check  fails when a file is not what coqui/ref/pp/<id>/ gives
import 'dart:convert';
import 'dart:io';

import '../test/support/hash.dart';

void main(List<String> args) {
  const scenes = {
    'frente': (
      file: 'set_refs.dart',
      constant: 'setRefs',
      what: "El frente's baked states",
    ),
    'balcon': (
      file: 'balcon_set_refs.dart',
      constant: 'balconSetRefs',
      what: "El balcón's baked states",
    ),
    'sala': (
      file: 'sala_set_refs.dart',
      constant: 'salaSetRefs',
      what: "La sala's baked states",
    ),
    'patio': (
      file: 'patio_set_refs.dart',
      constant: 'patioSetRefs',
      what: "El patio's baked states",
    ),
    'camino': (
      file: 'camino_set_refs.dart',
      constant: 'caminoSetRefs',
      what: "El camino's baked states",
    ),
    'campo': (
      file: 'campo_set_refs.dart',
      constant: 'campoSetRefs',
      what: "El campo's baked state and two frames of it (its glints at two times)",
    ),
    'lago': (
      file: 'lago_set_refs.dart',
      constant: 'lagoSetRefs',
      what: "El lago's baked state and two frames of it (its glints at two times)",
    ),
    'banco': (
      file: 'banco_set_refs.dart',
      constant: 'bancoSetRefs',
      what: "El banco's reached baked states",
    ),
    'mostrador': (
      file: 'mostrador_set_refs.dart',
      constant: 'mostradorSetRefs',
      what: "El mostrador's baked states, inside and in the street",
    ),
    'plaza': (
      file: 'plaza_set_refs.dart',
      constant: 'plazaSetRefs',
      what: "El banco de la plaza's baked states",
    ),
  };
  var stale = 0;
  for (final s in scenes.entries) {
    final dir = Directory('../../../ref/pp/${s.key}');
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
      '// Made by tool/make_set_fixture.dart from coqui/ref/pp/${s.key}/. Do not edit.',
      '// ignore_for_file: lines_longer_than_80_chars',
      '',
      '/// ${s.value.what}: the folder, the set page\'s query, and the hashes (test/support/hash.dart) of pix, zb, kinds.',
      "const String ${s.value.constant} = r'''${const JsonEncoder.withIndent(' ').convert(out)}''';",
      '',
    ].join('\n');
    final file = File('test/support/fixtures/${s.value.file}');
    if (args.contains('--check')) {
      final same = file.existsSync() && file.readAsStringSync() == made;
      stdout.writeln(
        same
            ? 'the ${s.key} set fixture is current'
            : 'the ${s.key} set fixture is NOT current: run tool/make_set_fixture.dart',
      );
      if (!same) stale++;
      continue;
    }
    file.writeAsStringSync(made);
    stdout.writeln('wrote ${file.path}: ${out.length} states');
  }
  if (stale > 0) exit(1);
}
