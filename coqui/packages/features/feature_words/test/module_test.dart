// The module and the dev entry.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/dev_main.dart';
import '../tool/dev_services.dart';
import 'support.dart';

void main() {
  test(
    'the module is words, and its tab uses the course language tab name',
    () {
      final s = fakeServices();
      const m = WordsModule();
      expect(m.id, 'words');
      final tab = m.tab(s)!;
      expect(tab.id, 'words');
      expect(tab.label, Language.spanish.tabNames['words']);
    },
  );

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

  testWidgets('the tab renders Words rows from sample stories', (tester) async {
    final rig = Rig();
    await rig.playSampleStories();
    await pumpTab(tester, rig);
    expect(find.text('Words'), findsOneWidget);
    expect(find.byType(NocheStageBar), findsWidgets);
  });

  group('the dev entry', () {
    for (final state in devStates) {
      testWidgets('opens on the fakes in the state "$state"', (tester) async {
        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(devApp(state: state));
        await tester.pumpAndSettle();
        expect(find.text('Words'), findsOneWidget);
        expect(find.byType(NocheTabBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets(
      'the word sheet opens via showNocheSheet over the tab bar scrim',
      (tester) async {
        tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(devApp(state: 'curso'));
        await tester.pumpAndSettle();
        expect(find.byType(NocheTabBar), findsOneWidget);
        final firstWord = rowOrder(tester).first;
        await tapWordRow(tester, firstWord);
        expect(sheet, findsOneWidget);
        expect(
          tester.getRect(find.byType(AnimatedModalBarrier).last),
          const Rect.fromLTWH(0, 0, 412, 915),
        );
        // Tapping the scrim near the top closes the sheet.
        await tester.tapAt(const Offset(206, 40));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
      },
    );

    testWidgets('mid-course: shows SPANISH Words, due card, and Start review', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412 * 2.625, 915 * 2.625);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(devApp(state: 'curso'));
      await tester.pumpAndSettle();
      expect(find.text('SPANISH'), findsOneWidget);
      expect(find.text('Words'), findsOneWidget);
      expect(find.text('Start review'), findsOneWidget);
      expect(find.byType(NocheBarChart), findsOneWidget);
      expect(find.byType(NocheSegmented<WordsSkill>), findsOneWidget);
    });
  });
}
