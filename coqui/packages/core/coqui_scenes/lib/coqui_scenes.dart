/// One folder per scene (its set, its scene), and the pictures other features ask for.
///
/// A converted scene is made from its sheet with [loadScene]; it is a [SetScene] (its set built by the engine, every
/// place from its sheet). [SetBakes] keeps a scene's baked states, [StillFrame] draws a frame of one on a [StillHost],
/// and [ScenePictures] is the `PictureSource` of page 12, section 3.
library;

export 'package:coqui_scenes/src/load_scene.dart'
    show convertedScenes, loadScene;
export 'package:coqui_scenes/src/pictures.dart'
    show PictureError, ScenePictures, pictureF;
export 'package:coqui_scenes/src/registry.dart' show sceneRegistry;
export 'package:coqui_scenes/src/scene_set.dart' show SetBakes, SetScene;
export 'package:coqui_scenes/src/sheets.dart' show loadSheet, sheetAsset;
export 'package:coqui_scenes/src/still_frame.dart' show StillFrame;
export 'package:coqui_scenes/src/still_host.dart' show StillHost, frogOfCode;
