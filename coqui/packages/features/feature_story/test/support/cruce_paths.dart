// El cruce's paths: every combination of a story's random draws (esquina_paths.dart's esquinaDrawsOf), the letters of
// the plan that play its two decisions one way or the other (mostrador_paths.dart's decisionLetters and letterPlan), and
// one play of a story on the real scene with its rules watched (playCruce). Used by test/cruce_stories_test.dart and
// tool/cruce_paths_test.dart.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/src/play/play.dart';

import '../../tool/tool_progress.dart';
import '../real_scene.dart';
import 'cruce_rules.dart';

export 'esquina_paths.dart' show esquinaDrawsOf;

const List<String> cruceStories = [
  'izquierda-o-derecha',
  'sigue-derecho',
  'al-frente-y-detras',
];

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playCruce(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  CruceRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = CruceRules(s)..wrap();
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
Map<String, dynamic> cruceSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as CruceRules;
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
    'known': [for (final b in rules.known) '${b.at}: ${b.what}'],
    'breaches': [
      for (final b in rules.breaches)
        {'at': b.at, 'rule': b.rule, 'what': b.what},
    ],
  };
}
