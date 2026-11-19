// The map tab on the fakes: a tap on an open place (the frog hops there, then the sheet), a tap on a locked
// place, a finished place (its flag, the frog moves on), the Today card, the story rows, reduceMotion.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_layout.dart';
import 'package:feature_map/src/map_perf.dart';
import 'package:feature_map/src/map_picture.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/map_fixture.dart';
import 'support/map_tester.dart';

/// What a test holds of the screen it started.
class Shown {
  Shown(this.f, this.perf);
  final MapFixture f;
  final MapPerf perf;
  late MapPicture picture;
}

/// The phone of ref/pantallas: 412 x 915 at 2.625 (or another size).
void phone(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  double dpr = 2.625,
}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
}

Future<Shown> showMap(
  WidgetTester tester,
  MapFixture f, {
  String? reviewTitle = CoquiLabels.reviewTitle,
  int? openPlace,
}) async {
  final shown = Shown(f, MapPerf());
  await tester.pumpWidget(
    MaterialApp(
      theme: coquiTheme(),
      home: Scaffold(
        body: MapScreen(
          services: f.services,
          perf: shown.perf,
          reviewTitle: reviewTitle,
          openPlace: openPlace,
          onPicture: (p) => shown.picture = p,
        ),
      ),
    ),
  );
  // the first frame shows the page colour; the bake follows it; then the course is read and the state laid on
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return shown;
}

/// Pumps [ms] of frames, 50 ms at a time (the screen never steps by more than 50 ms).
Future<void> run(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 50) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Where the stop of place [k] (0 to 9) is on the screen, with the map scrolled to put it near the top.
Future<Offset> stopPos(WidgetTester tester, int k) async {
  final view = find.byType(PixelView);
  final scrollable = tester.state<ScrollableState>(
    find.byType(Scrollable).first,
  );
  final topNow = tester.getTopLeft(view);
  final scale = tester.getSize(view).width / mapW;
  final p = MapPicture().stopOnPicture(k);
  final contentY =
      p.sy * scale; // from the picture's top, which is the scroll content's top
  final pos = scrollable.position;
  final want = (contentY - 150).clamp(pos.minScrollExtent, pos.maxScrollExtent);
  pos.jumpTo(want);
  await tester.pump();
  final top = tester.getTopLeft(view);
  expect(top.dx, topNow.dx);
  return top + Offset(p.sx * scale, p.sy * scale);
}

Future<void> tapStop(WidgetTester tester, int k) async {
  await tester.tapAt(await stopPos(tester, k));
  await tester.pump();
}

/// The place sheet is up: it is a route of the root navigator (`showCoquiSheet`), so it is there while it is
/// open and gone once it has slid out.
bool sheetOpen(WidgetTester tester) =>
    find.byType(CoquiSheet).evaluate().isNotEmpty;

/// The reddish pixels of the picture inside the rectangle where the flag of stop [k] is drawn.
int flagPixels(MapPicture m, int k) {
  final xy = XY(PADS[k][0] + .9, PADS[k][1] - .9);
  final a = m.e.project(xy.x, xy.y, 0),
      b = m.e.project(xy.x + .63, xy.y - .63, 1.7);
  var n = 0;
  for (var y = (b.sy - 6).floor(); y <= (a.sy + 2).ceil(); y++) {
    for (var x = (a.sx - 2).floor(); x <= (b.sx + 6).ceil(); x++) {
      final c = m.pix[y * mapW + x];
      final r = c & 255, g = c >> 8 & 255, bl = c >> 16 & 255;
      if (r > 150 && g < 100 && bl < 100) n++;
    }
  }
  return n;
}

void main() {
  mapTest('the page colour first, then the bake, then the map', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final perf = MapPerf();
    late MapPicture picture;
    // what the picture was when the first frame had been shown: this runs after that frame and before the
    // screen's own bake, which was asked for after it
    bool? bakedAtFirstFrame;
    var emptyAtFirstFrame = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: coquiTheme(),
        home: Scaffold(
          body: MapScreen(
            services: f.services,
            perf: perf,
            onPicture: (p) {
              picture = p;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                bakedAtFirstFrame = p.baked;
                emptyAtFirstFrame = p.pix.every((c) => c == 0);
              });
            },
          ),
        ),
      ),
    );
    expect(bakedAtFirstFrame, isFalse);
    expect(emptyAtFirstFrame, isTrue);
    await tester.pump();
    await tester.pump();
    expect(picture.baked, isTrue);
    expect(perf.bakeMs, greaterThan(0));
    expect(picture.pix.where((c) => c != 0).length, greaterThan(60000));
    expect(find.byType(PixelView), findsOneWidget);
  });

  mapTest(
    'tap an open place: the frog hops there, then the place sheet opens',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      final m = s.picture;
      expect(m.FROG.at, 0);
      expect(m.STATE.abierto.take(4), [true, true, true, false]);
      await tapStop(tester, 2);
      // hopping: the sheet is not open, the frog is on his way
      expect(m.FROG.path, isNotNull);
      expect(sheetOpen(tester), isFalse);
      expect(f.haptics.ticks, 1);
      await run(tester, 100);
      expect(sheetOpen(tester), isFalse);
      await run(tester, 3000);
      // landed: the frog is at place 3, the sheet is open on it
      expect(m.FROG.path, isNull);
      expect(m.FROG.at, 2);
      final stop = XY(PADS[2][0], PADS[2][1]);
      expect(m.FROG.x, closeTo(stop.x, 1e-9));
      expect(m.FROG.y, closeTo(stop.y, 1e-9));
      expect(sheetOpen(tester), isTrue);
      expect(find.text('La cocina'), findsWidgets);
      expect(
        find.text("Place 3 · The kitchen · a fork: either place first"),
        findsOneWidget,
      );
      // one hop sound for each landing, the old numbers
      final hops = route(0, 2);
      expect(f.clips.tones, isNotEmpty);
      expect(f.clips.tones.length, greaterThanOrEqualTo(hops.length - 1));
      for (final t in f.clips.tones) {
        expect(
          (t.hz, t.dur, t.wave, t.vol, t.toHz),
          (320.0, .07, 'square', .025, 520.0),
        );
      }
      // the place the course is at did not change: the chip still names place 1
      expect(find.text('1 · La casa'), findsOneWidget);
    },
  );

  mapTest(
    'a tap on a locked place opens the sheet at once and says it is locked',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      await tapStop(tester, 3);
      await run(tester, 300);
      expect(s.picture.FROG.path, isNull);
      expect(s.picture.FROG.at, 0); // he did not hop
      expect(f.clips.tones, isEmpty);
      expect(sheetOpen(tester), isTrue);
      expect(find.text('El colmado'), findsWidgets);
      expect(find.text('Place 4 · The corner shop'), findsOneWidget);
      expect(
        find.text('Locked until the places before it are done.'),
        findsOneWidget,
      );
      expect(
        find.text('Scenes: El mostrador · Los estantes · Las frutas · La caja'),
        findsOneWidget,
      );
      // the X closes it
      await tester.tap(find.byType(CoquiCloseButton));
      await run(tester, 300);
      expect(sheetOpen(tester), isFalse);
    },
  );

  mapTest(
    '"Open every place" opens a place with no stories: the frog hops, the sheet says it is not built',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'todo', todo: true);
      final s = await showMap(tester, f);
      expect(s.picture.STATE.abierto, everyElement(isTrue));
      await tapStop(tester, 3);
      await run(tester, 6000); // eighteen hops, a fifth of a second each
      expect(s.picture.FROG.at, 3);
      expect(find.text('Not built yet.'), findsOneWidget);
      expect(
        find.text('Scenes: El mostrador · Los estantes · Las frutas · La caja'),
        findsOneWidget,
      );
    },
  );

  mapTest(
    'finishing the last story of a place adds its flag and moves the frog',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final s = await showMap(tester, f);
      final m = s.picture;
      final course = f.services.course.places;
      expect(m.STATE.hecho.take(2), [false, false]);
      expect(m.FROG.at, 0);
      expect(flagPixels(m, 0), 0);
      expect(find.text('1 · La casa'), findsOneWidget);
      final ids = course[0].stories;
      for (final id in ids.take(ids.length - 1)) {
        finishStory(f.progress, id);
        await tester.pump();
      }
      // ten of the eleven: nothing yet
      expect(m.STATE.hecho[0], isFalse);
      expect(m.FROG.at, 0);
      expect(flagPixels(m, 0), 0);
      finishStory(f.progress, ids.last);
      await tester.pump();
      expect(m.STATE.hecho.take(3), [true, false, false]);
      expect(m.STATE.aqui, 1);
      expect(m.FROG.at, 1);
      final stop = XY(PADS[1][0], PADS[1][1]);
      expect(m.FROG.x, closeTo(stop.x, 1e-9));
      expect(m.FROG.y, closeTo(stop.y, 1e-9));
      expect(flagPixels(m, 0), greaterThan(20));
      expect(find.text('2 · El parque'), findsOneWidget);
    },
  );

  mapTest('the Today card names the next story; a tap on it goes there', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    await showMap(tester, f);
    expect(find.text('TODAY · 1 OF 3'), findsOneWidget);
    expect(find.text('La lluvia'), findsOneWidget);
    expect(find.text('New story · play it twice · 4 min'), findsOneWidget);
    await tester.tap(find.byType(TodayCard));
    await tester.pump();
    expect(f.nav.routes, [const StoryRoute('la-lluvia')]);
    expect(f.haptics.ticks, 1);
  });

  mapTest('the Today card: a story played once is a second play', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'segunda');
    await showMap(tester, f);
    expect(find.text('TODAY · 1 OF 3'), findsOneWidget);
    expect(find.text('La lluvia'), findsOneWidget);
    expect(find.text('Second play · 2 min'), findsOneWidget);
  });

  mapTest('the Today card offers the review first when words are due', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'uno');
    await showMap(tester, f);
    expect(find.text('TODAY · 1 OF 4'), findsOneWidget);
    expect(find.text(CoquiLabels.reviewTitle), findsOneWidget);
    expect(find.text('1 word coming back · 3 min'), findsOneWidget);
    await tester.tap(find.byType(TodayCard));
    await tester.pump();
    expect(f.nav.routes, [const ReviewRoute()]);
  });

  mapTest('with no title for the review the card goes to the stories', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'uno');
    await showMap(tester, f, reviewTitle: null);
    expect(find.text('TODAY · 1 OF 3'), findsOneWidget);
    expect(find.text('La lluvia'), findsOneWidget);
  });

  mapTest('the chips: the streak and the place', (tester) async {
    phone(tester);
    final f = fixture(seed: 'curso');
    await showMap(tester, f);
    // the flame is drawn, not a character (no emoji font is asked for): the text is the number of days
    expect(find.text('5 days'), findsOneWidget);
    expect(find.byType(CoquiFlame), findsOneWidget);
    expect(find.text('2 · El parque'), findsOneWidget);
  });

  mapTest('a story row calls nav.go(StoryRoute(id))', (tester) async {
    phone(tester);
    final f = fixture(seed: 'segunda');
    final s = await showMap(tester, f);
    await tapStop(
      tester,
      0,
    ); // the place the frog is on: the sheet opens at once
    await run(tester, 300);
    expect(sheetOpen(tester), isTrue);
    expect(s.picture.FROG.at, 0);
    expect(find.text('La casa'), findsWidgets);
    expect(find.text("Place 1 · Grandma's house"), findsOneWidget);
    // La lluvia was played once; the green disc is on the first story not played
    expect(find.bySemanticsLabel('Play again: La lluvia'), findsOneWidget);
    expect(find.bySemanticsLabel('Play: El bizcocho'), findsOneWidget);
    expect(find.text('Played · about 2 min'), findsOneWidget);
    expect(find.text('New · about 3 min'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Play: El bizcocho'));
    await run(tester, 300);
    expect(f.nav.routes, [const StoryRoute('el-bizcocho')]);
    // the play disc leaves for the story and closes the sheet, as the old page, which leaves, does
    expect(sheetOpen(tester), isFalse);
    await tapStop(tester, 0);
    await run(tester, 300);
    expect(sheetOpen(tester), isTrue);
    await tester.tap(find.bySemanticsLabel('Play again: La lluvia'));
    await run(tester, 300);
    expect(f.nav.routes.last, const StoryRoute('la-lluvia'));
    expect(f.nav.routes, hasLength(2));
    expect(sheetOpen(tester), isFalse);
  });

  mapTest('the sheet closes on the scrim', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    await showMap(tester, f, openPlace: 3);
    await run(tester, 300);
    expect(sheetOpen(tester), isTrue);
    await tester.tapAt(const Offset(200, 60));
    await run(tester, 300);
    expect(sheetOpen(tester), isFalse);
  });

  mapTest(
    'the sheet is above the tab bar: its scrim covers it, and a tap on it only closes the sheet',
    (tester) async {
      phone(tester);
      final f = fixture(seed: 'vacio');
      final taps = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: coquiTheme(),
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                MapScreen(services: f.services, openPlace: 3),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: CoquiTabBar(
                    selectedId: CoquiTabs.mapId,
                    onTap: taps.add,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await run(tester, 300);
      expect(sheetOpen(tester), isTrue);
      // the sheet's own box ends above the tab bar and the raised Mapa disc, and the scrim fills the screen
      final bar = tester.getRect(find.byType(CoquiTabBar));
      final sheet = tester.getRect(find.byType(CoquiSheet));
      expect(sheet.bottom, lessThanOrEqualTo(bar.top));
      final scrim = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
      expect(scrim.color, CoquiColors.scrim);
      // a tap on a tab while the sheet is up goes to the scrim: the sheet closes, the tab is not pressed
      await tester.tapAt(bar.center - const Offset(120, 0));
      await run(tester, 300);
      expect(taps, isEmpty);
      expect(sheetOpen(tester), isFalse);
      // the sheet closed, the tab bar takes its touches again
      await tester.tapAt(bar.center - const Offset(120, 0));
      await tester.pump();
      expect(taps, hasLength(1));
    },
  );

  mapTest('reduceMotion: everything stands still', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio', reduceMotion: true);
    final s = await showMap(tester, f);
    final m = s.picture;
    // no frame is asked for: the picture does not change with time
    expect(tester.binding.hasScheduledFrame, isFalse);
    final first = [...m.pix];
    await tester.pump(const Duration(seconds: 2));
    expect(m.pix, first);
    expect(m.e.STILL, isTrue);
    // a tap on an open place: no hop, no sound; the frog is simply there, then the sheet
    await tapStop(tester, 2);
    expect(m.FROG.path, isNull);
    expect(m.FROG.at, 2);
    expect(f.clips.tones, isEmpty);
    expect(sheetOpen(tester), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('La cocina'), findsWidgets);
  });

  mapTest('with motion the picture moves: wind, sea, the arrow', (
    tester,
  ) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final s = await showMap(tester, f);
    final first = [...s.picture.pix];
    await run(tester, 600);
    expect(s.picture.pix, isNot(first));
    expect(s.perf.frames, greaterThan(5));
  });

  mapTest('the map opens scrolled to the frog', (tester) async {
    // a small window, so the map has room to scroll: 412 x 448, one device pixel for a pixel
    phone(tester, size: const Size(412, 448), dpr: 1);
    final f = fixture(seed: 'vacio');
    final s = await showMap(tester, f);
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final stop = s.picture.stopOnPicture(0);
    final viewportH = 448.0 - 48; // the chips are 48 high
    final want =
        stop.sy * 1 - viewportH * .45; // one css pixel for a picture pixel
    expect(scrollable.position.maxScrollExtent, greaterThan(want));
    expect(scrollable.position.pixels, closeTo(want, 1));
  });

  mapTest('a tap that lands on no stop does nothing', (tester) async {
    phone(tester);
    final f = fixture(seed: 'vacio');
    final s = await showMap(tester, f);
    final rect = tester.getRect(find.byType(PixelView));
    await tester.tapAt(
      rect.topLeft + const Offset(8, 8),
    ); // the sea in the corner
    await run(tester, 300);
    expect(s.picture.FROG.path, isNull);
    expect(sheetOpen(tester), isFalse);
    expect(f.haptics.ticks, 0);
    expect(RendererBinding.instance.renderViews, isNotEmpty);
  });
}
