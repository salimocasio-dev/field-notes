import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/src/fake_platform.dart';

/// One call of [ClipPlayer.tone], as it was made.
typedef FakeTone = ({
  double hz,
  double at,
  double dur,
  String wave,
  double vol,
  double? toHz,
});

/// A clip player that records every call and plays instantly.
///
/// What it does: [play] returns at once. With [lengthOf] it plays a clip of known length to its end
/// (true) and moves [clock] on by that length, or by [play]'s `limit` when that is shorter (false: cut
/// off); a clip [lengthOf] does not know does not play (false, as juego.js's playClip without the clip).
/// Without [lengthOf] every clip plays to its end and no time passes. Tones, noise bursts and loops are
/// only recorded. [preload] records its ids and gives back the ones that are not ready: those in [failing]
/// and, when [lengthOf] is given, those it does not know (no clip, as no ClipInfo); every other clip is
/// ready. The fake keeps no list of what was loaded: a clip stays reported while it is in [failing] or
/// unknown, and is reported no more when it is taken out.
///
/// What it does not do: no sound, no decoding, no gaps between lines; [muted] changes nothing it returns.
class FakeClipPlayer implements ClipPlayer {
  FakeClipPlayer({this.clock, this.lengthOf});

  /// Moved on by each clip's length, when given.
  final FakeClock? clock;

  /// A clip's length in ms, or null when there is no such clip.
  final int? Function(String clipId)? lengthOf;

  /// Every clip [play] was asked for, in order.
  final List<String> played = [];

  /// Every clip [preload] was given, in order (duplicates and all, as it was asked).
  final List<String> preloaded = [];

  /// The clips [preload] reports as not ready (a failed fetch or decode), empty to start with. Change it
  /// between calls: a retry gives what the set holds then.
  Set<String> failing = {};

  /// Every tone, in order.
  final List<FakeTone> tones = [];

  /// The volume of every noise burst, in order.
  final List<double> noises = [];

  /// Every loop call, in order, as [name, on].
  final List<(String, bool)> loops = [];

  /// Which loops are on now.
  final Set<String> looping = {};

  bool unlocked = false;
  int stops = 0;

  @override
  bool muted = false;

  @override
  Future<void> unlock() async => unlocked = true;

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    final ids = clipIds.toList();
    preloaded.addAll(ids);
    final f = lengthOf;
    return [
      for (final id in {...ids})
        if (failing.contains(id) || (f != null && f(id) == null)) id,
    ];
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) async {
    played.add(clipId);
    final f = lengthOf;
    if (f == null) return true;
    final len = f(clipId);
    if (len == null) return false;
    final cap = limit?.inMilliseconds;
    final cut = cap != null && cap < len;
    clock?.advance(Duration(milliseconds: cut ? cap : len));
    return !cut;
  }

  @override
  void tone(
    double hz, {
    double at = 0,
    double dur = .1,
    String wave = 'square',
    double vol = .05,
    double? toHz,
  }) => tones.add((hz: hz, at: at, dur: dur, wave: wave, vol: vol, toHz: toHz));

  @override
  void noiseBurst({double vol = 1}) => noises.add(vol);

  @override
  void loop(String name, bool on) {
    loops.add((name, on));
    on ? looping.add(name) : looping.remove(name);
  }

  @override
  Future<void> stop() async => stops++;
}
