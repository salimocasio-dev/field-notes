// La muralla's paths: exhaustive/representative fixed-draw combinations across all 3 stories
// (16 for todos-en-la-foto, 6 for por-que-no-bailas, 12 for nos-vemos -> 34 x 4 = 136 fixed paths) plus seeded
// multi-round plays, with worker-isolate parallel execution and MurallaRules checked at every act's end and at
// the story's end.
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart'
    show SetScene, loadSheet, sceneRegistry;
import 'package:feature_story/feature_story.dart';
import 'package:flutter/services.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'mostrador_paths.dart' show letterPlan;
import 'muralla_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> murallaStories = [
  'todos-en-la-foto',
  'por-que-no-bailas',
  'nos-vemos',
];

/// Fixed draw assignments covering every door/word combo (117), reason pair (118), and guest pair (119).
List<Map<String, String>> murallaDrawsOf(String storyId) {
  switch (storyId) {
    case 'todos-en-la-foto':
      const doors = ['roja', 'azul'];
      const guests = ['pepe', 'maestra', 'piraguero', 'senor', 'senora'];
      final out = <Map<String, String>>[];
      var k = 0;
      for (final ha in doors) {
        for (final na in doors) {
          for (final hb in doors) {
            for (final nb in doors) {
              out.add({
                'ha': ha,
                'na': na,
                'hb': hb,
                'nb': nb,
                'pa': guests[k % guests.length],
                'pb': guests[(k + 1) % guests.length],
              });
              k++;
            }
          }
        }
      }
      return out;
    case 'por-que-no-bailas':
      const reasons = ['sed', 'hambre', 'cansado'];
      return [
        for (final ra in reasons)
          for (final rb in reasons)
            if (ra != rb) {'ra': ra, 'rb': rb},
      ];
    case 'nos-vemos':
      const guests = ['pepe', 'senora', 'senor', 'maestra'];
      return [
        for (final ga in guests)
          for (final gb in guests)
            if (ga != gb) {'ga': ga, 'gb': gb},
      ];
    default:
      throw ArgumentError.value(storyId, 'storyId', 'unknown muralla story');
  }
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playMuralla(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <MurallaRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = MurallaRules(s)..wrap();
        allRules.add(r);
      }
      return s;
    },
    course: course,
    progress: ToolProgress(),
    startFrog: startFrogOf,
    frogShadow: frogShadowOf,
  );
  if (allRules.isNotEmpty) {
    allRules.last.check('the end');
    t['_rules'] = allRules;
  }
  return t;
}

Future<List<int>> murallaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playMuralla(
      course,
      make,
      story,
      const {},
      (List.filled(16, 'r')..[i] = 'w').join(),
    );
    final ch = [
      for (final c in t['choices'] as List)
        if (c['kind'] == 'decide') c['letter'],
    ];
    for (var k = 0; k < ch.length; k++) {
      if (ch[k] == 'w' && at.length == k) at.add(i);
    }
  }
  return at;
}

typedef MurallaJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playMurallaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<MurallaJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/muralla-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.min(4, math.max(1, Platform.numberOfProcessors)),
  );
  final slices = <List<MurallaJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('muralla', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['muralla']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playMuralla(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<MurallaRules>;
          var checked = 0;
          final breaches = <Map<String, String>>[];
          for (final r in allRules) {
            checked += r.checked;
            for (final b in r.breaches) {
              breaches.add({'at': b.at, 'rule': b.rule, 'what': b.what});
            }
          }
          out.add({
            'story': id,
            'draws': j.d,
            'seed': j.seed,
            'pattern': j.pat,
            'decisionsPlayed': [
              for (final c in t['choices'] as List)
                if (c['kind'] == 'decide') c['letter'],
            ].join(),
            'end': t['end'],
            'lost': t['lost'],
            'errors': t['errors'],
            'checks': checked,
            'breaches': breaches,
          });
        }
        return out;
      }),
  ]);
  return [for (final p in parts) ...p];
}
