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
/// address (Biblioteca's books, and the moments of Repaso's games); [voiceTest] is the voice test's content (null when its file could not be read).
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
  StoryModule(showPerf: switches.perf, txt: switches.txt),
  ReviewModule(imageUrl: bookImageUrl),
];

/// Biblioteca's module, told where a book page's picture is ([imageUrl]: `historia/libros/<path>?v=39` on the site).
FeatureModule libraryModule({required String Function(String path) imageUrl}) =>
    LibraryModule(imageUrl: imageUrl);

/// Hablar's module. There is no entry to the voice test on the tab (v=39 links it from nowhere): it opens by its
/// address only (`#/prueba-voz`). With no [voiceTest] (its file could not be read) that address opens the map.
FeatureModule speakingModule({VoiceTestData? voiceTest}) => SpeakingModule(
  voiceTest: voiceTest == null ? null : voiceTestContent(voiceTest),
);

/// The voice test's content, from the file read at the start: its lines, each with its hint and its targets, and the
/// seven Spanish words around them (`VoiceTestLabels`, by the names [VoiceTestData.labelNames] holds).
VoiceTestContent voiceTestContent(VoiceTestData data) => VoiceTestContent(
  lines: [
    for (final l in data.lines)
      VoiceLine(l.text, [
        for (final t in l.targets) VoiceTarget(t.word, t.forms),
      ], hint: l.hint),
  ],
  labels: VoiceTestLabels(
    listening: data.labels['listening']!,
    processing: data.labels['processing']!,
    unavailable: data.labels['unavailable']!,
    again: data.labels['again']!,
    mic: data.labels['mic']!,
    next: data.labels['next']!,
    progress: data.labels['progress']!,
  ),
);
