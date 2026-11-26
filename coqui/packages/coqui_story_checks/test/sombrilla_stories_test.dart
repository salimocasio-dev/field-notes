// La sombrilla's three stories (75 to 77) played with no screen on the REAL scene (order 63), covering the four ways
// through each story's two decisions (rr, rw, wr, ww) and every value of every draw, with SombrillaRules checked at
// every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/sombrilla_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in sombrillaStories) {
    test('$id: the four ways through its decisions, every draw\'s values', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/sombrilla/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('sombrilla');
      final at = await sombrillaDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final all = sombrillaDrawsOf(story);
      final picks = <Map<String, String>>[all.first];
      for (final k in all.first.keys) {
        for (final v in {for (final d in all) d[k]!}) {
          if (v == all.first[k]) continue;
          final pick = all.firstWhere((d) => d[k] == v);
          if (!picks.contains(pick)) picks.add(pick);
        }
      }
      final summaries = await playSombrillaSummaries(story, at, [
        for (final pat in const ['rr', 'rw', 'wr', 'ww'])
          for (final d in pat == 'rr' ? picks : [picks.first]) (d: d, pat: pat),
      ]);
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
