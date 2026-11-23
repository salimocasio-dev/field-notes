// The sprite sheet for the content lane, who looks at every new drawing (page 13, orders 54 to 57; as orders 50 to 53,
// step b point 3): every sprite and pose of what only Las tiendas has (lib/src/tiendas/tiendas_sprites.dart), each at 3x
// on a plain ground with its number over it (tool/make_colmado_sprites_test.dart's sheetPicture), and a list of the
// numbers beside the picture. La calle's cast it uses is on calle-sprites.png (tool/make_calle_sprites_test.dart).
//
//   flutter test tool/tiendas_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/tiendas-sprites.png and .txt.
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/tiendas/tiendas_sprites.dart';
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
  test('the sprite sheet of Las tiendas', () {
    final sprites = tiendasSpriteSheet();
    final List<(String, Sprite)> list = sprites;
    final p = sheetPicture(list);
    writePng(_port('tiendas-sprites.png'), p.px, p.w, p.h, scale: 3);
    File(_port('tiendas-sprites.txt')).writeAsStringSync(
      [
        "What only Las tiendas has (lib/src/tiendas/tiendas_sprites.dart), at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.",
        'Made by coqui/packages/core/coqui_scenes/tool/tiendas_sprites_test.dart. Do not edit.',
        'The stroller is tiendas-preview.html\'s stand-in (its size is the sheet\'s); every other look is the port\'s guess.',
        '',
        for (var n = 0; n < sprites.length; n++)
          '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
        '',
      ].join('\n'),
    );
  });
}
