import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_speaking's module. A placeholder until order 24 builds the real one: its screen says the feature's name.
class SpeakingModule implements FeatureModule {
  const SpeakingModule();

  @override
  String get id => 'speak';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'speak',
    label: 'feature_speaking',
    icon: Icons.mic,
    builder: (_) => const _Placeholder(),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is CallRoute || route is VoiceTestRoute
      ? const _Placeholder()
      : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_speaking'));
}
