// La parada's paths: every combination of a story's random draws (esquinaDrawsOf of esquina_paths.dart: a `draw` takes
// each of its options, a `reparte` deals its options out in every order: story 51), the letters of the plan that play its
// two decisions one way or the other (mostrador_paths.dart's decisionLetters and letterPlan), and one play of a story on
// the real scene with its rules watched (playParada). Used by test/parada_stories_test.dart and
// tool/parada_paths_test.dart.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/src/play/play.dart';

import 'dart:convert';

import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'esquina_paths.dart' show esquinaDrawsOf;
import 'parada_rules.dart';

/// The distinct combinations of the story's draws (esquinaDrawsOf, each kept once): a name drawn in both rounds (story
/// 51's `a`, `b`, `frente`, `mio`, `primero`) takes one value for both, as a fixed draw does in the runner (`?name=value`
/// fixes every draw of that name).
List<Map<String, String>> paradaDrawsOf(Map<String, dynamic> story) {
  final seen = <String>{};
  return [
    for (final d in esquinaDrawsOf(story))
      if (seen.add(jsonEncode(d))) d,
  ];
}

const List<String> paradaStories = [
  'para-donde-vas',
  'se-monta-y-se-baja',
  'cerca-y-lejos',
];

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playParada(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
  int seed = 1,
}) async {
  ParadaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: seed,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = ParadaRules(s)..wrap();
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

/// What a play gives a report: its story, draws, pattern, end, lost, errors, how many checks and what broke a rule.
Map<String, dynamic> paradaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as ParadaRules;
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
    'overDepth': rules.overDepth.length,
    'overDepthAt': rules.overDepth.take(3).toList(),
    'known': [for (final b in rules.known) '${b.at}: ${b.what}'],
    'breaches': [
      for (final b in rules.breaches)
        {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
  };
}
