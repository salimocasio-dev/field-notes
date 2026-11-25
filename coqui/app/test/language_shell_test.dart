// Multi-language shell wiring (N2.11): startup language loading, switching
// between languages with fresh module state, and lesson RTL vs chrome LTR.
import 'dart:convert';

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

String _storeJson({
  Map<String, Object?> words = const {},
  Map<String, Object?> stories = const {},
  int welcome = 1,
}) => jsonEncode({
  'palabras': words,
  'dias': <String, Object?>{},
  'cuentos': stories,
  'ajustes': {'min': 30, 'todo': 0, 'bienvenida': welcome, 'habla': 1},
  'minutos': 0,
  'v': 1,
});

Map<String, Object?> _wordRecord(String text) => {
  'w': text,
  'primera': seedNow - 86400000,
  'oida': 3,
  'ear': {
    'etapa': 1,
    'paso': 1,
    'seguidas': 1,
    'fallos': 0,
    'gap': 1,
    'due': seedNow + 86400000,
    'aciertos': [seedNow],
    'ultima': seedNow,
    'aparcada': 0,
    'marca': 0,
    'n': 1,
    'bien': 1,
  },
  'mouth': {
    'etapa': 0,
    'paso': 1,
    'seguidas': 0,
    'fallos': 0,
    'gap': 0,
    'due': 0,
    'aciertos': <int>[],
    'ultima': 0,
    'aparcada': 0,
    'marca': 0,
    'n': 0,
    'bien': 0,
  },
};

String _sharedJson({
  required String languageCode,
  double minutes = 0,
  Map<String, Object?> days = const {},
  List<String> languages = const [],
}) => jsonEncode({
  'v': 1,
  'dias': days,
  'minutos': minutes,
  'minutosDia': <String, Object?>{},
  'idiomas': languages,
  'idioma': languageCode,
});

class _StatefulProbe extends StatefulWidget {
  const _StatefulProbe({
    required this.label,
    required this.onInit,
    required this.onDispose,
  });

  final String label;
  final void Function(int instanceId) onInit;
  final void Function(int instanceId) onDispose;

  static int _nextId = 0;

  @override
  State<_StatefulProbe> createState() => _StatefulProbeState();
}

class _StatefulProbeState extends State<_StatefulProbe> {
  late final int _id = ++_StatefulProbe._nextId;
  int _taps = 0;

  @override
  void initState() {
    super.initState();
    widget.onInit(_id);
  }

  @override
  void dispose() {
    widget.onDispose(_id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _taps++),
    child: Center(child: Text('${widget.label}:$_id:$_taps')),
  );
}

class _ProbeModule implements FeatureModule {
  const _ProbeModule(this.id, {this.tabBuilder, this.onRoute});

  @override
  final String id;

  final Widget Function(BuildContext context, Services s)? tabBuilder;
  final Widget? Function(AppRoute route, Services s)? onRoute;

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: id,
    label: id,
    icon: Icons.circle,
    builder: (context) =>
        tabBuilder?.call(context, s) ?? Center(child: Text('tab:$id')),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => onRoute?.call(route, s);
}

void main() {
  group('startup language loading', () {
    testWidgets(
      'reads coqui.shared.v1 idioma, loads that language course and per-language store, and wires them into modules',
      (tester) async {
        final loadedCodes = <String>[];
        final app = TestApp(tester)
          ..loadCourse = (code) async {
            loadedCodes.add(code);
            return code == 'ar'
                ? FakeCourseCatalog.arabic()
                : FakeCourseCatalog();
          };

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'ar',
              minutes: 15,
              days: {'2026-11-19': 1},
              languages: ['es', 'ar'],
            ),
            PalabrasStore.storageKeyFor('es'): _storeJson(
              words: {'casa': _wordRecord('casa')},
            ),
            PalabrasStore.storageKeyFor('ar'): _storeJson(
              words: {'بيت': _wordRecord('بيت')},
              stories: {
                'la-lluvia': {'n': 1, 'u': seedNow},
              },
            ),
          },
        );

        expect(loadedCodes, ['ar']);
        expect(app.services.course.language.code, 'ar');
        expect(app.services.course.language.direction, LanguageDirection.rtl);
        expect(app.services.progress.words.map((w) => w.w), contains('بيت'));
        expect(
          app.services.progress.words.map((w) => w.w),
          isNot(contains('casa')),
        );
        expect(app.services.progress.played('la-lluvia'), isTrue);
        expect(app.services.progress.minutes, 15);
        expect(app.services.progress.streak, 1);

        final bar = tester.widget<NocheTabBar>(find.byType(NocheTabBar));
        expect(bar.languageCode, 'ar');
        expect(bar.script, 'Arab');
        expect(bar.tabNames, arabicTestLanguage.tabNames);
        expect(find.text('المطر'), findsWidgets);
        expect(find.text('La lluvia'), findsNothing);

        await app.openTab('words');
        expect(find.text('بيت'), findsWidgets);
        expect(find.text('casa'), findsNothing);
      },
    );

    testWidgets(
      'migrates legacy coqui.palabras.v1 into Spanish per-language store on default startup',
      (tester) async {
        final app = TestApp(tester);
        await app.open(stored: seed('curso'));

        expect(app.services.course.language.code, 'es');
        expect(app.storedFor('es'), isNotNull);
        expect(app.sharedStored, isNotNull);
        final shared = jsonDecode(app.sharedStored!) as Map<String, dynamic>;
        expect(shared['idioma'], 'es');
        expect(app.services.progress.words, isNotEmpty);
        expect(app.services.progress.streak, 5);
        expect(find.text('5 days'), findsOneWidget);
      },
    );
  });

  group('switching language', () {
    testWidgets(
      'switching via ProgressStores.currentLanguageCode reloads course and store on map tab while preserving shared streak and minutes',
      (tester) async {
        final loadedCodes = <String>[];
        final app = TestApp(tester)
          ..loadCourse = (code) async {
            loadedCodes.add(code);
            return code == 'ar'
                ? FakeCourseCatalog.arabic()
                : FakeCourseCatalog();
          };

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'es',
              minutes: 20,
              days: {'2026-11-18': 1, '2026-11-19': 1},
              languages: ['es', 'ar'],
            ),
            PalabrasStore.storageKeyFor('es'): _storeJson(
              words: {'casa': _wordRecord('casa')},
            ),
            PalabrasStore.storageKeyFor('ar'): _storeJson(
              words: {'بيت': _wordRecord('بيت')},
            ),
          },
        );

        await app.openTab('me');
        expect(app.selectedTab, 'me');
        expect(app.services.course.language.code, 'es');

        final stores = ProgressStores(app.spaces.kv, app.clock);
        addTearDown(stores.dispose);
        stores.currentLanguageCode = 'ar';
        await app.settle(rounds: 15);

        expect(loadedCodes, ['es', 'ar']);
        expect(app.tabBarShown, isTrue);
        expect(app.selectedTab, 'map');
        expect(app.services.course.language.code, 'ar');
        expect(app.services.progress.words.map((w) => w.w), contains('بيت'));
        expect(
          app.services.progress.words.map((w) => w.w),
          isNot(contains('casa')),
        );
        expect(app.services.progress.minutes, 20);
        expect(app.services.progress.streak, 2);

        final bar = tester.widget<NocheTabBar>(find.byType(NocheTabBar));
        expect(bar.languageCode, 'ar');
        expect(bar.tabNames, arabicTestLanguage.tabNames);
      },
    );

    testWidgets(
      'switching via services.progress.setSetting("idioma", ...) round-trips es -> ar -> es without stale words or bounce-back',
      (tester) async {
        final loadedCodes = <String>[];
        final app = TestApp(tester)
          ..loadCourse = (code) async {
            loadedCodes.add(code);
            return code == 'ar'
                ? FakeCourseCatalog.arabic()
                : FakeCourseCatalog();
          };

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'es',
              minutes: 12,
              days: {'2026-11-19': 1},
              languages: ['es', 'ar'],
            ),
            PalabrasStore.storageKeyFor('es'): _storeJson(
              words: {'casa': _wordRecord('casa')},
            ),
            PalabrasStore.storageKeyFor('ar'): _storeJson(
              words: {'بيت': _wordRecord('بيت')},
            ),
          },
        );

        // Open Words tab so Spanish tab state is alive before switching.
        await app.openTab('words');
        expect(app.selectedTab, 'words');
        expect(find.text('casa'), findsWidgets);

        // Switch es -> ar through the progress setting (as LanguagesSheet does).
        app.services.progress.setSetting('idioma', 'ar');
        await app.settle(rounds: 15);

        expect(loadedCodes, ['es', 'ar']);
        expect(app.selectedTab, 'map');
        expect(app.services.course.language.code, 'ar');
        expect(
          (jsonDecode(app.sharedStored!) as Map<String, dynamic>)['idioma'],
          'ar',
        );
        expect(find.text('المطر'), findsWidgets);
        expect(find.text('La lluvia'), findsNothing);

        await app.openTab('words');
        expect(find.text('بيت'), findsWidgets);
        expect(find.text('casa'), findsNothing);

        // Switch ar -> es; Spanish store's stale 'idioma' must be synced so it
        // does not bounce back to Arabic on subsequent saves.
        app.services.progress.setSetting('idioma', 'es');
        await app.settle(rounds: 15);

        expect(loadedCodes, ['es', 'ar', 'es']);
        expect(app.selectedTab, 'map');
        expect(app.services.course.language.code, 'es');
        expect(
          (jsonDecode(app.sharedStored!) as Map<String, dynamic>)['idioma'],
          'es',
        );
        expect(find.text('La lluvia'), findsWidgets);
        expect(find.text('المطر'), findsNothing);

        // Trigger another write on Spanish progress and confirm no bounce-back.
        app.services.progress.setSetting('min', 45);
        await app.settle(rounds: 10);
        expect(loadedCodes, ['es', 'ar', 'es']);
        expect(app.services.course.language.code, 'es');
        expect(app.services.progress.minutes, 12);
        expect(app.services.progress.streak, 1);

        await app.openTab('words');
        expect(find.text('casa'), findsWidgets);
        expect(find.text('بيت'), findsNothing);
      },
    );

    testWidgets(
      'AppShell discards stale stateful tab subtrees when Services change',
      (tester) async {
        final spanish = FakeCourseCatalog();
        await spanish.load();
        final arabic = FakeCourseCatalog.arabic();
        await arabic.load();

        final nav = ShellNavigator();
        final router = GoRouter(
          initialLocation: '/tab/map',
          routes: [
            GoRoute(
              path: '/tab/:id',
              builder: (_, _) => const SizedBox.shrink(),
            ),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(nav.dispose);
        nav.router = router;

        final created = <String, List<int>>{};
        final disposed = <String, List<int>>{};
        List<FeatureModule> makeModules() => [
          for (final id in NocheTabs.order)
            _ProbeModule(
              id,
              tabBuilder: (_, s) => _StatefulProbe(
                label: '${s.course.language.code}:$id',
                onInit: (n) => created.putIfAbsent(id, () => []).add(n),
                onDispose: (n) => disposed.putIfAbsent(id, () => []).add(n),
              ),
            ),
        ];

        final modules = makeModules();
        Future<void> pumpShell(Services s, AppRoute route) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: AppShell(
                  services: s,
                  modules: modules,
                  nav: nav,
                  route: route,
                ),
              ),
            ),
          );
          await tester.pump();
        }

        final esServices = fakeServices(course: spanish, nav: nav);
        await pumpShell(esServices, const TabRoute('map'));
        final firstMapId = created['map']!.single;
        expect(find.text('es:map:$firstMapId:0'), findsOneWidget);
        await tester.tap(find.text('es:map:$firstMapId:0'));
        await tester.pump();
        expect(find.text('es:map:$firstMapId:1'), findsOneWidget);

        await pumpShell(esServices, const TabRoute('me'));
        final firstMeId = created['me']!.single;
        expect(find.text('es:me:$firstMeId:0'), findsOneWidget);

        // Swap to a new Services instance (new language).
        final arServices = fakeServices(course: arabic, nav: nav);
        await pumpShell(arServices, const TabRoute('map'));

        expect(disposed['map'], contains(firstMapId));
        expect(disposed['me'], contains(firstMeId));
        expect(created['map']!.length, 2);
        final secondMapId = created['map']!.last;
        expect(secondMapId, isNot(firstMapId));
        expect(find.text('ar:map:$secondMapId:0'), findsOneWidget);
        expect(find.text('es:map:$firstMapId:1'), findsNothing);
      },
    );
  });

  group('directionality', () {
    test('isLessonRoute classifies every AppRoute variant', () {
      const lessonRoutes = <AppRoute>[
        StoryRoute('la-lluvia'),
        StoryRoute('la-lluvia', listen: true),
        ReviewRoute(),
        ReviewRoute(practice: true),
        LevelCheckRoute(),
        BookRoute('la-lluvia'),
        CallRoute('casa'),
        VoiceTestRoute(),
      ];
      const chromeRoutes = <AppRoute>[
        TabRoute('library'),
        TabRoute('words'),
        TabRoute('map'),
        TabRoute('speak'),
        TabRoute('me'),
        PlaceRoute('casa'),
        LanguagesRoute(),
        PlansRoute(),
        ImportRoute(),
      ];

      for (final route in lessonRoutes) {
        expect(isLessonRoute(route), isTrue, reason: '$route');
      }
      for (final route in chromeRoutes) {
        expect(isLessonRoute(route), isFalse, reason: '$route');
      }
    });

    testWidgets(
      'RTL course sets TextDirection.rtl on every lesson route while keeping all 5 tabs, NocheTabBar, and non-lesson routes LTR',
      (tester) async {
        final arabic = FakeCourseCatalog.arabic();
        await arabic.load();

        final nav = ShellNavigator();
        final router = GoRouter(
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
        addTearDown(router.dispose);
        addTearDown(nav.dispose);
        nav.router = router;

        final tabDirections = <String, TextDirection>{};
        final routeDirections = <AppRoute, TextDirection>{};

        Widget directionCapture(
          String keyName,
          void Function(TextDirection dir) record,
        ) => Builder(
          key: ValueKey(keyName),
          builder: (context) {
            record(Directionality.of(context));
            return Center(child: Text(keyName));
          },
        );

        final modules = <FeatureModule>[
          for (final id in NocheTabs.order)
            _ProbeModule(
              id,
              tabBuilder: (_, _) =>
                  directionCapture('tab:$id', (d) => tabDirections[id] = d),
              onRoute: id != NocheTabs.map
                  ? null
                  : (route, _) => route is TabRoute
                        ? null
                        : directionCapture(
                            'route:${route.runtimeType}',
                            (d) => routeDirections[route] = d,
                          ),
            ),
        ];
        final services = fakeServices(course: arabic, nav: nav);
        nav.answers = (r) =>
            modules.any((m) => m.screenFor(r, services) != null);

        Future<void> pumpRoute(AppRoute route) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: AppShell(
                  services: services,
                  modules: modules,
                  nav: nav,
                  route: route,
                ),
              ),
            ),
          );
          await tester.pump();
        }

        // All 5 tabs + NocheTabBar stay LTR.
        for (final id in NocheTabs.order) {
          await pumpRoute(TabRoute(id));
          expect(tabDirections[id], TextDirection.ltr, reason: 'tab $id');
          expect(
            Directionality.of(tester.element(find.byType(NocheTabBar))),
            TextDirection.ltr,
            reason: 'NocheTabBar on tab $id',
          );
        }

        // Non-lesson overlay/detail routes stay LTR.
        const nonLessonRoutes = <AppRoute>[
          PlaceRoute('casa'),
          LanguagesRoute(),
          PlansRoute(),
          ImportRoute(),
        ];
        for (final route in nonLessonRoutes) {
          await pumpRoute(route);
          expect(
            routeDirections[route],
            TextDirection.ltr,
            reason: 'non-lesson route $route',
          );
        }

        // All 6 lesson routes get RTL.
        const lessonRoutes = <AppRoute>[
          StoryRoute('la-lluvia'),
          ReviewRoute(),
          LevelCheckRoute(),
          BookRoute('la-lluvia'),
          CallRoute('casa'),
          VoiceTestRoute(),
        ];
        for (final route in lessonRoutes) {
          await pumpRoute(route);
          expect(
            routeDirections[route],
            TextDirection.rtl,
            reason: 'lesson route $route',
          );
        }
      },
    );

    testWidgets(
      'LTR course keeps both lesson routes and tabs TextDirection.ltr',
      (tester) async {
        final spanish = FakeCourseCatalog();
        await spanish.load();

        final nav = ShellNavigator();
        final router = GoRouter(
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
            ])
              GoRoute(path: path, builder: (_, _) => const SizedBox.shrink()),
          ],
        );
        addTearDown(router.dispose);
        addTearDown(nav.dispose);
        nav.router = router;

        final tabDirections = <String, TextDirection>{};
        final lessonDirections = <AppRoute, TextDirection>{};

        final modules = <FeatureModule>[
          for (final id in NocheTabs.order)
            _ProbeModule(
              id,
              tabBuilder: (context, _) {
                tabDirections[id] = Directionality.of(context);
                return Center(child: Text('tab:$id'));
              },
              onRoute: id != NocheTabs.map
                  ? null
                  : (route, _) => route is TabRoute
                        ? null
                        : Builder(
                            builder: (context) {
                              lessonDirections[route] = Directionality.of(
                                context,
                              );
                              return Center(child: Text('$route'));
                            },
                          ),
            ),
        ];
        final services = fakeServices(course: spanish, nav: nav);
        nav.answers = (r) =>
            modules.any((m) => m.screenFor(r, services) != null);

        Future<void> pumpRoute(AppRoute route) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: AppShell(
                  services: services,
                  modules: modules,
                  nav: nav,
                  route: route,
                ),
              ),
            ),
          );
          await tester.pump();
        }

        for (final id in NocheTabs.order) {
          await pumpRoute(TabRoute(id));
          expect(tabDirections[id], TextDirection.ltr, reason: 'tab $id');
        }
        for (final route in const <AppRoute>[
          StoryRoute('la-lluvia'),
          ReviewRoute(),
          LevelCheckRoute(),
          BookRoute('la-lluvia'),
          CallRoute('casa'),
          VoiceTestRoute(),
        ]) {
          await pumpRoute(route);
          expect(lessonDirections[route], TextDirection.ltr, reason: '$route');
        }
      },
    );

    testWidgets(
      'end-to-end CoquiApp with Arabic course keeps Map and Me tabs LTR while StoryRoute is RTL',
      (tester) async {
        final app = TestApp(tester)
          ..loadCourse = (_) async => FakeCourseCatalog.arabic();

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'ar',
              languages: ['ar'],
            ),
            PalabrasStore.storageKeyFor('ar'): _storeJson(),
          },
          speechAvailable: false,
        );

        expect(app.selectedTab, 'map');
        expect(
          Directionality.of(tester.element(find.byType(NocheTabBar))),
          TextDirection.ltr,
        );
        expect(
          Directionality.of(tester.element(findMapTopChips())),
          TextDirection.ltr,
        );

        await app.openTab('me');
        expect(app.selectedTab, 'me');
        expect(
          Directionality.of(
            tester.element(find.byKey(const Key('yo-level-check'))),
          ),
          TextDirection.ltr,
        );

        await app.go(const StoryRoute('la-lluvia'));
        await app.until(
          () => byTypeName('StoryScreen').evaluate().isNotEmpty,
          what: 'StoryScreen',
        );
        expect(
          Directionality.of(tester.element(byTypeName('StoryScreen'))),
          TextDirection.rtl,
        );

        // Drain any clip playback timer started by opening the story.
        await app.advance(5000);
      },
    );
  });
}
