/// What the story needs of a scene besides its [Scene] members, to draw its frame (page 12, section 5, "The frame, every
/// tick"): the engine the set is baked on, the shadows the characters cast, where the frog starts and whether he keeps the old
/// flat shadow. A converted scene of coqui_scenes (a `SetScene`) gives all of them; a scene of our own (a test's, the dev
/// entry's) gives them by hand.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/coqui_scenes.dart';

/// How the frame is made for one scene.
class SceneFrameSetup {
  const SceneFrameSetup({required this.engine, required this.shadows});

  /// The engine the set is baked on: `PpEngine(w: 240, h: 216, s: 26, originX:, originY:, ...)` with the sheet's origin;
  /// [still] is the OS asking for reduced motion.
  final PpEngine Function({required bool still}) engine;

  /// The shadow each character casts in this world: one entry for each `castShadow` call of the frame.
  final List<ShadowCast> Function(Map<String, dynamic> W) shadows;
}

/// A scene and how to draw its frame.
class StoryScene {
  const StoryScene({
    required this.scene,
    required this.frame,
    this.startFrog,
    this.frogShadow = true,
  });

  final Scene scene;
  final SceneFrameSetup frame;

  /// Where the game puts the frog when a play starts (juego.js, `fresh`), from the scene's sheet. Null: the old numbers.
  final ({int x, int y, num scale}) Function()? startFrog;

  /// Whether the frog keeps the old flat shadow: not when the scene casts his shadow in the engine.
  final bool frogShadow;
}

/// Makes the scene a story file names (`story['scene']`), given the one random source of the app. It may read the scene's
/// sheet first, so it is asynchronous. Throws when there is no such scene, or it is not converted yet.
typedef SceneFactory = Future<StoryScene> Function(String sceneId, Rng rng);

/// The scenes of coqui_scenes: its registry's real scene for [sceneId] (made as `loadScene` makes it: its sheet read first),
/// with what the frame needs of it. A scene that is not converted yet throws `UnimplementedError('not converted yet')`.
///
/// [rng] is the story runner's random source, given to the scene's factory: a scene that draws random numbers (El balcón's
/// `azar`) draws from the one seeded source of the game, as the old one drew from `Math.random`; El frente draws none and
/// ignores it.
Future<StoryScene> registryScenes(String sceneId, Rng rng) async {
  final make =
      sceneRegistry[sceneId] ??
      (throw ArgumentError.value(sceneId, 'sceneId', 'not a scene'));
  if (convertedScenes.contains(sceneId)) await loadSheet(sceneId);
  final scene = make(rng: rng);
  if (scene is! SetScene) {
    throw StateError('scene "$sceneId" is not a converted scene with a set');
  }
  return StoryScene(
    scene: scene,
    frame: SceneFrameSetup(
      engine: ({required still}) => scene.newEngine(still: still),
      shadows: scene.shadows,
    ),
    startFrog: () => frogOfCode(scene.sheet, scene.projection, 'juego.js:16'),
    frogShadow: scene.frogShadow,
  );
}
