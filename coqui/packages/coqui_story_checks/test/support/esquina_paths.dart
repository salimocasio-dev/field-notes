// La esquina's paths: every combination of a story's random draws (esquinaDrawsOf: as El mostrador's drawsOf, and a draw
// whose options name variables, `$ua`, takes them as dealt before it: story 50), the letters of the plan that play its
// two decisions one way or the other (mostrador_paths.dart's decisionLetters and letterPlan), and one play of a story
// on the real scene with its rules watched (playEsquina). Used by test/esquina_stories_test.dart and
// tool/esquina_paths_test.dart.
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show Scene;
import 'package:coqui_scenes/coqui_scenes.dart' show SetScene;
import 'package:feature_story/feature_story.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'esquina_rules.dart';

const List<String> esquinaStories = [
  'la-calle',
  'la-esquina',
  'ahora-y-despues',
];

/// Every combination of the story's random draws, in the file's order: each `draw` takes each of its options (an option
/// `$name` is the value the combination already gives that name), each `reparte` deals its options out in every order.
List<Map<String, String>> esquinaDrawsOf(Map<String, dynamic> story) {
  final steps = <Map>[];
  void walk(Object? v) {
    if (v is Map) {
      if (v['draw'] is String || v['reparte'] is List) steps.add(v);
      v.values.forEach(walk);
    } else if (v is List) {
      v.forEach(walk);
    }
  }

  walk([story['beats'], story['final']]);
  var all = <Map<String, String>>[{}];
  for (final st in steps) {
    final next = <Map<String, String>>[];
    for (final x in all) {
      String res(Object? o) {
        final s = '$o';
        return s.startsWith(r'$') ? (x[s.substring(1)] ?? s) : s;
      }

      if (st['draw'] is String) {
        final ops = [for (final o in st['options'] as List) res(o)];
        for (final o in ops) {
          next.add({
            ...x,
            st['draw'] as String: o,
            if (st['other'] is String)
              st['other'] as String: ops.firstWhere((y) => y != o),
          });
        }
      } else {
        final names = (st['reparte'] as List).cast<String>();
        final ops = [for (final o in st['options'] as List) res(o)];
        void deal(int i, Map<String, String> got) {
          if (i == names.length) {
            next.add({...x, ...got});
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
      }
    }
    all = next;
  }
  return all;
}

/// One play of [story] on the real scene ([make]: the registry's factory), with [draws] fixed and the plan as
/// [letters]; with [watch] the scene's rules are checked at every act's end and at the end (`_rules` in the trace).
Future<Map<String, dynamic>> playEsquina(
  CourseCatalog course,
  Scene Function(Rng rng) make,
  Map<String, dynamic> story,
  Map<String, String> draws,
  String letters, {
  bool watch = false,
}) async {
  EsquinaRules? rules;
  final t = await play(
    story: story,
    plan: 'alternate',
    letters: letters,
    draws: draws,
    seed: 1,
    sceneFor: (rng) {
      final s = make(rng) as SetScene;
      if (watch) rules = EsquinaRules(s)..wrap();
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
Map<String, dynamic> esquinaSummary(
  String id,
  Map<String, String> draws,
  String pattern,
  Map<String, dynamic> t,
) {
  final rules = t['_rules'] as EsquinaRules;
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
