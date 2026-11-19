# Request: what the story needs of a scene to draw its frame, and the registry

## What I need

From `coqui_scenes` (and, for the shadows, from whoever ports each scene: orders 14 and 30b to 39b):

1. `lib/coqui_scenes.dart` exports `sceneRegistry` (or a function that makes the scene for a scene id). Today the public file is
   empty and the registry is under `src/`, which I may not import. The shell gives it to `StoryModule(scenes: ...)`.
2. For each scene, the two things `drawFrame` (coqui_pixel, page 12 section 5, "The frame, every tick") takes besides the
   `Scene`'s own members:
   - the engine the set is baked on: `PpEngine(w: 240, h: 216, s: 26, originX:, originY:, shadowX:, shadowY:, still:)`, with the
     sheet's `origin` (`Sheet.originX`, `Sheet.originY`) and the set reference's shadow direction;
   - the shadows the characters cast in a world state `W`: the list of `ShadowCast` (`x`, `y`, `z`, `r`: one `castShadow` call
     each). Order 12 says these heights are "not in the sheet as data" and that order 14 ports them from frente-set.html.

   The `Scene` class has no member for either. The simplest shape: two members of `Scene` (or of a small class a scene file also
   returns), `PpEngine newEngine({required bool still})` and `List<ShadowCast> shadows(Map<String, dynamic> W)`.
3. A scene that draws a random number must be given the app's `Rng` (`Services.rng`), never a new one (page 12, section 6):
   `SceneHost` has no `rng` member, so the scene's factory has to take it.

## Why

Order 15: "The frame is `drawFrame` from coqui_pixel; the camera is coqui_pixel's". `drawFrame` needs an engine and a shadow list, and
the runner cannot read them from a `Scene`.

## What I am using meanwhile

`StoryModule` takes a `SceneFactory` (`StoryScene Function(String sceneId, Rng rng)`, exported by `feature_story.dart` with
`StoryScene` and `SceneFrameSetup`): a scene plus the two functions above. The dev entry and the tests give it a scene of their
own (`tool/dev_scene.dart`, `tool/stand_in_scene.dart`). With none, `noScenes` throws and the screen shows the lesson frame with
its X and nothing else. When the scenes package gives the registry and the two members, the shell's factory is three lines and
`SceneFactory` can go.

## Order and branch

Order 15, branch `lane/feature_story/15`. For the orchestrator to place in orders 14 and 30b to 39b.
