// The module, and the three features added in order 25, restyled in Noche (N4.7):
//
//   M1  the module: the tab `me`, labelled from course.language.tabNames['me'], answers LanguagesRoute
//   N1  the build number, from Services.info.build, 12 px NocheColors.label, at the very foot of Me
//   N2  About: a row at the foot of Me, a NocheSheet with the credit line and the licence text under it
//   N3  on an iPhone in the browser, not installed: a one-time Noche hint, dismissible, remembered in space `yo`
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/about_sheet.dart';
import 'package:feature_profile/src/languages_sheet.dart';
import 'package:feature_profile/src/licence_text.dart';
import 'package:feature_profile/src/plans_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

const hint = 'To install: Share, then Add to Home Screen';
const credit = 'Map and scene engine: Pixel Plays by Amir Mushich (MIT)';

void main() {
  group('M1 the module', () {
    test('it is `me`, gives the tab `me` labelled from course language, answers LanguagesRoute and PlansRoute, and answers no other route', () {
      const module = ProfileModule();
      final s = fakeServices();
      expect(module.id, 'me');
      expect(module.tab(s)!.id, 'me');
      expect(module.tab(s)!.label, 'Yo');

      final arabicServices = fakeServices(
        course: FakeCourseCatalog(language: arabicTestLanguage),
      );
      expect(
        module.tab(arabicServices)!.label,
        arabicTestLanguage.tabNames['me'],
      );

      expect(
        module.screenFor(const LanguagesRoute(), s),
        isA<LanguagesSheet>(),
      );
      expect(module.screenFor(const PlansRoute(), s), isA<PlansScreen>());
      for (final r in <AppRoute>[
        const StoryRoute('x'),
        const ReviewRoute(),
        const LevelCheckRoute(),
        const BookRoute('x'),
        const CallRoute('casa'),
        const VoiceTestRoute(),
        const TabRoute('me'),
        const ImportRoute(),
        const PlaceRoute('casa'),
      ]) {
        expect(module.screenFor(r, s), isNull);
      }
    });
  });

  group('N1 the build number', () {
    testWidgets(
      '"build 39" for build 39, "build dev" without a number, at the very foot',
      (tester) async {
        final f = fixture(seed: 'curso', build: '39');
        await pumpYo(tester, f);
        expect(find.byKey(const Key('build-number')), findsOneWidget);
        expect(
          tester.widget<Text>(find.byKey(const Key('build-number'))).data,
          'build 39',
        );
        final g = fixture(seed: 'curso');
        await pumpYo(tester, g);
        expect(
          tester.widget<Text>(find.byKey(const Key('build-number'))).data,
          'build dev',
        );
        final all = yoTexts(tester);
        expect(all.last, 'build dev');
        expect(all.contains('About'), isTrue);
        expect(all.indexOf('About'), lessThan(all.indexOf('build dev')));
      },
    );

    testWidgets('small and label-coloured: 12 px, NocheColors.label', (
      tester,
    ) async {
      final f = fixture(seed: 'curso', build: '39');
      await pumpYo(tester, f);
      final style = tester
          .widget<Text>(find.byKey(const Key('build-number')))
          .style!;
      expect(style.fontSize, 12);
      expect(style.color, NocheColors.label);
    });
  });

  group('N2 About', () {
    testWidgets(
      'a row at the foot of Me opens a NocheSheet; nothing is written',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f);
        expect(find.byKey(const Key('about-row')), findsOneWidget);
        expect(sheetOpen(tester), isFalse);
        final saves = f.progress.saves;
        await tester.tap(find.byKey(const Key('about-row')));
        await settle(tester);
        expect(sheetOpen(tester), isTrue);
        expect(find.byType(NocheSheet), findsOneWidget);
        expect(f.progress.saves, saves);
        expect(f.nav.routes, isEmpty);
      },
    );

    testWidgets(
      'the sheet says exactly the credit line, then the licence text under it',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f, about: true);
        final texts = textsOf(tester, find.byKey(const ValueKey('about')));
        expect(texts.first, credit);
        expect(texts.skip(1).toList(), licenceParagraphs());
        expect(texts.length, greaterThan(2));
      },
    );

    test('the licence text is the file of coqui_pixel, word for word', () {
      final file = File('../../core/coqui_pixel/LICENSE-pixel-plays.txt');
      expect(file.existsSync(), isTrue, reason: 'run the test in the package');
      String words(String s) =>
          s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).join(' ');
      expect(pixelPlaysLicence.trim(), file.readAsStringSync().trim());
      expect(
        words(licenceParagraphs().join(' ')),
        words(file.readAsStringSync()),
      );
      expect(licenceParagraphs().first, 'MIT License');
      expect(licenceParagraphs()[1], contains('Amir Mushich'));
    });

    testWidgets('the close button closes the sheet', (tester) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      final closeBtn = find.descendant(
        of: find.byType(NocheSheet),
        matching: find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeSheet)),
      );
      await tester.tap(closeBtn);
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets('a tap on the scrim above the sheet closes it', (tester) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets('How Coquí works still opens its sheet after About was open', (
      tester,
    ) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      expect(find.text('Welcome to Coquí'), findsOneWidget);
    });
  });

  group('N3 the install hint', () {
    Finder hintFinder() => find.text(hint);

    testWidgets(
      'on an iPhone in the browser, not installed: the Noche card, at the top, with its words exactly',
      (tester) async {
        final f = fixture(seed: 'curso', ios: true);
        await pumpYo(tester, f);
        expect(hintFinder(), findsOneWidget);
        expect(find.byKey(const Key('install-hint')), findsOneWidget);
        final all = yoTexts(tester);
        expect(all.take(3).toList(), ['Me', 'How Coquí works', hint]);
        expect(
          find.descendant(
            of: find.byKey(const Key('install-hint')),
            matching: find.byType(NocheCard),
          ),
          findsOneWidget,
        );
      },
    );

    for (final c in [
      ('an Android phone in the browser', false, false, true),
      ('a desktop browser', false, false, true),
      ('an iPhone opened from the home screen', true, true, true),
      ('the iPhone app (not the web)', true, false, false),
    ]) {
      testWidgets('not on ${c.$1}', (tester) async {
        final f = fixture(seed: 'curso', ios: c.$2, installed: c.$3, web: c.$4);
        await pumpYo(tester, f);
        expect(hintFinder(), findsNothing);
        expect(f.spaces['yo']?.values ?? {}, isEmpty);
      });
    }

    testWidgets(
      'it is dismissible: the X takes it away, and it stays away while the app runs',
      (tester) async {
        final f = fixture(seed: 'curso', ios: true);
        await pumpYo(tester, f);
        await tester.tap(find.byKey(const Key('install-hint-close')));
        await settle(tester);
        expect(hintFinder(), findsNothing);
        f.progress.addMinutes(1);
        await settle(tester);
        expect(hintFinder(), findsNothing);
      },
    );

    testWidgets(
      'it is shown once: remembered in this feature\'s own space `yo`, never in the progress store',
      (tester) async {
        final f = fixture(seed: 'curso', ios: true);
        final before = f.progress.export();
        final saves = f.progress.saves;
        await pumpYo(tester, f);
        expect(hintFinder(), findsOneWidget);
        expect(f.spaces.keys, ['yo']);
        expect(f.spaces['yo']!.values, hasLength(1));
        expect(f.progress.export(), before);
        expect(f.progress.saves, saves);
        final again = f.reload();
        await pumpYo(tester, again);
        expect(hintFinder(), findsNothing);
      },
    );

    testWidgets(
      'a space that has not seen it shows it again (it is the space that remembers)',
      (tester) async {
        final f = fixture(seed: 'curso', ios: true);
        await pumpYo(tester, f);
        expect(hintFinder(), findsOneWidget);
        final other = fixture(seed: 'curso', ios: true);
        await pumpYo(tester, other);
        expect(hintFinder(), findsOneWidget);
      },
    );
  });
}
