import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/images.dart';
import 'package:feature_library/src/reader.dart';
import 'package:feature_library/src/shelf.dart';
import 'package:material_ui/material_ui.dart';

/// feature_library's module: the Biblioteca tab (the shelf of stories, each with Listen and Read) and the
/// book reader (`BookRoute`).
///
/// A book page's picture is a file served by the old site. Nothing in `Services` says where from, so
/// [imageUrl] turns the page's `img` into an address (default: the old site's relative path with its `?v=39`);
/// the shell passes the real one. [imageProvider] loads that address (default: over the network; the dev entry
/// and the tests, which have none, give their own).
class LibraryModule implements FeatureModule {
  const LibraryModule({
    this.imageUrl = defaultBookImageUrl,
    this.imageProvider = networkBookImage,
  });

  final BookImageUrl imageUrl;
  final BookImageProvider imageProvider;

  @override
  String get id => 'library';

  @override
  FeatureTab? tab(Services s) => FeatureTab(
    id: 'library',
    label: CoquiTabs.library.label,
    icon: Icons.menu_book,
    builder: (_) => LibraryShelf(
      services: s,
      imageUrl: imageUrl,
      imageProvider: imageProvider,
    ),
  );

  @override
  Widget? screenFor(AppRoute route, Services s) => route is BookRoute
      ? BookReader(
          key: ValueKey('book:${route.id}'),
          services: s,
          bookId: route.id,
          imageUrl: imageUrl,
          imageProvider: imageProvider,
        )
      : null;
}
