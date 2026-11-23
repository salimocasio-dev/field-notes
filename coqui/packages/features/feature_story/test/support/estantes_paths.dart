// Los estantes' paths, as El mostrador's (test/support/mostrador_paths.dart: drawsOf, decisionLetters, letterPlan are
// that file's): one play of a story on the real scene with its rules watched (playEstantes). Used by
// test/estantes_stories_test.dart (a part of the paths) and tool/estantes_paths_test.dart (all).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/src/play/play.dart';

import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'estantes_rules.dart';

const List<String> estantesStories = [
  'latas-y-botellas',
  'siete-latas',
  'diez-botellas',
];

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playEstantes(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  EstantesRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = EstantesRules(s)..wrap();
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
Future<List<int>> estantesDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final letters = List.filled(16, 'r')..[i] = 'w';
    final t = await playEstantes(course, make, story, const {}, letters.join());
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

/// What a play gives a report: its story, draws, pattern, end, lost, errors, how many checks and what broke a rule.
Map<String, dynamic> estantesSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as EstantesRules;
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
