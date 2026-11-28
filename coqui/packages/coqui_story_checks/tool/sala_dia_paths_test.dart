// La sala, de día's three stories (102 lee-y-escribe, 103 el-telefono, 104 por-la-tarde) played with no screen on the
// REAL scene across fixed draw combinations (40 x 4 = 160 paths) plus seeded plays (SEEDS default 24 x 4 x 3 = 288
// paths -> 448 total paths).
//
//   flutter test tool/sala_dia_paths_test.dart [--dart-define=SHARD=i/n] [--dart-define=OUT=dir] [--dart-define=ONLY=story] [--dart-define=SEEDS=n]
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import '../test/support/sala_dia_paths.dart';

const String _shard = String.fromEnvironment('SHARD', defaultValue: '0/1');
const String _out = String.fromEnvironment('OUT');
const String _only = String.fromEnvironment('ONLY');
const int _seeds = int.fromEnvironment('SEEDS', defaultValue: 24);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  final results = <Map<String, dynamic>>[];
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  final parts = _shard.split('/').map(int.parse).toList();
  test('La sala, de día: every path of its three stories ($_shard)', () async {
    final make = await realSceneFor('sala_dia');
    var n = 0;
    for (final id in salaDiaStories) {
      if (_only.isNotEmpty && _only != id) continue;
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/sala_dia/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final at = await salaDiaDecisionLetters(course, make, story);
      expect(at, hasLength(2), reason: '$id: the two decisions');
      final jobs = <SalaDiaJob>[];
      final draws = salaDiaDrawsOf(id);
      for (final d in draws) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          jobs.add((d: d, pat: pat, seed: 1));
        }
      }
      for (var seed = 1; seed <= _seeds; seed++) {
        for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
          if (n++ % parts[1] != parts[0]) continue;
          jobs.add((d: const <String, String>{}, pat: pat, seed: seed));
        }
      }
      results.addAll(await playSalaDiaSummaries(story, at, jobs));
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
