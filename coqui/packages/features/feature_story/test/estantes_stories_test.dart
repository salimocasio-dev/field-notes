// Los estantes' three stories (39 to 41) played with no screen on the REAL scene (order 51b), a part of every path
// through them (tool/estantes_paths_test.dart plays them all): for each story the four ways through its two decisions
// (rr, rw, wr, ww), each with the first value of every draw, and each other value of every draw once (with rr). Every
// play ends (`finished`), with no error, the decisions played as asked, the stake lost as the wrong ones say, and the
// sheet's rules hold at every act's end and at the end (test/support/estantes_rules.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/disk_course.dart';
import 'real_scene.dart';
import 'support/estantes_paths.dart';
import 'support/mostrador_paths.dart' show drawsOf, letterPlan;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in estantesStories) {
    test(
      '$id: the four ways through its decisions, every draw\'s values',
      () async {
        final story = jsonDecode(
          File('test/fixtures/estantes/$id.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final make = await realSceneFor('estantes');
        final at = await estantesDecisionLetters(course, make, story);
        expect(at, hasLength(2));
        final all = drawsOf(story);
        // the first combination, then for each variable each other value once
        final picks = <Map<String, String>>[all.first];
        for (final k in all.first.keys) {
          for (final v in {for (final d in all) d[k]!}) {
            if (v == all.first[k]) continue;
            picks.add(all.firstWhere((d) => d[k] == v));
          }
        }
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          for (final d in pat == 'rr' ? picks : [picks.first]) {
            final s = estantesSummary(
              id,
              d,
              pat,
              await playEstantes(
                course,
                make,
                story,
                d,
                letterPlan(at, pat),
                watch: true,
              ),
            );
            final what = jsonEncode(s);
            expect(s['end'], 'finished', reason: what);
            expect(s['errors'], isEmpty, reason: what);
            expect(s['decisionsPlayed'], pat, reason: what);
            expect(s['lost'], 'w'.allMatches(pat).length, reason: what);
            expect(s['breaches'], isEmpty, reason: what);
            expect(s['checks'], greaterThan(10), reason: what);
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 20)),
    );
  }
}
