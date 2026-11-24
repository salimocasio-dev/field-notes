// El reloj's three stories (63 to 65) played with no screen on the REAL scene (order 59b), a part of every path
// through them (tool/reloj_paths_test.dart plays them all): for each story the four ways through its two decisions
// (rr, rw, wr, ww), each with the first value of every draw, and each other value of every draw once (with rr). Every
// play ends (`finished`), with no error, the decisions played as asked, the stake lost as the wrong ones say, and the
// sheet's rules hold at every act's end and at the end (test/support/reloj_rules.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/disk_course.dart';
import 'real_scene.dart';
import 'support/reloj_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in relojStories) {
    test(
      '$id: the four ways through its decisions, every draw\'s values',
      () async {
        final story = jsonDecode(
          File('test/fixtures/reloj/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final make = await realSceneFor('reloj');
        final at = await relojDecisionLetters(course, make, story);
        expect(at, hasLength(2));
        final all = relojDrawsOf(story);
        final picks = <Map<String, String>>[all.first];
        for (final k in all.first.keys) {
          for (final v in {for (final d in all) d[k]!}) {
            if (v == all.first[k]) continue;
            final pick = all.firstWhere((d) => d[k] == v);
            if (!picks.contains(pick)) picks.add(pick);
          }
        }
        final summaries = await playRelojSummaries(story, at, [
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
