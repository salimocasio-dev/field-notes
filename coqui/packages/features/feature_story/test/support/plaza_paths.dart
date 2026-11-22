// El banco de la plaza's paths, as El mostrador's (test/support/mostrador_paths.dart: drawsOf, letterPlan): every
// combination of a story's random draws, the letters of the plan that play its two decisions one way or the other, and
// one play of a story on the real scene with its rules watched (playPlaza). Used by test/plaza_stories_test.dart (a part
// of the paths) and tool/plaza_paths_test.dart (all).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/src/play/play.dart';

import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'plaza_rules.dart';

export 'mostrador_paths.dart' show drawsOf, letterPlan;

const List<String> plazaStories = [
  'mucho-gusto',
  'de-donde-eres',
  'hablo-espanol',
];

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playPlaza(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  PlazaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = PlazaRules(s)..wrap();
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

/// The two letters of the plan the story's two decisions take: found by playing it with one `w` at each place in turn.
Future<List<int>> plazaDecisionLetters(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
) async {
  final at = <int>[];
  for (var i = 0; i < 16 && at.length < 2; i++) {
    final letters = List.filled(16, 'r')..[i] = 'w';
    final t = await playPlaza(course, make, story, const {}, letters.join());
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

/// What a play gives a report: its story, draws, pattern, end, lost, errors, how many checks, what broke a rule and
/// what the rules counted apart.
Map<String, dynamic> plazaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as PlazaRules;
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
    'notes': [
      for (final b in rules.notes) {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
  };
}
