// Los regalos's paths: exhaustive/representative fixed-draw combinations across all 3 stories
// (2 for la-sorpresa, 8 for las-velas, 24 for para-ti -> 34 x 4 = 136 fixed paths) plus seeded multi-round plays,
// with worker-isolate parallel execution and RegalosRules checked at every act's end and at the story's end.
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
import 'regalos_rules.dart';

export 'mostrador_paths.dart' show letterPlan;

const List<String> regalosStories = ['la-sorpresa', 'las-velas', 'para-ti'];

/// Fixed draw assignments covering every qa (114), na/ma/mb (115), and guest-pair/verb (116).
List<Map<String, String>> regalosDrawsOf(String storyId) {
  switch (storyId) {
    case 'la-sorpresa':
      // Both orders: regalo first or bizcocho first.
      return const [
        {'qa': 'regalo'},
        {'qa': 'bizcocho'},
      ];
    case 'las-velas':
      // All 2 na x 2 ma x 2 mb = 8 combinations, cycling photo table orders.
      const orders = [
        ['foto_3m', 'foto_7m', 'foto_3a', 'foto_7a'],
        ['foto_7a', 'foto_3a', 'foto_7m', 'foto_3m'],
        ['foto_3a', 'foto_3m', 'foto_7a', 'foto_7m'],
        ['foto_7m', 'foto_7a', 'foto_3m', 'foto_3a'],
      ];
      final out = <Map<String, String>>[];
      var k = 0;
      for (final na in const ['3', '7']) {
        for (final ma in const ['m', 'a']) {
          for (final mb in const ['m', 'a']) {
            final ord = orders[k % orders.length];
            out.add({
              'na': na,
              'ma': ma,
              'mb': mb,
              'fa': ord[0],
              'fb': ord[1],
              'fc': ord[2],
              'fd': ord[3],
            });
            k++;
          }
        }
      }
      return out;
    case 'para-ti':
      // All 6 ordered distinct guest pairs (ga, gb) x 2 va x 2 vb = 24 combinations.
      const guests = ['pepe', 'maestra', 'piraguero'];
      final out = <Map<String, String>>[];
      for (final ga in guests) {
        for (final gb in guests) {
          if (ga == gb) continue;
          for (final va in const ['da', 'recibe']) {
            for (final vb in const ['da', 'recibe']) {
              out.add({'ga': ga, 'gb': gb, 'va': va, 'vb': vb});
            }
          }
        }
      }
      return out;
    default:
      throw ArgumentError.value(storyId, 'storyId', 'unknown regalos story');
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

Future<Map<String, dynamic>> playRegalos(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  final allRules = <RegalosRules>[];
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) {
        final r = RegalosRules(s)..wrap();
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

Future<List<int>> regalosDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final t = await playRegalos(
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

typedef RegalosJob = ({Map<String, String> d, String pat, int seed});

Future<List<Map<String, dynamic>>> playRegalosSummaries(
  Map<String, dynamic> story,
  List<int> at,
  List<RegalosJob> jobs,
) async {
  if (jobs.isEmpty) return const [];
  final id = story['id'] as String;
  final root = findRoot();
  final sheetText = File(
    '${root.path}/coqui/packages/core/coqui_scenes/assets/sheets/regalos-sheet.json',
  ).readAsStringSync();
  final workers = math.min(
    jobs.length,
    math.max(1, Platform.numberOfProcessors),
  );
  final slices = <List<RegalosJob>>[for (var w = 0; w < workers; w++) []];
  for (var i = 0; i < jobs.length; i++) {
    slices[i % workers].add(jobs[i]);
  }
  final parts = await Future.wait([
    for (final slice in slices)
      Isolate.run(() async {
        await loadSheet('regalos', bundle: _TextBundle(sheetText));
        final course = DiskCourse(root);
        await course.load();
        SetScene make(Rng rng) =>
            sceneRegistry['regalos']!(rng: rng) as SetScene;
        final out = <Map<String, dynamic>>[];
        for (final j in slice) {
          final t = await playRegalos(
            course,
            make,
            story,
            j.d,
            letterPlan(at, j.pat),
            watch: true,
            seed: j.seed,
          );
          final allRules = t['_rules'] as List<RegalosRules>;
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
