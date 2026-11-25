// The module, and the three new things of order 25 (no old page to compare with: each is tested against the order's
// words).
//
//   M1  the module: the tab `me`, labelled Yo, and no route
//   N1  the build number, from Services.info.build, small and grey, at the foot of Yo
//   N2  About: a row at the foot of Yo, a sheet with exactly the credit line and the licence text under it
//   N3  on an iPhone in the browser, not installed: a one-time hint, dismissible, remembered in the feature's own space
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/about_sheet.dart';
import 'package:feature_profile/src/languages_sheet.dart';
import 'package:feature_profile/src/licence_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';
import 'support/harness.dart';

const hint = 'To install: Share, then Add to Home Screen';
const credit = 'Map and scene engine: Pixel Plays by Amir Mushich (MIT)';

void main() {
  group('M1 the module', () {
    test('it is `me`, gives the tab `me` labelled Yo, answers LanguagesRoute, and answers no other route', () {
      const module = ProfileModule();
      final s = fakeServices();
      expect(module.id, 'me');
      expect(module.tab(s)!.id, 'me');
      expect(module.tab(s)!.label, 'Yo');
      expect(
        module.screenFor(const LanguagesRoute(), s),
        isA<LanguagesSheet>(),
      );
      for (final r in <AppRoute>[
        const StoryRoute('x'),
        const ReviewRoute(),
        const LevelCheckRoute(),
        const BookRoute('x'),
        const CallRoute('casa'),
        const VoiceTestRoute(),
        const TabRoute('me'),
        const PlansRoute(),
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
        final all = textsOf(tester, find.byType(TabPage));
        expect(all.last, 'build dev');
        expect(all[all.length - 2], 'About');
        expect(all[all.length - 3], 'How it works');
      },
    );

    testWidgets(
      'small and grey: 12 px, the secondary colour, as the old meter labels',
      (tester) async {
        final f = fixture(seed: 'curso', build: '39');
        await pumpYo(tester, f);
        final style = tester
            .widget<Text>(find.byKey(const Key('build-number')))
            .style!;
        expect(style.fontSize, 12);
        expect(style.color, CoquiColors.mut);
      },
    );
  });

  group('N2 About', () {
    testWidgets('a row at the foot of Yo opens a sheet; nothing is written', (
      tester,
    ) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f);
      expect(find.byKey(const Key('about-row')), findsOneWidget);
      expect(sheetOpen(tester), isFalse);
      final saves = f.progress.saves;
      await tester.tap(find.byKey(const Key('about-row')));
      await settle(tester);
      expect(sheetOpen(tester), isTrue);
      expect(tester.widget<CoquiSheet>(find.byType(CoquiSheet)).modal, isFalse);
      expect(f.progress.saves, saves);
      expect(f.nav.routes, isEmpty);
    });

    testWidgets(
      'the sheet says exactly the credit line, then the licence text under it',
      (tester) async {
        final f = fixture(seed: 'curso');
        await pumpYo(tester, f, about: true);
        final texts = textsOf(tester, find.byType(CoquiSheet));
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

    testWidgets('the X closes the sheet', (tester) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      await tester.tap(find.byType(CoquiCloseButton));
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets('a tap on the page above the sheet closes it', (tester) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      await tester.tapAt(const Offset(200, 20));
      await settle(tester);
      expect(sheetOpen(tester), isFalse);
    });

    testWidgets('How it works still opens its own sheet after About was open', (
      tester,
    ) async {
      final f = fixture(seed: 'curso');
      await pumpYo(tester, f, about: true);
      await tester.tap(find.byType(CoquiCloseButton));
      await settle(tester);
      await tester.tap(find.byKey(const Key('yo-how-it-works')));
      await settle(tester);
      expect(find.text('Welcome to Coquí'), findsOneWidget);
    });
  });

  group('N3 the install hint', () {
    Finder hintFinder() => find.text(hint);

    testWidgets(
      'on an iPhone in the browser, not installed: the card, at the top, with its words exactly',
      (tester) async {
        final f = fixture(seed: 'curso', ios: true);
        await pumpYo(tester, f);
        expect(hintFinder(), findsOneWidget);
        expect(find.byKey(const Key('install-hint')), findsOneWidget);
        final all = textsOf(tester, find.byType(TabPage));
        expect(all.take(3).toList(), ['Yo', hint, '5']);
        expect(find.byType(CoquiFlame), findsOneWidget);
        // a card as v=39 draws them: white, 16 px corners
        final box = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(const Key('install-hint')),
                matching: find.byType(Container),
              )
              .first,
        );
        expect((box.decoration! as BoxDecoration).color, CoquiColors.card);
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
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('install-hint')),
            matching: find.byType(CoquiCloseButton),
          ),
        );
        await settle(tester);
        expect(hintFinder(), findsNothing);
        f.progress.addMinutes(1); // the page draws again
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
        // the app starts again on what was kept
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
