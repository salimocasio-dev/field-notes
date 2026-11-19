/// The one list of feature modules. The shell holds the only such list.
///
/// The five tabs first, in the tab bar's order (Biblioteca, Palabras, Mapa, Hablar, Yo), then the two features that
/// are not tabs (the story, opened by `StoryRoute`; Repaso and the level check, opened by `ReviewRoute` and
/// `LevelCheckRoute`). A route opens the screen of the first module whose `screenFor` answers it.
library;

import 'package:app/src/switches.dart';
import 'package:app/src/voice_test_data.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/feature_library.dart';
import 'package:feature_map/feature_map.dart';
import 'package:feature_profile/feature_profile.dart';
import 'package:feature_review/feature_review.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_story/feature_story.dart';
import 'package:feature_words/feature_words.dart';

/// The modules, for the address switches [switches]. [bookImageUrl] turns a book page's picture (`img/<file>`) into its
/// address; [voiceTest] is the voice test's content (null when its file could not be read).
List<FeatureModule> coquiModules({
  required AppSwitches switches,
  required String Function(String path) bookImageUrl,
  VoiceTestData? voiceTest,
}) => [
  libraryModule(imageUrl: bookImageUrl),
  const WordsModule(),
  MapModule(showPerf: switches.perf),
  speakingModule(voiceTest: voiceTest),
  const ProfileModule(),
  StoryModule(showPerf: switches.perf),
  const ReviewModule(),
];

/// Biblioteca's module, told where a book page's picture is ([imageUrl]: `historia/libros/<path>?v=39` on the site).
///
/// Until order 22's module is merged, feature_library's module is a placeholder that takes nothing. At that merge this
/// one line changes, from `const LibraryModule()` to `LibraryModule(imageUrl: imageUrl)`.
FeatureModule libraryModule({required String Function(String path) imageUrl}) =>
    const LibraryModule();

/// Hablar's module. There is no entry to the voice test on the tab (v=39 links it from nowhere): it opens by its
/// address only (`#/prueba-voz`).
///
/// [voiceTest] cannot reach the module yet: feature_speaking exports only `SpeakingModule`, not `VoiceTestContent`
/// and the types it is made of, so the shell cannot build one, and the voice test's address opens the map. Once
/// feature_speaking exports them, this function builds `SpeakingModule(voiceTest: ...)` from [voiceTest] (see
/// `../AGENTS.md`, "Waiting on other packages").
FeatureModule speakingModule({VoiceTestData? voiceTest}) =>
    const SpeakingModule();
