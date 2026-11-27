// La ropa's three stories (78 la-ropa-seca, 79 mi-sombrero, 80 se-pone-y-se-quita) played with no screen on the REAL
// scene across every reachable draw combination (48 + 960 + 256 = 1,264 total paths).
//
//   flutter test tool/ropa_paths_test.dart [--dart-define=SHARD=i/n] [--dart-define=OUT=dir] [--dart-define=ONLY=story]
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import '../test/support/ropa_paths.dart';

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
  test('La ropa: every path of its three stories ($_shard)', () async {
    final make = await realSceneFor('ropa');
    final cosaOrder = ropaCosaOrder(make);
    var n = 0;
    for (final id in ropaStories) {
      if (_only.isNotEmpty && _only != id) continue;
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/ropa/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final at = await ropaDecisionLetters(course, make, story);
      expect(at, hasLength(2), reason: '$id: the two decisions');
      final jobs = <({Map<String, String> d, String pat})>[];
      for (final pat in const ['rr', 'rw', 'wr', 'ww']) {
        for (final d in ropaDrawsOf(
          story,
          pattern: pat,
          cosaOrder: cosaOrder,
        )) {
          if (n++ % parts[1] != parts[0]) continue;
          jobs.add((d: d, pat: pat));
        }
      }
      results.addAll(await playRopaSummaries(story, at, jobs));
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
