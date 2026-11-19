/// The app's addresses: every screen has a stable one, after the `#` (GitHub Pages has no fallback for path
/// addresses, so the app uses hash addresses).
///
/// | Screen                         | Address                     | Route                          |
/// | ------------------------------ | --------------------------- | ------------------------------ |
/// | a tab                          | `#/tab/<id>`                | `TabRoute(id)`                 |
/// | a story                        | `#/cuento/<id>`             | `StoryRoute(id)`               |
/// | a story told straight through  | `#/cuento/<id>?oir=1`       | `StoryRoute(id, listen: true)` |
/// | Repaso                         | `#/repaso`                  | `ReviewRoute()`                |
/// | Repaso, practice               | `#/repaso?practica=1`       | `ReviewRoute(practice: true)`  |
/// | the level check                | `#/nivel`                   | `LevelCheckRoute()`            |
/// | a book                         | `#/libro/<id>`              | `BookRoute(id)`                |
/// | the call for a place           | `#/llamada/<placeId>`       | `CallRoute(placeId)`           |
/// | the voice test                 | `#/prueba-voz`              | `VoiceTestRoute()`             |
///
/// Tab ids are `library`, `words`, `map`, `speak`, `me`. Story, book and place ids are the course's (lower-case
/// letters, digits and hyphens). Anything else is not an address of the app.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show CoquiTabs;

/// The five tab ids, in the tab bar's order.
final List<String> tabIds = [for (final t in CoquiTabs.all) t.id];

/// The tab the app starts on, and where an unknown address goes.
const String startTab = CoquiTabs.mapId;

final RegExp _id = RegExp(r'^[a-z0-9][a-z0-9-]*$');

/// The address of [route] (the part after `#`).
String addressOf(AppRoute route) => switch (route) {
  TabRoute(:final tab) => '/tab/$tab',
  StoryRoute(:final id, :final listen) =>
    '/cuento/$id${listen ? '?oir=1' : ''}',
  ReviewRoute(:final practice) => '/repaso${practice ? '?practica=1' : ''}',
  LevelCheckRoute() => '/nivel',
  BookRoute(:final id) => '/libro/$id',
  CallRoute(:final placeId) => '/llamada/$placeId',
  VoiceTestRoute() => '/prueba-voz',
};

/// The route an address names, or null when it names none.
AppRoute? routeOf(Uri address) {
  final s = address.pathSegments.where((p) => p.isNotEmpty).toList();
  final q = address.queryParameters;
  if (s.length == 2) {
    final id = s[1];
    switch (s[0]) {
      case 'tab':
        return tabIds.contains(id) ? TabRoute(id) : null;
      case 'cuento':
        return _id.hasMatch(id)
            ? StoryRoute(id, listen: q['oir'] == '1')
            : null;
      case 'libro':
        return _id.hasMatch(id) ? BookRoute(id) : null;
      case 'llamada':
        return _id.hasMatch(id) ? CallRoute(id) : null;
    }
    return null;
  }
  if (s.length == 1) {
    switch (s[0]) {
      case 'repaso':
        return ReviewRoute(practice: q['practica'] == '1');
      case 'nivel':
        return const LevelCheckRoute();
      case 'prueba-voz':
        return const VoiceTestRoute();
    }
  }
  return null;
}
