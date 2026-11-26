import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_profile/src/languages_sheet.dart';
import 'package:feature_profile/src/plans_screen.dart';
import 'package:feature_profile/src/yo_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_profile's module: the Yo tab, the "Your languages" sheet
/// ([LanguagesRoute]), and the Plans screen ([PlansRoute]). The welcome is not
/// a tab: the shell wraps the app in [WelcomeGate] (exported beside this
/// module).
class ProfileModule implements FeatureModule {
  const ProfileModule();

  @override
  String get id => 'me';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: NocheTabs.me,
    label: s.course.language.tabNames[NocheTabs.me] ?? CoquiLabels.me,
    icon: Icons.person,
    builder: (_) => YoScreen(services: s),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => switch (route) {
    LanguagesRoute() => LanguagesSheet(services: s),
    PlansRoute() => PlansScreen(services: s),
    _ => null,
  };
}
