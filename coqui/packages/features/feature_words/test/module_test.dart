// The module and the dev entry.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/dev_main.dart';
import '../tool/dev_services.dart';
import 'support.dart';

void main() {
  test('the module is words, and its tab is the words tab', () {
    final s = fakeServices();
    const m = WordsModule();
    expect(m.id, 'words');
    final tab = m.tab(s)!;
    expect(tab.id, 'words');
    expect(tab.label, CoquiLabels.words);
  });

  testWidgets('screenFor answers its own tab and nothing else', (tester) async {
    final s = fakeServices();
    const m = WordsModule();
    expect(m.screenFor(const TabRoute('words'), s), isNotNull);
    for (final r in <AppRoute>[
      const TabRoute('map'),
      const TabRoute('library'),
      const TabRoute('speak'),
      const TabRoute('me'),
      const StoryRoute('la-lluvia'),
      const StoryRoute('la-lluvia', listen: true),
      const ReviewRoute(),
      const ReviewRoute(practice: true),
      const LevelCheckRoute(),
      const BookRoute('la-lluvia'),
      const CallRoute('casa'),
      const VoiceTestRoute(),
    ]) {
      expect(m.screenFor(r, s), isNull, reason: '$r');
    }
  });

  testWidgets('the tab and the screen for its route are the same screen', (
    tester,
  ) async {
    final rig = Rig();
    await rig.playSampleStories();
    await pumpTab(tester, rig);
    expect(find.byType(WordCard), findsWidgets);
  });

  group('the dev entry', () {
    for (final state in devStates) {
      testWidgets('opens on the fakes in the state "$state"', (tester) async {
        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(devApp(state: state));
        await tester.pumpAndSettle();
        expect(find.text(CoquiLabels.review), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'the word sheet opens above the tab bar (showCoquiSheet): the scrim dims it and takes a touch on it',
      (tester) async {
        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(devApp(state: 'curso'));
        await tester.pumpAndSettle();
        final bar = tester.getRect(find.byType(CoquiTabBar));
        await tester.tap(find.byType(WordCard).first);
        await tester.pumpAndSettle();
        expect(sheet, findsOneWidget);
        // the sheet stands above the bar and the raised Mapa disc (the bar's box holds both: 72 + 14 px), the scrim
        // covers the whole screen
        expect(bar.height, 72 + 14);
        expect(tester.getRect(sheet).bottom, bar.top);
        expect(
          tester.getRect(find.byType(AnimatedModalBarrier).last),
          const Rect.fromLTWH(0, 0, 412, 915),
        );
        // a touch on the bar goes to the scrim: the sheet closes
        await tester.tapAt(bar.center);
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
      },
    );

    testWidgets('mid-course: the Repaso card says ten words are due', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devApp(state: 'curso'));
      await tester.pumpAndSettle();
      expect(find.text('10 words today · about 2 min'), findsOneWidget);
      expect(find.text('La casa'), findsOneWidget);
    });
  });
}
