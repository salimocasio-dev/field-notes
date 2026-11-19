/// Which words of a line have a picture: app.html `pares` and `occs`.
library;

import 'package:coqui_contracts/coqui_contracts.dart';

/// One word that has a picture (one item of a review set), with its normalised tokens. app.html:321 (`pares`)
class PictureWord {
  const PictureWord(this.word, this.pair, this.tokens);

  /// The word as the review set writes it (`it.w`); multi-word words are phrases.
  final String word;

  /// The item (`it`): its `yes` side is the "si" picture.
  final ReviewPair pair;

  /// `PAL.norm(w).trim().split(" ")`.
  final List<String> tokens;
}

/// Where a picture word stands in a text: `{a, z, k}` of app.html:369 (`occs`).
class WordMark {
  const WordMark(this.start, this.end, this.k);

  /// `a`: the offset of its first letter.
  final int start;

  /// `z`: the offset after its last letter.
  final int end;

  /// Its index in [PictureWords.list] (`data-k`).
  final int k;

  @override
  bool operator ==(Object other) =>
      other is WordMark &&
      other.start == start &&
      other.end == end &&
      other.k == k;

  @override
  int get hashCode => Object.hash(start, end, k);

  @override
  String toString() => 'WordMark($start, $end, $k)';
}

/// The words that have a picture pair: `PW.L`, longest phrase first. app.html:321 (`pares`)
class PictureWords {
  PictureWords(Iterable<ReviewPair> pairs) : list = _build(pairs);

  /// `PW.L`: one entry per word, longest phrase first, the order of the items otherwise.
  final List<PictureWord> list;

  // app.html: pares
  static List<PictureWord> _build(Iterable<ReviewPair> pairs) {
    // CU.items.forEach(it=>m.set(it.w,it)): a later item with the same word replaces the value, the key keeps its place
    final m = <String, ReviewPair>{};
    for (final it in pairs) {
      m[it.word] = it;
    }
    final all = [
      for (final it in m.values)
        PictureWord(it.word, it, normalize(it.word).trim().split(' ')),
    ];
    // JavaScript's sort is stable: the index breaks ties
    final order = {for (var i = 0; i < all.length; i++) all[i]: i};
    all.sort((a, b) {
      final c = b.tokens.length.compareTo(a.tokens.length);
      return c != 0 ? c : order[a]!.compareTo(order[b]!);
    });
    return all;
  }

  /// [wordMarks] of [text] for this list's words.
  List<WordMark> marks(String text) =>
      wordMarks(text, [for (final w in list) w.tokens]);
}

final RegExp _token = RegExp(r'[\p{L}\p{N}]+', unicode: true);

// app.html: occs
/// Where the words of a list of phrases (each a list of normalised tokens) stand in [text]:
/// the first phrase of the list that fits at a word, so the longest when the list is sorted so;
/// accents, case and punctuation ignored.
List<WordMark> wordMarks(String text, List<List<String>> phrases) {
  final tk = <({int s, int e, String n})>[
    for (final m in _token.allMatches(text))
      (s: m.start, e: m.end, n: normalize(m.group(0)).trim()),
  ];
  final out = <WordMark>[];
  for (var i = 0; i < tk.length; i++) {
    for (var k = 0; k < phrases.length; k++) {
      final t = phrases[k];
      if (i + t.length > tk.length) continue;
      var every = true;
      for (var j = 0; j < t.length; j++) {
        if (tk[i + j].n != t[j]) {
          every = false;
          break;
        }
      }
      if (!every) continue;
      out.add(WordMark(tk[i].s, tk[i + t.length - 1].e, k));
      i += t.length - 1;
      break;
    }
  }
  return out;
}
