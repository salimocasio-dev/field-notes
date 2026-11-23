import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading_home.dart';
import 'package:feature_library/src/text_reader.dart';
import 'package:material_ui/material_ui.dart';

/// feature_library's module: the Biblioteca tab (a story made for the learner's level, the texts he added, his shelf)
/// and the text reader (`BookRoute`: a text of his shelf, or a course book's lines without its pictures).
class LibraryModule implements FeatureModule {
  const LibraryModule();

  @override
  String get id => 'library';

  @override
  FeatureTab tab(Services s) => FeatureTab(
    id: 'library',
    label: CoquiTabs.library.label,
    icon: Icons.menu_book,
    builder: (_) => ReadingHome(services: s),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => route is BookRoute
      ? TextReader(key: ValueKey('book:${route.id}'), services: s, id: route.id)
      : null;
}
