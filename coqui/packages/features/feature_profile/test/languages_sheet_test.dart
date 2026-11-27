import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_profile/src/language_chip.dart';
import 'package:feature_profile/src/languages_data.dart';
import 'package:feature_profile/src/languages_sheet.dart';
import 'package:feature_profile/src/motion.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/dev_app.dart';

const String _expectedFootLine =
    'Each language keeps its own map and its own words. Your streak and your minutes count across all of them.';

/// Test-only multi-place course wrapper for any [Language] (e.g. Arabic) using
/// the same 10-place structure as [DevCourse].
class _TenPlaceCourse extends FakeCourseCatalog {
  _TenPlaceCourse({required super.language, super.fetch})
    : _places = DevCourse().places;

  final List<Place> _places;

  @override
  List<Place> get places => _places;
}

void _setPhone(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double dpr = 3.0,
}) {
  tester.view.physicalSize = Size(size.width * dpr, size.height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

void _seedWords(FakeProgressStore store, int count, {String prefix = 'w'}) {
  for (var i = 0; i < count; i++) {
    store.heard('$prefix$i');
  }
}

void _finishPlaces(FakeProgressStore store, CourseCatalog course, int count) {
  for (final place in course.places.take(count)) {
    for (final storyId in place.stories) {
      store.storyFinished(StoryResult(id: storyId));
    }
  }
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required Services services,
  LanguagesSource? source,
  VoidCallback? onClose,
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
  Size size = const Size(390, 844),
  double dpr = 3.0,
  Widget? backdrop,
  Key? boundaryKey,
}) async {
  _setPhone(tester, size: size, dpr: dpr);
  Widget body = Stack(
    fit: StackFit.expand,
    children: [
      backdrop ??
          const ColoredBox(
            color: NocheColors.ground,
            child: Center(child: Text('underlying-screen')),
          ),
      LanguagesSheet(
        services: services,
        source: source,
        onClose: onClose,
        respectSafeArea: false,
      ),
    ],
  );
  if (boundaryKey != null) {
    body = RepaintBoundary(key: boundaryKey, child: body);
  }
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: coquiTheme(),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: textDirection,
            child: Scaffold(backgroundColor: NocheColors.ground, body: body),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('languages_data unit tests', () {
    test(
      'LanguageEntry.summaryLine formats singular, plural, and 0 places',
      () {
        final oneWord = LanguageEntry(
          language: Language.spanish,
          hasProgress: true,
          wordCount: 1,
          placeNumber: 1,
          placeTotal: 10,
        );
        expect(oneWord.summaryLine, 'A1 · place 1 of 10 · 1 word');

        final manyWords = LanguageEntry(
          language: Language.spanish,
          hasProgress: true,
          wordCount: 96,
          placeNumber: 3,
          placeTotal: 10,
        );
        expect(manyWords.summaryLine, 'A1 · place 3 of 10 · 96 words');

        final zeroWords = LanguageEntry(
          language: Language.spanish,
          hasProgress: false,
          wordCount: 0,
          placeNumber: 1,
          placeTotal: 1,
        );
        expect(zeroWords.summaryLine, 'A1 · place 1 of 1 · 0 words');

        final noPlaces = LanguageEntry(
          language: Language.spanish,
          hasProgress: true,
          wordCount: 5,
          placeNumber: 0,
          placeTotal: 0,
        );
        expect(noPlaces.summaryLine, 'A1 · 5 words');
      },
    );

    test('partitionLanguages puts current first, separates addable, deduplicates', () {
      final clock = FakeClock(referenceNowMs);
      final esCourse = DevCourse();
      final arCourse = _TenPlaceCourse(
        language: arabicTestLanguage,
        fetch: arabicSampleFile,
      );
      final shared = FakeProgressStore(clock: clock);
      final esStore = FakeProgressStore(clock: clock);
      final arStore = FakeProgressStore(clock: clock);
      _seedWords(esStore, 12);

      final source = CatalogLanguagesSource(
        courses: [esCourse, arCourse, esCourse],
        storeFor: (l) => l.code == 'ar' ? arStore : esStore,
        sharedStore: shared,
      );

      final first = partitionLanguages(source);
      expect(first.currentCode, 'es');
      expect(first.yourLanguages.map((e) => e.language.code), ['es']);
      expect(first.addableLanguages.map((e) => e.language.code), ['ar']);

      // Giving Arabic progress moves it into "Your languages" (after current).
      _seedWords(arStore, 4, prefix: 'a');
      final both = partitionLanguages(source);
      expect(both.yourLanguages.map((e) => e.language.code), ['es', 'ar']);
      expect(both.addableLanguages, isEmpty);

      // Switching active language to Arabic puts Arabic first.
      source.selectLanguage('ar');
      expect(shared.setting(currentLanguageSettingKey), 'ar');
      final arabicFirst = partitionLanguages(source);
      expect(arabicFirst.currentCode, 'ar');
      expect(arabicFirst.yourLanguages.map((e) => e.language.code), [
        'ar',
        'es',
      ]);
      expect(arabicFirst.addableLanguages, isEmpty);
    });

    test('selectLanguage rejects invalid codes', () {
      final f = fixture(seed: 'vacio');
      final source = ServicesLanguagesSource(f.services);
      expect(() => source.selectLanguage(''), throwsArgumentError);
      expect(() => source.selectLanguage('es.pr'), throwsArgumentError);
      expect(() => source.selectLanguage('es pr'), throwsArgumentError);
    });
  });

  group('LanguagesSheet — Spanish only', () {
    testWidgets(
      'opens on LanguagesRoute dimmed with scrim, shows Spanish card, hides Add a language, no sample languages',
      (tester) async {
        final clock = FakeClock(referenceNowMs);
        final esCourse = DevCourse();
        final esStore = FakeProgressStore(clock: clock);
        _finishPlaces(esStore, esCourse, 2);
        _seedWords(esStore, 96);
        final nav = FakeNavigator();
        final services = fakeServices(
          progress: esStore,
          course: esCourse,
          clock: clock,
          nav: nav,
        );

        final widget = const ProfileModule().screenFor(
          const LanguagesRoute(),
          services,
        );
        expect(widget, isA<LanguagesSheet>());

        _setPhone(tester);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(
                    color: NocheColors.ground,
                    child: Center(child: Text('map-behind')),
                  ),
                  widget!,
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Underlying screen stays behind, dimmed by NocheColors.scrim.
        expect(find.text('map-behind'), findsOneWidget);
        expect(find.byType(NocheSheetOverlay), findsOneWidget);
        final scrimBox = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .where((b) => b.color == NocheColors.scrim);
        expect(scrimBox, isNotEmpty);

        // Title and Spanish radio card.
        expect(find.byKey(const Key('languages-sheet')), findsOneWidget);
        expect(find.text('Your languages'), findsOneWidget);
        expect(find.text('Spanish'), findsOneWidget);
        expect(find.text('A1 · place 3 of 10 · 96 words'), findsOneWidget);

        // Card metrics: 72 high, 1 px line border on card, 2 px text outline
        // mark painted over the active card by NocheOutlineGroup, ground fill,
        // 32 check disc.
        final cardFinder = find.byKey(const ValueKey('language-card-es'));
        expect(cardFinder, findsOneWidget);
        expect(tester.getSize(cardFinder).height, 72);

        final cardContainer = tester
            .widgetList<Container>(
              find.descendant(of: cardFinder, matching: find.byType(Container)),
            )
            .first;
        final decoration = cardContainer.decoration! as BoxDecoration;
        expect(decoration.color, NocheColors.ground);
        expect(
          decoration.border,
          Border.all(color: NocheColors.line, width: 1),
        );

        final markFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        expect(markFinder, findsOneWidget);
        final markBox = tester.widget<DecoratedBox>(markFinder);
        final markDeco = markBox.decoration as BoxDecoration;
        expect(markDeco.border, Border.all(color: NocheColors.text, width: 2));
        expect(tester.getRect(markFinder), tester.getRect(cardFinder));

        // 32 check disc with check icon.
        final checkDisc = tester
            .widgetList<Container>(
              find.descendant(of: cardFinder, matching: find.byType(Container)),
            )
            .where((c) {
              final d = c.decoration;
              return d is BoxDecoration &&
                  d.shape == BoxShape.circle &&
                  d.color == NocheColors.text;
            })
            .single;
        expect(checkDisc.constraints?.minWidth, 32);
        expect(checkDisc.constraints?.minHeight, 32);

        // Line 1 uses NocheType.row (18/24).
        final nameText = tester.widget<Text>(find.text('Spanish'));
        expect(nameText.style?.fontSize, NocheType.row.fontSize);
        expect(nameText.style?.height, NocheType.row.height);

        // "Add a language" heading & rows hidden; never show sample languages.
        expect(find.text('ADD A LANGUAGE'), findsNothing);
        expect(find.text('Add a language'), findsNothing);
        expect(find.text('Switch'), findsNothing);
        for (final sample in const [
          'French',
          'Arabic',
          'Portuguese',
          'Italian',
        ]) {
          expect(find.text(sample), findsNothing);
        }

        // Exact foot line.
        expect(find.text(_expectedFootLine), findsOneWidget);
      },
    );

    testWidgets(
      'brand-new learner with 0 words still sees current Spanish card',
      (tester) async {
        final f = fixture(seed: 'vacio');
        await _pumpSheet(tester, services: f.services);

        expect(find.text('Spanish'), findsOneWidget);
        expect(find.text('A1 · place 1 of 10 · 0 words'), findsOneWidget);
        expect(find.text('ADD A LANGUAGE'), findsNothing);
        expect(find.text(_expectedFootLine), findsOneWidget);
      },
    );
  });

  group('LanguagesSheet — Spanish + Arabic fake course (LTR & RTL)', () {
    testWidgets(
      'shows Arabic under Add a language with native name in label colour, script font, locale, RTL direction, and plus icon; tapping adds/switches and returns to map',
      (tester) async {
        final clock = FakeClock(referenceNowMs);
        final esCourse = DevCourse();
        final arCourse = _TenPlaceCourse(
          language: arabicTestLanguage,
          fetch: arabicSampleFile,
        );
        await arCourse.load();
        final shared = FakeProgressStore(clock: clock);
        final esStore = FakeProgressStore(clock: clock);
        final arStore = FakeProgressStore(clock: clock);
        _finishPlaces(esStore, esCourse, 2);
        _seedWords(esStore, 96);

        final nav = FakeNavigator();
        final haptics = FakeHaptics();
        final services = fakeServices(
          progress: shared,
          course: esCourse,
          clock: clock,
          nav: nav,
          haptics: haptics,
        );
        final source = CatalogLanguagesSource(
          courses: [esCourse, arCourse],
          storeFor: (l) => l.code == 'ar' ? arStore : esStore,
          sharedStore: shared,
        );

        await _pumpSheet(tester, services: services, source: source);

        expect(find.text('Spanish'), findsOneWidget);
        expect(find.text('A1 · place 3 of 10 · 96 words'), findsOneWidget);
        expect(find.text('ADD A LANGUAGE'), findsOneWidget);

        final addRow = find.byKey(const ValueKey('add-language-ar'));
        expect(addRow, findsOneWidget);
        expect(tester.getSize(addRow).height, greaterThanOrEqualTo(56));

        expect(find.text('Arabic'), findsOneWidget);
        final nativeFinder = find.text(arabicTestLanguage.nativeName);
        expect(nativeFinder, findsOneWidget);
        final nativeText = tester.widget<Text>(nativeFinder);
        expect(nativeText.locale, const Locale('ar'));
        expect(nativeText.textDirection, TextDirection.rtl);
        expect(nativeText.style?.color, NocheColors.label);
        expect(
          nativeText.style?.fontFamily,
          NocheType.forScript(NocheType.bodyLarge, 'Arab').fontFamily,
        );

        // Plus icon present at end of row.
        final plusIcons = tester
            .widgetList<NocheIcon>(
              find.descendant(of: addRow, matching: find.byType(NocheIcon)),
            )
            .where((icon) => icon.data == NocheIcons.plus);
        expect(plusIcons, hasLength(1));

        // Tap Arabic to add & switch: updates shared setting and returns to map.
        await tester.tap(addRow);
        await tester.pump();
        expect(shared.setting(currentLanguageSettingKey), 'ar');
        expect(haptics.ticks, 1);
        expect(nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );

    testWidgets(
      'both Spanish and Arabic with progress: current first (2px border + check disc), other has 1px line border + Switch; tapping Switch changes setting and returns to map',
      (tester) async {
        final clock = FakeClock(referenceNowMs);
        final esCourse = DevCourse();
        final arCourse = _TenPlaceCourse(
          language: arabicTestLanguage,
          fetch: arabicSampleFile,
        );
        await arCourse.load();
        final shared = FakeProgressStore(clock: clock);
        final esStore = FakeProgressStore(clock: clock);
        final arStore = FakeProgressStore(clock: clock);
        _finishPlaces(esStore, esCourse, 2);
        _seedWords(esStore, 96);
        _seedWords(arStore, 12, prefix: 'ar');

        final nav = FakeNavigator();
        final haptics = FakeHaptics();
        final services = fakeServices(
          progress: shared,
          course: esCourse,
          clock: clock,
          nav: nav,
          haptics: haptics,
        );
        final source = CatalogLanguagesSource(
          courses: [esCourse, arCourse],
          storeFor: (l) => l.code == 'ar' ? arStore : esStore,
          sharedStore: shared,
        );

        await _pumpSheet(tester, services: services, source: source);

        final esCard = find.byKey(const ValueKey('language-card-es'));
        final arCard = find.byKey(const ValueKey('language-card-ar'));
        expect(esCard, findsOneWidget);
        expect(arCard, findsOneWidget);
        expect(find.text('ADD A LANGUAGE'), findsNothing);

        // Current (Spanish) is above Arabic.
        expect(
          tester.getTopLeft(esCard).dy,
          lessThan(tester.getTopLeft(arCard).dy),
        );
        expect(tester.getSize(esCard).height, 72);
        expect(tester.getSize(arCard).height, 72);

        // Non-current card has 1 px line border and "Switch".
        final arBox = tester
            .widgetList<Container>(
              find.descendant(of: arCard, matching: find.byType(Container)),
            )
            .first;
        final arDeco = arBox.decoration! as BoxDecoration;
        expect(arDeco.border, Border.all(color: NocheColors.line, width: 1));
        expect(
          find.descendant(of: arCard, matching: find.text('Switch')),
          findsOneWidget,
        );
        expect(find.text('A1 · place 1 of 10 · 12 words'), findsOneWidget);

        // Tap Arabic to switch: haptics fire immediately, while the outline
        // slides and switch/navigation happen after ProfileMotion.languageSwitchDelay.
        await tester.tap(arCard);
        await tester.pump();
        expect(haptics.ticks, 1);
        expect(shared.setting(currentLanguageSettingKey), isNull);
        expect(nav.routes, isEmpty);

        await tester.pump(ProfileMotion.languageSwitchDelay);
        expect(shared.setting(currentLanguageSettingKey), 'ar');
        expect(nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );

    testWidgets(
      'works in both LTR and RTL directions; directional layout mirrors cleanly and preserves native name direction',
      (tester) async {
        final clock = FakeClock(referenceNowMs);
        final esCourse = DevCourse();
        final arCourse = _TenPlaceCourse(
          language: arabicTestLanguage,
          fetch: arabicSampleFile,
        );
        await arCourse.load();
        final shared = FakeProgressStore(clock: clock);
        shared.setSetting(currentLanguageSettingKey, 'ar');
        final esStore = FakeProgressStore(clock: clock);
        final arStore = FakeProgressStore(clock: clock);
        _seedWords(arStore, 24, prefix: 'ar');

        final services = fakeServices(
          progress: shared,
          course: arCourse,
          clock: clock,
        );
        final source = CatalogLanguagesSource(
          courses: [esCourse, arCourse],
          storeFor: (l) => l.code == 'ar' ? arStore : esStore,
          sharedStore: shared,
        );

        // LTR: title on the left, check disc on the right.
        await _pumpSheet(
          tester,
          services: services,
          source: source,
          textDirection: TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);
        final ltrNameX = tester.getTopLeft(find.text('Arabic')).dx;
        final ltrCheckX = tester
            .getTopLeft(
              find.descendant(
                of: find.byKey(const ValueKey('language-card-ar')),
                matching: find.byType(NocheIcon),
              ),
            )
            .dx;
        expect(ltrNameX, lessThan(ltrCheckX));

        // Spanish is addable and preserves LTR native name + locale 'es'.
        final esNativeLtr = tester.widget<Text>(
          find.text(Language.spanish.nativeName),
        );
        expect(esNativeLtr.locale, const Locale('es'));
        expect(esNativeLtr.textDirection, TextDirection.ltr);

        // RTL: mirrors so check disc sits to the left of the text.
        await _pumpSheet(
          tester,
          services: services,
          source: source,
          textDirection: TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
        final rtlNameX = tester.getTopLeft(find.text('Arabic')).dx;
        final rtlCheckX = tester
            .getTopLeft(
              find.descendant(
                of: find.byKey(const ValueKey('language-card-ar')),
                matching: find.byType(NocheIcon),
              ),
            )
            .dx;
        expect(rtlCheckX, lessThan(rtlNameX));

        // Spanish native name still declares LTR + locale 'es' even in RTL sheet.
        final esNativeRtl = tester.widget<Text>(
          find.text(Language.spanish.nativeName),
        );
        expect(esNativeRtl.locale, const Locale('es'));
        expect(esNativeRtl.textDirection, TextDirection.ltr);
      },
    );

    testWidgets(
      'close button, scrim tap, and tapping already-current card close via nav.back without changing language',
      (tester) async {
        final clock = FakeClock(referenceNowMs);
        final esCourse = DevCourse();
        final arCourse = _TenPlaceCourse(
          language: arabicTestLanguage,
          fetch: arabicSampleFile,
        );
        final shared = FakeProgressStore(clock: clock);
        final esStore = FakeProgressStore(clock: clock);
        final arStore = FakeProgressStore(clock: clock);
        _seedWords(esStore, 10);

        final nav = FakeNavigator();
        final services = fakeServices(
          progress: shared,
          course: esCourse,
          clock: clock,
          nav: nav,
        );
        final source = CatalogLanguagesSource(
          courses: [esCourse, arCourse],
          storeFor: (l) => l.code == 'ar' ? arStore : esStore,
          sharedStore: shared,
        );

        await _pumpSheet(tester, services: services, source: source);

        // Close button (X).
        final closeButton = find.bySemanticsLabel('Close');
        expect(closeButton, findsOneWidget);
        expect(tester.getSize(closeButton).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(closeButton).height, greaterThanOrEqualTo(48));
        await tester.tap(closeButton);
        await tester.pump();
        expect(nav.backs, 1);
        expect(nav.routes, isEmpty);
        expect(shared.setting(currentLanguageSettingKey), isNull);

        // Scrim tap above the sheet.
        await tester.tapAt(const Offset(195, 40));
        await tester.pump();
        expect(nav.backs, 2);
        expect(nav.routes, isEmpty);

        // Tapping already-current language card closes without changing setting.
        await tester.tap(find.byKey(const ValueKey('language-card-es')));
        await tester.pump();
        expect(nav.backs, 3);
        expect(nav.routes, isEmpty);
        expect(shared.setting(currentLanguageSettingKey), isNull);
      },
    );

    testWidgets('rebuilds live when source.changes emits', (tester) async {
      final clock = FakeClock(referenceNowMs);
      final esCourse = DevCourse();
      final arCourse = _TenPlaceCourse(
        language: arabicTestLanguage,
        fetch: arabicSampleFile,
      );
      final shared = FakeProgressStore(clock: clock);
      final esStore = FakeProgressStore(clock: clock);
      final arStore = FakeProgressStore(clock: clock);
      final changes = StreamController<void>.broadcast();
      addTearDown(changes.close);

      final services = fakeServices(
        progress: shared,
        course: esCourse,
        clock: clock,
      );
      final source = CatalogLanguagesSource(
        courses: [esCourse, arCourse],
        storeFor: (l) => l.code == 'ar' ? arStore : esStore,
        sharedStore: shared,
        changes: changes.stream,
      );

      await _pumpSheet(tester, services: services, source: source);
      expect(find.byKey(const ValueKey('add-language-ar')), findsOneWidget);

      _seedWords(arStore, 3, prefix: 'ar');
      changes.add(null);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('add-language-ar')), findsNothing);
      expect(find.byKey(const ValueKey('language-card-ar')), findsOneWidget);
      expect(find.text('A1 · place 1 of 10 · 3 words'), findsOneWidget);
    });
  });

  group('LanguagesSheet — N8.16 motion', () {
    Future<
      ({
        FakeProgressStore shared,
        FakeNavigator nav,
        FakeHaptics haptics,
        Services services,
        LanguagesSource source,
      })
    >
    buildTwoLanguageFixture({String activeCode = 'es'}) async {
      final clock = FakeClock(referenceNowMs);
      final esCourse = DevCourse();
      final arCourse = _TenPlaceCourse(
        language: arabicTestLanguage,
        fetch: arabicSampleFile,
      );
      await arCourse.load();
      final shared = FakeProgressStore(clock: clock);
      if (activeCode != 'es') {
        shared.setSetting(currentLanguageSettingKey, activeCode);
      }
      final esStore = FakeProgressStore(clock: clock);
      final arStore = FakeProgressStore(clock: clock);
      _finishPlaces(esStore, esCourse, 2);
      _seedWords(esStore, 96);
      _seedWords(arStore, 12, prefix: 'ar');

      final nav = FakeNavigator();
      final haptics = FakeHaptics();
      final services = fakeServices(
        progress: shared,
        course: activeCode == 'ar' ? arCourse : esCourse,
        clock: clock,
        nav: nav,
        haptics: haptics,
      );
      final source = CatalogLanguagesSource(
        courses: [esCourse, arCourse],
        storeFor: (l) => l.code == 'ar' ? arStore : esStore,
        sharedStore: shared,
      );
      return (
        shared: shared,
        nav: nav,
        haptics: haptics,
        services: services,
        source: source,
      );
    }

    testWidgets(
      'sliding outline travels on move/travel, tick and Switch crossfade in quick, close is locked during switch, and course switches at 420 ms',
      (tester) async {
        final f = await buildTwoLanguageFixture();
        await _pumpSheet(tester, services: f.services, source: f.source);

        final esCard = find.byKey(const ValueKey('language-card-es'));
        final arCard = find.byKey(const ValueKey('language-card-ar'));
        final markFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        final esRect = tester.getRect(esCard);
        final arRect = tester.getRect(arCard);

        expect(tester.getRect(markFinder), esRect);

        // Tap Arabic: switch begins; outline starts at Spanish rect.
        await tester.tap(arCard);
        await tester.pump();
        expect(tester.getRect(markFinder).top, closeTo(esRect.top, 0.1));
        expect(f.haptics.ticks, 1);
        expect(f.shared.setting(currentLanguageSettingKey), isNull);
        expect(f.nav.routes, isEmpty);

        // Close button and scrim taps are ignored while switching.
        await tester.tap(find.bySemanticsLabel('Close'));
        await tester.tapAt(const Offset(195, 40));
        await tester.pump();
        expect(f.nav.backs, 0);
        expect(f.haptics.ticks, 1);

        // Midpoint of quick (70 ms): tick and Switch are mid-crossfade on both rows.
        final halfQuick = NocheMotion.quick ~/ 2;
        await tester.pump(halfQuick);
        final arCheckMid = tester
            .widget<Opacity>(find.byKey(const ValueKey('language-check-ar')))
            .opacity;
        final arSwitchMid = tester
            .widget<Opacity>(find.byKey(const ValueKey('language-switch-ar')))
            .opacity;
        final esCheckMid = tester
            .widget<Opacity>(find.byKey(const ValueKey('language-check-es')))
            .opacity;
        final esSwitchMid = tester
            .widget<Opacity>(find.byKey(const ValueKey('language-switch-es')))
            .opacity;
        expect(arCheckMid, greaterThan(0.0));
        expect(arCheckMid, lessThan(1.0));
        expect(arSwitchMid, greaterThan(0.0));
        expect(arSwitchMid, lessThan(1.0));
        expect(esCheckMid, greaterThan(0.0));
        expect(esCheckMid, lessThan(1.0));
        expect(esSwitchMid, greaterThan(0.0));
        expect(esSwitchMid, lessThan(1.0));

        // Midpoint of move (110 ms): outline mark sits on travel(0.5) between cards.
        final halfMove = NocheMotion.move ~/ 2;
        await tester.pump(halfMove - halfQuick);
        final expectedMidTop =
            esRect.top +
            (arRect.top - esRect.top) * NocheMotion.travel.transform(0.5);
        expect(tester.getRect(markFinder).top, closeTo(expectedMidTop, 0.5));
        expect(f.shared.setting(currentLanguageSettingKey), isNull);
        expect(f.nav.routes, isEmpty);

        // End of move (220 ms): outline reaches Arabic card, check/Switch swap is
        // complete, but switch and close have NOT fired yet (< 420 ms).
        await tester.pump(NocheMotion.move - halfMove);
        expect(tester.getRect(markFinder).top, closeTo(arRect.top, 0.1));
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('language-check-ar')))
              .opacity,
          1.0,
        );
        expect(find.byKey(const ValueKey('language-switch-ar')), findsNothing);
        expect(
          tester
              .widget<Opacity>(find.byKey(const ValueKey('language-switch-es')))
              .opacity,
          1.0,
        );
        expect(find.byKey(const ValueKey('language-check-es')), findsNothing);
        expect(f.shared.setting(currentLanguageSettingKey), isNull);
        expect(f.nav.routes, isEmpty);

        // Still not fired 1 ms before 420 ms.
        await tester.pump(
          ProfileMotion.languageSwitchDelay -
              NocheMotion.move -
              const Duration(milliseconds: 1),
        );
        expect(f.shared.setting(currentLanguageSettingKey), isNull);
        expect(f.nav.routes, isEmpty);

        // At 420 ms total: course switches and navigates to map.
        await tester.pump(const Duration(milliseconds: 1));
        expect(f.shared.setting(currentLanguageSettingKey), 'ar');
        expect(f.nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );

    testWidgets(
      'under reduced motion, outline snaps immediately to target and fades in quick without scaling check disc, switching at 420 ms',
      (tester) async {
        final f = await buildTwoLanguageFixture();
        await _pumpSheet(
          tester,
          services: f.services,
          source: f.source,
          disableAnimations: true,
        );

        final arCard = find.byKey(const ValueKey('language-card-ar'));
        final markFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        final arRect = tester.getRect(arCard);

        await tester.tap(arCard);
        await tester.pump();

        // Mark snaps immediately to Arabic rect (never at an intermediate y).
        expect(tester.getRect(markFinder), arRect);
        final markOpacityAtStart = tester
            .widget<Opacity>(
              find
                  .ancestor(of: markFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(markOpacityAtStart, 0.0);

        // Midpoint of quick: mark stays at arRect and fades in; check disc never scales.
        final halfQuick = NocheMotion.quick ~/ 2;
        await tester.pump(halfQuick);
        expect(tester.getRect(markFinder), arRect);
        final markOpacityMid = tester
            .widget<Opacity>(
              find
                  .ancestor(of: markFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(markOpacityMid, closeTo(NocheMotion.enter.transform(0.5), 0.05));
        final checkTransform = tester.widget<Transform>(
          find.descendant(
            of: find.byKey(const ValueKey('language-check-ar')),
            matching: find.byType(Transform),
          ),
        );
        expect(checkTransform.transform.storage[0], 1.0);
        expect(checkTransform.transform.storage[5], 1.0);

        // End of quick: mark fully opaque.
        await tester.pump(NocheMotion.quick - halfQuick);
        final markOpacityEnd = tester
            .widget<Opacity>(
              find
                  .ancestor(of: markFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(markOpacityEnd, 1.0);
        expect(f.shared.setting(currentLanguageSettingKey), isNull);

        // At 420 ms total: course switches and navigates to map.
        await tester.pump(
          ProfileMotion.languageSwitchDelay - NocheMotion.quick,
        );
        expect(f.shared.setting(currentLanguageSettingKey), 'ar');
        expect(f.nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );

    testWidgets(
      'in Arabic RTL course, outline slides cleanly from Arabic to Spanish, summaries stay LTR via NocheLtr, and switch fires at 420 ms',
      (tester) async {
        final f = await buildTwoLanguageFixture(activeCode: 'ar');
        await _pumpSheet(
          tester,
          services: f.services,
          source: f.source,
          textDirection: TextDirection.rtl,
        );

        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('languages-sheet'))),
          ),
          TextDirection.rtl,
        );
        for (final summary in const [
          'A1 · place 1 of 10 · 12 words',
          'A1 · place 3 of 10 · 96 words',
        ]) {
          expect(
            Directionality.of(tester.element(find.text(summary))),
            TextDirection.ltr,
            reason: '$summary should stay LTR via NocheLtr in RTL',
          );
        }

        final arCard = find.byKey(const ValueKey('language-card-ar'));
        final esCard = find.byKey(const ValueKey('language-card-es'));
        final markFinder = find.byKey(
          const ValueKey('noche_outline_group_mark'),
        );
        final arRect = tester.getRect(arCard);
        final esRect = tester.getRect(esCard);
        expect(tester.getRect(markFinder), arRect);

        await tester.tap(esCard);
        await tester.pump();
        expect(tester.getRect(markFinder).top, closeTo(arRect.top, 0.1));

        final halfMove = NocheMotion.move ~/ 2;
        await tester.pump(halfMove);
        final expectedMidTop =
            arRect.top +
            (esRect.top - arRect.top) * NocheMotion.travel.transform(0.5);
        expect(tester.getRect(markFinder).top, closeTo(expectedMidTop, 0.5));

        await tester.pump(NocheMotion.move - halfMove);
        expect(tester.getRect(markFinder).top, closeTo(esRect.top, 0.1));
        expect(f.shared.setting(currentLanguageSettingKey), 'ar');
        expect(f.nav.routes, isEmpty);

        await tester.pump(ProfileMotion.languageSwitchDelay - NocheMotion.move);
        expect(f.shared.setting(currentLanguageSettingKey), 'es');
        expect(f.nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );
  });

  group('LanguageChip', () {
    testWidgets(
      '48-high pill shows English name, optional level, chevronDown, opens LanguagesRoute, works LTR & RTL',
      (tester) async {
        final nav = FakeNavigator();
        for (final dir in const [TextDirection.ltr, TextDirection.rtl]) {
          nav.routes.clear();
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Directionality(
                textDirection: dir,
                child: Scaffold(
                  backgroundColor: NocheColors.ground,
                  body: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LanguageChip(
                        key: const Key('chip-map'),
                        language: Language.spanish,
                        level: 'A1',
                        onPressed: () => nav.go(const LanguagesRoute()),
                      ),
                      LanguageChip(
                        key: const Key('chip-me'),
                        language: arabicTestLanguage,
                        onPanel: true,
                        onPressed: () => nav.go(const LanguagesRoute()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          final mapChip = find.byKey(const Key('chip-map'));
          final meChip = find.byKey(const Key('chip-me'));
          expect(tester.getSize(mapChip).height, NocheSize.touch);
          expect(tester.getSize(meChip).height, NocheSize.touch);
          expect(find.text('Spanish'), findsOneWidget);
          expect(find.text('A1'), findsOneWidget);
          expect(find.text('Arabic'), findsOneWidget);

          final mapBox = tester.widget<Container>(
            find.descendant(of: mapChip, matching: find.byType(Container)),
          );
          expect(
            (mapBox.decoration! as BoxDecoration).color,
            NocheColors.panel,
          );
          final meBox = tester.widget<Container>(
            find.descendant(of: meChip, matching: find.byType(Container)),
          );
          expect(
            (meBox.decoration! as BoxDecoration).color,
            NocheColors.ground,
          );

          await tester.tap(mapChip);
          await tester.pump();
          expect(nav.routes, [const LanguagesRoute()]);
        }
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N2.10 Part 1.6 screenshots', (tester) async {
      for (final entry in nocheFontFiles.entries) {
        for (final prefix in ['', 'packages/coqui_ui/']) {
          final loader = FontLoader('$prefix${entry.key}');
          for (final path in entry.value.values) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(
                  File('../../core/coqui_ui/$path').readAsBytesSync(),
                ),
              ),
            );
          }
          await loader.load();
        }
      }

      final dir = Directory('test/screenshots')..createSync(recursive: true);

      for (final screen in [
        (tag: '390x844', size: const Size(390, 844), dpr: 3.0),
        (tag: '412x915', size: const Size(412, 915), dpr: 2.625),
      ]) {
        for (final variant in const [
          'es_only',
          'es_ar_add_ltr',
          'es_ar_both_ltr',
          'ar_es_rtl',
        ]) {
          final clock = FakeClock(referenceNowMs);
          final esCourse = DevCourse();
          final arCourse = _TenPlaceCourse(
            language: arabicTestLanguage,
            fetch: arabicSampleFile,
          );
          await arCourse.load();
          final shared = FakeProgressStore(clock: clock);
          final esStore = FakeProgressStore(clock: clock);
          final arStore = FakeProgressStore(clock: clock);
          _finishPlaces(esStore, esCourse, 2);
          _seedWords(esStore, 96);

          final bool isRtl = variant == 'ar_es_rtl';
          final List<CourseCatalog> courses;
          if (variant == 'es_only') {
            courses = [esCourse];
          } else {
            courses = [esCourse, arCourse];
          }
          if (variant == 'es_ar_both_ltr' || variant == 'ar_es_rtl') {
            _seedWords(arStore, 12, prefix: 'ar');
          }
          if (isRtl) {
            shared.setSetting(currentLanguageSettingKey, 'ar');
          }

          final activeCourse = isRtl ? arCourse : esCourse;
          final services = fakeServices(
            progress: shared,
            course: activeCourse,
            clock: clock,
          );
          final source = CatalogLanguagesSource(
            courses: courses,
            storeFor: (l) => l.code == 'ar' ? arStore : esStore,
            sharedStore: shared,
          );

          final boundaryKey = GlobalKey();
          await _pumpSheet(
            tester,
            services: services,
            source: source,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            size: screen.size,
            dpr: screen.dpr,
            backdrop: ColoredBox(
              color: NocheColors.ground,
              child: SafeArea(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: LanguageChip(
                      language: activeCourse.language,
                      level: defaultLanguageLevel,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
            boundaryKey: boundaryKey,
          );

          final bytes = await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: screen.dpr);
            final byteData = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            image.dispose();
            return byteData!.buffer.asUint8List();
          });
          File('${dir.path}/languages_${variant}_${screen.tag}.png')
              .writeAsBytesSync(bytes!);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  }
}
