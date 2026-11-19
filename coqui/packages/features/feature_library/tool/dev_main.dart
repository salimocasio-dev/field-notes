// The dev entry: feature_library alone, on the fakes.
//   flutter run -d chrome -t tool/dev_main.dart        (in this package)
//
// It starts on the shelf, like the Biblioteca tab with its tab bar under it; Read opens the reader, whose X and
// "Biblioteca" button come back. The address says which reference state to start in (coqui/ref/pantallas/):
//
//   ?seed=vacio|curso|casi|todo   the progress to start with (the seeds of ref/pantallas/seeds/; default curso)
//   &screen=shelf|book            the shelf (default) or a book
//   &book=la-lluvia               which book (the sample course has this one)
//   &page=3                       the page to open at, counted from 1
//   &hold=2                       hang the 2nd line of the page while it plays (it stays lit)
//   &speed=40                     the clips play this many times faster than their length (default 1)
//   &big=1                        the large text (24 px)
//   &card=1                       open with the card of the first picture word of the page
//   &scroll=end                   the shelf scrolled to its end
//   &tab=0                        the shelf without the tab bar
//   &content=real                 the real files of historia/ (served by tool/shots.mjs under assets/content/ and libros/)
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_library/src/images.dart';
import 'package:feature_library/src/reader.dart';
import 'package:feature_library/src/shelf.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'dev_catalog.dart';
import 'dev_clips.dart';
import 'dev_pictures.dart';
import 'dev_seeds.dart';

/// What the address asks for.
class DevOptions {
  const DevOptions({
    this.seed = 'curso',
    this.screen = 'shelf',
    this.book = 'la-lluvia',
    this.page = 1,
    this.hold,
    this.speed = 1,
    this.big = false,
    this.card = false,
    this.scrollEnd = false,
    this.tabBar = true,
    this.real = false,
  });

  factory DevOptions.fromQuery(Map<String, String> q) => DevOptions(
    seed: q['seed'] ?? 'curso',
    screen: q['screen'] ?? 'shelf',
    book: q['book'] ?? 'la-lluvia',
    page: int.tryParse(q['page'] ?? '') ?? 1,
    hold: int.tryParse(q['hold'] ?? ''),
    speed: double.tryParse(q['speed'] ?? '') ?? 1,
    big: q['big'] == '1',
    card: q['card'] == '1',
    scrollEnd: q['scroll'] == 'end',
    tabBar: q['tab'] != '0',
    real: q['content'] == 'real',
  );

  final String seed;
  final String screen;
  final String book;
  final int page;
  final int? hold;
  final double speed;
  final bool big;
  final bool card;
  final bool scrollEnd;
  final bool tabBar;
  final bool real;
}

/// Goes where the feature asks: a book opens the reader, back returns to the shelf; the other routes are only named.
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
  final _scroll = ScrollController();

  Future<_Dev> _setup() async {
    final o = widget.options;
    final clock = FakeClock();
    final progress = FakeProgressStore(clock: clock);
    final seed = devSeeds[o.seed];
    if (seed != null) progress.import(seed);
    final course = o.real ? RealCatalog() : DevCatalog();
    await course.load();
    final nav = DevNavigator();
    final services = fakeServices(
      progress: progress,
      course: course,
      clock: clock,
      nav: nav,
      pictures: devPictures(),
      clips: DevClips(
        speed: o.speed,
        hold: o.hold,
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

  // the page's height and where it is scrolled to, in the page's title, for the whole-page picture (tool/shots.mjs
  // cannot take a canvas as tall as the page in one picture: it scrolls and joins strips)
  bool _measure(Notification n) {
    if (n is ScrollMetricsNotification || n is ScrollNotification) {
      final m = n is ScrollMetricsNotification
          ? n.metrics
          : (n as ScrollNotification).metrics;
      if (m.axis != Axis.vertical) return false;
      unawaited(
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(
            label:
                'shelf-height=${(m.maxScrollExtent + m.viewportDimension).round()} scroll=${m.pixels.toStringAsFixed(1)}',
          ),
        ),
      );
      if (n is ScrollMetricsNotification &&
          widget.options.scrollEnd &&
          _scroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    }
    return false;
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
        return _Host(
          dev: dev,
          options: widget.options,
          scroll: _scroll,
          onMetrics: _measure,
        );
      },
    ),
  );
}

class _Host extends StatelessWidget {
  const _Host({
    required this.dev,
    required this.options,
    required this.scroll,
    required this.onMetrics,
  });

  final _Dev dev;
  final DevOptions options;
  final ScrollController scroll;
  final bool Function(Notification) onMetrics;

  // the first open of a book is at the page the address names; every later one from the shelf starts at page 1
  Widget _book(BookRoute route, {required bool first}) => BookReader(
    key: ValueKey('book:${route.id}'),
    services: dev.services,
    bookId: route.id,
    imageUrl: defaultBookImageUrl,
    startPage: first ? options.page - 1 : 0,
    startCard: first && options.card,
  );

  @override
  Widget build(BuildContext context) {
    final module = const LibraryModule();
    var first = options.screen == 'book';
    return ValueListenableBuilder<AppRoute?>(
      valueListenable: dev.nav.current,
      builder: (context, route, _) {
        if (route is BookRoute) {
          final isFirst = first;
          first = false;
          return Stack(
            children: [
              Positioned.fill(
                child: isFirst
                    ? _book(route, first: true)
                    : module.screenFor(route, dev.services)!,
              ),
            ],
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: NotificationListener<Notification>(
                onNotification: onMetrics,
                child: LibraryShelf(services: dev.services, controller: scroll),
              ),
            ),
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
