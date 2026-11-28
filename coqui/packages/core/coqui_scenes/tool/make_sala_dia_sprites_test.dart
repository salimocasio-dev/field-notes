// The sprite sheet for the content lane, who looks at every new drawing (page 13, order 72): every sprite of what
// only La sala, de día draws (lib/src/sala_dia/sala_dia_sprites.dart), each at 3x on a plain ground with its number
// over it, and a list of the numbers beside the picture.
//
//   COQUI_OUT=DIR flutter test tool/make_sala_dia_sprites_test.dart      (in this package)
//
// writes DIR/sala_dia-sprites.png and DIR/sala_dia-sprites.txt.
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/sala_dia/sala_dia_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/png.dart';
import 'make_colmado_sprites_test.dart' show sheetPicture;

void _write(
  String dir,
  String name,
  String title,
  List<(String, Sprite)> sprites, {
  int cols = 8,
}) {
  Directory(dir).createSync(recursive: true);
  final p = sheetPicture(sprites, cols: cols);
  writePng('$dir/$name.png', p.px, p.w, p.h, scale: 3);
  File('$dir/$name.txt').writeAsStringSync(
    [
      '$title, at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.',
      'Made by coqui/packages/core/coqui_scenes/tool/make_sala_dia_sprites_test.dart. Do not edit.',
      '',
      for (var n = 0; n < sprites.length; n++)
        '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
      '',
    ].join('\n'),
  );
}

void main() {
  final out = Platform.environment['COQUI_OUT'] ?? '';
  test('the sprite sheet of what only La sala, de día draws', () {
    if (out.isEmpty) return;
    _write(
      out,
      'sala_dia-sprites',
      'What only La sala, de día has (lib/src/sala_dia/sala_dia_sprites.dart)',
      salaDiaSpritesSheet(),
      cols: 8,
    );
  });
}
