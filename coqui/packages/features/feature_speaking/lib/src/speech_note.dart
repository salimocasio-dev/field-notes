/// The note "Speaking in stories isn't available on this phone right now." (app.html: `notaHabla`).
library;

import 'package:coqui_contracts/coqui_contracts.dart';

/// app.html: `NOTAPAG`. The day the note was first shown while the app has been open: it stays while the app is
/// open, and comes back once a day.
String _shownDay = '';

/// Forgets the day the note was shown (the old page's `NOTAPAG`, which a page load resets).
void resetSpeechNoteDay() => _shownDay = '';

/// app.html: the line itself.
const String speechNoteText =
    "Speaking in stories isn't available on this phone right now.";

/// The key of the setting that keeps the day the note was last shown (app.html: `AJ().notaHabla`).
const String speechNoteSetting = 'notaHabla';

// app.html: notaHabla
/// The note, or null for no note. A phone that can take a speaking turn gets none. Otherwise it is shown once a
/// day: the day is kept in the settings the first time, and while the app stays open the note stays.
///
/// The old page asks `habDisp()` (juego.js), which also says no after an error in a story; here the speech
/// listener's [SpeechListener.available] is all there is to ask.
Future<String?> speechNote({
  required SpeechListener speech,
  required ProgressStore progress,
  required Clock clock,
}) async {
  if (await speech.available()) return null;
  final today = DateTime.fromMillisecondsSinceEpoch(
    clock.nowMs(),
    isUtc: true,
  ).toIso8601String().substring(0, 10);
  if (_shownDay != today) {
    if (progress.setting(speechNoteSetting) == today) return null;
    progress.setSetting(speechNoteSetting, today);
    _shownDay = today;
  }
  return speechNoteText;
}
