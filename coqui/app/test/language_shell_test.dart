// Multi-language shell wiring (N2.11): startup language loading, switching
// between languages with fresh module state, and lesson RTL vs chrome LTR.
import 'dart:async';
import 'dart:convert';

import 'package:app/src/app.dart';
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
        expect(findShellTab('map'), findsOneWidget);
        expect(findMapUpNextCard(), findsOneWidget);

        await app.openTab('words');
        expect(findShellTab('words'), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:بيت')), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:casa')), findsNothing);
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
        expect(findShellTab('map'), findsOneWidget);
        expect(find.byKey(const Key('streak-chip')), findsOneWidget);
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

        // Shared minutes added in Spanish persist to coqui.shared.v1 and survive switching to Arabic.
        app.services.progress.addMinutes(1.0);
        await app.settle(rounds: 5);
        final beforeSwitchShared =
            jsonDecode(app.sharedStored!) as Map<String, dynamic>;
        expect(beforeSwitchShared['minutos'], 21);

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
        expect(app.services.progress.minutes, 21);
        final afterSwitchShared =
            jsonDecode(app.sharedStored!) as Map<String, dynamic>;
        expect(afterSwitchShared['minutos'], 21);
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

        final esTitle = app.services.course.meta('la-lluvia')!.title;
        final esMapCardEl = tester.element(findMapUpNextCard());
        expect(
          find.descendant(
            of: findShellTab('map'),
            matching: find.text(esTitle),
          ),
          findsWidgets,
        );

        // Open Words tab so Spanish tab state is alive before switching.
        await app.openTab('words');
        expect(app.selectedTab, 'words');
        expect(findShellTab('words'), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:casa')), findsOneWidget);

        // Switch es -> ar through the progress setting (as LanguagesSheet does).
        app.services.progress.setSetting('idioma', 'ar');
        await app.settle(rounds: 15);

        expect(loadedCodes, ['es', 'ar']);
        expect(app.selectedTab, 'map');
        expect(findShellTab('map'), findsOneWidget);
        expect(app.services.course.language.code, 'ar');
        expect(
          tester.widget<NocheTabBar>(find.byType(NocheTabBar)).languageCode,
          'ar',
        );
        expect(
          (jsonDecode(app.sharedStored!) as Map<String, dynamic>)['idioma'],
          'ar',
        );
        final arTitle = app.services.course.meta('la-lluvia')!.title;
        expect(arTitle, isNot(esTitle));
        final arMapCardEl = tester.element(findMapUpNextCard());
        expect(identical(esMapCardEl, arMapCardEl), isFalse);
        expect(
          find.descendant(
            of: findShellTab('map'),
            matching: find.text(arTitle),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: findShellTab('map'),
            matching: find.text(esTitle),
          ),
          findsNothing,
        );
        expect(app.services.progress.words.map((w) => w.w), contains('بيت'));
        expect(
          app.services.progress.words.map((w) => w.w),
          isNot(contains('casa')),
        );

        await app.openTab('words');
        expect(findShellTab('words'), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:بيت')), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:casa')), findsNothing);

        // Switch ar -> es; Spanish store's stale 'idioma' must be synced so it
        // does not bounce back to Arabic on subsequent saves.
        app.services.progress.setSetting('idioma', 'es');
        await app.settle(rounds: 15);

        expect(loadedCodes, ['es', 'ar', 'es']);
        expect(app.selectedTab, 'map');
        expect(findShellTab('map'), findsOneWidget);
        expect(app.services.course.language.code, 'es');
        expect(
          tester.widget<NocheTabBar>(find.byType(NocheTabBar)).languageCode,
          'es',
        );
        expect(
          (jsonDecode(app.sharedStored!) as Map<String, dynamic>)['idioma'],
          'es',
        );
        final backToEsTitle = app.services.course.meta('la-lluvia')!.title;
        expect(backToEsTitle, esTitle);
        final backToEsMapCardEl = tester.element(findMapUpNextCard());
        expect(identical(arMapCardEl, backToEsMapCardEl), isFalse);
        expect(
          find.descendant(
            of: findShellTab('map'),
            matching: find.text(backToEsTitle),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: findShellTab('map'),
            matching: find.text(arTitle),
          ),
          findsNothing,
        );
        expect(app.services.progress.words.map((w) => w.w), contains('casa'));
        expect(
          app.services.progress.words.map((w) => w.w),
          isNot(contains('بيت')),
        );

        // Trigger another write on Spanish progress and confirm no bounce-back.
        app.services.progress.setSetting('min', 45);
        await app.settle(rounds: 10);
        expect(loadedCodes, ['es', 'ar', 'es']);
        expect(app.services.course.language.code, 'es');
        expect(app.services.progress.minutes, 12);
        expect(app.services.progress.streak, 1);

        await app.openTab('words');
        expect(findShellTab('words'), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:casa')), findsOneWidget);
        expect(find.byKey(const ValueKey('word-row:بيت')), findsNothing);
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
          () =>
              findShellRoute(const StoryRoute('la-lluvia'))
                  .evaluate()
                  .isNotEmpty,
          what: 'StoryRoute(la-lluvia)',
        );
        expect(
          Directionality.of(
            tester.element(findShellRoute(const StoryRoute('la-lluvia'))),
          ),
          TextDirection.rtl,
        );

        // Drain any clip playback timer started by opening the story.
        await app.advance(5000);
      },
    );
  });

  group('audio cache isolation and fallback', () {
    testWidgets(
      'shared audio cache isolates recordings and in-flight loads when switching courses that reuse clip ids',
      (tester) async {
        final core = _SharedAudioCore();
        final spanishPendingLoad = Completer<void>();

        final app = TestApp(tester)
          ..loadCourse = (code) async {
            return code == 'ar'
                ? FakeCourseCatalog.arabic()
                : FakeCourseCatalog();
          }
          ..clipPlayerFactory = (lookup) => _SharedCacheClipPlayer(
            core: core,
            clipInfo: lookup,
            delayLoad: (scopedId) =>
                scopedId == 'es::mira_casa' ? spanishPendingLoad.future : null,
          );

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'es',
              languages: ['es', 'ar'],
            ),
            PalabrasStore.storageKeyFor('es'): _storeJson(),
            PalabrasStore.storageKeyFor('ar'): _storeJson(),
          },
        );

        // Preload & play a shared clip id in Spanish, and start an in-flight
        // load for another shared clip id before switching languages.
        final spanishClips = app.services.clips;
        expect(await spanishClips.preload(['esta_casa', 'missing_clip']), [
          'missing_clip',
        ]);
        expect(await spanishClips.play('esta_casa'), isTrue);
        expect(core.playedRecordings.last, contains('casa'));

        final inFlightSpanish = spanishClips.preload(['mira_casa']);

        // Switch to Arabic while the Spanish load is still in flight.
        final stores = ProgressStores(app.spaces.kv, app.clock);
        addTearDown(stores.dispose);
        stores.currentLanguageCode = 'ar';
        await app.settle(rounds: 15);
        expect(app.services.course.language.code, 'ar');

        // Resolve the stale Spanish load after switching; it must not pollute
        // Arabic's clip cache for the same clip id.
        spanishPendingLoad.complete();
        await inFlightSpanish;

        final arabicClips = app.services.clips;
        expect(
          await arabicClips.preload(['esta_casa', 'mira_casa', 'missing_clip']),
          ['missing_clip'],
        );
        expect(await arabicClips.play('esta_casa'), isTrue);
        expect(core.playedRecordings.last, contains('بيت'));
        expect(await arabicClips.play('mira_casa'), isTrue);
        expect(core.playedRecordings.last, contains('بيت'));
      },
    );

    testWidgets(
      'unknown language code falls back to Spanish and updates shared idioma without trapping on LoadFailed',
      (tester) async {
        final loadedCodes = <String>[];
        final app = TestApp(tester)
          ..loadCourse = (code) async {
            loadedCodes.add(code);
            if (code == 'es') return FakeCourseCatalog();
            throw UnsupportedError('No course for "$code"');
          };

        await app.open(
          initialStorage: {
            PalabrasStore.sharedStorageKey: _sharedJson(
              languageCode: 'xx',
              languages: ['es'],
            ),
            PalabrasStore.storageKeyFor('es'): _storeJson(
              words: {'casa': _wordRecord('casa')},
            ),
          },
        );

        expect(loadedCodes, ['xx', 'es']);
        expect(app.services.course.language.code, 'es');
        expect(find.byKey(LoadFailed.retryKey), findsNothing);
        expect(app.tabBarShown, isTrue);
        expect(app.selectedTab, 'map');
        expect(
          (jsonDecode(app.sharedStored!) as Map<String, dynamic>)['idioma'],
          'es',
        );

        // Subsequent progress writes stay on Spanish without reloading 'xx'.
        app.services.progress.setSetting('min', 20);
        await app.settle(rounds: 10);
        expect(loadedCodes, ['xx', 'es']);
      },
    );

    testWidgets(
      'tapping initial LoadFailed retry does not consume first-tap audio unlock before a player exists',
      (tester) async {
        final app = TestApp(tester)..offline = true;
        await app.open(stored: seed('curso'));
        expect(find.byKey(LoadFailed.retryKey), findsOneWidget);
        expect(app.clips, isNull);

        // Tap retry while still offline (no ClipPlayer exists yet).
        await app.tap(find.byKey(LoadFailed.retryKey));
        await app.settle(rounds: 5);
        expect(app.clips, isNull);

        // Recover network and tap retry (still no player during the tap).
        app.offline = false;
        await app.tap(find.byKey(LoadFailed.retryKey));
        await app.settle(rounds: 10);
        expect(app.clips, isNotNull);
        expect(app.clips!.unlocked, isFalse);

        // The first tap once the player exists unlocks audio inside the gesture.
        await app.openTab('me');
        expect(app.clips!.unlocked, isTrue);
      },
    );
  });
}

/// Models `webSoundCore` from `coqui_platform`: one shared clip cache keyed by
/// clip id across every `ClipPlayer` created during the session.
class _SharedAudioCore {
  final Map<String, String> clips = {};
  final List<String> playedRecordings = [];
}

/// Models `GraphClipPlayer` on a shared [_SharedAudioCore]: checks `core.clips`
/// before consulting [clipInfo], and deduplicates in-flight loads by id.
class _SharedCacheClipPlayer implements ClipPlayer {
  _SharedCacheClipPlayer({
    required this.core,
    required this.clipInfo,
    this.delayLoad,
  });

  final _SharedAudioCore core;
  final ClipInfo? Function(String id) clipInfo;
  final Future<void>? Function(String scopedId)? delayLoad;
  final Map<String, Future<String?>> _loading = {};

  @override
  bool muted = false;

  @override
  Future<void> unlock() async {}

  Future<String?> _load(String id) {
    final cached = core.clips[id];
    if (cached != null) return Future.value(cached);
    final ongoing = _loading[id];
    if (ongoing != null) return ongoing;
    final future = _loading[id] = () async {
      final info = clipInfo(id);
      if (info == null) return null;
      final wait = delayLoad?.call(id);
      if (wait != null) await wait;
      return core.clips[id] = '${info.url}|${info.text}';
    }();
    unawaited(
      future.whenComplete(() {
        if (identical(_loading[id], future)) _loading.remove(id);
      }),
    );
    return future;
  }

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    final ids = {...clipIds}.toList();
    final loaded = await Future.wait([for (final id in ids) _load(id)]);
    return [
      for (var i = 0; i < ids.length; i++)
        if (loaded[i] == null) ids[i],
    ];
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    final recording = core.clips[clipId] ?? await _load(clipId);
    if (recording == null) return false;
    core.playedRecordings.add(recording);
    return true;
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) {}

  @override
  void noiseBurst({double vol = 1}) {}

  @override
  void loop(String name, bool on) {}

  @override
  Future<void> stop() async {}
}
