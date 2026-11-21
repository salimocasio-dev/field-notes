// A trace's speech events in time order, as the old page writes them: A comer's stories are the first with speaking turns,
// and their recorded runs (coqui/ref/trazas/) interleave each turn and its answer.
import 'dart:convert';
import 'dart:io';

import 'package:feature_story/src/play/play.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/disk_course.dart';
import '../tool/replay_scene.dart';
import '../tool/sha256.dart';
import '../tool/tool_progress.dart';

void main() {
  test('speechInTimeOrder: by t, a turn before an answer at the same t, each list in its own order', () {
    final out = speechInTimeOrder(
      [
        {'t': 10, 'turn': 'a'},
        {'t': 30, 'turn': 'b'},
        {'t': 30, 'turn': 'c'},
      ],
      [
        {'t': 12, 'w': 'x'},
        {'t': 30, 'w': 'y'},
        {'t': 31, 'w': 'z'},
      ],
    );
    expect(
      [for (final e in out) e['turn'] ?? e['w']],
      ['a', 'x', 'b', 'c', 'y', 'z'],
    );
  });

  test('que-quieres, played on the replay scene: its speech events are the recorded run\'s, turn, answer, turn, answer', () async {
    final root = findRoot();
    final course = DiskCourse(root);
    await course.load();
    for (final plan in ['right', 'wrong', 'alternate']) {
      final committed = jsonDecode(
        File('${root.path}/coqui/ref/trazas/que-quieres/$plan.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final run = jsonDecode(
        File('test/fixtures/acts/que-quieres/$plan.acts.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      final file = await course.story('que-quieres');
      // the old learner's wrong touches, as the differential's compareRun gives them
      final wrongs = [
        for (final t
            in (committed['touches'] as List).cast<Map<String, dynamic>>())
          if (t['why'] == 'wrong-poke')
            (t: (t['t'] as num).toInt(), what: t['what'] as String),
      ];
      final trace = await play(
        story: file,
        plan: plan,
        seed: committed['seed'] as int,
        sceneFor: (rng) => ReplayScene(
          sceneId: file['scene'] as String,
          story: file,
          run: run,
          rng: rng,
        ),
        course: course,
        progress: ToolProgress(),
        storySha256: sha256Hex(course.storyBytes('que-quieres')),
        thingOrder: (W, now) {
          for (final w in wrongs) {
            if (w.t >= now) return [w.what];
          }
          return const [];
        },
      );
      final events = (trace['speech'] as Map)['events'] as List;
      final want = (committed['speech'] as Map)['events'] as List;
      expect(want.length, greaterThan(2), reason: plan);
      expect(
        jsonEncode(events),
        jsonEncode(want),
        reason:
            '$plan: the speech events, in the order the old page wrote them',
      );
    }
  });
}
