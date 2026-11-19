/// The widgets' `wait`: a timer the lesson can cancel when its screen goes away (page 12, section 6: the logic never
/// makes a timer of its own, the host does).
library;

import 'dart:async';

class HostWait {
  final Set<Timer> _timers = {};
  bool _cancelled = false;

  Future<void> call(Duration d) {
    final c = Completer<void>();
    if (_cancelled) return c.future;
    late final Timer t;
    t = Timer(d, () {
      _timers.remove(t);
      c.complete();
    });
    _timers.add(t);
    return c.future;
  }

  /// Every wait still going stops (and its future never completes): the lesson is over.
  void cancelAll() {
    _cancelled = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }
}
