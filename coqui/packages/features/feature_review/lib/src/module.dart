import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:material_ui/material_ui.dart';

/// feature_review's module: Repaso (¿Cuál?) and the level check. Both are full-screen lessons: no tab.
///
/// `ReviewRoute.practice` is not read: like the old page (cual.js: cualLista), the screen decides by itself,
/// from the store, whether anything is due and so whether this is a practice session.
class ReviewModule implements FeatureModule {
  const ReviewModule();

  @override
  String get id => 'review';

  @override
  FeatureTab? tab(Services s) => null;

  @override
  Widget? screenFor(AppRoute route, Services s) => switch (route) {
    ReviewRoute() => ReviewScreen(services: s),
    LevelCheckRoute() => LevelCheckScreen(services: s),
    _ => null,
  };
}
