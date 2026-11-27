import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:feature_map/src/place_screen.dart';
import 'package:feature_map/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// feature_map's module: the home map, the Up next card, and the place screen.
/// It owns the `map` tab and answers [PlaceRoute].
///
/// [showPerf]: the map shows its bake time and frame times in a small corner chip (the app's `?perf=1`). Off by default.
/// [entitlements]: explicit plan entitlements forwarded to [MapScreen] and [PlaceScreen].
class MapModule implements FeatureModule {
  const MapModule({this.showPerf = false, required this.entitlements});

  final bool showPerf;
  final Entitlements entitlements;

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
