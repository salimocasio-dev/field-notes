@TestOn('vm')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/feature_map.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_picture.dart';
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

double _slotScale(WidgetTester tester, Key key) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final transform = tester.widget<Transform>(finder);
  return transform.transform.storage[0];
}

Future<void> _runFrames(WidgetTester tester, int ms, {int step = 50}) async {
  var remaining = ms;
  while (remaining > 0) {
    final dt = remaining < step ? remaining : step;
    await tester.pump(Duration(milliseconds: dt));
    remaining -= dt;
  }
}

Finder _mapPixelViewFinder() => find.descendant(
  of: find.byType(SingleChildScrollView).first,
  matching: find.byType(PixelView),
);

Future<void> _tapStopOnMap(
  WidgetTester tester,
  int k, {
  bool scrollFirst = true,
}) async {
  final view = _mapPixelViewFinder();
  final scale = tester.getSize(view).width / mapW;
  final p = MapPicture().stopOnPicture(k);
  if (scrollFirst) {
    final scrollV = tester.state<ScrollableState>(
      find.byType(Scrollable).at(0),
    );
    final scrollH = tester.state<ScrollableState>(
      find.byType(Scrollable).at(1),
    );
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
  }
  final top = tester.getTopLeft(view);
  await tester.tapAt(top + Offset(p.sx * scale, p.sy * scale));
  await tester.pump();
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
    this.clips,
    this.reduceMotion = false,
    this.disableAnimations = false,
    this.textDirection = TextDirection.ltr,
    this.useArrivalScope = false,
    this.overlayOpacity = 1.0,
    this.animateColdLoad = false,
    this.onPicture,
    this.onCamera,
    this.onNavReady,
  });

  final CourseCatalog course;
  final ProgressStore progress;
  final Clock clock;
  final PictureSource pictures;
  final Entitlements entitlements;
  final ClipPlayer? clips;
  final bool reduceMotion;
  final bool disableAnimations;
  final TextDirection textDirection;
  final bool useArrivalScope;
  final double overlayOpacity;
  final bool animateColdLoad;
  final void Function(MapPicture picture)? onPicture;
  final void Function(MapCamera camera)? onCamera;
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
      clips: widget.clips,
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
                builder: (_) {
                  final map = MapScreen(
                    services: _services,
                    reviewTitle: MapWording.reviewTitle,
                    entitlements: widget.entitlements,
                    onPicture: widget.onPicture,
                    onCamera: widget.onCamera,
                  );
                  if (!widget.useArrivalScope) return map;
                  return MapArrivalScope(
                    overlayOpacity: widget.overlayOpacity,
                    animateColdLoad: widget.animateColdLoad,
                    child: map,
                  );
                },
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

  group('N8.5 Map trips, lock pill, house clearance, and MapArrivalScope', () {
    mapTest(
      '1. Open place tap (3 -> 2 in 4 hops): dest pill enters in press, here fades in quick, 90 ms delay, smooth camera travel, 250 ms settle, here rises, card swaps; second tap opens PlaceScreen',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixtureDemoWith('place3');
        final clips = FakeClipPlayer();
        late MapPicture picture;
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) => picture = p,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);
        expect(picture.FROG.at, 2);
        expect(find.text('UP NEXT · LA COCINA'), findsOneWidget);

        // Tap stop 1 (El parque) directly on screen without pre-scrolling so camera travels from stop 2 -> stop 1.
        final scrollH = tester.state<ScrollableState>(
          find.byType(Scrollable).at(1),
        );
        final startScrollX = scrollH.position.pixels;
        expect(startScrollX, greaterThan(0.0));
        await _tapStopOnMap(tester, 1, scrollFirst: false);

        // At 45 ms: dest pill mid-enter (press = 90 ms), here pill mid-fade-out (quick = 140 ms),
        // frog still waiting on 90 ms tripStartDelay.
        await tester.pump(const Duration(milliseconds: 45));
        expect(find.byKey(const Key('map-dest-pill')), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);
        final destOp45 = _slotOpacity(tester, const Key('map-dest-motion'));
        final destScale45 = _slotScale(tester, const Key('map-dest-motion'));
        expect(destOp45, greaterThan(0.0));
        expect(destOp45, lessThan(1.0));
        expect(destScale45, greaterThan(MapMotion.destEnterScale));
        expect(destScale45, lessThan(1.0));
        final hereOp45 = _slotOpacity(tester, const Key('map-here-motion'));
        expect(hereOp45, greaterThan(0.0));
        expect(hereOp45, lessThan(1.0));
        expect(picture.FROG.path, isNull);

        // Past 90 ms delay (135 ms total): dest pill settled, frog hopping 4 hops.
        await _runFrames(tester, 90, step: 45);
        expect(_slotOpacity(tester, const Key('map-dest-motion')), 1.0);
        expect(
          _slotScale(tester, const Key('map-dest-motion')),
          closeTo(1.0, 1e-3),
        );
        expect(picture.FROG.path, isNotNull);

        // Mid-travel (~400 ms into 800 ms travel): horizontal scroll is strictly between start and 0.
        await _runFrames(tester, 400);
        final midTravelX = scrollH.position.pixels;
        expect(midTravelX, lessThan(startScrollX));
        expect(midTravelX, greaterThan(0.0));
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        // Land at ~890 ms (total ~935 ms): frog has landed (4 tones), in 250 ms settle pause.
        await _runFrames(tester, 450);
        expect(picture.FROG.path, isNull);
        expect(picture.FROG.at, 1);
        expect(clips.tones, hasLength(4));
        expect(nav.routes, isEmpty);

        // After 250 ms settle + 70 ms: dest pill mid-exit (quick), card swapped to El parque,
        // "You are here" waiting on hereRiseAfter (120 ms).
        await _runFrames(tester, 300, step: 50);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('PLACE 2 OF 10'), findsOneWidget);
        expect(find.text('El parque'), findsAtLeastNWidgets(1));
        expect(nav.routes, isEmpty);

        // Complete here rise and dest pill exit.
        await _runFrames(tester, 500);
        expect(find.byKey(const Key('map-dest-pill')), findsNothing);
        expect(_slotOpacity(tester, const Key('map-here-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-here-motion')), 0.0);
        expect(nav.routes, isEmpty);

        // Tapping stop 1 again opens PlaceScreen for El parque.
        await _tapStopOnMap(tester, 1);
        await _runFrames(tester, 550);
        expect(nav.routes, [const PlaceRoute('parque')]);
        expect(find.byKey(const Key('place-screen')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '2. Tap current place: first tap focuses its card without opening PlaceScreen; second tap opens PlaceScreen',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        final clips = FakeClipPlayer();
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);
        expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        // First tap on current stop (0): switches card to focused place, does not open PlaceScreen.
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 350);
        expect(clips.tones, isEmpty);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('PLACE 1 OF 10'), findsOneWidget);
        expect(find.text('La casa'), findsOneWidget);

        // Second tap on current stop (0): opens PlaceScreen.
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 550);
        expect(nav.routes, [const PlaceRoute('casa')]);
        expect(find.byKey(const Key('place-screen')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '3. Far place (> 6 legs, 0 -> 9 with todo): 0 hop tones, frog fades out in quick, camera travels in pageIn, frog fades in in quick, card updates',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio', todo: true);
        final clips = FakeClipPlayer();
        late MapPicture picture;
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) => picture = p,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);
        expect(picture.FROG.at, 0);

        await _tapStopOnMap(tester, 9);

        // Past 90 ms start delay -> fade-out starts on next frame, then 70 ms into quick (140 ms): frog fading out.
        await tester.pump(const Duration(milliseconds: 95));
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 70));
        expect(picture.FROG.path, isNull);
        expect(picture.FROG.hideArrow, isTrue);
        expect(picture.FROG.opacity, greaterThan(0.0));
        expect(picture.FROG.opacity, lessThan(1.0));
        expect(clips.tones, isEmpty);

        // Finish fade out (+90 ms) and enter pageIn (320 ms) camera travel: frog placed at 9 at opacity 0.
        await tester.pump(const Duration(milliseconds: 90));
        expect(picture.FROG.at, 9);
        expect(picture.FROG.opacity, 0.0);
        expect(picture.FROG.hideArrow, isTrue);

        // Complete pageIn (320 ms) camera travel, start quick fade-in, sample at 70 ms.
        await tester.pump(Duration.zero);
        await _runFrames(tester, 340, step: 40);
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 70));
        expect(picture.FROG.opacity, greaterThan(0.0));
        expect(picture.FROG.opacity, lessThan(1.0));

        // Finish fade-in, settle (250 ms), and card swap.
        await _runFrames(tester, 800);
        expect(picture.FROG.at, 9);
        expect(picture.FROG.opacity, 1.0);
        expect(picture.FROG.hideArrow, isFalse);
        expect(clips.tones, isEmpty);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('PLACE 10 OF 10'), findsOneWidget);
        expect(find.text('El fuerte'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '4. Closed place tap (k = 3, El colmado): lock pill ("After La cocina") enters in press, holds lockHold (1400 ms), exits in move; frog stays put',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        final clips = FakeClipPlayer();
        late MapPicture picture;
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) => picture = p,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 3);

        // At 45 ms (mid press = 90 ms): rising 4 -> 0 and fading 0 -> 1.
        await tester.pump(const Duration(milliseconds: 45));
        expect(find.byKey(const Key('map-lock-pill')), findsOneWidget);
        expect(
          find.text('After La cocina', findRichText: true),
          findsOneWidget,
        );
        final enterOp = _slotOpacity(tester, const Key('map-lock-motion'));
        final enterDy = _slotDy(tester, const Key('map-lock-motion'));
        expect(enterOp, greaterThan(0.0));
        expect(enterOp, lessThan(1.0));
        expect(enterDy, greaterThan(0.0));
        expect(enterDy, lessThan(MapMotion.lockDropOffset));

        // During lockHold (90..1490 ms): opacity 1.0, dy 0.0.
        await tester.pump(const Duration(milliseconds: 155)); // 200 ms
        expect(_slotOpacity(tester, const Key('map-lock-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-lock-motion')), 0.0);

        await tester.pump(const Duration(milliseconds: 1200)); // 1400 ms
        expect(_slotOpacity(tester, const Key('map-lock-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-lock-motion')), 0.0);

        // Mid exit over move (1490..1710 ms): fading out and dropping 0 -> 4.
        await tester.pump(const Duration(milliseconds: 180)); // 1580 ms
        final exitOp = _slotOpacity(tester, const Key('map-lock-motion'));
        final exitDy = _slotDy(tester, const Key('map-lock-motion'));
        expect(exitOp, greaterThan(0.0));
        expect(exitOp, lessThan(1.0));
        expect(exitDy, greaterThan(0.0));
        expect(exitDy, lessThan(MapMotion.lockDropOffset));

        // Finished exit: lock pill unmounted, frog never moved, card unchanged.
        await tester.pump(const Duration(milliseconds: 200)); // 1780 ms
        expect(find.byKey(const Key('map-lock-pill')), findsNothing);
        expect(picture.FROG.at, 0);
        expect(clips.tones, isEmpty);
        expect(nav.routes, isEmpty);
        expect(find.text('UP NEXT · LA CASA'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '5. Pill house clearance: "You are here" on place 1 and lock pill on place 4 sit strictly above house pixels',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio', reduceMotion: true);
        late MapPicture picture;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            onPicture: (p) => picture = p,
          ),
        );
        await _pumpMapReady(tester);

        final pixRect = tester.getRect(find.byType(PixelView));
        final scale = pixRect.height / mapH;

        // Place 1 (casa, index 0): house sits directly above stop 0.
        final casaHouseTopPic = picture.houseTopOnPicture(0);
        expect(casaHouseTopPic, isNotNull);
        final casaHouseTopScreenY = pixRect.top + casaHouseTopPic! * scale;
        final hereRect = tester.getRect(find.byKey(const Key('you-are-here')));
        expect(hereRect.bottom, lessThanOrEqualTo(casaHouseTopScreenY - 7.0));

        // Place 4 (colmado, index 3): tap locked stop and verify lock pill clears its house.
        await _tapStopOnMap(tester, 3);
        await tester.pump(const Duration(milliseconds: 200));
        final colmadoHouseTopPic = picture.houseTopOnPicture(3);
        expect(colmadoHouseTopPic, isNotNull);
        final pixRectAfter = tester.getRect(find.byType(PixelView));
        final colmadoHouseTopScreenY =
            pixRectAfter.top + colmadoHouseTopPic! * scale;
        final lockRect = tester.getRect(find.byKey(const Key('map-lock-pill')));
        expect(
          lockRect.bottom,
          lessThanOrEqualTo(colmadoHouseTopScreenY - 7.0),
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '6. Reduced motion (disableAnimations: true): open tap places coqui immediately, jumps camera, swaps card via quick fade (dy == 0) without auto-opening',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        final clips = FakeClipPlayer();
        late MapPicture picture;
        late _FlowNavigator nav;
        final cameras = <MapCamera>[];

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            disableAnimations: true,
            onPicture: (p) => picture = p,
            onCamera: cameras.add,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);
        final camsBefore = cameras.length;

        await _tapStopOnMap(tester, 2);
        // Immediate frog placement, immediate camera jump, no dest pill, no hop tones, no auto-open.
        expect(picture.FROG.at, 2);
        expect(picture.FROG.path, isNull);
        expect(cameras.length, greaterThan(camsBefore));
        expect(clips.tones, isEmpty);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-dest-pill')), findsNothing);

        // Card swaps in quick (140 ms) with dy == 0.
        await tester.pump(const Duration(milliseconds: 70));
        final cardOp = _slotOpacity(tester, const Key('map-card-motion'));
        expect(cardOp, greaterThan(0.0));
        expect(cardOp, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-card-motion')), 0.0);

        await tester.pump(const Duration(milliseconds: 100));
        expect(_slotOpacity(tester, const Key('map-card-motion')), 1.0);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('La cocina'), findsOneWidget);
        expect(nav.routes, isEmpty);

        // Closed place lock pill also uses quick fade with dy == 0.
        await _tapStopOnMap(tester, 3);
        await tester.pump(const Duration(milliseconds: 70));
        final lockOp = _slotOpacity(tester, const Key('map-lock-motion'));
        expect(lockOp, greaterThan(0.0));
        expect(lockOp, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-lock-motion')), 0.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '7. Arabic RTL fake course (FakeCourseCatalog.arabic()): open place and closed place taps keep LTR map and RTL overlays with zero exceptions',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        final arabicCourse = FakeCourseCatalog.arabic(
          fetch: (path) async {
            final raw = await arabicSampleFile(path);
            if (path != 'datos/curso.json') return raw;
            final doc = jsonDecode(raw) as Map<String, dynamic>;
            final lugares = (doc['lugares'] as List<dynamic>).toList();
            lugares.add({
              'id': 'parque',
              'n': 2,
              'nombre': 'الحديقة',
              'en': 'The park',
              'cuentos': ['la-lluvia'],
              'escenas': ['الأمام'],
            });
            lugares.add({
              'id': 'cocina',
              'n': 3,
              'nombre': 'المطبخ',
              'en': 'The kitchen',
              'cuentos': <String>[],
              'escenas': <String>[],
            });
            doc['lugares'] = lugares;
            return jsonEncode(doc);
          },
        );
        late MapPicture picture;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: arabicCourse,
            progress: progress,
            clock: clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            textDirection: TextDirection.rtl,
            onPicture: (p) => picture = p,
          ),
        );
        await _pumpMapReady(tester);
        expect(
          Directionality.of(tester.element(_mapPixelViewFinder())),
          TextDirection.ltr,
        );

        // Tap open place 2 (index 1, الحديقة).
        await _tapStopOnMap(tester, 1);
        await _runFrames(tester, 50);
        expect(find.byKey(const Key('map-dest-pill')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _runFrames(tester, 2200);
        expect(picture.FROG.at, 1);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('الحديقة'), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.text('PLACE 2 OF 3'))),
          TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);

        // Tap closed place 3 (index 2, المطبخ).
        await _tapStopOnMap(tester, 2);
        await _runFrames(tester, 150);
        expect(find.byKey(const Key('map-lock-pill')), findsOneWidget);
        expect(find.text('After الحديقة', findRichText: true), findsOneWidget);
        expect(picture.FROG.at, 1);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '8. MapArrivalScope: overlayOpacity fades overlays while PixelView stays unfaded; animateColdLoad staggers chips/here/card/play disc',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio', reduceMotion: true);

        // (a) overlayOpacity = 0.35 fades overlays but NEVER PixelView.
        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            useArrivalScope: true,
            overlayOpacity: 0.35,
          ),
        );
        await _pumpMapReady(tester);

        expect(
          _slotOpacity(tester, const Key('map-load-chips')),
          closeTo(0.35, 1e-6),
        );
        expect(
          _slotOpacity(tester, const Key('map-here-motion')),
          closeTo(0.35, 1e-6),
        );
        expect(
          _slotOpacity(tester, const Key('map-load-card')),
          closeTo(0.35, 1e-6),
        );
        final pixelAncestors = tester
            .widgetList<Opacity>(
              find.ancestor(
                of: _mapPixelViewFinder(),
                matching: find.byType(Opacity),
              ),
            )
            .toList();
        for (final op in pixelAncestors) {
          expect(op.opacity, 1.0, reason: 'PixelView must stay unfaded');
        }

        // (b) animateColdLoad = true staggers chips (180), here (210), card (240), play (400).
        await tester.pumpWidget(const SizedBox.shrink());
        final fCold = fixture(seed: 'vacio');
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fCold.services.course,
            progress: fCold.progress,
            clock: fCold.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            useArrivalScope: true,
            animateColdLoad: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // At t = 150 ms (< 180 ms): all four slots still hidden.
        await _runFrames(tester, 150);
        expect(_slotOpacity(tester, const Key('map-load-chips')), 0.0);
        expect(_slotOpacity(tester, const Key('map-here-motion')), 0.0);
        expect(_slotOpacity(tester, const Key('map-load-card')), 0.0);
        expect(_slotOpacity(tester, const Key('map-load-play')), 0.0);

        // At t = 195 ms: chips rising; here, card, play still 0.
        await tester.pump(const Duration(milliseconds: 45));
        expect(
          _slotOpacity(tester, const Key('map-load-chips')),
          greaterThan(0.0),
        );
        expect(_slotDy(tester, const Key('map-load-chips')), greaterThan(0.0));
        expect(_slotOpacity(tester, const Key('map-here-motion')), 0.0);
        expect(_slotOpacity(tester, const Key('map-load-card')), 0.0);

        // At t = 225 ms: here rising; card still 0.
        await tester.pump(const Duration(milliseconds: 30));
        expect(
          _slotOpacity(tester, const Key('map-here-motion')),
          greaterThan(0.0),
        );
        expect(_slotOpacity(tester, const Key('map-load-card')), 0.0);

        // At t = 260 ms: card rising; play disc still 0.
        await tester.pump(const Duration(milliseconds: 35));
        expect(
          _slotOpacity(tester, const Key('map-load-card')),
          greaterThan(0.0),
        );
        expect(_slotOpacity(tester, const Key('map-load-play')), 0.0);

        // At t = 430 ms: play disc rising.
        await _runFrames(tester, 170, step: 45);
        final playOp = _slotOpacity(tester, const Key('map-load-play'));
        expect(playOp, greaterThan(0.0));
        expect(playOp, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-load-play')), greaterThan(0.0));

        // Settled at 700 ms: all four at opacity 1.0, dy 0.0.
        await _runFrames(tester, 300);
        for (final key in const [
          Key('map-load-chips'),
          Key('map-here-motion'),
          Key('map-load-card'),
          Key('map-load-play'),
        ]) {
          expect(_slotOpacity(tester, key), 1.0, reason: '$key settled');
          expect(_slotDy(tester, key), 0.0, reason: '$key dy settled');
        }

        // (c) animateColdLoad under reduced motion collapses to quick fade in place (dy == 0).
        await tester.pumpWidget(const SizedBox.shrink());
        final fReduced = fixture(seed: 'vacio');
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fReduced.services.course,
            progress: fReduced.progress,
            clock: fReduced.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            disableAnimations: true,
            useArrivalScope: true,
            animateColdLoad: true,
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        final cOp = _slotOpacity(tester, const Key('map-load-chips'));
        expect(cOp, greaterThan(0.0));
        expect(cOp, lessThan(1.0));
        expect(
          _slotOpacity(tester, const Key('map-here-motion')),
          closeTo(cOp, 1e-6),
        );
        expect(
          _slotOpacity(tester, const Key('map-load-card')),
          closeTo(cOp, 1e-6),
        );
        expect(_slotDy(tester, const Key('map-load-chips')), 0.0);
        expect(_slotDy(tester, const Key('map-here-motion')), 0.0);
        expect(_slotDy(tester, const Key('map-load-card')), 0.0);

        await tester.pump(const Duration(milliseconds: 100));
        expect(_slotOpacity(tester, const Key('map-load-chips')), 1.0);
        expect(_slotOpacity(tester, const Key('map-here-motion')), 1.0);
        expect(_slotOpacity(tester, const Key('map-load-card')), 1.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '9. Multi-leg capped trip (0 -> 3: 4 legs, 6 hops): camera travels for full 6 * hop (1200 ms), still moving past 4 * hop (800 ms)',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'todo', todo: true);
        final clips = FakeClipPlayer();
        late MapPicture picture;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) => picture = p,
          ),
        );
        await _pumpMapReady(tester);
        expect(picture.FROG.at, 0);
        // Verify 0 -> 3 has 4 legs but 6 total hops ([1, 2, 1, 2]).
        expect(picture.planHops(0, 3), hasLength(6));

        final scrollV = tester.state<ScrollableState>(
          find.byType(Scrollable).at(0),
        );
        final startScrollY = scrollV.position.pixels;

        // Tap stop 3 directly without pre-scrolling so camera starts at stop 0.
        await _tapStopOnMap(tester, 3, scrollFirst: false);

        // Advance past 90 ms tripStartDelay + 800 ms (4 * hop = leg count) = 900 ms.
        // Because camera duration is 6 * hop (1200 ms), camera must still be mid-travel
        // and not yet at stop 3's final scrollY.
        await _runFrames(tester, 900, step: 50);
        final scrollAt900 = scrollV.position.pixels;
        expect(scrollAt900, lessThan(startScrollY));
        expect(picture.FROG.path, isNotNull);

        // Advance another 450 ms (total 1350 ms > 90 + 1200 ms): camera finishes moving
        // further north and frog lands after 6 hops.
        await _runFrames(tester, 450, step: 50);
        final finalScrollY = scrollV.position.pixels;
        expect(finalScrollY, lessThan(scrollAt900));
        expect(picture.FROG.path, isNull);
        expect(picture.FROG.at, 3);
        expect(clips.tones, hasLength(6));

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}
