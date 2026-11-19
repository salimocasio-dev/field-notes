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

/// The scenes of coqui_scenes: its registry's real scene for [sceneId] (`loadScene`), with what the frame needs of it. A scene
/// that is not converted yet throws `UnimplementedError('not converted yet')`.
///
/// [rng] is not given to the scene: the registry's factories take none (El frente draws no random number; the scenes that do
/// are not converted yet).
Future<StoryScene> registryScenes(String sceneId, Rng rng) async {
  final scene = await loadScene(sceneId);
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
