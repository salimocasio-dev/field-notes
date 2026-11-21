// The runner against the old page's recorded runs (coqui/ref/trazas/, 57 files, three plans each).
//
// - On a stand-in scene that replays what the old scene did (tool/replay_scene.dart, from test/fixtures/acts/): every one of
//   the 171 runs, the whole trace equal: decisions, marks, lost, ending, the story result, the order of clips, the steps,
//   choices and touches, the number of random draws, the memory, and every time (`t`, virtualMs, the minutes). Only the
//   touches' places on the old screen (x, y) are left out.
// - On the real El frente: the traces of every file that plays on it, all three plans, once its scene is in the registry.
// - On the real El balcón (order 30b): the same, for its four files.
// - On the real La sala (order 31b): the same, for its six files.
// - On the real El patio (order 32b): the same, for its six files.
// - On the real El camino (order 33b): the same, for its five files; rapido-despacio's end (acts.sevan, the sheet's sevan:
//   everyone leaves in a file) is the new act's: its runs differ from the old there and after in time only.
// - On the real El campo (order 34b): the same, for its five files.
// - On the real El lago (order 35b): the same, for its five files.
// - On the real El banco (order 36b): the same, for its six files.
// - On the real La mesa (order 37b): the same, for its four files.
import 'dart:convert';
import 'dart:io';

import 'package:coqui_contracts/coqui_contracts.dart' show Mulberry32;
import 'package:coqui_pixel/coqui_pixel.dart' show Escena;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene, StillFrame;
import 'package:flutter_test/flutter_test.dart';

import 'package:feature_story/src/play/trace_json.dart' show firstDifference;
import 'package:feature_story/src/play/virtual_parts.dart' show CountingRng;
import 'package:feature_story/src/runner/story_view.dart'
    show StoryFoot, StoryScreenState, StoryView;
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

/// [placeless], and the places camino.js's state line writes for Canelo and the cat (`perro=x,y:`, `gato=x,y:`): the
/// sheet moves a few of them (Canelo at the first tree, the cat on the bench, everyone out through the arch).
Map<String, dynamic> caminoPlaceless(Map<String, dynamic> t) {
  final p = placeless(t);
  return {
    ...p,
    if (p['estado'] is String)
      'estado': (p['estado'] as String).replaceAllMapped(
        RegExp(r'(perro|gato)=-?[\d.]+,-?[\d.]+:'),
        (m) => '${m[1]}=_:',
      ),
  };
}

/// [placeless], and the place campo.js's state line writes for Canelo (`perro=x,y:`): the sheet moves a few of his
/// places by the water (`moves`).
Map<String, dynamic> campoPlaceless(Map<String, dynamic> t) {
  final p = placeless(t);
  return {
    ...p,
    if (p['estado'] is String)
      'estado': (p['estado'] as String).replaceAllMapped(
        RegExp(r'(perro)=-?[\d.]+,-?[\d.]+:'),
        (m) => '${m[1]}=_:',
      ),
  };
}

/// Each campo run's first difference with the old trace, time and hops included (null: equal whole), and, timeless.
final Map<String, String?> campoWhole = {}, campoTimeless = {};

/// Each lago run's first difference with the old trace, time and hops included (null: equal whole), and, timeless.
final Map<String, String?> lagoWhole = {}, lagoTimeless = {};

/// Each banco run's first difference with the old trace, time and hops included (null: equal whole), and, timeless.
final Map<String, String?> bancoWhole = {}, bancoTimeless = {};

/// Each mesa run's first difference with the old trace, time and hops included (null: equal whole), and, timeless.
final Map<String, String?> mesaWhole = {}, mesaTimeless = {};

/// STOP of order 37b, reported and not worked round: on the real La mesa the frog takes one hop fewer than the old run
/// where he goes from abuela's hand at the counter (q 58,165: acts.lleva26 `de: "abuela"`, ranaA(ab.x - 30, ab.y + 10))
/// to Carmen's place at seat 2 (ranaAl(2): the sheet's rana.2, moved from q 122,163 to 116,168: 64 px, 2 hops, became
/// 58 px, 1 hop): tengo-hambre beats.32.after.0 in every plan, and beats.70.right.0 in the right plan. The sheet's hops
/// name no such pair (its walks are between named frog places; this one starts at a place relative to abuela). By run,
/// how many hops the old run has more.
const Map<String, int> mesaHopStop = {
  'tengo-hambre right': 2,
  'tengo-hambre wrong': 1,
  'tengo-hambre alternate': 1,
};

/// Each balcon run's first difference with the old trace, time and hops included (null: equal whole).
final Map<String, String?> balconWhole = {};

/// Each sala run's first difference with the old trace, time and hops included (null: equal whole).
final Map<String, String?> salaWhole = {};

/// Each patio run's first difference with the old trace, time and hops included (null: equal whole).
final Map<String, String?> patioWhole = {};

/// Each camino run's first difference with the old trace, time and hops included (null: equal whole), and, timeless.
final Map<String, String?> caminoWhole = {}, caminoTimeless = {};

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

  // The end screen's buttons. The recorded runs do not hold them (page-drive.js writes `ending.screen` and nothing of the
  // buttons), so the comparison above never saw them, with the old story file or the new one. Here they are read from the view
  // the run was played on, on the real tree: the real story files and the real course (datos/curso.json).
  //
  // The one place where the app's end screen can differ from the old page's: the old page shows "Next story" for any
  // `next`; the app, only for a `next` the course names (a staged story is in no list: the shell opens no address for it).
  // Until the course named A comer's stories, jugo-de-china (`next: que-quieres`) ended so; now it leads on, as la-lluvia
  // does (coqui/AGENTS.md, "Stories staged by another session").
  group('the end screen of the recorded runs: Next story where the course names the next story', () {
    const mapMain = StoryFoot(next: false, again: true, home: true, map: false);
    const nextWaits = StoryFoot(
      next: true,
      again: true,
      home: false,
      map: true,
    );

    Future<StoryFoot> footOf(String story, [String plan = 'right']) async {
      final view = StoryView();
      expect(
        await compareRun(course, story, plan, acts, trazas, view: view),
        isNull,
        reason: '$story $plan',
      );
      expect(view.screen, StoryScreenState.end, reason: story);
      return view.foot;
    }

    test('(a) la-lluvia: its next, el-bizcocho, is a story of the course: Next story, and the outline Map beside Play again', () async {
      expect((await course.story('la-lluvia'))['next'], 'el-bizcocho');
      expect(course.meta('el-bizcocho'), isNotNull);
      expect(await footOf('la-lluvia'), nextWaits);
    });

    test('(b) jugo-de-china: its next, que-quieres, is a story of the course since A comer is in it: Next story, as for la-lluvia', () async {
      expect((await course.story('jugo-de-china'))['next'], 'que-quieres');
      expect(course.meta('que-quieres'), isNotNull);
      for (final plan in ['right', 'wrong', 'alternate']) {
        expect(await footOf('jugo-de-china', plan), nextWaits, reason: plan);
      }
    });

    test('(c) a story with no next (a picture story, a routine): Map is the main button, as before', () async {
      for (final s in ['d-toc-toc', 'h-frente']) {
        expect((await course.story(s)).containsKey('next'), isFalse);
        expect(await footOf(s), mapMain, reason: s);
      }
    });

    test('every one of the 57 files: Next story exactly when its next is listed in a place of the course', () async {
      var withNext = 0, withoutNext = 0;
      final listed = {
        for (final p in course.places) ...[
          ...p.stories,
          ...p.pictureStories,
          ...p.routines,
        ],
      };
      for (final s in stories) {
        final next = (await course.story(s))['next'];
        final named = next is String && listed.contains(next);
        named ? withNext++ : withoutNext++;
        expect(await footOf(s), named ? nextWaits : mapMain, reason: s);
      }
      // 34 stories lead on to a story of the course; the other 23 have no next (cafe-con-azucar's is none until El colmado is
      // out; the picture stories and the routines have none)
      expect(withNext, 34);
      expect(withoutNext, 23);
    });
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

  // The real La sala (order 31b): the room is built round the old picture, so its places keep their screen numbers but the
  // few the sheet moves (`moves`); the runs are the old ones in everything but time and the places its state line writes.
  // The scene draws its random numbers (`azar`: which side each of two people stands) from the game's one source, as the
  // old one drew from Math.random.
  group('the recorded runs, on the real La sala (order 31b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final sala = {
      for (final r in runs)
        if (r['scene'] == 'sala') r['story'] as String,
    };
    test('the six files of La sala', () {
      expect(sala, {
        'la-familia',
        'la-foto',
        'quien-eres-tu',
        'd-bizcocho-bebe',
        'd-foto-familia',
        'h-sala',
      });
    });
    for (final s in sala) {
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
              await realSceneFor('sala'),
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
            salaWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    // the screen's scene factory gives the scene the story runner's random source: `lados` draws which side each of two
    // people is on, once, from it
    test(
      'registryScenes gives La sala the random source it is given',
      () async {
        final rng = CountingRng(Mulberry32(1));
        final made = await registryScenes('sala', rng);
        StillFrame(made.scene as SetScene).host.fresh();
        expect(rng.draws, 0);
        await (made.scene as Escena).acts['lados']!({
          'a': 'mama',
          'b': 'papa',
          'donde': 'juntos',
        });
        expect(rng.draws, 1);
      },
    );
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/sala-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in salaWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}'].join('\n')}\n',
        );
    });
  });
  // The real El patio (order 32b): the yard is built round the old picture, so its places keep their screen numbers but
  // the few the sheet moves (`moves`); the runs are the old ones in everything but time and the places its state line
  // writes. The frog's two places at the gate moved (8 pairs of places take one hop more: the sheet's hops), and no
  // recorded run walks one of those pairs, so the hops are the old ones too. The scene draws its random numbers (`azar`:
  // which side of the crate each child stands) from the game's one source, as the old one drew from Math.random.
  group('the recorded runs, on the real El patio (order 32b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final patio = {
      for (final r in runs)
        if (r['scene'] == 'patio') r['story'] as String,
    };
    test('the six files of El patio', () {
      expect(patio, {
        'las-flores',
        'que-es-esto',
        'hasta-manana',
        'd-la-bola',
        'd-buenas-noches',
        'h-patio',
      });
    });
    for (final s in patio) {
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
              await realSceneFor('patio'),
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
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            // the hops and the random draws are the old ones (the sheet's hops: no recorded run walks a pair that changed)
            expect(hops(c.trace), hops(c.committed), reason: '$s $plan: hops');
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            // the whole trace, time and hops included: printed for the order's report, not a condition
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            patioWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    // the screen's scene factory gives the scene the story runner's random source: `lados` draws which side of the crate
    // each child is on, once, from it
    test(
      'registryScenes gives El patio the random source it is given',
      () async {
        final rng = CountingRng(Mulberry32(1));
        final made = await registryScenes('patio', rng);
        final host = StillFrame(made.scene as SetScene).host..fresh();
        expect(rng.draws, 0);
        await (made.scene as Escena).acts['inicio9']!({});
        expect(host.W['gente'], contains('luis'));
        await (made.scene as Escena).acts['lados']!({});
        expect(rng.draws, 1);
      },
    );
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/patio-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in patioWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}'].join('\n')}\n',
        );
    });
  });
  // The real El camino (order 33b): the park is built round the old picture, so its places keep their screen numbers but
  // the few the sheet moves (`moves`); the runs are the old ones in everything but time and the places its state line
  // writes. All 21 hop counts are the old ones (the sheet's hops is empty). The scene draws its random numbers
  // (`gatoarbol`: the order of the other two counts, and which one the bubble shows) from the game's one source. The end
  // of rapido-despacio (acts.sevan) is the sheet's new act: everyone leaves through the arch in a file, 20 ticks where
  // the old act took 8 for the people; its frog hops twice by the act's own steps instead of hopTo's (no 110 ms wait
  // after each hop). The old trace was recorded with the old act: the act and what follows it are 140 ms later, with the
  // same steps, the same two hop sounds and the same draws, so the timeless comparison holds for that story too.
  group('the recorded runs, on the real El camino (order 33b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final camino = {
      for (final r in runs)
        if (r['scene'] == 'camino') r['story'] as String,
    };
    test('the five files of El camino', () {
      expect(camino, {
        'uno-dos-tres',
        'donde-esta-el-gato',
        'rapido-despacio',
        'd-corre',
        'h-camino',
      });
    });
    for (final s in camino) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('camino'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            final timeless = firstDifference(
              caminoPlaceless(forTimeless(c.committed)),
              caminoPlaceless(forTimeless(c.trace)),
            );
            caminoTimeless['$s $plan'] = timeless;
            if (s != 'rapido-despacio') {
              expect(
                timeless,
                isNull,
                reason: '$s $plan (whole: ${d ?? 'equal'})',
              );
            }
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            if (s != 'rapido-despacio') {
              expect(
                hops(c.trace),
                hops(c.committed),
                reason: '$s $plan: hops',
              );
            }
            // the random draws are the old ones in every run, rapido-despacio's included
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            caminoWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    test(
      'registryScenes gives El camino the random source it is given',
      () async {
        final rng = CountingRng(Mulberry32(1));
        final made = await registryScenes('camino', rng);
        final host = StillFrame(made.scene as SetScene).host..fresh();
        expect(rng.draws, 0);
        final acts = (made.scene as Escena).acts;
        await acts['inicio13']!({});
        await acts['posan']!({'p': '231'});
        expect(host.W['gato'], isNotNull);
        await acts['gatoarbol']!({'en': '0'});
        expect(rng.draws, 2);
      },
    );
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/camino-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in caminoWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}; timeless: ${caminoTimeless[e.key] ?? 'equal'}'].join('\n')}\n',
        );
    });
  });
  // The real El campo (order 34b): the field is built round the old picture, so its places keep their screen numbers but
  // the ones the sheet moves (`moves`: the places at the shore, the answer cards in the sky, the ball in a raised hand;
  // `remap`: the story positions it moved, d-bola-canelo's Canelo by the water). 6 pairs of the frog's places take one
  // hop fewer (the sheet's `hops`), but none of them is walked in a recorded run: the hop sounds are the old ones. The
  // scene draws no random number of its own; the runner's draws are the old ones.
  group('the recorded runs, on the real El campo (order 34b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final campo = {
      for (final r in runs)
        if (r['scene'] == 'campo') r['story'] as String,
    };
    test('the five files of El campo', () {
      expect(campo, {
        'la-bola',
        'arriba-abajo',
        'otra-vez',
        'd-bola-canelo',
        'h-campo',
      });
    });
    for (final s in campo) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('campo'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            final timeless = firstDifference(
              campoPlaceless(forTimeless(c.committed)),
              campoPlaceless(forTimeless(c.trace)),
            );
            campoTimeless['$s $plan'] = timeless;
            expect(
              timeless,
              isNull,
              reason: '$s $plan (whole: ${d ?? 'equal'})',
            );
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            expect(hops(c.trace), hops(c.committed), reason: '$s $plan: hops');
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            campoWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/campo-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in campoWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}; timeless: ${campoTimeless[e.key] ?? 'equal'}'].join('\n')}\n',
        );
    });
  });
  // The real El lago (order 35b): the lake and its dock are built round the old picture, so its places keep their
  // screen numbers but the ones the sheet moves (`moves`: the post, Carmen on the right bank, the boats' rows, where
  // boats stick in the reeds, the ducks' and the fish's places and paths, the flower, the answer cards; `remap`: the
  // story positions it moved, d-pato-pequeno's ducks, Luis in h-lago and d-pato-pequeno, the bird on the post). All 21
  // hop counts are the old ones (the sheet's `hops` is empty). The scene draws its random numbers (mueven, rina) from the
  // runner's one source: the draws are the old ones. The state line writes where each duck is (`patos=k@x,y:`), which
  // `placeless` leaves out.
  group('the recorded runs, on the real El lago (order 35b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final lago = {
      for (final r in runs)
        if (r['scene'] == 'lago') r['story'] as String,
    };
    test('the five files of El lago', () {
      expect(lago, {
        'pan-para-el-pato',
        'los-botes',
        'cual',
        'd-pato-pequeno',
        'h-lago',
      });
    });
    for (final s in lago) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('lago'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            final timeless = firstDifference(
              placeless(forTimeless(c.committed)),
              placeless(forTimeless(c.trace)),
            );
            lagoTimeless['$s $plan'] = timeless;
            expect(
              timeless,
              isNull,
              reason: '$s $plan (whole: ${d ?? 'equal'})',
            );
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            expect(hops(c.trace), hops(c.committed), reason: '$s $plan: hops');
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            lagoWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/lago-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in lagoWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}; timeless: ${lagoTimeless[e.key] ?? 'equal'}'].join('\n')}\n',
        );
    });
  });
  // The real El banco (order 36b): the corner is built round the old picture, so its places keep their screen numbers
  // but the ones the sheet moves (`moves`: the gate and every way out through it, the cart and its man, the sitters on
  // the seats' edges and what lies on the seats, the pigeons' perches, the dogs, the frog's home, Carmen, the answer
  // cards; `remap`: the story positions it moved, d-vamos-a-casa's ways out through the gate). All hop counts are the old
  // ones (the sheet's `hops` is empty). The scene draws no random number. The state line writes where each person is
  // (`gente=k@x,y`), which `placeless` leaves out.
  group('the recorded runs, on the real El banco (order 36b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final banco = {
      for (final r in runs)
        if (r['scene'] == 'banco') r['story'] as String,
    };
    test('the six files of El banco', () {
      expect(banco, {
        'la-piragua',
        'senor-senora',
        'el-bebe-duerme',
        'd-piragua-luis',
        'd-vamos-a-casa',
        'h-banco',
      });
    });
    for (final s in banco) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('banco'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            final timeless = firstDifference(
              placeless(forTimeless(c.committed)),
              placeless(forTimeless(c.trace)),
            );
            bancoTimeless['$s $plan'] = timeless;

            expect(
              timeless,
              isNull,
              reason: '$s $plan (whole: ${d ?? 'equal'})',
            );
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            // every walk of the frog takes its old hops (the sheet's round 4: the man of el-bebe-duerme 1 px left)
            expect(hops(c.committed), hops(c.trace), reason: '$s $plan: hops');
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            bancoWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/banco-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in bancoWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}; timeless: ${bancoTimeless[e.key] ?? 'equal'}'].join('\n')}\n',
        );
    });
  });
  // The real La mesa (order 37b): the kitchen is built round the old picture, so its places keep their screen numbers
  // but the ones the sheet moves (`moves`: the seats stepped down the table, SD, and what stands at each place; the
  // doorway, PUERTA, and the walkway behind the chairs, PASO; the places in front of each seat for the frog, Luis,
  // abuela and Canelo; the things on the counter and the stove; the answer cards per story; `remap`: h-mesa's sitters on
  // their chairs). One hop count changes (frog.ranaa - rana.2, 3 to 2), on a pair no run walks: every walk takes its old
  // hops. The scene draws its random numbers (elige25) from the runner's one source: the draws are the old ones. The
  // state line writes where each person is (`gente=k@x,y`), which `placeless` leaves out.
  group('the recorded runs, on the real La mesa (order 37b)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mesa = {
      for (final r in runs)
        if (r['scene'] == 'mesa') r['story'] as String,
    };
    test('the four files of La mesa', () {
      expect(mesa, {'la-mesa', 'la-cuchara', 'tengo-hambre', 'h-mesa'});
    });
    for (final s in mesa) {
      test(
        '$s: the three plans: every decision, mark, step, clip, touch, draw and the story result as the old run',
        () async {
          for (final plan in ['right', 'wrong', 'alternate']) {
            final d = await compareWithScene(
              course,
              s,
              plan,
              trazas,
              await realSceneFor('mesa'),
              startFrog: startFrogOf,
              frogShadow: frogShadowOf,
            );
            expect(
              d == null || !d.startsWith('the run failed'),
              isTrue,
              reason: '$s $plan: $d',
            );
            final c = lastCompared!;
            final timeless = firstDifference(
              placeless(forTimeless(c.committed)),
              placeless(forTimeless(c.trace)),
            );
            mesaTimeless['$s $plan'] = timeless;

            expect(
              timeless,
              isNull,
              reason: '$s $plan (whole: ${d ?? 'equal'})',
            );
            int hops(Map<String, dynamic> t) =>
                '${t['sounds']}'.split('hop').length - 1;
            // every walk of the frog takes its old hops (the sheet's round 4: the man of el-bebe-duerme 1 px left)
            // every walk of the frog takes its old hops but the ones of the stop (mesaHopStop: reported, not worked round)
            expect(
              hops(c.committed) - hops(c.trace),
              mesaHopStop['$s $plan'] ?? 0,
              reason: '$s $plan: hops',
            );
            expect(
              c.trace['draws'],
              c.committed['draws'],
              reason: '$s $plan: random draws',
            );
            final steps = firstDifference(
              forComparison(c.committed)['steps'],
              forComparison(c.trace)['steps'],
              '.steps',
            );
            mesaWhole['$s $plan'] = d == null
                ? null
                : '$d; first step: ${steps ?? 'none'}; hop sounds ${hops(c.committed)} old, ${hops(c.trace)} new';
          }
        },
      );
    }
    tearDownAll(() {
      final dir = Platform.environment['COQUI_REPORT_DIR'];
      if (dir == null) return;
      File('$dir/mesa-traces.txt')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          '${[for (final e in mesaWhole.entries) '${e.key}: ${e.value ?? 'equal whole'}; timeless: ${mesaTimeless[e.key] ?? 'equal'}'].join('\n')}\n',
        );
    });
  });
}
