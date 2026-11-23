// The dev entry: feature_library alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//
// It starts on Biblioteca, like the tab with its tab bar under it; Read opens the text reader, whose X comes back.
//
//   ?seed=vacio|curso|casi|todo   the progress to start with (the seeds of ref/pantallas/seeds/; default curso). On
//                                 curso every word of the story plots is also known, so a story can be made
//   &screen=shelf|book            Biblioteca (default) or a book's text
//   &book=la-lluvia               which book (the sample course has this one)
//   &speed=40                     the clips play this many times faster than their length (default 1)
//   &big=1                        the large text (24 px)
//   &tab=0                        without the tab bar
//   &content=real                 the real files of historia/ (served under assets/content/)
import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_catalog.dart';
import 'dev_clips.dart';
import 'dev_seeds.dart';

/// What the address asks for.
class DevOptions {
  const DevOptions({
    this.seed = 'curso',
    this.screen = 'shelf',
    this.book = 'la-lluvia',
    this.speed = 1,
    this.big = false,
    this.tabBar = true,
    this.real = false,
  });

  factory DevOptions.fromQuery(Map<String, String> q) => DevOptions(
    seed: q['seed'] ?? 'curso',
    screen: q['screen'] ?? 'shelf',
    book: q['book'] ?? 'la-lluvia',
    speed: double.tryParse(q['speed'] ?? '') ?? 1,
    big: q['big'] == '1',
    tabBar: q['tab'] != '0',
    real: q['content'] == 'real',
  );

  final String seed;
  final String screen;
  final String book;
  final double speed;
  final bool big;
  final bool tabBar;
  final bool real;
}

/// Goes where the feature asks: a book opens the reader, back returns to Biblioteca; the other routes are only named.
class DevNavigator implements AppNavigator {
  final ValueNotifier<AppRoute?> current = ValueNotifier(null);
  final ValueNotifier<AppRoute?> elsewhere = ValueNotifier(null);

  @override
  void go(AppRoute route) {
    if (route is BookRoute) {
      current.value = route;
    } else {
      elsewhere.value = route;
    }
  }

  @override
  void back() => current.value = null;
}

/// The dev entry's root widget: the module on the fakes, started in the state [options] name.
Widget devApp({DevOptions options = const DevOptions()}) =>
    _DevApp(options: options);

void main() =>
    runApp(devApp(options: DevOptions.fromQuery(Uri.base.queryParameters)));

class _Dev {
  _Dev(this.services, this.nav);
  final Services services;
  final DevNavigator nav;
}

class _DevApp extends StatefulWidget {
  const _DevApp({required this.options});
  final DevOptions options;

  @override
  State<_DevApp> createState() => _DevAppState();
}

class _DevAppState extends State<_DevApp> {
  late final Future<_Dev> _ready = _setup();

  Future<_Dev> _setup() async {
    final o = widget.options;
    final clock = FakeClock();
    final progress = FakeProgressStore(clock: clock);
    final seed = devSeeds[o.seed];
    if (seed != null) progress.import(seed);
    if (!o.real && o.screen == 'shelf' && o.seed == 'curso') {
      final generator = await StoryGenerator.load();
      final snapshot = progress.raw;
      final vocabulary = {
        for (final plot in generator.plots)
          for (final beat in plot.beats)
            for (final option in beat) ...readingWords(option),
      };
      progress.import(
        jsonEncode({
          ...snapshot,
          'palabras': {
            ...?snapshot['palabras'] as Map?,
            for (final token in vocabulary)
              token: WordRecord(
                w: token,
                primera: clock.nowMs(),
                ear: SkillRecord(etapa: 4),
              ).toJson(),
          },
        }),
      );
    }
    final course = o.real ? RealCatalog() : DevCatalog();
    await course.load();
    final nav = DevNavigator();
    final services = fakeServices(
      progress: progress,
      course: course,
      clock: clock,
      nav: nav,
      clips: DevClips(
        speed: o.speed,
        lengthOf: (id) {
          final c = course.clip(id);
          return c == null ? null : c.endMs - c.startMs;
        },
      ),
    );
    if (o.big) await services.storage('leer').write('tam', '24');
    if (o.screen == 'book') nav.current.value = BookRoute(o.book);
    return _Dev(services, nav);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Coqui dev: feature_library',
    theme: coquiTheme(),
    home: FutureBuilder<_Dev>(
      future: _ready,
      builder: (context, snap) {
        final dev = snap.data;
        if (dev == null) return const ColoredBox(color: CoquiColors.bg);
        return _Host(dev: dev, options: widget.options);
      },
    ),
  );
}

class _Host extends StatelessWidget {
  const _Host({required this.dev, required this.options});

  final _Dev dev;
  final DevOptions options;

  @override
  Widget build(BuildContext context) {
    const module = LibraryModule();
    return ValueListenableBuilder<AppRoute?>(
      valueListenable: dev.nav.current,
      builder: (context, route, _) {
        if (route is BookRoute) return module.screenFor(route, dev.services)!;
        return Stack(
          children: [
            Positioned.fill(child: ReadingHome(services: dev.services)),
            if (options.tabBar)
              Align(
                alignment: Alignment.bottomCenter,
                child: CoquiTabBar(
                  selectedId: CoquiTabs.libraryId,
                  onTap: (_) {},
                ),
              ),
            ValueListenableBuilder<AppRoute?>(
              valueListenable: dev.nav.elsewhere,
              builder: (context, r, _) => r == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => dev.nav.elsewhere.value = null,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(12),
                          color: CoquiColors.ink,
                          child: Text('$r', style: CoquiText.button),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
