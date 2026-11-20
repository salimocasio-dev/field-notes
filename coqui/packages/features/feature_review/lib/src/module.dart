import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/ui/book_image.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_review's module: Repaso and the level check. Both are full-screen lessons: no tab.
///
/// Repaso is the games of page 15 (docs/proyecto/15-repaso-juegos.md) when the course has read
/// `datos/repaso.json` (a catalog that is a `RepasoCatalog` with its data); without that file, or with one it
/// could not read, it is today's ¿Cuál? (cual.js).
///
/// `ReviewRoute.practice` is not read: like the old page (cual.js: cualLista), the screen decides by itself,
/// from the store, whether anything is due and so whether this is a practice session.
///
/// A book page's picture (¿Dónde?, and the moment a sentence was first heard) is a file of the site. Nothing in
/// `Services` says where from, so [imageUrl] turns its `img` (`img/<file>`) into an address (default: the old
/// site's relative path with its `?v=39`) and [imageProvider] loads it (default: over the network), as
/// `LibraryModule` has them.
class ReviewModule implements FeatureModule {
  const ReviewModule({
    this.imageUrl = defaultBookImageUrl,
    this.imageProvider = networkBookImage,
  });

  final String Function(String path) imageUrl;
  final ImageProvider Function(String url) imageProvider;

  @override
  String get id => 'review';

  @override
  FeatureTab? tab(Services s) => null;

  @override
  Widget? screenFor(AppRoute route, Services s) => switch (route) {
    ReviewRoute() => switch (_repaso(s.course)) {
      final RepasoData data => RepasoScreen(
        services: s,
        data: data,
        imageUrl: imageUrl,
        imageProvider: imageProvider,
      ),
      null => ReviewScreen(services: s),
    },
    LevelCheckRoute() => LevelCheckScreen(services: s),
    _ => null,
  };

  // the games' data of a course, when it has read it
  static RepasoData? _repaso(CourseCatalog c) =>
      c is RepasoCatalog ? (c as RepasoCatalog).repaso : null;
}
