// El cuarto's three stories (96 to 98) played with no screen on the REAL scene (order 70), covering all four
// right/wrong patterns (rr, rw, wr, ww) across all draw combinations (6 + 4 + 16 = 26 -> 104 fixed paths) plus
// seeded plays (24 paths -> 128 total paths), with CuartoRules checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/cuarto_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in cuartoStories) {
    test('$id: fixed draws x rr/rw/wr/ww + seeded plays', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/cuarto/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('cuarto');
      final at = await cuartoDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = cuartoDrawsOf(id);
      final jobs = <CuartoJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        // Seeded plays where every draw runs independently
        // (broader 24-seed 392-path sweep runs in tool/cuarto_paths_test.dart).
        for (var seed = 1; seed <= 2; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playCuartoSummaries(story, at, jobs);
      for (final s in summaries) {
        final pat = s['pattern'] as String;
        final what = jsonEncode(s);
        expect(s['end'], 'finished', reason: what);
        expect(s['errors'], isEmpty, reason: what);
        expect(s['decisionsPlayed'], pat, reason: what);
        expect(s['lost'], 'w'.allMatches(pat).length, reason: what);
        expect(s['breaches'], isEmpty, reason: what);
        expect(s['checks'], greaterThan(10), reason: what);
      }
    }, timeout: const Timeout(Duration(minutes: 20)));
  }
}
