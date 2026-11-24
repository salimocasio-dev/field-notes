import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/feature_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/map_dev_app.dart';
import 'support/map_fixture.dart';
import 'support/map_tester.dart';

void main() {
  test('the module is map: it owns the tab map and no route', () {
    const m = MapModule();
    expect(m.id, 'map');
    final tab = m.tab(fakeServices())!;
    expect(tab.id, 'map');
    expect(tab.label, Language.spanish.tabNames['map']);
    expect(m.screenFor(const StoryRoute('la-lluvia'), fakeServices()), isNull);
    expect(m.screenFor(const TabRoute('map'), fakeServices()), isNull);
  });

  mapTest('the tab builds the map on the fakes', (tester) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(412, 915) * 2.625;
    addTearDown(tester.view.reset);
    final services = fakeServices(reduceMotion: true);
    final tab = const MapModule().tab(services)!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: tab.builder)),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(PixelView), findsOneWidget);
    expect(find.byKey(const Key('language-chip')), findsOneWidget);
    expect(find.text('Spanish'), findsOneWidget);
    expect(find.text('A1'), findsNothing);
    expect(find.text('You are here'), findsOneWidget);
  });

  mapTest(
    'the tab gives the Up next card the English review title when words are due',
    (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412, 915) * 2.625;
      addTearDown(tester.view.reset);
      // a learner with one word coming back: the plan opens with the review
      final f = fixture(seed: 'uno');
      final tab = const MapModule().tab(f.services)!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: tab.builder)),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('1 word coming back · 3 min'), findsOneWidget);
      await tester.tap(find.byKey(const Key('up-next-play')));
      await tester.pump();
      expect(f.nav.routes, [const ReviewRoute()]);
    },
  );

  mapTest('the dev entry opens on the fakes, with the corner chip', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(412, 915) * 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(devApp(const {'demo': 'three', 'reduce': '1'}));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PixelView), findsOneWidget);
    expect(find.byKey(const Key('perf-chip')), findsOneWidget);
    expect(find.textContaining('bake '), findsOneWidget);
    expect(find.textContaining('frame max '), findsOneWidget);
    expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
    expect(find.text('Second play · 2 min'), findsOneWidget);
  });

  mapTest('the dev entry: no corner chip with chip=0', (tester) async {
    await tester.pumpWidget(devApp(const {'chip': '0', 'reduce': '1'}));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('perf-chip')), findsNothing);
  });

  mapTest('the tab has no corner chip unless the module is asked for one', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(412, 915) * 2.625;
    addTearDown(tester.view.reset);
    final tab = const MapModule().tab(fakeServices(reduceMotion: true))!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Builder(builder: tab.builder)),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(PixelView), findsOneWidget);
    expect(find.byKey(const Key('map-perf-chip')), findsNothing);
    expect(find.textContaining('bake '), findsNothing);
  });

  mapTest(
    'showPerf: the tab shows the bake and the frame times in a corner chip, under the top chips',
    (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412, 915) * 2.625;
      addTearDown(tester.view.reset);
      final tab = const MapModule(showPerf: true)
          .tab(fakeServices(reduceMotion: false))!;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Builder(builder: tab.builder)),
        ),
      );
      await tester.pump();
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final chip = find.byKey(const Key('map-perf-chip'));
      expect(chip, findsOneWidget);
      final text = tester.widget<Text>(
        find.descendant(of: chip, matching: find.byType(Text)),
      );
      expect(
        text.data,
        matches(
          RegExp(r'^bake \d+ ms · frame max \d+\.\d ms · mean \d+\.\d ms$'),
        ),
      );
      // the bake has run: its time is in the chip (and frames were timed)
      expect(text.data, isNot(startsWith('bake 0 ms · frame max 0.0')));
      expect(
        tester.getTopLeft(chip).dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byKey(const Key('language-chip'))).dy,
        ),
      );
      expect(tester.getTopRight(chip).dx, 412 - 16);
      // the ticker would run for ever: take the screen away
      await tester.pumpWidget(const SizedBox());
    },
  );
}
