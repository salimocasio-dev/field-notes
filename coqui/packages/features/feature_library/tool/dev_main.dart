// The dev entry: feature_library alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//
// It starts on Biblioteca, like the tab with its tab bar under it; tapping an item opens the text reader, whose X comes back.
//
//   ?seed=vacio|curso|casi|todo   the progress to start with (the seeds of ref/pantallas/seeds/; default curso). On
//                                 curso every word of the story plots is also known, so a story can be made
//   &screen=shelf|book            Biblioteca (default) or a book's text
//   &shelf=empty|stories|both     pre-populated shelf items (default empty)
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
    this.shelf = 'empty',
    this.book = 'la-lluvia',
    this.speed = 1,
    this.big = false,
    this.tabBar = true,
    this.real = false,
  });

  factory DevOptions.fromQuery(Map<String, String> q) => DevOptions(
    seed: q['seed'] ?? 'curso',
    screen: q['screen'] ?? 'shelf',
    shelf: q['shelf'] ?? 'empty',
    book: q['book'] ?? 'la-lluvia',
    speed: double.tryParse(q['speed'] ?? '') ?? 1,
    big: q['big'] == '1',
    tabBar: q['tab'] != '0',
    real: q['content'] == 'real',
  );

  final String seed;
  final String screen;
  final String shelf;
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

  Future<void> _seedShelf(
    ReadingStore store,
    CourseCatalog course,
    int now,
    String mode,
  ) async {
    if (mode != 'stories' && mode != 'both') return;
    final generator = await StoryGenerator.load();
    var t = now + 1000;
    for (final plot in generator.plots.take(2)) {
      final body = [
        for (final beat in plot.beats)
          if (beat.isNotEmpty) beat.first,
      ].join('\n');
      final added = await store.add(
        now: t,
        title: plot.title,
        body: body,
        generated: true,
      );
      await store.markOpened(added.id, t);
      t += 1000;
    }
    if (mode == 'both') {
      final book = await course.book(widget.options.book);
      final story = await course.story(widget.options.book);
      final clips = story['clips'];
      final lines = <String>[];
      if (book != null && clips is Map) {
        for (final page in book.pages) {
          for (final id in page.clips) {
            if (clips[id] case {'text': final String text}
                when text.isNotEmpty) {
              lines.add(text);
            }
          }
        }
      }
      if (book != null && lines.isNotEmpty) {
        final added = await store.add(
          now: t,
          title: book.title,
          body: lines.join('\n'),
          generated: false,
        );
        await store.savePlace(
          added.id,
          ReadingPlace(page: 1, openedAt: t + 1000),
        );
      }
    }
  }

  Future<_Dev> _setup() async {
    final o = widget.options;
    final clock = FakeClock();
    final progress = FakeProgressStore(clock: clock);
    final seed = devSeeds[o.seed];
    if (seed != null) progress.import(seed);
    final course = o.real ? RealCatalog() : DevCatalog();
    await course.load();
    if (!o.real && o.screen == 'shelf' && o.seed == 'curso') {
      final generator = await StoryGenerator.load();
      final snapshot = progress.raw;
      final vocabulary = {
        for (final plot in generator.plots)
          for (final beat in plot.beats)
            for (final option in beat)
              ...readingWords(option, language: course.language),
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
    await _seedShelf(
      ReadingStore(services.storage(ReadingStore.space)),
      course,
      clock.nowMs(),
      o.shelf,
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
        if (dev == null) return const ColoredBox(color: NocheColors.ground);
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
    final language = dev.services.course.language;
    return ValueListenableBuilder<AppRoute?>(
      valueListenable: dev.nav.current,
      builder: (context, route, _) {
        if (route is BookRoute) return module.screenFor(route, dev.services)!;
        return ColoredBox(
          color: NocheColors.ground,
          child: Stack(
            children: [
              Positioned.fill(child: ReadingHome(services: dev.services)),
              if (options.tabBar)
                Align(
                  alignment: AlignmentDirectional.bottomCenter,
                  child: NocheTabBar(
                    selectedId: NocheTabs.library,
                    tabNames: language.tabNames,
                    script: language.script,
                    languageCode: language.code,
                    onTap: (_) {},
                  ),
                ),
              ValueListenableBuilder<AppRoute?>(
                valueListenable: dev.nav.elsewhere,
                builder: (context, r, _) => r == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: GestureDetector(
                          onTap: () => dev.nav.elsewhere.value = null,
                          child: Container(
                            margin: const EdgeInsetsDirectional.all(16),
                            padding: const EdgeInsetsDirectional.all(12),
                            color: NocheColors.panel,
                            child: Text(
                              '$r',
                              style: NocheType.button.copyWith(
                                color: NocheColors.text,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
