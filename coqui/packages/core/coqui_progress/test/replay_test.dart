// Replays the recordings of historia/palabras.js (coqui/ref/progress/, as a Dart fixture) on the
// PalabrasStore: for each call of each sequence, the same call with the clock at the recorded
// time, then the WHOLE store against the recorded one (numbers as numbers, exact), and the return
// value. Also: the text the store saved against what palabras.js saved, and export().
//
// The same replay runs the pieces of historia/app.html that read or write the store (marcaLeido, extra,
// the settings handlers, hecho ...), cut out of the page and run against the real palabras.js by
// tool/app_sequences.mjs: the members palabras.js does not have (markRead, hasRead, add, added,
// setting, setSetting, played, levelResult, minutes).
//
// The test process must run in the zone of the recordings it replays: UTC or America/New_York
// (`bash tool/test_zones.sh` runs both, on the VM and in Chrome). In any other zone it fails.
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_progress/coqui_progress.dart';
import 'package:test/test.dart';

import 'fixtures/progress_fixture.dart';
import 'support/diff.dart';
import 'support/fakes.dart';
import 'support/zone.dart';

void main() {
  final zone = detectedZone();
  if (zone == null) {
    test('the time zone is one the recordings were made in', () {
      fail(
        'This test process runs in a time zone the recordings do not cover '
        '(${zoneOffsets()}). They were made in UTC (offsets 0 and 0) and in '
        'America/New_York (-5:00 in January, -4:00 in July). Run it with TZ=UTC or '
        'TZ=America/New_York, or use tool/test_zones.sh.',
      );
    });
    return;
  }

  final ids = [
    for (final k in fixtureSequences.keys)
      if (k.startsWith('$zone/')) k,
  ];
  final sequences = {
    for (final k in ids)
      k: jsonDecode(fixtureSequences[k]!) as Map<String, dynamic>,
  };
  final replayable = [
    for (final k in ids)
      if (sequences[k]!['dartReplayable'] == true) k,
  ];
  final skipped = [
    for (final k in ids)
      if (sequences[k]!['dartReplayable'] != true) k,
  ];
  // The calls a replay makes: a step with a ProgressStore member and its arguments in Dart.
  bool replays(Map<String, dynamic> s) =>
      s['member'] != null && s['dart'] != null;
  final expectedCalls = [
    for (final k in replayable)
      for (final s
          in (sequences[k]!['steps'] as List).cast<Map<String, dynamic>>())
        if (replays(s)) s,
  ].length;
  var comparedSequences = 0;
  var comparedCalls = 0;

  test(
    'detected zone $zone (${zoneOffsets()}): '
    'replaying ${replayable.length} sequences, $expectedCalls calls; '
    'skipped ${skipped.length}: ${skipped.map((k) => k.split('/').last).join(', ')}',
    () {
      expect(replayable, isNotEmpty);
    },
  );

  group('the $zone recordings', () {
    for (final key in replayable) {
      final seq = sequences[key]!;
      final steps = (seq['steps'] as List).cast<Map<String, dynamic>>();
      test('${seq['id']}: ${steps.length} steps', () {
        comparedCalls += _replay(key, seq, steps, replays);
        comparedSequences++;
      });
    }
  });

  test(
    'compared ${replayable.length} sequences and $expectedCalls calls in $zone',
    () {
      expect(comparedSequences, replayable.length);
      expect(comparedCalls, expectedCalls);
    },
  );

  // historia/app.html, run: the same, from tool/app_sequences.mjs
  final appIds = [
    for (final k in fixtureAppSequences.keys)
      if (k.startsWith('$zone/')) k,
  ];
  final appSequences = {
    for (final k in appIds)
      k: jsonDecode(fixtureAppSequences[k]!) as Map<String, dynamic>,
  };
  final appCalls = [
    for (final k in appIds)
      for (final s
          in (appSequences[k]!['steps'] as List).cast<Map<String, dynamic>>())
        if (replays(s)) s,
  ].length;
  var comparedAppSequences = 0;
  var comparedAppCalls = 0;

  test(
    'detected zone $zone: also replaying ${appIds.length} app.html sequences, $appCalls calls',
    () {
      expect(appIds, isNotEmpty);
    },
  );

  group('the $zone app.html pieces', () {
    for (final key in appIds) {
      final seq = appSequences[key]!;
      final steps = (seq['steps'] as List).cast<Map<String, dynamic>>();
      test('${seq['id']}: ${steps.length} steps', () {
        comparedAppCalls += _replay(key, seq, steps, replays);
        comparedAppSequences++;
      });
    }
  });

  test(
    'compared ${appIds.length} app.html sequences and $appCalls calls in $zone',
    () {
      expect(comparedAppSequences, appIds.length);
      expect(comparedAppCalls, appCalls);
    },
  );
}

/// Replays one sequence. Returns how many calls it made.
int _replay(
  String key,
  Map<String, dynamic> seq,
  List<Map<String, dynamic>> steps,
  bool Function(Map<String, dynamic>) replays,
) {
  final setup = seq['setup'] as Map<String, dynamic>;
  final broken = setup['storage'] != 'memory';
  final kv = MemoryKeyValueStore(
    stored: setup['stored'] as String?,
    broken: broken,
    key: PalabrasStore.storageKey,
  );
  final clock = SettableClock(((steps.first['now']) as num).toInt());
  final store = PalabrasStore(kv, clock);

  // Before any call: what palabras.js had after loading.
  final initial = seq['initial'] as Map<String, dynamic>;
  _expectSame(
    store.raw,
    jsonDecode(initial['store'] as String),
    '$key, loaded',
  );
  _expectSavedText(kv, initial['saved'], null, '$key, loaded');

  var calls = 0;
  for (final step in steps) {
    final where = '$key, step ${step['i']} (${step['call']})';
    clock.now = (step['now'] as num).toInt();
    final expectedStore = step['store'] as String;
    if (replays(step)) {
      calls++;
      final dart = (step['dart'] as Map).cast<String, dynamic>();
      final throws = step['throws'] != null;
      Object? returned;
      Object? thrown;
      try {
        returned = _call(store, step['member'] as String, dart);
      } catch (e) {
        thrown = e;
      }
      if (throws) {
        expect(
          thrown,
          isNotNull,
          reason: '$where: palabras.js threw (${step['throws']}), this did not',
        );
      } else {
        expect(
          thrown,
          isNull,
          reason: '$where: this threw, palabras.js did not',
        );
        if (step.containsKey('returns')) {
          _expectSame(returned, step['returns'], '$where, return value');
        } else {
          expect(
            returned,
            isNull,
            reason: '$where: palabras.js returned nothing',
          );
        }
      }
    }
    // The whole store, and the text that goes with it.
    _expectSame(store.raw, jsonDecode(expectedStore), '$where, the store');
    expect(store.export(), expectedStore, reason: '$where: export()');
    if (step['call'] == 'save') {
      // PAL.save() has no ProgressStore member: palabras.js oida() and rec() do not save, and a
      // later save() writes what they left. Its effect is writing the text export() gives.
      expect(kv.broken || step['saved'] == 'same', isTrue, reason: where);
      if (!kv.broken) kv.write(PalabrasStore.storageKey, store.export());
    }
    _expectSavedText(kv, step['saved'], expectedStore, '$where, saved');
  }
  return calls;
}

/// The call of one step, by the ProgressStore member (the README of ref/progress). Returns what
/// the member returns, as JSON.
Object? _call(PalabrasStore store, String member, Map<String, dynamic> a) {
  List<String> strings(Object? v) => [for (final x in v as List) x as String];
  switch (member) {
    case 'heard':
      return store.heard(a['w'] as String).toJson();
    case 'answer':
      return store
          .answer(
            a['w'] as String,
            Skill.values.byName(a['skill'] as String),
            ok: a['ok'] as bool,
            ms: (a['ms'] as num?)?.toInt(),
            intro: a['intro'] as bool,
          )
          .toJson();
    case 'storyFinished':
      final r = a['result'] as Map<String, dynamic>;
      store.storyFinished(
        StoryResult(
          id: r['id'] as String,
          focusWords: strings(r['focusWords']),
          backAgain: strings(r['backAgain']),
          lost: (r['lost'] as num).toInt(),
          log: [
            for (final d in r['log'] as List)
              Decision.fromJson((d as Map).cast<String, dynamic>()),
          ],
        ),
      );
      return null;
    case 'presume':
      store.presume(
        strings(a['words']),
        strings(a['stories']),
        (a['log'] as List).cast<Object?>(),
      );
      return null;
    case 'listened':
      store.listened(a['id'] as String);
      return null;
    case 'addMinutes':
      store.addMinutes((a['m'] as num).toDouble());
      return null;
    case 'due':
      return store.due(
        Skill.values.byName(a['skill'] as String),
        at: (a['at'] as num?)?.toInt(),
      );
    case 'streak':
      return store.streak;
    case 'openForSpeaking':
      return store.openForSpeaking(a['w'] as String);
    case 'normalize':
      return normalize(a['s'] as String?);
    case 'reset':
      store.reset();
      return null;
    case 'raw':
      return store.raw;
    // the members palabras.js does not have: historia/app.html (tool/app_sequences.mjs)
    case 'markRead':
      store.markRead(a['id'] as String);
      return null;
    case 'hasRead':
      return store.hasRead(a['id'] as String);
    case 'add':
      store.add(a['wordOrGoal'] as String);
      return null;
    case 'added':
      return store.added;
    case 'played':
      return store.played(a['id'] as String);
    case 'setting':
      return store.setting(a['key'] as String);
    case 'setSetting':
      store.setSetting(a['key'] as String, a['value'] as Object);
      return null;
    case 'levelResult':
      return store.levelResult;
    case 'minutes':
      return store.minutes;
  }
  throw StateError(
    'the recording has a member this test does not know: $member',
  );
}

void _expectSame(Object? actual, Object? expected, String where) {
  final d = firstDifference(actual, expected);
  expect(d, isNull, reason: '$where: $d');
}

/// What is in the storage, against the recording's `saved`: "same" is the store's own text;
/// null is nothing stored; {"text": t} is text that is not JSON; anything else is the stored JSON.
void _expectSavedText(
  MemoryKeyValueStore kv,
  Object? saved,
  String? storeText,
  String where,
) {
  final text = kv.data[PalabrasStore.storageKey];
  if (saved == null) {
    expect(text, isNull, reason: '$where: nothing should be stored');
  } else if (saved == 'same') {
    expect(text, storeText, reason: '$where: the stored text is the store');
  } else if (saved is String) {
    expect(
      text,
      saved,
      reason: '$where: the text stored before the first save',
    );
  } else if (saved is Map && saved.length == 1 && saved['text'] is String) {
    expect(text, saved['text'], reason: '$where: text that is not JSON');
  } else {
    expect(text, isNotNull, reason: '$where: something should be stored');
    _expectSame(jsonDecode(text!), saved, '$where, the stored JSON');
  }
}
