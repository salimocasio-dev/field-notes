// A virtual clock for the tests that run a lesson without a screen: the host's `wait` is a timer on it, the clip
// player's clips last a set time on it, and the lesson's Clock is it. Nothing waits for real.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

class _Timer {
  _Timer(this.id, this.at, this.fn);
  final int id;
  final int at;
  final void Function() fn;
}

class VirtualTime implements Clock {
  int now = 0;
  int _seq = 0;
  final List<_Timer> _timers = [];

  @override
  int nowMs() => now;

  /// The host's wait.
  Future<void> wait(Duration d) {
    final c = Completer<void>();
    final ms = d.inMilliseconds;
    _timers.add(_Timer(++_seq, now + (ms < 0 ? 0 : ms), c.complete));
    return c.future;
  }

  /// Runs [fn] at the virtual time [t].
  void at(int t, void Function() fn) {
    _timers.add(_Timer(++_seq, t, fn));
  }

  bool get hasTimers => _timers.isNotEmpty;

  /// Fires the earliest timer (ties: the one made first). False when there is none.
  bool fireNext() {
    if (_timers.isEmpty) return false;
    var best = _timers.first;
    for (final t in _timers) {
      if (t.at < best.at || (t.at == best.at && t.id < best.id)) best = t;
    }
    _timers.remove(best);
    now = best.at;
    best.fn();
    return true;
  }

  /// Fires every timer due up to the virtual time [t] (letting microtasks run after each), then the clock stands at
  /// [t]. For a driver that stops the lesson at an instant.
  Future<void> advanceTo(int t) async {
    while (_timers.isNotEmpty) {
      var best = _timers.first;
      for (final x in _timers) {
        if (x.at < best.at || (x.at == best.at && x.id < best.id)) best = x;
      }
      if (best.at > t) break;
      fireNext();
      await settle();
    }
    if (now < t) now = t;
  }

  /// Advances [ms] of virtual time.
  Future<void> advance(int ms) => advanceTo(now + ms);

  /// Fires timers one at a time until [done] is true (or there are none left): the lesson runs on by itself.
  Future<void> runUntil(bool Function() done, {int limit = 100000}) async {
    await settle();
    for (var i = 0; i < limit && !done() && fireNext(); i++) {
      await settle();
    }
  }

  /// Lets every pending microtask run (a timer comes after all of them).
  Future<void> settle() => Future<void>.delayed(Duration.zero);
}

/// A count of draws in front of a generator.
class CountingRng implements Rng {
  CountingRng(this.inner);
  final Rng inner;
  int draws = 0;
  @override
  double next() {
    draws++;
    return inner.next();
  }
}
