// La comida's three stories (90 to 92) played with no screen on the REAL scene (order 68), covering all four
// right/wrong patterns (rr, rw, wr, ww) across every Round A draw combination (32 x 4 = 128 paths) plus cross-round
// seeded plays, with ComidaRules checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/comida_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in comidaStories) {
    test('$id: every draw combination x rr/rw/wr/ww + cross-round seeds', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/comida/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('comida');
      final at = await comidaDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = comidaDrawsOf(story);
      final jobs = <ComidaJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        // Cross-round seeded plays where Round A and Round B draw independently
        // (full 24-seed sweep runs in tool/comida_paths_test.dart).
        for (var seed = 1; seed <= 2; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playComidaSummaries(story, at, jobs);
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
