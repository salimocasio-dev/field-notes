// The dev entry's root widget (tool/dev_main.dart runs it). It lives here so that the tests can run it in a
// browser too: `flutter test --platform chrome` loads nothing outside test/.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:feature_map/src/motion.dart';
import 'package:feature_map/src/place_screen.dart';
import 'package:feature_map/src/wording.dart';
import 'package:material_ui/material_ui.dart';

import 'map_fixture.dart';

/// The dev entry's root widget, for the address [query].
Widget devApp([Map<String, String> query = const {}]) =>
    MapDevApp(query: query);

class _DevNavigator implements AppNavigator {
  _DevNavigator(this.onRoute, this.onBack);

  final ValueChanged<AppRoute> onRoute;
  final VoidCallback onBack;

  @override
  void go(AppRoute route) => onRoute(route);

  @override
  void back() => onBack();
}

class MapDevApp extends StatefulWidget {
  const MapDevApp({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  State<MapDevApp> createState() => _MapDevAppState();
}

class _MapDevAppState extends State<MapDevApp> {
  final perf = MapPerf();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final HeroController _heroController = HeroController();
  late final MapFixture fixtureState;
  late final Services services;
  late final Entitlements _entitlements;
  FakeEntitlements? _ownedFakeEntitlements;
  String? _initialPlaceId;
  bool _atPlace = false;

  @override
  void initState() {
    super.initState();
    final q = widget.query;
    switch (q['plan']) {
      case 'free':
        _entitlements = _ownedFakeEntitlements = FakeEntitlements(
          plan: Plan.free,
        );
      case 'course':
        _entitlements = _ownedFakeEntitlements = FakeEntitlements(
          plan: Plan.course,
        );
      case 'calls':
        _entitlements = _ownedFakeEntitlements = FakeEntitlements(
          plan: Plan.courseAndCalls,
        );
      default:
        _entitlements = const AllowAllEntitlements();
    }
    final reduce =
        q['reduce'] == '1' ||
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    final seed = q['seed'];
    fixtureState = seed != null
        ? fixture(seed: seed, todo: q['todo'] == '1', reduceMotion: reduce)
        : fixtureDemoWith(q['demo'] ?? 'none', reduceMotion: reduce);
    if (seed == null && q['todo'] == '1') {
      fixtureState.progress.setSetting('todo', 1);
    }
    final base = fixtureState.services;
    services = Services(
      progress: base.progress,
      course: base.course,
      clips: base.clips,
      speech: base.speech,
      call: base.call,
      nav: _DevNavigator(_onRoute, _onBack),
      clock: base.clock,
      rng: base.rng,
      haptics: base.haptics,
      info: base.info,
      pictures: base.pictures,
      storage: base.storage,
      entitlements: _entitlements,
      reduceMotion: base.reduceMotion,
    );
    final rawPlace = q['place'];
    if (rawPlace != null && rawPlace.isNotEmpty) {
      final placeNum = int.tryParse(rawPlace);
      if (placeNum == null) {
        _initialPlaceId = rawPlace;
        _atPlace = true;
      } else {
        unawaited(_resolveInitialPlace(placeNum));
      }
    }
  }

  Future<void> _resolveInitialPlace(int placeNum) async {
    await services.course.load();
    if (!mounted) return;
    final places = services.course.places;
    final idx = placeNum - 1;
    if (idx >= 0 && idx < places.length) {
      _pushPlace(places[idx].id);
    }
  }

  PageRoute<void> _mapRoute(BuildContext context) {
    final q = widget.query;
    return buildNocheMapRoute<void>(
      context: context,
      serviceReduceMotion: services.reduceMotion,
      settings: const RouteSettings(name: 'map'),
      builder: (_) => MapScreen(
        services: services,
        perf: perf,
        reviewTitle: q['review'] == '0' ? null : MapWording.reviewTitle,
        entitlements: _entitlements,
      ),
    );
  }

  PageRoute<void> _placeRoute(BuildContext context, String placeId) {
    return buildNocheMapRoute<void>(
      context: context,
      serviceReduceMotion: services.reduceMotion,
      settings: RouteSettings(name: 'place:$placeId'),
      builder: (_) => PlaceScreen(
        key: ValueKey(PlaceRoute(placeId)),
        placeId: placeId,
        services: services,
        entitlements: _entitlements,
      ),
    );
  }

  void _pushPlace(String placeId) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    final route = _placeRoute(nav.context, placeId);
    if (_atPlace) {
      unawaited(
        nav.pushReplacement(route).whenComplete(() {
          if (mounted) _atPlace = nav.canPop();
        }),
      );
    } else {
      _atPlace = true;
      unawaited(
        nav.push(route).whenComplete(() {
          if (mounted) _atPlace = nav.canPop();
        }),
      );
    }
  }

  void _popToMap() {
    final nav = _navKey.currentState;
    if (nav == null || !nav.canPop()) return;
    nav.popUntil((r) => r.isFirst);
    _atPlace = false;
  }

  void _onRoute(AppRoute route) {
    fixtureState.nav.go(route);
    if (!mounted) return;
    if (route is PlaceRoute) {
      _pushPlace(route.placeId);
    } else if (route is TabRoute && route.tab == NocheTabs.map) {
      _popToMap();
    }
  }

  void _onBack() {
    fixtureState.nav.back();
    if (!mounted) return;
    final nav = _navKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
  }

  @override
  void dispose() {
    _heroController.dispose();
    _ownedFakeEntitlements?.dispose();
    perf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final lang = services.course.language;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui map',
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Builder(
              builder: (navContext) => Navigator(
                key: _navKey,
                observers: [_heroController],
                onGenerateInitialRoutes: (navigator, initialRoute) {
                  final routes = <Route<dynamic>>[_mapRoute(navContext)];
                  final placeId = _initialPlaceId;
                  if (placeId != null) {
                    routes.add(_placeRoute(navContext, placeId));
                  }
                  return routes;
                },
                onGenerateRoute: (settings) => _mapRoute(navContext),
              ),
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
                onTap: (id) {
                  if (id == NocheTabs.map) {
                    _popToMap();
                  }
                },
              ),
            ),
            if (q['chip'] != '0')
              PositionedDirectional(
                top: 4,
                end: 4,
                child: ListenableBuilder(
                  listenable: perf,
                  builder: (context, _) => _PerfChip(perf),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PerfChip extends StatelessWidget {
  const _PerfChip(this.perf);

  final MapPerf perf;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('perf-chip'),
    decoration: BoxDecoration(
      color: NocheColors.panel,
      border: Border.all(color: NocheColors.line, width: 1),
      borderRadius: BorderRadius.circular(NocheSize.grid),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: NocheSize.grid,
        vertical: 4,
      ),
      child: Text(
        'bake ${perf.bakeMs.toStringAsFixed(0)} ms · frame max ${perf.slowestFrameMs.toStringAsFixed(1)} ms · mean ${perf.meanFrameMs.toStringAsFixed(1)} ms',
        style: NocheType.bodySmall.copyWith(color: NocheColors.text),
      ),
    ),
  );
}
