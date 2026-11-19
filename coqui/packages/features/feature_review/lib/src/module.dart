import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_review's module. A placeholder until order 23 builds the real one: its screen says the feature's name.
class ReviewModule implements FeatureModule {
  const ReviewModule();

  @override
  String get id => 'review';

  @override
  FeatureTab? tab(Services s) => null;

  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is ReviewRoute || route is LevelCheckRoute
      ? const _Placeholder()
      : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_review'));
}
