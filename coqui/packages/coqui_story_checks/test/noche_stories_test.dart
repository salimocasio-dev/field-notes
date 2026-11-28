// La noche's three stories (105 to 107) played with no screen on the REAL scene (order 73), covering all four
// right/wrong patterns (rr, rw, wr, ww) across every fixed draw combination (112 paths) plus seeded plays,
// with NocheRules checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/noche_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in nocheStories) {
    test('$id: every draw combination x rr/rw/wr/ww + seeded plays', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/noche/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('noche');
      final at = await nocheDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = nocheDrawsOf(story);
      final jobs = <NocheJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        for (var seed = 1; seed <= 3; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playNocheSummaries(story, at, jobs);
      for (final s in summaries) {
        final pat = s['pattern'] as String;
        final what = jsonEncode(s);
        expect(s['end'], 'finished', reason: what);
        expect(s['errors'], isEmpty, reason: what);
        expect(s['decisionsPlayed'], pat, reason: what);
        final d = s['draws'] as Map;
        // In prende-y-apaga, whenever round A asks `apaga` (only luz3 is lit), all three lamps
        // end dark (0,0,0) after round A, so round B switches to `prende` with every lamp in `vale`
        // (no wrong lamp exists in round B, so only round A can cost a stripe).
        final expectLost = id == 'prende-y-apaga' && d['wa'] == 'apaga'
            ? (pat.startsWith('w') ? 1 : 0)
            : 'w'.allMatches(pat).length;
        if (d.isNotEmpty || id != 'prende-y-apaga') {
          expect(s['lost'], expectLost, reason: what);
        }
        expect(s['breaches'], isEmpty, reason: what);
        expect(s['checks'], greaterThan(10), reason: what);
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}
