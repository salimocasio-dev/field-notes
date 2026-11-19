// The pictures of El frente as ScenePictures draws them at the sizes other features ask for, for a person to look at. Not
// part of the package's tests: run it on the vm with
//
//   COQUI_OUT=<dir> flutter test tool/make_cells_test.dart
//
// It writes, under COQUI_OUT, each picture enlarged 4x (nearest neighbour):
//   review/<word>.<side>.png   the 24 review pictures, 196 x 104 picture pixels (accents left out of the file name)
//   cells/nivel.<word>.<index>.png   the 9 cells of the level check that use El frente, 96 x 106
//   cells-contact.png          the 9 cells in a grid, three to a row, in the order of the sheet's `level`: no text in it
//   cells-contact.key.txt      which cell is where, and what each is
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/support/pairs.dart';
import '../test/support/png.dart';

String ascii(String s) => s
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ñ', 'n')
    .replaceAll(' ', '_');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final out = Platform.environment['COQUI_OUT'];

  test('the review pictures and the level cells of El frente', () async {
    if (out == null) {
      markTestSkipped('set COQUI_OUT');
      return;
    }
    final pairs = frentePairs();
    final byWord = {for (final p in pairs) p.word: p};
    final items = {for (final i in frenteLevelItems()) i.word: i};
    final source = ScenePictures(pairs: pairs);
    final sheet = (await source.frameOf('frente')).scene.sheet;

    for (final p in pairs) {
      for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
        final px = await source.pixels(PictureRef.of(p, spec));
        writePng(
          '$out/review/${ascii(p.word)}.$side.png',
          px,
          196,
          104,
          scale: 4,
        );
      }
    }

    final cells = <Uint32List>[];
    final key = StringBuffer()
      ..writeln(
        'cells-contact.png: the 9 cells of the level check that use El frente, each 96 x 106 picture pixels, 4x, three to a '
        'row, left to right then top to bottom, 8 picture pixels between them (the grey is not part of a cell).',
      );
    for (final (n, l) in sheet.level.indexed) {
      final ref = PictureRef.ofLevel(items[l.word]!, l.index, pairs: byWord);
      final px = await source.pixels(ref, width: 96, height: 106);
      cells.add(px);
      writePng(
        '$out/cells/nivel.${ascii(l.word)}.${l.index}.png',
        px,
        96,
        106,
        scale: 4,
      );
      key.writeln(
        'row ${n ~/ 3 + 1}, column ${n % 3 + 1}: level item "${l.word}", picture ${l.index} (${ref.name}): the picture '
        '"${l.picture}" (${sheet.pictures[l.picture]!.what}); zoom ${l.zoom}, crop ${l.crop}; cells/nivel.${ascii(l.word)}.${l.index}.png',
      );
    }
    const gap = 8, grey = 0xFF303030;
    final w = 3 * 96 + 4 * gap, h = 3 * 106 + 4 * gap;
    final sheetPx = Uint32List(w * h)..fillRange(0, w * h, grey);
    for (final (n, px) in cells.indexed) {
      final ox = gap + (n % 3) * (96 + gap), oy = gap + (n ~/ 3) * (106 + gap);
      for (var y = 0; y < 106; y++) {
        for (var x = 0; x < 96; x++) {
          sheetPx[(oy + y) * w + ox + x] = px[y * 96 + x];
        }
      }
    }
    writePng('$out/cells-contact.png', sheetPx, w, h, scale: 4);
    File('$out/cells-contact.key.txt').writeAsStringSync(key.toString());
  });
}
