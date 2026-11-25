/// Repaso as games (docs/proyecto/15-repaso-juegos.md): which words a session asks, the scored item of each word,
/// the play items around them, and what each item shows. Plain Dart: the data, the store, the course's pairs and a
/// random source are handed in, so a plan can be made and checked without a screen.
///
/// The rules, as page 15 gives them:
/// - Words: as today (up to 10; due first, most overdue first). A word that no game can serve is dropped before the
///   cap. Nothing due: practice, the words he has heard in a mixed order, as today's practice.
/// - One scored item per word. ¿Cuál? and ¿Qué oyes? in turn by the word's count of Ear answers (`n`: even ¿Cuál?,
///   odd ¿Qué oyes?); after a miss (the record's last answer was wrong) ¿Cuál?; a word with only one of the two gets
///   that one. The sentence in turn by that same count, among the sentences of stories he has finished.
/// - After every third scored item, one play item; the kinds in turn (Arma la frase, Parejas, ¿Dónde?, Dilo),
///   skipping a kind that has no material among the session's words; never a sentence of a scored item of the session.
library;

import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_review/src/logic/js_sort.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:feature_review/src/logic/word_picture.dart';

/// The kinds of item. [cual] and [hear] (¿Qué oyes?) are scored; the others are play and score nothing for Ear.
enum GameKind { cual, hear, build, match, where, say }

/// The play kinds, in the order they take turns.
///
/// Issue #10 override: `GameKind.where` (`¿Dónde?`) uses story-book screenshots, so it is excluded from play turns.
const List<GameKind> playKinds = [GameKind.build, GameKind.match, GameKind.say];

/// The plain English line that says what to do in each game (menus may be English), page 15 "The session". A game that
/// plays a sentence starts with "Listen."; Parejas, where he starts with a touch, does not. The two picture games
/// (¿Cuál? and ¿Dónde?) say the same line. For Dilo (#9), the learner hears and sees the sentence with the tested word
/// highlighted, and says it back.
String gameInstruction(GameKind k) => switch (k) {
  GameKind.cual => 'Listen. Touch the picture that fits.',
  GameKind.hear => 'Listen. Touch the word you heard.',
  GameKind.build =>
    "Listen. Touch the words in the order you hear. Two don't belong.",
  GameKind.match => 'Touch a sound, then its word.',
  GameKind.where => 'Listen. Touch the picture that fits.',
  GameKind.say => 'Listen. Say the sentence back.',
};

/// How many words a session asks at most (cual.js: CAP).
const int repasoCap = 10;

/// A miss comes back this many items later, at most this many times a session.
const int repasoReturnAfter = 3;
const int repasoMaxReturns = 5;

/// A play item after every this many scored items.
const int repasoPlayEvery = 3;

const int _day = 86400000;

/// One item of a session.
sealed class GameItem {
  GameItem(this.kind, this.word);
  final GameKind kind;

  /// The word it is about (a play item that uses several words: the first).
  final String word;

  bool get scored => kind == GameKind.cual || kind == GameKind.hear;

  /// The recorded sentence it plays (Parejas: none).
  String? get clip;

  /// That sentence's text.
  String? get text;
}

/// ¿Cuál?: the word's own picture pair with one of its sentences. [rightPanel]: which of the two pictures (0 top,
/// 1 bottom) is the one that fits.
class CualItem extends GameItem {
  CualItem({
    required String word,
    required this.pair,
    required this.line,
    required this.rightPanel,
    this.asset,
  }) : super(GameKind.cual, word);
  final ReviewPair pair;
  final RepasoPairLine line;
  final int rightPanel;
  final WordPictureAsset? asset;
  @override
  String get clip => line.clip;
  @override
  String get text => line.text;

  /// The same sentence and pair with the pictures the other way round (a missed item comes back like this: never the
  /// identical picture).
  CualItem rearranged() => CualItem(
    word: word,
    pair: pair,
    line: line,
    rightPanel: 1 - rightPanel,
    asset: asset,
  );
}

/// ¿Qué oyes?: a sentence and three written tiles; [answer] is the tile of the word that was in it.
class HearItem extends GameItem {
  HearItem({
    required String word,
    required this.sentence,
    required this.tiles,
    required this.answer,
    required this.solo,
  }) : super(GameKind.hear, word);
  final RepasoSentence sentence;
  final List<String> tiles;
  final int answer;

  /// The clip of each tile's word said alone, or null.
  final List<String?> solo;

  /// Whether the tiles show a speaker each: only when every tile of the item has a clip of its word alone (a speaker
  /// on some tiles and not on others would say which are the ones to look at).
  bool get speakers => solo.every((c) => c != null);
  @override
  String get clip => sentence.clip;
  @override
  String get text => sentence.text;

  /// The same sentence and tiles in an order that is not the one they had (a missed item comes back like this: never
  /// the identical arrangement). [pick] is a number in [0, 1) from the session's random source.
  HearItem rearranged(double pick) {
    final n = tiles.length;
    // every order of the tiles but the one they are in, in a fixed order: n! - 1 of them
    final orders = _permutations(n).where((o) {
      for (var i = 0; i < n; i++) {
        if (o[i] != i) return true;
      }
      return false;
    }).toList();
    final o =
        orders[(pick * orders.length).floor().clamp(0, orders.length - 1)];
    return HearItem(
      word: word,
      sentence: sentence,
      tiles: [for (final i in o) tiles[i]],
      answer: o.indexOf(answer),
      solo: [for (final i in o) solo[i]],
    );
  }
}

List<List<int>> _permutations(int n) {
  if (n <= 1) return [List<int>.generate(n, (i) => i)];
  final out = <List<int>>[];
  for (final rest in _permutations(n - 1)) {
    for (var at = 0; at <= rest.length; at++) {
      out.add([...rest.take(at), n - 1, ...rest.skip(at)]);
    }
  }
  return out;
}

/// Arma la frase: the sentence's words ([order]) and the tiles in their mixed order with two extra words ([pool]).
class BuildItem extends GameItem {
  BuildItem({
    required String word,
    required this.sentence,
    required this.order,
    required this.pool,
  }) : super(GameKind.build, word);
  final RepasoSentence sentence;
  final List<String> order;
  final List<String> pool;
  @override
  String get clip => sentence.clip;
  @override
  String get text => sentence.text;
}

/// Parejas: four words, each with a sentence that has it and none of the others ([words] and [sentences], the
/// speakers in this order); the written words show in [wordOrder].
class MatchItem extends GameItem {
  MatchItem({
    required this.words,
    required this.sentences,
    required this.wordOrder,
  }) : super(GameKind.match, words.first);
  final List<String> words;
  final List<RepasoSentence> sentences;
  final List<int> wordOrder;
  @override
  String? get clip => null;
  @override
  String? get text => null;
}

/// ¿Dónde?: the sentence and two or three pictures of its story; [answer] is its own. [farthest] is the fair wrong
/// picture that is farthest from its own in the story: the one wrong picture of an item that has only two.
class WhereItem extends GameItem {
  WhereItem({
    required String word,
    required this.sentence,
    required this.pictures,
    required this.answer,
    String? farthest,
  }) : farthest =
           farthest ??
           pictures.firstWhere((p) => p != pictures[answer], orElse: () => ''),
       super(GameKind.where, word);
  final RepasoSentence sentence;
  final List<String> pictures;
  final int answer;
  final String farthest;
  @override
  String get clip => sentence.clip;
  @override
  String get text => sentence.text;

  /// The pictures of the item when the screen has room for [n] of them: all of them, or, for two, its own and the
  /// farthest wrong one, in the order they have.
  List<String> picturesFor(int n) {
    if (n >= pictures.length || farthest.isEmpty) return pictures;
    final own = pictures[answer];
    return [
      for (final p in pictures)
        if (p == own || p == farthest) p,
    ];
  }
}

/// Dilo: he hears and sees the sentence ([line].clip / [line].text) with the tested word highlighted, and says it back.
class SayItem extends GameItem {
  SayItem({required String word, required this.line})
    : super(GameKind.say, word);
  final RepasoSay line;
  @override
  String get clip => line.clip;
  @override
  String get text => line.text;
}

/// A place in the session's queue: a scored item, a play slot (its item is chosen when it is reached), or a missed
/// item asked again (unscored).
class QueueEntry {
  QueueEntry.scored(GameItem this.item)
    : again = false,
      slot = false,
      origin = null;
  QueueEntry.again(GameItem this.item, {this.origin})
    : again = true,
      slot = false;
  QueueEntry.slot() : item = null, again = false, slot = true, origin = null;

  /// A play item given as it is (a test, a tool).
  QueueEntry.play(GameItem this.item)
    : again = false,
      slot = false,
      origin = null;
  GameItem? item;
  final bool again;
  final bool slot;

  /// A return: the entry whose miss it answers (the bar has no dash of its own for a return, and it repaints none).
  final QueueEntry? origin;
}

/// Whether he has finished the story [id] (the rule lives in coqui_contracts, where every count asks it too).
bool storyFinished(ProgressStore p, String id) => repasoStoryFinished(p, id);

/// Whether the Ear record's last answer was a miss: a miss since the last right one, or the miss that parked it
/// (palabras.js: a third miss sets `aparcada` a week after that answer and clears `fallos`).
bool lastWasMiss(SkillRecord e) =>
    e.fallos > 0 || (e.aparcada != 0 && e.aparcada == e.ultima + 7 * _day);

/// A Fisher-Yates shuffle with [rng], from the end.
List<T> shuffled<T>(List<T> list, Rng rng) {
  final out = [...list];
  for (var i = out.length - 1; i > 0; i--) {
    final j = (rng.next() * (i + 1)).floor();
    final t = out[i];
    out[i] = out[j];
    out[j] = t;
  }
  return out;
}

/// The feature's own memory of the last sentence each word was asked in, so that a word never gets the same
/// sentence twice running (the count alone cannot promise it: stories also write Ear answers). In the feature's own
/// storage space, never in the progress store.
class LastAsked {
  LastAsked(this.store);
  final KeyValueStore? store;
  static const key = 'repaso.last';

  /// Where the play kinds' turn stands (see [RepasoPlanner.nextKind]).
  static const kindKey = 'repaso.kind';

  int readKind() {
    try {
      final v = int.tryParse(store?.read(kindKey) ?? '') ?? 0;
      return v < 0 ? 0 : v % playKinds.length;
    } catch (_) {
      return 0;
    }
  }

  void writeKind(int k) {
    final s = store;
    if (s == null) return;
    s.write(kindKey, '$k').ignore();
  }

  Map<String, String> read() {
    try {
      final t = store?.read(key);
      if (t == null) return {};
      return Map<String, String>.from(jsonDecode(t) as Map);
    } catch (_) {
      return {};
    }
  }

  void write(String word, String clip) {
    final s = store;
    if (s == null) return;
    final m = read()..[word] = clip;
    s.write(key, jsonEncode(m)).ignore();
  }
}

/// The words of a session, its scored items, and how the play items are chosen.
class RepasoPlanner {
  RepasoPlanner({
    required this.data,
    required this.progress,
    required this.pairs,
    required this.rng,
    Language? language,
    Map<String, String>? lastAsked,
    this.nextKind = 0,
    this.wordAssets = const {},
  }) : language = language ?? Language.spanish,
       lastAsked = lastAsked ?? const {};

  final RepasoData data;
  final ProgressStore progress;

  /// The course's picture pairs (`CourseCatalog.pairs`).
  final List<ReviewPair> pairs;

  /// The session's random source (seeded once for the session).
  final Rng rng;

  /// The course's language for word folding and tokenisation.
  final Language language;

  /// The clip each word was last asked in (see [LastAsked]).
  final Map<String, String> lastAsked;

  /// Dedicated single-word picture assets keyed by word (`#10`).
  final Map<String, WordPictureAsset> wordAssets;

  late final Map<String, ReviewPair> _pairOf = {
    for (final p in pairs) p.word: p,
  };

  /// Which sentences and words are his to be asked: the one rule, shared with the counts outside Repaso.
  late final RepasoServing serving = RepasoServing(
    data: data,
    progress: progress,
    pairs: pairs,
  );

  final Map<String, List<String>> _foldedCache = {};
  List<String> _tokensOf(String s) =>
      _foldedCache[s] ??= foldedTokens(s, language: language);

  final Map<RepasoSentence, Set<String>> _inSentenceCache = {};
  Set<String> _wordsIn(RepasoSentence s) => _inSentenceCache[s] ??= {
    ..._tokensOf(s.text),
    ...s.tokens.expand(_tokensOf),
  };

  bool finished(String? story) => serving.finished(story);

  /// The words he has met that the data knows, in the data's (course) order.
  List<RepasoWord> get met => serving.met;

  /// The sentences of the session's items so far (no two items share one).
  final Set<String> used = {};

  // ---- ¿Cuál? and ¿Qué oyes? material

  /// Dedicated single-word picture asset for [word] when present and usable under `#10`.
  WordPictureAsset? pictureAssetFor(String word) {
    final asset = wordAssets[word];
    return asset != null && asset.word == word && asset.isUsable ? asset : null;
  }

  /// The word's ¿Cuál? sentences he may get: only when a usable dedicated single-word asset exists (`#10`).
  List<RepasoPairLine> cualLines(RepasoWord w) {
    if (pictureAssetFor(w.word) == null) return const [];
    return serving.cualLines(w);
  }

  /// The word's ¿Qué oyes? sentences he may get, in the fixed order: from finished stories, with two fair wrong
  /// tiles among the words he has met.
  ///
  /// For Latin scripts (`Latn`, including Spanish), native sentences delegate directly to `serving.hearSentences` so
  /// this stays 100% aligned with `RepasoServing.canServe` used by Map and Palabras. For non-Latin scripts (e.g.
  /// `Arab`), where `coqui_contracts`'s `RepasoServing` still defaults to Spanish tokenisation, this uses
  /// [wrongTileChoices] with [language] until
  /// `coqui/requests/90-feature-review-needs-coqui-contracts-repaso-serving-language.md` lands (known non-Latin gap:
  /// Map/Palabras counts will align once `RepasoServing` accepts [Language]).
  ///
  /// Under `#10`, when a word has no dedicated single-word picture asset ([cualLines] is empty) and no native
  /// hearing sentences, its existing `serving.cualLines(w)` audio lines are served as text-only `¿Qué oyes?`
  /// sentences (no pictures). This keeps [servable] 100% aligned with `RepasoServing.canServe` used by Map and
  /// Palabras so due words like `cual`-only entries are always cleared and never stuck as perpetually due.
  List<RepasoSentence> hearSentences(RepasoWord w) {
    final native = language.script == 'Latn'
        ? serving.hearSentences(w)
        : [
            for (final k in w.sentences)
              if (data.sentences[k] case final s
                  when s.forHearing &&
                      finished(s.story) &&
                      wrongTileChoices(w, s).length >= 2)
                s,
          ];
    if (native.isNotEmpty) return native;
    if (cualLines(w).isNotEmpty) return const [];
    final pairFallback = serving.cualLines(w);
    if (pairFallback.isEmpty) return const [];
    return [
      for (final l in pairFallback)
        if (_pairLineAsHearingSentence(l) case final s
            when _hasFairWrongTiles(w, s))
          s,
    ];
  }

  RepasoSentence _pairLineAsHearingSentence(RepasoPairLine l) {
    final tokens = _tokensOf(l.text);
    final tokenSet = tokens.toSet();
    final forbidden = [
      for (final m in data.words)
        if (_tokensOf(m.word).any(tokenSet.contains)) m.word,
    ];
    return RepasoSentence(
      clip: l.clip,
      story: l.story ?? '',
      text: l.text,
      tokens: tokens,
      forbidden: forbidden,
      picture: null,
      forHearing: true,
      forBuilding: false,
    );
  }

  /// Whether some game can score the word now. Matches `RepasoServing.canServe` for every word with at least two
  /// fair distractors, and gracefully rules out words in a thin course where no two fair distractors exist.
  bool servable(RepasoWord w) =>
      cualLines(w).isNotEmpty || hearSentences(w).isNotEmpty;

  /// The words other than [target] that may stand as a wrong written tile beside [s], in the data's order: words he
  /// has met, not in the sentence (none of their words is a word of it), not in its forbidden list, not in the
  /// `no_juntas` of the target or of any tracked word in the sentence. The two picked are also apart from each other.
  ///
  /// Delegates directly to `serving.wrongTileChoices` for Latin scripts (`Latn`). For non-Latin scripts, delegates to
  /// [wrongTileChoicesForLanguage] until `coqui_contracts`'s `RepasoServing` accepts [Language]
  /// (`coqui/requests/90-feature-review-needs-coqui-contracts-repaso-serving-language.md`).
  List<RepasoWord> wrongTileChoices(
    RepasoWord target,
    RepasoSentence s, {
    bool singleWords = false,
  }) => language.script == 'Latn'
      ? serving.wrongTileChoices(target, s, singleWords: singleWords)
      : wrongTileChoicesForLanguage(target, s, singleWords: singleWords);

  /// Language-aware wrong-tile filter matching `RepasoServing.wrongTileChoices` rule-for-rule, using [language]
  /// folding for scripts that `RepasoServing` does not yet support.
  List<RepasoWord> wrongTileChoicesForLanguage(
    RepasoWord target,
    RepasoSentence s, {
    bool singleWords = false,
  }) {
    final inSentence = _wordsIn(s);
    final banned = <String>{
      target.word,
      ...target.apart,
      ...s.forbidden,
      for (final x in s.forbidden) ...?data.word(x)?.apart,
    };
    return [
      for (final m in met)
        if (!banned.contains(m.word) &&
            !m.apart.contains(target.word) &&
            !_tokensOf(m.word).any(inSentence.contains) &&
            (!singleWords || _tokensOf(m.word).length == 1))
          m,
    ];
  }

  /// Two wrong tiles for [s]: [wrongTileChoices] mixed by the session's random source, the words of the target's place
  /// first; the second is not one the first must not meet. Null when there are not two.
  List<RepasoWord>? wrongTiles(
    RepasoWord target,
    RepasoSentence s, {
    bool singleWords = false,
  }) => _pickTwoWrongTiles(
    target,
    wrongTileChoices(target, s, singleWords: singleWords),
  );

  List<RepasoWord>? _pickTwoWrongTiles(
    RepasoWord target,
    List<RepasoWord> pool,
  ) {
    final mixed = shuffled(pool, rng);
    // the same place first (a stable sort: the mixed order stays inside each group)
    final cands = [
      for (final m in mixed)
        if (m.place == target.place) m,
      for (final m in mixed)
        if (m.place != target.place) m,
    ];
    if (cands.length < 2) return null;
    for (var i = 0; i < cands.length; i++) {
      final a = cands[i];
      for (var j = i + 1; j < cands.length; j++) {
        final b = cands[j];
        if (!a.apart.contains(b.word) && !b.apart.contains(a.word)) {
          return [a, b];
        }
      }
    }
    return null;
  }

  List<RepasoWord> _fallbackPool(RepasoWord target, RepasoSentence s) {
    final inSentence = _wordsIn(s);
    final banned = <String>{
      target.word,
      ...target.apart,
      ...s.forbidden,
      for (final x in s.forbidden) ...?data.word(x)?.apart,
    };
    return [
      for (final m in data.words)
        if (!banned.contains(m.word) &&
            !m.apart.contains(target.word) &&
            !_tokensOf(m.word).any(inSentence.contains))
          m,
    ];
  }

  static bool _hasCompatiblePair(List<RepasoWord> pool) {
    for (var i = 0; i < pool.length; i++) {
      for (var j = i + 1; j < pool.length; j++) {
        if (!pool[i].apart.contains(pool[j].word) &&
            !pool[j].apart.contains(pool[i].word)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _hasFairWrongTiles(RepasoWord target, RepasoSentence s) =>
      _hasCompatiblePair(wrongTileChoices(target, s)) ||
      _hasCompatiblePair(_fallbackPool(target, s));

  /// Fallback pool from all course words when a learner has met fewer than two fair distractors for a pair-line
  /// fallback sentence. Strictly enforces `banned`, `apart`, and in-sentence exclusion; returns null when no fair
  /// pair exists.
  List<RepasoWord>? _fallbackWrongTiles(RepasoWord target, RepasoSentence s) =>
      _pickTwoWrongTiles(target, _fallbackPool(target, s));

  // ---- the words of a session

  /// The words of the session and whether it is a practice (nothing due). [only], [cap], [all]: the old page's
  /// switches (`?solo=`, `?n=`, `?todo=`).
  ({List<RepasoWord> words, bool practice}) sessionWords({
    int cap = repasoCap,
    List<String>? only,
    bool all = false,
  }) {
    final due = progress.due(Skill.ear);
    var list = <RepasoWord>[
      for (final w in due)
        if (data.word(w) case final r? when servable(r)) r,
    ];
    final practice = list.isEmpty;
    if (practice) {
      final heard = [
        for (final r in progress.words)
          if (data.word(r.w) case final d? when servable(d)) d,
      ];
      list = heard.isNotEmpty && !all
          ? heard
          : [
              for (final d in data.words)
                if (servable(d)) d,
            ];
      jsSort<RepasoWord>(list, (a, b) => rng.next() - .5);
    }
    if (only != null) {
      list = [
        for (final d in data.words)
          if (only.contains(d.word) && servable(d)) d,
      ];
    }
    return (words: list.take(cap).toList(), practice: practice);
  }

  /// Which scored game the word gets: ¿Cuál? and ¿Qué oyes? in turn by its count of Ear answers; ¿Cuál? after a
  /// miss; the one it has when it has only one.
  GameKind scoredKind(RepasoWord w) {
    final hasCual = cualLines(w).isNotEmpty;
    final hasHear = hearSentences(w).isNotEmpty;
    if (!hasHear) return GameKind.cual;
    if (!hasCual) return GameKind.hear;
    final e = progress.word(w.word)?.ear;
    if (e == null) return GameKind.cual;
    if (lastWasMiss(e)) return GameKind.cual;
    return e.n.isEven ? GameKind.cual : GameKind.hear;
  }

  /// The place in a list of [length] sentences that the word's count gives: with both games taking turns each
  /// game sees every other count, so the count is halved.
  int sentenceIndex(RepasoWord w, int length, {required bool both}) {
    final n = progress.word(w.word)?.ear.n ?? 0;
    return (both ? n ~/ 2 : n) % length;
  }

  /// From [clips] (the candidates in order), the one at [start] or after it that is not the word's last sentence,
  /// not a sentence already used in this session, and not in [avoid]; failing that, the first that is not the last
  /// sentence and not used; then the first that is not the last sentence; [start] when every one is.
  int _pick(
    List<String> clips,
    int start,
    String word, {
    Set<String> avoid = const {},
  }) {
    bool last(String c) => clips.length > 1 && c == lastAsked[word];
    for (final skip in <bool Function(String)>[
      (c) => last(c) || used.contains(c) || avoid.contains(c),
      (c) => last(c) || used.contains(c),
      last,
    ]) {
      for (var d = 0; d < clips.length; d++) {
        final k = (start + d) % clips.length;
        if (!skip(clips[k])) return k;
      }
    }
    return start;
  }

  /// The scored item of [w].
  GameItem scoredItem(RepasoWord w) {
    final kind = scoredKind(w);
    final both = cualLines(w).isNotEmpty && hearSentences(w).isNotEmpty;
    if (kind == GameKind.cual) {
      final lines = cualLines(w);
      final k = _pick(
        [for (final l in lines) l.clip],
        sentenceIndex(w, lines.length, both: both),
        w.word,
      );
      used.add(lines[k].clip);
      return CualItem(
        word: w.word,
        pair: _pairOf[w.word]!,
        line: lines[k],
        rightPanel: rng.next() < .5 ? 0 : 1,
        asset: pictureAssetFor(w.word),
      );
    }
    final ss = hearSentences(w);
    // a ¿Qué oyes? sentence that is also one of the word's ¿Cuál? sentences only when there is no other: the next
    // review is most often ¿Cuál?, and must not be the same sentence
    final k = _pick(
      [for (final s in ss) s.clip],
      sentenceIndex(w, ss.length, both: both),
      w.word,
      avoid: {for (final l in cualLines(w)) l.clip},
    );
    used.add(ss[k].clip);
    return hearItem(w, ss[k]);
  }

  /// The ¿Qué oyes? item of [w] with [s]: the word and two wrong tiles, the word at a random place.
  HearItem hearItem(RepasoWord w, RepasoSentence s) {
    final wrong = (wrongTiles(w, s) ?? _fallbackWrongTiles(w, s))!;
    final at = (rng.next() * 3).floor();
    final tiles = [...wrong]..insert(at, w);
    return HearItem(
      word: w.word,
      sentence: s,
      tiles: [for (final t in tiles) t.word],
      answer: at,
      solo: [for (final t in tiles) t.solo],
    );
  }

  /// The queue: each word's scored item, and a play slot after every third.
  List<QueueEntry> queue(List<RepasoWord> words) {
    final q = <QueueEntry>[];
    for (var i = 0; i < words.length; i++) {
      q.add(QueueEntry.scored(scoredItem(words[i])));
      if ((i + 1) % repasoPlayEvery == 0) q.add(QueueEntry.slot());
    }
    return q;
  }

  // ---- play items

  /// The place in [playKinds] of the kind the next play slot tries first. The turn goes on from one session to the
  /// next (the session keeps it in the feature's own space): with three slots in a session of ten words, a turn that
  /// started again each session would never reach Dilo.
  int nextKind;

  /// The play item for a slot: the kinds in turn, from the one after the last given, skipping a kind with no
  /// material. [words]: the session's words, the ones asked just before the slot first. [canSay]: Dilo can run.
  /// Null when no kind has material.
  GameItem? playItem(List<RepasoWord> words, {required bool canSay}) {
    for (var d = 0; d < playKinds.length; d++) {
      final i = (nextKind + d) % playKinds.length;
      final item = switch (playKinds[i]) {
        GameKind.build => _build(words),
        GameKind.match => _match(words),
        GameKind.say => canSay ? _say(words) : null,
        _ => null,
      };
      if (item != null) {
        nextKind = (i + 1) % playKinds.length;
        return item;
      }
    }
    return null;
  }

  Iterable<RepasoSentence> _free(
    RepasoWord w,
    bool Function(RepasoSentence) ok,
  ) => [
    for (final k in w.sentences)
      if (ok(data.sentences[k]) &&
          finished(data.sentences[k].story) &&
          !used.contains(data.sentences[k].clip))
        data.sentences[k],
  ];

  /// The lower-case form of a word as a tile of Arma la frase: no signs.
  static String tileForm(String w, {Language? language}) {
    final lang = language ?? Language.spanish;
    return [for (final t in lang.tokens(w)) t.text.toLowerCase()].join(' ');
  }

  BuildItem? _build(List<RepasoWord> words) {
    for (final w in words) {
      final ss = shuffled(_free(w, (s) => s.forBuilding).toList(), rng);
      for (final s in ss) {
        final extra = wrongTiles(w, s, singleWords: true);
        if (extra == null) continue;
        final forms = [
          for (final e in extra) tileForm(e.word, language: language),
        ];
        if (forms.any(s.tokens.contains) || forms[0] == forms[1]) continue;
        var pool = shuffled([...s.tokens, ...forms], rng);
        if (_sameStart(pool, s.tokens)) pool = [...pool.skip(1), pool.first];
        used.add(s.clip);
        return BuildItem(
          word: w.word,
          sentence: s,
          order: s.tokens,
          pool: pool,
        );
      }
    }
    return null;
  }

  static bool _sameStart(List<String> pool, List<String> order) {
    for (var i = 0; i < order.length; i++) {
      if (pool[i] != order[i]) return false;
    }
    return true;
  }

  /// Whether [b] may sit in a matching round beside the sentence [s] of [a]: [b] is not in it, not forbidden beside
  /// it, and must not meet [a] or a tracked word of it.
  bool _apartFrom(RepasoWord a, RepasoSentence s, RepasoWord b) {
    final inSentence = _wordsIn(s);
    if (s.forbidden.contains(b.word)) return false;
    if (a.apart.contains(b.word) || b.apart.contains(a.word)) return false;
    for (final x in s.forbidden) {
      if (data.word(x)?.apart.contains(b.word) ?? false) return false;
    }
    return !_tokensOf(b.word).any(inSentence.contains);
  }

  MatchItem? _match(List<RepasoWord> words) {
    final ws = <RepasoWord>[];
    final ss = <RepasoSentence>[];
    for (final w in words) {
      if (ws.length == 4) break;
      if (ws.any((x) => x.word == w.word)) continue;
      for (final s in shuffled(_free(w, (s) => s.forHearing).toList(), rng)) {
        var ok = true;
        for (var i = 0; i < ws.length && ok; i++) {
          ok = _apartFrom(w, s, ws[i]) && _apartFrom(ws[i], ss[i], w);
        }
        if (ok && !ss.any((x) => x.clip == s.clip)) {
          ws.add(w);
          ss.add(s);
          break;
        }
      }
    }
    if (ws.length < 4) return null;
    used.addAll([for (final s in ss) s.clip]);
    var order = shuffled([0, 1, 2, 3], rng);
    if (order.join() == '0123') order = [1, 2, 3, 0];
    return MatchItem(
      words: [for (final w in ws) w.word],
      sentences: ss,
      wordOrder: order,
    );
  }

  SayItem? _say(List<RepasoWord> words) {
    for (final w in words) {
      if (!progress.openForSpeaking(w.word)) continue;
      final ls = [
        for (final l in w.say)
          if (finished(l.story) && !used.contains(l.clip)) l,
      ];
      if (ls.isEmpty) continue;
      final l = ls[(rng.next() * ls.length).floor()];
      used.add(l.clip);
      return SayItem(word: w.word, line: l);
    }
    return null;
  }
}
