// La cuenta's three stories (93 to 95) played with no screen on the REAL scene (order 69), covering all four
// right/wrong patterns (rr, rw, wr, ww) across every fixed draw combination (68 paths) plus cross-round seeded plays
// varying guests and totals, with CuentaRules checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/cuenta_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in cuentaStories) {
    test('$id: every draw combination x rr/rw/wr/ww + seeded guest deals', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/cuenta/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('cuenta');
      final at = await cuentaDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = cuentaDrawsOf(story);
      final jobs = <CuentaJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        // Seeded plays covering distinct guest deals and totals
        // (full 24-seed 356-path sweep runs in tool/cuenta_paths_test.dart).
        for (var seed = 1; seed <= 3; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playCuentaSummaries(story, at, jobs);
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
