// Los regalos's three stories (114 to 116) played with no screen on the REAL scene (order 76), covering all four
// right/wrong patterns (rr, rw, wr, ww) across fixed draw combinations (34 x 4 = 136 fixed paths) plus seeded plays
// (2 seeds x 4 patterns = 8 paths per story, 24 seeded paths -> 160 total across the 3 stories), with RegalosRules
// checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/regalos_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in regalosStories) {
    test('$id: fixed draws x rr/rw/wr/ww + seeded plays', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/regalos/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('regalos');
      final at = await regalosDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = regalosDrawsOf(id);
      final jobs = <RegalosJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        for (var seed = 1; seed <= 2; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playRegalosSummaries(story, at, jobs);
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
