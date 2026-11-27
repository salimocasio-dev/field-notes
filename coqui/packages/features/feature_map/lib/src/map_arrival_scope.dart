/// Inherited arrival and course-turn scope for `MapScreen`.
///
/// Lets the app shell fade map overlays independently of `PixelView` during a
/// course language turn and trigger cold-load arrival stagger on first bake.
library;

import 'package:material_ui/material_ui.dart';

/// Controls overlay opacity during course turns and cold-load arrival stagger
/// inside `MapScreen`.
class MapArrivalScope extends InheritedWidget {
  const MapArrivalScope({
    super.key,
    this.overlayOpacity = 1.0,
    this.animateColdLoad = false,
    required super.child,
  });

  /// Opacity multiplier (`0.0` to `1.0`) applied to map overlays (top chips,
  /// map pills, and bottom card) while keeping the pixel island unfaded.
  final double overlayOpacity;

  /// Whether `MapScreen` should stagger its overlays on first bake.
  final bool animateColdLoad;

  /// Returns the nearest [MapArrivalScope], or `null` if none is present.
  static MapArrivalScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MapArrivalScope>();

  @override
  bool updateShouldNotify(MapArrivalScope oldWidget) =>
      overlayOpacity != oldWidget.overlayOpacity ||
      animateColdLoad != oldWidget.animateColdLoad;
}
