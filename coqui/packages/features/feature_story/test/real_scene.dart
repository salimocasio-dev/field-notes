// The real scenes, as the differential test makes them: made by coqui_scenes from their sheets (order 14: El frente).
import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// The real scene [id], a new one, its sheet read from the package's assets first. Needs the Flutter test binding.
Future<SetScene> realScene(String id) async => await loadScene(id) as SetScene;

/// The real scene [id] as the story screen makes it (`registryScenes`): made by the registry's factory, given the run's one
/// random source when the runner asks for it, a new scene each time. Its sheet is read first. Needs the Flutter test binding.
Future<SetScene Function(Rng rng)> realSceneFor(String id) async {
  await loadSheet(id);
  return (rng) => sceneRegistry[id]!(rng: rng) as SetScene;
}

/// Where the frog starts in [scene] (juego.js line 16: the sheet's `code` entry for it).
({int x, int y, num scale}) startFrogOf(Scene scene) {
  final s = scene as SetScene;
  return frogOfCode(s.sheet, s.projection, 'juego.js:16');
}

/// Whether the frog keeps the old flat shadow under him in [scene].
bool frogShadowOf(Scene scene) => (scene as SetScene).frogShadow;
