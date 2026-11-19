// The voice and the words on screen (juego.js: say 113, playClip 108, dur 107, partes 123, muestra 130, letras 137): the line
// is the recording when every line of the story has one; when a clip is missing the lines are timed and still said; the words
// follow the TXT setting.
import 'package:feature_story/src/play/virtual_parts.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

void main() {
  group('the timed-line fallback (juego.js dur 107 and say 113)', () {
    test('every clip has a recording: the lines are played by the clip player, each then a pause of 420 ms', () async {
      final r = await Rig.make(
        story(beats: ['a', 'b'], clips: {'a': 'uno dos', 'b': 'tres'}),
      );
      await r.finish((pn) => null);
      expect(r.runner.VOICE, isTrue);
      expect(r.clips, ['a', 'b']);
      expect(r.timers.now, 420 + 420 + 1200);
    });

    test('one clip is missing: VOICE is off and every line is told by its words: 360 ms a word + 300, then the pause', () async {
      final r = await Rig.make(
        story(beats: ['a', 'b'], clips: {'a': 'uno dos', 'b': 'tres'}),
        course: TestCourse(missing: {'b'}),
      );
      await r.finish((pn) => null);
      expect(r.runner.VOICE, isFalse);
      expect(r.clips, isEmpty); // nothing went to the clip player
      // a: 2 words: 360 * 2 + 300 = 1020, then 420; b: 1 word: 660, then 420; the end 1200
      expect(r.timers.now, 1020 + 420 + 660 + 420 + 1200);
    });

    test('the words of a line are counted as the old page counts them (split on white space; no text: two words)', () async {
      final r = await Rig.make(
        story(beats: ['a', 'b'], clips: {'a': '  uno   dos tres ', 'b': ''}),
        course: TestCourse(missing: {'a'}),
      );
      await r.finish((pn) => null);
      // " uno dos tres ".split(/\s+/) is ["", "uno", "dos", "tres", ""]: 5 words; "" is the guess of two
      expect(r.runner.dur('a'), (360 * 5 + 300) / 1000);
      expect(r.runner.dur('b'), (360 * 2 + 300) / 1000);
    });

    test(
      'preload says a clip could not be made ready: the same fallback',
      () async {
        late _FailingPlayer player;
        final r = await Rig.make(
          story(beats: ['a'], clips: {'a': 'uno'}),
          playerFor: (timers, course) =>
              player = _FailingPlayer(timers, course, {'a'}),
        );
        await r.finish((pn) => null);
        expect(player.preloaded, ['a']);
        expect(r.runner.VOICE, isFalse);
        expect(r.timers.now, 660 + 420 + 1200);
      },
    );

    test(
      'a recorded line lasts as its marks say; a missing one is not played',
      () async {
        final r = await Rig.make(
          story(beats: ['a'], clips: {'a': 'uno'}),
          course: TestCourse(lengths: {'a': 2500}),
        );
        expect(r.runner.dur('a'), 2.5);
      },
    );

    test('speech bubbles that speak by ear (`voces`) use the timed line when the clip is missing', () async {
      final scene = StandInScene();
      final r = await Rig.make(
        story(
          beats: [
            {'wait': 100},
            {
              'ask': 'puerta',
              'line': 'q',
              'resp': ['si', 'no'],
              'voces': {'si': 'vsi', 'no': 'vno'},
            },
          ],
          clips: {'q': 'Q', 'vsi': 'uno dos', 'vno': 'tres', 'muy_bien': 'M'},
        ),
        scene: scene,
        course: TestCourse(missing: {'vno'}),
      );
      await r.start();
      await r.untilAsked();
      // q (1 word: 660 ms) and the pause of 300 a question with voices has, then the two voices: (2 words) 1020, a pause
      // of 700, (1 word) 660
      expect(r.timers.now, 100 + 660 + 300 + 1020 + 700 + 660);
    });
  });

  group('the words on screen (juego.js: TXT, partes 123, muestra 130, borra 136)', () {
    final clips = {'n': 'La casa', 'f': 'tu:Hola', 'p': 'Abuela: Hola, hola'};

    Future<Rig> rig(
      TxtMode txt, {
      Map<String, List<num>> talk = const {},
    }) async {
      final s = story(
        beats: [
          {'wait': 100},
          'n',
          {'wait': 3000},
        ],
        clips: clips,
      );
      (s['clips'] as Map)['p'] = {
        'who': 'narr',
        'text': 'Abuela: Hola, hola',
        'habla': 'abuela',
      };
      return Rig.make(
        s,
        txt: txt,
        scene: StandInScene(talk: talk),
      );
    }

    test(
      'con: the caption shows while the line is said and goes 1700 ms after it',
      () async {
        final r = await rig(TxtMode.con);
        await r.start();
        await r.advance(50);
        expect(r.runner.cap, '');
        await r.advance(100); // t = 150: the clip is playing (it ends in 0 ms; the caption stays 1700 ms)
        expect(r.runner.cap, 'La casa');
        await r.advance(1600);
        expect(r.runner.cap, 'La casa');
        await r.advance(200);
        expect(r.runner.cap, '');
      },
    );

    test('tras: the words come right after the line and stay for the longer of 1800 ms and 70 ms a letter', () async {
      final r = await rig(TxtMode.tras);
      await r.start();
      await r.advance(100);
      // the clip ends in 0 ms: the words show at once, for max(1800, 7 * 70) = 1800 ms
      expect(r.runner.cap, 'La casa');
      await r.advance(1750);
      expect(r.runner.cap, 'La casa');
      await r.advance(100);
      expect(r.runner.cap, '');
    });

    test('no: the words never show', () async {
      final r = await rig(TxtMode.no);
      await r.start();
      for (var i = 0; i < 5; i++) {
        await r.advance(300);
        expect(r.runner.cap, '');
        expect(r.runner.bubText, '');
      }
    });

    test('the frog\'s lines (`who: tu`) show in a bubble at the frog, never as a caption', () async {
      final s = story(
        beats: [
          {'wait': 100},
          'f',
          {'wait': 3000},
        ],
        clips: {'f': 'tu:Hola'},
      );
      final r = await Rig.make(s);
      await r.start();
      await r.advance(150);
      expect(r.runner.cap, '');
      expect(r.runner.bubText, 'Hola');
      expect(r.runner.view.bubbleWho, 'coqui');
      expect(r.runner.TALK, isNull); // the clip has ended: his mouth is closed
    });

    test('a person\'s line: the name as a caption, the words in a bubble at her; with nobody to point at, all in the caption', () async {
      final seen = await rig(
        TxtMode.con,
        talk: {
          'abuela': [100, 100],
        },
      );
      expect(seen.runner.partes('p'), (
        cap: 'Abuela:',
        quien: 'abuela',
        bub: 'Hola, hola',
        all: 'Abuela: Hola, hola',
      ));
      final s = story(
        beats: [
          {'wait': 100},
          'p',
          {'wait': 3000},
        ],
        clips: {},
      );
      (s['clips'] as Map)['p'] = {
        'who': 'narr',
        'text': 'Abuela: Hola, hola',
        'habla': 'abuela',
      };
      final at = await Rig.make(
        s,
        scene: StandInScene(
          talk: {
            'abuela': [100, 100],
          },
        ),
      );
      await at.start();
      await at.advance(150);
      expect(at.runner.cap, 'Abuela:');
      expect(at.runner.bubText, 'Hola, hola');
      final nobody = await Rig.make(s);
      await nobody.start();
      await nobody.advance(150);
      expect(nobody.runner.cap, 'Abuela: Hola, hola');
      expect(nobody.runner.bubText, '');
    });

    test('while a line is said TALK says who talks', () async {
      final r = await Rig.make(story(beats: ['f'], clips: {'f': 'tu:Hola'}));
      await r.start();
      expect(r.runner.TALK, 'coqui');
      expect(r.runner.live, hasLength(1));
      expect(r.runner.speaking, 1);
      await r.advance(10);
      expect(r.runner.TALK, isNull);
      expect(r.runner.speaking, 0);
    });
  });
}

/// A clip player that cannot make some clips ready.
class _FailingPlayer extends VirtualClipPlayer {
  _FailingPlayer(super.timers, super.course, this.failing);

  final Set<String> failing;
  final List<String> preloaded = [];

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    preloaded.addAll(clipIds);
    return [
      for (final id in clipIds)
        if (failing.contains(id)) id,
    ];
  }
}
