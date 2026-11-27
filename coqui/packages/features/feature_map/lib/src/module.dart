import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:feature_map/src/place_screen.dart';
import 'package:feature_map/src/wording.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

/// feature_map's module: the home map, the Up next card, and the place screen.
/// It owns the `map` tab and answers [PlaceRoute].
///
/// [showPerf]: the map shows its bake time and frame times in a small corner chip (the app's `?perf=1`). Off by default.
/// [entitlements]: explicit plan entitlements forwarded to [MapScreen] and [PlaceScreen].
/// [overlayOpacity]: optional listenable (`0.0` to `1.0`) driven by the shell during a course language turn so map overlays fade while `PixelView` stays unfaded.
/// [animateColdLoad]: whether [MapScreen] staggers its internal overlays on initial bake.
class MapModule implements FeatureModule {
  const MapModule({
    this.showPerf = false,
    required this.entitlements,
    this.overlayOpacity,
    this.animateColdLoad = false,
  });

  final bool showPerf;
  final Entitlements entitlements;
  final ValueListenable<double>? overlayOpacity;
  final bool animateColdLoad;

  @override
  String get id => 'map';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'map',
    label: s.course.language.tabNames['map'] ?? CoquiTabs.map.label,
    icon: Icons.map,
    builder: (_) => MapScreen(
      services: s,
      reviewTitle: MapWording.reviewTitle,
      showPerf: showPerf,
      entitlements: entitlements,
      overlayOpacity: overlayOpacity,
      animateColdLoad: animateColdLoad,
    ),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) {
    if (route case PlaceRoute(:final placeId)) {
      if (s.course.places.isNotEmpty &&
          !s.course.places.any((p) => p.id == placeId)) {
        return null;
      }
      return PlaceScreen(
        key: ValueKey(route),
        placeId: placeId,
        services: s,
        entitlements: entitlements,
      );
    }
    return null;
  }
}
