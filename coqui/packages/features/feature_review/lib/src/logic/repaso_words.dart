/// Text helpers of Repaso's games: words compared with accents and case folded, a tracked word found in a sentence.
library;

import 'package:coqui_contracts/coqui_contracts.dart';

/// The words of [s], lower case, accents and signs gone (`normalize`, PAL.norm, split).
List<String> foldedTokens(String s) => repasoTokens(s);

/// A word of a written text and where it stands in it.
class TextSpanAt {
  const TextSpanAt(this.start, this.end);
  final int start;
  final int end;
}

final RegExp _letters = RegExp(r'[0-9A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+');

/// Where [word] (one word or a phrase) stands in [text]: the run of words of [text] that are the word's, the last one
/// with a final s or es allowed (make_repaso.py: tracked_in); with its accents first, then with accents folded (so
/// "bebe" lights "bebe", not "bebé", where both are there). Null when it is not there.
TextSpanAt? findWord(String text, String word) {
  final ms = _letters.allMatches(text).toList();
  TextSpanAt? find(List<String> want, String Function(String) form) {
    if (want.isEmpty) return null;
    final got = [for (final m in ms) form(m.group(0)!)];
    for (var i = 0; i + want.length <= got.length; i++) {
      var ok = true;
      for (var k = 0; k < want.length && ok; k++) {
        final g = got[i + k];
        final w = want[k];
        ok = k == want.length - 1
            ? (g == w || g == '${w}s' || g == '${w}es')
            : g == w;
      }
      if (ok) return TextSpanAt(ms[i].start, ms[i + want.length - 1].end);
    }
    return null;
  }

  String lower(String s) => s.toLowerCase();
  return find([
        for (final m in _letters.allMatches(word)) lower(m.group(0)!),
      ], lower) ??
      find(foldedTokens(word), (s) => foldedTokens(s).join());
}
