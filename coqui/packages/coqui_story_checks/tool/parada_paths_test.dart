// La parada's three stories (51 para-donde-vas, 52 se-monta-y-se-baja, 53 cerca-y-lejos) played with no screen (feature_story's `play`,
// what tool/juega.dart plays) on the REAL scene, on every path through them: every value of every random draw (`draw`,
// `reparte`: fixed from outside, as the old page's `?name=value`), times every way through the two decisions (right
// and right, right and wrong, wrong and right, wrong and wrong: `play(letters:)`). Each play must end (`finished`), with no
// error and no step that waits forever; at every act's end and at the end the frame is checked against the sheet's
// rules (test/support/parada_rules.dart). The asks are played right (a wrong touch on an ask changes no path).
//
//   flutter test tool/parada_paths_test.dart [--dart-define=SEEDS=n] [--dart-define=SHARD=i/n] [--dart-define=OUT=dir] [--dart-define=ONLY=story]
//
// With OUT it writes <OUT>/paths-<i>.json: each play's story, draws, pattern, end, lost, errors and broken rules.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import '../test/support/parada_paths.dart';
import '../test/support/mostrador_paths.dart' show decisionLetters, letterPlan;

const String _shard = String.fromEnvironment('SHARD', defaultValue: '0/1');
const String _out = String.fromEnvironment('OUT');
const String _only = String.fromEnvironment('ONLY');

/// Plays more with the draws left to the seed (1 to SEEDS), each of the four ways: rounds whose draws differ.
const int _seeds = int.fromEnvironment('SEEDS');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  final results = <Map<String, dynamic>>[];
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  final parts = _shard.split('/').map(int.parse).toList();
  test('La parada: every path of its three stories ($_shard)', () async {
    final make = await realSceneFor('parada');
    var n = 0;
    for (final id in paradaStories) {
      if (_only.isNotEmpty && _only != id) continue;
      final story = jsonDecode(
        File('test/fixtures/parada/$id.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final at = await decisionLetters(course, make, story);
      expect(at, hasLength(2), reason: '$id: the two decisions');
      for (final d in paradaDrawsOf(story)) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          final t = await playParada(
            course,
            make,
            story,
            d,
            letterPlan(at, pat),
            watch: true,
          );
          results.add(paradaSummary(id, d, pat, t));
        }
      }
      for (var seed = 1; seed <= _seeds; seed++) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          final t = await playParada(
            course,
            make,
            story,
            const {},
            letterPlan(at, pat),
            watch: true,
            seed: seed,
          );
          results.add(paradaSummary(id, {'seed': '$seed'}, pat, t));
        }
      }
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
    final over = results.where((r) => (r['overDepth'] as int) > 0);
    // ignore: avoid_print
    print(
      'paths ${results.length}, not ended or with errors ${bad.length}, with a rule broken ${breached.length}, checks ${results.fold<int>(0, (a, r) => a + (r['checks'] as int))}, the frog drawn over a grown-up nearer than he in ${over.length}',
    );
    expect(bad, isEmpty, reason: bad.take(3).map(jsonEncode).join('\n'));
    expect(
      breached,
      isEmpty,
      reason: breached.take(3).map(jsonEncode).join('\n'),
    );
  }, timeout: Timeout.none);
}
