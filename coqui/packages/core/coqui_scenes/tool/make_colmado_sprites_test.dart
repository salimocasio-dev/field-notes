// The sprite sheets for the content lane, who looks at every new drawing (page 13, orders 50 to 53, step b point 3):
// every sprite and pose of El colmado's cast (lib/src/colmado/colmado_cast.dart) and of what only El mostrador has
// (lib/src/mostrador/mostrador_sprites.dart), each at 3x on a plain ground with its number over it, and a list of the
// numbers beside each picture.
//
//   flutter test tool/make_colmado_sprites_test.dart        (in this package)
//
// writes docs/proyecto/pixel/port/colmado-sprites.png and .txt, mostrador-sprites.png and .txt.
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/colmado/colmado_cast.dart';
import 'package:coqui_scenes/src/mostrador/mostrador_sprites.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/png.dart';

// a 3 x 5 numeral font, one string a numeral
const List<String> _digits = [
  '###'
      '#.#'
      '#.#'
      '#.#'
      '###',
  '.#.'
      '##.'
      '.#.'
      '.#.'
      '###',
  '###'
      '..#'
      '###'
      '#..'
      '###',
  '###'
      '..#'
      '###'
      '..#'
      '###',
  '#.#'
      '#.#'
      '###'
      '..#'
      '..#',
  '###'
      '#..'
      '###'
      '..#'
      '###',
  '###'
      '#..'
      '###'
      '#.#'
      '###',
  '###'
      '..#'
      '..#'
      '..#'
      '..#',
  '###'
      '#.#'
      '###'
      '#.#'
      '###',
  '###'
      '#.#'
      '###'
      '..#'
      '###',
];

const int _ground = 0xFFE4E0D8, _cell = 0xFFF2EFE8, _ink = 0xFF282020;

/// The sheet picture of [sprites] (each with its name), [cols] to a row; its numbers start at 1.
({Uint32List px, int w, int h}) sheetPicture(
  List<(String, Sprite)> sprites, {
  int cols = 8,
}) {
  final cw = sprites.map((s) => s.$2.w).reduce((a, b) => a > b ? a : b) + 6,
      ch = sprites.map((s) => s.$2.h).reduce((a, b) => a > b ? a : b) + 14;
  final rows = (sprites.length + cols - 1) ~/ cols,
      w = cols * cw,
      h = rows * ch;
  final px = Uint32List(w * h)..fillRange(0, w * h, _ground);
  for (var n = 0; n < sprites.length; n++) {
    final x0 = (n % cols) * cw, y0 = (n ~/ cols) * ch, s = sprites[n].$2;
    for (var y = 1; y < ch - 1; y++) {
      for (var x = 1; x < cw - 1; x++) {
        px[(y0 + y) * w + x0 + x] = _cell;
      }
    }
    final label = '${n + 1}';
    for (var d = 0; d < label.length; d++) {
      final g = _digits[label.codeUnitAt(d) - 48];
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 3; c++) {
          if (g[r * 3 + c] != '#') continue;
          px[(y0 + 3 + r) * w + x0 + 3 + d * 4 + c] = _ink;
        }
      }
    }
    final ox = x0 + (cw - s.w) ~/ 2, oy = y0 + 11 + (ch - 14 - s.h);
    for (var y = 0; y < s.h; y++) {
      for (var x = 0; x < s.w; x++) {
        final c = s.px[y * s.w + x];
        if (c >>> 24 != 0) px[(oy + y) * w + ox + x] = c;
      }
    }
  }
  return (px: px, w: w, h: h);
}

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
      'Made by coqui/packages/core/coqui_scenes/tool/make_colmado_sprites_test.dart. Do not edit.',
      '',
      for (var n = 0; n < sprites.length; n++)
        '${n + 1}. ${sprites[n].$1} (${sprites[n].$2.w} x ${sprites[n].$2.h})',
      '',
    ].join('\n'),
  );
}

void main() {
  test('the sprite sheets of El colmado', () {
    _write(
      'colmado-sprites',
      "El colmado's cast (lib/src/colmado/colmado_cast.dart)",
      colmadoCastSheet(),
    );
    _write(
      'mostrador-sprites',
      "What only El mostrador has (lib/src/mostrador/mostrador_sprites.dart)",
      mostradorSpriteSheet(),
    );
  });
}
