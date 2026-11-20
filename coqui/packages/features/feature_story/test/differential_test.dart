// The runner against the old page's recorded runs (coqui/ref/trazas/, 51 files, three plans each).
//
// - On a stand-in scene that replays what the old scene did (tool/replay_scene.dart, from test/fixtures/acts/): every one of
//   the 153 runs, the whole trace equal: decisions, marks, lost, ending, the story result, the order of clips, the steps,
//   choices and touches, the number of random draws, the memory, and every time (`t`, virtualMs, the minutes). Only the
//   touches' places on the old screen (x, y) are left out.
// - On the real El frente: the traces of every file that plays on it, all three plans, once its scene is in the registry.
// - On the real El balcón (order 30b): the same, for its four files.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart' show Mulberry32;
import 'package:coqui_pixel/coqui_pixel.dart' show Escena;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene, StillFrame;
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_story/src/play/trace_json.dart' show firstDifference;
import 'package:feature_story/src/play/virtual_parts.dart' show CountingRng;
import 'package:feature_story/src/screen/scene_frame.dart' show registryScenes;

import '../tool/differential.dart';
import '../tool/disk_course.dart';
import '../tool/frente_order.dart';
import 'real_scene.dart';

/// A trace without the places in its scene's state line (`estado`: balcon.js writes where each glass and the bird
/// are, `@x` and `@x,y`): the new picture puts them elsewhere, as it does the touches (which the comparison leaves out).
Map<String, dynamic> placeless(Map<String, dynamic> t) => {
  ...t,
  if (t['estado'] is String)
    'estado': (t['estado'] as String).replaceAll(
      RegExp(r'@-?[\d.]+(,-?[\d.]+)?'),
      '@_',
    ),
};

/// Each balcon run's first difference with the old trace, time and hops included (null: equal whole).
final Map<String, String?> balconWhole = {};

void main() {
  final root = findRoot();
  final trazas = Directory('${root.path}/coqui/ref/trazas');
  final acts = Directory('test/fixtures/acts');
  final runs =
      (jsonDecode(File('${trazas.path}/runs.json').readAsStringSync())['runs']
              as List)
          .cast<Map<String, dynamic>>();
  final stories = {for (final r in runs) r['story'] as String}.toList();
  late DiskCourse course;

  setUpAll(() async {
    course = DiskCourse(root);
    await course.load();
  });

  group('the recorded runs, on a scene that replays the old one', () {
    for (final s in stories) {
      test('$s: the three plans, whole', () async {
        for (final plan in ['right', 'wrong', 'alternate']) {
          expect(
            await compareRun(course, s, plan, acts, trazas),
            isNull,
            reason: '$s $plan',
          );
        }
      });
    }
  });

  // The real El frente (order 14): its sheet puts the frog and the views in the new picture, so the runs are the old ones in
  // everything but time. Two reproduce whole; in the other thirteen the first step that differs is a step after a call of the
  // scene that took less time than the old one: `camGo("casa")` is no move (the sheet's `casa` view is its `wide` one: the
  // old one slid 16 ticks and back 12), or `ir`/`tocar` make one hop fewer (each is 5 ticks and 110 ms: 460 ms) because the
  // frog's spots are nearer in the new picture.
  group('the recorded runs, on the real El frente (order 14)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final frente = {
      for (final r in runs)
        if (r['scene'] == 'frente') r['story'] as String,
    };
    const whole = {'el-bizcocho wrong', 'el-bizcocho alternate'};
    for (final s in frente) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            // a new scene for each run: the scene keeps its own state
            final scene = await realScene('frente');
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              (rng) => scene,
              thingOrder: frenteThingOrder,
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            final c = lastCompared!;
            expect(
              firstDifference(forTimeless(c.committed), forTimeless(c.trace)),
              isNull,
              reason: '$s $plan',
            );
            if (whole.contains('$s $plan')) {
              expect(d, isNull, reason: '$s $plan whole');
            }
          }
        },
      );
    }
  });

  // The real El balcón (order 30b): its sheet puts the frog, abuela and the drinks in the new picture, so the runs are the old
  // ones in everything but time, the frog's hop sounds (page 13, order 21's result) and the places its state line writes. The scene draws its random numbers
  // (`azar`: which side each glass and jug is on) from the game's one source, as the old one drew from Math.random.
  group('the recorded runs, on the real El balcón (order 30b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final balcon = {
      for (final r in runs)
        if (r['scene'] == 'balcon') r['story'] as String,
    };
    for (final s in balcon) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            // a new scene for each run, given the run's random source
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('balcon'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            expect(
              firstDifference(
                placeless(forTimeless(c.committed)),
                placeless(forTimeless(c.trace)),
              ),
              isNull,
              reason: '$s $plan (whole: ${d ?? 'equal'})',
            );
            // the whole trace, time and hops included: printed for the order's report, not a condition
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            balconWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    // the screen's scene factory gives the scene the story runner's random source (`_s.rng`): `pone` draws which side each jug
    // is on, once, from it; El frente draws none
    test(
      'registryScenes gives the scene the random source it is given',
      () async {
        final rng = CountingRng(Mulberry32(1));
        final made = await registryScenes('balcon', rng);
        StillFrame(made.scene as SetScene).host.fresh();
        expect(rng.draws, 0);
        await (made.scene as Escena).acts['pone']!({});
        expect(rng.draws, 1);
        final frente = CountingRng(Mulberry32(1));
        await registryScenes('frente', frente);
        expect(frente.draws, 0);
      },
    );
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/balcon-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in balconWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}'].join('\n')}\n',
        );
    });
  });
}
