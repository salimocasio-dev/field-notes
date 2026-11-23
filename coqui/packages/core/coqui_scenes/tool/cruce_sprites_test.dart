// The sprite sheet of what El cruce adds, for the content lane, who looks at every new drawing (page 13, orders 54 to
// 57): each sprite and pose of lib/src/cruce/cruce_sprites.dart (cruceSpriteSheet) at 3x on a plain ground with its
// number over it (tool/make_colmado_sprites_test.dart's sheetPicture), and a list of the numbers.
//
//   flutter test tool/cruce_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/cruce-sprites.png and .txt.
import 'dart:io';

import 'package:coqui_scenes/src/cruce/cruce_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/png.dart';
import 'make_colmado_sprites_test.dart' show sheetPicture;

void main() {
  test('the sprite sheet of El cruce', () {
    final d = Directory('../../../../docs/proyecto/pixel/port')
      ..createSync(recursive: true);
    final sprites = cruceSpriteSheet();
    final p = sheetPicture(sprites);
    writePng('${d.path}/cruce-sprites.png', p.px, p.w, p.h, scale: 3);
    File('${d.path}/cruce-sprites.txt').writeAsStringSync(
      [
        "What only El cruce has (lib/src/cruce/cruce_sprites.dart), at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.",
        'Made by coqui/packages/core/coqui_scenes/tool/cruce_sprites_test.dart. Do not edit.',
        '',
        for (var n = 0; n < sprites.length; n++)
          '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
        '',
      ].join('\n'),
    );
  });
}
