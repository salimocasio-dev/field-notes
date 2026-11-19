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
