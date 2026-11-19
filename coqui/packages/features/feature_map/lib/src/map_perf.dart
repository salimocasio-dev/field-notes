import 'package:material_ui/material_ui.dart';

/// What the map measured of itself, for a dev entry to show (the real limits, 500 ms for the bake and 8 ms for
/// a frame, are read on a phone). The screen records it; nothing in the app reads it.
class MapPerf extends ChangeNotifier {
  /// How long `bake` took, in ms (0 until it has run).
  double bakeMs = 0;

  /// The slowest frame so far: `updateFrog` and `draw`, in ms. The picture's upload to the screen is not in it.
  double slowestFrameMs = 0;

  /// The mean frame so far, in ms.
  double get meanFrameMs => frames == 0 ? 0 : _total / frames;

  /// How many frames were timed.
  int frames = 0;

  double _total = 0;

  /// Records the bake.
  void recordBake(double ms) {
    bakeMs = ms;
    notifyListeners();
  }

  /// Records a frame. Listeners hear of a new slowest frame at once and of the rest every 30 frames.
  void recordFrame(double ms) {
    frames++;
    _total += ms;
    final slower = ms > slowestFrameMs;
    if (slower) slowestFrameMs = ms;
    if (slower || frames % 30 == 0) notifyListeners();
  }
}
