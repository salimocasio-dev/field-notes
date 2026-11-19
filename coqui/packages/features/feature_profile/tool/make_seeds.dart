// Embeds the progress states of the reference pictures (coqui/ref/pantallas/seeds/) into this package, so the
// dev entry and the tests load them on every platform, a browser too.
//
//   dart run tool/make_seeds.dart          (in this package) writes test/support/seeds.dart
//   dart run tool/make_seeds.dart --check  says whether that file is the one the seeds give
//
// Each seed is the JSON the old app keeps under localStorage `coqui.palabras.v1`, as one string.
import 'dart:convert';
import 'dart:io';

const sourceDir = '../../../ref/pantallas/seeds';
const target = 'test/support/seeds.dart';

String quote(String s) =>
    "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$').replaceAll('\n', r'\n')}'";

String render(Directory dir) {
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final b = StringBuffer()
    ..writeln(
      '// Made by tool/make_seeds.dart from coqui/ref/pantallas/seeds/. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// The stored progress of each reference state of v=39, by name (the file name of the seed).',
    )
    ..writeln('const Map<String, String> seeds = {');
  for (final f in files) {
    final name = f.uri.pathSegments.last.replaceAll('.json', '');
    // one line, as the app stores it
    final text = jsonEncode(jsonDecode(f.readAsStringSync()));
    b.writeln('  ${quote(name)}: ${quote(text)},');
  }
  b.writeln('};');
  return b.toString();
}

void main(List<String> args) {
  final dir = Directory(sourceDir);
  if (!dir.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/features/feature_profile: $sourceDir is not there.',
    );
    exit(2);
  }
  final made = render(dir);
  final out = File(target);
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same
          ? '$target is the seeds, embedded.'
          : '$target is NOT what the seeds give: run `dart run tool/make_seeds.dart`.',
    );
    exit(same ? 0 : 1);
  }
  out.writeAsStringSync(made);
  stdout.writeln('wrote $target');
}
