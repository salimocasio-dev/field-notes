// El calendario's three stories (69 to 71) played with no screen on the REAL scene (order 61), covering the four ways
// through each story's two decisions (rr, rw, wr, ww) and every value of every draw, with CalendarioRules checked at
// every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/disk_course.dart';
import 'real_scene.dart';
import 'support/calendario_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in calendarioStories) {
    test(
      '$id: the four ways through its decisions, every draw\'s values',
      () async {
        final story = jsonDecode(
          File('test/fixtures/calendario/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final make = await realSceneFor('calendario');
        final at = await calendarioDecisionLetters(course, make, story);
        expect(at, hasLength(2));
        final all = calendarioRoundCoverDraws(story);
        final picks = <Map<String, String>>[all.first];
        for (final k in all.first.keys) {
          for (final v in {for (final d in all) d[k]!}) {
            if (v == all.first[k]) continue;
            final pick = all.firstWhere((d) => d[k] == v);
            if (!picks.contains(pick)) picks.add(pick);
          }
        }
        final summaries = await playCalendarioSummaries(story, at, [
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            for (final d in pat == 'rr' ? picks : [picks.first])
              (d: d, pat: pat),
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
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }
}
