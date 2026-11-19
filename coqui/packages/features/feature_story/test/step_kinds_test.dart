// The kinds of step juego.js's `paso` knows (lines 319 to 337), one test each, on a scene of our own. The second part is
// what a story file may use besides: `$name` filling (line 315), conditions (317), the memory between stories.
import 'dart:convert';

import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

Future<Rig> played(
  Map<String, dynamic> s, {
  StandInScene? scene,
  Map<String, String> forced = const {},
  MemStore? memory,
}) async {
  final r = await Rig.make(s, scene: scene, forced: forced, memory: memory);
  await r.finish((pn) => pn.live.first);
  return r;
}

void main() {
  group('the kinds of step (juego.js paso, lines 319 to 337)', () {
    test('a bare string is a line: the clip is said, then the 420 ms pause (320, say 113)', () async {
      final r = await played(
        story(beats: ['a', 'b'], clips: {'a': 'A', 'b': 'B'}),
      );
      expect(r.clips, ['a', 'b']);
      expect(r.runner.running, isFalse);
      // 1 ms to start the clip + 420 pause for each, then 1200 at the end: 0 + 420 + 420 + 1200
      expect(r.timers.now, 420 + 420 + 1200);
    });

    test('say: a line with its own pause (321)', () async {
      final r = await played(
        story(
          beats: [
            {'say': 'a', 'gap': 1000},
            {'say': 'b'},
          ],
          clips: {'a': 'A', 'b': 'B'},
        ),
      );
      expect(r.clips, ['a', 'b']);
      expect(r.timers.now, 1000 + 420 + 1200);
    });

    test('wait: sleeps that long (322)', () async {
      final r = await played(
        story(
          beats: [
            {'wait': 500},
            {'wait': 0},
          ],
        ),
      );
      expect(r.timers.now, 500 + 1200);
    });

    test('cam: the camera slides to a view; it is a wait of that many ticks (323, camGo 152)', () async {
      final r = await Rig.make(
        story(
          beats: [
            {'cam': 'side', 'n': 5},
          ],
        ),
      );
      await r.start();
      expect(r.runner.cam, [0, 0, 196, 216]);
      await r.until(() => !r.runner.running, what: 'the end');
      expect(r.runner.cam, [44, 0, 196, 216]);
      // 5 ticks of 70 ms (the move is done when t >= 1) from the first tick after it began, then the 1200 ms
      expect(r.timers.now, 5 * 70 + 1200);
      expect(r.runner.at('side'), isTrue);
    });

    test('cam: a view the camera is at already takes no time', () async {
      final r = await played(
        story(
          beats: [
            {'cam': 'wide'},
          ],
        ),
      );
      expect(r.timers.now, 1200);
    });

    test(
      'cam: a change of zoom is a cut: at the target from the first step',
      () async {
        final r = await Rig.make(
          story(
            beats: [
              {'cam': 'close', 'n': 4},
            ],
          ),
        );
        await r.start();
        await r.advance(100);
        expect(r.runner.cam, [10, 10, 98, 108]);
      },
    );

    test('dots: lights that many progress dashes (324, step 276)', () async {
      final r = await Rig.make(
        story(
          beats: [
            {'dots': 2},
            {'wait': 100},
            {'dots': 4},
            {'wait': 100},
          ],
        ),
      );
      expect(r.runner.view.dots, 5);
      await r.start();
      await r.advance(50);
      expect(r.runner.view.dotsLit, 2);
      await r.advance(100);
      expect(r.runner.view.dotsLit, 4);
      await r.until(() => !r.runner.running, what: 'the end');
      expect(r.runner.view.dotsLit, 5);
    });

    test('set: puts values into the world (325)', () async {
      final r = await played(
        story(
          beats: [
            {
              'set': {'storm': true, 'n': 3},
            },
          ],
        ),
      );
      expect(r.runner.W['storm'], true);
      expect(r.runner.W['n'], 3);
    });

    test('set: a position goes through the scene\'s remap (page 12, section 5); the story file is not changed', () async {
      final seen = <List<num>>[];
      final scene = _RemapScene(seen);
      final file = story(
        beats: [
          {
            'set': {
              'gente': {
                'luis': {'x': 150, 'y': 150, 'pose': 'idle'},
              },
            },
          },
        ],
      );
      final copy = jsonDecode(jsonEncode(file));
      final r = await played(file, scene: scene);
      expect(seen, [
        [150, 150],
      ]);
      expect(((r.runner.W['gente'] as Map)['luis'] as Map)['x'], 151);
      expect(((r.runner.W['gente'] as Map)['luis'] as Map)['y'], 152);
      expect(((r.runner.W['gente'] as Map)['luis'] as Map)['pose'], 'idle');
      expect(file, copy);
    });

    test('if: runs then or else by a condition (326, cond 317)', () async {
      final r = await played(
        story(
          beats: [
            {
              'set': {'wet': true},
            },
            {
              'if': 'wet',
              'then': ['a'],
              'else': ['b'],
            },
            {
              'if': '!wet',
              'then': ['c'],
              'else': ['d'],
            },
            {
              'if': 'wet=true',
              'then': ['e'],
            },
            {
              'if': 'dry',
              'then': ['f'],
            },
            {
              'if': 'n=3',
              'then': ['g'],
            },
          ],
          clips: {for (final k in 'abcdefg'.split('')) k: k.toUpperCase()},
          extra: {},
        ),
      );
      // `wet` is true: a, then d (not wet is false: else), e ("true" is how JavaScript writes true), no f, no g
      expect(r.clips, ['a', 'd', 'e']);
    });

    test('if: the story\'s variables first, then the world', () async {
      final r = await played(
        story(
          beats: [
            {
              'draw': 'v',
              'options': ['x', 'y'],
            },
            {
              'set': {'v': 'world'},
            },
            {
              'if': 'v=world',
              'then': ['a'],
            },
            {
              'if': 'lost',
              'then': ['b'],
            },
            {
              'if': '!lost',
              'then': ['c'],
            },
          ],
          clips: {'a': 'A', 'b': 'B', 'c': 'C'},
        ),
        forced: {'v': 'x'},
      );
      // V.v ("x") wins over W.v ("world"); lost is 0: not truthy
      expect(r.clips, ['c']);
      expect(r.runner.V['v'], 'x');
    });

    test('act: runs the scene\'s act with the step\'s fields, `\$name` filled (327)', () async {
      final got = <Map<String, dynamic>>[];
      final scene = StandInScene(acts: {'tocar': (o) async => got.add(o)});
      await played(
        story(
          beats: [
            {
              'draw': 'k',
              'options': ['uno'],
            },
            {
              'act': 'tocar',
              'en': r'$k',
              'n': 2,
              'list': [r'$k'],
            },
          ],
        ),
        scene: scene,
      );
      expect(got, [
        {
          'act': 'tocar',
          'en': 'uno',
          'n': 2,
          'list': [r'$k'],
        },
      ]);
    });

    test('act: a scene with no such act is a loud failure (327)', () async {
      final scene = StandInScene(lenient: false, acts: {});
      final r = await Rig.make(
        story(
          beats: [
            {'act': 'nada'},
          ],
        ),
        scene: scene,
      );
      var failed = false;
      try {
        await r.finish((pn) => null);
      } on StoryError catch (e) {
        failed = true;
        expect(e.message, contains('nada'));
      } catch (e) {
        failed = true;
      }
      expect(failed, isTrue);
    });

    test('ask: waits for a touch on the asked thing, then the signal, "¡Muy bien!", then (328, ask 341)', () async {
      final r = await played(
        story(
          beats: [
            {
              'ask': 'puerta',
              'line': 'q',
              'then': ['z'],
            },
          ],
          clips: {'q': 'Q', 'muy_bien': 'M', 'z': 'Z'},
        ),
      );
      expect(r.clips, ['q', 'muy_bien', 'z']);
      expect(r.sounds.where((s) => s == 'right'), hasLength(1));
      expect(r.runner.LOG, isEmpty);
    });

    test(
      'decide: a choice with a right answer, logged (329, decide 354)',
      () async {
        final r = await played(
          story(
            beats: [
              {'wait': 100},
              {
                'decide': 'do',
                'options': ['puerta', 'ventana'],
                'pick': 'puerta',
                'line': 'q',
                'tests': 'uno',
              },
            ],
            clips: {'q': 'Q', 'muy_bien': 'M'},
          ),
        );
        expect(r.runner.LOG.single.toJson(), {
          'word': 'uno',
          'asked': 'puerta',
          'got': 'puerta',
          'ok': true,
          'ms': 700,
        });
      },
    );

    test('elige: a choice with no wrong answer; each answer leads somewhere (330, elige 347)', () async {
      final r = await Rig.make(
        story(
          beats: [
            {
              'elige': 'x',
              'options': ['si', 'no'],
              'line': 'q',
              'no': ['n'],
            },
          ],
          clips: {'q': 'Q', 'n': 'N', 's': 'S'},
        ),
      );
      await r.finish((pn) => 'no');
      expect(r.clips, ['q', 'n']);
      expect(r.runner.V['elegido'], 'no');
      expect(r.runner.LOG.single.toJson(), {
        'word': null,
        'asked': 'libre',
        'got': 'no',
        'ok': true,
      });
    });

    test('draw: draws one of the options with the one random source; a name fixes it (331)', () async {
      final r = await played(
        story(
          beats: [
            {
              'draw': 'a',
              'options': ['x', 'y', 'z'],
              'other': 'b',
            },
          ],
        ),
      );
      // Mulberry32(1) first value is .627: floor(.627 * 3) = 1
      expect(r.runner.V['a'], 'y');
      expect(r.runner.V['b'], 'x');
      final f = await played(
        story(
          beats: [
            {
              'draw': 'a',
              'options': ['x', 'y', 'z'],
              'other': 'b',
            },
          ],
        ),
        forced: {'a': 'z'},
      );
      expect(f.runner.V['a'], 'z');
      expect(f.runner.V['b'], 'x');
    });

    test(
      'reparte: deals the options to several names, none twice (332)',
      () async {
        final r = await played(
          story(
            beats: [
              {
                'reparte': ['a', 'b', 'c'],
                'options': ['x', 'y', 'z'],
              },
            ],
          ),
        );
        final got = [r.runner.V['a'], r.runner.V['b'], r.runner.V['c']];
        expect(got.toSet(), {'x', 'y', 'z'});
        // 2 draws, the shuffle of 3 (i = 2, 1)
        final f = await played(
          story(
            beats: [
              {
                'reparte': ['a', 'b'],
                'options': ['x', 'y', 'z'],
              },
            ],
          ),
          forced: {'b': 'x'},
        );
        expect(f.runner.V['b'], 'x');
        expect(f.runner.V['a'], isNot('x'));
      },
    );

    test('calc: sets a variable from a condition (334)', () async {
      final r = await played(
        story(
          beats: [
            {
              'set': {'wet': 1},
            },
            {'calc': 'w', 'cond': 'wet', 'then': 'si', 'else': 'no'},
            {'calc': 'd', 'cond': '!wet', 'then': 'si', 'else': r'no-$w'},
          ],
        ),
      );
      expect(r.runner.V['w'], 'si');
      expect(r.runner.V['d'], 'no-si');
    });

    test('recuerda: keeps a value for later stories, in this feature\'s storage space (335)', () async {
      final mem = MemStore();
      final r = await played(
        story(
          beats: [
            {
              'draw': 'k',
              'options': ['uno'],
            },
            {'recuerda': 'amigo', 'valor': r'$k'},
          ],
        ),
        memory: mem,
      );
      expect(jsonDecode(mem.values['mem']!), {'amigo': 'uno'});
      expect(r.runner.V['mem_amigo'], 'uno');
      expect(r.runner.MEM, {'amigo': 'uno'});
    });

    test('cost: takes a step of the thing at stake (336)', () async {
      final scene = StandInScene();
      final r = await played(
        story(
          beats: [
            {'cost': 1, 'en': 'pan'},
            {'cost': 1},
          ],
        ),
        scene: scene,
      );
      expect(scene.stakes, [
        [1, 3, 'pan'],
        [2, 3, ''],
      ]);
      expect(r.runner.W['lost'], 2);
    });

    test('a step the game does not know is a loud failure (337)', () async {
      for (final bad in <Object?>[
        {'nada': 1},
        7,
        null,
        <Object?>[],
      ]) {
        final r = await Rig.make(story(beats: [bad]));
        Object? err;
        try {
          await r.finish((pn) => null);
        } catch (e) {
          err = e;
        }
        expect(err, isNotNull, reason: '$bad');
      }
    });

    test('the kinds found in paso are the 16 the recording tool names', () {
      final kinds = <String>{};
      for (final s in <Object?>[
        'a',
        {'say': 'a'},
        {'wait': 1},
        {'cam': 'a'},
        {'dots': 1},
        {
          'set': {'a': 1},
        },
        {'if': 'a'},
        {'act': 'a'},
        {'ask': 'a'},
        {'decide': 'a'},
        {'elige': 'a'},
        {'draw': 'a'},
        {
          'reparte': ['a'],
        },
        {'calc': 'a'},
        {'recuerda': 'a'},
        {'cost': 1},
      ]) {
        kinds.add(stepKind(s));
      }
      expect(kinds, {
        'line',
        'say',
        'wait',
        'cam',
        'dots',
        'set',
        'if',
        'act',
        'ask',
        'decide',
        'elige',
        'draw',
        'reparte',
        'calc',
        'recuerda',
        'cost',
      });
      expect(stepKind({'zzz': 1}), 'unknown');
      expect(stepKind(3), 'bad');
    });
  });

  group('\$name filling (juego.js sub 315)', () {
    test('a clip id, an ask, an act\'s fields and a nested step are filled from the story\'s variables', () async {
      final r = await played(
        story(
          beats: [
            {
              'draw': 'k',
              'options': ['uno'],
            },
            r'a_$k',
            {'say': r'b_$k'},
            {
              'ask': r'$k',
              'line': r'q_$k',
              'then': [r'c_$k'],
            },
            r'$nada',
          ],
          clips: {
            'a_uno': 'A',
            'b_uno': 'B',
            'q_uno': 'Q',
            'muy_bien': 'M',
            'c_uno': 'C',
          },
        ),
        scene: StandInScene(
          things: [
            Thing(id: 'uno', box: [10, 10, 20, 20]),
          ],
        ),
      );
      // `$nada` is not set, so it stays as it is: a line with no recording, told by its timing alone
      expect(r.clips, ['a_uno', 'b_uno', 'q_uno', 'muy_bien', 'c_uno']);
      expect(r.runner.LINES.containsKey(r'$nada'), isFalse);
    });

    test(
      'a name that is not set stays as it is; an empty value is filled in',
      () async {
        final r = await Rig.make(
          story(
            beats: [
              {
                'set': {'x': 'w'},
              },
              {'calc': 'e', 'cond': 'x', 'then': '', 'else': ''},
              r'a_$e_$q',
            ],
            clips: {r'a__$q': 'A'},
          ),
        );
        await r.finish((pn) => null);
        expect(r.clips, [r'a__$q']);
      },
    );
  });

  group('the memory between stories', () {
    test('what one story remembers is in V of the next (fresh 16), from the same storage space', () async {
      final mem = MemStore();
      await played(
        story(
          beats: [
            {'recuerda': 'bebida', 'valor': 'jugo'},
          ],
        ),
        memory: mem,
      );
      expect(mem.values.keys, ['mem']);
      final next = await Rig.make(
        story(
          beats: [
            {
              'if': 'mem_bebida=jugo',
              'then': ['a'],
              'else': ['b'],
            },
          ],
          clips: {'a': 'A', 'b': 'B'},
        ),
        memory: mem,
      );
      await next.finish((pn) => null);
      expect(next.clips, ['a']);
      // `?mem=` fixes one for a check
      final fixed = await Rig.make(
        story(
          beats: [
            {
              'if': 'mem_amigo=1',
              'then': ['a'],
              'else': ['b'],
            },
          ],
          clips: {'a': 'A', 'b': 'B'},
        ),
        mem: {'amigo': '1'},
      );
      await fixed.finish((pn) => null);
      expect(fixed.clips, ['a']);
    });

    test(
      'a story that remembers a number remembers it as text, as String(valor)',
      () async {
        final mem = MemStore();
        await played(
          story(
            beats: [
              {'recuerda': 'n', 'valor': 3},
            ],
          ),
          memory: mem,
        );
        expect(jsonDecode(mem.values['mem']!), {'n': '3'});
      },
    );

    test('alterna: the other option than last play, the last pick kept under "<story>.<as>" (decide 354)', () async {
      final mem = MemStore();
      final picks = <String>[];
      for (var i = 0; i < 4; i++) {
        final r = await Rig.make(
          story(
            beats: [
              {
                'decide': 'do',
                'options': ['a', 'b'],
                'as': 'k',
                'alterna': true,
                'line': 'q',
              },
            ],
            clips: {'q': 'Q', 'muy_bien': 'M'},
          ),
          scene: StandInScene(
            things: [
              Thing(id: 'a', box: [0, 0, 9, 9]),
              Thing(id: 'b', box: [20, 0, 9, 9]),
            ],
          ),
          memory: mem,
        );
        await r.finish((pn) => pn.pick);
        picks.add(r.runner.V['k'] as String);
      }
      // the first play draws; each next one is the other
      expect(picks[1], isNot(picks[0]));
      expect(picks[2], picks[0]);
      expect(picks[3], picks[1]);
      expect(jsonDecode(mem.values['ult']!), {'prueba.k': picks[3]});
    });
  });
}

class _RemapScene extends StandInScene {
  _RemapScene(this.seen);

  final List<List<num>> seen;

  @override
  List<num> remap(List<num> xy) {
    seen.add(xy);
    return [xy[0] + 1, xy[1] + 2];
  }
}
