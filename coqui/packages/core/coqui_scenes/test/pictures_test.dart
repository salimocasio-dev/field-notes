// ScenePictures, the PictureSource of coqui_scenes: every picture of the 12 pairs of cual-frente and every level cell that
// uses El frente draws through it, found by its name and cut as the sheet and the size rule say; a scene that is not
// converted shows its old picture.
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Sheet;
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_scenes/src/old_pictures.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/content_files.dart';
import 'support/fixtures/old_hashes.dart';
import 'support/hash.dart';
import 'support/pairs.dart';
import 'support/sheet_bundle.dart';

/// Ends a test with nothing left waiting (the picture's upload in a browser leaves a zero-length timer).
Future<void> settle(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
}

/// Shows [w] and waits for what it loads (real time: the sheet, the baking, an image decode, which a browser does slowly)
/// until there is a picture or an error to read.
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

/// What the picture of [px] must be: the region of [pic] (240 x 216) as the size rule says, written out: [x], [y], [w],
/// [h] then each pixel as a [zoom] x [zoom] block.
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

String errorText(WidgetTester tester) {
  final texts = tester.widgetList<Text>(find.byType(Text)).toList();
  return texts.map((t) => t.data ?? '').join('\n');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final pairs = frentePairs();
  final byWord = {for (final p in pairs) p.word: p};
  final items = {for (final i in frenteLevelItems()) i.word: i};

  group('El frente (converted)', () {
    testWidgets(
      'the 24 pictures of the 12 pairs draw through ScenePictures, by their names',
      (tester) async {
        expect(pairs, hasLength(12));
        final source = ScenePictures(bundle: testBundle());
        final frame = (await tester.runAsync(() => source.frameOf('frente')))!;
        final sheet = frame.scene.sheet;
        for (final p in pairs) {
          for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
            final name = '${p.word}.$side', ref = PictureRef.of(p, spec);
            expect(ref.name, name);
            await show(tester, source.of(ref));
            final view = tester.widget<PixelView>(find.byType(PixelView));
            expect([view.width, view.height], [196, 104], reason: name);
            // the picture the sheet's own cut makes of the frame the source just drew (abuela.si and cierra.no too)
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
          }
        }
        await settle(tester);
      },
    );

    testWidgets(
      'the 9 level cells that use El frente are 96 x 106 at zoom 1, found by their level names',
      (tester) async {
        final source = ScenePictures(bundle: testBundle());
        final frame = (await tester.runAsync(() => source.frameOf('frente')))!;
        final sheet = frame.scene.sheet;
        expect(sheet.level, hasLength(9));
        for (final l in sheet.level) {
          final item = items[l.word]!;
          final ref = PictureRef.ofLevel(item, l.index, pairs: byWord);
          expect(ref.name, 'nivel.${l.word}.${l.index}');
          expect(ref.scene, 'frente');
          // the level entry names the pair picture the cell uses
          final pic = item.pictures[l.index];
          expect('${pic[0]}.${pic[1]}', l.picture);
          expect(sheet.pictures[l.picture]!.crop, l.crop);
          await show(tester, source.of(ref, width: 96, height: 106));
          final view = tester.widget<PixelView>(find.byType(PixelView));
          expect(
            [view.width, view.height],
            [96, 106],
            reason: '${l.word} ${l.index}',
          );
          // the region: always 96 x 106, one picture pixel per pixel, centred on the centre of the entry's crop (a zoom-2
          // pair picture too)
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

    testWidgets(
      'a size that is not whole blocks fails clearly; a smaller whole one draws',
      (tester) async {
        final source = ScenePictures(bundle: testBundle());
        final p = byWord['puerta']!; // zoom 2
        final ref = PictureRef.of(p, p.yes);
        await show(tester, source.of(ref, width: 97, height: 104));
        expect(find.byType(PixelView), findsNothing);
        expect(errorText(tester), contains('not whole numbers'));
        await show(tester, source.of(ref, width: 100, height: 50));
        final view = tester.widget<PixelView>(find.byType(PixelView));
        expect([view.width, view.height, view.pixels.length], [100, 50, 5000]);
        await settle(tester);
      },
    );

    testWidgets(
      'a reference with no name is found by the review pairs, and fails when two pictures match',
      (tester) async {
        final source = ScenePictures(pairs: pairs, bundle: testBundle());
        PictureRef plain(ReviewPair p, PictureSpec s) =>
            PictureRef(scene: p.scene, set: s.set, cam: s.cam);
        // casa.si: no other picture has its state and view
        final casa = byWord['casa']!;
        final named = PictureRef.of(casa, casa.yes);
        await show(tester, source.of(plain(casa, casa.yes)));
        final byPairs = tester.widget<PixelView>(find.byType(PixelView)).pixels;
        await show(tester, source.of(named));
        expect(
          tester.widget<PixelView>(find.byType(PixelView)).pixels,
          byPairs,
        );
        // abuela.si and cierra.no share scene, state and view with another picture the sheet crops differently
        for (final (word, side) in [('abuela', 'si'), ('cierra', 'no')]) {
          final p = byWord[word]!, spec = side == 'si' ? p.yes : p.no;
          await show(tester, source.of(plain(p, spec)));
          expect(find.byType(PixelView), findsNothing, reason: '$word.$side');
          expect(
            errorText(tester),
            contains('which the sheet crops differently'),
            reason: '$word.$side',
          );
          await show(tester, source.of(PictureRef.of(p, spec)));
          expect(find.byType(PixelView), findsOneWidget, reason: '$word.$side');
        }
        await settle(tester);
      },
    );

    testWidgets('a name the sheet does not have fails clearly', (tester) async {
      final source = ScenePictures(bundle: testBundle());
      for (final name in ['nada.si', 'nivel.abuela.3', 'nivel.x']) {
        await show(
          tester,
          source.of(
            PictureRef(scene: 'frente', cam: const [0, 0, 1, 1], name: name),
          ),
        );
        expect(find.byType(PixelView), findsNothing, reason: name);
        expect(
          errorText(tester),
          contains('its sheet has no picture "$name"'),
          reason: name,
        );
      }
      await settle(tester);
    });

    testWidgets(
      'an animated picture keeps ticking: the wind and the scene\'s own motion',
      (tester) async {
        final source = ScenePictures(pairs: pairs, bundle: testBundle());
        final p = byWord['casa']!;
        await show(tester, source.of(PictureRef.of(p, p.yes), animated: true));
        final view = tester.widget<PixelView>(find.byType(PixelView));
        final first = List<int>.of(view.pixels);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 70));
        }
        expect(
          view.pixels,
          isNot(first),
          reason: 'ten ticks later the leaves and the butterflies have moved',
        );
        await settle(tester);
      },
      // In a browser the picture's upload (PixelView, decodeImageFromPixels) leaves a zero-length timer that the test
      // binding still counts as pending after the tree is gone, so this one runs on the vm only.
      skip: kIsWeb,
    );

    testWidgets(
      'a picture handed another picture in place shows the new one and no error box, animated or not',
      (tester) async {
        final source = ScenePictures(pairs: pairs, bundle: testBundle());
        final casa = byWord['casa']!, abuela = byWord['abuela']!;
        final refs = [
          PictureRef.of(casa, casa.yes),
          PictureRef.of(casa, casa.no),
          PictureRef.of(abuela, abuela.yes),
        ];
        final drawn = [
          for (final r in refs)
            (await tester.runAsync(() => source.pixels(r)))!,
        ];
        expect(drawn[0], isNot(drawn[1]));
        expect(drawn[1], isNot(drawn[2]));

        // one tree, the same widget in the same place each time: a state that is handed another picture
        Future<void> handed(int k, {required bool animated}) async {
          await show(tester, source.of(refs[k], animated: animated));
          final reason = 'picture $k, animated: $animated';
          expect(tester.takeException(), isNull, reason: reason);
          expect(
            find.byType(Text),
            findsNothing,
            reason: '$reason: no error box (${errorText(tester)})',
          );
          final view = tester.widget<PixelView>(find.byType(PixelView));
          expect(view.pixels, drawn[k], reason: '$reason: the new picture');
        }

        await handed(0, animated: false);
        // another picture, not animated, then the same pictures animated: the first ticker
        await handed(1, animated: false);
        await handed(0, animated: true);
        // an animated picture handed another animated picture: a second ticker (and a third, and one after a still one)
        await handed(1, animated: true);
        await handed(2, animated: true);
        await handed(0, animated: false);
        await handed(2, animated: true);
        // and it goes on moving after all that
        final view = tester.widget<PixelView>(find.byType(PixelView));
        final first = List<int>.of(view.pixels);
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 70));
        }
        expect(
          view.pixels,
          isNot(first),
          reason: 'the last picture is animated',
        );
        await settle(tester);
      },
      // as 'an animated picture keeps ticking': the picture's upload in a browser leaves a pending zero-length timer
      skip: kIsWeb,
    );

    testWidgets('warm bakes the states ahead', (tester) async {
      final source = ScenePictures(bundle: testBundle());
      final p = byWord['abuela']!;
      await tester.runAsync(
        () => source.warm([PictureRef.of(p, p.yes), PictureRef.of(p, p.no)]),
      );
      final frame = (await tester.runAsync(() => source.frameOf('frente')))!;
      expect(frame.bakes.keys, hasLength(2));
    });
  });

  group('a scene that is not converted shows its old picture', () {
    // the scene whose old pictures a browser test has (the last one that is not converted); on the vm every scene is there
    final scene = oldSampleScene, index = oldSampleIndex;
    final review = index.keys.firstWhere((n) => n.endsWith('.si'));
    final level = index.keys.firstWhere((n) => n.startsWith('nivel.'));
    PictureRef named(String name) =>
        PictureRef(scene: scene, cam: const [0, 0, 196, 104], name: name);

    testWidgets('a review picture is 196 x 104, a level cell 96 x 106', (
      tester,
    ) async {
      final source = ScenePictures(bundle: testBundle());
      await show(tester, source.of(named(review)));
      var view = tester.widget<PixelView>(find.byType(PixelView));
      expect([view.width, view.height], [196, 104]);
      expect(hashOf(view.pixels), oldHashes['$scene/$review']);
      await show(tester, source.of(named(level), width: 96, height: 106));
      view = tester.widget<PixelView>(find.byType(PixelView));
      expect([view.width, view.height], [96, 106]);
      expect(hashOf(view.pixels), oldHashes['$scene/$level']);
      await settle(tester);
    });

    testWidgets(
      'the names are the ones PictureRef.of and PictureRef.ofLevel make',
      (tester) async {
        final source = ScenePictures(bundle: testBundle());
        final word = review.substring(0, review.length - 3);
        final pair = ReviewPair(
          word: word,
          say: word,
          scene: scene,
          yes: PictureSpec(cam: const [0, 0, 196, 104]),
          no: PictureSpec(cam: const [0, 0, 196, 104]),
        );
        expect(PictureRef.of(pair, pair.yes).name, review);
        await show(tester, source.of(PictureRef.of(pair, pair.yes)));
        expect(
          hashOf(tester.widget<PixelView>(find.byType(PixelView)).pixels),
          oldHashes['$scene/$review'],
        );
        // a level cell: nivel.<item word>.<index>
        final parts = level.split('.');
        final item = LevelItem(
          word: parts[1],
          step: 1,
          pictures: [
            for (var i = 0; i < 4; i++) [word, 'si'],
          ],
        );
        final ref = PictureRef.ofLevel(
          item,
          int.parse(parts[2]),
          pairs: {word: pair},
        );
        expect(ref.name, level);
        await show(tester, source.of(ref, width: 96, height: 106));
        expect(
          hashOf(tester.widget<PixelView>(find.byType(PixelView)).pixels),
          oldHashes['$scene/$level'],
        );
        await settle(tester);
      },
    );

    testWidgets('any other size fails clearly', (tester) async {
      final source = ScenePictures(bundle: testBundle());
      for (final (w, h) in [(98, 52), (196, 106), (96, 104)]) {
        await show(tester, source.of(named(review), width: w, height: h));
        expect(find.byType(PixelView), findsNothing, reason: '$w x $h');
        expect(
          errorText(tester),
          allOf(contains('196 x 104'), contains('$w x $h')),
          reason: '$w x $h',
        );
      }
      await show(tester, source.of(named(level), width: 196, height: 104));
      expect(find.byType(PixelView), findsNothing);
      expect(errorText(tester), contains('96 x 106'));
      await settle(tester);
    });

    testWidgets(
      'a reference with no name fails clearly, saying how to make one',
      (tester) async {
        final source = ScenePictures(bundle: testBundle());
        await show(
          tester,
          source.of(PictureRef(scene: scene, cam: const [0, 0, 196, 104])),
        );
        expect(find.byType(PixelView), findsNothing);
        expect(
          errorText(tester),
          allOf(
            contains('not converted yet'),
            contains('PictureRef.of'),
            contains('ofLevel'),
          ),
        );
        await settle(tester);
      },
    );

    testWidgets(
      'a name with no old picture, and a scene that is not one, fail clearly',
      (tester) async {
        final source = ScenePictures(bundle: testBundle());
        await show(tester, source.of(named('nada.si')));
        expect(
          errorText(tester),
          contains('there is no old picture "nada.si"'),
        );
        await show(
          tester,
          source.of(
            PictureRef(
              scene: 'luna',
              cam: const [0, 0, 196, 104],
              name: 'x.si',
            ),
          ),
        );
        expect(errorText(tester), contains('"luna" is not a scene'));
        await settle(tester);
      },
    );

    testWidgets('animated does nothing for an old picture', (tester) async {
      final source = ScenePictures(bundle: testBundle());
      await show(tester, source.of(named(review), animated: true));
      final view = tester.widget<PixelView>(find.byType(PixelView));
      final first = List<int>.of(view.pixels);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 70));
      }
      expect(view.pixels, first);
      expect(hashOf(view.pixels), oldHashes['$scene/$review']);
      await settle(tester);
    });

    test(
      'warm decodes ahead, and fails for a reference it cannot find',
      () async {
        final source = ScenePictures(bundle: testBundle());
        await source.warm([named(review), named(level)]);
        expect(
          hashOf(await source.pixels(named(review))),
          oldHashes['$scene/$review'],
        );
        await expectLater(
          source.warm([
            PictureRef(scene: scene, cam: const [0, 0, 196, 104]),
          ]),
          throwsA(isA<PictureError>()),
        );
        await expectLater(
          source.warm([named('nada.si')]),
          throwsA(isA<PictureError>()),
        );
      },
    );

    test('every old picture of every scene that is not converted decodes to its hash', () async {
      final source = OldPictures(bundle: testBundle());
      var n = 0;
      for (final id in sceneRegistry.keys) {
        if (convertedScenes.contains(id)) continue;
        // on the vm every scene's folder is there; in a browser only the sample scene's
        if (kIsWeb && id != scene) continue;
        final idx = await source.indexOf(id);
        expect(idx, isNotEmpty, reason: id);
        for (final name in idx.keys) {
          final pic = await source.picture(id, name);
          final size = name.startsWith('nivel.') ? [96, 106] : [196, 104];
          expect([pic.width, pic.height], size, reason: '$id/$name');
          expect(
            hashOf(pic.pixels),
            oldHashes['$id/$name'],
            reason: '$id/$name',
          );
          n++;
        }
      }
      // on the vm: 379 old pictures of the 9 scenes not converted (El balcón's 36 went at order 30b)
      expect(n, greaterThan(kIsWeb ? 30 : 350));
    });
  });

  group('the names the content makes', () {
    // vm only: it reads historia/ (the review sets and the level items)
    final curso = historiaFile('datos/curso.json');
    test('every picture of every course item is in its scene\'s sheet or old pictures, and the level copy is the real one', () async {
      final course = jsonDecode(curso!) as Map<String, dynamic>;
      final all = <ReviewPair>[];
      for (final f in (course['cual'] as List).cast<String>()) {
        final j = jsonDecode(
          historiaFile('cuentos/$f.json')!,
        ) as Map<String, dynamic>;
        for (final it in j['items'] as List) {
          all.add(
            ReviewPair.fromJson(
              Map<String, dynamic>.from(it as Map),
              scene: j['scene'] as String,
            ),
          );
        }
      }
      final byWord = {for (final p in all) p.word: p};
      final levelItems = [
        for (final q in jsonDecode(historiaFile('datos/nivel.json')!) as List)
          LevelItem.fromJson(Map<String, dynamic>.from(q as Map)),
      ];
      // the frente items of the tests are the real ones
      for (final i in frenteLevelItems()) {
        expect(
          levelItems.firstWhere((l) => l.word == i.word).toJson(),
          i.toJson(),
        );
      }

      final refs = <PictureRef>[
        for (final p in all) ...[
          PictureRef.of(p, p.yes),
          PictureRef.of(p, p.no),
        ],
        for (final item in levelItems)
          for (var i = 0; i < item.pictures.length; i++)
            PictureRef.ofLevel(item, i, pairs: byWord),
      ];
      expect(refs, hasLength(2 * all.length + 4 * levelItems.length));
      final seen = <String>{};
      final source = ScenePictures(bundle: testBundle());
      final sheets = <String, Sheet>{
        for (final id in convertedScenes)
          id: (await source.frameOf(id)).scene.sheet,
      };
      final old = OldPictures(bundle: testBundle());
      var inSheet = 0, inOld = 0;
      for (final r in refs) {
        expect(r.name, isNotNull, reason: '$r');
        expect(
          seen.add('${r.scene}/${r.name}'),
          isTrue,
          reason: 'two pictures are ${r.scene}/${r.name}',
        );
        if (convertedScenes.contains(r.scene)) {
          final n = r.name!, sheet = sheets[r.scene]!;
          expect(
            sheet.pictures.containsKey(n) ||
                sheet.level.any((l) => 'nivel.${l.word}.${l.index}' == n),
            isTrue,
            reason: '${r.scene}: the sheet has no picture "$n"',
          );
          inSheet++;
        } else {
          final idx = await old.indexOf(r.scene);
          expect(
            idx.containsKey(r.name),
            isTrue,
            reason: '${r.scene}: no old picture "${r.name}"',
          );
          expect(oldHashes.containsKey('${r.scene}/${r.name}'), isTrue);
          inOld++;
        }
      }
      // each converted scene's sheet has exactly the pictures the content asks of it
      expect(
        inSheet,
        [
          for (final sheet in sheets.values)
            sheet.pictures.length + sheet.level.length,
        ].reduce((a, b) => a + b),
      );
      expect(inOld + inSheet, refs.length);
      expect(
        oldHashes.length,
        inOld,
        reason: 'every old picture is asked for by an item',
      );
    }, skip: curso == null ? 'reads historia/ (vm only)' : false);
  });
}
