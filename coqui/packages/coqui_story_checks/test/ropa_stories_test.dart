// La ropa's three stories (78 to 80) played with no screen on the REAL scene (order 64), covering the four ways
// through each story's two decisions (rr, rw, wr, ww) and every value of every draw, with RopaRules checked at
// every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/ropa_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in ropaStories) {
    test('$id: the four ways through its decisions, every draw\'s values', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/ropa/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('ropa');
      final cosaOrder = ropaCosaOrder(make);
      final at = await ropaDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final jobs = <({Map<String, String> d, String pat})>[];
      for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
        final all = ropaDrawsOf(story, pattern: pat, cosaOrder: cosaOrder);
        final picks = <Map<String, String>>[all.first];
        if (pat == 'rr') {
          final keys = {for (final d in all) ...d.keys};
          for (final k in keys) {
            final values = {
              for (final d in all)
                if (d[k] != null) d[k]!,
            };
            for (final v in values) {
              if (v == all.first[k]) continue;
              final pick = all.firstWhere((d) => d[k] == v);
              if (!picks.contains(pick)) picks.add(pick);
            }
          }
        }
        for (final d in picks) {
          jobs.add((d: d, pat: pat));
        }
      }
      final summaries = await playRopaSummaries(story, at, jobs);
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
