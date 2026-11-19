import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_story's module. A placeholder until order 15 builds the real one: its screen says the feature's name.
class StoryModule implements FeatureModule {
  const StoryModule();

  @override
  String get id => 'story';

  @override
  FeatureTab? tab(Services s) => null;

  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is StoryRoute ? const _Placeholder() : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_story'));
}
