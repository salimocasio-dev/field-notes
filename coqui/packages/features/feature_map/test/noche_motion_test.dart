@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart' show FontLoader;
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
    this.overlayOpacity,
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
  final ValueNotifier<double>? overlayOpacity;
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
                builder: (_) => MapScreen(
                  services: _services,
                  reviewTitle: MapWording.reviewTitle,
                  entitlements: widget.entitlements,
                  overlayOpacity: widget.overlayOpacity,
                  animateColdLoad: widget.animateColdLoad,
                  onPicture: widget.onPicture,
                  onCamera: widget.onCamera,
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
      '8. MapModule arrival hooks: overlayOpacity fades overlays while PixelView stays unfaded; animateColdLoad staggers chips/here/card/play disc',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio', reduceMotion: true);
        final opacity = ValueNotifier<double>(0.35);
        addTearDown(opacity.dispose);

        // (a) MapModule forwards overlayOpacity and animateColdLoad to MapScreen.
        final module = MapModule(
          entitlements: const AllowAllEntitlements(),
          overlayOpacity: opacity,
          animateColdLoad: true,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Scaffold(
              body: Builder(builder: module.tab(f.services)!.builder),
            ),
          ),
        );
        final mapWidget = tester.widget<MapScreen>(find.byType(MapScreen));
        expect(mapWidget.overlayOpacity, same(opacity));
        expect(mapWidget.animateColdLoad, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());

        // (b) overlayOpacity = 0.35 fades overlays (including dynamic updates & clamping) but NEVER PixelView.
        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            overlayOpacity: opacity,
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

        // Dynamic out-of-range value is clamped safely to [0.0, 1.0].
        opacity.value = 1.5;
        await tester.pump();
        expect(_slotOpacity(tester, const Key('map-load-chips')), 1.0);
        opacity.value = -0.2;
        await tester.pump();
        expect(_slotOpacity(tester, const Key('map-load-chips')), 0.0);

        // (c) animateColdLoad = true staggers chips (180), here (210), card (240), play (400).
        await tester.pumpWidget(const SizedBox.shrink());
        final fCold = fixture(seed: 'vacio');
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fCold.services.course,
            progress: fCold.progress,
            clock: fCold.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
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

        // (d) animateColdLoad under reduced motion collapses to quick fade in place (dy == 0).
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

    mapTest(
      '10. Plan-locked stop on Plan.free preserves N3.4: tapping place 2 hops and focuses place card; opening it opens PlaceRoute(parque) with plan card',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);
        final f = fixture(seed: 'vacio');
        late MapPicture picture;
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: entitlements,
            onPicture: (p) => picture = p,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);
        expect(picture.FROG.at, 0);

        await _tapStopOnMap(tester, 1);
        // 90 ms delay + 1200 ms (6 hops) + 250 ms settle + 360 ms card swap
        await _runFrames(tester, 2200, step: 50);
        expect(picture.FROG.at, 1);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('PLACE 2 OF 10'), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);

        await tester.tap(find.byKey(const Key('place-card-open')));
        await tester.pump();
        await _runFrames(tester, 550);
        expect(nav.routes.whereType<StoryRoute>(), isEmpty);
        expect(nav.routes, [const PlaceRoute('parque')]);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-see-plans')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('N8.6 Map: the place card', () {
    mapTest(
      '1. Card swap to place card: height grows ~60 px (start/middle/end in move), incoming rises at 60 ms, play disc lands last at 140..360 ms',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
          ),
        );
        await _pumpMapReady(tester);

        final upNextHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(upNextHeight, greaterThanOrEqualTo(150));
        expect(upNextHeight, lessThanOrEqualTo(185));
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        // Tap current stop (0) to focus La casa place card.
        await _tapStopOnMap(tester, 0);
        final startHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(startHeight, closeTo(upNextHeight, 0.5));
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.byKey(const Key('place-card-handle')), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const Key('place-card-handle'))),
          const Size(40, 4),
        );

        // At 45 ms: incoming content still waiting on followAfter (60 ms); play disc waiting on 140 ms.
        await tester.pump(const Duration(milliseconds: 45));
        expect(_slotOpacity(tester, const Key('map-card-motion')), 0.0);
        expect(_slotOpacity(tester, const Key('map-load-play')), 0.0);

        // At NocheMotion.move ~/ 2 (110 ms): card height mid-expansion, incoming rising, play disc still 0.
        await tester.pump(const Duration(milliseconds: 65));
        final midHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(midHeight, greaterThan(startHeight));
        expect(midHeight, lessThan(215));
        final inOp110 = _slotOpacity(tester, const Key('map-card-motion'));
        final inDy110 = _slotDy(tester, const Key('map-card-motion'));
        expect(inOp110, greaterThan(0.0));
        expect(inOp110, lessThan(1.0));
        expect(inDy110, greaterThan(0.0));
        expect(inDy110, lessThan(NocheMotion.row));
        expect(_slotOpacity(tester, const Key('map-load-play')), 0.0);

        // At NocheMotion.move (220 ms): height animation finished (~214 px place card); play disc rising (140..360 ms).
        await tester.pump(const Duration(milliseconds: 110));
        final endHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(endHeight, closeTo(214, 4));
        expect(endHeight, greaterThan(startHeight));
        expect(
          _slotOpacity(tester, const Key('map-load-play')),
          greaterThan(0.0),
        );

        // At 300 ms: card content has already landed (1.0 / 0.0), while play disc is still landing last!
        await tester.pump(const Duration(milliseconds: 80));
        expect(_slotOpacity(tester, const Key('map-card-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-card-motion')), 0.0);
        final playOp300 = _slotOpacity(tester, const Key('map-load-play'));
        final playDy300 = _slotDy(tester, const Key('map-load-play'));
        expect(playOp300, greaterThan(0.0));
        expect(playOp300, lessThan(1.0));
        expect(playDy300, greaterThan(0.0));
        expect(playDy300, lessThan(NocheMotion.row));

        // Settled at 380 ms.
        await tester.pump(const Duration(milliseconds: 80));
        expect(_slotOpacity(tester, const Key('map-load-play')), 1.0);
        expect(_slotDy(tester, const Key('map-load-play')), 0.0);
        expect(find.text('PLACE 1 OF 10'), findsOneWidget);
        expect(find.text('La casa'), findsOneWidget);
        expect(find.text('0 of 11 stories heard'), findsOneWidget);
        expect(find.text('PLAY NEXT · STORY 1'), findsOneWidget);
        expect(find.text('La lluvia'), findsOneWidget);
        expect(find.text('2 min'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '2. Small drag of 20 up and 20 down follows finger, returns in NocheMotion.move (middle & end), and clamp caps at -80 / +48',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 400);

        // Drag 20 up: follows finger, then returns over NocheMotion.move without opening.
        final dragUp = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('up-next-card'))),
        );
        await dragUp.moveBy(const Offset(0, -20));
        await tester.pump();
        expect(
          _slotDy(tester, const Key('map-card-drag')),
          closeTo(-20.0, 0.5),
        );
        await dragUp.up();
        await tester.pump();

        await tester.pump(NocheMotion.move ~/ 2);
        final midUpDy = _slotDy(tester, const Key('map-card-drag'));
        expect(midUpDy, greaterThan(-20.0));
        expect(midUpDy, lessThan(0.0));

        await tester.pump(
          NocheMotion.move ~/ 2 + const Duration(milliseconds: 20),
        );
        expect(_slotDy(tester, const Key('map-card-drag')), 0.0);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        // Drag 20 down: follows finger, then returns over NocheMotion.move without collapsing.
        final dragDown = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('up-next-card'))),
        );
        await dragDown.moveBy(const Offset(0, 20));
        await tester.pump();
        expect(_slotDy(tester, const Key('map-card-drag')), closeTo(20.0, 0.5));
        await dragDown.up();
        await tester.pump();

        await tester.pump(NocheMotion.move ~/ 2);
        final midDownDy = _slotDy(tester, const Key('map-card-drag'));
        expect(midDownDy, greaterThan(0.0));
        expect(midDownDy, lessThan(20.0));

        await tester.pump(
          NocheMotion.move ~/ 2 + const Duration(milliseconds: 20),
        );
        expect(_slotDy(tester, const Key('map-card-drag')), 0.0);
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        // Drag -120 clamps at -80 (MapMotion.cardDragUpLimit); +80 clamps at +48.
        final dragClampUp = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('up-next-card'))),
        );
        await dragClampUp.moveBy(const Offset(0, -120));
        await tester.pump();
        expect(
          _slotDy(tester, const Key('map-card-drag')),
          closeTo(MapMotion.cardDragUpLimit, 0.5),
        );
        await dragClampUp.moveBy(const Offset(0, 200));
        await tester.pump();
        expect(
          _slotDy(tester, const Key('map-card-drag')),
          closeTo(MapMotion.cardDragDownLimit, 0.5),
        );
        await dragClampUp.cancel();
        await tester.pump();

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '3. Drag of 40 up opens PlaceRoute with NocheWindow flying from dragged rect; back keeps place card at dy == 0',
      (tester) async {
        const dpr = 3.0;
        _phone(tester, size: const Size(390, 844), dpr: dpr);
        final f = fixture(
          seed: 'vacio',
          customPairs: _casaPairs,
          storyScenes: _casaScenes,
        );
        late _FlowNavigator nav;
        final expectedGeom = computeScenePictureGeometry(
          viewportWidth: 390,
          heroHeight: placeHeroBaseHeight,
          dpr: dpr,
        );

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 400);

        final restWinRect = tester.getRect(
          find.byKey(const Key('up-next-window')),
        );
        final drag = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('up-next-card'))),
        );
        await drag.moveBy(const Offset(0, -40));
        await tester.pump();
        final draggedWinRect = tester.getRect(
          find.byKey(const Key('up-next-window')),
        );
        expect(draggedWinRect.top, closeTo(restWinRect.top - 40, 0.5));

        await drag.up();
        await tester.pump();

        // At 1 ms into pageIn: Hero shuttle starts from the dragged window rect (40 px higher).
        await tester.pump(const Duration(milliseconds: 1));
        final shuttleRect = tester.getRect(
          find.byKey(NocheWindow.surfaceKey('la-lluvia')),
        );
        expect(shuttleRect.top, closeTo(restWinRect.top - 40, 20));
        expect(shuttleRect.top, lessThan(restWinRect.top - 20));
        expect(
          _pixelScaleInWindow(tester, tag: 'la-lluvia', dpr: dpr),
          expectedGeom.scale,
        );

        await tester.pump(const Duration(milliseconds: 520));
        expect(nav.routes, [const PlaceRoute('casa')]);
        expect(find.byKey(const Key('place-screen')), findsOneWidget);

        // Pop back: place card remains focused and rests at dy == 0.
        await tester.tap(find.byKey(const Key('place-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));
        expect(find.byKey(const Key('place-screen')), findsNothing);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(_slotDy(tester, const Key('map-card-drag')), 0.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '4. Drag of 40 down collapses place card back to Up next and shrinks height over NocheMotion.move',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        final upNextHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 400);
        final placeHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(placeHeight, greaterThan(upNextHeight));

        await tester.drag(
          find.byKey(const Key('up-next-card')),
          const Offset(0, 40),
        );
        await tester.pump();
        expect(nav.routes, isEmpty);
        expect(find.byKey(const Key('map-place-card')), findsNothing);
        expect(find.text('UP NEXT · LA CASA'), findsOneWidget);

        await tester.pump(NocheMotion.move ~/ 2);
        final midHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(midHeight, lessThan(placeHeight));
        expect(midHeight, greaterThan(upNextHeight));

        await tester.pump(NocheMotion.move);
        final endHeight = tester
            .getSize(find.byKey(const Key('up-next-card')))
            .height;
        expect(endHeight, closeTo(upNextHeight, 0.5));
        expect(_slotDy(tester, const Key('map-card-drag')), 0.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '5. Card tap and 48x48 arrow button (place-card-open, semantic "Open <place>") both open PlaceRoute',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 400);

        final openBtn = find.byKey(const Key('place-card-open'));
        expect(openBtn, findsOneWidget);
        final btnSize = tester.getSize(openBtn);
        expect(btnSize.width, greaterThanOrEqualTo(48));
        expect(btnSize.height, greaterThanOrEqualTo(48));
        expect(
          find.bySemanticsLabel(MapWording.openPlaceSemantic('La casa')),
          findsOneWidget,
        );

        await tester.tap(openBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 520));
        expect(nav.routes, [const PlaceRoute('casa')]);

        await tester.tap(find.byKey(const Key('place-back')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 240));
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        // Tapping the card itself also opens PlaceRoute.
        await tester.tap(find.byKey(const Key('up-next-card')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 520));
        expect(nav.routes, [
          const PlaceRoute('casa'),
          const TabRoute(NocheTabs.map),
          const PlaceRoute('casa'),
        ]);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '6. Finished place (all stories heard): shows ALL STORIES HEARD, Call Danny (or Review with no calls), mic/play icon, and routes play disc to CallRoute/ReviewRoute',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);

        // (a) Place with a call: Call Danny + mic icon + 4 min -> CallRoute('casa').
        final fCall = fixture(seed: 'vacio', callPlaces: const {'casa'});
        for (final id in fCall.services.course.places[0].stories) {
          finishStory(fCall.progress, id);
        }
        late _FlowNavigator navCall;
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fCall.services.course,
            progress: fCall.progress,
            clock: fCall.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            onNavReady: (n, _) => navCall = n,
          ),
        );
        await _pumpMapReady(tester);
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 200);

        expect(find.text('ALL STORIES HEARD'), findsOneWidget);
        expect(find.text('Call Danny'), findsOneWidget);
        expect(find.text('4 min'), findsOneWidget);
        final micDisc = tester.widget<NochePlayDisc>(
          find.byKey(const Key('up-next-play')),
        );
        expect(micDisc.icon, NocheIcons.mic);
        expect(find.bySemanticsLabel('Call Danny'), findsOneWidget);

        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        expect(navCall.routes, [const CallRoute('casa')]);

        // (b) Place with no calls: Review + play icon -> ReviewRoute().
        await tester.pumpWidget(const SizedBox.shrink());
        final fReview = fixture(seed: 'vacio', callPlaces: const {});
        for (final id in fReview.services.course.places[0].stories) {
          finishStory(fReview.progress, id);
        }
        late _FlowNavigator navReview;
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fReview.services.course,
            progress: fReview.progress,
            clock: fReview.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            onNavReady: (n, _) => navReview = n,
          ),
        );
        await _pumpMapReady(tester);
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 200);

        expect(find.text('ALL STORIES HEARD'), findsOneWidget);
        expect(find.text('Review'), findsOneWidget);
        final reviewDisc = tester.widget<NochePlayDisc>(
          find.byKey(const Key('up-next-play')),
        );
        expect(reviewDisc.icon, NocheIcons.play);
        expect(
          find.bySemanticsLabel(MapWording.startReviewSemantic),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        expect(navReview.routes, [const ReviewRoute()]);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '7. Screen reader actions "Open" and "Show what is next" via CustomSemanticsActions',
      (tester) async {
        final semantics = tester.ensureSemantics();
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio', reduceMotion: true);
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            reduceMotion: true,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 200);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        final openId = CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: MapWording.cardActionOpen),
        );
        final showUpNextId = CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: MapWording.cardActionShowUpNext),
        );

        final cardNode = tester.getSemantics(
          find.byKey(const Key('up-next-card')),
        );
        expect(
          cardNode.getSemanticsData().customSemanticsActionIds,
          containsAll([openId, showUpNextId]),
        );

        // Trigger "Show what is next" -> returns to Up next card.
        cardNode.owner!.performAction(
          cardNode.id,
          SemanticsAction.customAction,
          showUpNextId,
        );
        await tester.pump();
        await _runFrames(tester, 200);
        expect(find.byKey(const Key('map-place-card')), findsNothing);
        expect(find.text('UP NEXT · LA CASA'), findsOneWidget);

        // Focus again and trigger "Open" -> opens PlaceRoute('casa').
        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 200);
        final cardNode2 = tester.getSemantics(
          find.byKey(const Key('up-next-card')),
        );
        cardNode2.owner!.performAction(
          cardNode2.id,
          SemanticsAction.customAction,
          openId,
        );
        await tester.pump();
        expect(nav.routes, [const PlaceRoute('casa')]);

        semantics.dispose();
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '8. Reduced motion (disableAnimations: true) and Arabic RTL (FakeCourseCatalog.arabic())',
      (tester) async {
        // (a) Reduced motion: snaps height, quick fade (dy == 0), instant drag snap-back.
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            disableAnimations: true,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await tester.pump(const Duration(milliseconds: 70));
        final opMid = _slotOpacity(tester, const Key('map-card-motion'));
        expect(opMid, greaterThan(0.0));
        expect(opMid, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-card-motion')), 0.0);
        await tester.pump(const Duration(milliseconds: 100));
        expect(_slotOpacity(tester, const Key('map-card-motion')), 1.0);

        final smallDrag = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('up-next-card'))),
        );
        await smallDrag.moveBy(const Offset(0, -20));
        await tester.pump();
        await smallDrag.up();
        await tester.pump();
        expect(_slotDy(tester, const Key('map-card-drag')), 0.0);

        await tester.drag(
          find.byKey(const Key('up-next-card')),
          const Offset(0, 40),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 70));
        expect(_slotDy(tester, const Key('map-card-motion')), 0.0);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        // (b) Arabic RTL: mirrored arrow-up and play disc at end (left), picture at start (right), LTR numbers.
        await tester.pumpWidget(const SizedBox.shrink());
        final clockAr = FakeClock(fixtureNowMs);
        final progressAr = FakeProgressStore(clock: clockAr);
        final arabicCourse = FakeCourseCatalog.arabic();
        await tester.pumpWidget(
          _MapMotionHarness(
            course: arabicCourse,
            progress: progressAr,
            clock: clockAr,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            textDirection: TextDirection.rtl,
          ),
        );
        await _pumpMapReady(tester);

        await _tapStopOnMap(tester, 0);
        await _runFrames(tester, 400);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        final winRect = tester.getRect(find.byKey(const Key('up-next-window')));
        final openRect = tester.getRect(
          find.byKey(const Key('place-card-open')),
        );
        final playRect = tester.getRect(find.byKey(const Key('up-next-play')));
        expect(openRect.center.dx, lessThan(winRect.center.dx));
        expect(playRect.center.dx, lessThan(winRect.center.dx));
        expect(
          Directionality.of(tester.element(find.textContaining('PLACE 1 OF'))),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(
            tester.element(find.textContaining('stories heard')),
          ),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(find.text('PLAY NEXT · STORY 1'))),
          TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '9. Plan.free gating on place 2 (El parque): swipe up, tap, arrow button, and play disc (unheard & all-heard) ALL open PlaceRoute(parque) and never StoryRoute/CallRoute',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);

        // (a) Place 2 with unheard stories.
        final f = fixture(seed: 'curso', reduceMotion: true);
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

        // Tap stop 1 (El parque) -> focuses place card.
        await _tapStopOnMap(tester, 1);
        await _runFrames(tester, 200);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);
        expect(nav.routes, isEmpty);

        Future<void> verifyGatedOpen(Future<void> Function() action) async {
          final before = nav.routes.length;
          await action();
          await tester.pump();
          await _runFrames(tester, 200);
          expect(nav.routes.length, before + 1);
          expect(nav.routes.last, const PlaceRoute('parque'));
          expect(nav.routes.whereType<StoryRoute>(), isEmpty);
          expect(nav.routes.whereType<CallRoute>(), isEmpty);
          expect(nav.routes.whereType<ReviewRoute>(), isEmpty);
          expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
          expect(find.byKey(const Key('place-see-plans')), findsOneWidget);

          await tester.tap(find.byKey(const Key('place-back')));
          await tester.pump();
          await _runFrames(tester, 200);
          expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        }

        // 1) Swipe up 40.
        await verifyGatedOpen(
          () => tester.drag(
            find.byKey(const Key('up-next-card')),
            const Offset(0, -40),
          ),
        );
        // 2) Tap card.
        await verifyGatedOpen(
          () => tester.tap(find.byKey(const Key('up-next-card'))),
        );
        // 3) Tap arrow button.
        await verifyGatedOpen(
          () => tester.tap(find.byKey(const Key('place-card-open'))),
        );
        // 4) Tap play disc (unheard state).
        await verifyGatedOpen(
          () => tester.tap(find.byKey(const Key('up-next-play'))),
        );

        // (b) Place 2 with all stories heard on Plan.free: play disc still gates to PlaceRoute('parque').
        await tester.pumpWidget(const SizedBox.shrink());
        final fAllHeard = fixture(seed: 'vacio', reduceMotion: true);
        for (final id in fAllHeard.services.course.places[1].stories) {
          finishStory(fAllHeard.progress, id);
        }
        late _FlowNavigator navAllHeard;
        await tester.pumpWidget(
          _MapMotionHarness(
            course: fAllHeard.services.course,
            progress: fAllHeard.progress,
            clock: fAllHeard.clock,
            pictures: _pixelPictures(),
            entitlements: entitlements,
            reduceMotion: true,
            onNavReady: (n, _) => navAllHeard = n,
          ),
        );
        await _pumpMapReady(tester);
        await _tapStopOnMap(tester, 1);
        await _runFrames(tester, 200);
        expect(find.text('ALL STORIES HEARD'), findsOneWidget);

        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        await _runFrames(tester, 200);
        expect(navAllHeard.routes, [const PlaceRoute('parque')]);
        expect(navAllHeard.routes.whereType<StoryRoute>(), isEmpty);
        expect(navAllHeard.routes.whereType<CallRoute>(), isEmpty);
        expect(navAllHeard.routes.whereType<ReviewRoute>(), isEmpty);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-see-plans')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('N8.7 Map: a new place opens', () {
    mapTest(
      '1. 4-step choreography in order and exact start times: here fade at 0 ms, crossfade & rising New place pill at 100 ms, hops & camera travel at 600 ms, pill crossfade & new place card after 250 ms settle',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final clock = FakeClock(fixtureNowMs);
        final progress = FakeProgressStore(clock: clock);
        final clips = FakeClipPlayer();
        final course = MapFixtureCourse(
          builtPlaces: 4,
          customPairs: [..._casaPairs, _pair('mostrador', 'mostrador')],
          storyScenes: {
            ..._casaScenes,
            'uno-dos-tres': 'camino',
            'colmado-1': 'mostrador',
          },
        );
        late MapPicture picture;

        // Finish places 0 and 1 before opening the map so the learner sits at place 2 (La cocina)
        // and place 3 (El colmado) is next.
        for (final p in course.places.take(2)) {
          for (final id in p.stories) {
            clock.advance(const Duration(seconds: 5));
            finishStory(progress, id);
          }
        }
        final cocinaStories = course.places[2].stories;
        for (final id in cocinaStories.take(cocinaStories.length - 1)) {
          clock.advance(const Duration(seconds: 5));
          finishStory(progress, id);
        }

        await tester.pumpWidget(
          _MapMotionHarness(
            course: course,
            progress: progress,
            clock: clock,
            clips: clips,
            pictures: _pixelPictures(),
            entitlements: const AllowAllEntitlements(),
            onPicture: (p) => picture = p,
          ),
        );
        await _pumpMapReady(tester);
        expect(picture.FROG.at, 2);
        expect(picture.STATE.hecho[2], isFalse);
        expect(find.byKey(const Key('up-next-card')), findsOneWidget);
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        final hopCount = picture.planHops(2, 3).length;
        expect(hopCount, greaterThan(0));
        final scrollV = tester.state<ScrollableState>(
          find.byType(Scrollable).at(0),
        );
        final startScrollY = scrollV.position.pixels;

        // Finish the last story of La cocina -> triggers N8.7 Step 1 at t = 0 ms.
        finishStory(progress, cocinaStories.last);
        await tester.pump();

        // Step 1 (t = 50 ms): "You are here" fading out in quick, no crossfade or New place pill yet, frog still at 2.
        await tester.pump(const Duration(milliseconds: 50));
        final hereOp50 = _slotOpacity(tester, const Key('map-here-motion'));
        expect(hereOp50, greaterThan(0.0));
        expect(hereOp50, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-here-motion')), 0.0);
        expect(find.byKey(const Key('map-unlock-crossfade')), findsNothing);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(picture.FROG.at, 2);
        expect(picture.FROG.path, isNull);

        // Step 2 (t = 100 ms -> sample ~60 ms into Step 2): crossfade overlay visible, new state applied,
        // "New place El colmado" pill rising by row, frog still parked at 2.
        await tester.pump(const Duration(milliseconds: 55)); // past 100 ms
        await tester.pump(); // settle Step 2 start frame
        await tester.pump(
          const Duration(milliseconds: 60),
        ); // 60 ms into Step 2
        expect(find.byKey(const Key('map-unlock-crossfade')), findsOneWidget);
        final crossOp160 = _slotOpacity(
          tester,
          const Key('map-unlock-crossfade'),
        );
        expect(crossOp160, greaterThan(0.0));
        expect(crossOp160, lessThan(1.0));
        expect(picture.STATE.hecho[2], isTrue);
        expect(find.byKey(const Key('map-new-place-pill')), findsOneWidget);
        expect(find.text(MapWording.newPlace), findsOneWidget);
        expect(find.text('El colmado'), findsOneWidget);
        final destOp160 = _slotOpacity(tester, const Key('map-dest-motion'));
        final destDy160 = _slotDy(tester, const Key('map-dest-motion'));
        expect(destOp160, greaterThan(0.0));
        expect(destOp160, lessThan(1.0));
        expect(destDy160, greaterThan(0.0));
        expect(destDy160, lessThan(NocheMotion.row));
        expect(picture.FROG.at, 2);
        expect(picture.FROG.path, isNull);

        // At t = 330 ms: New place pill settled (op == 1, dy == 0), crossfade still running (480 ms settle), frog still at 2.
        await _runFrames(tester, 170, step: 45);
        expect(_slotOpacity(tester, const Key('map-dest-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-dest-motion')), 0.0);
        final crossOp330 = _slotOpacity(
          tester,
          const Key('map-unlock-crossfade'),
        );
        expect(crossOp330, greaterThan(0.0));
        expect(crossOp330, lessThan(crossOp160));
        expect(picture.FROG.at, 2);
        expect(picture.FROG.path, isNull);

        // Step 3 (t = 600 ms -> sample at t = 650 ms): crossfade gone, frog hopping, camera travelling.
        await _runFrames(tester, 270, step: 45); // t = 600 ms
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 50)); // t = 650 ms
        expect(find.byKey(const Key('map-unlock-crossfade')), findsNothing);
        expect(picture.FROG.path, isNotNull);
        await _runFrames(
          tester,
          150,
          step: 50,
        ); // t = 800 ms (200 ms into hops)
        expect(scrollV.position.pixels, isNot(closeTo(startScrollY, 1.0)));

        // Land and wait 250 ms settle -> Step 4 (sample 70 ms into 140 ms quick crossfade).
        final remainingHopMs = hopCount * NocheMotion.hop.inMilliseconds - 200;
        await _runFrames(tester, remainingHopMs + 60, step: 50);
        expect(picture.FROG.path, isNull);
        expect(picture.FROG.at, 3);
        expect(clips.tones, hasLength(hopCount));
        await _runFrames(tester, 250, step: 50);
        await tester.pump(Duration.zero);
        await tester.pump(const Duration(milliseconds: 70));

        final destExitOp = _slotOpacity(tester, const Key('map-dest-motion'));
        expect(destExitOp, greaterThan(0.0));
        expect(destExitOp, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-dest-motion')), 0.0);
        final hereEnterOp = _slotOpacity(tester, const Key('map-here-motion'));
        expect(hereEnterOp, greaterThan(0.0));
        expect(hereEnterOp, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-here-motion')), 0.0);

        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(
          find.text(MapWording.newPlaceCounter(4, 10).toUpperCase()),
          findsOneWidget,
        );
        expect(find.text('El colmado'), findsAtLeastNWidgets(1));
        expect(
          find.text(MapWording.playFirstStory(1).toUpperCase()),
          findsOneWidget,
        );

        // Finish pill crossfade and card swap, verify MapSceneWindow uses PixelView.
        await _runFrames(tester, 400, step: 50);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(_slotOpacity(tester, const Key('map-here-motion')), 1.0);
        expect(_slotDy(tester, const Key('map-here-motion')), 0.0);
        expect(
          find.descendant(
            of: find.byKey(const Key('up-next-window')),
            matching: find.byType(PixelView),
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '2. Offstage deferral & plays once: finishing last story while TickerMode(enabled: false) defers until visible, then plays once without replaying on further toggles',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(
          seed: 'vacio',
          customPairs: _casaPairs,
          storyScenes: {..._casaScenes, 'uno-dos-tres': 'camino'},
        );
        late MapPicture picture;
        final visible = ValueNotifier<bool>(true);
        addTearDown(visible.dispose);

        await tester.pumpWidget(
          ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
            child: _MapMotionHarness(
              course: f.services.course,
              progress: f.progress,
              clock: f.clock,
              pictures: _pixelPictures(),
              entitlements: const AllowAllEntitlements(),
              onPicture: (p) => picture = p,
            ),
          ),
        );
        await _pumpMapReady(tester);

        // Go offstage (as when Lesson/StoryRoute covers the map).
        visible.value = false;
        await tester.pump();

        final ids = f.services.course.places[0].stories;
        for (final id in ids) {
          finishStory(f.progress, id);
        }
        await tester.pump();
        await _runFrames(tester, 500, step: 50);

        // Deferred while offstage: frog and pre-unlock state unchanged.
        expect(picture.FROG.at, 0);
        expect(picture.STATE.hecho[0], isFalse);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(find.byKey(const Key('map-place-card')), findsNothing);

        // Return to the map -> post-frame callback starts unlock sequence, next frame settles t = 0.
        visible.value = true;
        await tester.pump();
        await tester.pump();

        await tester.pump(const Duration(milliseconds: 50));
        expect(
          _slotOpacity(tester, const Key('map-here-motion')),
          lessThan(1.0),
        );
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);

        await tester.pump(const Duration(milliseconds: 110));
        expect(find.byKey(const Key('map-unlock-crossfade')), findsOneWidget);
        expect(find.byKey(const Key('map-new-place-pill')), findsOneWidget);
        expect(find.text('El parque'), findsOneWidget);

        await _runFrames(tester, 2500, step: 50);
        expect(picture.FROG.at, 1);
        expect(picture.STATE.hecho[0], isTrue);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(
          find.text(MapWording.newPlaceCounter(2, 10).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(MapWording.playFirstStory(1).toUpperCase()),
          findsOneWidget,
        );

        // Toggling TickerMode off and back on must NOT replay the unlock sequence.
        visible.value = false;
        await tester.pump();
        visible.value = true;
        await tester.pump();
        await _runFrames(tester, 300, step: 50);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(find.byKey(const Key('map-unlock-crossfade')), findsNothing);
        expect(picture.FROG.at, 1);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '3. Leaving the map mid-sequence (TickerMode -> false at ~250 ms) finishes the unlock immediately',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
        late MapPicture picture;
        final visible = ValueNotifier<bool>(true);
        addTearDown(visible.dispose);

        await tester.pumpWidget(
          ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (_, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
            child: _MapMotionHarness(
              course: f.services.course,
              progress: f.progress,
              clock: f.clock,
              pictures: _pixelPictures(),
              entitlements: const AllowAllEntitlements(),
              onPicture: (p) => picture = p,
            ),
          ),
        );
        await _pumpMapReady(tester);

        final ids = f.services.course.places[0].stories;
        for (final id in ids.take(ids.length - 1)) {
          finishStory(f.progress, id);
        }
        await tester.pump();
        finishStory(f.progress, ids.last);
        await tester.pump();

        // Mid-Step 2 (~250 ms): crossfade active, New place pill visible, frog still at 0.
        await _runFrames(tester, 250, step: 50);
        expect(find.byKey(const Key('map-unlock-crossfade')), findsOneWidget);
        expect(find.byKey(const Key('map-new-place-pill')), findsOneWidget);
        expect(picture.FROG.at, 0);

        // Leave the map mid-sequence -> finishes at once.
        visible.value = false;
        await tester.pump();
        expect(picture.FROG.at, 1);
        expect(picture.FROG.path, isNull);
        expect(picture.STATE.hecho[0], isTrue);
        expect(picture.STATE.aqui, 1);
        expect(find.byKey(const Key('map-unlock-crossfade')), findsNothing);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(_slotOpacity(tester, const Key('map-here-motion')), 1.0);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(
          find.text(MapWording.newPlaceCounter(2, 10).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(MapWording.playFirstStory(1).toUpperCase()),
          findsOneWidget,
        );
        expect(_slotOpacity(tester, const Key('map-card-motion')), 1.0);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '4. Reduced motion (disableAnimations: true): immediately places frog, applies new map state with no crossfade or hop tones, and swaps card in quick fade (dy == 0)',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final f = fixture(seed: 'vacio');
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
            disableAnimations: true,
            onPicture: (p) => picture = p,
          ),
        );
        await _pumpMapReady(tester);

        final ids = f.services.course.places[0].stories;
        for (final id in ids) {
          finishStory(f.progress, id);
        }
        await tester.pump();

        expect(picture.FROG.at, 1);
        expect(picture.FROG.path, isNull);
        expect(picture.STATE.hecho[0], isTrue);
        expect(clips.tones, isEmpty);
        expect(find.byKey(const Key('map-unlock-crossfade')), findsNothing);
        expect(find.byKey(const Key('map-new-place-pill')), findsNothing);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 70));
        final opMid = _slotOpacity(tester, const Key('map-card-motion'));
        expect(opMid, greaterThan(0.0));
        expect(opMid, lessThan(1.0));
        expect(_slotDy(tester, const Key('map-card-motion')), 0.0);

        await tester.pump(const Duration(milliseconds: 100));
        expect(_slotOpacity(tester, const Key('map-card-motion')), 1.0);
        expect(
          find.text(MapWording.newPlaceCounter(2, 10).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(MapWording.playFirstStory(1).toUpperCase()),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '5. Arabic RTL (FakeCourseCatalog.arabic()): finishing place 1 runs the 4 steps cleanly in RTL with NocheLtr on NEW PLACE and PLAY FIRST labels',
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
              'cuentos': ['uno-dos-tres'],
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

        for (final id in arabicCourse.places[0].stories) {
          finishStory(progress, id);
        }
        await tester.pump();
        await _runFrames(tester, 200, step: 50);
        expect(find.byKey(const Key('map-new-place-pill')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _runFrames(tester, 2500, step: 50);
        expect(picture.FROG.at, 1);
        expect(find.byKey(const Key('map-place-card')), findsOneWidget);
        expect(find.text('الحديقة'), findsOneWidget);
        expect(
          Directionality.of(
            tester.element(
              find.text(MapWording.newPlaceCounter(2, 3).toUpperCase()),
            ),
          ),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(
            tester.element(
              find.text(MapWording.playFirstStory(1).toUpperCase()),
            ),
          ),
          TextDirection.ltr,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    mapTest(
      '6. Plan.free gating after finishing free place 1 (La casa -> El parque): all 4 steps play, and Play first disc opens PlaceRoute(parque) and never StoryRoute',
      (tester) async {
        _phone(tester, size: const Size(390, 844), dpr: 3.0);
        final entitlements = FakeEntitlements(plan: Plan.free);
        addTearDown(entitlements.dispose);
        final f = fixture(seed: 'vacio');
        late MapPicture picture;
        late _FlowNavigator nav;

        await tester.pumpWidget(
          _MapMotionHarness(
            course: f.services.course,
            progress: f.progress,
            clock: f.clock,
            pictures: _pixelPictures(),
            entitlements: entitlements,
            onPicture: (p) => picture = p,
            onNavReady: (n, _) => nav = n,
          ),
        );
        await _pumpMapReady(tester);

        for (final id in f.services.course.places[0].stories) {
          finishStory(f.progress, id);
        }
        await tester.pump();
        await _runFrames(tester, 2600, step: 50);

        expect(picture.FROG.at, 1);
        expect(
          find.text(MapWording.newPlaceCounter(2, 10).toUpperCase()),
          findsOneWidget,
        );
        expect(
          find.text(MapWording.playFirstStory(1).toUpperCase()),
          findsOneWidget,
        );
        expect(nav.routes, isEmpty);

        await tester.tap(find.byKey(const Key('up-next-play')));
        await tester.pump();
        await _runFrames(tester, 550);
        expect(nav.routes, [const PlaceRoute('parque')]);
        expect(nav.routes.whereType<StoryRoute>(), isEmpty);
        expect(find.byKey(const Key('place-plan-card')), findsOneWidget);
        expect(find.byKey(const Key('place-see-plans')), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N8.6 place card screenshots', (tester) async {
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

      ReviewPair pair(String word, String scene) => ReviewPair(
        word: word,
        say: '',
        scene: scene,
        yes: PictureSpec(cam: const [0, 0, 196, 104]),
        no: PictureSpec(cam: const [0, 0, 196, 104]),
      );

      final cocinaPairs = <ReviewPair>[
        pair('mesa', 'mesa'),
        pair('cuchara', 'mesa'),
        pair('estufa', 'estufa'),
        pair('nevera', 'nevera'),
      ];
      const cocinaScenes = <String, String>{
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
            customPairs: cocinaPairs,
            storyScenes: cocinaScenes,
          );
          final places = f.services.course.places;
          for (final p in places.take(2)) {
            for (final id in p.stories) {
              f.clock.advance(const Duration(seconds: 5));
              finishStory(f.progress, id);
            }
          }
          for (final id in places[2].stories.take(state.count)) {
            f.clock.advance(const Duration(seconds: 5));
            finishStory(f.progress, id);
          }
          // Seed 6-day streak to match Noche-Motion-Visita.dc.html.
          final now = DateTime.fromMillisecondsSinceEpoch(
            f.clock.nowMs(),
            isUtc: true,
          );
          final dias = <String, dynamic>{};
          for (var i = 0; i < 6; i++) {
            final d = now.subtract(Duration(days: i));
            final key =
                '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            dias[key] = 5;
          }
          final raw = Map<String, dynamic>.from(f.progress.raw);
          raw['dias'] = dias;
          f.progress.import(jsonEncode(raw));

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
                      MapScreen(
                        services: services,
                        reviewTitle: MapWording.reviewTitle,
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
          await _pumpMapReady(tester);
          await _tapStopOnMap(tester, 2);
          await tester.pump(const Duration(milliseconds: 250));
          await tester.runAsync(() async {
            await precacheImage(
              MemoryImage(mesaBytes),
              tester.element(find.byType(MapScreen)),
            );
            await precacheImage(
              MemoryImage(estufaBytes),
              tester.element(find.byType(MapScreen)),
            );
            await precacheImage(
              MemoryImage(neveraBytes),
              tester.element(find.byType(MapScreen)),
            );
            await Future<void>.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

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
          File('${dir.path}/place_card_${state.name}_${screen.tag}.png')
              .writeAsBytesSync(bytes!);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  }
}
