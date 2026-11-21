// TEST-ONLY. A scene that is not converted and never will be, and a story at it: the tests of what the screen does for a
// story whose scene is not converted yet use them, so that they do not depend on which real scenes are converted (order
// 36b; El banco's la-piragua was their story until El banco was converted).
import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:feature_story/src/screen/scene_frame.dart';

import 'screen_harness.dart';

/// The test scene's id: no scene of coqui_scenes' registry has it.
const String testSceneId = 'prueba';

/// The test story's id: a story at [testSceneId].
const String testStoryId = 'prueba-cuento';

/// The scenes of the registry ([registryScenes]), and the test scene, which is not converted: its factory throws as
/// every scene's stub in the registry does while that scene is not converted (`UnimplementedError('not converted
/// yet')`, coqui_scenes' registry and `loadScene`).
Future<StoryScene> scenesWithTestScene(String id, Rng rng) => id == testSceneId
    ? Future.error(UnimplementedError('not converted yet'))
    : registryScenes(id, rng);

/// The sample course with the test story: la-lluvia's file, at the test scene.
class WithTestScene extends EditedCourse {
  WithTestScene() : super((id, f) {});

  @override
  Future<Map<String, dynamic>> story(String id) async {
    if (id != testStoryId) return super.story(id);
    final f = Map<String, dynamic>.of(await super.story('la-lluvia'));
    f['id'] = testStoryId;
    f['scene'] = testSceneId;
    return f;
  }
}
