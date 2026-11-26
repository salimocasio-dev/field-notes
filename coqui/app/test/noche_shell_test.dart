import 'dart:convert';
import 'dart:ui' as ui;

import 'package:app/src/app.dart';
import 'package:app/src/navigator.dart';
import 'package:app/src/shell.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/foundation.dart' show DebugPrintCallback, debugPrint;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

class _LanguageCatalog extends FakeCourseCatalog implements LanguageCatalog {
  _LanguageCatalog(this.language);

  @override
  final Language language;
}

class _StubTabModule implements FeatureModule {
  const _StubTabModule(this.id, {this.onRoute});

  @override
  final String id;

  final Widget? Function(AppRoute route, Services s)? onRoute;

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: id,
    label: id,
    icon: Icons.circle,
    builder: (_) => Center(child: Text('tab:$id')),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => onRoute?.call(route, s);
}

final Language _arabicTestLanguage = Language(
  code: 'ar',
  englishName: 'Arabic',
  nativeName: 'العربية',
  recognitionLocale: 'ar-EG',
  direction: LanguageDirection.rtl,
  script: 'Arab',
  partnerName: 'Danny',
  callAgentId: spanishCallAgentId,
  micWords: const {
    'ready': 'اضغط وتكلم',
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
    'speak': 'التحدث',
    'me': 'أنا',
  },
);

List<FeatureModule> _stubModules({
  Widget? Function(AppRoute route, Services s)? onRoute,
}) => [for (final id in NocheTabs.order) _StubTabModule(id, onRoute: onRoute)];

void main() {
  for (final size in const [Size(390, 844), Size(412, 915)]) {
    testWidgets('system insets paint ground at $size', (tester) async {
      // Android 16's transparent system bars show the app's actual pixels,
      // regardless of SystemUiOverlayStyle.statusBarColor.
      tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 34);
      addTearDown(tester.view.reset);
      final app = TestApp(tester);
      await app.open(stored: seed('curso'), size: size, ratio: 1);
      final key = GlobalKey();
      final widget = tester.widget<CoquiApp>(find.byType(CoquiApp));
      await tester.pumpWidget(RepaintBoundary(key: key, child: widget));
      await app.settle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final pixels = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        image.dispose();
        return bytes!.buffer.asUint8List();
      });
      for (final y in [
        0,
        43,
        size.height.toInt() - 34,
        size.height.toInt() - 1,
      ]) {
        final offset = (y * size.width.toInt() + size.width ~/ 2) * 4;
        expect(pixels!.sublist(offset, offset + 4), [
          12,
          25,
          38,
          255,
        ], reason: 'system inset at y=$y must show Noche ground');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'NocheTabBar replaces CoquiTabBar, uses course.language.tabNames, and updates when the language changes',
    (tester) async {
      final spanishCatalog = FakeCourseCatalog();
      await spanishCatalog.load();
      final arabicCatalog = _LanguageCatalog(_arabicTestLanguage);
      await arabicCatalog.load();

      final nav = ShellNavigator();
      final router = GoRouter(
        initialLocation: '/tab/map',
        routes: [
          GoRoute(path: '/tab/:id', builder: (_, _) => const SizedBox.shrink()),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(nav.dispose);
      nav.router = router;

      Future<void> pumpWithLanguage(CourseCatalog course) async {
        final s = fakeServices(course: course, nav: nav);
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: AppShell(
                services: s,
                modules: _stubModules(),
                nav: nav,
                route: const TabRoute('map'),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpWithLanguage(spanishCatalog);
      expect(find.byType(NocheTabBar), findsOneWidget);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      final spanishBar = tester.widget<NocheTabBar>(find.byType(NocheTabBar));
      expect(spanishBar.tabNames, Language.spanish.tabNames);
      expect(spanishBar.script, 'Latn');
      expect(spanishBar.languageCode, 'es');
      for (final label in Language.spanish.tabNames.values) {
        expect(find.text(label), findsOneWidget);
      }

      await pumpWithLanguage(arabicCatalog);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      final arabicBar = tester.widget<NocheTabBar>(find.byType(NocheTabBar));
      expect(arabicBar.tabNames, _arabicTestLanguage.tabNames);
      expect(arabicBar.script, 'Arab');
      expect(arabicBar.languageCode, 'ar');
      for (final label in _arabicTestLanguage.tabNames.values) {
        expect(find.text(label), findsOneWidget);
      }
      for (final label in Language.spanish.tabNames.values) {
        expect(find.text(label), findsNothing);
      }
    },
  );

  testWidgets(
    'LanguagesRoute, PlansRoute, ImportRoute, and PlaceRoute go to the module that answers them',
    (tester) async {
      final course = FakeCourseCatalog();
      await course.load();
      final nav = ShellNavigator();
      final currentRoute = ValueNotifier<AppRoute>(const TabRoute('map'));
      final router = GoRouter(
        initialLocation: '/tab/map',
        routes: [
          for (final path in const [
            '/tab/:id',
            '/idiomas',
            '/planes',
            '/importar',
            '/lugar/:id',
          ])
            GoRoute(path: path, builder: (_, _) => const SizedBox.shrink()),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(nav.dispose);
      addTearDown(currentRoute.dispose);
      nav.router = router;

      Widget? screenFor(AppRoute route, Services s) => switch (route) {
        LanguagesRoute() => const Center(child: Text('screen:languages')),
        PlansRoute() => const Center(child: Text('screen:plans')),
        ImportRoute() => const Center(child: Text('screen:import')),
        PlaceRoute(:final placeId) => Center(
          child: Text('screen:place:$placeId'),
        ),
        _ => null,
      };
      final modules = _stubModules(onRoute: screenFor);
      final services = fakeServices(course: course, nav: nav);
      nav.answers = (r) => modules.any((m) => m.screenFor(r, services) != null);

      Future<void> pumpRoute(AppRoute route) async {
        currentRoute.value = route;
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: ValueListenableBuilder<AppRoute>(
                valueListenable: currentRoute,
                builder: (_, r, _) => AppShell(
                  services: services,
                  modules: modules,
                  nav: nav,
                  route: r,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpRoute(const LanguagesRoute());
      expect(findShellRoute(const LanguagesRoute()), findsOneWidget);
      expect(findShellTab('map'), findsOneWidget);
      expect(find.text('screen:languages'), findsOneWidget);
      expect(find.text('tab:map'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const PlansRoute());
      expect(findShellRoute(const PlansRoute()), findsOneWidget);
      expect(find.text('screen:plans'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const ImportRoute());
      expect(findShellRoute(const ImportRoute()), findsOneWidget);
      expect(find.text('screen:import'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const PlaceRoute('casa'));
      expect(findShellRoute(const PlaceRoute('casa')), findsOneWidget);
      expect(find.text('screen:place:casa'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsOneWidget);
      expect(find.byKey(ShellKeys.tabBar), findsOneWidget);
      expect(
        tester.widget<NocheTabBar>(find.byType(NocheTabBar)).selectedId,
        NocheTabs.map,
      );
    },
  );

  testWidgets(
    'unknown PlaceRoute falls back and logs; LanguagesRoute, PlaceRoute, PlansRoute, and ImportRoute behave cleanly',
    (tester) async {
      final logs = <String>[];
      final DebugPrintCallback previous = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = previous);

      final app = TestApp(tester);
      await app.open(stored: seed('curso'));
      expect(app.selectedTab, 'map');
      expect(findShellTab('map'), findsOneWidget);

      // Unknown PlaceRoute always falls back to map and logs.
      logs.clear();
      await app.go(const PlaceRoute('no-existe'));
      expect(findShellRoute(const PlaceRoute('no-existe')), findsNothing);
      expect(app.tabBarShown, isTrue, reason: 'PlaceRoute(no-existe)');
      expect(app.selectedTab, 'map', reason: 'PlaceRoute(no-existe)');
      expect(logs, isNotEmpty, reason: 'expected log line for unknown place');
      expect(tester.takeException(), isNull, reason: 'PlaceRoute(no-existe)');

      // PlansRoute() opens under ShellKeys.route(PlansRoute()) with tab bar hidden.
      logs.clear();
      await app.go(const PlansRoute());
      expect(tester.takeException(), isNull, reason: 'PlansRoute()');
      expect(findShellRoute(const PlansRoute()), findsOneWidget);
      expect(find.byKey(const Key('plans-scroll')), findsOneWidget);
      expect(app.tabBarShown, isFalse, reason: 'PlansRoute()');
      await app.go(const TabRoute('map'));

      // ImportRoute() opens under ShellKeys.route(ImportRoute()) (with tab bar
      // hidden) once #115 lands, or stays on map and logs unanswered before #115.
      logs.clear();
      await app.go(const ImportRoute());
      expect(tester.takeException(), isNull, reason: 'ImportRoute()');
      if (findShellRoute(const ImportRoute()).evaluate().isNotEmpty ||
          !app.tabBarShown) {
        expect(app.tabBarShown, isFalse, reason: 'ImportRoute()');
        await app.go(const TabRoute('map'));
      } else {
        expect(app.tabBarShown, isTrue, reason: 'ImportRoute()');
        expect(app.selectedTab, 'map', reason: 'ImportRoute()');
        expect(logs, isNotEmpty, reason: 'expected log line for ImportRoute');
      }

      // LanguagesRoute() opens under ShellKeys.route(LanguagesRoute()) with tab bar hidden.
      logs.clear();
      await app.go(const LanguagesRoute());
      expect(tester.takeException(), isNull, reason: 'LanguagesRoute()');
      expect(findShellRoute(const LanguagesRoute()), findsOneWidget);
      expect(find.byKey(const ValueKey('language-card-es')), findsOneWidget);
      expect(app.tabBarShown, isFalse, reason: 'LanguagesRoute()');

      // Opening unknown PlaceRoute directly falls back to the map and logs.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final unknownPlaceDirect = TestApp(tester);
      await unknownPlaceDirect.open(
        stored: seed('curso'),
        location: '/lugar/no-existe',
      );
      expect(findShellRoute(const PlaceRoute('no-existe')), findsNothing);
      expect(unknownPlaceDirect.tabBarShown, isTrue);
      expect(unknownPlaceDirect.selectedTab, 'map');
      expect(
        logs,
        isNotEmpty,
        reason: 'expected log line for /lugar/no-existe',
      );
      expect(tester.takeException(), isNull);

      // /planes opens under ShellKeys.route(PlansRoute()) with tab bar hidden.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final plansDirect = TestApp(tester);
      await plansDirect.open(stored: seed('curso'), location: '/planes');
      expect(tester.takeException(), isNull, reason: '/planes');
      expect(findShellRoute(const PlansRoute()), findsOneWidget);
      expect(find.byKey(const Key('plans-scroll')), findsOneWidget);
      expect(plansDirect.tabBarShown, isFalse, reason: '/planes');

      // /importar opens under ShellKeys.route(ImportRoute()) (tab bar hidden)
      // once #115 lands, or falls back to map and logs.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final importDirect = TestApp(tester);
      await importDirect.open(stored: seed('curso'), location: '/importar');
      expect(tester.takeException(), isNull, reason: '/importar');
      if (findShellRoute(const ImportRoute()).evaluate().isNotEmpty ||
          !importDirect.tabBarShown) {
        expect(importDirect.tabBarShown, isFalse, reason: '/importar');
      } else {
        expect(importDirect.tabBarShown, isTrue, reason: '/importar');
        expect(importDirect.selectedTab, 'map', reason: '/importar');
        expect(logs, isNotEmpty, reason: 'expected log line for /importar');
      }

      // /idiomas opens under ShellKeys.route(LanguagesRoute()) with tab bar hidden.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final languagesDirect = TestApp(tester);
      await languagesDirect.open(stored: seed('curso'), location: '/idiomas');
      expect(tester.takeException(), isNull, reason: '/idiomas');
      expect(findShellRoute(const LanguagesRoute()), findsOneWidget);
      expect(find.byKey(const ValueKey('language-card-es')), findsOneWidget);
      expect(languagesDirect.tabBarShown, isFalse, reason: '/idiomas');

      // /lugar/casa opens under ShellKeys.route(PlaceRoute('casa')) with Map tab bar.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final placeDirect = TestApp(tester);
      await placeDirect.open(stored: seed('curso'), location: '/lugar/casa');
      expect(placeDirect.tabBarShown, isTrue);
      expect(placeDirect.selectedTab, 'map');
      expect(findShellRoute(const PlaceRoute('casa')), findsOneWidget);
      expect(find.byKey(const Key('place-back')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'app background, loading background, status bars, web CSP, and Android release signing are hardened',
    (tester) async {
      final app = TestApp(tester);
      await app.open(stored: seed('curso'));

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme!.scaffoldBackgroundColor, NocheColors.ground);
      expect(materialApp.theme!.canvasColor, NocheColors.ground);

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.statusBarColor, NocheColors.ground);
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.statusBarBrightness, Brightness.dark);
      expect(region.value.systemStatusBarContrastEnforced, isFalse);
      expect(region.value.systemNavigationBarColor, NocheColors.ground);
      expect(region.value.systemNavigationBarIconBrightness, Brightness.light);
      expect(region.value.systemNavigationBarContrastEnforced, isFalse);

      final indexHtml = repoFile('coqui/app/web/index.html');
      expect(
        indexHtml,
        contains('<meta name="theme-color" content="#0C1926">'),
      );
      expect(indexHtml, contains('background:#0C1926'));
      // S8: Content-Security-Policy with local scripts/WASM + ElevenLabs endpoints and zero external script CDNs.
      expect(indexHtml, contains('<meta http-equiv="Content-Security-Policy"'));
      expect(indexHtml, contains("script-src 'self' 'wasm-unsafe-eval'"));
      expect(indexHtml, contains('https://*.elevenlabs.io'));
      expect(indexHtml, contains('wss://*.elevenlabs.io'));
      expect(indexHtml, isNot(contains('cdn.jsdelivr.net')));
      expect(indexHtml, isNot(contains('unpkg.com')));
      expect(indexHtml, isNot(contains('gstatic.com')));

      // S9: Android release signing fails closed without silently falling back to debug.keystore.
      final gradle = repoFile('coqui/app/android/app/build.gradle.kts');
      expect(gradle, contains('key.properties'));
      expect(gradle, contains('COQUI_ANDROID_STORE_FILE'));
      expect(gradle, contains('GradleException'));
      expect(
        RegExp(
          r'release\s*\{[^}]*getByName\("debug"\)',
          dotAll: true,
        ).hasMatch(gradle),
        isFalse,
        reason: 'release buildType must never sign with debug signingConfig',
      );

      final manifest = jsonDecode(
        repoFile('coqui/app/web/manifest.json'),
      ) as Map<String, dynamic>;
      expect(manifest['background_color'], '#0C1926');
      expect(manifest['theme_color'], '#0C1926');
    },
  );
}
