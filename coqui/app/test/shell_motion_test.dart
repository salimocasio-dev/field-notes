// N8.3 Shell motion checks (strictly shell-only — stub modules, ShellKeys,
// TestApp, and harness.dart helpers only).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app/src/app.dart';
import 'package:app/src/motion.dart';
import 'package:app/src/navigator.dart';
import 'package:app/src/shell.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

class _TabProbe extends StatefulWidget {
  const _TabProbe({required this.id, required this.onInit});

  final String id;
  final void Function(String id) onInit;

  @override
  State<_TabProbe> createState() => _TabProbeState();
}

class _TabProbeState extends State<_TabProbe> {
  @override
  void initState() {
    super.initState();
    widget.onInit(widget.id);
  }

  @override
  Widget build(BuildContext context) => Center(child: Text('tab:${widget.id}'));
}

class _StubShellModule implements FeatureModule {
  const _StubShellModule(this.id, {this.onTabInit, this.onRoute});

  @override
  final String id;

  final void Function(String id)? onTabInit;
  final Widget? Function(AppRoute route, Services s)? onRoute;

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: id,
    label: id,
    icon: Icons.circle,
    builder: (_) => _TabProbe(id: id, onInit: onTabInit ?? (_) {}),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => onRoute?.call(route, s);
}

List<FeatureModule> _stubModules({
  void Function(String id)? onTabInit,
  Widget? Function(AppRoute route, Services s)? onRoute,
}) => [
  for (final id in NocheTabs.order)
    _StubShellModule(id, onTabInit: onTabInit, onRoute: onRoute),
];

GoRouter _shellRouter() => GoRouter(
  initialLocation: '/tab/map',
  routes: [
    for (final path in const [
      '/tab/:id',
      '/cuento/:id',
      '/repaso',
      '/nivel',
      '/libro/:id',
      '/llamada/:id',
      '/prueba-voz',
      '/idiomas',
      '/planes',
      '/importar',
      '/lugar/:id',
    ])
      GoRoute(path: path, builder: (_, _) => const SizedBox.shrink()),
  ],
);

String _sharedJson(String code) => jsonEncode({
  'v': 1,
  'dias': <String, Object?>{},
  'minutos': 0,
  'minutosDia': <String, Object?>{},
  'idiomas': ['es', 'ar'],
  'idioma': code,
});

String _storeJson() => jsonEncode({
  'palabras': <String, Object?>{},
  'dias': <String, Object?>{},
  'cuentos': <String, Object?>{},
  'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 1, 'habla': 1},
  'minutos': 0,
  'v': 1,
});

double _tabDx(WidgetTester tester, String id) => tester
    .widget<Transform>(find.byKey(ShellKeys.tabMotion(id), skipOffstage: false))
    .transform
    .getTranslation()
    .x;

double _tabOpacity(WidgetTester tester, String id) => tester
    .widget<Opacity>(find.byKey(ShellKeys.tabOpacity(id), skipOffstage: false))
    .opacity;

double _tabBarDy(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(ShellKeys.tabBarMotion))
    .transform
    .getTranslation()
    .y;

double _tabBarOpacity(WidgetTester tester) {
  final motion = find.byKey(ShellKeys.tabBarMotion);
  final opacity = find.descendant(of: motion, matching: find.byType(Opacity));
  return tester.widget<Opacity>(opacity.first).opacity;
}

Color _groundColor(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byKey(ShellKeys.ground)).color;

void main() {
  group('AppShell tab switching (NocheFollow keep-alive)', () {
    for (final (label, isArabic) in [
      ('Spanish LTR', false),
      ('Arabic RTL', true),
    ]) {
      testWidgets(
        '$label switches toward end and start with exact NocheFollow math and stationary tab bar',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: false);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );

          final course = isArabic
              ? FakeCourseCatalog.arabic()
              : FakeCourseCatalog();
          await course.load();

          final nav = ShellNavigator();
          final router = _shellRouter();
          addTearDown(router.dispose);
          addTearDown(nav.dispose);
          nav.router = router;

          final initCounts = <String, int>{};
          final modules = _stubModules(
            onTabInit: (id) => initCounts[id] = (initCounts[id] ?? 0) + 1,
          );
          final services = fakeServices(course: course, nav: nav);
          final currentRoute = ValueNotifier<AppRoute>(const TabRoute('map'));
          addTearDown(currentRoute.dispose);

          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: ValueListenableBuilder<AppRoute>(
                  valueListenable: currentRoute,
                  builder: (_, route, _) => AppShell(
                    services: services,
                    modules: modules,
                    nav: nav,
                    route: route,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(initCounts['map'], 1);

          // 1. Switch toward end: map (2) -> speak (3).
          currentRoute.value = const TabRoute('speak');
          await tester.pump();

          final endSign = isArabic ? -1.0 : 1.0;
          expect(
            _tabDx(tester, 'speak'),
            closeTo(endSign * NocheMotion.tab, 1e-4),
          );
          expect(_tabOpacity(tester, 'speak'), 0.0);
          expect(_tabOpacity(tester, 'map'), 1.0);
          expect(_tabBarDy(tester), 0.0);
          expect(_tabBarOpacity(tester), 1.0);

          // Mid-outgoing (press ~/ 2 = 45ms): map fading on exit, speak still waiting.
          await tester.pump(const Duration(milliseconds: 45));
          expect(
            _tabOpacity(tester, 'map'),
            closeTo(1.0 - NocheMotion.exit.transform(0.5), 1e-3),
          );
          expect(_tabOpacity(tester, 'speak'), 0.0);
          expect(
            _tabDx(tester, 'speak'),
            closeTo(endSign * NocheMotion.tab, 1e-4),
          );
          expect(_tabBarDy(tester), 0.0);

          // At followAfter + move ~/ 2 (60 + 110 = 170ms -> +125ms): map offstage, speak at enter(0.5).
          await tester.pump(const Duration(milliseconds: 125));
          expect(findShellTab('map').evaluate(), isEmpty);
          expect(findShellTab('map', skipOffstage: false), findsOneWidget);
          final pMidEnd = NocheMotion.enter.transform(0.5);
          expect(_tabOpacity(tester, 'speak'), closeTo(pMidEnd, 1e-3));
          expect(
            _tabDx(tester, 'speak'),
            closeTo(endSign * NocheMotion.tab * (1.0 - pMidEnd), 1e-3),
          );
          expect(_tabBarDy(tester), 0.0);

          // At followAfter + move (280ms -> +110ms): settled.
          await tester.pump(const Duration(milliseconds: 110));
          expect(_tabOpacity(tester, 'speak'), 1.0);
          expect(_tabDx(tester, 'speak'), 0.0);
          expect(_tabBarDy(tester), 0.0);
          expect(initCounts['map'], 1);
          expect(initCounts['speak'], 1);

          // 2. Switch toward start: speak (3) -> words (1).
          currentRoute.value = const TabRoute('words');
          await tester.pump();

          final startSign = isArabic ? 1.0 : -1.0;
          expect(
            _tabDx(tester, 'words'),
            closeTo(startSign * NocheMotion.tab, 1e-4),
          );
          expect(_tabOpacity(tester, 'words'), 0.0);
          expect(_tabOpacity(tester, 'speak'), 1.0);
          expect(_tabBarDy(tester), 0.0);

          await tester.pump(const Duration(milliseconds: 170));
          final pMidStart = NocheMotion.enter.transform(0.5);
          expect(_tabOpacity(tester, 'words'), closeTo(pMidStart, 1e-3));
          expect(
            _tabDx(tester, 'words'),
            closeTo(startSign * NocheMotion.tab * (1.0 - pMidStart), 1e-3),
          );
          expect(_tabBarDy(tester), 0.0);

          await tester.pump(const Duration(milliseconds: 110));
          expect(_tabOpacity(tester, 'words'), 1.0);
          expect(_tabDx(tester, 'words'), 0.0);

          // Tabs & NocheTabBar always stay LTR even for Arabic RTL.
          expect(
            Directionality.of(tester.element(findShellTab('words'))),
            TextDirection.ltr,
          );
          expect(
            Directionality.of(tester.element(find.byType(NocheTabBar))),
            TextDirection.ltr,
          );

          // Map tab was never rebuilt/disposed when switching away and back.
          currentRoute.value = const TabRoute('map');
          await tester.pump(const Duration(milliseconds: 280));
          expect(initCounts['map'], 1);
          expect(initCounts['words'], 1);
          expect(initCounts['speak'], 1);
        },
      );
    }

    testWidgets(
      'reduced motion cross-fades tabs in place with zero travel in followAfter + quick',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final course = FakeCourseCatalog();
        await course.load();
        final nav = ShellNavigator();
        final router = _shellRouter();
        addTearDown(router.dispose);
        addTearDown(nav.dispose);
        nav.router = router;

        final modules = _stubModules();
        final services = fakeServices(course: course, nav: nav);
        final currentRoute = ValueNotifier<AppRoute>(const TabRoute('map'));
        addTearDown(currentRoute.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: ValueListenableBuilder<AppRoute>(
                valueListenable: currentRoute,
                builder: (_, route, _) => AppShell(
                  services: services,
                  modules: modules,
                  nav: nav,
                  route: route,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        currentRoute.value = const TabRoute('speak');
        await tester.pump();
        expect(_tabDx(tester, 'speak'), 0.0);
        expect(_tabOpacity(tester, 'speak'), 0.0);

        // Middle: followAfter + quick ~/ 2 = 60 + 70 = 130ms.
        await tester.pump(const Duration(milliseconds: 130));
        expect(_tabDx(tester, 'speak'), 0.0);
        expect(
          _tabOpacity(tester, 'speak'),
          closeTo(NocheMotion.enter.transform(0.5), 1e-3),
        );

        // End: followAfter + quick = 60 + 140 = 200ms -> +70ms.
        await tester.pump(const Duration(milliseconds: 70));
        expect(_tabDx(tester, 'speak'), 0.0);
        expect(_tabOpacity(tester, 'speak'), 1.0);
        expect(findShellTab('map').evaluate(), isEmpty);
      },
    );
  });

  group('AppShell full-screen lesson routes & ground transitions', () {
    for (final lessonRoute in const <AppRoute>[
      StoryRoute('la-lluvia'),
      CallRoute('casa'),
      BookRoute('la-familia'),
    ]) {
      testWidgets(
        'opening and closing $lessonRoute sinks/rises NocheTabBar and lerps ground color',
        (tester) async {
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: false);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );

          final course = FakeCourseCatalog();
          await course.load();
          final nav = ShellNavigator();
          final router = _shellRouter();
          addTearDown(router.dispose);
          addTearDown(nav.dispose);
          nav.router = router;

          final modules = _stubModules(
            onRoute: (r, _) => r is TabRoute
                ? null
                : Center(child: Text('screen:${r.runtimeType}')),
          );
          final services = fakeServices(course: course, nav: nav);
          nav.answers = (r) =>
              modules.any((m) => m.screenFor(r, services) != null);
          final currentRoute = ValueNotifier<AppRoute>(const TabRoute('map'));
          addTearDown(currentRoute.dispose);

          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: ValueListenableBuilder<AppRoute>(
                  valueListenable: currentRoute,
                  builder: (_, route, _) => AppShell(
                    services: services,
                    modules: modules,
                    nav: nav,
                    route: route,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();

          expect(_groundColor(tester), NocheColors.ground);
          expect(_tabBarDy(tester), 0.0);
          expect(_tabBarOpacity(tester), 1.0);

          // Open lesson: tab bar sinks 0 -> 96 in pageOut (200ms) on exit,
          // ground transitions ground -> lessonGround in pageIn (320ms) on enter.
          currentRoute.value = lessonRoute;
          await tester.pump();
          expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
          expect(_tabBarDy(tester), 0.0);
          expect(_tabBarOpacity(tester), 1.0);
          expect(_groundColor(tester), NocheColors.ground);

          // Middle of tab bar sink: 100ms (pageOut / 2).
          await tester.pump(const Duration(milliseconds: 100));
          final pOutMid = NocheMotion.exit.transform(0.5);
          expect(
            _tabBarDy(tester),
            closeTo(ShellMotion.tabBarSinkDistance * pOutMid, 1e-2),
          );
          expect(_tabBarOpacity(tester), closeTo(1.0 - pOutMid, 1e-3));
          expect(
            _groundColor(tester),
            Color.lerp(
              NocheColors.ground,
              NocheColors.lessonGround,
              NocheMotion.enter.transform(100 / 320),
            ),
          );

          // End of tab bar sink: 200ms (+100ms).
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.byKey(ShellKeys.tabBar), findsNothing);
          expect(find.byType(NocheTabBar), findsNothing);

          // End of ground transition: 320ms (+120ms).
          await tester.pump(const Duration(milliseconds: 120));
          expect(_groundColor(tester), NocheColors.lessonGround);

          // Close lesson back to map: tab bar mounts at 96 / opacity 0, waits
          // followAfter (60ms), rises 96 -> 0 in move (220ms) and fades 0 -> 1 in quick (140ms).
          // Ground transitions lessonGround -> ground in pageOut (200ms).
          currentRoute.value = const TabRoute('map');
          await tester.pump();
          expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
          expect(_tabBarDy(tester), ShellMotion.tabBarSinkDistance);
          expect(_tabBarOpacity(tester), 0.0);
          expect(_groundColor(tester), NocheColors.lessonGround);

          // End of followAfter (60ms): tab bar still waiting at bottom.
          await tester.pump(const Duration(milliseconds: 60));
          expect(_tabBarDy(tester), ShellMotion.tabBarSinkDistance);
          expect(_tabBarOpacity(tester), 0.0);

          // Middle of rise: 60 + 110 = 170ms (+110ms).
          await tester.pump(const Duration(milliseconds: 110));
          expect(
            _tabBarDy(tester),
            closeTo(
              ShellMotion.tabBarSinkDistance *
                  (1.0 - NocheMotion.enter.transform(0.5)),
              1e-2,
            ),
          );
          expect(
            _tabBarOpacity(tester),
            closeTo(NocheMotion.enter.transform(110 / 140), 1e-3),
          );

          // End of ground pageOut: 200ms (+30ms).
          await tester.pump(const Duration(milliseconds: 30));
          expect(_groundColor(tester), NocheColors.ground);

          // End of tab bar rise: 280ms (+80ms).
          await tester.pump(const Duration(milliseconds: 80));
          expect(_tabBarDy(tester), 0.0);
          expect(_tabBarOpacity(tester), 1.0);
        },
      );
    }

    testWidgets(
      'reduced motion fades tab bar in place with dy == 0 and transitions ground in quick',
      (tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        final course = FakeCourseCatalog();
        await course.load();
        final nav = ShellNavigator();
        final router = _shellRouter();
        addTearDown(router.dispose);
        addTearDown(nav.dispose);
        nav.router = router;

        final modules = _stubModules(
          onRoute: (r, _) => r is TabRoute
              ? null
              : Center(child: Text('screen:${r.runtimeType}')),
        );
        final services = fakeServices(course: course, nav: nav);
        nav.answers = (r) =>
            modules.any((m) => m.screenFor(r, services) != null);
        final currentRoute = ValueNotifier<AppRoute>(const TabRoute('map'));
        addTearDown(currentRoute.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: ValueListenableBuilder<AppRoute>(
                valueListenable: currentRoute,
                builder: (_, route, _) => AppShell(
                  services: services,
                  modules: modules,
                  nav: nav,
                  route: route,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        currentRoute.value = const StoryRoute('la-lluvia');
        await tester.pump();
        expect(_tabBarDy(tester), 0.0);

        await tester.pump(const Duration(milliseconds: 70));
        expect(_tabBarDy(tester), 0.0);
        expect(
          _tabBarOpacity(tester),
          closeTo(1.0 - NocheMotion.exit.transform(0.5), 1e-3),
        );

        await tester.pump(const Duration(milliseconds: 70));
        expect(find.byKey(ShellKeys.tabBar), findsNothing);
        expect(_groundColor(tester), NocheColors.lessonGround);

        currentRoute.value = const TabRoute('map');
        await tester.pump();
        expect(_tabBarDy(tester), 0.0);
        expect(_tabBarOpacity(tester), 0.0);

        await tester.pump(const Duration(milliseconds: 60));
        expect(_tabBarDy(tester), 0.0);
        expect(_tabBarOpacity(tester), 0.0);

        await tester.pump(const Duration(milliseconds: 140));
        expect(_tabBarDy(tester), 0.0);
        expect(_tabBarOpacity(tester), 1.0);
        expect(_groundColor(tester), NocheColors.ground);
      },
    );
  });

  group('CoquiApp course change (N2.11)', () {
    for (final reduceMotion in [false, true]) {
      testWidgets(
        'fades out in quick, swaps course, and fades back in move (reduceMotion: $reduceMotion)',
        (tester) async {
          final app = TestApp(tester)
            ..loadCourse = (code) async =>
                code == 'ar' ? FakeCourseCatalog.arabic() : FakeCourseCatalog();

          await app.open(
            reduceMotion: reduceMotion,
            initialStorage: {
              PalabrasStore.sharedStorageKey: _sharedJson('es'),
              PalabrasStore.storageKeyFor('es'): _storeJson(),
              PalabrasStore.storageKeyFor('ar'): _storeJson(),
            },
          );
          // Settle any initial load arrival so course-turn starts from opacity 1.
          await app.advance(600);
          expect(
            tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
            1.0,
          );
          expect(app.services.course.language.code, 'es');

          // Trigger course change es -> ar.
          app.services.progress.setSetting('idioma', 'ar');
          await tester.pump();
          await tester.pump();

          // Mid fade-out (quick ~/ 2 = 70ms): fading out on exit, still Spanish.
          await tester.pump(const Duration(milliseconds: 70));
          expect(
            tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
            closeTo(1.0 - NocheMotion.exit.transform(0.5), 1e-2),
          );
          expect(app.services.course.language.code, 'es');

          // End of fade-out (140ms -> +70ms), then +1ms so Simulation.isDone (>) fires
          // and fadeOutFuture completes and swaps course.
          await tester.pump(const Duration(milliseconds: 70));
          expect(
            tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
            0.0,
          );
          await tester.pump(const Duration(milliseconds: 1));
          await tester.pump();
          expect(app.services.course.language.code, 'ar');

          // Mid fade-in: move ~/ 2 (110ms normal, 70ms reduced).
          final halfInMs = reduceMotion ? 70 : 110;
          await tester.pump(Duration(milliseconds: halfInMs));
          expect(
            tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
            closeTo(NocheMotion.enter.transform(0.5), 2e-2),
          );

          // End of fade-in (+1ms for Simulation.isDone).
          await tester.pump(Duration(milliseconds: halfInMs + 1));
          expect(
            tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
            1.0,
          );
        },
      );
    }

    testWidgets(
      'blocks pointer events and semantics while outgoing course is at opacity 0.0 awaiting slow async fetch, then restores interactivity',
      (tester) async {
        final arabicCompleter = Completer<CourseCatalog>();
        final app = TestApp(tester)
          ..loadCourse = (code) async =>
              code == 'ar' ? arabicCompleter.future : FakeCourseCatalog();

        await app.open(
          reduceMotion: false,
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson('es'),
            PalabrasStore.storageKeyFor('es'): _storeJson(),
            PalabrasStore.storageKeyFor('ar'): _storeJson(),
          },
        );
        await app.advance(600);
        expect(app.services.course.language.code, 'es');
        expect(app.selectedTab, 'map');
        final ticksBeforeSwitch = app.haptics.ticks;

        // Trigger slow course switch es -> ar.
        app.services.progress.setSetting('idioma', 'ar');
        await tester.pump();
        await tester.pump();

        // Advance past quick (140ms) while Arabic fetch is still pending.
        await tester.pump(const Duration(milliseconds: 141));
        await tester.pump();
        expect(
          tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
          0.0,
        );
        expect(app.services.course.language.code, 'es');

        // Tapping a tab on the invisible old NocheTabBar must be blocked.
        final spanishMeTab = find.descendant(
          of: find.byType(NocheTabBar),
          matching: find.text(Language.spanish.tabNames['me']!),
        );
        await tester.tap(spanishMeTab, warnIfMissed: false);
        await tester.pump();
        expect(app.haptics.ticks, ticksBeforeSwitch);
        expect(app.selectedTab, 'map');

        // Complete the Arabic course load, settle fade-in, and verify interactivity returns.
        arabicCompleter.complete(FakeCourseCatalog.arabic());
        await app.settle(rounds: 15);
        await app.advance(300);
        expect(app.services.course.language.code, 'ar');
        expect(
          tester.widget<Opacity>(find.byKey(shellCourseTurnKey)).opacity,
          1.0,
        );

        await app.openTab('me');
        expect(app.selectedTab, 'me');
        expect(app.haptics.ticks, greaterThan(ticksBeforeSwitch));
      },
    );
  });

  group('CoquiApp boot loading, load arrival, and load failure', () {
    testWidgets(
      'loading stays silent for 300ms, fades in pulsing dots + line, then arrives with tab bar rising from 96',
      (tester) async {
        final courseCompleter = Completer<CourseCatalog>();
        final app = TestApp(tester)..loadCourse = (_) => courseCompleter.future;

        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: false);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        app.spaces = Spaces({progressKey: seed('curso')});
        app.speech = FakeSpeechListener();
        app.call = FakeCallSession();
        addTearDown(app.call.dispose);

        await tester.pumpWidget(CoquiApp(platform: app.platform()));
        await tester.pump();

        final loadingBox = tester.widget<ColoredBox>(
          find.byKey(shellLoadingKey),
        );
        expect(loadingBox.color, NocheColors.ground);
        expect(find.byKey(shellLoadingDotsKey), findsOneWidget);
        expect(find.text(loadingCourseLine), findsOneWidget);

        double loadingOpacity() => tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.byKey(shellLoadingDotsKey),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity;

        List<double> dotOpacities() => [
          for (final op in tester.widgetList<Opacity>(
            find.descendant(
              of: find.byKey(shellLoadingDotsKey),
              matching: find.byType(Opacity),
            ),
          ))
            op.opacity,
        ];

        // Silent for first 300ms.
        expect(loadingOpacity(), 0.0);
        await tester.pump(const Duration(milliseconds: 280));
        expect(loadingOpacity(), 0.0);

        // Visible after 300ms + 220ms = 520ms (+240ms).
        await tester.pump(const Duration(milliseconds: 240));
        expect(loadingOpacity(), 1.0);

        // Dots pulse with stagger over 900ms (opacities are not all identical).
        await tester.pump(const Duration(milliseconds: 120));
        final dots = dotOpacities();
        expect(dots, hasLength(3));
        expect(dots.toSet().length, greaterThan(1));

        // Complete course load -> loading fades out in 140ms, map fades in 320ms,
        // tab bar waits 160ms then rises from 96 in 320ms and fades in 220ms.
        courseCompleter.complete(FakeCourseCatalog());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
        expect(_tabBarDy(tester), ShellMotion.tabBarSinkDistance);
        expect(_tabBarOpacity(tester), 0.0);

        // At 140ms: outgoing loading unmounted, tab bar still waiting (< 160ms).
        await tester.pump(const Duration(milliseconds: 140));
        expect(find.byKey(shellLoadingKey), findsNothing);
        expect(_tabBarDy(tester), ShellMotion.tabBarSinkDistance);
        expect(_tabBarOpacity(tester), 0.0);

        // At 160ms (+20ms): tab bar about to start rising.
        await tester.pump(const Duration(milliseconds: 20));
        expect(
          _tabBarDy(tester),
          closeTo(ShellMotion.tabBarSinkDistance, 1e-2),
        );

        // At 160 + 160 = 320ms (+160ms): tab bar midway up, map fade finished.
        await tester.pump(const Duration(milliseconds: 160));
        expect(
          _tabBarDy(tester),
          closeTo(
            ShellMotion.tabBarSinkDistance *
                (1.0 - NocheMotion.enter.transform(0.5)),
            1e-2,
          ),
        );
        expect(
          _tabBarOpacity(tester),
          closeTo(NocheMotion.enter.transform(160 / 220), 1e-2),
        );

        // At 160 + 320 = 480ms (+160ms): tab bar at rest.
        await tester.pump(const Duration(milliseconds: 160));
        expect(_tabBarDy(tester), 0.0);
        expect(_tabBarOpacity(tester), 1.0);
      },
    );

    testWidgets(
      'reduced motion keeps loading dots stationary at 1.0 and tab bar at dy == 0 on arrival',
      (tester) async {
        final courseCompleter = Completer<CourseCatalog>();
        final app = TestApp(tester)..loadCourse = (_) => courseCompleter.future;

        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        app.spaces = Spaces({progressKey: seed('curso')});
        app.speech = FakeSpeechListener();
        app.call = FakeCallSession();
        addTearDown(app.call.dispose);

        await tester.pumpWidget(CoquiApp(platform: app.platform()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        for (final sample in [0, 150, 300, 450]) {
          if (sample > 0) await tester.pump(const Duration(milliseconds: 150));
          final dots = [
            for (final op in tester.widgetList<Opacity>(
              find.descendant(
                of: find.byKey(shellLoadingDotsKey),
                matching: find.byType(Opacity),
              ),
            ))
              op.opacity,
          ];
          expect(dots, [1.0, 1.0, 1.0]);
        }

        courseCompleter.complete(FakeCourseCatalog());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.pump();

        expect(_tabBarDy(tester), 0.0);
        await tester.pump(const Duration(milliseconds: 160));
        expect(_tabBarDy(tester), 0.0);
        await tester.pump(const Duration(milliseconds: 140));
        expect(_tabBarDy(tester), 0.0);
        expect(_tabBarOpacity(tester), 1.0);
      },
    );

    testWidgets(
      'load failure fades out dots, arrives via NocheArrive, and Try again returns to loading',
      (tester) async {
        var completer = Completer<CourseCatalog>();
        final app = TestApp(tester)..loadCourse = (_) => completer.future;

        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: false);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        app.spaces = Spaces({progressKey: seed('curso')});
        app.speech = FakeSpeechListener();
        app.call = FakeCallSession();
        addTearDown(app.call.dispose);

        await tester.pumpWidget(CoquiApp(platform: app.platform()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 520));
        expect(find.byKey(shellLoadingKey), findsOneWidget);

        // Fail course load.
        completer.completeError(const SocketException('offline'));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
        await tester.pump();

        expect(find.byKey(LoadFailed.screenKey), findsOneWidget);
        final lineItem = find.byKey(const ValueKey('noche_arrive_item_0'));
        final nextItem = find.byKey(const ValueKey('noche_arrive_next'));

        double itemOpacity(Finder f) => tester
            .widget<Opacity>(
              find.descendant(of: f, matching: find.byType(Opacity)).first,
            )
            .opacity;
        double itemDy(Finder f) =>
            tester.widget<Transform>(f).transform.getTranslation().y;

        // Before swapAfter (100ms): both hidden and offset by NocheMotion.row (8).
        expect(itemOpacity(lineItem), 0.0);
        expect(itemDy(lineItem), NocheMotion.row);
        expect(itemOpacity(nextItem), 0.0);
        expect(itemDy(nextItem), NocheMotion.row);

        // At 140ms: outgoing loading dots unmounted; line has started (40ms into 220ms),
        // Try again still waiting until swapAfter + nextDelay = 180ms.
        await tester.pump(const Duration(milliseconds: 140));
        expect(find.byKey(shellLoadingKey), findsNothing);
        expect(itemOpacity(lineItem), greaterThan(0.0));
        expect(itemOpacity(nextItem), 0.0);

        // At 180ms (+40ms): Try again starts.
        await tester.pump(const Duration(milliseconds: 40));
        expect(itemOpacity(nextItem), 0.0);

        // At 400ms (+220ms): both settled.
        await tester.pump(const Duration(milliseconds: 220));
        expect(itemOpacity(lineItem), 1.0);
        expect(itemDy(lineItem), 0.0);
        expect(itemOpacity(nextItem), 1.0);
        expect(itemDy(nextItem), 0.0);

        // Tap Try again with a new pending Completer -> fades out LoadFailed in
        // 140ms and returns to loading dots.
        completer = Completer<CourseCatalog>();
        await tester.tap(find.byKey(LoadFailed.retryKey));
        await tester.pump();
        expect(find.byKey(shellLoadingKey), findsOneWidget);
        expect(find.byKey(LoadFailed.screenKey), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 140));
        expect(find.byKey(LoadFailed.screenKey), findsNothing);

        // Clean up pending completer so no dangling state remains.
        completer.complete(FakeCourseCatalog());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 600));
      },
    );

    testWidgets(
      'reduced motion load failure arrives together in place after swapAfter',
      (tester) async {
        final app = TestApp(tester)..offline = true;
        await app.open(stored: seed('curso'), reduceMotion: true);

        final lineItem = find.byKey(const ValueKey('noche_arrive_item_0'));
        final nextItem = find.byKey(const ValueKey('noche_arrive_next'));
        expect(
          tester.widget<Transform>(lineItem).transform.getTranslation().y,
          0.0,
        );
        expect(
          tester.widget<Transform>(nextItem).transform.getTranslation().y,
          0.0,
        );
        // Settle remaining 80ms of 100ms + 140ms = 240ms (open settles 160ms).
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          tester
              .widget<Opacity>(
                find
                    .descendant(of: lineItem, matching: find.byType(Opacity))
                    .first,
              )
              .opacity,
          1.0,
        );
        expect(
          tester
              .widget<Opacity>(
                find
                    .descendant(of: nextItem, matching: find.byType(Opacity))
                    .first,
              )
              .opacity,
          1.0,
        );
      },
    );
  });
}
