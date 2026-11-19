import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_profile's module: the Yo tab. It owns the tab `me` and no route. The welcome is not a tab: the
/// shell wraps the app in [WelcomeGate] (exported beside this module).
class ProfileModule implements FeatureModule {
  const ProfileModule();

  @override
  String get id => 'me';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'me',
    label: CoquiLabels.me,
    icon: Icons.person,
    builder: (_) => YoScreen(services: s),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => null;
}
