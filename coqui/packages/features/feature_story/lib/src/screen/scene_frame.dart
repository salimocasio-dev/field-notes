/// What the story needs of a scene besides its [Scene] members, to draw its frame (page 12, section 5, "The frame, every
/// tick"): the engine the set is baked on and the shadows the characters cast.
///
/// `Scene` has no member for these: they live in the scene's sheet and in its set reference (the shadows' heights are not
/// in the sheet as data). Until the scenes package gives them (request
/// `coqui/requests/15-feature-story-needs-coqui-scenes-frame-inputs.md`), the module takes them from a [SceneFactory].
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';

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
  const StoryScene({required this.scene, required this.frame});

  final Scene scene;
  final SceneFrameSetup frame;
}

/// Makes the scene a story file names (`story['scene']`), given the one random source of the app: a scene that draws a
/// random number draws it from [rng]. Throws when there is no such scene.
typedef SceneFactory = StoryScene Function(String sceneId, Rng rng);

/// The factory the module has until the scenes package gives its registry: no scene is known.
StoryScene noScenes(String sceneId, Rng rng) => throw UnimplementedError(
  'no scene "$sceneId": the module was given no scenes',
);
