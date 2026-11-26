/// Two small pure functions of app.html: where a word stands in a line (`occs`) and when a word comes back
/// (`vuelve`).
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_words/src/wording.dart';

/// Where a phrase stands in a text: [a, z) are UTF-16 offsets and [k] is the phrase's index in the list.
typedef Occurrence = ({int a, int z, int k});

// app.html: occs
/// Where the words of a list of phrases (each a list of normalised tokens) stand in [text], the first phrase of
/// the list that fits first (a list sorted longest phrase first gives the longest): accents, case and punctuation
/// are ignored.
List<Occurrence> occurrences(
  String text,
  List<List<String>> phrases, {
  Language? language,
}) {
  final lang = language ?? Language.spanish;
  final tokens = [
    for (final tok in lang.tokens(text))
      (s: tok.start, e: tok.end, n: lang.normalize(tok.text).trim()),
  ];
  final out = <Occurrence>[];
  for (var i = 0; i < tokens.length; i++) {
    for (var k = 0; k < phrases.length; k++) {
      final t = phrases[k];
      if (t.isEmpty || i + t.length > tokens.length) continue;
      var fits = true;
      for (var j = 0; j < t.length; j++) {
        if (tokens[i + j].n != t[j]) {
          fits = false;
          break;
        }
      }
      if (!fits) continue;
      out.add((a: tokens[i].s, z: tokens[i + t.length - 1].e, k: k));
      i += t.length - 1;
      break;
    }
  }
  return out;
}

// app.html: oidoEn (the line: `wt=PAL.norm(w).trim().split(" ")`)
/// The normalised tokens of a word or phrase.
List<String> wordTokens(String word, {Language? language}) {
  final lang = language ?? Language.spanish;
  final norm = lang.normalize(word).trim();
  return norm.isEmpty ? const [] : norm.split(' ');
}

// app.html: vuelve
/// What the word sheet says about the next return of the ear: [due] is the stored `due` (ms, 0 = none), [now]
/// the palabras clock.
String comesBack(num due, int now) {
  if (due == 0 || due.isNaN) return '';
  if (due <= now) return WordsWording.comesBackToday;
  // Math.round: the number is positive here
  final n = math.max(1, ((due - now) / 864e5 + 0.5).floor());
  return WordsWording.comesBackInDays(n);
}
