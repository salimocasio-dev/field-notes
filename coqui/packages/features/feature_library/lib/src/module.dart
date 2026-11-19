import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// feature_library's module. A placeholder until order 22 builds the real one: its screen says the feature's name.
class LibraryModule implements FeatureModule {
  const LibraryModule();

  @override
  String get id => 'library';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'library',
    label: 'feature_library',
    icon: Icons.menu_book,
    builder: (_) => const _Placeholder(),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is BookRoute ? const _Placeholder() : null;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('feature_library'));
}
