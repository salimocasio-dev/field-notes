// The sprite sheet for the content lane, who looks at every new drawing (page 13, orders 58 to 61): every sprite of
// what only El calendario draws (lib/src/calendario/calendario_sprites.dart), each at 3x on a plain ground with its
// number over it, and a list of the numbers beside the picture.
//
//   flutter test tool/make_calendario_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/calendario-sprites.png and .txt.
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calendario/calendario_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/png.dart';
import 'make_colmado_sprites_test.dart' show sheetPicture;

String _port(String name) {
  for (final base in const ['../../../../docs', '../../../docs', 'docs']) {
    final d = Directory('$base/proyecto/pixel');
    if (d.existsSync()) {
      Directory('${d.path}/port').createSync();
      return '${d.path}/port/$name';
    }
  }
  throw StateError('docs/proyecto/pixel not found');
}

void _write(
  String name,
  String title,
  List<(String, Sprite)> sprites, {
  int cols = 8,
}) {
  final p = sheetPicture(sprites, cols: cols);
  writePng(_port('$name.png'), p.px, p.w, p.h, scale: 3);
  File(_port('$name.txt')).writeAsStringSync(
    [
      '$title, at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.',
      'Made by coqui/packages/core/coqui_scenes/tool/make_calendario_sprites_test.dart. Do not edit.',
      '',
      for (var n = 0; n < sprites.length; n++)
        '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
      '',
    ].join('\n'),
  );
}

void main() {
  test('the sprite sheet of what only El calendario draws', () {
    _write(
      'calendario-sprites',
      'What only El calendario has (lib/src/calendario/calendario_sprites.dart)',
      calendarioSpritesSheet(),
      cols: 8,
    );
  });
}
