// La comida's paths: every draw combination of stories 90, 91, and 92 across rr/rw/wr/ww plus seeded multi-round
// plays exercising `reparte` permutations and independent Round B draws, with worker-isolate parallel execution and
// ComidaRules checked at every act's end.
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

import 'comida_rules.dart';
import 'mostrador_paths.dart' show letterPlan;

export 'mostrador_paths.dart' show letterPlan;

const List<String> comidaStories = ['prueba', 'falta-algo', 'mas-y-menos'];

/// Representative fixed-draw combinations for each story (covering every person × taste/order/saying in Round A,
/// while seeded plays cover `reparte` and Round B independently).
List<Map<String, String>> comidaDrawsOf(Map<String, dynamic> story) {
  final id = story['id'] as String;
  if (id == 'prueba') {
    return [
      for (final qa in const ['abuela', 'abuelo', 'luis', 'carmen'])
        for (final ga in const ['salado', 'dulce', 'picante'])
          {'qa': qa, 'ga': ga},
    ];
  }
  if (id == 'falta-algo') {
    return [
      for (final qa in const ['abuela', 'abuelo', 'luis', 'carmen'])
        for (final oa in const ['hf', 'fh']) {'qa': qa, 'oa': oa},
    ];
  }
  // mas-y-menos
  return [
    for (final ga in const ['senor', 'senora', 'joven', 'mujer'])
      for (final sa in const ['mas', 'menos', 'bien']) {'ga': ga, 'sa': sa},
  ];
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playComida(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <ComidaRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = ComidaRules(s)..wrap();
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

Future<List<int>> comidaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playComida(
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

typedef ComidaJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playComidaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<ComidaJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/comida-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<ComidaJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('comida', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['comida']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playComida(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<ComidaRules>;
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
