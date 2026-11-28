// La música's three stories (111 to 113) played with no screen on the REAL scene (order 75), covering all four
// right/wrong patterns (rr, rw, wr, ww) across every draw combination plus cross-round seeded plays, with MusicaRules
// checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/musica_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in musicaStories) {
    test('$id: every draw combination x rr/rw/wr/ww + cross-round seeds', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/musica/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('musica');
      final at = await musicaDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = musicaDrawsOf(story);
      final jobs = <MusicaJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        for (var seed = 1; seed <= 4; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playMusicaSummaries(story, at, jobs);
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
