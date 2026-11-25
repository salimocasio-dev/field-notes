// Arabic / RTL language coverage for feature_words (N2.8).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:feature_words/src/text_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  group('text_rules with Arabic', () {
    test(
      'wordTokens preserves Arabic letters, strips diacritics, folds alef',
      () {
        expect(wordTokens('بيت', language: arabicTestLanguage), ['بيت']);
        expect(wordTokens('مرحباً', language: arabicTestLanguage), ['مرحبا']);
        expect(wordTokens('أغلق', language: arabicTestLanguage), ['اغلق']);
        expect(wordTokens('إلى', language: arabicTestLanguage), ['الى']);
        expect(wordTokens('بيت جدة', language: arabicTestLanguage), [
          'بيت',
          'جدة',
        ]);
        expect(wordTokens('', language: arabicTestLanguage), isEmpty);
        expect(wordTokens('!؟،.', language: arabicTestLanguage), isEmpty);
      },
    );

    test('occurrences matches Arabic words across diacritics, alef variants, phrases, and punctuation with UTF-16 offsets', () {
      const line1 = 'هذا بيت جدة.';
      final o1 = occurrences(line1, [
        wordTokens('بيت', language: arabicTestLanguage),
      ], language: arabicTestLanguage);
      expect(o1, hasLength(1));
      expect((o1.single.a, o1.single.z), (4, 7));
      expect(line1.substring(o1.single.a, o1.single.z), 'بيت');

      const line2 = 'تقول جدة: مرحباً! هل تريد كعكة؟';
      final o2 = occurrences(line2, [
        wordTokens('مرحبا', language: arabicTestLanguage),
      ], language: arabicTestLanguage);
      expect(o2, hasLength(1));
      expect(line2.substring(o2.single.a, o2.single.z), 'مرحباً');

      const line3 = 'أغلق الباب، ثم أغلق النافذة!';
      final o3 = occurrences(line3, [
        wordTokens('اغلق', language: arabicTestLanguage),
      ], language: arabicTestLanguage);
      expect([for (final o in o3) line3.substring(o.a, o.z)], ['أغلق', 'أغلق']);

      const line4 = 'انظر إلى بيت جدة الكبير، هل هذا بيت جدة؟';
      final o4 = occurrences(line4, [
        wordTokens('بيت جدة', language: arabicTestLanguage),
      ], language: arabicTestLanguage);
      expect(
        [for (final o in o4) line4.substring(o.a, o.z)],
        ['بيت جدة', 'بيت جدة'],
      );
    });
  });

  test('WordsModule uses Arabic tab label from course language', () {
    final s = fakeServices(course: FakeCourseCatalog.arabic());
    final tab = const WordsModule().tab(s)!;
    expect(tab.label, arabicTestLanguage.tabNames['words']);
    expect(tab.label, 'الكلمات');
  });

  group('WordsTab and WordSheet in Arabic', () {
    Future<Rig> arabicRig({FakeClipPlayer? clips}) async {
      final rig = Rig(course: FakeCourseCatalog.arabic(), clips: clips);
      await rig.playSampleStories();
      // Give mixed ear/mouth stages and due dates so Repaso and meters render meaningfully.
      rig.word('بيت', ear: 3, mouth: 2, due: 1);
      rig.word('باب', ear: 2, mouth: 1, due: 0);
      rig.word('مرحباً', ear: 2, mouth: 0, due: 2);
      // Extra word not in any played story so 'More words' also renders.
      rig.word('شمس', ear: 1, mouth: 0, due: 3);
      return rig;
    }

    for (final size in const [Size(390, 844), Size(360, 640)]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = await arabicRig();
          await pumpTab(tester, rig, size: size);
          expect(tester.takeException(), isNull);
          expect(find.text('الكلمات'), findsOneWidget);
          expect(find.text('البيت'), findsOneWidget);
          expect(find.text('More words'), findsOneWidget);
          for (final t in tester.widgetList<Text>(find.byType(Text))) {
            final r = tester.getRect(find.byWidget(t));
            expect(r.right, lessThanOrEqualTo(size.width + 0.5));
            expect(r.left, greaterThanOrEqualTo(-0.5));
          }
        },
      );
    }

    testWidgets(
      'keeps English chrome LTR while Arabic heading and WordGrid are RTL and pictures stay LTR',
      (tester) async {
        final rig = await arabicRig();
        await pumpTab(tester, rig);
        expect(tester.takeException(), isNull);

        // English chrome / menus remain English and LTR.
        final keyLineFinder = find.text(
          'Ear: you know it when you hear it. Mouth: you can say it.',
        );
        final addTitleFinder = find.text('Add a word or a goal');
        final moreWordsFinder = find.text('More words');
        final startButtonFinder = find.text('Start');
        expect(keyLineFinder, findsOneWidget);
        expect(addTitleFinder, findsOneWidget);
        expect(moreWordsFinder, findsOneWidget);
        expect(startButtonFinder, findsOneWidget);

        expect(
          Directionality.of(tester.element(keyLineFinder)),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(addTitleFinder)),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(moreWordsFinder)),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(startButtonFinder)),
          TextDirection.ltr,
        );

        // Arabic place heading 'البيت' is RTL with Locale('ar').
        final placeFinder = find.text('البيت');
        expect(placeFinder, findsOneWidget);
        final placeElement = tester.element(placeFinder);
        expect(Directionality.of(placeElement), TextDirection.rtl);
        expect(tester.widget<Text>(placeFinder).locale, const Locale('ar'));

        // WordGrid is RTL and places the first card to the right of the second card.
        final firstGridFinder = find.byType(WordGrid).first;
        expect(
          Directionality.of(tester.element(firstGridFinder)),
          TextDirection.rtl,
        );
        final gridCards = tester
            .widgetList<WordCard>(
              find.descendant(
                of: firstGridFinder,
                matching: find.byType(WordCard),
              ),
            )
            .toList();
        expect(gridCards.length, greaterThanOrEqualTo(2));
        final firstCardFinder = card(gridCards[0].word);
        final secondCardFinder = card(gridCards[1].word);
        expect(
          tester.getTopLeft(firstCardFinder).dx,
          greaterThan(tester.getTopLeft(secondCardFinder).dx),
        );

        // Pixel pictures inside pair WordCards stay LTR so scenes never mirror.
        final pairWordCard = find.byWidgetPredicate(
          (w) => w is WordCard && w.picture != null,
        );
        expect(pairWordCard, findsWidgets);
        final firstPictureCard = tester.widget<WordCard>(pairWordCard.first);
        final picture = firstPictureCard.picture!;
        expect(picture, isA<Directionality>());
        final pictureDir = picture as Directionality;
        expect(pictureDir.textDirection, TextDirection.ltr);
        expect(
          Directionality.of(tester.element(find.byWidget(pictureDir.child))),
          TextDirection.ltr,
        );

        // Tapping 'Start' navigates to ReviewRoute().
        await tester.tap(startButtonFinder);
        await tester.pumpAndSettle();
        expect(rig.nav.routes, [const ReviewRoute()]);

        // Adding a goal in AddBox saves and renders the saved note.
        await tester.ensureVisible(find.byType(TextField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Speak with Tariq');
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        expect(
          find.text('Saved. Material for it comes later.'),
          findsOneWidget,
        );
        expect(find.text('· Speak with Tariq'), findsOneWidget);
      },
    );

    testWidgets(
      'WordSheet for Arabic pair word renders RTL word & Heard in, LTR picture & English chrome, bolds matches, and plays/stops clip',
      (tester) async {
        final clips = GateClips();
        final rig = await arabicRig(clips: clips);
        await pumpTab(tester, rig);
        await tapCard(tester, 'بيت');
        expect(tester.takeException(), isNull);
        expect(sheet, findsOneWidget);

        // Big word 'بيت' has textDirection RTL and locale Locale('ar').
        final bigWordFinder = inSheet(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data == 'بيت' &&
                w.textAlign == TextAlign.center &&
                w.style == CoquiText.h1,
          ),
        );
        expect(bigWordFinder, findsOneWidget);
        final bigWord = tester.widget<Text>(bigWordFinder);
        expect(bigWord.textDirection, TextDirection.rtl);
        expect(bigWord.locale, const Locale('ar'));

        // Picture inside PictureFrame has Directionality LTR.
        final frameFinder = inSheet(find.byType(PictureFrame));
        expect(frameFinder, findsOneWidget);
        final frame = tester.widget<PictureFrame>(frameFinder);
        expect(frame.child, isA<Directionality>());
        expect(
          (frame.child as Directionality).textDirection,
          TextDirection.ltr,
        );

        // 'Heard in' heading and 'Comes back ...' stay English and LTR.
        final heardInFinder = inSheet(find.text('Heard in'));
        final comesBackFinder = inSheet(find.text('Comes back in 1 day'));
        expect(heardInFinder, findsOneWidget);
        expect(comesBackFinder, findsOneWidget);
        expect(
          Directionality.of(tester.element(heardInFinder)),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(comesBackFinder)),
          TextDirection.ltr,
        );

        // DividedRows inside 'Heard in' is RTL, placing trailing PlayButton to the left of text.
        final dividedRowsFinder = inSheet(find.byType(DividedRows));
        expect(dividedRowsFinder, findsOneWidget);
        expect(
          Directionality.of(tester.element(dividedRowsFinder)),
          TextDirection.rtl,
        );
        final firstRowPlay = find
            .descendant(
              of: dividedRowsFinder,
              matching: find.byType(PlayButton),
            )
            .first;
        final firstRowText = find
            .descendant(of: dividedRowsFinder, matching: find.byType(RichText))
            .first;
        expect(
          tester.getTopLeft(firstRowPlay).dx,
          lessThan(tester.getTopLeft(firstRowText).dx),
        );

        // Every 'Heard in' RichText line preserves original text and bolds 'بيت'.
        final expectedLines = await rig.course.linesWith('بيت', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        expect(expectedLines, isNotEmpty);

        final lineRichTexts = tester
            .widgetList<RichText>(
              find.descendant(
                of: dividedRowsFinder,
                matching: find.byType(RichText),
              ),
            )
            .where(
              (r) => expectedLines.any((l) => r.text.toPlainText() == l.text),
            )
            .toList();
        expect(lineRichTexts, hasLength(expectedLines.length));
        for (var i = 0; i < lineRichTexts.length; i++) {
          final r = lineRichTexts[i];
          expect(r.textDirection, TextDirection.rtl);
          expect(r.locale, const Locale('ar'));
          final bold = <String>[];
          r.text.visitChildren((s) {
            if (s is TextSpan &&
                s.text != null &&
                s.style?.fontWeight == FontWeight.w700) {
              bold.add(s.text!);
            }
            return true;
          });
          expect(bold, isNotEmpty);
          for (final b in bold) {
            expect(
              arabicTestLanguage.normalize(b).trim(),
              arabicTestLanguage.normalize('بيت').trim(),
            );
          }
          expect(r.text.toPlainText(), expectedLines[i].text);
        }

        // Tapping a PlayButton preloads and plays the clip; closing the sheet stops it.
        await tester.ensureVisible(inSheet(find.byType(PlayButton)).first);
        await tester.pumpAndSettle();
        await tester.tap(inSheet(find.byType(PlayButton)).first);
        await tester.pump();
        expect(clips.preloaded, [expectedLines.first.clipId]);
        expect(clips.played, [expectedLines.first.clipId]);

        final stopsBeforeClose = clips.stops;
        await tester.tap(inSheet(find.byType(CoquiCloseButton)));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(clips.stops, greaterThan(stopsBeforeClose));
      },
    );

    testWidgets(
      'WordSheet for Arabic word with diacritics (مرحباً) bolds matching token in Heard in line',
      (tester) async {
        final rig = await arabicRig();
        await pumpTab(tester, rig);
        await tapCard(tester, 'مرحباً');
        expect(tester.takeException(), isNull);
        expect(sheet, findsOneWidget);

        final expectedLines = await rig.course.linesWith('مرحباً', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        expect(expectedLines, isNotEmpty);

        final dividedRowsFinder = inSheet(find.byType(DividedRows));
        final lineRichTexts = tester
            .widgetList<RichText>(
              find.descendant(
                of: dividedRowsFinder,
                matching: find.byType(RichText),
              ),
            )
            .where(
              (r) => expectedLines.any((l) => r.text.toPlainText() == l.text),
            )
            .toList();
        expect(lineRichTexts, hasLength(expectedLines.length));
        for (final r in lineRichTexts) {
          final bold = <String>[];
          r.text.visitChildren((s) {
            if (s is TextSpan &&
                s.text != null &&
                s.style?.fontWeight == FontWeight.w700) {
              bold.add(s.text!);
            }
            return true;
          });
          expect(bold, contains('مرحباً'));
        }
      },
    );
  });
}
