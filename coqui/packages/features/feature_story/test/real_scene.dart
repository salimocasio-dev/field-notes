// The real scenes, as the differential test makes them: made by coqui_scenes from their sheets (order 14: El frente).
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// The real scene [id], a new one, its sheet read from the package's assets first. Needs the Flutter test binding.
Future<SetScene> realScene(String id) async => await loadScene(id) as SetScene;

/// Where the frog starts in [scene] (juego.js line 16: the sheet's `code` entry for it).
({int x, int y, num scale}) startFrogOf(Scene scene) {
  final s = scene as SetScene;
  return frogOfCode(s.sheet, s.projection, 'juego.js:16');
}

/// Whether the frog keeps the old flat shadow under him in [scene].
bool frogShadowOf(Scene scene) => (scene as SetScene).frogShadow;
