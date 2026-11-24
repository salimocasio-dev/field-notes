import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// What the map measured of itself, for a dev entry or the app's `?perf=1` to show (the real limits, 500 ms for the
/// bake and 8 ms for a frame, are read on a phone). The screen records it; [MapPerfChip] shows it.
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

/// The corner chip that shows [perf]: the bake, the slowest frame and the mean frame, in ms. Shown by the dev entry, and by
/// the app when `MapModule(showPerf: true)` (its `?perf=1`).
class MapPerfChip extends StatelessWidget {
  const MapPerfChip(this.perf, {super.key});

  final MapPerf perf;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: perf,
    builder: (context, _) => DecoratedBox(
      key: const Key('map-perf-chip'),
      decoration: BoxDecoration(
        color: NocheColors.panel,
        border: Border.all(color: NocheColors.line, width: 1),
        borderRadius: BorderRadius.circular(NocheSize.grid),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: NocheSize.grid,
          vertical: 4,
        ),
        child: Text(
          'bake ${perf.bakeMs.toStringAsFixed(0)} ms · frame max ${perf.slowestFrameMs.toStringAsFixed(1)} ms · mean ${perf.meanFrameMs.toStringAsFixed(1)} ms',
          style: NocheType.bodySmall.copyWith(color: NocheColors.text),
        ),
      ),
    ),
  );
}
