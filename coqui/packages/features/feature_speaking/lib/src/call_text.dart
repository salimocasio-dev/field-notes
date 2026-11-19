/// The matching helpers of the call (llamada.js: norm, dice, adios) and the lines it shows.
library;

import 'package:coqui_contracts/coqui_contracts.dart';

// llamada.js: dice
/// Does the normalised [text] hold [word] (or phrase) on word boundaries? [text] is already `normalize`d
/// (one space each side); the word is normalised here and an empty one never matches.
bool dice(String text, String word) {
  final w = normalize(word);
  return w.trim() != '' && text.contains(w);
}

// llamada.js: adios
/// A goodbye, from either side: [text] holds one of [goodbyeWords] (`course.goodbyeWords`).
bool isGoodbye(String text, Iterable<String> goodbyeWords) {
  final n = normalize(text);
  return goodbyeWords.any((g) => dice(n, g));
}

// llamada.js: mmss
/// Call seconds as `mm:ss`.
String mmss(double seconds) {
  final s = seconds.floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

/// What the call shows and sends. English copied from llamada.js and app.html (v=39); the two
/// messages to Danny are the page's protocol with the agent (page 05, "How the page and Danny talk"),
/// not text for the learner.
abstract final class CallTexts {
  static const startCall = 'Start call';
  static const calling = 'Calling…';
  static const danny = 'Danny';
  static const yourTurn = 'Your turn';
  static const oneMoment = 'One moment';
  static const help = 'Help';
  static const helpNote = 'Danny will say it again, slowly.';
  static const done = 'Call done';
  static const micOff =
      'The microphone is off. Allow it in your browser to call.';
  static const notStarted =
      'The call did not start. Check your connection and try again.';
  static const libraryFailed =
      'The voice part did not load. Check your connection and try again.';

  /// "Call Danny", the Hablar card's title and the call screen's dialog label. app.html:458
  static const callDanny = 'Call Danny';

  /// What the page sends Danny when the learner taps Help. llamada.js: ayuda
  static const sendHelp = '(ayuda)';

  /// What the page sends Danny to end the call. llamada.js: enviaFin
  static const sendEnd = '(fin)';

  /// `${place} · about ${minutes} min`, the line before the call. llamada.js: abre
  static String aboutLine(String place, int minutes) =>
      '$place · about $minutes min';

  /// `N min · M words said`. llamada.js: finish
  static String summary(int minutes, int words) =>
      '$minutes min · $words word${words == 1 ? '' : 's'} said';

  /// llamada.js: the word's `<`, `>` and `&` are left out of a chip.
  static String chip(String word) => word.replaceAll(RegExp('[<>&]'), '');
}
