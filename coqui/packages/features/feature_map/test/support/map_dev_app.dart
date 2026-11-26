// The dev entry's root widget (tool/dev_main.dart runs it). It lives here so that the tests can run it in a
// browser too: `flutter test --platform chrome` loads nothing outside test/.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:feature_map/src/place_screen.dart';
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
  late final MapFixture fixtureState;
  late final Services services;
  late final Entitlements _entitlements;
  FakeEntitlements? _ownedFakeEntitlements;
  String? _activePlaceId;

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
        _activePlaceId = rawPlace;
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
      setState(() => _activePlaceId = places[idx].id);
    }
  }

  void _onRoute(AppRoute route) {
    fixtureState.nav.go(route);
    if (!mounted) return;
    if (route is PlaceRoute) {
      setState(() => _activePlaceId = route.placeId);
    } else if (route is TabRoute && route.tab == NocheTabs.map) {
      setState(() => _activePlaceId = null);
    }
  }

  void _onBack() {
    fixtureState.nav.back();
    if (!mounted) return;
    if (_activePlaceId != null) {
      setState(() => _activePlaceId = null);
    }
  }

  @override
  void dispose() {
    _ownedFakeEntitlements?.dispose();
    perf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final lang = services.course.language;
    final placeId = _activePlaceId;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui map',
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (placeId == null)
              MapScreen(
                services: services,
                perf: perf,
                reviewTitle: q['review'] == '0' ? null : 'Review',
                entitlements: _entitlements,
              )
            else
              PlaceScreen(
                key: ValueKey(PlaceRoute(placeId)),
                placeId: placeId,
                services: services,
                entitlements: _entitlements,
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
                  if (id == NocheTabs.map && _activePlaceId != null) {
                    setState(() => _activePlaceId = null);
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
