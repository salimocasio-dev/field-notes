// The story's clock does not advance while the app is out of sight: the screen stops pumping the runner's timers and
// holds the virtual clock; on the return the story goes on from where it stopped (no burst of due timers, no jump).
//
// The app's lifecycle is changed as the platform changes it (`handleAppLifecycleStateChanged`); the clock is the
// test's own, moved by hand (a story on a real clock would be pumped by the frames, with the time that went by).
import 'package:coqui_testing/coqui_testing.dart' show FakeClipPlayer;
import 'package:coqui_ui/coqui_ui.dart' show NochePlayDisc;
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

void main() {
  /// The frames after the return, 20 ms each: which timers each of them fired, by name.
  Future<List<List<String>>> framesFor(
    Screen s,
    List<String> fired,
    int frames,
  ) async {
    final perFrame = <List<String>>[];
    for (var i = 0; i < frames; i++) {
      final before = fired.length;
      await s.advance(20);
      perFrame.add(fired.sublist(before));
    }
    return perFrame;
  }

  /// A timer of the story's own timers, due [ms] after the story's time now, that writes [name] when it fires.
  void timer(StoryRunner r, List<String> fired, String name, int ms) =>
      r.timers.setTimeout(() => fired.add(name), ms);

  testWidgets(
    'timers that fell due while the app was away fire after the return, in order, a frame at a time',
    (tester) async {
      final s = await openScreen(tester);
      final r = s.runner;
      await s.advance(200);
      final fired = <String>[];
      // A is due in 100 ms; B and C, which have the same due time, in 250 ms (B was made first); D in 600 ms
      timer(r, fired, 'A', 100);
      timer(r, fired, 'B', 250);
      timer(r, fired, 'C', 250);
      timer(r, fired, 'D', 600);
      await s.advance(60);
      expect(fired, isEmpty);
      final held = r.timers.now;

      // the app leaves the foreground (inactive, hidden, paused), and five minutes go by on the clock while frames
      // still come now and then (a window that is only inactive goes on drawing)
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await s.advance(100);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      s.clock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 20));
      await s.advance(200);
      s.clock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 20));
      // nothing fired, and the story's time stands where it stopped
      expect(fired, isEmpty);
      expect(r.timers.now, held);

      // the app is back: no burst on the first frame, no jump of the story's time
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(fired, isEmpty);
      expect(r.timers.now, held);

      // and then the story goes on at the pace of the clock: A has 40 ms to wait (the 60 ms it had before), B and C
      // 190 ms, D 540 ms; each frame fires only what is due by then, in the order of the due times and of creation
      final frames = await framesFor(s, fired, 28);
      expect(frames[0], isEmpty);
      expect(frames[1], ['A']); // 40 ms
      for (var i = 2; i < 9; i++) {
        expect(frames[i], isEmpty, reason: 'frame ${i + 1}');
      }
      expect(frames[9], [
        'B',
        'C',
      ]); // 200 ms: the first frame at or after 190 ms
      for (var i = 10; i < 26; i++) {
        expect(frames[i], isEmpty, reason: 'frame ${i + 1}');
      }
      expect(frames[26], ['D']); // 540 ms
      expect(fired, ['A', 'B', 'C', 'D']);
    },
  );

  testWidgets(
    'without the hold the same five minutes would fire everything on the first frame back (the test is sharp)',
    (tester) async {
      final s = await openScreen(tester);
      final r = s.runner;
      await s.advance(200);
      final fired = <String>[];
      timer(r, fired, 'A', 100);
      timer(r, fired, 'B', 250);
      // the clock moves while the story is not held (the app never said it left): everything that was due fires at once
      s.clock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(milliseconds: 20));
      expect(fired, ['A', 'B']);
    },
  );

  testWidgets(
    'the story holds for every state that is not resumed, and goes on only for resumed',
    (tester) async {
      final s = await openScreen(tester);
      final r = s.runner;
      await s.advance(100);
      final fired = <String>[];
      timer(r, fired, 'A', 100);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
        final at = r.timers.now;
        s.clock.advance(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 20));
        expect(fired, isEmpty, reason: '$state');
        expect(r.timers.now, at, reason: '$state');
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await s.advance(100);
      expect(fired, ['A']);
    },
  );

  testWidgets(
    'a story that is playing: nothing of it happens while the app is away, and it goes on afterwards',
    (tester) async {
      final s = await openScreen(tester);
      await tester.tap(find.byType(NochePlayDisc));
      await s.advance(400);
      final at = s.runner.timers.now;
      final dots = s.runner.view.dotsLit;
      final plays = (s.services.clips as FakeClipPlayer).played.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      s.clock.advance(const Duration(minutes: 3));
      await tester.pump(const Duration(milliseconds: 20));
      await s.advance(100);
      expect(s.runner.timers.now, at);
      expect(s.runner.view.dotsLit, dots);
      expect((s.services.clips as FakeClipPlayer).played.length, plays);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(s.runner.timers.now, at);
      await s.until(() => s.runner.view.dotsLit > dots, what: 'the next dash');
      expect(s.runner.running, isTrue);
    },
  );
}
