// The call without a screen, on the scripted fake call of coqui_testing: one test for each check of
// historia/tools/llamada_check.py (its name is in the test's name), and the rest of what llamada.js does.
//
// The call's clock is a FakeClock the test moves together with the fake call's own timers (CallRig.elapse).
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/call_rig.dart';
import 'support/scripted_call.dart';

// The seven words of La casa in the stub's three learner lines, in the order the page records them
// (the order of the place's words: "Hola. Bien, gracias." gives hola, gracias, bien, and so on).
const stubWords = ['hola', 'gracias', 'bien', 'sí', 'jugo', 'quiero', 'adiós'];

/// A rig with the controller opened, as the screen opens it.
Future<CallRig> opened({Set<String> stub = const {}}) async {
  final rig = await CallRig.create(stub: stub);
  rig.controller.open();
  return rig;
}

/// The states the call went through, from now.
List<CallState> watch(CallController c) {
  final seq = <CallState>[c.state];
  c.addListener(() {
    if (seq.last != c.state) seq.add(c.state);
  });
  return seq;
}

/// The call's time in ms when the next text is sent, noted as the test moves on.
class SentClock {
  SentClock(this.rig, this.t0);
  final CallRig rig;
  final int t0;
  final List<int> at = [];
  int _seen = 0;

  void look() {
    while (_seen < rig.call.sent.length) {
      at.add(rig.clock.now - t0);
      _seen++;
    }
  }
}

void main() {
  group('the natural call', () {
    testWidgets(
      'natural call: states idle > connecting > danny > (you > proc > danny)... > done, ends by itself after the goodbye (fin)',
      (tester) async {
        final rig = await opened();
        final c = rig.controller;
        final seq = watch(c);
        expect(c.state, CallState.idle);
        c.start();
        expect(c.state, CallState.connecting);
        await rig.until(tester, () => c.state == CallState.done);
        expect(seq.sublist(0, 3), [
          CallState.idle,
          CallState.connecting,
          CallState.danny,
        ]);
        expect(seq.last, CallState.done);
        expect(
          seq.where((s) => s == CallState.proc).length,
          greaterThanOrEqualTo(3),
        );
        expect(c.why, 'fin');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(rig.call.ended, isTrue);
        expect(c.busy, isFalse);
        rig.dispose();
      },
    );

    testWidgets(
      'natural call: (fin) went out under 90 s of call time and the call ended under 2 minutes (timer), its minutes agree with the timer and it says 7 words said',
      (tester) async {
        final rig = await opened();
        final c = rig.controller;
        final t0 = rig.clock.now;
        final sent = SentClock(rig, t0);
        c.start();
        await rig.until(tester, () {
          sent.look();
          return c.state == CallState.done;
        });
        final fa = sent.at.first / 1000;
        expect(fa, greaterThan(0));
        expect(fa, lessThan(90));
        final parts = c.timerText.split(':');
        final secs = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        expect(secs, lessThan(120));
        final min = secs / 60 + 0.5;
        expect(
          c.summaryLine,
          '${min.floor() < 1 ? 1 : min.floor()} min · 7 words said',
        );
        expect(c.said, stubWords);
        rig.dispose();
      },
    );

    testWidgets(
      "the learner's goodbye: (fin) once, at once, the call ends after Danny's goodbye",
      (tester) async {
        // llamada_check: "the learner's 'Hasta mañana.' at under a minute: (fin) sent once at once, the call ends after
        // Danny's goodbye (why=fin), 'hasta mañana' counted as a word said"
        final rig = await opened(stub: {'hasta'});
        final c = rig.controller;
        final t0 = rig.clock.now;
        final sent = SentClock(rig, t0);
        c.start();
        await rig.until(tester, () {
          sent.look();
          return c.state == CallState.done;
        });
        expect(c.why, 'fin');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(sent.at.first, lessThan(60000));
        expect(rig.call.ended, isTrue);
        expect(c.said, contains('hasta mañana'));
        rig.dispose();
      },
    );

    testWidgets(
      "Danny's own goodbye: the call ends when his line is over (not at the 15 s cap), nothing is sent, why=fin",
      (tester) async {
        final rig = await opened(stub: {'dannybye'});
        final c = rig.controller;
        c.start();
        // the walk until Danny's third line begins (the learner says nothing more)
        await rig.until(
          tester,
          () => rig.call.log.where((m) => m == 'speaking').length >= 3,
        );
        final lineBegan = rig.clock.now;
        await rig.until(tester, () => c.state == CallState.done, maxMs: 20000);
        final dt = rig.clock.now - lineBegan;
        expect(c.why, 'fin');
        expect(rig.call.sent, isEmpty);
        expect(rig.call.ended, isTrue);
        expect(rig.call.log.where((m) => m == 'speaking').length, 3);
        expect(dt, lessThan(5000));
        rig.dispose();
      },
    );

    testWidgets(
      "the goodbye loop: the learner's goodbye, Danny goes on saying goodbyes every 3 s: (fin) once, the call ends after the first goodbye line, one goodbye line heard in all",
      (tester) async {
        final rig = await opened(stub: {'loop'});
        final c = rig.controller;
        final t0 = rig.clock.now;
        final sent = SentClock(rig, t0);
        c.start();
        await rig.until(tester, () {
          sent.look();
          return rig.call.sent.contains(CallTexts.sendEnd);
        });
        final finAt = rig.clock.now;
        await rig.until(tester, () => c.state == CallState.done, maxMs: 20000);
        final dt = rig.clock.now - finAt;
        await rig.elapse(tester, 4000);
        expect(c.why, 'fin');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(rig.call.ended, isTrue);
        expect(rig.call.log.where((m) => m == 'speaking').length, 3);
        expect(dt, lessThan(5000));
        expect(c.state, CallState.done);
        rig.dispose();
      },
    );

    testWidgets(
      "the goodbye loop after Danny's own goodbye: the call ends after his first goodbye line, nothing is sent, no second goodbye line",
      (tester) async {
        final rig = await opened(stub: {'dannybye', 'loop'});
        final c = rig.controller;
        c.start();
        await rig.until(
          tester,
          () => rig.call.log.where((m) => m == 'speaking').length >= 3,
        );
        final began = rig.clock.now;
        await rig.until(tester, () => c.state == CallState.done, maxMs: 20000);
        final dt = rig.clock.now - began;
        await rig.elapse(tester, 4000);
        expect(c.why, 'fin');
        expect(rig.call.sent, isEmpty);
        expect(rig.call.ended, isTrue);
        expect(rig.call.log.where((m) => m == 'speaking').length, 3);
        expect(dt, lessThan(5000));
        rig.dispose();
      },
    );

    testWidgets(
      'no answer to (fin): the page ends the call 15 s later (why=cap)',
      (tester) async {
        final rig = await opened(stub: {'nofin'});
        final c = rig.controller;
        c.start();
        await rig.until(
          tester,
          () => rig.call.sent.contains(CallTexts.sendEnd),
        );
        final finAt = rig.clock.now;
        await rig.until(tester, () => c.state == CallState.done, maxMs: 30000);
        final dt = rig.clock.now - finAt;
        expect(c.why, 'cap');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(rig.call.ended, isTrue);
        expect(dt, inInclusiveRange(finCapMs, finCapMs + 100));
        rig.dispose();
      },
    );
  });

  group('the limits', () {
    testWidgets(
      '6-minute rule: (fin) sent once at 6 call-minutes, the call ends when Danny has said goodbye (why=fin, before 7 min)',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1')
          ..go('you1');
        await rig.elapse(tester, 100);
        // five minutes and fifty-nine seconds: nothing yet
        rig.clock.advance(const Duration(seconds: 359));
        c.tick();
        expect(rig.call.sent, isEmpty);
        rig.clock.advance(const Duration(seconds: 1));
        c.tick();
        expect(rig.call.sent, [CallTexts.sendEnd]);
        await rig.until(tester, () => c.state == CallState.done, maxMs: 10000);
        expect(c.why, 'fin');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(rig.call.ended, isTrue);
        final parts = c.timerText.split(':');
        expect(int.parse(parts[0]), lessThan(7));
        rig.dispose();
      },
    );

    testWidgets(
      '7-minute stop: (fin) sent at 6 min, the call ended by the page at 7 min even with no answer (why=max)',
      (tester) async {
        // The old check's clock ran 60 times faster while the 15 s cap stayed real, so 7 minutes came before the cap.
        // Here the cap is on the same clock; a clock that jumps (the page was asleep) reaches both limits in one step.
        final rig = await opened(stub: {'manual', 'nofin'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1');
        await rig.elapse(tester, 100);
        rig.clock.advance(const Duration(seconds: 421));
        c.tick();
        expect(c.state, CallState.done);
        expect(c.why, 'max');
        expect(rig.call.sent, [CallTexts.sendEnd]);
        expect(rig.call.ended, isTrue);
        rig.dispose();
      },
    );
  });

  group('the tap and what it starts', () {
    testWidgets(
      'connecting: shows at once, label Calling…; the call is started once, from the tap, the lock is on',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        expect(c.label, 'Start call');
        expect(c.busy, isFalse);
        c.start();
        c.start(); // a second tap does nothing
        expect(c.state, CallState.connecting);
        expect(c.label, 'Calling…');
        expect(c.busy, isTrue);
        await tester.pump();
        expect(rig.call.starts, 1);
        rig.dispose();
      },
    );

    testWidgets('the tap stops every other sound before the microphone opens', (
      tester,
    ) async {
      final rig = await opened(stub: {'manual'});
      rig.controller.start();
      await tester.pump();
      expect(rig.clips.stops, 1);
      expect(rig.clips.loops, [('rain', false)]);
      rig.dispose();
    });

    testWidgets(
      'variables: place, job, minutes 5, opening; words_open = every place word of La casa (50, in the list order); words_heard empty; the six variables, no more',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        rig.controller.start();
        await tester.pump();
        final v = rig.call.variables!;
        expect(v.keys.toSet(), {
          'place',
          'job',
          'words_open',
          'words_heard',
          'minutes',
          'opening',
        });
        expect(v['place'], 'La casa');
        expect(v['minutes'], '5');
        expect(v['job'], startsWith('Say hello'));
        expect(v['opening'], isNotEmpty);
        expect(v['words_open']!.split(', '), rig.casaWords);
        expect(rig.casaWords.length, 50);
        expect(v['words_heard'], '');
        expect(rig.call.brief!.placeId, 'casa');
        rig.dispose();
      },
    );
  });

  group('the screen of the call, state by state', () {
    testWidgets(
      'danny: state, label Danny, the rings reach as far as his voice is loud; the timer shows 00:00 at the start',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call.go('connect');
        await rig.elapse(tester, 120);
        expect(c.state, CallState.danny);
        expect(c.label, 'Danny');
        expect(c.timerText, '00:00');
        rig.call.go('danny1');
        await rig.elapse(tester, 100);
        expect(c.dannyLine, '¡Hola! Soy Danny. ¿Cómo estás?');
        expect(c.lineMuted, isFalse);
        // 1.3 + min(1, .15 * 4) * .6
        expect(c.wave, closeTo(1.66, 1e-9));
        rig.dispose();
      },
    );

    testWidgets(
      'you: the ring thickness follows the microphone level (quiet 3 px, talking more than 5 px); the dots come after he went quiet for 0.6 s; every change of state shows within 200 ms',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1');
        await rig.elapse(tester, 2000);
        // within 200 ms of its cause
        rig.call.go('you1');
        await tester.pump();
        expect(c.state, CallState.you);
        expect(c.label, 'Your turn');
        expect(c.ring, 3);
        rig.call.go('talk1');
        await rig.elapse(tester, 500);
        expect(c.ring, greaterThan(5));
        rig.call.go('quiet1');
        final quietAt = rig.clock.now;
        await rig.until(tester, () => c.state == CallState.proc, maxMs: 3000);
        final after = rig.clock.now - quietAt;
        expect(c.label, 'One moment');
        expect(after, inInclusiveRange(550, 750));
        rig.call.go('heard1');
        await tester.pump();
        expect(c.heardLine, 'Hola. Bien, gracias.');
        rig.call.go('danny2');
        await tester.pump();
        expect(c.state, CallState.danny);
        rig.dispose();
      },
    );

    testWidgets(
      "show_picture('puerta') changes the picture; a key that is not a word of the place, or a word with no picture, is ignored",
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        expect(c.pictureWord, 'casa');
        expect(c.pictureShown, isTrue);
        c.start();
        await tester.pump();
        rig.call.go('connect');
        await rig.elapse(tester, 200);
        rig.call.emit(const Tool('show_picture', {'picture': 'zzz'}));
        rig.call.emit(const Tool('show_picture', {'picture': 'bizcocho'}));
        await rig.elapse(tester, 100);
        expect(c.pictureWord, 'casa');
        rig.call.emit(const Tool('show_picture', {'picture': 'Puerta'}));
        await rig.elapse(tester, 100);
        expect(c.pictureWord, 'puerta');
        expect(c.picturePair, isNotNull);
        // other names of the argument the old page took
        rig.call.emit(const Tool('show_picture', {'key': 'ventana'}));
        await rig.elapse(tester, 100);
        expect(c.pictureWord, 'ventana');
        // 'jugo' is a word of La casa and the sample course has no picture for it: the picture stays
        rig.call.emit(const Tool('show_picture', {'picture': 'jugo'}));
        await rig.elapse(tester, 100);
        expect(c.pictureWord, 'ventana');
        rig.dispose();
      },
    );
  });

  group('Help, the X and the ways out', () {
    testWidgets('Help sends (ayuda), says so, and the note goes after 5 s', (
      tester,
    ) async {
      final rig = await opened(stub: {'manual'});
      final c = rig.controller;
      c.start();
      await tester.pump();
      rig.call
        ..go('connect')
        ..go('danny1')
        ..go('you1');
      await rig.elapse(tester, 300);
      c.help();
      expect(rig.call.sent, [CallTexts.sendHelp]);
      expect(c.note, 'Danny will say it again, slowly.');
      expect(c.helpPressed, isTrue);
      await rig.elapse(tester, 650);
      expect(c.helpPressed, isFalse);
      expect(c.note, isNotEmpty);
      await rig.elapse(tester, 4500);
      expect(c.note, isEmpty);
      rig.dispose();
    });

    testWidgets("Help before the call is live does nothing", (tester) async {
      final rig = await opened(stub: {'manual'});
      final c = rig.controller;
      c.help();
      c.start();
      await tester.pump();
      c.help();
      expect(rig.call.sent, isEmpty);
      rig.dispose();
    });

    testWidgets(
      "the learner's 'Adiós.' at under a minute sends (fin) at once, after the Help message",
      (tester) async {
        final rig = await opened(stub: {'manual', 'nofin'});
        final c = rig.controller;
        final t0 = rig.clock.now;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1')
          ..go('you1');
        await rig.elapse(tester, 1000);
        c.help();
        rig.call.emit(const Heard('Adiós.'));
        await tester.pump();
        expect(rig.call.sent, [CallTexts.sendHelp, CallTexts.sendEnd]);
        expect(rig.clock.now - t0, lessThan(60000));
        expect(c.ending, isTrue);
        expect(rig.call.ended, isFalse);
        rig.dispose();
      },
    );

    testWidgets(
      'the timer counts (mm:ss), and the X ends the live call with the summary: 1 min, the words said, the call ended, the lock released, the minutes counted',
      (tester) async {
        final rig = await opened(stub: {'manual', 'nofin'});
        final c = rig.controller;
        final before = rig.progress.minutes;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1')
          ..go('you1');
        await rig.elapse(tester, 3200);
        expect(c.timerText, '00:03');
        rig.call.emit(const Heard('Hola. Bien, gracias.'));
        await tester.pump();
        c.closeX();
        expect(c.state, CallState.done);
        expect(c.summaryLine, '1 min · 3 words said');
        expect(c.said, ['hola', 'gracias', 'bien']);
        expect(c.why, 'x');
        expect(rig.call.ended, isTrue);
        expect(c.busy, isFalse);
        expect(rig.progress.minutes, greaterThan(before));
        expect(rig.progress.minutes - before, closeTo(3.2 / 60, 0.01));
        expect(rig.closes, 0, reason: 'the summary stays until Back to Hablar');
        c.close();
        expect(rig.closes, 1);
        expect(c.closed, isTrue);
        rig.dispose();
      },
    );

    testWidgets('the X ends it with "1 word said" in the singular', (
      tester,
    ) async {
      final rig = await opened(stub: {'manual'});
      final c = rig.controller;
      c.start();
      await tester.pump();
      rig.call
        ..go('connect')
        ..go('danny1')
        ..go('you1');
      await rig.elapse(tester, 500);
      rig.call.emit(const Heard('Hola.'));
      await tester.pump();
      c.closeX();
      expect(c.summaryLine, '1 min · 1 word said');
      rig.dispose();
    });

    testWidgets(
      'X before the call starts closes the screen; the lock is free; the call can be opened again',
      (tester) async {
        final rig = await opened();
        final c = rig.controller;
        c.closeX();
        expect(c.closed, isTrue);
        expect(rig.closes, 1);
        expect(c.busy, isFalse);
        expect(rig.call.starts, 0);
        // "the call can be opened again": a new screen, a new controller, idle
        rig.controller = rig.newController()..open();
        expect(rig.controller.state, CallState.idle);
        expect(rig.controller.closed, isFalse);
        rig.dispose();
      },
    );

    testWidgets(
      'X while calling: hang up before it picks up; the screen is gone, the lock free, the late answer is ended at once and nothing shows',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        expect(c.state, CallState.connecting);
        expect(c.busy, isTrue);
        c.closeX();
        expect(c.closed, isTrue);
        expect(rig.closes, 1);
        expect(c.busy, isFalse);
        rig.call.go('connect'); // the late answer
        await rig.elapse(tester, 300);
        expect(rig.call.ended, isTrue);
        expect(
          c.state,
          CallState.connecting,
          reason: 'nothing shows after the X',
        );
        expect(c.ticking, isFalse);
        rig.dispose();
      },
    );

    testWidgets(
      'Danny ends the call: summary, why=disc, lock free; a second tap on the disc did nothing',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1');
        await rig.elapse(tester, 300);
        rig.call.go('end');
        await rig.elapse(tester, 100);
        expect(rig.call.starts, 1);
        expect(c.state, CallState.done);
        expect(c.why, 'disc');
        expect(c.busy, isFalse);
        expect(c.ticking, isFalse);
        rig.dispose();
      },
    );

    testWidgets(
      'pagehide while live: ends the session, clears the timers, frees the lock, counts the minutes',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        final before = rig.progress.minutes;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1');
        await rig.elapse(tester, 1200);
        c.pageHide();
        expect(rig.call.ended, isTrue);
        expect(c.busy, isFalse);
        expect(c.ticking, isFalse);
        expect(rig.progress.minutes, greaterThan(before));
        // no timers of the call left: nothing moves any more
        final saves = rig.progress.saves;
        await rig.elapse(tester, 20000);
        expect(rig.progress.saves, saves);
        expect(rig.call.sent, isEmpty);
        rig.dispose();
      },
    );

    testWidgets('leaving the screen in a live call does what pagehide did', (
      tester,
    ) async {
      final rig = await opened(stub: {'manual'});
      final c = rig.controller;
      c.start();
      await tester.pump();
      rig.call
        ..go('connect')
        ..go('danny1');
      await rig.elapse(tester, 1200);
      c.leave();
      expect(rig.call.ended, isTrue);
      expect(rig.progress.minutes, greaterThan(0));
      rig.dispose();
    });
  });

  group('the errors', () {
    testWidgets(
      'refused microphone: one plain line and the X; the X closes it, the lock is free',
      (tester) async {
        final rig = await opened(stub: {'mic'});
        final c = rig.controller;
        c.start();
        await rig.until(tester, () => c.state == CallState.err, maxMs: 3000);
        expect(
          c.errorLine,
          'The microphone is off. Allow it in your browser to call.',
        );
        expect(c.busy, isFalse);
        c.closeX();
        expect(c.closed, isTrue);
        expect(rig.closes, 1);
        rig.dispose();
      },
    );

    testWidgets('failed start: a plain line', (tester) async {
      final rig = await opened(stub: {'fail'});
      final c = rig.controller;
      c.start();
      await rig.until(tester, () => c.state == CallState.err, maxMs: 3000);
      expect(
        c.errorLine,
        'The call did not start. Check your connection and try again.',
      );
      expect(c.busy, isFalse);
      c.closeX();
      expect(rig.closes, 1);
      rig.dispose();
    });

    testWidgets(
      'without the library: the tap gives "The voice part did not load. Check your connection and try again.", the X closes, the lock is free',
      (tester) async {
        final rig = await CallRig.create(
          stub: {'manual'},
          startError: Exception(
            'LibraryError: The voice library did not load.',
          ),
        );
        final c = rig.controller..open();
        c.start();
        await rig.until(tester, () => c.state == CallState.err, maxMs: 3000);
        expect(
          c.errorLine,
          'The voice part did not load. Check your connection and try again.',
        );
        expect(c.busy, isFalse);
        c.closeX();
        expect(c.closed, isTrue);
        rig.dispose();
      },
    );

    testWidgets('the place has no stories to read: the call does not start', (
      tester,
    ) async {
      // llamada.js: palabrasDe gives nothing (no story can be read): "The call did not start..."
      final rig = await CallRig.create(stub: {'manual'});
      rig.course.readable = false;
      final c = rig.controller..open();
      c.start();
      await tester.pump();
      await tester.pump();
      expect(c.state, CallState.err);
      expect(
        c.errorLine,
        'The call did not start. Check your connection and try again.',
      );
      expect(rig.call.starts, 0);
      expect(c.busy, isFalse);
      rig.dispose();
    });

    testWidgets(
      'the connection drops before it connects: the microphone line when the error says so, else the plain one',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call.emit(const CallError('Permission denied by the browser'));
        rig.call.emit(const Ended('user'));
        await tester.pump();
        expect(c.state, CallState.err);
        expect(
          c.errorLine,
          'The microphone is off. Allow it in your browser to call.',
        );
        final rig2 = await opened(stub: {'manual'});
        final c2 = rig2.controller;
        c2.start();
        await tester.pump();
        rig2.call.emit(const CallError('socket closed'));
        rig2.call.emit(const Ended('agent'));
        await tester.pump();
        expect(
          c2.errorLine,
          'The call did not start. Check your connection and try again.',
        );
        rig.dispose();
        rig2.dispose();
      },
    );
  });

  group('the words said, the minutes', () {
    testWidgets(
      'mouth records saved: each of the 7 matched words 0/0 -> 1/1, nothing else recorded, ms given',
      (tester) async {
        final rig = await opened();
        final c = rig.controller;
        final before = rig.progress.minutes;
        for (final w in stubWords) {
          expect(rig.progress.word(w)?.mouth.n ?? 0, 0);
        }
        c.start();
        await rig.until(tester, () => c.state == CallState.done);
        final calls = rig.progress.answers;
        expect(calls.length, 7);
        expect([for (final a in calls) a[0]], stubWords);
        expect(calls.every((a) => a[1] == 'mouth' && a[2] == true), isTrue);
        expect(calls.every((a) => a[3] == null || a[3] is int), isTrue);
        for (final w in stubWords) {
          final m = rig.progress.word(w)!.mouth;
          expect([m.n, m.bien], [1, 1]);
        }
        // minutes listened went up with the call
        expect(rig.progress.minutes, greaterThan(before));
        rig.dispose();
      },
    );

    testWidgets(
      'a speaking turn is open when the line comes: ms is how long he took to start speaking',
      (tester) async {
        final rig = await opened(stub: {'manual'});
        final c = rig.controller;
        c.start();
        await tester.pump();
        rig.call
          ..go('connect')
          ..go('danny1');
        await rig.elapse(tester, 500);
        rig.call.go('you1');
        await rig.elapse(tester, 300);
        rig.call.go('talk1');
        await rig.elapse(tester, 300);
        rig.call.go('quiet1');
        await rig.elapse(tester, 1000);
        rig.call.emit(const Heard('gracias'));
        await tester.pump();
        // the turn began at you1; he was loud from the next 50 ms step after talk1 (300 ms on)
        expect(rig.progress.answers, [
          ['gracias', 'mouth', true, 300],
        ]);
        rig.dispose();
      },
    );

    testWidgets('our own (ayuda) and (fin) coming back are not his words', (
      tester,
    ) async {
      final rig = await opened(stub: {'manual'});
      final c = rig.controller;
      c.start();
      await tester.pump();
      rig.call
        ..go('connect')
        ..go('danny1');
      await rig.elapse(tester, 300);
      rig.call.emit(const Heard('(ayuda)'));
      rig.call.emit(const Heard('(fin) hola'));
      rig.call.emit(const Heard('  (casa)'));
      await tester.pump();
      expect(rig.progress.answers, isEmpty);
      expect(c.heardLine, '');
      rig.dispose();
    });
  });

  group('persisted call completion and readiness', () {
    testWidgets(
      'finish marks legacy main call id done on fin, closeX while live, disc, and max, and persists across export/import',
      (tester) async {
        // 1. Natural fin
        final rigFin = await opened();
        rigFin.controller.start();
        await rigFin.until(
          tester,
          () => rigFin.controller.state == CallState.done,
        );
        expect(rigFin.controller.why, 'fin');
        expect(rigFin.progress.callDone('casa'), isTrue);
        final restored = FakeProgressStore(json: rigFin.progress.export());
        expect(restored.callDone('casa'), isTrue);
        rigFin.dispose();

        // 2. closeX while live
        final rigX = await opened(stub: {'manual', 'nofin'});
        rigX.controller.start();
        await tester.pump();
        rigX.call
          ..go('connect')
          ..go('danny1')
          ..go('you1');
        await rigX.elapse(tester, 500);
        rigX.controller.closeX();
        expect(rigX.controller.why, 'x');
        expect(rigX.progress.callDone('casa'), isTrue);
        rigX.dispose();

        // 3. Disconnect while live
        final rigDisc = await opened(stub: {'manual'});
        rigDisc.controller.start();
        await tester.pump();
        rigDisc.call
          ..go('connect')
          ..go('danny1');
        await rigDisc.elapse(tester, 300);
        rigDisc.call.go('end');
        await rigDisc.elapse(tester, 100);
        expect(rigDisc.controller.why, 'disc');
        expect(rigDisc.progress.callDone('casa'), isTrue);
        rigDisc.dispose();

        // 4. Max time
        final rigMax = await opened(stub: {'manual', 'nofin'});
        rigMax.controller.start();
        await tester.pump();
        rigMax.call
          ..go('connect')
          ..go('danny1');
        await rigMax.elapse(tester, 100);
        rigMax.clock.advance(const Duration(seconds: 421));
        rigMax.controller.tick();
        expect(rigMax.controller.why, 'max');
        expect(rigMax.progress.callDone('casa'), isTrue);
        rigMax.dispose();
      },
    );

    testWidgets(
      'finish marks CallsCatalog callId done and persists across export/import',
      (tester) async {
        final course = _CallsCatalogCourse(
          places: [
            Place(
              id: 'cocina',
              n: 1,
              name: 'La cocina',
              en: 'The kitchen',
              stories: const ['cocina-1'],
            ),
          ],
          callsByPlace: {
            'cocina': [
              CallBrief(
                id: 'cocina_tomar',
                placeId: 'cocina',
                title: '¿Qué quieres tomar?',
                jobEn: 'Say what you want to drink.',
                minutes: 2,
                job: 'Drink',
                opening: 'Hola',
                isMain: false,
              ),
            ],
          },
        );
        await course.load();
        final clock = FakeClock();
        final progress = RecordingProgress(clock: clock);
        final session = ScriptedCall(stub: {'manual'});
        final c = CallController(
          session: session,
          clock: clock,
          course: course,
          progress: progress,
          placeId: 'cocina',
          callId: 'cocina_tomar',
        );
        expect(c.available, isTrue);
        c.open();
        c.start();
        await tester.pump();
        session
          ..go('connect')
          ..go('danny1');
        await tester.pump();
        clock.advance(const Duration(milliseconds: 500));
        c.tick();
        c.finish('fin');
        expect(progress.callDone('cocina_tomar'), isTrue);
        final restored = FakeProgressStore(json: progress.export());
        expect(restored.callDone('cocina_tomar'), isTrue);
        c.dispose();
        session.dispose();
      },
    );

    testWidgets(
      'failed start and closeX while connecting do not mark the call done',
      (tester) async {
        // Mic error
        final rigMic = await opened(stub: {'mic'});
        rigMic.controller.start();
        await rigMic.until(
          tester,
          () => rigMic.controller.state == CallState.err,
          maxMs: 3000,
        );
        expect(rigMic.progress.callDone('casa'), isFalse);
        rigMic.dispose();

        // Failed start
        final rigFail = await opened(stub: {'fail'});
        rigFail.controller.start();
        await rigFail.until(
          tester,
          () => rigFail.controller.state == CallState.err,
          maxMs: 3000,
        );
        expect(rigFail.progress.callDone('casa'), isFalse);
        rigFail.dispose();

        // closeX while connecting (_t0 == null)
        final rigConn = await opened(stub: {'manual'});
        rigConn.controller.start();
        await tester.pump();
        expect(rigConn.controller.state, CallState.connecting);
        rigConn.controller.closeX();
        expect(rigConn.progress.callDone('casa'), isFalse);
        rigConn.dispose();
      },
    );

    testWidgets(
      'CallBrief with empty or whitespace opening has available == false and open/start are no-ops',
      (tester) async {
        for (final opening in ['', '   ', '\n\t']) {
          final course = _CallsCatalogCourse(
            places: [
              Place(
                id: 'parque',
                n: 1,
                name: 'El parque',
                en: 'The park',
                stories: const ['la-lluvia'],
              ),
            ],
            callsByPlace: {
              'parque': [
                CallBrief(
                  id: 'parque_main',
                  placeId: 'parque',
                  title: 'El perro en el parque',
                  jobEn: 'Describe the park.',
                  minutes: 5,
                  job: 'Describe the park.',
                  opening: opening,
                  isMain: true,
                ),
              ],
            },
          );
          await course.load();
          final clock = FakeClock();
          final progress = RecordingProgress(clock: clock);
          final session = ScriptedCall();
          final c = CallController(
            session: session,
            clock: clock,
            course: course,
            progress: progress,
            placeId: 'parque',
            callId: 'parque_main',
          );
          expect(c.brief, isNotNull);
          expect(c.available, isFalse);
          c.open();
          expect(c.dannyLine, isEmpty);
          expect(c.libraryReadyAtOpen, isFalse);
          await c.start();
          expect(c.state, CallState.idle);
          expect(session.starts, 0);
          expect(progress.callDone('parque_main'), isFalse);
          c.dispose();
          session.dispose();
        }
      },
    );
  });
}

class _CallsCatalogCourse extends FixtureCourse {
  _CallsCatalogCourse({required List<Place> places, required this.callsByPlace})
    : _customPlaces = places;

  final List<Place> _customPlaces;
  final Map<String, List<CallBrief>> callsByPlace;

  @override
  List<Place> get places => _customPlaces;

  @override
  Future<Map<String, dynamic>> story(String id) async {
    if (id == 'cocina-1') {
      return {
        'id': 'cocina-1',
        'place': 'La cocina',
        'focus_words': ['agua', 'jugo'],
      };
    }
    return super.story(id);
  }

  @override
  List<CallBrief> callsFor(String placeId) => callsByPlace[placeId] ?? const [];

  @override
  CallBrief? callFor(String placeId) {
    final list = callsFor(placeId);
    if (list.isEmpty) return null;
    for (final c in list) {
      if (c.isMain) return c;
    }
    return list.first;
  }
}
