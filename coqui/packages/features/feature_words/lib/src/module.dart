import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/words_tab.dart';
import 'package:material_ui/material_ui.dart';

/// feature_words's module: the Words tab (id `words`).
class WordsModule implements FeatureModule {
  const WordsModule();

  @override
  String get id => 'words';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'words',
    label: s.course.language.tabNames['words']!,
    icon: Icons.style,
    builder: (_) => WordsTab(services: s),
  );

  /// Nothing but its own tab.
  @override
  Widget? screenFor(AppRoute route, Services s) =>
      route is TabRoute && route.tab == 'words' ? WordsTab(services: s) : null;
}
