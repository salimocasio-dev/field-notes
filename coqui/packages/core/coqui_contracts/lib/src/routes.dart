/// Where the app can go. The shell maps each route to the module that answers it.
///
/// Routes compare by value, so a recorded route can be checked in a test.
sealed class AppRoute {
  const AppRoute();
}

/// A story, played, or told straight through (`listen`, juego.js ?oir=1).
final class StoryRoute extends AppRoute {
  const StoryRoute(this.id, {this.listen = false});
  final String id;
  final bool listen;

  @override
  bool operator ==(Object other) =>
      other is StoryRoute && other.id == id && other.listen == listen;
  @override
  int get hashCode => Object.hash(StoryRoute, id, listen);
  @override
  String toString() => 'StoryRoute($id, listen: $listen)';
}

/// Repaso (¿Cuál?). `practice`: nothing is due, a practice session.
final class ReviewRoute extends AppRoute {
  const ReviewRoute({this.practice = false});
  final bool practice;

  @override
  bool operator ==(Object other) =>
      other is ReviewRoute && other.practice == practice;
  @override
  int get hashCode => Object.hash(ReviewRoute, practice);
  @override
  String toString() => 'ReviewRoute(practice: $practice)';
}

/// The level check.
final class LevelCheckRoute extends AppRoute {
  const LevelCheckRoute();

  @override
  bool operator ==(Object other) => other is LevelCheckRoute;
  @override
  int get hashCode => (LevelCheckRoute).hashCode;
  @override
  String toString() => 'LevelCheckRoute()';
}

/// A book in the reader.
final class BookRoute extends AppRoute {
  const BookRoute(this.id);
  final String id;

  @override
  bool operator ==(Object other) => other is BookRoute && other.id == id;
  @override
  int get hashCode => Object.hash(BookRoute, id);
  @override
  String toString() => 'BookRoute($id)';
}

/// The call with Danny for one place.
final class CallRoute extends AppRoute {
  const CallRoute(this.placeId);
  final String placeId;

  @override
  bool operator ==(Object other) =>
      other is CallRoute && other.placeId == placeId;
  @override
  int get hashCode => Object.hash(CallRoute, placeId);
  @override
  String toString() => 'CallRoute($placeId)';
}

/// The voice test (habla-prueba.html).
final class VoiceTestRoute extends AppRoute {
  const VoiceTestRoute();

  @override
  bool operator ==(Object other) => other is VoiceTestRoute;
  @override
  int get hashCode => (VoiceTestRoute).hashCode;
  @override
  String toString() => 'VoiceTestRoute()';
}

/// A tab: library, words, map, speak, me.
final class TabRoute extends AppRoute {
  const TabRoute(this.tab);
  final String tab;

  @override
  bool operator ==(Object other) => other is TabRoute && other.tab == tab;
  @override
  int get hashCode => Object.hash(TabRoute, tab);
  @override
  String toString() => 'TabRoute($tab)';
}

/// The language picker sheet.
final class LanguagesRoute extends AppRoute {
  const LanguagesRoute();

  @override
  bool operator ==(Object other) => other is LanguagesRoute;
  @override
  int get hashCode => (LanguagesRoute).hashCode;
  @override
  String toString() => 'LanguagesRoute()';
}

/// The subscription plans screen.
final class PlansRoute extends AppRoute {
  const PlansRoute();

  @override
  bool operator ==(Object other) => other is PlansRoute;
  @override
  int get hashCode => (PlansRoute).hashCode;
  @override
  String toString() => 'PlansRoute()';
}

/// Adding the learner's own books and texts to the Library.
final class ImportRoute extends AppRoute {
  const ImportRoute();

  @override
  bool operator ==(Object other) => other is ImportRoute;
  @override
  int get hashCode => (ImportRoute).hashCode;
  @override
  String toString() => 'ImportRoute()';
}

/// One place's screen on the map.
final class PlaceRoute extends AppRoute {
  const PlaceRoute(this.placeId);
  final String placeId;

  @override
  bool operator ==(Object other) =>
      other is PlaceRoute && other.placeId == placeId;
  @override
  int get hashCode => Object.hash(PlaceRoute, placeId);
  @override
  String toString() => 'PlaceRoute($placeId)';
}

/// Moves between screens. Only the shell implements it.
abstract interface class AppNavigator {
  void go(AppRoute route);
  void back();
}
