// The sprite sheet of what Las frutas adds, for the content lane, who looks at every new drawing (page 13, orders 50 to
// 53, step b point 3): every sprite and pose of lib/src/frutas/frutas_sprites.dart, each at 3x on a plain ground with its
// number over it (tool/make_colmado_sprites_test.dart's sheetPicture), and a list of the numbers beside the picture.
//
//   flutter test tool/make_frutas_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/frutas-sprites.png and .txt.
import 'dart:io';

import 'package:coqui_scenes/src/frutas/frutas_sprites.dart';
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

void main() {
  test('the sprite sheet of Las frutas', () {
    final sprites = frutasSpriteSheet();
    final p = sheetPicture(sprites);
    writePng(_port('frutas-sprites.png'), p.px, p.w, p.h, scale: 3);
    File(_port('frutas-sprites.txt')).writeAsStringSync(
      [
        "What only Las frutas has (lib/src/frutas/frutas_sprites.dart), at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.",
        'Made by coqui/packages/core/coqui_scenes/tool/make_frutas_sprites_test.dart. Do not edit.',
        'Las frutas also uses the cast of colmado-sprites.png (don Pepe, the goat standing, chewing and with its neck out, coins, bags) and, from mostrador-sprites.png, the open basket, the list and the señora.',
        '',
        for (var n = 0; n < sprites.length; n++)
          '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
        '',
      ].join('\n'),
    );
  });
}
