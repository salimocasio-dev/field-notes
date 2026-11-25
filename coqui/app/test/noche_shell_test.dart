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
      expect(find.byType(CoquiTabBar), findsNothing);
      final spanishBar = tester.widget<NocheTabBar>(find.byType(NocheTabBar));
      expect(spanishBar.tabNames, Language.spanish.tabNames);
      expect(spanishBar.script, 'Latn');
      expect(spanishBar.languageCode, 'es');
      for (final label in Language.spanish.tabNames.values) {
        expect(find.text(label), findsOneWidget);
      }

      await pumpWithLanguage(arabicCatalog);
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
      expect(find.text('screen:languages'), findsOneWidget);
      expect(find.text('tab:map'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const PlansRoute());
      expect(find.text('screen:plans'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const ImportRoute());
      expect(find.text('screen:import'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsNothing);

      await pumpRoute(const PlaceRoute('casa'));
      expect(find.text('screen:place:casa'), findsOneWidget);
      expect(find.byType(NocheTabBar), findsOneWidget);
      expect(
        tester.widget<NocheTabBar>(find.byType(NocheTabBar)).selectedId,
        NocheTabs.map,
      );
    },
  );

  testWidgets(
    'unanswered LanguagesRoute, PlansRoute, ImportRoute, and unknown PlaceRoute do nothing and log a line without crashing',
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

      for (final route in const <AppRoute>[
        LanguagesRoute(),
        PlansRoute(),
        ImportRoute(),
        PlaceRoute('no-existe'),
      ]) {
        logs.clear();
        await app.go(route);
        expect(app.tabBarShown, isTrue, reason: '$route');
        expect(app.selectedTab, 'map', reason: '$route');
        expect(logs, isNotEmpty, reason: 'expected log line for $route');
        expect(tester.takeException(), isNull, reason: '$route');
      }

      // Opening those addresses directly falls back to the map and logs.
      for (final location in const [
        '/idiomas',
        '/planes',
        '/importar',
        '/lugar/no-existe',
      ]) {
        logs.clear();
        await tester.pumpWidget(const SizedBox());
        final direct = TestApp(tester);
        await direct.open(stored: seed('curso'), location: location);
        expect(direct.tabBarShown, isTrue, reason: location);
        expect(direct.selectedTab, 'map', reason: location);
        expect(logs, isNotEmpty, reason: 'expected log line for $location');
        expect(tester.takeException(), isNull, reason: location);
      }

      // PlaceRoute('casa') opens PlaceScreen (with Map tab bar) once N4.2 lands,
      // or logs unanswered on pre-N4.2 main.
      logs.clear();
      await tester.pumpWidget(const SizedBox());
      final placeDirect = TestApp(tester);
      await placeDirect.open(stored: seed('curso'), location: '/lugar/casa');
      expect(placeDirect.tabBarShown, isTrue);
      expect(placeDirect.selectedTab, 'map');
      expect(tester.takeException(), isNull);
      if (byTypeName('PlaceScreen').evaluate().isEmpty) {
        expect(logs, isNotEmpty, reason: 'expected log line for /lugar/casa');
      }
    },
  );

  testWidgets(
    'app background, loading background, status bars, and web assets use NocheColors.ground',
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

      final manifest = jsonDecode(
        repoFile('coqui/app/web/manifest.json'),
      ) as Map<String, dynamic>;
      expect(manifest['background_color'], '#0C1926');
      expect(manifest['theme_color'], '#0C1926');
    },
  );
}
