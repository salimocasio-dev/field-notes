import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_map/src/map_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_map's module: the home map, the Today card and the place sheet. It owns the tab `map` and no route.
class MapModule implements FeatureModule {
  const MapModule();

  @override
  String get id => 'map';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'map',
    label: CoquiTabs.map.label,
    icon: Icons.map,
    builder: (_) =>
        MapScreen(services: s, reviewTitle: CoquiLabels.reviewTitle),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => null;
}
