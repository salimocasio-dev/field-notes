// Arabic / RTL language coverage for feature_words (N2.8 + N4.4).
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

  group('Noche WordsTab and WordSheet in Arabic (RTL)', () {
    Future<Rig> arabicRig({FakeClipPlayer? clips}) async {
      final rig = Rig(course: FakeCourseCatalog.arabic(), clips: clips);
      await rig.playSampleStories();
      rig.word('بيت', ear: 4, mouth: 2, mouthN: 2, due: 21, mouthDue: 1);
      rig.word('باب', ear: 2, mouth: 1, mouthN: 1, due: 0, mouthDue: 0);
      rig.word('مرحباً', ear: 2, mouth: 0, due: 2);
      rig.word('شمس', ear: 1, mouth: 0, due: 5);
      return rig;
    }

    for (final size in const [Size(390, 844), Size(412, 915)]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final rig = await arabicRig();
          await pumpTab(tester, rig, size: size);
          expect(tester.takeException(), isNull);
          expect(find.text('ARABIC'), findsOneWidget);
          expect(find.text('Words'), findsOneWidget);
          for (final t in tester.widgetList<Text>(find.byType(Text))) {
            final r = tester.getRect(find.byWidget(t));
            expect(r.right, lessThanOrEqualTo(size.width + 0.5));
            expect(r.left, greaterThanOrEqualTo(-0.5));
          }
        },
      );
    }

    testWidgets(
      'mirrors whole screen in RTL, marks Arabic words with Locale(ar) and Arabic font, and navigates to ReviewRoute',
      (tester) async {
        final rig = await arabicRig();
        await pumpTab(tester, rig);
        expect(tester.takeException(), isNull);

        // Whole screen mirrors for RTL course (Part 1.4).
        final wordsHeader = find.text('Words');
        final addPill = find.byKey(const Key('words-add-pill'));
        expect(
          Directionality.of(tester.element(wordsHeader)),
          TextDirection.rtl,
        );
        // In RTL, the header title ("start") stands to the right of the pill ("end").
        expect(
          tester.getTopLeft(wordsHeader).dx,
          greaterThan(tester.getTopLeft(addPill).dx),
        );

        // Arabic words carry Locale('ar') and Noto Sans Arabic via NocheType.forScript.
        final wordFinder = find.descendant(
          of: wordRow('باب'),
          matching: find.text('باب'),
        );
        expect(wordFinder, findsOneWidget);
        final wordText = tester.widget<Text>(wordFinder);
        expect(wordText.locale, const Locale('ar'));
        expect(wordText.style?.fontFamily, endsWith(nocheFontNotoSansArabic));

        // In RTL row, word ("start") is to the right of NocheStageBar ("end").
        final barFinder = find.descendant(
          of: wordRow('باب'),
          matching: find.byType(NocheStageBar),
        );
        expect(
          tester.getCenter(wordFinder).dx,
          greaterThan(tester.getCenter(barFinder).dx),
        );

        // Tapping Start review navigates to ReviewRoute().
        await tester.tap(find.text('Start review'));
        await tester.pumpAndSettle();
        expect(rig.nav.routes, [const ReviewRoute()]);

        // Adding a goal via the header pill saves and shows the saved note.
        await tester.tap(addPill);
        await tester.pumpAndSettle();
        await tester.enterText(
          inSheet(find.byType(TextField)),
          'Speak with Tariq',
        );
        await tester.tap(inSheet(find.text('Add')));
        await tester.pumpAndSettle();
        expect(
          inSheet(find.text('Saved. Material for it comes later.')),
          findsOneWidget,
        );
        expect(inSheet(find.text('· Speak with Tariq')), findsOneWidget);
      },
    );

    testWidgets(
      'WordSheet for Arabic pair word renders RTL word & Heard in, keeps picture LTR, bolds matches, and plays/stops clip',
      (tester) async {
        final clips = GateClips();
        final rig = await arabicRig(clips: clips);
        await pumpTab(tester, rig);
        await tapWordRow(tester, 'بيت');
        expect(tester.takeException(), isNull);
        expect(sheet, findsOneWidget);

        // Fixed header preserves the word while scrolling, and big word is RTL with Locale('ar').
        expect(tester.widget<NocheSheet>(sheet).title, 'بيت');
        final bigWordFinder = inSheet(
          find.byKey(const Key('word-sheet-heading')),
        );
        expect(bigWordFinder, findsOneWidget);
        final bigWord = tester.widget<Text>(bigWordFinder);
        expect(bigWord.data, 'بيت');
        expect(bigWord.textDirection, TextDirection.rtl);
        expect(bigWord.locale, const Locale('ar'));
        expect(bigWord.style?.fontFamily, endsWith(nocheFontNotoSansArabic));

        // Pixel picture inside ClipRRect stays LTR so scenes never mirror.
        final clipRectFinder = inSheet(find.byType(ClipRRect));
        expect(clipRectFinder, findsWidgets);
        final pictureDir = inSheet(
          find.byWidgetPredicate(
            (w) => w is Directionality && w.textDirection == TextDirection.ltr,
          ),
        );
        expect(pictureDir, findsWidgets);

        // Every 'Heard in' RichText line preserves original text and bolds 'بيت'.
        final expectedLines = await rig.course.linesWith('بيت', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        expect(expectedLines, isNotEmpty);

        final lineRichTexts = tester
            .widgetList<RichText>(inSheet(find.byType(RichText)))
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

        // Play button preloads & plays clip; closing sheet stops it.
        await tester.ensureVisible(sheetPlayButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(sheetPlayButtons.first);
        await tester.pump();
        expect(clips.preloaded, [expectedLines.first.clipId]);
        expect(clips.played, [expectedLines.first.clipId]);

        final stopsBeforeClose = clips.stops;
        await closeSheet(tester);
        expect(sheet, findsNothing);
        expect(clips.stops, greaterThan(stopsBeforeClose));
      },
    );

    testWidgets(
      'WordSheet for Arabic word with diacritics (مرحباً) bolds matching token in Heard in line',
      (tester) async {
        final rig = await arabicRig();
        await pumpTab(tester, rig);
        await tapWordRow(tester, 'مرحباً');
        expect(tester.takeException(), isNull);
        expect(sheet, findsOneWidget);

        final expectedLines = await rig.course.linesWith('مرحباً', [
          'la-lluvia',
          'el-bizcocho',
          'donde-esta-el-pajaro',
        ]);
        expect(expectedLines, isNotEmpty);

        final lineRichTexts = tester
            .widgetList<RichText>(inSheet(find.byType(RichText)))
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
