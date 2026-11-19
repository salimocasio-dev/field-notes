import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_profile's module. A placeholder until order 25 builds the real one: its screen says the feature's name.
class ProfileModule implements FeatureModule {
  const ProfileModule();

  @override
  String get id => 'me';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'me',
    label: 'feature_profile',
    icon: Icons.person,
    builder: (_) => const _Placeholder(),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_profile'));
}
