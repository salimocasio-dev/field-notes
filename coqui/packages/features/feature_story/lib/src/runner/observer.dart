/// What a no-screen player watches in a run. The runner calls these at the places where the old page's recording tool
/// (`coqui/tool/ref/trazas/page-drive.js`) wrapped juego.js's functions. They record and change nothing.
library;

import 'package:feature_story/src/runner/pending.dart';

/// The default watches nothing and runs everything straight.
class StoryObserver {
  const StoryObserver();

  /// `paso(st)` was called. [kind] is the key that chooses the step's branch (`line`, `say`, `wait`, `cam`, `dots`,
  /// `set`, `if`, `act`, `ask`, `decide`, `elige`, `draw`, `reparte`, `calc`, `recuerda`, `cost`), [id] a line's clip
  /// after `$` filling, [act] an act's name. [run] runs the step; the observer returns its future.
  Future<void> step(
    Object? st,
    String kind,
    String? id,
    String? act,
    Future<void> Function() run,
  ) => run();

  /// `pasos(list)` is about to run `list[i]`.
  void pasosItem(List<Object?> list, int i) {}

  /// `espera` was called: [start] runs it (it runs up to its first await at once), [current] reads `pending` after.
  Future<Pending> espera(
    Future<Pending> Function() start,
    Pending? Function() current,
    String? line,
  ) => start();

  /// A clip was asked for: by `say` ([via] "say") or directly by `playClip` ([via] "clip"). [who] is the clip's `who`,
  /// [talker] who speaks it on screen (`partes().quien`), [noVoice] true when there is no recording for it.
  void clip(String id, String via, String? who, String? talker, bool noVoice) {}

  /// A scene called `tone` itself (not through an SFX): its arguments as given.
  void tone(List<Object?> args) {}
}
