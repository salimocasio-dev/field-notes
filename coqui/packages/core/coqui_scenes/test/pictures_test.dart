// ScenePictures, the PictureSource of coqui_scenes: every picture of the 12 pairs of cual-frente and every level picture
// that uses El frente draws through it, as the sheet crops it; a scene that is not converted fails clearly.
import 'package:coqui_scenes/coqui_scenes.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/pairs.dart';
import 'support/sheet_bundle.dart';

/// The two sides a PictureRef alone cannot tell apart: the same scene, state and view, cropped differently by the sheet.
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

const ambiguous = {'abuela.si', 'cierra.no'};

void main() {
  final pairs = frentePairs();

  testWidgets('the 24 pictures of the 12 pairs draw through ScenePictures', (
    tester,
  ) async {
    expect(pairs, hasLength(12));
    final source = ScenePictures(pairs: pairs, bundle: SheetBundle());
    final sheet = (await tester.runAsync(() => source.frameOf('frente')))!
        .scene
        .sheet;
    for (final p in pairs) {
      for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
        final name = '${p.word}.$side', ref = PictureRef.of(p, spec);
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(width: 196, child: source.of(ref)),
          ),
        );
        await tester.runAsync(() async => tester.pump());
        await tester.pump();
        if (ambiguous.contains(name)) {
          // a plain reference cannot say which of the two it is (see the request filed by order 14)
          expect(find.byType(PixelView), findsNothing, reason: name);
          expect(
            find.textContaining('which the sheet crops differently'),
            findsOneWidget,
            reason: name,
          );
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: SizedBox(width: 196, child: source.ofPicture(ref, name)),
            ),
          );
          await tester.runAsync(() async => tester.pump());
          await tester.pump();
        }
        final view = tester.widget<PixelView>(find.byType(PixelView));
        expect([view.width, view.height], [196, 104], reason: name);
        final want = (await tester.runAsync(
          () => source.pixels(ref, name: name),
        ))!;
        expect(
          view.pixels,
          want,
          reason: '$name is drawn as the sheet crops it',
        );
        expect(sheet.pictures.containsKey(name), isTrue);
      }
    }
    await settle(tester);
  });

  testWidgets(
    'the level pictures that use El frente draw through ScenePictures',
    (tester) async {
      final source = ScenePictures(pairs: pairs, bundle: SheetBundle());
      final sheet = (await tester.runAsync(() => source.frameOf('frente')))!
          .scene
          .sheet;
      expect(sheet.level, hasLength(9));
      for (final l in sheet.level) {
        final word = l.picture.split('.').first,
            side = l.picture.split('.').last;
        final p = pairs.firstWhere((p) => p.word == word);
        final ref = PictureRef.of(p, side == 'si' ? p.yes : p.no);
        final px = (await tester.runAsync(
          () => source.pixels(ref, name: l.picture),
        ))!;
        expect(px, hasLength(196 * 104));
        expect(
          sheet.pictures[l.picture]!.crop,
          l.crop,
          reason: '${l.word} ${l.index}: the level picture is its pair picture',
        );
      }
    },
  );

  testWidgets(
    'a picture of a scene that is not converted says so, and draws nothing',
    (tester) async {
      final source = ScenePictures(bundle: SheetBundle());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 196,
            child: source.of(
              const PictureRef(scene: 'balcon', cam: [0, 0, 196, 104]),
            ),
          ),
        ),
      );
      await tester.runAsync(() async => tester.pump());
      await tester.pump();
      expect(find.byType(PixelView), findsNothing);
      expect(find.textContaining('not converted yet'), findsOneWidget);
    },
  );

  testWidgets(
    'an animated picture keeps ticking: the wind and the scene\'s own motion',
    (tester) async {
      final source = ScenePictures(pairs: pairs, bundle: SheetBundle());
      final p = pairs.firstWhere((p) => p.word == 'casa');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 196,
            child: source.of(PictureRef.of(p, p.yes), animated: true),
          ),
        ),
      );
      await tester.runAsync(() async => tester.pump());
      await tester.pump();
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
}
