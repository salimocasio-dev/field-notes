// La entrada's paths: exhaustive draws for bienvenidos (4 x 4 = 16 paths), covering draws for esta-libre (all 5
// colours, all 5 askers, both tables, both orders: 10 x 4 = 40 fixed paths) and con-y-sin (all 4 family members,
// both con/sin, both izq: 16 x 4 = 64 fixed paths), plus seeded independent plays across worker isolates with
// EntradaRules checked at every act's end and at the story's end.
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

import 'entrada_rules.dart';
import 'mostrador_paths.dart' show letterPlan;

export 'mostrador_paths.dart' show letterPlan;

const List<String> entradaStories = ['bienvenidos', 'esta-libre', 'con-y-sin'];

/// Representative fixed-draw combinations for each La entrada story:
/// - bienvenidos: all 4 combinations (exhaustive);
/// - esta-libre: 10 covering combinations across all 5 colours, all 5 askers, both tables, both statement orders;
/// - con-y-sin: 16 covering combinations across all 4 family speakers, both con/sin, both tray orientations.
List<Map<String, String>> entradaDrawsOf(Map<String, dynamic> story) {
  final id = story['id'] as String?;
  if (id == 'bienvenidos') {
    return [
      for (final da in const ['adelante', 'momento'])
        for (final db in const ['adelante', 'momento']) {'da': da, 'db': db},
    ];
  }
  if (id == 'esta-libre') {
    const cols = ['rojo', 'azul', 'verde', 'amarillo', 'blanco'];
    const askers = ['senor', 'senora', 'hombre', 'mujer', 'joven'];
    return [
      for (var i = 0; i < 10; i++)
        {
          'fa': cols[i % 5],
          'ea': '${(i % 4) + 1}',
          'la': i % 2 == 0 ? 'mesa2' : 'mesa3',
          'oa': i < 5 ? 'lt' : 'tl',
          'qa': askers[i % 5],
          'eb': '${(i % 6) + 1}',
          'gb': '${((i + 1) % 4) + 1}',
          'lb': i % 2 == 0 ? 'mesa3' : 'mesa2',
          'ob': i < 5 ? 'tl' : 'lt',
        },
    ];
  }
  if (id == 'con-y-sin') {
    const speakers = ['abuela', 'abuelo', 'luis', 'carmen'];
    return [
      for (var i = 0; i < 4; i++)
        for (final ca in const ['con', 'sin'])
          for (final ia in const ['con', 'sin'])
            {
              'qa': speakers[i],
              'ca': ca,
              'ia': ia,
              'gb': '${(i % 3) + 1}',
              'cb': ca == 'con' ? 'sin' : 'con',
              'ib': ia == 'con' ? 'sin' : 'con',
            },
    ];
  }
  throw StateError('unknown entrada story "$id"');
}

class _TextBundle extends CachingAssetBundle {
  _TextBundle(this.text);
  final String text;
  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<Map<String, dynamic>> playEntrada(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <EntradaRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = EntradaRules(s)..wrap();
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

Future<List<int>> entradaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playEntrada(
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

typedef EntradaJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playEntradaSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<EntradaJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/entrada-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<EntradaJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('entrada', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['entrada']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playEntrada(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<EntradaRules>;
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
