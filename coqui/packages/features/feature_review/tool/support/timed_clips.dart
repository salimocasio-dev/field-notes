// A clip player for the dev entry on the fakes: a clip lasts a set time, on real timers, so that a person can hear
// (see) the sentence play and end. No sound.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

class TimedClips implements ClipPlayer {
  TimedClips({this.lengthOf = _same});

  /// How long a clip "plays" (ms).
  final int Function(String id) lengthOf;
  static int _same(String id) => 1200;

  final List<Completer<bool>> _live = [];
  final List<Timer> _timers = [];

  @override
  bool muted = false;

  @override
  Future<void> unlock() async {}

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async => const [];

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    final c = Completer<bool>();
    _live.add(c);
    late final Timer t;
    t = Timer(Duration(milliseconds: lengthOf(clipId)), () {
      _timers.remove(t);
      if (_live.remove(c)) c.complete(true);
    });
    _timers.add(t);
    return c.future;
  }

  @override
  Future<void> stop() async {
    for (final c in [..._live]) {
      _live.remove(c);
      c.complete(false);
    }
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) {}

  @override
  void noiseBurst({double vol = 1}) {}

  @override
  void loop(String name, bool on) {}
}
