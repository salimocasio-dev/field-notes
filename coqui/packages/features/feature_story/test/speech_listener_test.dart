// The real recogniser path of a speaking turn (docs/hablar/01-decisiones.md, "What counts as heard right" and "When speaking
// cannot work"): the settings it is started with, what its results mean, and what the story does when it goes wrong. The
// listener is a scripted one; the turns' rules are the same as with the stub (see speaking_turns_test.dart).
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/stand_in_scene.dart';
import 'speaking_turns_test.dart' show turnsStory;
import 'support/rig.dart';

class ScriptedTurn implements SpeechTurn {
  final Completer<SpeechResult> r = Completer();
  final Completer<void> end = Completer();
  bool cancelled = false;

  @override
  Future<SpeechResult> get result => r.future;

  @override
  Future<void> get speechEnd => end.future;

  @override
  void cancel() {
    cancelled = true;
    if (!r.isCompleted) r.complete(SpeechResult(error: 'aborted'));
  }
}

class Scripted implements SpeechListener {
  Scripted({this.isAvailable = true});

  bool isAvailable;
  final List<({String locale, Duration limit, int maxAlternatives})> listens =
      [];
  final List<ScriptedTurn> turns = [];

  @override
  Future<bool> available() async => isAvailable;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    listens.add((
      locale: locale,
      limit: limit,
      maxAlternatives: maxAlternatives,
    ));
    final t = ScriptedTurn();
    turns.add(t);
    return t;
  }
}

final things = [
  Thing(id: 'puerta', box: [150, 60, 30, 50]),
  Thing(id: 'ventana', box: [60, 60, 40, 30]),
];

void main() {
  Future<(Rig, Scripted)> start({bool available = true}) async {
    final sp = Scripted(isAvailable: available);
    final r = await Rig.make(
      turnsStory(),
      scene: StandInScene(things: things),
      speech: sp,
      allOpen: true,
    );
    await r.start();
    return (r, sp);
  }

  test('speaking is not offered when there is no recogniser, no network or no permission (available() false)', () async {
    final (r, sp) = await start(available: false);
    await r.advance(5000);
    expect(r.runner.habDisp(), isFalse);
    expect(r.runner.HAB.n, 0);
    expect(sp.listens, isEmpty);
    expect(r.runner.view.mic, '');
  });

  test('the recogniser is started inside the tap, in Spanish, with 5 alternatives and the 6 s limit', () async {
    final (r, sp) = await start();
    await r.until(() => r.runner.HAB.est == 'ready', what: 'the mic');
    expect(sp.listens, isEmpty);
    r.runner.tapMic();
    expect(sp.listens.single, (
      locale: 'es-US',
      limit: const Duration(seconds: 6),
      maxAlternatives: 5,
    ));
    expect(r.runner.HAB.est, 'listening');
    expect(r.runner.speaking, 0); // nothing plays while he is listened to
  });

  test('the end of speech shows the processing state; the result says heard right with his time to the first sound', () async {
    final (r, sp) = await start();
    await r.until(() => r.runner.HAB.est == 'ready');
    r.runner.tapMic();
    sp.turns.single.end.complete();
    await r.drain();
    expect(r.runner.HAB.est, 'processing');
    sp.turns.single.r.complete(
      SpeechResult(alternatives: ['ese', 'si'], msToSound: 340),
    );
    await r.until(() => r.runner.HAB.est == 'ok');
    expect(r.progress.answers.single, (w: 'sí', ok: true, ms: 340));
    expect(
      r.runner.view.bubbleText,
      'ese',
    ); // the best alternative is what shows
  });

  test(
    'no sound at all: msToSound is null and the time written is 0',
    () async {
      final (r, sp) = await start();
      await r.until(() => r.runner.HAB.est == 'ready');
      r.runner.tapMic();
      sp.turns.single.r.complete(SpeechResult(alternatives: ['si']));
      await r.until(() => r.runner.HAB.est == 'ok');
      expect(r.progress.answers.single.ms, 0);
    },
  );

  test('no-speech and aborted are misses; the mic is ready again, Ahora tú. is said again', () async {
    final (r, sp) = await start();
    await r.until(() => r.runner.HAB.est == 'ready');
    r.runner.tapMic();
    sp.turns.single.r.complete(SpeechResult(error: 'no-speech'));
    await r.until(
      () =>
          r.runner.HAB.est == 'ready' &&
          sp.turns.length == 1 &&
          r.clips.contains('ahora_tu') &&
          r.runner.habLog.single['intentos'] == 1,
      what: 'ready again',
    );
    r.runner.tapMic();
    sp.turns.last.r.complete(SpeechResult(error: 'aborted'));
    await r.until(
      () => r.runner.habLog.single['est'] == 'fallo',
      what: 'two misses',
    );
    expect(r.progress.answers.single.ok, isFalse);
  });

  test('not-allowed, network, audio-capture... say speaking cannot work here: the line plays as today, no more turns', () async {
    for (final code in [
      'not-allowed',
      'service-not-allowed',
      'network',
      'audio-capture',
      'language-not-supported',
    ]) {
      final (r, sp) = await start();
      await r.until(() => r.runner.HAB.est == 'ready');
      r.runner.tapMic();
      sp.turns.single.r.complete(SpeechResult(error: code));
      await r.until(
        () => r.runner.habLog.single['est'] == 'nodisp',
        what: code,
      );
      expect(r.progress.mouth, isEmpty);
      expect(r.runner.session.unavailable, isTrue);
      expect(r.runner.habDisp(), isFalse);
    }
  });

  test('after a turn the clips have a time limit of their length + 1 s (iPhone: a clip may never report its end)', () async {
    final (r, sp) = await start();
    await r.until(() => r.runner.HAB.est == 'ready');
    final before = r.player.limits.length;
    expect(r.player.limits.every((l) => l == null), isTrue);
    r.runner.tapMic();
    sp.turns.single.r.complete(
      SpeechResult(alternatives: ['si'], msToSound: 100),
    );
    await r.until(
      () => r.player.limits.length > before + 1,
      what: 'a clip after the turn',
    );
    expect(
      r.player.limits.last,
      const Duration(milliseconds: 2000),
    ); // the test course's clips are 1000 ms long
  });

  test('a touch on an elige while the mic listens takes the recogniser back (cancel)', () async {
    final sp = Scripted();
    final r = await Rig.make(
      turnsStory(
        beats: [
          {'wait': 100},
          {
            'elige': 'x',
            'options': ['si', 'no'],
            'line': 'bizcocho_q',
            'said': {'si': 'cq_si_gracias', 'no': 'cq_no_gracias'},
            'si': ['toma'],
            'no': ['abuela_no'],
          },
        ],
      ),
      scene: StandInScene(things: things),
      speech: sp,
      allOpen: true,
    );
    await r.start();
    await r.until(() => r.runner.HAB.est == 'ready');
    r.runner.tapMic();
    expect(r.runner.HAB.est, 'listening');
    // a touch does nothing while he is listened to, but an elige may still be answered by touching
    r.touch('si');
    await r.until(() => sp.turns.single.cancelled, what: 'the cancel');
    expect(r.progress.mouth, isEmpty); // nothing is written for a touch
  });
}
