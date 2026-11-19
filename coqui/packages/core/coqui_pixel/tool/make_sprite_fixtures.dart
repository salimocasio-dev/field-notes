// Makes the Dart fixtures the chrome tests read, from the reference data in coqui/ref/sprites/engine/ and coqui/ref/ctx/.
//
//   dart run tool/make_sprite_fixtures.dart          (in this package) writes
//       test/support/fixtures/ref_sprites.dart  (coqui/ref/sprites/engine/)
//       test/support/fixtures/ref_ctx.dart      (coqui/ref/ctx/: cases.json, the tiles, the source sprites)
//   dart run tool/make_sprite_fixtures.dart --check  says whether those files are the ones the reference data gives
//
// A test in a browser cannot read files, so the reference data goes into Dart files: each file below as base64, in
// pieces (the same way tool/make_fixtures.dart does it for coqui/ref/pp/). The vm tests read the files themselves, and
// test/fixtures_test.dart checks that the fixtures hold the very same bytes, so the two platforms compare against
// one reference.
import 'dart:convert';
import 'dart:io';

const piece = 4000;

/// The path of each file under coqui/ref/, sorted, from the folders the tests read.
List<String> listFiles(Directory ref, String folder, {bool deep = false}) {
  final dir = Directory('${ref.path}/$folder');
  final out = <String>[];
  for (final e in dir.listSync(recursive: deep)) {
    if (e is File) {
      out.add(e.path.substring(ref.path.length + 1));
    }
  }
  out.sort();
  return out;
}

String render(Directory ref, String name, String what, List<String> files) {
  final b = StringBuffer()
    ..writeln(
      '// Made by tool/make_sprite_fixtures.dart from $what. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln('/// Each file of $what the tests read, as base64 in pieces.')
    ..writeln('const Map<String, List<String>> $name = {');
  for (final f in files) {
    final bytes = File('${ref.path}/$f').readAsBytesSync();
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
  final ref = Directory('../../../ref');
  if (!ref.existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_pixel: ../../../ref is not there.',
    );
    exit(2);
  }
  final spriteFiles = listFiles(ref, 'sprites/engine');
  final ctxFiles = [
    'ctx/cases.json',
    ...listFiles(ref, 'ctx/tiles'),
    ...listFiles(ref, 'ctx/sources'),
  ];
  final outputs = {
    'test/support/fixtures/ref_sprites.dart': render(
      ref,
      'refSpritesFixture',
      'coqui/ref/sprites/engine/',
      spriteFiles,
    ),
    'test/support/fixtures/ref_ctx.dart': render(
      ref,
      'refCtxFixture',
      'coqui/ref/ctx/',
      ctxFiles,
    ),
  };
  if (args.contains('--check')) {
    var same = true;
    outputs.forEach((path, made) {
      final out = File(path);
      if (!out.existsSync() || out.readAsStringSync() != made) {
        stdout.writeln('the fixture $path is NOT current');
        same = false;
      }
    });
    stdout.writeln(
      same
          ? 'the fixtures are current'
          : 'run tool/make_sprite_fixtures.dart to remake them',
    );
    exit(same ? 0 : 1);
  }
  outputs.forEach((path, made) {
    File(path).writeAsStringSync(made);
    stdout.writeln('wrote $path: ${made.length} characters');
  });
}
