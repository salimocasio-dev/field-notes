// A story played to its end in the real app, on the real El frente.
import 'dart:convert';

import 'package:app/src/switches.dart';
import 'package:coqui_scenes/coqui_scenes.dart' show convertedScenes;
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/harness.dart';

/// Opens the story on the Today card and plays it to its end screen. The taps are scripted with no knowledge of the
/// scene: every 700 ms the next point of a 7 x 9 grid over the picture is touched (in a fixed scattered order), until the
/// end screen comes. A touch on the thing asked for answers it; a touch elsewhere does what a touch there does in the
/// story. So the story runs as it does for a learner who touches everywhere. Returns the virtual ms it took.
Future<int> playFromToday(TestApp app) async {
  final tester = app.tester;
  await app.tap(findMapUpNextAction());
  await app.until(
    () => findStoryStartButton().evaluate().isNotEmpty,
    what: 'the story\'s start disc',
  );
  expect(app.lessonShown, isTrue);
  expect(find.byType(NocheTabBar), findsNothing);
  await app.tap(findStoryStartButton());
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
      expect(find.text('New story · 4 min'), findsOneWidget);

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
      expect(find.text('UP NEXT · LA CASA'), findsOneWidget);
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
      expect(find.text('New story · 6 min'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
  testWidgets(
    '(p) ?txt= reaches the story: its first line shows while it is spoken (con, and with no ?txt=), right after it (tras), never (no)',
    (tester) async {
      final first =
          ((jsonDecode(repoFile('historia/cuentos/la-lluvia.json'))
                      as Map)['clips']
                  as Map)['esta_casa']['text']
              as String;
      // The virtual ms after Start at which the narrator's first line is on screen (null: not in ten seconds, which is
      // well past the end of the line)
      Future<int?> shownAt(Map<String, String> query) async {
        final app = TestApp(tester);
        await app.open(
          stored: seed('curso'),
          location: '/cuento/la-lluvia',
          switches: AppSwitches.fromQuery(query),
          speechAvailable: false,
        );
        await app.until(
          () => findStoryStartButton().evaluate().isNotEmpty,
          what: 'the start disc',
        );
        await app.tap(findStoryStartButton());
        int? at;
        for (var t = 0; t < 10000; t += 20) {
          await app.advance(20);
          if (at == null && find.text(first).evaluate().isNotEmpty) at = t;
        }
        expect(app.clips!.played.first, 'esta_casa');
        await tester.pumpWidget(const SizedBox());
        return at;
      }

      final none = await shownAt(const {});
      final con = await shownAt(const {'txt': 'con'});
      final tras = await shownAt(const {'txt': 'tras'});
      final no = await shownAt(const {'txt': 'no'});
      expect(none, isNotNull);
      expect(con, none);
      expect(tras, isNotNull);
      // right after the line, not while it is spoken (it is two seconds long)
      expect(tras!, greaterThan(con! + 1000));
      expect(no, isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );

  testWidgets(
    '(q) A comer\'s three stories and La cocina\'s three routines are in the course; one whose scene is not converted '
    'yet opens on "This story is not in the new app yet." and returns to the map; one whose scene is converted opens on '
    'its start disc (the list of converted scenes decides, so no port has to change this test)',
    (tester) async {
      final curso = jsonDecode(
        repoFile('historia/datos/curso.json'),
      ) as Map<String, dynamic>;
      final cocina = (curso['lugares'] as List).firstWhere(
        (p) => (p as Map)['id'] == 'cocina',
      ) as Map;
      const stories = ['que-quieres', 'buen-provecho', 'cafe-con-azucar'];
      const routines = ['h-mesa', 'h-estufa', 'h-nevera'];
      expect(cocina['cuentos'] as List, containsAllInOrder(stories));
      expect(cocina['haz'], routines);
      for (final id in [...stories, ...routines]) {
        final scene =
            (jsonDecode(repoFile('historia/cuentos/$id.json')) as Map)['scene']
                as String;
        final app = TestApp(tester);
        await app.open(stored: seed('curso'), location: '/cuento/$id');
        if (convertedScenes.contains(scene)) {
          await app.until(
            () => findStoryStartButton().evaluate().isNotEmpty,
            what:
                '$id: the story\'s start disc (its scene $scene is converted)',
          );
          expect(
            find.text('This story is not in the new app yet.'),
            findsNothing,
            reason: id,
          );
          expect(tester.takeException(), isNull, reason: id);
        } else {
          await app.until(
            () => find
                .text('This story is not in the new app yet.')
                .evaluate()
                .isNotEmpty,
            what:
                '$id: the not-converted screen (its scene $scene is not converted)',
          );
          expect(tester.takeException(), isNull, reason: id);
          await app.tap(find.text('Back to the map'));
          await app.settle(rounds: 5);
          expect(app.selectedTab, 'map', reason: id);
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
