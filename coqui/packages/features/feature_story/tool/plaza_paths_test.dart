// El banco de la plaza's three stories (60 mucho-gusto, 61 de-donde-eres, 62 hablo-espanol) played with no screen (feature_story's `play`,
// what tool/juega.dart plays) on the REAL scene, on every path through them: every value of every random draw (`draw`,
// `reparte`: fixed from outside, as the old page's `?name=value`), times every way through the two decisions (right
// and right, right and wrong, wrong and right, wrong and wrong: `play(letters:)`). Each play must end (`finished`), with no
// error and no step that waits forever; at every act's end and at the end the frame is checked against the sheet's
// rules (test/support/plaza_rules.dart; what they count apart is written too). The asks are played right (a wrong touch on an ask changes no path).
//
//   flutter test tool/plaza_paths_test.dart [--dart-define=SHARD=i/n] [--dart-define=OUT=dir] [--dart-define=ONLY=story]
//
// With OUT it writes <OUT>/paths-<i>.json: each play's story, draws, pattern, end, lost, errors and broken rules.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../test/real_scene.dart';
import '../test/support/plaza_paths.dart';
import 'disk_course.dart';

const String _shard = String.fromEnvironment('SHARD', defaultValue: '0/1');
const String _out = String.fromEnvironment('OUT');
const String _only = String.fromEnvironment('ONLY');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  final results = <Map<String, dynamic>>[];
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  final parts = _shard.split('/').map(int.parse).toList();
  test('El banco de la plaza: every path of its three stories ($_shard)', () async {
    final make = await realSceneFor('plaza');
    var n = 0;
    for (final id in plazaStories) {
      if (_only.isNotEmpty && _only != id) continue;
      final story = jsonDecode(
        File('test/fixtures/plaza/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final at = await plazaDecisionLetters(course, make, story);
      expect(at, hasLength(2), reason: '$id: the two decisions');
      final jobs = <({Map<String, String> d, String pat})>[];
      for (final d in drawsOf(story)) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          jobs.add((d: d, pat: pat));
        }
      }
      results.addAll(await playPlazaSummaries(story, at, jobs));
    }
    if (_out.isNotEmpty) {
      Directory(_out).createSync(recursive: true);
      File('$_out/paths-${parts[0]}.json')
          .writeAsStringSync(jsonEncode(results));
    }
    final bad = results.where(
      (r) =>
          r['end'] != 'finished' ||
          (r['errors'] as List).isNotEmpty ||
          r['pattern'] != r['decisionsPlayed'],
    );
    final breached = results.where((r) => (r['breaches'] as List).isNotEmpty);
    final noted = <String, int>{};
    for (final r in results) {
      for (final n in r['notes'] as List) {
        final k =
            '${r['story']}: ${n['rule']}: ${(n['what'] as String).replaceAll(RegExp(r'paloma:\\d'), 'paloma')}';
        noted[k] = (noted[k] ?? 0) + 1;
      }
    }
    for (final e in noted.entries) {
      // ignore: avoid_print
      print('counted apart (${e.value} checks): ${e.key}');
    }
    var checks = 0;
    for (final r in results) {
      checks += r['checks'] as int;
    }
    // ignore: avoid_print
    print(
      'paths ${results.length}, rules checked $checks times, not ended or with errors ${bad.length}, with a rule broken ${breached.length}',
    );
    expect(bad, isEmpty, reason: bad.take(3).map(jsonEncode).join('\n'));
    expect(
      breached,
      isEmpty,
      reason: breached.take(3).map(jsonEncode).join('\n'),
    );
  }, timeout: Timeout.none);
}
