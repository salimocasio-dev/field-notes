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
    expect(tab.label, CoquiTabs.map.label);
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
    expect(find.byType(MapChips), findsOneWidget);
    // the sample course has one place; the chip names it
    expect(find.text('1 · La casa'), findsOneWidget);
  });

  mapTest(
    'the tab gives the Today card the review entry\'s title, `CoquiLabels.reviewTitle`',
    (tester) async {
      tester.view.devicePixelRatio = 2.625;
      tester.view.physicalSize = const Size(412, 915) * 2.625;
      addTearDown(tester.view.reset);
      // a learner with one word coming back: the plan opens with the review
      final f = fixture(seed: 'uno');
      final tab = const MapModule().tab(f.services)!;
      await tester.pumpWidget(
        MaterialApp(
          theme: coquiTheme(),
          home: Scaffold(body: Builder(builder: tab.builder)),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text(CoquiLabels.reviewTitle), findsOneWidget);
      expect(find.text('1 word coming back · 3 min'), findsOneWidget);
      await tester.tap(find.byType(TodayCard));
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
    expect(find.text('4 · El colmado'), findsOneWidget);
  });

  mapTest('the dev entry: no corner chip with chip=0', (tester) async {
    await tester.pumpWidget(devApp(const {'chip': '0', 'reduce': '1'}));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('perf-chip')), findsNothing);
  });
}
