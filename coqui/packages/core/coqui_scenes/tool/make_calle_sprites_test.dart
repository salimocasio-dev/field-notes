// The sprite sheets for the content lane, who looks at every new drawing (page 13, orders 54 to 57; as orders 50 to 53,
// step b point 3): every sprite and pose of La calle's cast and its vehicles (lib/src/calle/calle_cast.dart,
// calle_vehicles.dart) and of what only La esquina has (lib/src/esquina/esquina_sprites.dart), each at 3x on a plain
// ground with its number over it (tool/make_colmado_sprites_test.dart's sheetPicture), and a list of the numbers beside
// each picture.
//
//   flutter test tool/make_calle_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/calle-sprites.png and .txt (and esquina-sprites.png and .txt).
import 'dart:io';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/calle/calle_cast.dart';
import 'package:coqui_scenes/src/esquina/esquina_sprites.dart';
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

void _write(String name, String title, List<(String, Sprite)> sprites) {
  final p = sheetPicture(sprites);
  writePng(_port('$name.png'), p.px, p.w, p.h, scale: 3);
  File(_port('$name.txt')).writeAsStringSync(
    [
      '$title, at 3x: ${sprites.length} sprites, numbered left to right, top to bottom.',
      'Made by coqui/packages/core/coqui_scenes/tool/make_calle_sprites_test.dart. Do not edit.',
      '',
      for (var n = 0; n < sprites.length; n++)
        '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
      '',
    ].join('\n'),
  );
}

void main() {
  test('the sprite sheets of La calle', () {
    _write(
      'calle-sprites',
      "La calle's cast and vehicles (lib/src/calle/calle_cast.dart, calle_vehicles.dart)",
      calleCastSheet(),
    );
    _write(
      'esquina-sprites',
      "What only La esquina has (lib/src/esquina/esquina_sprites.dart)",
      esquinaSpriteSheet(),
    );
  });
}
