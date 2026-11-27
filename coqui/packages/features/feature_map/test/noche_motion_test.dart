@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:feature_map/src/motion.dart';
import 'package:feature_map/src/place_screen.dart';
import 'package:feature_map/src/scene_window.dart';
import 'package:feature_map/src/wording.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/map_fixture.dart';
import 'support/map_tester.dart';

void _phone(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double dpr = 3.0,
}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
}

ReviewPair _pair(String word, String scene) => ReviewPair(
  word: word,
  say: '',
  scene: scene,
  yes: PictureSpec(cam: const [0, 0, scenePictureWidth, scenePictureHeight]),
  no: PictureSpec(cam: const [0, 0, scenePictureWidth, scenePictureHeight]),
);

final _casaPairs = <ReviewPair>[
  _pair('frente', 'frente'),
  _pair('balcon', 'balcon'),
  _pair('camino', 'camino'),
];

const _casaScenes = <String, String>{
  'la-lluvia': 'frente',
  'quien-es': 'frente',
  'aqui-o-alla': 'balcon',
  'uno-dos-tres': 'camino',
};

FakePictureSource _pixelPictures() {
  final cache = <String, Uint32List>{};
  return FakePictureSource(
    frames: (ref, {required width, required height}) {
      final key = '${ref.scene}:${width}x$height';
      final pixels = cache.putIfAbsent(
        key,
        () =>
            Uint32List(width * height)
              ..fillRange(0, width * height, 0xFF335577),
      );
      return PixelView(pixels: pixels, width: width, height: height);
    },
  );
}

int _pixelScaleInWindow(
  WidgetTester tester, {
  required Object tag,
  required double dpr,
}) {
  final surface = find.byKey(NocheWindow.surfaceKey(tag));
  expect(surface, findsOneWidget);
  final pixelFinder = find.descendant(
    of: surface,
    matching: find.byType(PixelView),
  );
  expect(pixelFinder, findsOneWidget);
  final size = tester.getSize(pixelFinder);
  final scale = pixelViewScale(
    availableWidth: size.width,
    devicePixelRatio: dpr,
    width: scenePictureWidth,
  );
  expect(
    size.width * dpr / scenePictureWidth,
    closeTo(scale.toDouble(), 1e-3),
    reason: 'PixelView width must be a whole-number device-pixel multiple',
  );
  expect(
    size.height * dpr / scenePictureHeight,
    closeTo(scale.toDouble(), 1e-3),
    reason: 'PixelView height must be a whole-number device-pixel multiple',
  );
  return scale;
}

double _windowRadius(WidgetTester tester, Object tag) {
  final clip = tester.widget<ClipRRect>(
    find.byKey(NocheWindow.surfaceKey(tag)),
  );
  return clip.borderRadius.resolve(TextDirection.ltr).topLeft.x;
}

double _slotOpacity(WidgetTester tester, Key key) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final widget = tester.widget(finder);
  if (widget is Opacity) return widget.opacity;
  return tester
      .widget<Opacity>(
        find.descendant(of: finder, matching: find.byType(Opacity)).first,
      )
      .opacity;
}

double _slotDy(WidgetTester tester, Key key) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final transform = tester.widget<Transform>(finder);
  return transform.transform.getTranslation().y;
}

class _FlowNavigator implements AppNavigator {
  _FlowNavigator(this.onGo, this.onBack);

  final ValueChanged<AppRoute> onGo;
  final VoidCallback onBack;
  final List<AppRoute> routes = [];

  @override
  void go(AppRoute route) {
    routes.add(route);
    onGo(route);
  }

  @override
  void back() => onBack();
}

/// Minimal stand-in for `feature_story`'s lesson screen: a 64 px header above
/// a 400 px [NocheWindow] sharing the story's [MapMotion.storyWindowTag] and
/// the same whole-number scene picture geometry.
class _MockLessonScreen extends StatelessWidget {
  const _MockLessonScreen({
    required this.storyId,
    required this.pictures,
    required this.pictureRef,
    required this.onBack,
  });

  final String storyId;
  final PictureSource pictures;
  final PictureRef pictureRef;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;
    final geom = computeScenePictureGeometry(
      viewportWidth: media.size.width,
      heroHeight: placeHeroBaseHeight + media.padding.top,
      dpr: dpr,
    );
    const windowHeight = 400.0;
    final picSize = geom.pictureSize;
    final offset = Offset(
      (media.size.width - picSize.width) / 2,
      (windowHeight - picSize.height) / 2,
    );

    return ColoredBox(
      key: const Key('mock-lesson-screen'),
      color: NocheColors.ground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 64 + media.padding.top,
            child: Align(
              alignment: AlignmentDirectional.bottomStart,
              child: Pressable(
                key: const Key('mock-lesson-back'),
                onPressed: onBack,
                builder: (context, _) => const SizedBox.square(
                  dimension: NocheSize.touch,
                  child: Center(
                    child: NocheIcon(
                      NocheIcons.close,
                      size: 24,
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: media.size.width,
            height: windowHeight,
            child: NocheWindow(
              tag: MapMotion.storyWindowTag(storyId),
              borderRadius: 0,
              pictureSize: picSize,
              pictureOffset: offset,
              child: NocheLtr(
                child: pictures.of(
                  pictureRef,
                  width: scenePictureWidth,
                  height: scenePictureHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMotionHarness extends StatefulWidget {
  const _MapMotionHarness({
    required this.course,
    required this.progress,
    required this.clock,
    required this.pictures,
    required this.entitlements,
    this.reduceMotion = false,
    this.disableAnimations = false,
    this.textDirection = TextDirection.ltr,
    this.onNavReady,
  });

  final CourseCatalog course;
  final ProgressStore progress;
  final Clock clock;
  final PictureSource pictures;
  final Entitlements entitlements;
  final bool reduceMotion;
  final bool disableAnimations;
  final TextDirection textDirection;
  final void Function(_FlowNavigator nav, GlobalKey<NavigatorState> navKey)?
  onNavReady;

  @override
  State<_MapMotionHarness> createState() => _MapMotionHarnessState();
}

class _MapMotionHarnessState extends State<_MapMotionHarness> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final HeroController _heroController = HeroController();
  late final _FlowNavigator _flowNav;
  late final Services _services;

  @override
  void initState() {
    super.initState();
    _flowNav = _FlowNavigator(_handleGo, _handleBack);
    _services = fakeServices(
      progress: widget.progress,
      course: widget.course,
      clock: widget.clock,
      nav: _flowNav,
      pictures: widget.pictures,
      entitlements: widget.entitlements,
      reduceMotion: widget.reduceMotion,
    );
    widget.onNavReady?.call(_flowNav, _navKey);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  PictureRef _storyRef(String storyId) {
    final pairs = widget.course.pairs;
    if (pairs.isNotEmpty) {
      return PictureRef.of(pairs.first, pairs.first.yes);
    }
    return PictureRef.of(_casaPairs.first, _casaPairs.first.yes);
  }

  void _handleGo(AppRoute route) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    if (route is PlaceRoute) {
      nav.push(
        buildNocheMapRoute<void>(
          context: nav.context,
          serviceReduceMotion: widget.reduceMotion,
          builder: (_) => PlaceScreen(
            placeId: route.placeId,
            services: _services,
            entitlements: widget.entitlements,
          ),
        ),
      );
    } else if (route is StoryRoute) {
      nav.push(
        buildNocheMapRoute<void>(
          context: nav.context,
          serviceReduceMotion: widget.reduceMotion,
          builder: (_) => _MockLessonScreen(
            storyId: route.id,
            pictures: widget.pictures,
            pictureRef: _storyRef(route.id),
            onBack: _handleBack,
          ),
        ),
      );
    } else if (route is TabRoute && route.tab == NocheTabs.map) {
      if (nav.canPop()) nav.pop();
    }
  }

  void _handleBack() {
    final nav = _navKey.currentState;
    if (nav != null && nav.canPop()) nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final baseMedia = MediaQuery.of(context);
    return MediaQuery(
      data: baseMedia.copyWith(disableAnimations: widget.disableAnimations),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: coquiTheme(),
        builder: (context, child) =>
            Directionality(textDirection: widget.textDirection, child: child!),
        home: Scaffold(
          backgroundColor: NocheColors.ground,
          body: Builder(
            builder: (navContext) => Navigator(
              key: _navKey,
              observers: [_heroController],
              onGenerateRoute: (_) => buildNocheMapRoute<void>(
                context: navContext,
                serviceReduceMotion: widget.reduceMotion,
                builder: (_) => MapScreen(
                  services: _services,
                  reviewTitle: MapWording.reviewTitle,
                  entitlements: widget.entitlements,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pumpMapReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('N8.4 Map motion', () {
    mapTest(
      '1. Card -> Place (pageIn): constant PixelView scale, map fade in quick, staggered rows at 120/150/180 ms, chrome at 200 ms, play bar at 260 ms',
      (tester) async {
        const dpr = 3.0;
        _phone(tester, size: const Size(390, 844), dpr: dpr);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        // Mark story 1 heard? Leave story 1 unheard and seed story 2 or keep story 1 unheard:
        // On fresh place 1, next unheard is 'la-lluvia' (scene 'frente').
        // Give place 1 a call so all three rows (title, stories, pills) exist, or mark none heard
        // so Call pill is still present (pillsRow != null).
        final course = MapFixtureCourse(
          builtPlaces: 3,
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
          callPlaces: const {'casa', 'parque', 'cocina'},
        );
        final pictures = _pixelPictures();
        final expectedGeom = computeScenePictureGeometry(
          viewportWidth: 390,
          heroHeight: placeHeroBaseHeight,
          dpr: dpr,
        );
        const tag = 'la-lluvia';

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            pictures: pictures,
            entitlements: const AllowAllEntitlements(),
          ),
        );
        await _pumpMapReady(tester);

        // Start state on MapScreen: 72x72, radius 16, whole-number PixelView scale.
        final startRect = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(startRect.width, closeTo(72, 0.5));
        expect(startRect.height, closeTo(72, 0.5));
        expect(_windowRadius(tester, tag), closeTo(NocheSize.tileRadius, 0.01));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        expect(_slotOpacity(tester, const Key('map-motion-content')), 1.0);

        // Open place from Up next card.
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();

        // At 70 ms: map content is mid-fade (in quick = 140 ms).
        await tester.pump(const Duration(milliseconds: 70));
        final mapOpMid = _slotOpacity(tester, const Key('map-motion-content'));
        expect(mapOpMid, greaterThan(0.0));
        expect(mapOpMid, lessThan(1.0));

        // At 120 ms: place rows have not risen yet.
        await tester.pump(const Duration(milliseconds: 50));
        expect(_slotOpacity(tester, const Key('place-motion-title')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-stories')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-pills')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-back')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-counter')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-play-bar')), 0.0);

        // At 140 ms: map faded out completely; s1 (title) is rising; s2 (150ms) still 0.
        await tester.pump(const Duration(milliseconds: 20));
        expect(_slotOpacity(tester, const Key('map-motion-content')), 0.0);
        final s1Op140 = _slotOpacity(tester, const Key('place-motion-title'));
        final s1Dy140 = _slotDy(tester, const Key('place-motion-title'));
        expect(s1Op140, greaterThan(0.0));
        expect(s1Op140, lessThan(1.0));
        expect(s1Dy140, greaterThan(0.0));
        expect(s1Dy140, lessThan(NocheMotion.row));
        expect(_slotOpacity(tester, const Key('place-motion-stories')), 0.0);

        // At 160 ms (pageIn ~/ 2): Hero shuttle mid-flight, constant PixelView scale, s2 rising, s3 still 0.
        await tester.pump(const Duration(milliseconds: 20));
        final midRect = tester.getRect(find.byKey(NocheWindow.surfaceKey(tag)));
        expect(midRect.width, greaterThan(72));
        expect(midRect.width, lessThan(390));
        expect(midRect.height, greaterThan(72));
        expect(midRect.height, lessThan(placeHeroBaseHeight));
        final midRadius = _windowRadius(tester, tag);
        expect(midRadius, greaterThan(0.0));
        expect(midRadius, lessThan(NocheSize.tileRadius));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        expect(
          _slotOpacity(tester, const Key('place-motion-stories')),
          greaterThan(0.0),
        );
        expect(
          _slotDy(tester, const Key('place-motion-stories')),
          greaterThan(0.0),
        );
        expect(_slotOpacity(tester, const Key('place-motion-pills')), 0.0);

        // At 195 ms: s3 (pills, 180 ms) is rising; s0 (chrome, 200 ms) still 0.
        await tester.pump(const Duration(milliseconds: 35));
        expect(
          _slotOpacity(tester, const Key('place-motion-pills')),
          greaterThan(0.0),
        );
        expect(
          _slotDy(tester, const Key('place-motion-pills')),
          greaterThan(0.0),
        );
        expect(_slotOpacity(tester, const Key('place-motion-back')), 0.0);
        expect(_slotOpacity(tester, const Key('place-motion-counter')), 0.0);

        // At 230 ms: s0 (back & counter, 200 ms) fading in with dy == 0; play bar (260 ms) still 0.
        await tester.pump(const Duration(milliseconds: 35));
        final backOp230 = _slotOpacity(tester, const Key('place-motion-back'));
        final counterOp230 = _slotOpacity(
          tester,
          const Key('place-motion-counter'),
        );
        expect(backOp230, greaterThan(0.0));
        expect(backOp230, lessThan(1.0));
        expect(counterOp230, closeTo(backOp230, 1e-6));
        expect(
          tester.getTopLeft(find.byKey(const Key('place-back'))).dy,
          closeTo(16, 0.5),
        );
        expect(_slotOpacity(tester, const Key('place-motion-play-bar')), 0.0);

        // At 290 ms: play bar (260 ms) rising.
        await tester.pump(const Duration(milliseconds: 60));
        final nextOp290 = _slotOpacity(
          tester,
          const Key('place-motion-play-bar'),
        );
        final nextDy290 = _slotDy(tester, const Key('place-motion-play-bar'));
        expect(nextOp290, greaterThan(0.0));
        expect(nextOp290, lessThan(1.0));
        expect(nextDy290, greaterThan(0.0));
        expect(nextDy290, lessThan(NocheMotion.row));

        // End state (500 ms total): 390x296, radius 0, constant PixelView scale, all rows settled.
        await tester.pump(const Duration(milliseconds: 220));
        final endRect = tester.getRect(find.byKey(NocheWindow.surfaceKey(tag)));
        expect(endRect.width, closeTo(390, 0.5));
        expect(endRect.height, closeTo(placeHeroBaseHeight, 0.5));
        expect(_windowRadius(tester, tag), closeTo(0.0, 0.01));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        for (final key in const [
          Key('place-motion-back'),
          Key('place-motion-counter'),
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          expect(_slotOpacity(tester, key), 1.0, reason: '$key settled');
        }
        for (final key in const [
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          expect(_slotDy(tester, key), 0.0, reason: '$key dy settled');
        }

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '2. Back (pageOut): Place -> Map and Story -> Place fade in over quick after 40 ms with dy == 0 and constant PixelView scale',
      (tester) async {
        const dpr = 3.0;
        _phone(tester, size: const Size(390, 844), dpr: dpr);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        final course = MapFixtureCourse(
          builtPlaces: 3,
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
          callPlaces: const {'casa', 'parque', 'cocina'},
        );
        final pictures = _pixelPictures();
        final expectedGeom = computeScenePictureGeometry(
          viewportWidth: 390,
          heroHeight: placeHeroBaseHeight,
          dpr: dpr,
        );
        const tag = 'la-lluvia';

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            pictures: pictures,
            entitlements: const AllowAllEntitlements(),
          ),
        );
        await _pumpMapReady(tester);

        // Open Place and settle.
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 520));
        expect(find.byKey(const Key('place-screen')), findsOneWidget);

        // Open Story from Place play bar and settle.
        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 360));
        expect(find.byKey(const Key('mock-lesson-screen')), findsOneWidget);

        // Pop Story -> Place in pageOut (200 ms): rows wait 40 ms, fade in over quick with dy == 0.
        await tester.tap(find.byKey(const Key('mock-lesson-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        for (final key in const [
          Key('place-motion-back'),
          Key('place-motion-counter'),
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          expect(
            _slotOpacity(tester, key),
            0.0,
            reason: '$key waits 40 ms before back fade',
          );
        }

        await tester.pump(
          const Duration(milliseconds: 80),
        ); // 110 ms into 200 ms pageOut
        for (final key in const [
          Key('place-motion-back'),
          Key('place-motion-counter'),
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          final op = _slotOpacity(tester, key);
          expect(op, greaterThan(0.0), reason: '$key fading in on back');
          expect(op, lessThan(1.0), reason: '$key still fading in on back');
        }
        for (final key in const [
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          expect(
            _slotDy(tester, key),
            0.0,
            reason: '$key must not rise on back',
          );
        }
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );

        // Finish Story -> Place pop.
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.byKey(const Key('mock-lesson-screen')), findsNothing);
        expect(_slotOpacity(tester, const Key('place-motion-title')), 1.0);

        // Now pop Place -> Map via Back button in pageOut (200 ms).
        await tester.tap(find.byKey(const Key('place-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(_slotOpacity(tester, const Key('map-motion-content')), 0.0);

        // Mid-flight at 100 ms (pageOut ~/ 2): NocheWindow shrinks with constant PixelView scale,
        // and MapScreen fades in over quick after 40 ms with zero rise.
        await tester.pump(const Duration(milliseconds: 70));
        final backMidRect = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(backMidRect.width, greaterThan(72));
        expect(backMidRect.width, lessThan(390));
        expect(backMidRect.height, greaterThan(72));
        expect(backMidRect.height, lessThan(placeHeroBaseHeight));
        final backMidRadius = _windowRadius(tester, tag);
        expect(backMidRadius, greaterThan(0.0));
        expect(backMidRadius, lessThan(NocheSize.tileRadius));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        final mapReturnOp = _slotOpacity(
          tester,
          const Key('map-motion-content'),
        );
        expect(mapReturnOp, greaterThan(0.0));
        expect(mapReturnOp, lessThan(1.0));

        // Settled back on MapScreen.
        await tester.pump(const Duration(milliseconds: 140));
        expect(find.byKey(const Key('place-screen')), findsNothing);
        final finalRect = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(finalRect.width, closeTo(72, 0.5));
        expect(finalRect.height, closeTo(72, 0.5));
        expect(_windowRadius(tester, tag), closeTo(NocheSize.tileRadius, 0.01));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        expect(_slotOpacity(tester, const Key('map-motion-content')), 1.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '3. Card play disc -> Story & Place play bar -> Story share storyId tag with constant PixelView scale and unique Hero per screen',
      (tester) async {
        const dpr = 3.0;
        _phone(tester, size: const Size(390, 844), dpr: dpr);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        final course = MapFixtureCourse(
          builtPlaces: 3,
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
        );
        final pictures = _pixelPictures();
        final expectedGeom = computeScenePictureGeometry(
          viewportWidth: 390,
          heroHeight: placeHeroBaseHeight,
          dpr: dpr,
        );
        const tag = 'la-lluvia';

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            pictures: pictures,
            entitlements: const AllowAllEntitlements(),
          ),
        );
        await _pumpMapReady(tester);

        // Card play disc -> Story in pageIn.
        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        final midCardToStory = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(midCardToStory.width, greaterThan(72));
        expect(midCardToStory.width, lessThan(390));
        expect(midCardToStory.height, greaterThan(72));
        expect(midCardToStory.height, lessThan(400));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );

        await tester.pump(const Duration(milliseconds: 200));
        final endCardToStory = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(endCardToStory.width, closeTo(390, 0.5));
        expect(endCardToStory.height, closeTo(400, 0.5));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );

        // Pop back to Map, then open Place and verify unique Hero tag (story tiles have zero Heroes).
        await tester.tap(find.byKey(const Key('mock-lesson-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 520));

        final placeHeroes = tester
            .widgetList<Hero>(
              find.descendant(
                of: find.byKey(const Key('place-screen')),
                matching: find.byType(Hero),
              ),
            )
            .toList();
        expect(placeHeroes, hasLength(1));
        expect(placeHeroes.single.tag, tag);
        expect(
          find.descendant(
            of: find.byKey(const Key('place-stories-scroll')),
            matching: find.byType(Hero),
          ),
          findsNothing,
        );

        // Place play bar -> Story in pageIn with constant PixelView scale.
        await tester.tap(find.byKey(const Key('place-play-bar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        final midPlaceToStory = tester.getRect(
          find.byKey(NocheWindow.surfaceKey(tag)),
        );
        expect(midPlaceToStory.height, greaterThan(placeHeroBaseHeight));
        expect(midPlaceToStory.height, lessThan(400));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );

        await tester.pump(const Duration(milliseconds: 200));
        expect(
          _pixelScaleInWindow(tester, tag: tag, dpr: dpr),
          expectedGeom.scale,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '4. Reduced motion (MediaQueryData(disableAnimations: true)): no Hero mounted, rows arrive together with dy == 0 in quick',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        final course = MapFixtureCourse(
          builtPlaces: 3,
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
          callPlaces: const {'casa', 'parque', 'cocina'},
        );

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            disableAnimations: true,
          ),
        );
        await _pumpMapReady(tester);

        expect(find.byType(Hero), findsNothing);

        // Open Place under reduced motion.
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();
        expect(find.byType(Hero), findsNothing);

        // At 190 ms (rowsAfter 120 ms + half of quick 140 ms): s1, s2, s3, next all have the
        // exact same partial opacity and dy == 0.
        await tester.pump(const Duration(milliseconds: 190));
        final s1Op = _slotOpacity(tester, const Key('place-motion-title'));
        final s2Op = _slotOpacity(tester, const Key('place-motion-stories'));
        final s3Op = _slotOpacity(tester, const Key('place-motion-pills'));
        final nextOp = _slotOpacity(tester, const Key('place-motion-play-bar'));
        expect(s1Op, greaterThan(0.0));
        expect(s1Op, lessThan(1.0));
        expect(s2Op, closeTo(s1Op, 1e-6));
        expect(s3Op, closeTo(s1Op, 1e-6));
        expect(nextOp, closeTo(s1Op, 1e-6));
        for (final key in const [
          Key('place-motion-title'),
          Key('place-motion-stories'),
          Key('place-motion-pills'),
          Key('place-motion-play-bar'),
        ]) {
          expect(_slotDy(tester, key), 0.0);
        }

        // Settle Place (total reduced duration = 340 ms).
        await tester.pump(const Duration(milliseconds: 200));
        expect(_slotOpacity(tester, const Key('place-motion-back')), 1.0);
        expect(_slotOpacity(tester, const Key('place-motion-play-bar')), 1.0);

        // Back under reduced motion: no 40 ms wait, Map fades immediately in quick (140 ms).
        await tester.tap(find.byKey(const Key('place-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(
          _slotOpacity(tester, const Key('map-motion-content')),
          greaterThan(0.0),
        );
        await tester.pump(const Duration(milliseconds: 140));
        expect(_slotOpacity(tester, const Key('map-motion-content')), 1.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '5. Arabic RTL fake course (FakeCourseCatalog.arabic()): mirrored Card -> Place -> Back flow with LTR numbers and pictures, zero exceptions',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        // Seed a streak so streak-chip is mounted and checked for NocheLtr.
        finishStory(progress, 'la-lluvia');
        final arabicCourse = FakeCourseCatalog.arabic();

        await tester.pumpWidget(
          _MapMotionHarness(
            course: arabicCourse,
            progress: progress,
            clock: clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            textDirection: TextDirection.rtl,
          ),
        );
        await _pumpMapReady(tester);

        // Map mirrored layout + LTR streak text + LTR map picture.
        final langRect = tester.getRect(find.byKey(const Key('language-chip')));
        final streakRect = tester.getRect(find.byKey(const Key('streak-chip')));
        expect(langRect.right, closeTo(390 - 16, 0.5));
        expect(streakRect.left, closeTo(16, 0.5));
        expect(
          Directionality.of(tester.element(find.text('1 day'))),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(
            tester.element(
              find.descendant(
                of: find.byKey(const Key('up-next-window')),
                matching: find.byType(LayoutBuilder),
              ),
            ),
          ),
          TextDirection.ltr,
        );

        // Open Place in RTL.
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 380));

        // Place mirrored layout + LTR counter/heard numbers + LTR hero picture.
        final backRect = tester.getRect(find.byKey(const Key('place-back')));
        final counterRect = tester.getRect(
          find.byKey(const Key('place-counter')),
        );
        expect(backRect.right, closeTo(390 - 16, 0.5));
        expect(counterRect.left, closeTo(16, 0.5));
        expect(
          Directionality.of(tester.element(find.textContaining('Place 1 of'))),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(
            tester.element(find.textContaining('stories heard')),
          ),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(
            tester.element(
              find.descendant(
                of: find.byKey(const Key('place-hero-picture')),
                matching: find.byType(LayoutBuilder),
              ),
            ),
          ),
          TextDirection.ltr,
        );

        // Back to Map in RTL.
        await tester.tap(find.byKey(const Key('place-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 140));
        expect(find.byKey(const Key('map-screen')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '6. Entitlement guard: Plan.free with place 1 done routes up-next-play to PlaceRoute(parque) and opens no StoryRoute',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);
        final f = fixture(builtPlaces: 3, reduceMotion: true);
        for (final id in f.services.course.places[0].stories) {
          finishStory(f.progress, id);
        }
        f.clock.advance(const Duration(days: 1));
        for (final id in f.services.course.places[0].stories) {
          finishStory(f.progress, id);
        }

        late _FlowNavigator nav;
        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: entitlements,
            reduceMotion: true,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        expect(find.text('UP NEXT · EL PARQUE'), findsOneWidget);
        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(nav.routes.whereType<StoryRoute>(), isEmpty);
        expect(nav.routes, [const PlaceRoute('parque')]);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-see-plans')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '7. Stable keys contract: MapScreen and PlaceScreen expose root and integration keys',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        finishStory(progress, 'la-lluvia');
        final course = MapFixtureCourse(
          builtPlaces: 3,
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
        );
        final freePlan = FakeEntitlements(plan: Plan.free);
        addTearDown(freePlan.dispose);

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            pictures: _pixelPictures(),
            entitlements: freePlan,
            reduceMotion: true,
          ),
        );
        await _pumpMapReady(tester);

        for (final key in const [
          Key('map-screen'),
          Key('language-chip'),
          Key('streak-chip'),
          Key('up-next-card'),
          Key('up-next-play'),
          Key('up-next-place'),
          Key('you-are-here'),
        ]) {
          expect(find.byKey(key), findsOneWidget, reason: '$key on MapScreen');
        }

        // Open place 1 (unlocked on Plan.free).
        await tester.tap(find.byKey(const Key('up-next-place')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        for (final key in const [
          Key('place-screen'),
          Key('place-back'),
          Key('place-counter'),
          Key('place-hero-picture'),
          Key('story-tile-la-lluvia'),
          Key('place-play-bar'),
          Key('place-stories-scroll'),
        ]) {
          expect(
            find.byKey(key),
            findsOneWidget,
            reason: '$key on PlaceScreen',
          );
        }

        // Direct PlaceScreen with enteringFromBack: true fades with dy == 0 and exposes plan card keys when locked.
        final services = fakeServices(
          progress: progress,
          course: course,
          clock: clock,
          pictures: _pixelPictures(),
          entitlements: freePlan,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Scaffold(
              body: PlaceScreen(
                placeId: 'parque',
                services: services,
                entitlements: freePlan,
                enteringFromBack: true,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 110));
        expect(_slotDy(tester, const Key('place-motion-title')), 0.0);
        expect(
          _slotOpacity(tester, const Key('place-motion-title')),
          greaterThan(0.0),
        );
        await tester.pump(const Duration(milliseconds: 120));

        for (final key in const [
          Key('place-screen'),
          Key('place-back'),
          Key('place-plan-card'),
          Key('place-see-plans'),
          Key('place-plan-tag'),
        ]) {
          expect(
            find.byKey(key),
            findsOneWidget,
            reason: '$key on locked PlaceScreen',
          );
        }

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
