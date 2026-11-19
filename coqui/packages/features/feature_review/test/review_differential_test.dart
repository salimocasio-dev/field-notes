// The Repaso session (lib/src/logic/review_session.dart) against the old page (historia/cual.js, run in Node by
// tool/diff/runs.mjs): the same scenario, the same scripted touches at the same virtual times, must give the same
// session: the words asked and in what order (the draws of Math.random included), which picture is on which side,
// every call to the progress store with its arguments and its time, every clip played and every tone, the pictures'
// state at every instant (dimmed, ringed, checked, the caption under them), the bar, the end screen.
//
// Expected values: test/fixtures/review_sessions.json, made by `node tool/diff/make_fixture.mjs`.
import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart' show PictureRef;
import 'package:feature_review/src/logic/review_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_catalog.dart';
import 'support/recording_store.dart';
import '../tool/support/scripted_clips.dart';
import 'support/snapshots.dart';
import '../tool/support/virtual_time.dart';

Object? norm(Object? x) => jsonDecode(jsonEncode(x));

/// JSON values equal as JavaScript sees them: 784 and 784.0 are the same number.
bool deepEqual(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEqual(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !deepEqual(a[k], b[k])) return false;
    }
    return true;
  }
  return a == b;
}

/// Fails with the first place where two lists of the same kind of thing differ.
void expectList(List<Object?> actual, List<Object?> expected, String what) {
  final a = norm(actual) as List;
  final e = norm(expected) as List;
  for (var i = 0; i < a.length && i < e.length; i++) {
    if (!deepEqual(a[i], e[i])) {
      fail(
        '$what differs at $i of ${e.length}:\n  dart: ${jsonEncode(a[i])}\n  node: ${jsonEncode(e[i])}',
      );
    }
  }
  expect(a.length, e.length, reason: '$what: how many');
}

ReviewOptions optionsOf(Map<String, dynamic> q) => ReviewOptions(
  cap: q['n'] == null ? reviewCap : int.parse(q['n'] as String),
  only: q['solo'] == null ? null : (q['solo'] as String).split(','),
  all: q['todo'] != null && (q['todo'] as String).isNotEmpty,
);

void main() {
  final fixture = readFixture('review_sessions.json');
  final sessions = [
    for (final s in fixture['sessions'] as List) s as Map<String, dynamic>,
  ];
  final course = FixtureCatalog();

  test('the fixture is there', () {
    expect(sessions.length, greaterThan(40));
  });

  for (final entry in sessions) {
    final sc = entry['scenario'] as Map<String, dynamic>;
    final ex = entry['expected'] as Map<String, dynamic>;
    test('cual.js session: ${sc['name']} (seed ${sc['seed']})', () async {
      final vt = VirtualTime();
      final rng = CountingRng(Mulberry32(sc['seed'] as int));
      final clips = ScriptedClips(vt, ready: sc['clips'] != 'silent');
      final store = RecordingStore(
        vt,
        clock: FakeClock(sc['now'] as int),
        json: jsonEncode(sc['store']),
      );
      final shown = <List<PictureRef>>[];
      final session = ReviewSession(
        rng: rng,
        clock: vt,
        course: course,
        progress: store,
        clips: clips,
        wait: vt.wait,
        options: optionsOf(
          (sc['query'] as Map?)?.cast<String, dynamic>() ?? {},
        ),
        warm: shown.add,
      );

      // the start screen
      session.prepare();
      await vt.settle();
      final start = ex['start'] as Map<String, dynamic>;
      expect(
        [for (final p in session.list) p.word],
        start['lista'],
        reason: 'the words of the session',
      );
      expect(session.practice, start['practica']);
      expect(session.screenTitle, (start['pantalla'] as Map)['h']);
      expect(session.screenLines, (start['pantalla'] as Map)['ps']);
      expect([session.barSegments], start['dots']);
      expect(session.screen.name, (start['estado'] as List)[0]);

      // the scripted learner's touches, at the times the old page was touched
      for (final t in ex['touches'] as List) {
        final m = t as Map<String, dynamic>;
        vt.at(m['t'] as int, () => session.touch(m['k'] as int));
      }
      final trace = <Map<String, Object?>>[];
      void snap() {
        final s = {'t': vt.now, ...reviewSnapshot(session)};
        if (trace.isEmpty ||
            !deepEqual(
              norm({...trace.last}..remove('t')),
              norm({...s}..remove('t')),
            )) {
          trace.add(s);
        }
        // each picture on screen is the right side of the right pair
        final ps = session.panels;
        if (ps != null) {
          final it = session.queue[session.index].pair;
          for (final p in ps) {
            expect(
              sameRef(p.ref, PictureRef.of(it, p.right ? it.yes : it.no)),
              isTrue,
              reason: 'the picture of ${it.word}',
            );
          }
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
        'calls to the progress store',
      );
      expectList(clips.plays, ex['plays'] as List, 'clips played');
      expectList(clips.stops, ex['stops'] as List, 'clips stopped');
      expectList(clips.tones, ex['tones'] as List, 'tones');

      final res = ex['result'] as Map<String, dynamic>;
      expectList(
        [
          for (final a in session.answers)
            {'w': a.word, 'ok': a.ok, 'ms': a.ms, if (a.auto) 'auto': 1},
        ],
        res['hecho'] as List,
        'answers (Cual.hecho)',
      );
      expectList(
        [
          for (final a in session.secondAnswers) {'w': a.word, 'ok': a.ok},
        ],
        res['rehecho'] as List,
        'second asks (Cual.rehecho)',
      );
      expectList(
        [
          for (final q in session.queue) {'w': q.pair.word, 're': q.again},
        ],
        res['cola'] as List,
        'the queue (Cual.cola)',
      );
      expectList(
        [
          for (final t in session.asks)
            {
              'i': t.i,
              'w': t.word,
              're': t.again,
              'fin': ?t.fin,
              'rep': ?t.rep,
              'repFin': ?t.repFin,
              'auto': ?t.auto,
              'ok': ?t.ok,
            },
        ],
        res['tt'] as List,
        'timings (Cual.tt)',
      );
      final end = session.end!;
      expect(
        norm({'up': end.up, 'soon': end.soon, 'practica': end.practice}),
        res['fin'],
      );
      expectList(
        [
          for (final g in end.groups)
            {'titulo': g.title, 'sub': g.sub, 'words': g.words},
        ],
        ex['groups'] as List,
        'the groups of the end screen',
      );
      expect(session.screenTitle, (res['pantalla'] as Map)['h']);
      expect(session.screenLines, (res['pantalla'] as Map)['ps']);
      expect(session.screen.name, (res['estado'] as List)[0]);

      expect(rng.draws, ex['draws'], reason: 'draws of the random source');
      expect(
        rng.inner.next(),
        ex['nextDraw'],
        reason: 'the next draw (same place in the stream)',
      );
      // the pictures of the next ask were asked for (a hint the old page has no counterpart of)
      expect(shown.every((l) => l.length == 2), isTrue);
    });
  }
}
