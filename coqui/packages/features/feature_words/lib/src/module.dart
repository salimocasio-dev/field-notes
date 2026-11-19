import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_words's module. A placeholder until order 21 builds the real one: its screen says the feature's name.
class WordsModule implements FeatureModule {
  const WordsModule();

  @override
  String get id => 'words';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'words',
    label: 'feature_words',
    icon: Icons.style,
    builder: (_) => const _Placeholder(),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_words'));
}
