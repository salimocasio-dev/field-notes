// A decision, as the engine runs it (docs/proyecto/07-handoff-build-a1.md; juego.js decide 354), with its asks and its
// endings: right first time, wrong then right, `noretry`, `lock`, `pick`, `alterna` (see step_kinds_test), `other`, `as`,
// `bien`, `resp`, the stake and `lost`, each ending.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

final things = [
  Thing(id: 'puerta', box: [10, 10, 20, 20]),
  Thing(id: 'ventana', box: [60, 10, 20, 20]),
  Thing(id: 'casa', box: [100, 10, 20, 20]),
];

const clips = {'q': 'Q', 'muy_bien': 'M', 'mal': 'N', 'ok': 'K', 'si_dice': 'S', 'no_dice': 'D', 'pos': 'P', 'otra': 'O'};

Map<String, dynamic> decision(Map<String, dynamic> d, {List<Object?> before = const [], List<Object?> after = const [], Map<String, dynamic> extra = const {}}) => story(
  beats: [
    {'wait': 100},
    ...before,
    {'decide': 'do', 'options': ['puerta', 'ventana'], 'line': 'q', 'tests': 'uno', 'pick': 'puerta', ...d},
    ...after,
  ],
  clips: clips,
  extra: extra,
);

void main() {
  group('decide', () {
    test('right first time: logged ok, the signal, "¡Muy bien!", the right steps; nothing lost', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'right': ['ok'], 'wrong': ['mal']}), scene: scene);
      await r.finish((pn) => 'puerta');
      expect(r.runner.LOG.single.toJson(), {'word': 'uno', 'asked': 'puerta', 'got': 'puerta', 'ok': true, 'ms': 700});
      expect(r.clips, ['q', 'muy_bien', 'ok']);
      expect(r.sounds, ['calla', 'right']);
      expect(scene.stakes, isEmpty);
      expect(r.runner.W['lost'], 0);
      expect(r.runner.V['ok'], '1');
      expect(r.runner.V['x'], 'puerta');
    });

    test('wrong then right: the wrong steps, a step lost and shown, then the big sign and the right one', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'right': ['ok'], 'wrong': ['mal']}), scene: scene);
      final asked = <String?>[];
      var n = 0;
      await r.finish((pn) {
        asked.add(pn.sign);
        return n++ == 0 ? 'ventana' : 'puerta';
      });
      expect(asked, [null, 'puerta']); // no sign at first; after the wrong one the big sign shows the right one
      expect(r.runner.LOG.single.toJson(), {'word': 'uno', 'asked': 'puerta', 'got': 'ventana', 'ok': false, 'ms': 700});
      expect(r.clips, ['q', 'mal', 'q', 'muy_bien', 'ok']);
      expect(scene.stakes, [[1, 3, 'ventana']]);
      expect(r.runner.W['lost'], 1);
      expect(r.runner.V['ok'], '');
      expect(r.runner.V['x'], 'ventana');
    });

    test('a wrong answer that has its own cost step does not lose a second one', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'wrong': [{'cost': 1, 'en': 'x'}]}), scene: scene);
      var n = 0;
      await r.finish((pn) => n++ == 0 ? 'ventana' : 'puerta');
      expect(scene.stakes, [[1, 3, 'x']]);
      expect(r.runner.W['lost'], 1);
    });

    test('noretry: one guess; the story goes on with no sign, no signal and no right steps', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'noretry': true, 'right': ['ok']}, after: ['pos']), scene: scene);
      await r.finish((pn) => 'ventana');
      expect(r.clips, ['q', 'pos']);
      expect(r.runner.W['lost'], 1);
      expect(r.sounds.where((s) => s == 'right'), isEmpty);
    });

    test('lock: a touch before the question has been asked once does not count', () async {
      Future<Rig> go(bool lock) async {
        final r = await Rig.make(decision({'lock': lock, 'lead': ['otra']}), scene: StandInScene(things: things));
        await r.start();
        await r.until(() => r.runner.pending != null, what: 'the decision');
        r.touch('puerta'); // during the lead
        await r.drain();
        return r;
      }

      final locked = await go(true);
      expect(locked.runner.pending!.done, isFalse);
      final open = await go(false);
      // a touch counts from the first word of the lead-in
      expect(open.runner.LOG.single.toJson(), {'word': 'uno', 'asked': 'puerta', 'got': 'puerta', 'ok': true, 'ms': 0});
    });

    test('pick fixes the right option, `\$name` filled; `as` and `other` name the two', () async {
      final r = await Rig.make(story(beats: [
        {'draw': 'b', 'options': ['ventana']},
        {'decide': 'do', 'options': ['puerta', 'ventana'], 'pick': r'$b', 'as': 'a', 'other': 'o', 'line': 'q'},
      ], clips: clips), scene: StandInScene(things: things));
      await r.finish((pn) => pn.pick);
      expect(r.runner.V['a'], 'ventana');
      expect(r.runner.V['o'], 'puerta');
      expect(r.runner.LOG.single.asked, 'ventana');
    });

    test('with no pick the right option is drawn; a value named like `as` fixes it', () async {
      final d = {'decide': 'do', 'options': ['puerta', 'ventana'], 'as': 'a', 'line': 'q'};
      final r = await Rig.make(story(beats: [d], clips: clips), scene: StandInScene(things: things));
      await r.finish((pn) => pn.pick);
      expect(r.runner.V['a'], 'ventana'); // Mulberry32(1): .627 -> floor(.627 * 2) = 1
      final f = await Rig.make(story(beats: [d], clips: clips), scene: StandInScene(things: things), forced: {'a': 'puerta'});
      await f.finish((pn) => pn.pick);
      expect(f.runner.V['a'], 'puerta');
    });

    test('bien: false says nothing; a clip of its own replaces "¡Muy bien!"', () async {
      Future<List<String>> go(Object? bien) async {
        final r = await Rig.make(decision({'bien': bien}), scene: StandInScene(things: things));
        await r.finish((pn) => 'puerta');
        return r.clips;
      }

      expect(await go(false), ['q']);
      expect(await go('otra'), ['q', 'otra']);
      expect(await go(null), ['q', 'muy_bien']);
      // the story's own `bien` is the default praise
      final own = await Rig.make(decision({}, extra: {'bien': 'ok'}), scene: StandInScene(things: things));
      await own.finish((pn) => 'puerta');
      expect(own.clips, ['q', 'ok']);
    });

    test('vale: another answer that is right too; tests "-" files nothing; the word table renames the word', () async {
      final r = await Rig.make(decision({'vale': ['casa'], 'tests': '-'}), scene: StandInScene(things: things));
      await r.finish((pn) => 'casa');
      expect(r.runner.LOG, isEmpty);
      expect(r.runner.W['lost'], 0);
      final w = await Rig.make(decision({'tests': 'uno'}, extra: {'palabras': {'uno': 'abuela'}}), scene: StandInScene(things: things));
      await w.finish((pn) => 'puerta');
      expect(w.runner.LOG.single.word, 'abuela');
    });

    test('gratis: an answer that costs nothing runs its steps and he chooses again', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'gratis': {'casa': ['otra']}, 'options': ['puerta', 'ventana', 'casa']}), scene: scene);
      var n = 0;
      await r.finish((pn) => n++ == 0 ? 'casa' : 'puerta');
      expect(r.clips, contains('otra'));
      expect(r.runner.LOG.single.ok, isTrue);
      expect(r.runner.W['lost'], 0);
    });

    test('libre: a wrong touch costs nothing and logs nothing; the name of what he touched, then the sign', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(decision({'libre': true}, extra: {'names': {'ventana': 'otra'}}), scene: scene);
      var n = 0;
      await r.finish((pn) => n++ == 0 ? 'ventana' : 'puerta');
      expect(r.runner.LOG, isEmpty);
      expect(r.runner.W['lost'], 0);
      expect(scene.stakes, isEmpty);
      expect(r.clips, ['q', 'otra', 'q', 'muy_bien']);
      expect(r.sounds, contains('bonk'));
    });

    test('resp: "say" shows the answer bubbles while he chooses, and takes them away', () async {
      final r = await Rig.make(decision({'decide': 'say', 'options': ['si', 'no'], 'pick': 'si', 'said': {'si': 'si_dice', 'no': 'no_dice'}}), scene: StandInScene(things: things));
      await r.start();
      final pn = await r.untilAsked();
      expect(r.runner.W['resp'], ['si', 'no']);
      expect(r.runner.respBox('si'), isNotNull);
      r.touch(pn.live.first);
      await r.until(() => !r.runner.running);
      expect(r.runner.W['resp'], isNull);
      // what he said is said by the frog
      expect(r.clips, contains('si_dice'));
      expect(r.runner.LOG.single.got, 'si');
    });

    test('an ask can use answer bubbles too (`resp`)', () async {
      final r = await Rig.make(story(beats: [
        {'wait': 100},
        {'ask': 'si', 'resp': ['si', 'no'], 'line': 'q', 'said': {'si': 'si_dice'}},
      ], clips: clips), scene: StandInScene(things: things));
      await r.start();
      await r.untilAsked();
      expect(r.runner.W['resp'], ['si', 'no']);
      r.touch('si');
      await r.until(() => !r.runner.running);
      expect(r.runner.W['resp'], isNull);
      expect(r.clips, ['q', 'si_dice', 'muy_bien']);
    });
  });

  group('the stake and `lost`', () {
    test('every wrong answer takes one step, to the number the story has (S.stake.steps)', () async {
      final scene = StandInScene(things: things);
      final s = story(
        steps: 2,
        beats: [
          {'wait': 100},
          for (var i = 0; i < 3; i++) {'decide': 'do', 'options': ['puerta', 'ventana'], 'pick': 'puerta', 'line': 'q', 'tests': 'uno'},
        ],
        clips: clips,
      );
      final r = await Rig.make(s, scene: scene);
      var n = 0;
      await r.finish((pn) => n++ % 2 == 0 ? 'ventana' : 'puerta');
      expect(scene.stakes.map((x) => x.take(2).toList()), [[1, 2], [2, 2], [3, 2]]);
      expect(r.runner.W['lost'], 3);
      expect(r.progress.finished.single.lost, 3);
    });
  });

  group('the endings', () {
    test('a story with a next one: the end screen offers Play again and Next story (and the outline Map beside)', () async {
      final r = await Rig.make(story(beats: ['q'], clips: clips, extra: {'next': 'otra-historia'}));
      await r.finish((pn) => null);
      expect(r.runner.view.screen, StoryScreenState.end);
      expect(r.runner.view.title, 'Prueba');
      expect(r.runner.view.foot, const StoryFoot(next: true, again: true, home: false, map: true));
      expect(r.runner.view.dotsLit, 5);
    });

    test('a story with no next one: Map takes the main place', () async {
      final r = await Rig.make(story(beats: ['q'], clips: clips));
      await r.finish((pn) => null);
      expect(r.runner.view.foot, const StoryFoot(next: false, again: true, home: true, map: false));
    });

    test('at the end the story result goes to the progress store, with the minutes (PAL.cuento, PAL.minutos)', () async {
      final r = await Rig.make(decision({}), scene: StandInScene(things: things));
      await r.finish((pn) => 'puerta');
      final f = r.progress.finished.single;
      expect(f.id, 'prueba');
      expect(f.focusWords, ['uno']);
      expect(f.backAgain, ['dos']);
      expect(f.lost, 0);
      expect(f.log.single.word, 'uno');
      // the story's own time at the moment it ended, in minutes: before the last 1200 ms
      expect(r.progress.minutesAdded, hasLength(1));
      expect(r.progress.minutesAdded.single, closeTo((r.timers.now - 1200) / 60000, 1e-9));
      expect(r.progress.listenedIds, isEmpty);
    });

    test('a picture story or a routine (it has a `tipo`) is heard, not scored: PAL.oido', () async {
      final r = await Rig.make(story(beats: ['q'], clips: clips, extra: {'tipo': 'escucha'}));
      await r.finish((pn) => null);
      expect(r.progress.finished, isEmpty);
      expect(r.progress.listenedIds, ['prueba']);
      expect(r.progress.minutesAdded, hasLength(1));
    });

    test('nothing is written under ?fast without ?rec', () async {
      final r = await Rig.make(story(beats: ['q'], clips: clips));
      // the option the old address switch becomes
      expect(const StoryOptions(recordsProgress: false).recordsProgress, isFalse);
      await r.finish((pn) => null);
      expect(r.progress.finished, hasLength(1));
    });

    test('the branches of a story\'s end: by what is left (an `if` on lost)', () async {
      for (final lostSteps in [0, 1, 3]) {
        final scene = StandInScene(things: things);
        final r = await Rig.make(
          story(
            beats: [
              {'wait': 100},
              for (var i = 0; i < lostSteps; i++) {'cost': 1},
            ],
            final_: [
              {'if': 'lost', 'then': [{'if': 'lost=3', 'then': ['mal'], 'else': ['ok']}], 'else': ['pos']},
            ],
            clips: clips,
          ),
          scene: scene,
        );
        await r.finish((pn) => null);
        expect(r.clips, [lostSteps == 0 ? 'pos' : lostSteps == 3 ? 'mal' : 'ok']);
        expect(r.progress.finished.single.lost, lostSteps);
      }
    });

    test('the X: all sound stops, the play ends, nothing is written', () async {
      final r = await Rig.make(story(beats: ['q', {'wait': 5000}, 'otra'], clips: clips));
      await r.start();
      await r.advance(1000);
      r.runner.leave();
      await r.advance(10000);
      expect(r.clips, ['q']);
      expect(r.progress.finished, isEmpty);
      expect(r.runner.view.screen, isNot(StoryScreenState.end));
      expect(r.sounds.last, 'calla');
    });

    test('Play again starts the story from the beginning: a new world, the old one gone', () async {
      final r = await Rig.make(story(beats: [{'wait': 100}, {'set': {'storm': true}}, 'q'], clips: clips));
      await r.finish((pn) => null);
      expect(r.runner.W['storm'], true);
      await r.start();
      expect(r.runner.W['storm'], isNull);
      await r.until(() => !r.runner.running);
      expect(r.progress.finished, hasLength(2));
    });
  });
}
