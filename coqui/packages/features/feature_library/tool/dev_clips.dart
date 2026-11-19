// A clip player for the dev entry: each clip takes its own length (or a part of it), and one play can be held.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

/// Plays each clip for its length divided by [speed] (real time), and records what it was asked.
/// [hold] hangs the n-th play since the last [stop] (1 is the first line of a page) until the next [stop]: the line stays lit,
/// as in a picture of the old page taken while a line plays.
class DevClips implements ClipPlayer {
  DevClips({required this.lengthOf, this.speed = 1, this.hold});

  final int? Function(String id) lengthOf;
  final double speed;
  final int? hold;

  final List<String> played = [];
  final List<Completer<bool>> _pending = [];
  int _plays = 0;

  @override
  bool muted = false;

  @override
  Future<void> unlock() async {}

  @override
  Future<void> preload(Iterable<String> clipIds) async {}

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    _plays++;
    final done = Completer<bool>();
    _pending.add(done);
    if (hold != null && _plays == hold) return done.future;
    final ms = ((lengthOf(clipId) ?? 0) / speed).round();
    Timer(Duration(milliseconds: ms), () {
      if (!done.isCompleted) done.complete(true);
      _pending.remove(done);
    });
    return done.future;
  }

  @override
  Future<void> stop() async {
    _plays = 0;
    for (final c in _pending) {
      if (!c.isCompleted) c.complete(false);
    }
    _pending.clear();
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
