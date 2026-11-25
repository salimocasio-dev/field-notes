/// The story game: the step runner, the play screen, Listen mode and speaking turns.
///
/// The public surface is the module.
library;

export 'package:feature_story/src/module.dart';
// The setting `StoryModule(txt:)` takes.
export 'package:feature_story/src/runner/story_options.dart' show TxtMode;
// The no-screen player, for `coqui_story_checks`.
export 'package:feature_story/src/play/play.dart' show play;
