// Makes test/support/fixtures/course_fixture.dart from the old course data: the ten places of
// historia/datos/curso.json and the focus words (with the place) of the stories of La casa, which is what
// llamada.js reads (`palabrasDe`) to say which words Danny may ask for.
//
//   dart run tool/make_fixtures.dart          (in this package)
//   dart run tool/make_fixtures.dart --check
import 'dart:convert';
import 'dart:io';

String render(Directory historia) {
  final curso = jsonDecode(
    File('${historia.path}/datos/curso.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final places = (curso['lugares'] as List).cast<Map<String, dynamic>>();
  final casa = places.firstWhere((l) => l['id'] == 'casa');
  final stories = <String, Map<String, dynamic>>{};
  for (final id in (casa['cuentos'] as List).cast<String>()) {
    final j = jsonDecode(
      File('${historia.path}/cuentos/$id.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    stories[id] = {'place': j['place'], 'focus_words': j['focus_words']};
  }
  final b = StringBuffer()
    ..writeln(
      '// Made by tool/make_fixtures.dart from historia/datos/curso.json and the stories of La casa. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// curso.json\'s `lugares`: the ten places, as one line of JSON.',
    )
    ..writeln("const String fixturePlacesJson = r'''${jsonEncode(places)}''';")
    ..writeln()
    ..writeln(
      '/// For each story of La casa, what llamada.js reads of it: its `place` and its `focus_words`.',
    )
    ..writeln('const Map<String, String> fixtureCasaStories = {');
  for (final e in stories.entries) {
    b.writeln("  '${e.key}': r'''${jsonEncode(e.value)}''',");
  }
  b.writeln('};');
  return b.toString();
}

/// What `dart format` makes of [text] (the file is kept formatted, as the repository's checks want it).
String formatted(String text) {
  final dir = Directory.systemTemp.createTempSync('make_fixtures');
  try {
    final f = File('${dir.path}/course_fixture.dart')..writeAsStringSync(text);
    final r = Process.runSync('dart', ['format', f.path]);
    if (r.exitCode != 0) {
      stderr.writeln('dart format failed: ${r.stderr}');
      exit(2);
    }
    return f.readAsStringSync();
  } finally {
    dir.deleteSync(recursive: true);
  }
}

void main(List<String> args) {
  final historia = Directory('../../../../historia');
  if (!historia.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/features/feature_speaking: ../../../../historia is not there.',
    );
    exit(2);
  }
  final out = File('test/support/fixtures/course_fixture.dart');
  final made = formatted(render(historia));
  if (args.contains('--check')) {
    final same = out.existsSync() && out.readAsStringSync() == made;
    stdout.writeln(
      same ? 'the fixture is current' : 'the fixture is NOT current',
    );
    exit(same ? 0 : 1);
  }
  out.createSync(recursive: true);
  out.writeAsStringSync(made);
  stdout.writeln('wrote ${out.path}: ${made.length} characters');
}
