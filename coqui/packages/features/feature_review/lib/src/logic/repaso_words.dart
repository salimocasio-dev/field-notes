/// Text helpers of Repaso's games: words compared with accents and case folded, a tracked word found in a sentence.
library;

import 'package:coqui_contracts/coqui_contracts.dart';

/// The words of [s], lower case, accents/marks and signs gone (`language.normalize`, PAL.norm, split).
List<String> foldedTokens(String s, {Language? language}) {
  final lang = language ?? Language.spanish;
  return [
    for (final t in lang.normalize(s).trim().split(' '))
      if (t.isNotEmpty) t,
  ];
}

/// A word of a written text and where it stands in it.
class TextSpanAt {
  const TextSpanAt(this.start, this.end);
  final int start;
  final int end;
}

/// Where [word] (one word or a phrase) stands in [text]: the run of words of [text] that are the word's, the last one
/// with a final s or es allowed for Latin scripts (make_repaso.py: tracked_in); with its marks first, then folded
/// through [language] (so "bebe" lights "bebe", not "bebé", where both are there, and Arabic words match across
/// diacritics/alef forms). Null when it is not there.
TextSpanAt? findWord(String text, String word, {Language? language}) {
  final lang = language ?? Language.spanish;
  final ms = lang.tokens(text);
  final allowLatinPlural = lang.script == 'Latn';
  TextSpanAt? find(List<String> want, String Function(String) form) {
    if (want.isEmpty) return null;
    final got = [for (final m in ms) form(m.text)];
    for (var i = 0; i + want.length <= got.length; i++) {
      var ok = true;
      for (var k = 0; k < want.length && ok; k++) {
        final g = got[i + k];
        final w = want[k];
        ok = k == want.length - 1
            ? (g == w || (allowLatinPlural && (g == '${w}s' || g == '${w}es')))
            : g == w;
      }
      if (ok) return TextSpanAt(ms[i].start, ms[i + want.length - 1].end);
    }
    return null;
  }

  String lower(String s) => s.toLowerCase();
  return find([for (final m in lang.tokens(word)) lower(m.text)], lower) ??
      find(
        foldedTokens(word, language: lang),
        (s) => foldedTokens(s, language: lang).join(),
      );
}
