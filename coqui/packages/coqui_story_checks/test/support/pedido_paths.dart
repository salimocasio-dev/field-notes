// El pedido's paths: representative fixed-draw combinations covering every dish, slot, guest, drink, asker, answerer,
// and para value across all 3 stories (12 for que-hay-de-comer, 8 for tostones-y-mofongo, 18 for las-bebidas ->
// 38 x 4 = 152 fixed paths) plus seeded multi-round plays, with worker-isolate parallel execution and PedidoRules
// checked at every act's end and at the story's end.
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
import 'pedido_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> pedidoStories = [
  'que-hay-de-comer',
  'tostones-y-mofongo',
  'las-bebidas',
];

/// Fixed draw assignments covering every dish/slot (87), guest/plate/side (88), and asker/drink/lifted/answerer/para (89).
List<Map<String, String>> pedidoDrawsOf(String storyId) {
  switch (storyId) {
    case 'que-hay-de-comer':
      // All 4 dishes x 3 rolls (12 distinct Round A -> Round B dish pairs) with slota/slotb cycling through 1..3.
      const dishes = ['sopa', 'carne', 'pescado', 'ensalada'];
      const rolls = ['1', '2', '3'];
      final out = <Map<String, String>>[];
      var k = 0;
      for (final d in dishes) {
        for (final r in rolls) {
          out.add({
            'disha': d,
            'roll': r,
            'slota': '${(k % 3) + 1}',
            'slotb': '${((k + 1) % 3) + 1}',
          });
          k++;
        }
      }
      return out;
    case 'tostones-y-mofongo':
      // Both guests (joven/mujer) x all 4 (platea, sidea) pairs, with complementary (plateb, sideb).
      final out = <Map<String, String>>[];
      for (final g in const ['joven', 'mujer']) {
        for (final pa in const ['carne', 'pescado']) {
          for (final sa in const ['tostones', 'mofongo']) {
            out.add({
              'guesta': g,
              'guestb': g == 'joven' ? 'mujer' : 'joven',
              'platea': pa,
              'sidea': sa,
              'plateb': pa == 'carne' ? 'pescado' : 'carne',
              'sideb': sa == 'tostones' ? 'mofongo' : 'tostones',
            });
          }
        }
      }
      return out;
    case 'las-bebidas':
      // All 3 lifted x 2 answerers x 3 para (18), paired cyclically with all 3 askers x 2 drinks (6).
      const askers = ['abuelo', 'abuela', 'luis'];
      const drinks = ['refresco', 'limonada'];
      const lifteds = ['refresco', 'limonada', 'cafe'];
      const answerers = ['abuelo', 'luis'];
      const paras = ['mi', 'el', 'ella'];
      final out = <Map<String, String>>[];
      var k = 0;
      for (final lf in lifteds) {
        for (final ans in answerers) {
          for (final pa in paras) {
            out.add({
              'asker': askers[k % askers.length],
              'drink': drinks[(k ~/ askers.length) % drinks.length],
              'lifted': lf,
              'answerer': ans,
              'para': pa,
            });
            k++;
          }
        }
      }
      return out;
    default:
      throw ArgumentError.value(storyId, 'storyId', 'unknown pedido story');
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

Future<Map<String, dynamic>> playPedido(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <PedidoRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = PedidoRules(s)..wrap();
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

Future<List<int>> pedidoDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playPedido(
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

typedef PedidoJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playPedidoSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<PedidoJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/pedido-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<PedidoJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('pedido', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['pedido']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playPedido(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<PedidoRules>;
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
