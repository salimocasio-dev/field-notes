// The level check (lib/src/logic/level_check.dart) against the old page (historia/nivel.js, run in Node by
// tool/diff/runs.mjs): the same scenario and the same scripted touches at the same virtual times must give the same
// check: the items in order (the stepping rule), where the four pictures sit (the draws of Math.random), each crop
// of a picture, the ring on the touched one, the replay every 9 s, the answers, the frontier, and the arguments of
// PAL.presume.
//
// Expected values: test/fixtures/level_sessions.json, made by `node tool/diff/make_fixture.mjs`.
import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:flutter_test/flutter_test.dart';

import 'review_differential_test.dart' show deepEqual, expectList, norm;
import 'support/fixture_catalog.dart';
import 'support/recording_store.dart';
import '../tool/support/scripted_clips.dart';
import 'support/snapshots.dart';
import '../tool/support/virtual_time.dart';

void main() {
  final fixture = readFixture('level_sessions.json');
  final sessions = [
    for (final s in fixture['sessions'] as List) s as Map<String, dynamic>,
  ];
  final course = FixtureCatalog();

  test('the fixture is there', () {
    expect(sessions.length, greaterThan(25));
    expect(course.levelItems.length, 48);
  });

  for (final entry in sessions) {
    final sc = entry['scenario'] as Map<String, dynamic>;
    final ex = entry['expected'] as Map<String, dynamic>;
    test('nivel.js check: ${sc['name']} (seed ${sc['seed']})', () async {
      final vt = VirtualTime();
      final rng = CountingRng(Mulberry32(sc['seed'] as int));
      final clips = ScriptedClips(vt, ready: sc['clips'] != 'silent');
      final store = RecordingStore(
        vt,
        clock: FakeClock(sc['now'] as int),
        json: jsonEncode(sc['store']),
      );
      final q = (sc['query'] as Map?)?.cast<String, dynamic>() ?? {};
      final session = LevelCheckSession(
        rng: rng,
        clock: vt,
        course: course,
        progress: store,
        clips: clips,
        wait: vt.wait,
        options: LevelOptions(all: q['todo'] != null),
      );

      session.prepare();
      await vt.settle();
      final start = ex['start'] as Map<String, dynamic>;
      expect(session.screenTitle, (start['pantalla'] as Map)['h']);
      expect(session.screenLines, (start['pantalla'] as Map)['ps']);
      expect(session.screen.name, (start['estado'] as List)[0]);
      expect(session.items.length, start['nv'], reason: 'NV');
      expect(session.total, start['nn'], reason: 'NN');
      expect(session.upStep, start['paso'], reason: 'PASO');
      expect([session.barSegments], start['dots']);

      for (final t in ex['touches'] as List) {
        final m = t as Map<String, dynamic>;
        vt.at(m['t'] as int, () => session.touch(m['k'] as int));
      }
      final trace = <Map<String, Object?>>[];
      void snap() {
        final s = {'t': vt.now, ...levelSnapshot(session)};
        if (trace.isEmpty ||
            !deepEqual(
              norm({...trace.last}..remove('t')),
              norm({...s}..remove('t')),
            )) {
          trace.add(s);
        }
      }

      unawaited(session.run());
      await vt.settle();
      snap();
      for (var guard = 0; guard < 200000 && vt.fireNext(); guard++) {
        await vt.settle();
        snap();
      }

      expectList(trace, ex['trace'] as List, 'the pictures over time');
      expectList(
        store.calls,
        ex['calls'] as List,
        'calls to the progress store (PAL.presume)',
      );
      expectList(clips.plays, ex['plays'] as List, 'clips played');
      expectList(clips.stops, ex['stops'] as List, 'clips stopped');
      expectList(clips.tones, ex['tones'] as List, 'tones');

      final res = ex['result'] as Map<String, dynamic>;
      expectList(
        [for (final a in session.answers) a.toJson()],
        res['hecho'] as List,
        'answers (Nivel.hecho)',
      );
      final fin = res['fin'] as Map<String, dynamic>;
      final r = session.result!;
      expect(r.frontier, fin['S0']);
      expect(r.stories, fin['ids']);
      expect(r.words, fin['pal']);
      expect(session.screenTitle, (res['pantalla'] as Map)['h']);
      expect(session.screenLines, (res['pantalla'] as Map)['ps']);
      expect(session.screen.name, (res['estado'] as List)[0]);
      expect(rng.draws, ex['draws'], reason: 'draws of the random source');
      expect(
        rng.inner.next(),
        ex['nextDraw'],
        reason: 'the next draw (same place in the stream)',
      );
    });
  }
}
