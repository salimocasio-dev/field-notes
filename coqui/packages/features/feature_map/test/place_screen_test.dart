@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:feature_map/src/place_screen.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/map_fixture.dart';
import 'support/map_tester.dart';

void _phone(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  double dpr = 2.625,
}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
}

ReviewPair _pair(String word, String scene) => ReviewPair(
  word: word,
  say: '',
  scene: scene,
  yes: PictureSpec(cam: const [0, 0, 196, 104]),
  no: PictureSpec(cam: const [0, 0, 196, 104]),
);

final _cocinaPairs = <ReviewPair>[
  _pair('mesa', 'mesa'),
  _pair('cuchara', 'mesa'),
  _pair('estufa', 'estufa'),
  _pair('nevera', 'nevera'),
];

const _cocinaScenes = <String, String>{
  'la-mesa': 'mesa',
  'la-cuchara': 'mesa',
  'tengo-hambre': 'mesa',
  'arroz-con-habichuelas': 'estufa',
  'el-pollo-y-el-huevo': 'estufa',
  'cuidado': 'estufa',
  'no-hay-leche': 'nevera',
  'para-los-pajaros': 'nevera',
  'jugo-de-china': 'nevera',
};

Future<MapFixture> _pumpPlace(
  WidgetTester tester, {
  String placeId = 'cocina',
  int builtPlaces = 3,
  bool todo = false,
  Set<String> callPlaces = const {'casa', 'parque', 'cocina'},
  Set<String>? bookIds,
  List<ReviewPair>? customPairs,
  Map<String, String> storyScenes = _cocinaScenes,
  void Function(MapFixture f)? seedProgress,
  TextDirection textDirection = TextDirection.ltr,
  FakePictureSource? pictures,
  CourseCatalog? overrideCourse,
  Entitlements entitlements = const AllowAllEntitlements(),
}) async {
  final f = fixture(
    builtPlaces: builtPlaces,
    todo: todo,
    reduceMotion: true,
    callPlaces: callPlaces,
    bookIds: bookIds,
    customPairs: customPairs ?? _cocinaPairs,
    storyScenes: storyScenes,
  );
  seedProgress?.call(f);
  var services = f.services;
  if (overrideCourse != null || pictures != null) {
    services = fakeServices(
      progress: f.progress,
      course: overrideCourse ?? f.services.course,
      clock: f.clock,
      nav: f.nav,
      clips: f.clips,
      haptics: f.haptics,
      pictures: pictures ?? f.services.pictures,
      reduceMotion: true,
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      theme: coquiTheme(),
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          backgroundColor: NocheColors.ground,
          body: PlaceScreen(
            placeId: placeId,
            services: services,
            entitlements: entitlements,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return f;
}

class _ArabicPlaceCourse extends MapFixtureCourse implements LanguageCatalog {
  _ArabicPlaceCourse({super.customPairs, super.storyScenes})
    : super(builtPlaces: 3);

  static final _arabic = Language(
    code: 'ar',
    englishName: 'Arabic',
    nativeName: 'العربية',
    recognitionLocale: 'ar-SA',
    direction: LanguageDirection.rtl,
    script: 'Arab',
    partnerName: 'Karim',
    callAgentId: 'agent_ar_test',
    micWords: const {
      'ready': 'تحدث',
      'listening': 'أسمعك',
      'thinking': 'لحظة',
      'theySpeak': 'استمع',
      'right': 'ممتاز',
      'notYet': 'مرة أخرى',
    },
    tabNames: const {
      'library': 'المكتبة',
      'words': 'الكلمات',
      'map': 'الخريطة',
      'speak': 'تحدث',
      'me': 'أنا',
    },
  );

  @override
  Language get language => _arabic;
}

void main() {
  group('map_model place helpers & picture pickers', () {
    test('nextUnheardStory and lastHeardStory handle empty, partial, replay ties, and done', () {
      final f = fixture();
      final cocina = MapFixtureCourse().places[2];
      expect(nextUnheardStory(f.progress, cocina), 'la-mesa');
      expect(lastHeardStory(f.progress, cocina), isNull);

      f.clock.advance(const Duration(seconds: 10));
      finishStory(f.progress, 'la-mesa');
      f.clock.advance(const Duration(seconds: 10));
      finishStory(f.progress, 'la-cuchara');
      expect(nextUnheardStory(f.progress, cocina), 'tengo-hambre');
      expect(lastHeardStory(f.progress, cocina), 'la-cuchara');

      // Replay story 1 after story 2 -> story 1 wins lastHeardStory
      f.clock.advance(const Duration(seconds: 10));
      finishStory(f.progress, 'la-mesa');
      expect(lastHeardStory(f.progress, cocina), 'la-mesa');

      // Tie on timestamp -> later story in place.stories wins (>=)
      final fTie = fixture();
      finishStory(fTie.progress, 'la-mesa');
      finishStory(fTie.progress, 'la-cuchara');
      expect(lastHeardStory(fTie.progress, cocina), 'la-cuchara');

      // All heard -> nextUnheardStory is null
      for (final id in cocina.stories) {
        finishStory(f.progress, id);
      }
      expect(nextUnheardStory(f.progress, cocina), isNull);
    });

    test('pickPlaceHeroPictureRef and pickStoryTilePictureRef pick scene then place fallback', () {
      final course = MapFixtureCourse(customPairs: _cocinaPairs);
      final cocina = course.places[2];

      expect(
        pickPlaceHeroPictureRef(
          place: cocina,
          course: course,
          preferredScene: 'estufa',
        )?.scene,
        'estufa',
      );
      expect(
        pickPlaceHeroPictureRef(place: cocina, course: course)?.scene,
        'mesa',
      );
      expect(
        pickStoryTilePictureRef(
          place: cocina,
          storyIndex: 1,
          course: course,
          storyScene: 'mesa',
        )?.name,
        'cuchara.si',
      );
      expect(
        pickStoryTilePictureRef(
          place: cocina,
          storyIndex: 3,
          course: course,
          storyScene: 'nevera',
        )?.scene,
        'nevera',
      );
      expect(
        pickStoryTilePictureRef(
          place: cocina,
          storyIndex: 2,
          course: course,
        )?.scene,
        'estufa',
      );
      expect(
        pickPlaceHeroPictureRef(place: course.places[3], course: course),
        isNull,
      );
      expect(
        pickStoryTilePictureRef(
          place: course.places[3],
          storyIndex: 0,
          course: course,
        ),
        isNull,
      );
    });
  });

  group('PlaceScreen states & interactions', () {
    mapTest(
      'new place (0/9 heard): story 1 has 3px next border, no badges, no Listen/Read, Call Danny shown, play bar routes to StoryRoute',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(tester);
        expect(find.text('Place 3 of 10'), findsOneWidget);
        expect(find.text('La cocina'), findsOneWidget);
        expect(find.text('0 of 9 stories heard'), findsOneWidget);
        expect(find.text('ALL 9 STORIES'), findsOneWidget);

        // Story 1 highlighted with 3px next border, no heard check badges
        final tile1 = find.byKey(const Key('story-tile-la-mesa'));
        final bordered = tester.widget<Container>(
          find.descendant(
            of: tile1,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.foregroundDecoration is BoxDecoration,
            ),
          ),
        );
        final dec = bordered.foregroundDecoration! as BoxDecoration;
        expect(dec.border, Border.all(color: NocheColors.next, width: 3));
        expect(find.byKey(const Key('story-heard-la-mesa')), findsNothing);

        // Listen again & Read omitted; Call Danny present
        expect(find.byKey(const Key('place-pill-listen')), findsNothing);
        expect(find.byKey(const Key('place-pill-read')), findsNothing);
        expect(find.byKey(const Key('place-pill-call')), findsOneWidget);
        expect(find.text('Call Danny'), findsOneWidget);

        // Play bar shows Story 1
        expect(find.text('PLAY NEXT · STORY 1'), findsOneWidget);
        expect(find.text('La mesa'), findsOneWidget);
        expect(find.text('5 min'), findsOneWidget);

        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        expect(f.nav.routes, [const StoryRoute('la-mesa')]);
      },
    );

    mapTest('new place without call omits Call pill and outline pills row', (
      tester,
    ) async {
      _phone(tester);
      await _pumpPlace(tester, callPlaces: const {});
      expect(find.byKey(const Key('place-pill-listen')), findsNothing);
      expect(find.byKey(const Key('place-pill-read')), findsNothing);
      expect(find.byKey(const Key('place-pill-call')), findsNothing);
      expect(find.text('Call Danny'), findsNothing);
    });

    mapTest(
      'half-done place (2/9 heard): check badges on 1 & 2, story 3 highlighted, all 3 pills & play bar route cleanly',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(
          tester,
          seedProgress: (f) {
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, 'la-mesa');
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, 'la-cuchara');
          },
        );

        expect(find.text('2 of 9 stories heard'), findsOneWidget);
        expect(find.byKey(const Key('story-heard-la-mesa')), findsOneWidget);
        expect(find.byKey(const Key('story-heard-la-cuchara')), findsOneWidget);
        expect(find.byKey(const Key('story-heard-tengo-hambre')), findsNothing);

        // Story 3 highlighted
        final tile3 = find.byKey(const Key('story-tile-tengo-hambre'));
        expect(
          find.descendant(
            of: tile3,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.foregroundDecoration is BoxDecoration,
            ),
          ),
          findsOneWidget,
        );

        // All 3 pills present
        expect(find.text('Listen again'), findsOneWidget);
        expect(find.text('Read'), findsOneWidget);
        expect(find.text('Call Danny'), findsOneWidget);
        expect(find.text('PLAY NEXT · STORY 3'), findsOneWidget);
        expect(find.text('Tengo hambre'), findsOneWidget);

        await tester.tap(find.byKey(const Key('place-pill-listen')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('place-pill-read')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('place-pill-call')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();

        expect(f.nav.routes, const [
          StoryRoute('la-cuchara', listen: true),
          BookRoute('la-cuchara'),
          CallRoute('cocina'),
          StoryRoute('tengo-hambre'),
        ]);
      },
    );

    mapTest('book unavailable omits Read pill while keeping Listen again', (
      tester,
    ) async {
      _phone(tester);
      await _pumpPlace(
        tester,
        bookIds: const {},
        seedProgress: (f) => finishStory(f.progress, 'la-mesa'),
      );
      expect(find.byKey(const Key('place-pill-listen')), findsOneWidget);
      expect(find.byKey(const Key('place-pill-read')), findsNothing);
    });

    mapTest(
      'replayed story timestamp makes Listen again and Read target the replayed story',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(
          tester,
          seedProgress: (f) {
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, 'la-mesa');
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, 'la-cuchara');
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, 'la-mesa');
          },
        );
        await tester.tap(find.byKey(const Key('place-pill-listen')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('place-pill-read')));
        await tester.pump();
        expect(f.nav.routes, const [
          StoryRoute('la-mesa', listen: true),
          BookRoute('la-mesa'),
        ]);
      },
    );

    mapTest(
      'finished place WITH call: all 9 heard, no next border, play bar is Call Danny',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(
          tester,
          seedProgress: (f) {
            final course = MapFixtureCourse();
            for (final id in course.places[2].stories) {
              f.clock.advance(const Duration(seconds: 5));
              finishStory(f.progress, id);
            }
          },
        );
        expect(find.text('9 of 9 stories heard'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Container && w.foregroundDecoration is BoxDecoration,
          ),
          findsNothing,
        );
        expect(find.text('ALL STORIES HEARD'), findsOneWidget);
        expect(find.text('Call Danny'), findsNWidgets(2));
        expect(find.text('4 min'), findsOneWidget);

        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        expect(f.nav.routes, [const CallRoute('cocina')]);
      },
    );

    mapTest(
      'finished place WITHOUT call: no Call pill, play bar is Review -> ReviewRoute',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(
          tester,
          callPlaces: const {},
          seedProgress: (f) {
            final course = MapFixtureCourse();
            for (final id in course.places[2].stories) {
              f.clock.advance(const Duration(seconds: 5));
              finishStory(f.progress, id);
            }
          },
        );
        expect(find.byKey(const Key('place-pill-call')), findsNothing);
        expect(find.text('ALL STORIES HEARD'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);

        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        expect(f.nav.routes, [const ReviewRoute()]);
      },
    );

    mapTest(
      'locked vs unbuilt place (stories.isEmpty) shows message, scenes, and no play bar',
      (tester) async {
        _phone(tester);
        await _pumpPlace(tester, placeId: 'colmado');
        expect(find.text('Place 4 of 10'), findsOneWidget);
        expect(find.text('El colmado'), findsOneWidget);
        expect(
          find.text('Locked until the places before it are done.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Scenes: El mostrador · Los estantes · Las frutas · La caja',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('place-play-bar')), findsNothing);

        await _pumpPlace(tester, placeId: 'colmado', todo: true);
        expect(find.text('Not built yet.'), findsOneWidget);
        expect(find.byKey(const Key('place-play-bar')), findsNothing);
      },
    );

    mapTest(
      'every story tile (all 9 of La cocina) scrolls into view and routes to StoryRoute',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(tester);
        final stories = MapFixtureCourse().places[2].stories;
        final scroll = find.byKey(const Key('place-stories-scroll'));
        for (final id in stories) {
          final tile = find.byKey(Key('story-tile-$id'));
          await tester.scrollUntilVisible(
            tile,
            120,
            scrollable: find.descendant(
              of: scroll,
              matching: find.byType(Scrollable),
            ),
          );
          await tester.tap(tile);
          await tester.pump();
        }
        expect(f.nav.routes, [for (final id in stories) StoryRoute(id)]);
      },
    );

    mapTest(
      'back button is 48x48 ground circle at top-start and routes to TabRoute(map)',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(tester);
        final back = find.byKey(const Key('place-back'));
        final rect = tester.getRect(back);
        expect(rect.size, const Size(48, 48));
        expect(rect.left, closeTo(16, 0.5));
        expect(rect.top, closeTo(16, 0.5));
        await tester.tap(back);
        await tester.pump();
        expect(f.nav.routes, [const TabRoute(NocheTabs.map)]);
      },
    );

    mapTest(
      'RTL Arabic course mirrors back, counter, heard badge, Call Karim, and keeps picture LTR',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final arabicCourse = _ArabicPlaceCourse(
          customPairs: _cocinaPairs,
          storyScenes: _cocinaScenes,
        );
        final f = await _pumpPlace(
          tester,
          overrideCourse: arabicCourse,
          textDirection: TextDirection.rtl,
          seedProgress: (f) => finishStory(f.progress, 'la-mesa'),
        );

        expect(find.text('Call Karim'), findsOneWidget);
        final backRect = tester.getRect(find.byKey(const Key('place-back')));
        final counterRect = tester.getRect(
          find.byKey(const Key('place-counter')),
        );
        expect(backRect.right, closeTo(390 - 16, 0.5));
        expect(counterRect.left, closeTo(16, 0.5));

        final tileRect = tester.getRect(
          find.byKey(const Key('story-tile-la-mesa')),
        );
        final badgeRect = tester.getRect(
          find.byKey(const Key('story-heard-la-mesa')),
        );
        expect(badgeRect.center.dx, greaterThan(tileRect.center.dx));

        final heroBox = find.byKey(const Key('place-hero-picture'));
        final heroInner = find.descendant(
          of: heroBox,
          matching: find.byType(LayoutBuilder),
        );
        expect(Directionality.of(tester.element(heroInner)), TextDirection.ltr);
        expect(f.nav.routes, isEmpty);
      },
    );

    mapTest(
      'touch targets are >= 48x48 on back button, all pills, story tiles, and play bar',
      (tester) async {
        _phone(tester);
        await _pumpPlace(
          tester,
          seedProgress: (f) => finishStory(f.progress, 'la-mesa'),
        );
        for (final key in const [
          Key('place-back'),
          Key('place-pill-listen'),
          Key('place-pill-read'),
          Key('place-pill-call'),
          Key('story-tile-la-mesa'),
          Key('story-tile-la-cuchara'),
          Key('place-play-bar'),
        ]) {
          final size = tester.getSize(find.byKey(key));
          expect(size.width, greaterThanOrEqualTo(48), reason: '$key width');
          expect(size.height, greaterThanOrEqualTo(48), reason: '$key height');
        }
      },
    );

    mapTest(
      'live progress update updates heard count, badges, Read pill, and play bar',
      (tester) async {
        _phone(tester);
        final f = await _pumpPlace(tester);
        expect(find.text('0 of 9 stories heard'), findsOneWidget);
        expect(find.byKey(const Key('place-pill-listen')), findsNothing);

        finishStory(f.progress, 'la-mesa');
        await tester.pump();
        await tester.pump();

        expect(find.text('1 of 9 stories heard'), findsOneWidget);
        expect(find.byKey(const Key('story-heard-la-mesa')), findsOneWidget);
        expect(find.byKey(const Key('place-pill-listen')), findsOneWidget);
        expect(find.byKey(const Key('place-pill-read')), findsOneWidget);
        expect(find.text('PLAY NEXT · STORY 2'), findsOneWidget);
      },
    );

    mapTest(
      'zero overflow at 390x844 and 412x915 across new, half-done, and finished states',
      (tester) async {
        for (final screen in [
          (size: const Size(390, 844), dpr: 3.0),
          (size: const Size(412, 915), dpr: 2.625),
        ]) {
          for (final count in [0, 2, 9]) {
            _phone(tester, size: screen.size, dpr: screen.dpr);
            await _pumpPlace(
              tester,
              seedProgress: (f) {
                final stories = MapFixtureCourse().places[2].stories;
                for (final id in stories.take(count)) {
                  f.clock.advance(const Duration(seconds: 5));
                  finishStory(f.progress, id);
                }
              },
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        }
      },
    );

    mapTest(
      'Plan.free: place 1 plays normally; place 2 & place 3 show Course tag, highlight card, and gate stories',
      (tester) async {
        _phone(tester);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);

        // Place 1 (La casa) is always open
        final fCasa = await _pumpPlace(
          tester,
          placeId: 'casa',
          entitlements: entitlements,
        );
        expect(find.byKey(const Key('place-plan-tag')), findsNothing);
        expect(find.byKey(const Key('place-plan-card')), findsNothing);
        expect(find.byKey(const Key('place-play-bar')), findsOneWidget);
        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        expect(fCasa.nav.routes, [const StoryRoute('la-lluvia')]);

        // Place 2 (El parque) shows stories, Course plan tag, and highlight card
        final fParque = await _pumpPlace(
          tester,
          placeId: 'parque',
          entitlements: entitlements,
          seedProgress: (f) => finishStory(f.progress, 'uno-dos-tres'),
        );
        expect(find.text('Place 2 of 10'), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);
        expect(find.text('ALL 12 STORIES'), findsOneWidget);
        expect(find.byKey(const Key('place-plan-tag')), findsOneWidget);
        expect(find.text('Course'), findsOneWidget);
        expect(find.byKey(const Key('place-play-bar')), findsNothing);
        expect(find.byKey(const Key('place-pill-listen')), findsNothing);
        expect(find.byKey(const Key('place-pill-read')), findsNothing);
        expect(find.byKey(const Key('place-pill-call')), findsNothing);
        expect(
          find.byWidgetPredicate(
            (w) => w is Container && w.foregroundDecoration is BoxDecoration,
          ),
          findsNothing,
        );

        final card = tester.widget<NocheCard>(
          find.byKey(const Key('place-plan-card')),
        );
        expect(card.variant, NocheCardVariant.highlight);
        expect(find.text('This place is in Course'), findsOneWidget);
        expect(
          find.text('Every place and every story are in Course.'),
          findsOneWidget,
        );
        expect(find.text('See plans'), findsOneWidget);

        // Story tiles do not open gated stories
        await tester.tap(find.byKey(const Key('story-tile-uno-dos-tres')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story-tile-donde-esta-el-gato')),
        );
        await tester.pump();
        expect(fParque.nav.routes, isEmpty);

        // See plans button is >= 48x48 and routes to PlansRoute
        final seePlans = find.byKey(const Key('place-see-plans'));
        expect(tester.getSize(seePlans).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSize(find.byKey(const Key('place-back'))).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(seePlans);
        await tester.pump();
        expect(fParque.nav.routes, [const PlansRoute()]);
        expect(fParque.haptics.ticks, 1);

        // Place 3 (La cocina) is also gated on Plan.free
        final fCocina = await _pumpPlace(
          tester,
          placeId: 'cocina',
          entitlements: entitlements,
        );
        expect(find.byKey(const Key('place-plan-tag')), findsOneWidget);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-play-bar')), findsNothing);
        await tester.tap(find.byKey(const Key('story-tile-la-mesa')));
        await tester.pump();
        expect(fCocina.nav.routes, isEmpty);
      },
    );

    mapTest('Plan.course unlocks place 1 and place 2', (tester) async {
      _phone(tester);
      final entitlements = FakeEntitlements(plan: Plan.course);
      addTearDown(entitlements.dispose);

      for (final entry in [
        (id: 'casa', story: 'la-lluvia'),
        (id: 'parque', story: 'uno-dos-tres'),
      ]) {
        final f = await _pumpPlace(
          tester,
          placeId: entry.id,
          entitlements: entitlements,
        );
        expect(find.byKey(const Key('place-plan-tag')), findsNothing);
        expect(find.byKey(const Key('place-plan-card')), findsNothing);
        expect(find.byKey(const Key('place-play-bar')), findsOneWidget);
        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        expect(f.nav.routes, [StoryRoute(entry.story)]);
      }
    });

    mapTest('live entitlement upgrade replaces plan card with play bar', (
      tester,
    ) async {
      _phone(tester);
      final entitlements = FakeEntitlements(plan: Plan.free);
      addTearDown(entitlements.dispose);

      final f = await _pumpPlace(
        tester,
        placeId: 'parque',
        entitlements: entitlements,
      );
      expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
      expect(find.byKey(const Key('place-play-bar')), findsNothing);

      entitlements.plan = Plan.course;
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('place-plan-card')), findsNothing);
      expect(find.byKey(const Key('place-plan-tag')), findsNothing);
      expect(find.byKey(const Key('place-play-bar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('place-play-bar')));
      await tester.pump();
      expect(f.nav.routes, [const StoryRoute('uno-dos-tres')]);
    });

    mapTest(
      'RTL Arabic course on denied place mirrors plan tag to end and has zero overflow',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);
        final arabicCourse = _ArabicPlaceCourse(
          customPairs: _cocinaPairs,
          storyScenes: _cocinaScenes,
        );
        await _pumpPlace(
          tester,
          placeId: 'parque',
          overrideCourse: arabicCourse,
          textDirection: TextDirection.rtl,
          entitlements: entitlements,
        );

        expect(find.text('ALL 12 STORIES'), findsOneWidget);
        expect(find.byKey(const Key('place-plan-tag')), findsOneWidget);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);

        final tagRect = tester.getRect(find.byKey(const Key('place-plan-tag')));
        final labelRect = tester.getRect(find.text('ALL 12 STORIES'));
        expect(tagRect.right, lessThanOrEqualTo(labelRect.left));
        expect(tester.takeException(), isNull);
      },
    );

    mapTest('zero overflow on denied place at 390x844 and 412x915', (
      tester,
    ) async {
      final entitlements = FakeEntitlements(plan: Plan.free);
      addTearDown(entitlements.dispose);
      for (final screen in [
        (size: const Size(390, 844), dpr: 3.0),
        (size: const Size(412, 915), dpr: 2.625),
      ]) {
        _phone(tester, size: screen.size, dpr: screen.dpr);
        await _pumpPlace(tester, placeId: 'parque', entitlements: entitlements);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N4.2 PlaceScreen screenshots', (tester) async {
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

      final mesaBytes = File('../../../ref/pp/mesa/m0h1/pix.png')
          .readAsBytesSync();
      final estufaBytes = File('../../../ref/pp/estufa/banco0/pix.png')
          .readAsBytesSync();
      final neveraBytes = File(
        '../../../ref/pp/nevera/nev-0-cajon-0-pila-0-banco-1/pix.png',
      ).readAsBytesSync();

      final pictures = FakePictureSource(
        frames: (ref, {required width, required height}) {
          final Uint8List bytes;
          if (ref.scene.contains('estufa')) {
            bytes = estufaBytes;
          } else if (ref.scene.contains('nevera')) {
            bytes = neveraBytes;
          } else {
            bytes = mesaBytes;
          }
          return Image.memory(
            bytes,
            width: width.toDouble(),
            height: height.toDouble(),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          );
        },
      );

      final dir = Directory('test/screenshots')..createSync(recursive: true);

      for (final screen in [
        (tag: '390x844', size: const Size(390, 844), dpr: 3.0),
        (tag: '412x915', size: const Size(412, 915), dpr: 2.625),
      ]) {
        for (final state in [
          (name: 'new', count: 0),
          (name: 'half', count: 2),
          (name: 'done', count: 9),
        ]) {
          _phone(tester, size: screen.size, dpr: screen.dpr);
          final f = fixture(
            builtPlaces: 3,
            reduceMotion: true,
            customPairs: _cocinaPairs,
            storyScenes: _cocinaScenes,
          );
          final stories = MapFixtureCourse().places[2].stories;
          for (final id in stories.take(state.count)) {
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, id);
          }
          final services = fakeServices(
            progress: f.progress,
            course: f.services.course,
            clock: f.clock,
            nav: f.nav,
            clips: f.clips,
            haptics: f.haptics,
            pictures: pictures,
            reduceMotion: true,
          );
          final lang = services.course.language;
          final boundaryKey = GlobalKey();

          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: coquiTheme(),
                home: Scaffold(
                  backgroundColor: NocheColors.ground,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaceScreen(
                        placeId: 'cocina',
                        services: services,
                        entitlements: const AllowAllEntitlements(),
                      ),
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: NocheTabBar(
                          selectedId: NocheTabs.map,
                          tabNames: lang.tabNames,
                          script: lang.script,
                          languageCode: lang.code,
                          onTap: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          await tester.pump();
          await tester.runAsync(() async {
            await precacheImage(
              MemoryImage(mesaBytes),
              tester.element(find.byType(PlaceScreen)),
            );
            await precacheImage(
              MemoryImage(estufaBytes),
              tester.element(find.byType(PlaceScreen)),
            );
            await precacheImage(
              MemoryImage(neveraBytes),
              tester.element(find.byType(PlaceScreen)),
            );
          });
          await tester.pump();

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
          File('${dir.path}/place_${state.name}_${screen.tag}.png')
              .writeAsBytesSync(bytes!);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }

      // N3.4 Place not in the plan screenshots (Plan.free on place 2: El parque)
      final caminoBytes = File('../../../ref/pp/camino/gran-0/pix.png')
          .readAsBytesSync();
      final lagoBytes = File('../../../ref/pp/lago/lago/pix.png')
          .readAsBytesSync();
      final bancoBytes = File(
        '../../../ref/pp/banco/luz-dia-luna-0-carro-abierto/pix.png',
      ).readAsBytesSync();
      final parquePairs = <ReviewPair>[
        _pair('camino', 'camino'),
        _pair('lago', 'lago'),
        _pair('banco', 'banco'),
      ];
      const parqueScenes = <String, String>{
        'uno-dos-tres': 'camino',
        'donde-esta-el-gato': 'lago',
        'rapido-despacio': 'banco',
      };
      final parquePictures = FakePictureSource(
        frames: (ref, {required width, required height}) {
          final Uint8List bytes;
          if (ref.scene.contains('lago')) {
            bytes = lagoBytes;
          } else if (ref.scene.contains('banco')) {
            bytes = bancoBytes;
          } else {
            bytes = caminoBytes;
          }
          return Image.memory(
            bytes,
            width: width.toDouble(),
            height: height.toDouble(),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
          );
        },
      );
      final freePlan = FakeEntitlements(plan: Plan.free);
      addTearDown(freePlan.dispose);

      for (final shot in [
        (
          name: 'place_plan_390x844.png',
          size: const Size(390, 844),
          dpr: 3.0,
          rtl: false,
        ),
        (
          name: 'place_plan_412x915.png',
          size: const Size(412, 915),
          dpr: 2.625,
          rtl: false,
        ),
        (
          name: 'place_plan_ar_390x844.png',
          size: const Size(390, 844),
          dpr: 3.0,
          rtl: true,
        ),
      ]) {
        _phone(tester, size: shot.size, dpr: shot.dpr);
        final course = shot.rtl
            ? _ArabicPlaceCourse(
                customPairs: parquePairs,
                storyScenes: parqueScenes,
              )
            : MapFixtureCourse(
                builtPlaces: 3,
                customPairs: parquePairs,
                storyScenes: parqueScenes,
              );
        final f = fixture(builtPlaces: 3, reduceMotion: true);
        final services = fakeServices(
          progress: f.progress,
          course: course,
          clock: f.clock,
          nav: f.nav,
          clips: f.clips,
          haptics: f.haptics,
          pictures: parquePictures,
          reduceMotion: true,
        );
        final lang = services.course.language;
        final boundaryKey = GlobalKey();

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Directionality(
                textDirection: shot.rtl ? TextDirection.rtl : TextDirection.ltr,
                child: Scaffold(
                  backgroundColor: NocheColors.ground,
                  body: Stack(
                    fit: StackFit.expand,
                    children: [
                      PlaceScreen(
                        placeId: 'parque',
                        services: services,
                        entitlements: freePlan,
                      ),
                      PositionedDirectional(
                        start: 0,
                        end: 0,
                        bottom: 0,
                        child: NocheTabBar(
                          selectedId: NocheTabs.map,
                          tabNames: lang.tabNames,
                          script: lang.script,
                          languageCode: lang.code,
                          onTap: (_) {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.runAsync(() async {
          await precacheImage(
            MemoryImage(caminoBytes),
            tester.element(find.byType(PlaceScreen)),
          );
          await precacheImage(
            MemoryImage(lagoBytes),
            tester.element(find.byType(PlaceScreen)),
          );
          await precacheImage(
            MemoryImage(bancoBytes),
            tester.element(find.byType(PlaceScreen)),
          );
        });
        await tester.pump();

        final bytes = await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: shot.dpr);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          image.dispose();
          return byteData!.buffer.asUint8List();
        });
        File('${dir.path}/${shot.name}').writeAsBytesSync(bytes!);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }
}
