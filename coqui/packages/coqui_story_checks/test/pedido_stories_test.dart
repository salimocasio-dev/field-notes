// El pedido's three stories (87 to 89) played with no screen on the REAL scene (order 67), covering all four
// right/wrong patterns (rr, rw, wr, ww) across fixed draw combinations (all dishes, slots, guests, drinks, askers,
// answerers, and para values -> 152 fixed paths) plus seeded plays (24 paths -> 176 total paths), with PedidoRules
// checked at every act's end and at the story's end.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:coqui_story_checks/coqui_story_checks.dart';

import 'support/pedido_paths.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DiskCourse course;
  setUpAll(() async {
    course = DiskCourse(findRoot());
    await course.load();
  });

  for (final id in pedidoStories) {
    test('$id: fixed draws x rr/rw/wr/ww + seeded plays', () async {
      final story = jsonDecode(
        File(
          '${findRoot().path}/coqui/packages/core/coqui_scenes/test/support/fixtures/pedido/$id.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;
      final make = await realSceneFor('pedido');
      final at = await pedidoDecisionLetters(course, make, story);
      expect(at, hasLength(2));
      final draws = pedidoDrawsOf(id);
      final jobs = <PedidoJob>[
        for (final d in draws)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: d, pat: pat, seed: 1),
        // Seeded plays where every draw & reparte runs independently
        // (broader 24-seed 440-path sweep runs in tool/pedido_paths_test.dart).
        for (var seed = 1; seed <= 2; seed++)
          for (final pat in const ['rr', 'rw', 'wr', 'ww'])
            (d: const <String, String>{}, pat: pat, seed: seed),
      ];
      final summaries = await playPedidoSummaries(story, at, jobs);
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
