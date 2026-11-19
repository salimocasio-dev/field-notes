// Makes tool/map_seeds.dart from the progress states of coqui/ref/pantallas/seeds/ (what v=39 keeps under
// localStorage `coqui.palabras.v1`, made by the old palabras.js), so the dev entry and the tests can open the
// map in the states the reference pictures were taken in.
//
//   dart run tool/make_seeds.dart          (in this package)
//   dart run tool/make_seeds.dart --check
import 'dart:convert';
import 'dart:io';

const names = ['vacio', 'segunda', 'uno', 'curso', 'casi', 'todo'];

String render(Directory seeds) {
  final b = StringBuffer()
    ..writeln(
      '// Made by tool/make_seeds.dart from coqui/ref/pantallas/seeds/. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// The stored progress (coqui.palabras.v1) of each reference state, as one line of JSON.',
    )
    ..writeln('const Map<String, String> mapSeeds = {');
  for (final n in names) {
    final json = jsonEncode(
      jsonDecode(File('${seeds.path}/$n.json').readAsStringSync()),
    );
    b.writeln("  '$n': r'''$json''',");
  }
  b.writeln('};');
  return b.toString();
}

void main(List<String> args) {
  final seeds = Directory('../../../ref/pantallas/seeds');
  if (!seeds.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/features/feature_map: ../../../ref/pantallas/seeds is not there.',
    );
    exit(2);
  }
  final out = File('tool/map_seeds.dart');
  final made = render(seeds);
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same ? 'the seeds are current' : 'the seeds are NOT current',
    );
    exit(same ? 0 : 1);
  }
  out.writeAsStringSync(made);
  stdout.writeln('wrote ${out.path}: ${made.length} characters');
}
