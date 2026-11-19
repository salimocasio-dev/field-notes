/// The story's timers: what `setTimeout` and `setInterval` are in juego.js, on a clock the host moves.
///
/// Nothing here reads a real clock or sleeps. Time is [now], in whole milliseconds, and it moves only when a host
/// moves it: the play screen on every tick ([advanceTo], driven by a `Clock`), the no-screen player from one due
/// timer to the next ([fire]), as `coqui/tool/ref/trazas/page-init.js` does for the old page. The rules are that file's:
/// - a delay is converted as the browser converts it (WebIDL `long`: a fraction is cut, a negative is 0);
/// - timers fire in order of due time, then of creation;
/// - an interval is re-armed at due + interval when it fires, and counts as created then;
/// - an interval of 0 ms is refused.
library;

import 'dart:math' as math;

/// One timer. [at] is its due time (ms); [seq] its creation order.
class StoryTimer {
  StoryTimer._(this.id, this.at, this.seq, this.fn, this.repeat);

  final int id;
  int at;
  int seq;
  final void Function() fn;

  /// 0 for a timeout; the interval for an interval.
  final int repeat;
}

/// Thrown by a delay of 0 ms on an interval, which the virtual clock does not support (the old page uses none).
class TimerError extends StateError {
  TimerError(super.message);
}

// JavaScript: `(Number(delay) || 0) | 0`, then negative is 0
int _delay(num ms) {
  if (ms.isNaN || ms.isInfinite) return 0;
  final t = ms.truncate();
  // `| 0` wraps to 32 bits
  final w = ((t + 0x80000000) & 0xFFFFFFFF) - 0x80000000;
  return math.max(0, w);
}

class StoryTimers {
  /// The time, in ms. juego.js's `performance.now()`. A host moves it ([advanceTo], [fire]); the no-screen player also
  /// sets it, for a touch at a set time.
  int now = 0;
  int _seq = 0;
  int _nextId = 1;
  final Map<int, StoryTimer> _timers = {};

  /// How many timers are waiting.
  int get count => _timers.length;

  /// juego.js: `setTimeout(fn, ms)`. Returns the id for [clear].
  int setTimeout(void Function() fn, num ms) => _add(fn, ms, false);

  /// juego.js: `setInterval(fn, ms)`.
  int setInterval(void Function() fn, num ms) => _add(fn, ms, true);

  /// juego.js: `clearTimeout(id)` and `clearInterval(id)`. A null or unknown id does nothing.
  void clear(int? id) {
    if (id != null) _timers.remove(id);
  }

  int _add(void Function() fn, num ms, bool repeat) {
    final d = _delay(ms);
    if (repeat && d == 0) {
      throw TimerError(
        'setInterval with 0 ms (not supported by the virtual clock)',
      );
    }
    final id = _nextId++;
    _timers[id] = StoryTimer._(id, now + d, ++_seq, fn, repeat ? d : 0);
    return id;
  }

  /// The next timer to fire: the earliest due, then the first created. Null when none waits.
  StoryTimer? next() {
    StoryTimer? b;
    for (final t in _timers.values) {
      if (b == null || t.at < b.at || (t.at == b.at && t.seq < b.seq)) b = t;
    }
    return b;
  }

  /// Fires [t] now: the time becomes its due time, an interval is re-armed, then its function runs.
  void fire(StoryTimer t) {
    now = t.at;
    if (t.repeat != 0) {
      t.at += t.repeat;
      t.seq = ++_seq;
    } else {
      _timers.remove(t.id);
    }
    t.fn();
  }

  /// The live host's tick: fires every timer due at or before [t], in order, then the time is [t].
  /// A timer that fires may add timers due within the window: they fire too.
  void advanceTo(int t) {
    for (;;) {
      final n = next();
      if (n == null || n.at > t) break;
      fire(n);
    }
    if (t > now) now = t;
  }
}
