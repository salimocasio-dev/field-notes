import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_map's module. A placeholder until order 13 builds the real one: its screen says the feature's name.
class MapModule implements FeatureModule {
  const MapModule();

  @override
  String get id => 'map';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'map',
    label: 'feature_map',
    icon: Icons.map,
    builder: (_) => const _Placeholder(),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_map'));
}
