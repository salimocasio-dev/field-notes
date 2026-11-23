// The sprite sheet of what La parada adds, for the content lane, who looks at every new drawing (page 13, orders 54 to
// 57; as orders 50 to 53, step b point 3): every sprite and pose of lib/src/parada/parada_sprites.dart and the guagua's
// looks added for La parada to La calle's vehicles (calle_vehicles.dart: `atras` the back door open, `puertas` both open,
// with each roof picture), each at 3x on a plain ground with its number over it (tool/make_colmado_sprites_test.dart's
// sheetPicture), and a list of the numbers beside the picture.
//
//   flutter test tool/parada_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/parada-sprites.png and .txt.
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_vehicles.dart';
import 'package:coqui_scenes/src/parada/parada_sprites.dart';
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
  test('the sprite sheet of La parada', () {
    final sprites = <(String, Sprite)>[
      ...paradaSpriteSheet(),
      for (final look in const ['atras', 'puertas'])
        for (final b in GUAGUA_BOARDS)
          (
            'guagua i $b, $look',
            vehicleSprite('guagua', 'i', board: b, look: look).s,
          ),
    ];
    final p = sheetPicture(sprites);
    writePng(_port('parada-sprites.png'), p.px, p.w, p.h, scale: 3);
    File(_port('parada-sprites.txt')).writeAsStringSync(
      [
        "What La parada adds (lib/src/parada/parada_sprites.dart; the guagua's looks atras and puertas, calle_vehicles.dart), at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.",
        'Made by coqui/packages/core/coqui_scenes/tool/parada_sprites_test.dart. Do not edit.',
        '',
        for (var n = 0; n < sprites.length; n++)
          '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
        '',
      ].join('\n'),
    );
  });
}
