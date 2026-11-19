// The Pixel Plays MIT licence: its full text sits under the first line of lib/src/pp_engine.dart and is also kept
// as LICENSE-pixel-plays.txt, word for word. (The text was fetched from github.com/amirmushichge/pixel-plays.)
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final licence = File('LICENSE-pixel-plays.txt').readAsStringSync();

  test('LICENSE-pixel-plays.txt is the MIT licence of Amir Mushich', () {
    expect(
      licence,
      startsWith('MIT License\n\nCopyright (c) 2026 Amir Mushich\n\n'),
    );
    expect(licence, contains('Permission is hereby granted, free of charge'));
    expect(licence, endsWith('SOFTWARE.\n'));
  });

  test('pp_engine.dart carries the same text as a comment block under its first line', () {
    final lines = File('lib/src/pp_engine.dart').readAsLinesSync();
    expect(
      lines.first,
      startsWith('// Pixel Plays engine by AmirMushich, MIT licence'),
    );
    final block = <String>[];
    for (final l in lines.skip(1)) {
      if (!l.startsWith('//')) break;
      block.add(l);
    }
    // the block is `//`, the licence one `// ` line at a time, `//` (and then "Changed for Coquí")
    final at = block.indexOf('// SOFTWARE.');
    expect(at, greaterThan(0));
    final text = block
        .take(at + 1)
        .skip(1)
        .map((l) => l.length > 3 ? l.substring(3) : '')
        .join('\n');
    expect(text, licence.trimRight());
  });
}
