// The sprite sheet for the content lane, who looks at every new drawing (page 13, order 66): every sprite of
// what only La entrada draws (lib/src/entrada/entrada_sprites.dart), each at 3x on a plain ground with its number
// over it, and a list of the numbers beside the picture.
//
//   COQUI_OUT=DIR flutter test tool/make_entrada_sprites_test.dart        (in this package)
//
// writes DIR/entrada-sprites.png and DIR/entrada-sprites.txt.
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/entrada/entrada_sprites.dart';
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
      'Made by coqui/packages/core/coqui_scenes/tool/make_entrada_sprites_test.dart. Do not edit.',
      '',
      for (var n = 0; n < sprites.length; n++)
        '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
      '',
    ].join('\n'),
  );
}

void main() {
  final out = Platform.environment['COQUI_OUT'] ?? '';
  test('the sprite sheet of what only La entrada draws', () {
    if (out.isEmpty) return;
    _write(
      out,
      'entrada-sprites',
      'What only La entrada has (lib/src/entrada/entrada_sprites.dart)',
      entradaSpritesSheet(),
      cols: 8,
    );
  });
}
