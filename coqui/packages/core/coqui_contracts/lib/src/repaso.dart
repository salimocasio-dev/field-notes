/// Repaso as games (docs/proyecto/15-repaso-juegos.md, "The data"): what the app reads from
/// `historia/datos/repaso.json`, the file `coqui/tool/make_repaso.py --app` writes.
///
/// A sentence is kept once in [RepasoData.sentences]; a word names its sentences by their place there. Every
/// sentence names the story it was recorded in ([RepasoSentence.story]): the app offers it only once he has
/// finished that story.
library;

import 'package:coqui_contracts/src/course.dart';
import 'package:coqui_contracts/src/json.dart';
import 'package:coqui_contracts/src/language.dart';
import 'package:coqui_contracts/src/progress.dart';

/// How a word's Ear is scored (`puntua`): by ¿Cuál? and ¿Qué oyes?, by ¿Qué oyes? only, or by no game.
/// A word with a picture pair is `cual` in the file; it gets ¿Qué oyes? too when it has sentences for it.
enum RepasoScoring { cual, queOyes, none }

RepasoScoring _scoring(Object? v) => switch (v) {
  'cual' => RepasoScoring.cual,
  'que_oyes' => RepasoScoring.queOyes,
  _ => RepasoScoring.none,
};

/// A recorded sentence ("frases" of the file). [tokens]: its words, lower case, no punctuation, the speaker tag
/// left out. [forbidden] (`prohibidas`): the tracked words that are in it (accents folded, a plural counted), never
/// a wrong written tile beside it. [picture] (`img`): its book picture (`img/<file>`, as a book page names it)
/// when the readers judged that the picture shows it, else null. [forHearing] (`oyes`): usable for ¿Qué oyes?;
/// [forBuilding] (`arma`): usable for Arma la frase.
class RepasoSentence {
  RepasoSentence({
    required this.clip,
    required this.story,
    required this.text,
    required this.tokens,
    required this.forbidden,
    this.picture,
    required this.forHearing,
    required this.forBuilding,
  });

  factory RepasoSentence.fromJson(Map<String, dynamic> j) => RepasoSentence(
    clip: j['clip'] as String,
    story: j['cuento'] as String,
    text: j['text'] as String,
    tokens: jsonStrings(j['tokens']),
    forbidden: jsonStrings(j['prohibidas']),
    picture: j['img'] as String?,
    forHearing: j['oyes'] == true,
    forBuilding: j['arma'] == true,
  );

  final String clip;
  final String story;
  final String text;
  final List<String> tokens;
  final List<String> forbidden;
  final String? picture;
  final bool forHearing;
  final bool forBuilding;
}

/// One sentence of a word's ¿Cuál? (`cual`): the word's picture pair with this sentence. [story] is null for the
/// pair's own sentence (always there, as today's Repaso has it).
class RepasoPairLine {
  RepasoPairLine({required this.clip, required this.text, this.story});

  factory RepasoPairLine.fromJson(Map<String, dynamic> j) => RepasoPairLine(
    clip: j['clip'] as String,
    text: j['text'] as String,
    story: j['cuento'] as String?,
  );

  final String clip;
  final String text;
  final String? story;
}

/// A ¿Dónde? item (`donde`): the sentence (by its place in [RepasoData.sentences]; its [RepasoSentence.picture]
/// is the right picture) and the fair wrong pictures of the same story ([others], `otras`), farthest first.
class RepasoWhere {
  RepasoWhere({required this.sentence, required this.others});

  factory RepasoWhere.fromJson(Map<String, dynamic> j) => RepasoWhere(
    sentence: jsonInt(j['frase']),
    others: jsonStrings(j['otras']),
  );

  final int sentence;
  final List<String> others;
}

/// A Dilo line (`dilo`): the line he says ([clip], [text], recorded in [story]), the forms that count as heard
/// right ([forms], `formas`), the clip that comes just before it in its story ([before], `antes`: what he hears),
/// and the line's book picture when the readers judged it to show it ([picture]).
class RepasoSay {
  RepasoSay({
    required this.clip,
    required this.story,
    required this.text,
    required this.forms,
    required this.before,
    this.picture,
  });

  factory RepasoSay.fromJson(Map<String, dynamic> j) => RepasoSay(
    clip: j['clip'] as String,
    story: j['cuento'] as String,
    text: j['text'] as String,
    forms: jsonStrings(j['formas']),
    before: j['antes'] as String,
    picture: j['img'] as String?,
  );

  final String clip;
  final String story;
  final String text;
  final List<String> forms;
  final String before;
  final String? picture;
}

/// One tracked word (`palabras`): [word] (`w`), its [place] (`lugar`, a place id), how it is scored ([scoring],
/// `puntua`), the clip of the word said alone when there is one ([solo]), the other words never shown beside
/// it ([apart], `no_juntas`), its ¿Cuál? sentences ([pairLines], `cual`), its sentences for ¿Qué oyes? and Arma la
/// frase in their fixed order ([sentences], `frases`: places in [RepasoData.sentences]), its ¿Dónde? items
/// ([where], `donde`) and its Dilo lines ([say], `dilo`).
class RepasoWord {
  RepasoWord({
    required this.word,
    required this.place,
    required this.scoring,
    this.solo,
    this.apart = const [],
    this.pairLines = const [],
    this.sentences = const [],
    this.where = const [],
    this.say = const [],
  });

  factory RepasoWord.fromJson(Map<String, dynamic> j) => RepasoWord(
    word: j['w'] as String,
    place: j['lugar'] as String,
    scoring: _scoring(j['puntua']),
    solo: j['solo'] as String?,
    apart: jsonStrings(j['no_juntas']),
    pairLines: [
      for (final x in (j['cual'] as List?) ?? const [])
        RepasoPairLine.fromJson(jsonMap(x)),
    ],
    sentences: [for (final x in (j['frases'] as List?) ?? const []) jsonInt(x)],
    where: [
      for (final x in (j['donde'] as List?) ?? const [])
        RepasoWhere.fromJson(jsonMap(x)),
    ],
    say: [
      for (final x in (j['dilo'] as List?) ?? const [])
        RepasoSay.fromJson(jsonMap(x)),
    ],
  );

  final String word;
  final String place;
  final RepasoScoring scoring;
  final String? solo;
  final List<String> apart;
  final List<RepasoPairLine> pairLines;
  final List<int> sentences;
  final List<RepasoWhere> where;
  final List<RepasoSay> say;
}

/// The whole file. [fromJson] throws a [FormatException] on a file it cannot read as this (a wrong version, a
/// word naming a sentence that is not there).
class RepasoData {
  RepasoData({required this.sentences, required this.words});

  /// The version of the file this reads (`v`).
  static const int version = 1;

  factory RepasoData.fromJson(Map<String, dynamic> j) {
    if (j['v'] != version) {
      throw FormatException('repaso.json: version ${j['v']}, not $version');
    }
    final sentences = [
      for (final x in j['frases'] as List) RepasoSentence.fromJson(jsonMap(x)),
    ];
    final words = [
      for (final x in j['palabras'] as List) RepasoWord.fromJson(jsonMap(x)),
    ];
    for (final w in words) {
      final refs = [...w.sentences, for (final d in w.where) d.sentence];
      for (final k in refs) {
        if (k < 0 || k >= sentences.length) {
          throw FormatException(
            'repaso.json: ${w.word} names sentence $k of ${sentences.length}',
          );
        }
      }
    }
    return RepasoData(sentences: sentences, words: words);
  }

  final List<RepasoSentence> sentences;
  final List<RepasoWord> words;

  late final Map<String, RepasoWord> _byWord = {
    for (final w in words) w.word: w,
  };

  /// The word's entry, by its exact text; null when the file has none.
  RepasoWord? word(String w) => _byWord[w];
}

/// What a course catalog that has read `datos/repaso.json` also gives.
///
/// Not a member of `CourseCatalog` (order 27 asked for one): a new member there would break every catalog that
/// implements `CourseCatalog` outside the packages that order may change (feature_library's and feature_story's
/// test catalogs). A catalog that reads the file implements this as well; Repaso asks `course is RepasoCatalog`.
abstract interface class RepasoCatalog {
  /// The file, read by `load()`; null when it is missing or cannot be read (Repaso then plays today's ¿Cuál?).
  RepasoData? get repaso;
}

// ---- which words Repaso can serve (one rule, for the session and for every count shown outside it)

/// Whether he has finished the story [id]: played it to its end (a story the level check only presumed does not
/// count until he plays it), or, a picture story, heard it to its end.
bool repasoStoryFinished(ProgressStore p, String id) {
  final r = p.story(id);
  if (r != null) {
    final presumed = r.presunto != null && r.presunto != 0 ? 1 : 0;
    if (r.n > presumed) return true;
  }
  final oidos = p.raw['oidos'];
  if (oidos is Map) {
    final v = oidos[id];
    if (v is num && v > 0) return true;
  }
  return false;
}

/// The words of [s], lower case, accents and signs gone (`Language.spanish.normalize`, PAL.norm, split).
List<String> repasoTokens(String s) => [
  for (final t in Language.spanish.normalize(s).trim().split(' '))
    if (t.isNotEmpty) t,
];

/// What Repaso may ask of one learner now (page 15, "The session"): the sentences of the stories he has finished,
/// the words he has met, the course's picture pairs. The session's plan and the counts the Palabras tab and the map
/// show ("N words today") all ask this one place, so they cannot drift: a word can be served when ¿Cuál? has a
/// sentence of his for it (its picture pair and a finished story), or ¿Qué oyes? has one with two fair wrong tiles.
///
/// It reads the progress once as it is when asked for its first answer; make a new one for a new moment.
class RepasoServing {
  RepasoServing({
    required this.data,
    required this.progress,
    required Iterable<ReviewPair> pairs,
  }) : _pairWords = {for (final p in pairs) p.word};

  final RepasoData data;
  final ProgressStore progress;
  final Set<String> _pairWords;

  final Map<String, bool> _finished = {};

  /// Whether the story is finished (null: a sentence of the pair itself, always his).
  bool finished(String? story) =>
      story == null ||
      (_finished[story] ??= repasoStoryFinished(progress, story));

  /// The words he has met that the data knows, in the data's (course) order.
  late final List<RepasoWord> met = [
    for (final w in data.words)
      if (progress.word(w.word) != null) w,
  ];

  final Map<String, List<String>> _folded = {};
  List<String> _tokensOf(String s) => _folded[s] ??= repasoTokens(s);

  final Map<RepasoSentence, Set<String>> _inSentence = {};
  Set<String> _wordsIn(RepasoSentence s) =>
      _inSentence[s] ??= {..._tokensOf(s.text), ...s.tokens.expand(_tokensOf)};

  /// Whether the course has a picture pair for the word.
  bool hasPair(RepasoWord w) => _pairWords.contains(w.word);

  /// The word's ¿Cuál? sentences he may get: its pair's own, and the others whose story he has finished. None when
  /// the course has no pair for it.
  List<RepasoPairLine> cualLines(RepasoWord w) => !hasPair(w)
      ? const []
      : [
          for (final l in w.pairLines)
            if (finished(l.story)) l,
        ];

  bool _hearable(RepasoWord w, RepasoSentence s) =>
      s.forHearing && finished(s.story) && wrongTileChoices(w, s).length >= 2;

  /// The word's ¿Qué oyes? sentences he may get, in the fixed order: from finished stories, with two fair wrong
  /// tiles among the words he has met.
  List<RepasoSentence> hearSentences(RepasoWord w) => [
    for (final k in w.sentences)
      if (_hearable(w, data.sentences[k])) data.sentences[k],
  ];

  /// Whether some game can score the word now.
  bool servable(RepasoWord w) =>
      cualLines(w).isNotEmpty ||
      w.sentences.any((k) => _hearable(w, data.sentences[k]));

  /// Whether Repaso can serve the word [text] now: the data knows it and some game can score it.
  bool canServe(String text) {
    final w = data.word(text);
    return w != null && servable(w);
  }

  /// The words other than [target] that may stand as a wrong written tile beside [s], in the data's order: words he
  /// has met, not in the sentence (none of their words is a word of it), not in its forbidden list, not in the
  /// `no_juntas` of the target or of any tracked word in the sentence.
  List<RepasoWord> wrongTileChoices(
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
}

/// What Repaso may serve this learner now, or null when the course has not read `datos/repaso.json` (then Repaso is
/// today's ¿Cuál?, which asks the words that have a picture pair, and the counts say the same).
RepasoServing? repasoServing(CourseCatalog course, ProgressStore progress) {
  final c = course;
  if (c is! RepasoCatalog) return null;
  final d = (c as RepasoCatalog).repaso;
  if (d == null) return null;
  return RepasoServing(data: d, progress: progress, pairs: course.pairs);
}
