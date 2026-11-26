// La sombrilla's three stories (75 la-cara, 76 la-cabeza-y-los-brazos, 77 me-duele) played with no screen on the REAL
// scene across every reachable draw combination (9 + 9 + 18 = 36 draws) x rr/rw/wr/ww = 144 total paths.
//
//   flutter test tool/sombrilla_paths_test.dart [--dart-define=SHARD=i/n] [--dart-define=OUT=dir] [--dart-define=ONLY=story]
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import '../test/support/sombrilla_paths.dart';

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
  test('La sombrilla: every path of its three stories ($_shard)', () async {
    final make = await realSceneFor('sombrilla');
    var n = 0;
    for (final id in sombrillaStories) {
      if (_only.isNotEmpty && _only != id) continue;
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/sombrilla/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final at = await sombrillaDecisionLetters(course, make, story);
      expect(at, hasLength(2), reason: '$id: the two decisions');
      final jobs = <({Map<String, String> d, String pat})>[];
      final draws = sombrillaDrawsOf(story);
      for (final d in draws) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          jobs.add((d: d, pat: pat));
        }
      }
      results.addAll(await playSombrillaSummaries(story, at, jobs));
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
        final k = '${r['story']}: ${n['rule']}: ${n['what']}';
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
