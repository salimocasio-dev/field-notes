// A story played to its end in the real app, on the real El frente.
import 'dart:convert';

import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/harness.dart';

/// Opens the story on the Today card and plays it to its end screen. The taps are scripted with no knowledge of the
/// scene: every 700 ms the next point of a 7 x 9 grid over the picture is touched (in a fixed scattered order), until the
/// end screen comes. A touch on the thing asked for answers it; a touch elsewhere does what a touch there does in the
/// story. So the story runs as it does for a learner who touches everywhere. Returns the virtual ms it took.
Future<int> playFromToday(TestApp app) async {
  final tester = app.tester;
  await app.tap(find.byType(TodayCard));
  await app.until(
    () => find.byType(LessonStartButton).evaluate().isNotEmpty,
    what: 'the story\'s start disc',
  );
  expect(app.lessonShown, isTrue);
  expect(find.byType(CoquiTabBar), findsNothing);
  await app.tap(find.byType(LessonStartButton));
  final pic = tester.getRect(find.byType(PixelView));
  final points = <Offset>[
    for (var j = 0; j < 9; j++)
      for (var i = 0; i < 7; i++)
        Offset(
          pic.left + pic.width * (i + .5) / 7,
          pic.top + pic.height * (j + .5) / 9,
        ),
  ];
  final end = find.text('Play again');
  var k = 0, t = 0;
  for (; end.evaluate().isEmpty; t += 700) {
    if (t > 15 * 60 * 1000) fail('the story did not end in 15 minutes');
    await tester.tapAt(points[(k * 17) % points.length]);
    k++;
    await app.advance(700);
  }
  return t;
}

void main() {
  testWidgets(
    '(d) La lluvia played to its end writes storyFinished; the map follows, and names the next story once it is due',
    (tester) async {
      final app = TestApp(tester);
      // the welcome done, nothing played; the recogniser off (the story's speaking turns do not run, as on a phone
      // without one), so every answer is a touch
      await app.open(stored: seed('vacio'), speechAvailable: false);
      expect(find.text('La lluvia'), findsOneWidget);
      expect(find.text('New story · play it twice · 4 min'), findsOneWidget);

      await playFromToday(app);
      expect(app.clips!.played.first, 'esta_casa');
      // storyFinished: the story's record, under the old key
      var db = jsonDecode(app.stored!) as Map<String, dynamic>;
      expect(((db['cuentos'] as Map)['la-lluvia'] as Map)['n'], 1);
      expect(app.services.progress.played('la-lluvia'), isTrue);
      // the end screen offers the next story
      expect(find.text('Next story'), findsOneWidget);

      // Map: the map follows the store. v=39's plan (app.html, plan) puts a story played once first, as its second
      // play; the next story is the plan's second entry
      await app.tap(find.text('Map').last);
      await app.settle(rounds: 5);
      expect(app.tabBarShown, isTrue);
      expect(app.selectedTab, 'map');
      expect(find.text('TODAY · 1 OF 3'), findsOneWidget);
      expect(find.text('La lluvia'), findsOneWidget);
      expect(find.text('Second play · 2 min'), findsOneWidget);

      // the second play, from the Today card: then the card names the next story
      await playFromToday(app);
      db = jsonDecode(app.stored!) as Map<String, dynamic>;
      expect(((db['cuentos'] as Map)['la-lluvia'] as Map)['n'], 2);
      await app.tap(find.text('Map').last);
      await app.settle(rounds: 5);
      expect(app.selectedTab, 'map');
      expect(find.text('El bizcocho'), findsOneWidget);
      expect(find.text('New story · play it twice · 6 min'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
