// La mesa's review and level pictures through ScenePictures: the 24 pictures of its 12 review pairs, by their names (the
// sheet's names write a space as _, tengo hambre.si is tengo_hambre.si), are the sheet's crops of the frame (196 x 104,
// each pixel a zoom block: at zoom 2 or 1; cocina.no on the stored still of El colmado's stall), and the 16 level cells
// that use it are 96 x 106 at zoom 1 at the centre of their entries' crops. The places a pair's own W holds deeper than
// its top level (those who sit, stand, the things) go through the sheet's story moves (Mesa.placePair:
// mesa-preview.html's remapW for cual-mesa). (The same checks as El frente's in pictures_test.dart, and every converted
// scene's after it.)
import 'dart:typed_data';

import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/pictures.dart' show sheetPictureName;
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/pairs.dart';
import 'support/sheet_bundle.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

Future<void> show(WidgetTester tester, Widget w) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(alignment: Alignment.topLeft, child: w),
    ),
  );
  for (var i = 0; i < 200; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await tester.runAsync(() async => tester.pump());
    await tester.pump();
    if (find.byType(PixelView).evaluate().isNotEmpty ||
        find.byType(Text).evaluate().isNotEmpty) {
      return;
    }
  }
}

Uint32List blocks(
  Uint32List pic,
  List<int> region,
  int zoom,
  int width,
  int height,
) {
  expect(region[2] * zoom, width);
  expect(region[3] * zoom, height);
  final out = Uint32List(width * height);
  for (var y = 0; y < region[3]; y++) {
    for (var x = 0; x < region[2]; x++) {
      final v = pic[(region[1] + y) * 240 + region[0] + x];
      for (var j = 0; j < zoom; j++) {
        for (var i = 0; i < zoom; i++) {
          out[(y * zoom + j) * width + x * zoom + i] = v;
        }
      }
    }
  }
  return out;
}

String errorText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pairs = mesaPairs();
  // a level entry names its pair picture as the sheet does: the word with its accents and ñ folded, a space as _
  String fold(String w) => w
      .split('')
      .map((c) => 'áéíóúñ'.contains(c) ? 'aeioun'['áéíóúñ'.indexOf(c)] : c)
      .join()
      .replaceAll(' ', '_');
  final byFolded = {for (final p in pairs) fold(p.word): p};

  testWidgets(
    'the 24 pictures of the 12 pairs draw through ScenePictures, by their names',
    (tester) async {
      expect(pairs, hasLength(12));
      final source = ScenePictures(bundle: testBundle());
      final frame = (await tester.runAsync(() => source.frameOf('mesa')))!;
      final sheet = frame.scene.sheet;
      var n = 0;
      for (final p in pairs) {
        for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
          final name0 = '${p.word}.$side', ref = PictureRef.of(p, spec);
          expect(ref.scene, 'mesa');
          expect(ref.name, name0);
          final name = sheetPictureName(sheet, name0);
          await show(tester, source.of(ref));
          expect(
            find.byType(PixelView),
            findsOneWidget,
            reason: errorText(tester),
          );
          final view = tester.widget<PixelView>(find.byType(PixelView));
          expect([view.width, view.height], [196, 104], reason: name);
          final drawn = (await tester.runAsync(() => source.pixels(ref)))!;
          expect(view.pixels, drawn, reason: '$name is what pixels() draws');
          expect(
            view.pixels,
            sheet.pictureCrop(name, frame.engine, frame.picture).px,
            reason: '$name is the sheet\'s cut of the frame',
          );
          final c = sheet.pictures[name]!;
          expect(
            view.pixels,
            blocks(frame.picture, c.crop, c.zoom, 196, 104),
            reason: '$name is the sheet\'s crop, each pixel a zoom block',
          );
          n++;
        }
      }
      expect(n, 24);
      await settle(tester);
    },
  );

  testWidgets(
    'the 16 level cells that use La mesa are 96 x 106 at zoom 1, found by their level names',
    (tester) async {
      final source = ScenePictures(bundle: testBundle());
      final frame = (await tester.runAsync(() => source.frameOf('mesa')))!;
      final sheet = frame.scene.sheet;
      expect(sheet.level, hasLength(16));
      for (final l in sheet.level) {
        // the pair picture the cell uses, with its state, under the level entry's name
        final dot = l.picture.lastIndexOf('.');
        final p = byFolded[l.picture.substring(0, dot)]!,
            spec = l.picture.endsWith('.si') ? p.yes : p.no;
        final ref = PictureRef(
          scene: 'mesa',
          set: spec.set,
          cam: spec.cam,
          name: 'nivel.${l.word}.${l.index}',
        );
        expect(sheet.pictures[l.picture]!.crop, l.crop);
        await show(tester, source.of(ref, width: 96, height: 106));
        expect(
          find.byType(PixelView),
          findsOneWidget,
          reason: errorText(tester),
        );
        final view = tester.widget<PixelView>(find.byType(PixelView));
        expect([view.width, view.height], [96, 106]);
        const w = 96, h = 106;
        final cx = l.crop[0] + l.crop[2] / 2, cy = l.crop[1] + l.crop[3] / 2;
        final x = ((cx - w / 2) + .5).floor().clamp(0, 240 - w),
            y = ((cy - h / 2) + .5).floor().clamp(0, 216 - h);
        expect(
          view.pixels,
          blocks(frame.picture, [x, y, w, h], 1, 96, 106),
          reason: '${l.word} ${l.index}: ${l.picture} as a cell',
        );
      }
      await settle(tester);
    },
  );
}
