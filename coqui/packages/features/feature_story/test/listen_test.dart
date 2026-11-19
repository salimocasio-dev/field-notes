// Listen mode (juego.js `?oir=1`, Escuchar: Otra vez): the story told straight through, nothing to touch.
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

final things = [
  Thing(id: 'puerta', box: [10, 10, 20, 20]),
  Thing(id: 'ventana', box: [60, 10, 20, 20]),
];

const clips = {'q': 'Q', 'muy_bien': 'M', 'si_dice': 'S', 'a': 'A', 'b': 'B'};

void main() {
  test('the asks answer themselves: the question, the signal that only bounces, no praise, nothing filed', () async {
    final s = story(beats: [
      {'wait': 100},
      {'ask': 'puerta', 'line': 'q', 'then': ['a']},
      {'decide': 'do', 'options': ['puerta', 'ventana'], 'pick': 'ventana', 'line': 'q', 'right': ['b']},
      {'elige': 'x', 'options': ['si', 'no'], 'line': 'q', 'si': ['a']},
    ], clips: clips);
    final r = await Rig.make(s, listen: true, scene: StandInScene(things: things));
    await r.finish((pn) => fail('a question was waited for: ${pn.live}'));
    // each question once (at 350 ms), what it leads to; the right answer is taken; no "¡Muy bien!"
    expect(r.clips, ['q', 'a', 'q', 'b', 'q', 'a']);
    // the decide files nothing (`!OIR`); an elige writes its free choice to the log whatever the mode (juego.js 349)
    expect(r.runner.LOG.map((d) => d.asked), ['libre']);
    expect(r.sounds.where((x) => x == 'right'), isEmpty);
    expect(r.runner.W['lost'], 0);
    // the end: Listen has no next story: Play again and Map
    expect(r.runner.view.foot.next, isFalse);
    expect(r.runner.view.foot.again, isTrue);
  });

  test('at the end: progress.listened(id), the minutes; the story is not scored', () async {
    final r = await Rig.make(story(beats: ['q'], clips: clips), listen: true);
    await r.finish((pn) => null);
    expect(r.progress.listenedIds, ['prueba']);
    expect(r.progress.finished, isEmpty);
    expect(r.progress.minutesAdded, hasLength(1));
  });

  test('a story with a next one still has no Next story button in Listen mode', () async {
    final r = await Rig.make(story(beats: ['q'], clips: clips, extra: {'next': 'otra'}), listen: true);
    await r.finish((pn) => null);
    expect(r.runner.view.screen, StoryScreenState.end);
    expect(r.runner.view.foot, const StoryFoot(next: false, again: true, home: true, map: false));
  });

  test('no answer bubbles are shown (the story answers itself)', () async {
    final s = story(beats: [
      {'wait': 100},
      {'decide': 'say', 'options': ['si', 'no'], 'pick': 'si', 'line': 'q', 'said': {'si': 'si_dice'}},
    ], clips: clips);
    final r = await Rig.make(s, listen: true);
    await r.start();
    await r.advance(200);
    expect(r.runner.W['resp'], isNull);
    await r.until(() => !r.runner.running);
    expect(r.clips, ['q', 'si_dice']);
  });

  test('a touch does nothing: nothing is asked', () async {
    final scene = StandInScene(things: things);
    final r = await Rig.make(story(beats: [{'wait': 100}, {'ask': 'puerta', 'line': 'q'}, {'wait': 3000}], clips: clips), listen: true, scene: scene);
    await r.start();
    await r.advance(500);
    expect(r.runner.pendingNow, isNull);
  });
}
