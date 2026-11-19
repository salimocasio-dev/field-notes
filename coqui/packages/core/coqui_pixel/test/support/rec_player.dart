import 'package:coqui_contracts/coqui_contracts.dart';

/// A [ClipPlayer] that records what reaches it, as `[name, args...]`. Lists, not strings: the web prints 1.0 as 1.
class RecPlayer implements ClipPlayer {
  final calls = <List<Object?>>[];

  @override
  bool muted = false;

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => calls.add(['tone', hz, at, dur, wave, vol, toHz]);

  @override
  void noiseBurst({double vol = 1}) => calls.add(['noise', vol]);

  @override
  void loop(String name, bool on) => calls.add(['loop', name, on]);

  @override
  Future<void> unlock() async {}

  @override
  Future<void> preload(Iterable<String> clipIds) async {}

  @override
  Future<bool> play(String clipId, {Duration? limit}) async => true;

  @override
  Future<void> stop() async {}
}
