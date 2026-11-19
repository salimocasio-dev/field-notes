// Waiting for a touch, and what a touch does (juego.js: espera 162, tap 181, poke 179, senal 196). A touch is made by thing
// id (`tapThing`) or by place (`tap`, which finds the thing with the scene's hit test).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'support/rig.dart';
import 'support/stories.dart';

final things = [
  Thing(id: 'puerta', box: [10, 10, 20, 20]),
  Thing(id: 'ventana', box: [60, 10, 20, 20]),
  Thing(id: 'casa', box: [100, 10, 20, 20]),
];
const clips = {'q': 'Q', 'muy_bien': 'M', 'p_n': 'PN', 'v_n': 'VN', 'cq_n': 'CN', 'otra': 'O'};

Map<String, dynamic> ask(Map<String, dynamic> a, {Map<String, dynamic> extra = const {}}) => story(
  beats: [{'wait': 100}, {'ask': 'puerta', 'line': 'q', ...a}],
  clips: clips,
  extra: {'names': {'ventana': 'v_n', 'puerta': 'p_n', 'coqui': 'cq_n'}, ...extra},
);

void main() {
  group('a touch', () {
    test('by place: the scene\'s hit test finds the thing; a touch outside everything does nothing', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(ask({}), scene: scene);
      await r.start();
      await r.untilAsked();
      r.runner.tap(300, 150);
      await r.drain();
      expect(r.runner.pendingNow, isNotNull);
      expect(scene.pokes, isEmpty);
      r.runner.tap(20, 20); // the door
      await r.until(() => !r.runner.running);
      expect(r.clips, ['q', 'muy_bien']);
    });

    test('a thing that is not the answer is poked: a blip, three stars, the scene\'s own poke; it is named, then the question again', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(ask({}), scene: scene);
      await r.start();
      await r.untilAsked();
      r.touch('ventana');
      expect(scene.pokes, ['ventana']);
      expect(r.sounds.last, 'blip');
      expect((r.runner.W['fx'] as List).last, {'t': 'star', 'n': 7, 'pts': [[93, 96], [108, 102], [100, 90]], 'f0': r.runner.F});
      expect(r.runner.pendingNow!.busy, isTrue);
      await r.until(() => !r.runner.pendingNow!.busy, what: 'the name');
      // the name of what he touched, then the question asked again
      expect(r.clips, ['q', 'v_n', 'q']);
      expect(r.runner.pendingNow, isNotNull);
      expect(r.runner.LOG, isEmpty);
    });

    test('poking is free: it never costs a step', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(ask({}), scene: scene);
      await r.start();
      await r.untilAsked();
      for (var i = 0; i < 3; i++) {
        r.touch('casa');
        await r.drain();
      }
      expect(r.runner.W['lost'], 0);
      expect(scene.stakes, isEmpty);
    });

    test('the frog: he bounces and says his name, or the coquí sound when he has no name clip', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(ask({}), scene: scene);
      await r.start();
      await r.untilAsked();
      r.touch('coqui');
      expect(r.clips.last, 'cq_n'); // he says his name (when no line is playing)
      await r.advance(2000);
      final noName = await Rig.make(ask({}, extra: {'names': {}}), scene: scene);
      await noName.start();
      await noName.untilAsked();
      noName.touch('coqui');
      expect(noName.sounds.last, 'coqui');
    });

    test('a touch on the answer counts from the first word of the lead-in', () async {
      final r = await Rig.make(ask({'lead': ['otra']}), scene: StandInScene(things: things));
      await r.start();
      await r.until(() => r.runner.pending != null);
      r.touch('puerta');
      await r.until(() => !r.runner.running);
      expect(r.runner.W['lost'], 0);
      expect(r.clips, ['otra', 'muy_bien']);
    });

    test('loose: before the door has a name, the door is the house', () async {
      final r = await Rig.make(story(beats: [{'wait': 100}, {'ask': 'casa', 'loose': true, 'line': 'q'}], clips: clips), scene: StandInScene(things: things));
      await r.start();
      await r.untilAsked();
      r.touch('puerta');
      await r.until(() => !r.runner.running);
      expect(r.clips, ['q', 'muy_bien']);
      final strict = await Rig.make(story(beats: [{'wait': 100}, {'ask': 'casa', 'line': 'q'}], clips: clips), scene: StandInScene(things: things));
      await strict.start();
      await strict.untilAsked();
      strict.touch('puerta');
      await strict.drain();
      expect(strict.runner.pendingNow, isNotNull);
    });

    test('alias: a thing that stands for another', () async {
      final r = await Rig.make(story(beats: [
        {'wait': 100},
        {'decide': 'do', 'options': ['casa', 'ventana'], 'pick': 'casa', 'alias': {'puerta': 'casa'}, 'line': 'q'},
      ], clips: clips), scene: StandInScene(things: things));
      await r.start();
      await r.untilAsked();
      r.touch('puerta');
      await r.until(() => !r.runner.running);
      expect(r.runner.LOG.single.got, 'casa');
      expect(r.runner.LOG.single.ok, isTrue);
    });

    test('a touch when nothing is asked is a poke when the story runs', () async {
      final scene = StandInScene(things: things);
      final r = await Rig.make(story(beats: [{'wait': 5000}], clips: clips, extra: {'names': {'ventana': 'v_n'}}), scene: scene);
      r.touch('ventana');
      expect(scene.pokes, isEmpty); // not running yet
      await r.start();
      await r.advance(100);
      r.touch('ventana');
      expect(scene.pokes, ['ventana']);
      await r.advance(100);
      expect(r.clips, ['v_n']);
    });

    test('the question is asked again every 9 s while he waits; a routine\'s sign comes after the second time', () async {
      final r = await Rig.make(
        story(beats: [{'wait': 100}, {'decide': 'do', 'libre': true, 'options': ['puerta', 'ventana'], 'pick': 'puerta', 'line': 'q'}], clips: clips),
        scene: StandInScene(things: things),
      );
      await r.start();
      await r.untilAsked();
      final t0 = r.timers.now;
      expect(r.clips, ['q']);
      await r.advance(9000);
      expect(r.clips, ['q', 'q']);
      expect(r.runner.W['spot'], isNull);
      await r.advance(9000);
      expect(r.clips, ['q', 'q', 'q']);
      expect(r.runner.W['spot'], 'puerta');
      expect(r.timers.now - t0, 18000);
    });
  });

  group('the signal for a right move (juego.js senal 196)', () {
    test('a sound, a bounce and six stars; not when the story is quiet (callado)', () async {
      final r = await Rig.make(ask({}), scene: StandInScene(things: things));
      await r.finish((pn) => 'puerta');
      expect(r.sounds.where((s) => s == 'right'), hasLength(1));
      final q = await Rig.make(ask({}, extra: {'callado': true}), scene: StandInScene(things: things));
      await q.finish((pn) => 'puerta');
      expect(q.sounds.where((s) => s == 'right'), isEmpty);
      expect(q.clips, ['q']); // no "¡Muy bien!" either
    });
  });
}
