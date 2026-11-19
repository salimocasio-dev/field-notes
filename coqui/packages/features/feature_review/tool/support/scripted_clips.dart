// A clip player whose clips last as long as old_harness.mjs says (a function of the id) on a virtual clock, and that
// writes down everything it is asked: what the Dart session did to the sound is compared with what the old page did.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';

import 'virtual_time.dart';

/// tool/diff/old_harness.mjs: clipLength
int clipLength(String id) {
  var s = 0;
  for (final u in id.codeUnits) {
    s += u;
  }
  return 700 + (s % 13) * 110;
}

class _Live {
  _Live(this.id, this.done);
  final String id;
  final Completer<bool> done;
  bool over = false;
}

class ScriptedClips implements ClipPlayer {
  ScriptedClips(this.vt, {this.ready = true});
  final VirtualTime vt;

  /// False: no clip is ready (preload reports them all).
  final bool ready;

  final List<Map<String, Object?>> plays = [];
  final List<Map<String, Object?>> stops = [];
  final List<Map<String, Object?>> tones = [];
  final List<String> preloaded = [];
  final List<_Live> _live = [];

  @override
  bool muted = false;

  @override
  Future<void> unlock() async {}

  @override
  Future<List<String>> preload(Iterable<String> clipIds) async {
    final ids = clipIds.toList();
    preloaded.addAll(ids);
    return ready ? <String>[] : <String>{...ids}.toList();
  }

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    plays.add({'t': vt.now, 'id': clipId});
    final live = _Live(clipId, Completer<bool>());
    _live.add(live);
    vt.wait(Duration(milliseconds: clipLength(clipId))).then((_) {
      if (live.over) return;
      live.over = true;
      _live.remove(live);
      live.done.complete(true);
    });
    return live.done.future;
  }

  @override
  Future<void> stop() async {
    for (final l in [..._live]) {
      l.over = true;
      _live.remove(l);
      stops.add({'t': vt.now, 'id': l.id});
      l.done.complete(false);
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
  }) => tones.add({
    't': vt.now,
    'hz': hz,
    'at': at,
    'dur': dur,
    'wave': wave,
    'vol': vol,
    'toHz': toHz,
  });

  @override
  void noiseBurst({double vol = 1}) {}

  @override
  void loop(String name, bool on) {}
}
