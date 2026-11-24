// The dev entry's root widget (tool/dev_main.dart runs it). It lives here so that the tests can run it in a
// browser too: `flutter test --platform chrome` loads nothing outside test/.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'map_fixture.dart';

/// The dev entry's root widget, for the address [query].
Widget devApp([Map<String, String> query = const {}]) =>
    MapDevApp(query: query);

class MapDevApp extends StatefulWidget {
  const MapDevApp({super.key, this.query = const {}});

  final Map<String, String> query;

  @override
  State<MapDevApp> createState() => _MapDevAppState();
}

class _MapDevAppState extends State<MapDevApp> {
  final perf = MapPerf();
  late final MapFixture fixtureState;

  @override
  void initState() {
    super.initState();
    final q = widget.query;
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
  }

  @override
  void dispose() {
    perf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    final place = int.tryParse(q['place'] ?? '');
    final lang = fixtureState.services.course.language;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui map',
      theme: coquiTheme(),
      home: Scaffold(
        backgroundColor: NocheColors.ground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MapScreen(
              services: fixtureState.services,
              perf: perf,
              reviewTitle: q['review'] == '0' ? null : 'Review',
              openPlace: place == null ? null : place - 1,
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
