// The map tab on the fakes: Noche layout, camera centering/clamping, chips, You are here pill,
// Up next card, frog hops, PlaceRoute navigation, reduceMotion, and RTL mirroring.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_model.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/map_fixture.dart';
import 'support/map_tester.dart';

/// What a test holds of the screen it started.
class Shown {
  Shown(this.f, this.perf);
  final MapFixture f;
  final MapPerf perf;
  late MapPicture picture;
  MapCamera? camera;
}

/// The phone of ref/pantallas: 412 x 915 at 2.625 (or another size).
void phone(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  double dpr = 2.625,
}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
}

Future<Shown> showMap(
  WidgetTester tester,
  MapFixture f, {
  String? reviewTitle = 'Review',
  int? openPlace,
  TextDirection textDirection = TextDirection.ltr,
  Entitlements entitlements = const AllowAllEntitlements(),
}) async {
  final shown = Shown(f, MapPerf());
  await tester.pumpWidget(
    MaterialApp(
      theme: coquiTheme(),
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          backgroundColor: NocheColors.ground,
          body: MapScreen(
            services: f.services,
            perf: shown.perf,
            reviewTitle: reviewTitle,
            openPlace: openPlace,
            entitlements: entitlements,
            onPicture: (p) => shown.picture = p,
            onCamera: (c) => shown.camera = c,
          ),
        ),
      ),
    ),
  );
  // first frame: ground; postFrame: bake + course load; second postFrame: camera center
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return shown;
}

/// Pumps [ms] of frames, 50 ms at a time (the screen never steps by more than 50 ms).
Future<void> run(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Where the stop of place [k] (0 to 9) is on the screen, scrolled into the clear middle band.
Future<Offset> stopPos(WidgetTester tester, int k) async {
  final view = find.byType(PixelView);
  final scrollV = tester.state<ScrollableState>(find.byType(Scrollable).at(0));
  final scrollH = tester.state<ScrollableState>(find.byType(Scrollable).at(1));
  final scale = tester.getSize(view).width / mapW;
  final p = MapPicture().stopOnPicture(k);
  final size = tester.getSize(find.byType(MapScreen));
  final posV = scrollV.position;
  final posH = scrollH.position;
  posV.jumpTo(
    (p.sy * scale - size.height * 0.4).clamp(
      posV.minScrollExtent,
      posV.maxScrollExtent,
    ),
  );
  posH.jumpTo(
    (p.sx * scale - size.width * 0.5).clamp(
      posH.minScrollExtent,
      posH.maxScrollExtent,
    ),
  );
  await tester.pump();
  final top = tester.getTopLeft(view);
  return top + Offset(p.sx * scale, p.sy * scale);
}

Future<void> tapStop(WidgetTester tester, int k) async {
  await tester.tapAt(await stopPos(tester, k));
  await tester.pump();
}

/// The reddish pixels of the picture inside the rectangle where the flag of stop [k] is drawn.
int flagPixels(MapPicture m, int k) {
  final xy = XY(PADS[k][0] + .9, PADS[k][1] - .9);
  final a = m.e.project(xy.x, xy.y, 0),
      b = m.e.project(xy.x + .63, xy.y - .63, 1.7);
  var n = 0;
  for (var y = (b.sy - 6).floor(); y <= (a.sy + 2).ceil(); y++) {
    for (var x = (a.sx - 2).floor(); x <= (b.sx + 6).ceil(); x++) {
      final c = m.pix[y * mapW + x];
      final r = c & 255, g = c >> 8 & 255, bl = c >> 16 & 255;
      if (r > 150 && g < 100 && bl < 100) n++;
    }
  }
  return n;
}

class _ArabicTestCourse extends MapFixtureCourse implements LanguageCatalog {
  _ArabicTestCourse() : super(builtPlaces: 3);

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
  mapTest('the ground colour first, then the bake, then the map', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final perf = MapPerf();
    late MapPicture picture;
    bool? bakedAtFirstFrame;
    var emptyAtFirstFrame = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: coquiTheme(),
        home: Scaffold(
          body: MapScreen(
            services: f.services,
            perf: perf,
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) {
              picture = p;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                bakedAtFirstFrame = p.baked;
                emptyAtFirstFrame = p.pix.every((c) => c == 0);
              });
            },
          ),
        ),
      ),
    );
    expect(bakedAtFirstFrame, isFalse);
    expect(emptyAtFirstFrame, isTrue);
    await tester.pump();
    await tester.pump();
    expect(picture.baked, isTrue);
    expect(perf.bakeMs, greaterThan(0));
    expect(picture.pix.where((c) => c != 0).length, greaterThan(60000));
    expect(find.byType(PixelView), findsOneWidget);
  });

  mapTest(
    'tap an open place: the frog hops there and focuses the card; tapping again opens PlaceRoute',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      final m = s.picture;
      expect(m.FROG.at, 0);
      expect(m.STATE.abierto.take(4), [true, true, true, false]);
      await tapStop(tester, 2);
      expect(find.byKey(const Key('map-dest-pill')), findsOneWidget);
      expect(f.nav.routes, isEmpty);
      expect(f.haptics.ticks, 1);
      // After 90 ms tripStartDelay, the frog is mid-hop
      await run(tester, 150);
      expect(m.FROG.path, isNotNull);
      expect(f.nav.routes, isEmpty);
      await run(tester, 2500);
      expect(m.FROG.path, isNull);
      expect(m.FROG.at, 2);
      final stop = XY(PADS[2][0], PADS[2][1]);
      expect(m.FROG.x, closeTo(stop.x, 1e-9));
      expect(m.FROG.y, closeTo(stop.y, 1e-9));
      expect(f.nav.routes, isEmpty);
      expect(f.clips.tones, hasLength(6));
      for (final t in f.clips.tones) {
        expect(
          (t.hz, t.dur, t.wave, t.vol, t.toHz),
          (320.0, .07, 'square', .025, 520.0),
        );
      }
      // Card switched to the visited place without opening PlaceRoute
      expect(find.byKey(const Key('map-place-card')), findsOneWidget);
      expect(find.text('La cocina'), findsOneWidget);
      // Tapping the focused stop again opens PlaceRoute
      await tapStop(tester, 2);
      expect(f.nav.routes, [const PlaceRoute('cocina')]);
    },
  );

  mapTest(
    'a tap on a locked place shows the lock pill without hopping or opening PlaceRoute',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      await tapStop(tester, 3);
      await run(tester, 200);
      expect(s.picture.FROG.path, isNull);
      expect(s.picture.FROG.at, 0);
      expect(f.clips.tones, isEmpty);
      expect(f.nav.routes, isEmpty);
      expect(find.byKey(const Key('map-lock-pill')), findsOneWidget);
      expect(find.text('After La cocina', findRichText: true), findsOneWidget);
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
      await run(tester, 1800);
      expect(find.byKey(const Key('map-lock-pill')), findsNothing);
    },
  );

  mapTest(
    '"Open every place" opens a place with no stories: the frog hops and focuses card; tapping again opens PlaceRoute',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'todo', todo: true);
      final s = await showMap(tester, f);
      expect(s.picture.STATE.abierto, everyElement(isTrue));
      await tapStop(tester, 3);
      await run(tester, 2500);
      expect(s.picture.FROG.at, 3);
      expect(f.nav.routes, isEmpty);
      expect(find.byKey(const Key('map-place-card')), findsOneWidget);
      expect(find.text('El colmado'), findsOneWidget);
      expect(find.text('Not built yet.'), findsOneWidget);
      await tapStop(tester, 3);
      expect(f.nav.routes, [const PlaceRoute('colmado')]);
    },
  );

  mapTest(
    'finishing the last story of a place adds its flag and moves the frog',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      final m = s.picture;
      final course = f.services.course.places;
      expect(m.STATE.hecho.take(2), [false, false]);
      expect(m.FROG.at, 0);
      expect(flagPixels(m, 0), 0);
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
      final ids = course[0].stories;
      for (final id in ids.take(ids.length - 1)) {
        finishStory(f.progress, id);
        await tester.pump();
      }
      expect(m.STATE.hecho[0], isFalse);
      expect(m.FROG.at, 0);
      expect(flagPixels(m, 0), 0);
      finishStory(f.progress, ids.last);
      await tester.pump();
      expect(m.STATE.hecho.take(3), [true, false, false]);
      expect(m.STATE.aqui, 1);
      expect(m.FROG.at, 1);
      final stop = XY(PADS[1][0], PADS[1][1]);
      expect(m.FROG.x, closeTo(stop.x, 1e-9));
      expect(m.FROG.y, closeTo(stop.y, 1e-9));
      expect(flagPixels(m, 0), greaterThan(20));
      // Play each story of La casa a second time so todayPlan advances to El parque.
      // Advance a day first so todayPlan's 3-new-stories/day cap does not hold us on La casa.
      f.clock.advance(const Duration(days: 1));
      for (final id in ids) {
        finishStory(f.progress, id);
      }
      await tester.pump();
      expect(find.text('UP NEXT · EL PARQUE'), findsOneWidget);
    },
  );

  mapTest(
    'the Up next card shows the first story, steps line, and play disc goes there',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      await showMap(tester, f);
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
      expect(find.text('La lluvia'), findsOneWidget);
      expect(find.text('New story · 4 min'), findsOneWidget);
      expect(find.text('Then a new story, then a new story'), findsOneWidget);
      // Tapping the picture/text opens PlaceRoute
      await tester.tap(find.byKey(const Key('up-next-place')));
      await tester.pump();
      expect(f.nav.routes, [const PlaceRoute('casa')]);
      // Tapping the orange play disc opens the story route
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(f.nav.routes, [
        const PlaceRoute('casa'),
        const StoryRoute('la-lluvia'),
      ]);
      expect(f.haptics.ticks, 2);
    },
  );

  mapTest('the Up next card: a story played once is a second play', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'segunda');
    await showMap(tester, f);
    expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
    expect(find.text('La lluvia'), findsOneWidget);
    expect(find.text('Second play · 2 min'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
  });

  mapTest('the Up next card offers Review in English when words are due', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'uno');
    await showMap(tester, f);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('1 word coming back · 3 min'), findsOneWidget);
    expect(find.text('Then a new story, then a new story'), findsOneWidget);
    expect(find.byKey(const Key('up-next-place')), findsNothing);
    await tester.tap(find.byKey(const Key('up-next-play')));
    await tester.pump();
    expect(f.nav.routes, [const ReviewRoute()]);
  });

  mapTest('with no title for the review the card goes to the stories', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'uno');
    await showMap(tester, f, reviewTitle: null);
    expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
    expect(find.text('La lluvia'), findsOneWidget);
  });

  mapTest('the chips: language chip opens LanguagesRoute; streak hides at 0', (
    tester,
  ) async {
    phone(tester);
    // Streak 0: streak chip is hidden
    final vacio = fixture(seed: 'vacio');
    await showMap(tester, vacio);
    expect(find.byKey(const Key('language-chip')), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('A1'), findsNothing);
    expect(find.byKey(const Key('streak-chip')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('language-chip'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.byKey(const Key('language-chip')));
    await tester.pump();
    expect(vacio.nav.routes, [const LanguagesRoute()]);

    // Streak 5: streak chip shows "5 days"
    final curso = fixture(seed: 'curso');
    await showMap(tester, curso);
    expect(find.byKey(const Key('streak-chip')), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
  });

  mapTest(
    'camera centers the current stop on screen and clamps edges at both phone sizes',
    (tester) async {
      for (final screen in [
        (size: const Size(390, 844), dpr: 3.0),
        (size: const Size(412, 915), dpr: 2.625),
      ]) {
        for (final demo in ['none', 'place3', 'last']) {
          phone(tester, size: screen.size, dpr: screen.dpr);
          final f = fixtureDemoWith(demo, reduceMotion: true);
          final s = await showMap(tester, f);
          final cam = s.camera!;
          final pixRect = tester.getRect(find.byType(PixelView));
          final cardRect = tester.getRect(
            find.byKey(const Key('up-next-card')),
          );
          final chipsRect = tester.getRect(
            find.byKey(const Key('language-chip')),
          );
          final pillRect = tester.getRect(
            find.byKey(const Key('you-are-here')),
          );

          // No horizontal or top edge of the map shows
          expect(pixRect.left, lessThanOrEqualTo(0.01));
          expect(pixRect.right, greaterThanOrEqualTo(screen.size.width - 0.01));
          expect(pixRect.top, lessThanOrEqualTo(0.01));
          expect(cam.mapWidth, greaterThanOrEqualTo(screen.size.width));
          expect(cam.mapHeight, greaterThanOrEqualTo(screen.size.height));

          // Current stop is on screen, between the top chips and the Up next card
          expect(cam.screenStopX, greaterThan(0));
          expect(cam.screenStopX, lessThan(screen.size.width));
          expect(cam.screenStopY, greaterThan(chipsRect.bottom));
          expect(cam.screenStopY, lessThan(cardRect.top));

          // "You are here" pill is centered over the current stop and visible on screen
          expect(pillRect.center.dx, closeTo(cam.screenStopX, 1.5));
          expect(pillRect.top, greaterThanOrEqualTo(chipsRect.bottom));
          expect(pillRect.bottom, lessThanOrEqualTo(cam.screenStopY));

          if (demo != 'place3') {
            // Stops 0 and 9 sit at u=0, so they are dead-centered horizontally
            expect(cam.screenStopX, closeTo(screen.size.width / 2, 1.5));
          } else {
            // Stop 2 (cocina) is near the right edge, clamped at maxScrollX
            expect(cam.scrollX, closeTo(cam.maxScrollX, 0.5));
            expect(cam.screenStopY, closeTo(screen.size.height * 0.51, 1.5));
          }
          if (demo == 'none') {
            expect(cam.screenStopY, closeTo(screen.size.height * 0.51, 1.5));
            expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
            expect(find.text('La lluvia'), findsOneWidget);
          } else if (demo == 'place3') {
            expect(find.text('UP NEXT · LA COCINA'), findsOneWidget);
            expect(find.text('Tengo hambre'), findsOneWidget);
            expect(find.text('6 days'), findsOneWidget);
          } else if (demo == 'last') {
            expect(find.text('UP NEXT · EL FUERTE'), findsOneWidget);
            expect(find.text('12 days'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    },
  );

  mapTest('openPlace routes immediately to PlaceRoute', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    await showMap(tester, f, openPlace: 3);
    expect(f.nav.routes, [const PlaceRoute('colmado')]);
  });

  mapTest(
    'reduceMotion: everything stands still; first tap moves immediately and focuses card, second opens PlaceRoute',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio', reduceMotion: true);
      final s = await showMap(tester, f);
      final m = s.picture;
      expect(tester.binding.hasScheduledFrame, isFalse);
      final first = [...m.pix];
      await tester.pump(const Duration(seconds: 2));
      expect(m.pix, first);
      expect(m.e.STILL, isTrue);
      await tapStop(tester, 2);
      await run(tester, 200);
      expect(m.FROG.path, isNull);
      expect(m.FROG.at, 2);
      expect(f.clips.tones, isEmpty);
      expect(f.nav.routes, isEmpty);
      expect(find.byKey(const Key('map-place-card')), findsOneWidget);
      expect(find.text('La cocina'), findsOneWidget);
      await tapStop(tester, 2);
      expect(f.nav.routes, [const PlaceRoute('cocina')]);
    },
  );

  mapTest('with motion the picture moves: wind, sea, the arrow', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final s = await showMap(tester, f);
    final first = [...s.picture.pix];
    await run(tester, 600);
    expect(s.picture.pix, isNot(first));
    expect(s.perf.frames, greaterThan(5));
  });

  mapTest('RTL course mirrors chips and card while keeping PixelView LTR', (
    tester,
  ) async {
    phone(tester, size: const Size(390, 844), dpr: 3.0);
    final clock = FakeClock(fixtureNowMs);
    final progress = FakeProgressStore(clock: clock);
    final nav = FakeNavigator();
    final services = fakeServices(
      progress: progress,
      course: _ArabicTestCourse(),
      clock: clock,
      nav: nav,
      reduceMotion: true,
    );
    final f = (
      services: services,
      progress: progress,
      nav: nav,
      clock: clock,
      clips: FakeClipPlayer(),
      haptics: FakeHaptics(),
    );
    await showMap(tester, f, textDirection: TextDirection.rtl);
    expect(find.text('Arabic'), findsOneWidget);
    // Language chip sits at start (right side in RTL)
    final chipRect = tester.getRect(find.byKey(const Key('language-chip')));
    expect(chipRect.right, closeTo(390 - 16, 0.5));
    // Play disc sits at end (left side in RTL)
    final playRect = tester.getRect(find.byKey(const Key('up-next-play')));
    final placeRect = tester.getRect(find.byKey(const Key('up-next-place')));
    expect(playRect.center.dx, lessThan(placeRect.center.dx));
    // PixelView is wrapped in LTR so the pixel map never mirrors
    final pixDir = Directionality.of(tester.element(find.byType(PixelView)));
    expect(pixDir, TextDirection.ltr);
  });

  mapTest('a tap that lands on no stop does nothing', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final s = await showMap(tester, f);
    final rect = tester.getRect(find.byType(PixelView));
    await tester.tapAt(rect.topLeft + const Offset(8, 8));
    await run(tester, 300);
    expect(s.picture.FROG.path, isNull);
    expect(f.nav.routes, isEmpty);
    expect(f.haptics.ticks, 0);
    expect(RendererBinding.instance.renderViews, isNotEmpty);
  });

  mapTest(
    'didUpdateWidget re-bakes with updated reduceMotion and uses new clips for hop sound',
    (tester) async {
      phone(tester);
      final first = fixture(seed: 'vacio', reduceMotion: false);
      final pictures = <MapPicture>[];
      Widget wrap(Services s) => MaterialApp(
        theme: coquiTheme(),
        home: Scaffold(
          backgroundColor: NocheColors.ground,
          body: MapScreen(
            services: s,
            entitlements: const AllowAllEntitlements(),
            onPicture: pictures.add,
          ),
        ),
      );
      await tester.pumpWidget(wrap(first.services));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(pictures, hasLength(1));
      expect(pictures.last.e.STILL, isFalse);
      expect(tester.binding.hasScheduledFrame, isTrue);

      // Switch to reduceMotion: true — MapPicture is re-baked with STILL and stops animating
      final still = fixture(seed: 'vacio', reduceMotion: true);
      await tester.pumpWidget(wrap(still.services));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(pictures, hasLength(2));
      expect(pictures.last.baked, isTrue);
      expect(pictures.last.e.STILL, isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      final frozen = [...pictures.last.pix];
      await tester.pump(const Duration(seconds: 1));
      expect(pictures.last.pix, frozen);

      // Switch back to reduceMotion: false with a fresh FakeClipPlayer — resumes motion and uses new clips
      final moved = fixture(seed: 'vacio', reduceMotion: false);
      await tester.pumpWidget(wrap(moved.services));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(pictures, hasLength(3));
      expect(pictures.last.baked, isTrue);
      expect(pictures.last.e.STILL, isFalse);
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tapStop(tester, 2);
      await run(tester, 3000);
      expect(first.clips.tones, isEmpty);
      expect(still.clips.tones, isEmpty);
      expect(moved.clips.tones, isNotEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  group('pickUpNextPictureRef', () {
    ReviewPair pair(String word, String scene) => ReviewPair(
      word: word,
      say: '',
      scene: scene,
      yes: PictureSpec(cam: const [0, 0]),
      no: PictureSpec(cam: const [0, 0]),
    );

    test('review returns matching due word pair, or null when no due word has a pair', () {
      final f = fixture(seed: 'vacio');
      final course = _PairsCourse([pair('casa', 'frente')]);
      const review = TodayEntry(
        line: '1 word coming back',
        minutes: 3,
        route: ReviewRoute(),
        review: true,
        kind: TodayEntryKind.review,
      );

      // No due words: never fall back to pairs.first
      expect(
        pickUpNextPictureRef(
          entry: review,
          course: course,
          progress: f.progress,
        ),
        isNull,
      );

      // Due word without a matching pair: still returns null
      f.progress.put(
        WordRecord(w: 'perro', primera: 1, ear: SkillRecord(etapa: 1, due: 1)),
      );
      expect(
        pickUpNextPictureRef(
          entry: review,
          course: course,
          progress: f.progress,
        ),
        isNull,
      );

      // Due word with a matching pair: returns its yes PictureRef
      f.progress.put(
        WordRecord(w: 'casa', primera: 1, ear: SkillRecord(etapa: 1, due: 1)),
      );
      final ref = pickUpNextPictureRef(
        entry: review,
        course: course,
        progress: f.progress,
      );
      expect(ref, isNotNull);
      expect(ref!.scene, 'frente');
    });

    test('story scene and place fallback normalize cleanly without loose substring contains', () {
      final f = fixture(seed: 'vacio');
      final casa = Place(
        id: 'casa',
        n: 1,
        name: 'La casa',
        en: "Grandma's house",
        scenes: const ['El frente', 'El balcón'],
      );
      final plaza = Place(
        id: 'plaza',
        n: 6,
        name: 'La plaza',
        en: 'The town square',
        scenes: const ['El banco de la plaza'],
      );
      const entry = TodayEntry(
        title: 'La lluvia',
        line: 'New story · play it twice',
        minutes: 4,
        route: StoryRoute('la-lluvia'),
        kind: TodayEntryKind.newStory,
      );

      // Exact normalized match on storyScene (accented vs plain)
      final balconCourse = _PairsCourse([pair('balcon', 'Balcón')]);
      expect(
        pickUpNextPictureRef(
          entry: entry,
          course: balconCourse,
          progress: f.progress,
          place: casa,
          storyScene: 'balcon',
        )?.scene,
        'Balcón',
      );

      // Place fallback normalizes pair scene ("Balcón" matches "El balcón")
      expect(
        pickUpNextPictureRef(
          entry: entry,
          course: balconCourse,
          progress: f.progress,
          place: casa,
        )?.scene,
        'Balcón',
      );

      // Loose substring does not match storyScene or place fallback
      final substringCourse = _PairsCourse([pair('x', 'frent')]);
      expect(
        pickUpNextPictureRef(
          entry: entry,
          course: substringCourse,
          progress: f.progress,
          place: casa,
          storyScene: 'frente',
        ),
        isNull,
      );
      expect(
        pickUpNextPictureRef(
          entry: entry,
          course: substringCourse,
          progress: f.progress,
          place: casa,
        ),
        isNull,
      );

      // Multi-word scene from another place does not loosely match "banco"
      final bancoCourse = _PairsCourse([pair('banco', 'banco')]);
      expect(
        pickUpNextPictureRef(
          entry: entry,
          course: bancoCourse,
          progress: f.progress,
          place: plaza,
        ),
        isNull,
      );
    });
  });

  mapTest(
    'Plan.free: place 2 keeps normal map state and opens PlaceRoute; Up next gates place 2 stories',
    (tester) async {
      phone(tester);
      final entitlements = FakeEntitlements(plan: Plan.free);
      addTearDown(entitlements.dispose);

      // Place 1 story and Review remain playable on Plan.free
      final fCasa = fixture(seed: 'vacio');
      await showMap(tester, fCasa, entitlements: entitlements);
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(fCasa.nav.routes, [const StoryRoute('la-lluvia')]);

      final fReview = fixture(seed: 'uno');
      await showMap(tester, fReview, entitlements: entitlements);
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(fReview.nav.routes, [const ReviewRoute()]);

      // Finish place 1 twice so Up next points to place 2 (El parque)
      final fCurso = fixture(seed: 'curso');
      fCurso.clock.advance(const Duration(days: 1));
      for (final id in fCurso.services.course.places[0].stories) {
        finishStory(fCurso.progress, id);
      }
      final shown = await showMap(
        tester,
        fCurso,
        entitlements: entitlements,
        reviewTitle: null,
      );
      expect(shown.picture.STATE.abierto.take(4), [true, true, true, false]);
      expect(find.text('UP NEXT · EL PARQUE'), findsOneWidget);

      // Up next play disc opens PlaceRoute('parque') instead of gated StoryRoute
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(fCurso.nav.routes, [const PlaceRoute('parque')]);

      // Tapping place 2 on map focuses its card; play disc still gates to PlaceRoute; tapping again opens PlaceRoute
      await tapStop(tester, 1);
      await run(tester, 400);
      expect(find.byKey(const Key('map-place-card')), findsOneWidget);
      expect(find.text('El parque'), findsOneWidget);
      expect(fCurso.nav.routes, [const PlaceRoute('parque')]);
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(fCurso.nav.routes, [
        const PlaceRoute('parque'),
        const PlaceRoute('parque'),
      ]);
      await tapStop(tester, 1);
      expect(fCurso.nav.routes, [
        const PlaceRoute('parque'),
        const PlaceRoute('parque'),
        const PlaceRoute('parque'),
      ]);

      // Upgrading to Plan.course restores direct StoryRoute playback for the focused place's next unheard story
      entitlements.plan = Plan.course;
      await tester.pump();
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(fCurso.nav.routes.last, const StoryRoute('arriba-abajo'));
    },
  );

  mapTest(
    'the Up next card Listen again play disc routes to StoryRoute with listen: true',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'todo');
      await showMap(tester, f);
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
      expect(find.text('La lluvia'), findsOneWidget);
      expect(find.text('Listen again · 2 min'), findsOneWidget);
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(f.nav.routes, [const StoryRoute('la-lluvia', listen: true)]);
    },
  );
}

class _PairsCourse extends MapFixtureCourse {
  _PairsCourse(this._customPairs);

  final List<ReviewPair> _customPairs;

  @override
  List<ReviewPair> get pairs => _customPairs;

  @override
  ReviewPair? pairFor(String word) {
    final n = language.normalize(word);
    for (final p in _customPairs) {
      if (language.normalize(p.word) == n) return p;
    }
    return null;
  }
}
