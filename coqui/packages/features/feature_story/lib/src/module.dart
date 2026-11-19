import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:material_ui/material_ui.dart';

/// What speaking remembers until the app is closed: an error that says speaking cannot work ends the turns of every story
/// after it (juego.js: the session flag).
final SpeechSession _speech = SpeechSession();

/// feature_story's module: the story game. It answers [StoryRoute] (a story played, or told straight through when the route
/// says `listen`) with the play screen, full screen: the shell hides its tab bar. It has no tab.
///
/// [scenes] makes the scene a story file names: by default the scenes package's registry (`registryScenes`: the real
/// scenes, the converted ones; the others throw "not converted yet" and the screen shows the lesson frame and its X).
///
/// [showPerf]: the play screen shows, in a small corner chip, the bake time of the scene's state now on screen (the app's
/// `?perf=1`). Off by default.
class StoryModule implements FeatureModule {
  const StoryModule({this.scenes = registryScenes, this.showPerf = false});

  final SceneFactory scenes;
  final bool showPerf;

  @override
  String get id => 'story';

  @override
  FeatureTab? tab(Services s) => null;

  @override
  Widget? screenFor(AppRoute route, Services s) => route is StoryRoute
      ? StoryScreen(
          key: ValueKey(route),
          services: s,
          route: route,
          scenes: scenes,
          session: _speech,
          showPerf: showPerf,
        )
      : null;
}
