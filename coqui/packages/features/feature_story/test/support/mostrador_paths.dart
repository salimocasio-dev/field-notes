// El mostrador's paths: every combination of a story's random draws (drawsOf), the letters of the plan that play its two
// decisions one way or the other (letterPlan), and one play of a story on the real scene with its rules watched
// (playMostrador). Used by test/mostrador_stories_test.dart (a part of the paths) and tool/mostrador_paths_test.dart (all).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/src/play/play.dart';

import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'mostrador_rules.dart';

const List<String> mostradorStories = ['el-colmado', 'algo-mas', 'esto-y-eso'];

/// Every combination of the story's random draws: each `draw` takes each of its options, each `reparte` deals its
/// options out in every order. Names are the story's variables (a `$p` in an option is not filled: the stories of El
/// mostrador draw from fixed lists).
List<Map<String, String>> drawsOf(Map<String, dynamic> story) {
  final axes = <List<Map<String, String>>>[];
  void walk(Object? v) {
    if (v is Map) {
      if (v['draw'] is String) {
        axes.add([
          for (final o in v['options'] as List) {v['draw'] as String: '$o'},
        ]);
      } else if (v['reparte'] is List) {
        final names = (v['reparte'] as List).cast<String>();
        final ops = (v['options'] as List).map((o) => '$o').toList();
        final out = <Map<String, String>>[];
        void deal(int i, Map<String, String> got) {
          if (i == names.length) {
            out.add(Map.of(got));
            return;
          }
          for (final o in ops) {
            if (got.values.contains(o)) continue;
            got[names[i]] = o;
            deal(i + 1, got);
            got.remove(names[i]);
          }
        }

        deal(0, {});
        axes.add(out);
      }
      v.values.forEach(walk);
    } else if (v is List) {
      v.forEach(walk);
    }
  }

  walk([story['beats'], story['final']]);
  var all = <Map<String, String>>[{}];
  for (final a in axes) {
    all = [
      for (final x in all)
        for (final y in a) {...x, ...y},
    ];
  }
  return all;
}

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playMostrador(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  MostradorRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = MostradorRules(s)..wrap();
      return s;
    },
    course: course,
    progress: ToolProgress(),
    startFrog: startFrogOf,
    frogShadow: frogShadowOf,
  );
  if (rules != null) {
    rules!.check('the end');
    t['_rules'] = rules;
  }
  return t;
}

/// The two letters of the plan the story's two decisions take (the asks and the speaking turns take letters too):
/// found by playing it with one `w` at each place in turn.
Future<List<int>> decisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final letters = List.filled(16, 'r')..[i] = 'w';
    final t = await playMostrador(
      course,
      make,
      story,
      const {},
      letters.join(),
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

/// The plan's letters for [pattern] (`rr`, `rw`, `wr`, `ww`: the two decisions) with the decisions at [at].
String letterPlan(List<int> at, String pattern) {
  final letters = List.filled(16, 'r');
  if (pattern[0] == 'w') letters[at[0]] = 'w';
  if (pattern[1] == 'w') letters[at[1]] = 'w';
  return letters.join();
}

/// What a play gives a report: its story, draws, pattern, end, lost, errors, how many checks and what broke a rule.
Map<String, dynamic> playSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as MostradorRules;
  return {
    'story': id,
    'draws': draws,
    'pattern': pattern,
    'decisionsPlayed': [
      for (final c in t['choices'] as List)
        if (c['kind'] == 'decide') c['letter'],
    ].join(),
    'end': t['end'],
    'lost': t['lost'],
    'errors': t['errors'],
    'checks': rules.checked,
    'breaches': [
      for (final b in rules.breaches)
        {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
  };
}
