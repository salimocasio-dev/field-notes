// The dev entry: feature_map alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//   flutter build web -t tool/dev_main.dart --no-web-resources-cdn
//
// What the address says (all optional):
//   ?demo=none|three|all   mapa.html's three states: nothing done / places 1 to 3 done / all ten done (the default
//                          is none). With `demo`, places 4 and up have made-up stories, so they can be done.
//   ?seed=vacio|segunda|uno|curso|casi|todo   the stored progress of a reference picture of v=39
//                          (coqui/ref/pantallas/seeds), on the course v=39 has: places 1 to 3 built.
//   &todo=1                "Open every place" is on.
//   &place=1..10           once the map is up, go to that place as if it had been tapped.
//   &reduce=1              reduceMotion: everything stands still.
//   &review=0              the Today card has no review entry (the screen is given no title for it).
//   &chip=0                no corner chip (for screenshots).
//
// The corner chip shows the bake time and the slowest frame, in ms, as the screen measured them.
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:material_ui/material_ui.dart';

import 'map_fixture.dart';

/// The dev entry's root widget, for the address [query].
Widget devApp([Map<String, String> query = const {}]) =>
    MapDevApp(query: query);

void main() => runApp(devApp(Uri.base.queryParameters));

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Coqui map',
      theme: coquiTheme(),
      home: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            MapScreen(
              services: fixtureState.services,
              perf: perf,
              reviewTitle: q['review'] == '0' ? null : fixtureReviewTitle,
              openPlace: place == null ? null : place - 1,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: CoquiTabBar(selectedId: CoquiTabs.mapId, onTap: (_) {}),
            ),
            if (q['chip'] != '0')
              Positioned(
                top: 4,
                right: 4,
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
      color: const Color(0xCC000000),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'bake ${perf.bakeMs.toStringAsFixed(0)} ms · frame max ${perf.slowestFrameMs.toStringAsFixed(1)} ms',
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 11,
          decoration: TextDecoration.none,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}
