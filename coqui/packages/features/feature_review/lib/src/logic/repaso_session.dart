/// Repaso as games: the running session (docs/proyecto/15-repaso-juegos.md, "The session", "The games", "What is
/// written to his progress"). The plan (repaso_plan.dart) decides what is asked; this plays it and writes what page
/// 15 says: an Ear answer for ¿Cuál? and ¿Qué oyes? exactly as Repaso writes today, a Mouth answer for Dilo (right
/// when heard right, wrong when two spoken attempts fail), nothing for the other play games, and the session's time
/// to the day's minutes.
///
/// Plain Dart on the host's wait, like the old session: a test runs it on a virtual clock with no screen.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show CoquiLabels, DashMark, PictureRef;
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/review_session.dart'
    show OptionRing, ReviewOptions, reviewSilence;
import 'package:feature_review/src/logic/word_picture.dart';

/// The page's own English lines (menus and labels; nothing in a game is English but these).
abstract final class RepasoStrings {
  static const startHint =
      'Listen, then answer. Each word comes back in a new sentence.';
  static const doneTitle = 'Done';
  static const next = 'Next';
  static const cantSpeak = "Can't speak now";
  static const nothingHeard = 'Nothing heard';
  static const listening = 'Listening…';
  static const tryAgain = 'Try again';
  static const sayTargetWord = 'Word to say';
  static const gotItFirst = 'Got it the first time';
  static String heard(String what) => 'Heard: $what';

  /// The end screen's headline: how many of the session's scored words he got right the first time.
  static String rightFirst(int n, int of) =>
      '$n of $of words right the first time';
  static String inARow(int n) => '$n in a row';
}

/// The streak chip shows from this many right answers in a row.
const int repasoStreakFrom = 3;

/// One picture or tile of an item, as the screen shows it.
class Choice {
  Choice({this.label = '', this.clip, this.right = false});

  /// The written word of a tile ('' for a picture or a speaker).
  final String label;

  /// The clip its speaker plays, or null.
  final String? clip;

  /// Whether it is the answer.
  final bool right;

  /// While the sentence plays: shown, not yet touchable.
  bool pre = true;

  /// The one that is not it, after an answer.
  bool dim = false;
  OptionRing ring = OptionRing.none;

  /// The check badge of a right answer.
  bool check = false;

  /// The X badge of a wrong touch (the corner where the check goes).
  bool cross = false;

  /// Parejas: the number of the pair this tile is in (1 to 4, in the order matched), beside the check.
  int? number;

  /// The sign (the pointing hand): touch this one.
  bool sign = false;

  /// Arma la frase: the tile has gone onto the line (it is right, and stays). Parejas: the pair is found.
  bool done = false;

  /// Counts wrong touches, so the screen can shake the tile back.
  int shakes = 0;
}

/// The state of a Dilo turn's mic: [missed] is the mic of a turn whose two tries were not heard right (it shows the X).
enum MicState { dead, ready, listening, processing, ok, missed }

/// What the end screen lists for one word: the sentence it was asked in.
class RepasoEndRow {
  RepasoEndRow(this.word, this.clip, this.text, {required this.ok});
  final String word;
  final String clip;
  final String text;
  final bool ok;
}

class RepasoEndGroup {
  RepasoEndGroup(this.title, this.sub, this.rows);
  final String title;
  final String sub;
  final List<RepasoEndRow> rows;
}

class RepasoEnd {
  RepasoEnd({
    required this.right,
    required this.of,
    required this.practice,
    required this.summary,
    required this.groups,
  });
  final int right;
  final int of;
  final bool practice;
  final String summary;
  final List<RepasoEndGroup> groups;
}

/// A scored answer (as the old session keeps them).
class RepasoAnswer {
  RepasoAnswer(
    this.word,
    this.kind, {
    required this.ok,
    required this.ms,
    this.auto = false,
  });
  final String word;
  final GameKind kind;
  final bool ok;
  final int ms;
  final bool auto;
}

class RepasoSession extends LessonBase {
  RepasoSession({
    required this.data,
    required Rng rng,
    required super.clock,
    required super.course,
    required this.progress,
    required super.clips,
    required super.wait,
    this.speech,
    this.storage,
    this.options = const ReviewOptions(),
    this.warm,
    this.wordAssets = const {},
  }) : super(captions: CaptionMode.never) {
    // one seed for the session: every choice of the plan follows from it
    seed = (rng.next() * 4294967296).floor();
    _last = LastAsked(storage);
    planner = RepasoPlanner(
      data: data,
      progress: progress,
      pairs: course.pairs,
      rng: Mulberry32(seed),
      language: course.language,
      lastAsked: _last.read(),
      nextKind: _last.readKind(),
      wordAssets: wordAssets,
    );
  }

  final RepasoData data;
  final ProgressStore progress;
  final SpeechListener? speech;

  /// The feature's own storage space (the last sentence of each word).
  final KeyValueStore? storage;
  final ReviewOptions options;
  final void Function(List<PictureRef> refs)? warm;
  final Map<String, WordPictureAsset> wordAssets;

  late final int seed;
  late final RepasoPlanner planner;
  late final LastAsked _last;

  // ---- the session
  List<RepasoWord> words = const [];
  bool practice = false;
  List<QueueEntry> queue = [];
  int index = 0;
  int returns = 0;
  bool running = false;
  final List<RepasoAnswer> answers = [];
  final List<RepasoAnswer> secondAnswers = [];
  RepasoEnd? end;

  /// How each planned item's first answer went (the bar's colours). Set once, at the item's first answer, and kept to
  /// the end: a return answers an item that is already marked and repaints nothing.
  final Map<QueueEntry, DashMark> _marks = {};

  /// The planned items of the queue, in order (the bar has one dash for each; a return has none of its own).
  List<QueueEntry> get _planned => [
    for (final q in queue)
      if (!q.again) q,
  ];

  /// The bar's colours, one for each planned item: green when its first answer was right, red-orange when it was wrong,
  /// the neutral grey of [DashMark.skipped] when it was skipped ("Can't speak now"), the grey of "not reached" before.
  List<DashMark> get barMarks => [
    for (final q in _planned) _marks[q] ?? DashMark.none,
  ];

  /// The dash of the item on screen (a return is the item it answers again), or null when none is.
  int? get barCurrent {
    final q = entry;
    if (q == null || screen != LessonScreen.play) return null;
    final own = q.again ? q.origin : q;
    if (own == null) return null;
    final i = _planned.indexOf(own);
    return i < 0 ? null : i;
  }

  /// The item on screen has been answered for the first time: its dash takes the colour [m] and keeps it. Only the
  /// first answer counts (a wrong touch is not undone by the right one after it), and a return counts for nothing.
  void _mark(DashMark m) {
    final q = entry;
    if (q == null || q.again || _marks.containsKey(q)) return;
    _marks[q] = m;
    changed();
  }

  /// Right answers in a row (shown from three up).
  int streak = 0;

  /// How many pictures a ¿Dónde? item has: 3, or 2 when the screen has no room for three of them at 150 px wide at
  /// least (the screen says, before the session runs).
  int wherePictures = 3;

  /// Dilo is off for this session ("Can't speak now", or speaking cannot work here).
  bool sayOff = false;
  bool _speechOk = false;

  /// Every item that was played, in order (a test and the screenshots read it).
  final List<QueueEntry> played = [];

  // ---- the item on screen
  QueueEntry? entry;
  GameItem? get item => entry?.item;
  bool get again => entry?.again ?? false;

  /// The pictures (¿Cuál?, ¿Dónde?) or tiles (¿Qué oyes?, Arma la frase, Parejas' words) of the item.
  List<Choice> choices = [];

  /// Parejas' speakers.
  List<Choice> speakers = [];
  int? selectedSpeaker;

  /// Arma la frase: the choices put on the line so far, one after another (each is the next word of the sentence: a
  /// wrong one never goes on the line, and one that is on it stays).
  List<int> placed = [];

  /// Arma la frase: the words on the line so far, in order.
  List<String> get built => [for (final k in placed) choices[k].label];

  /// His turn: the sentence has ended.
  bool yourTurn = false;

  /// The sentence shows as text (with the word lit, ¿Qué oyes?), and its story picture where there is one: the
  /// reveal, once the item is answered.
  bool showText = false;

  /// The Next button is there.
  bool canNext = false;

  /// Dilo.
  MicState mic = MicState.dead;
  String heard = '';
  bool heardRight = false;

  /// Dilo: a try was made and was not heard right (what was heard shows; "Try again" if one is left).
  bool notHeard = false;

  // the clip sounding now (the round speaker pulses while the item's sentence is)
  String? _playingId;
  int _playTok = 0;

  /// The item's sentence is sounding now.
  bool get sentencePlaying {
    final id = _playingId;
    return id != null && id == item?.clip;
  }

  @override
  Future<bool> playClip(String id) async {
    final mine = ++_playTok;
    _playingId = id;
    changed();
    try {
      return await super.playClip(id);
    } finally {
      if (_playTok == mine) {
        _playingId = null;
        changed();
      }
    }
  }

  // touches go here
  void Function(int k)? _onChoice;
  void Function(int k)? _onSpeaker;
  void Function()? _onSentence;
  void Function()? _onNext;
  void Function()? _onMic;

  void touch(int k) => _onChoice?.call(k);

  /// A tile's own speaker (a word said alone in ¿Qué oyes?, a sentence in Parejas).
  void touchSpeaker(int k) => _onSpeaker?.call(k);

  /// The game's round speaker: the sentence again.
  void replay() => _onSentence?.call();
  void pressNext() => _onNext?.call();
  void pressMic() => _onMic?.call();

  int _t0 = 0;
  bool _started = false;
  bool _minutesAdded = false;
  int _lastSpeakerTap = -1;

  // ---- the start screen

  void prepare() {
    final ws = planner.sessionWords(
      cap: options.cap,
      only: options.only,
      all: options.all,
    );
    words = ws.words;
    practice = ws.practice;
    queue = planner.queue(words);
    makeDots(queue.length);
    setScreen(LessonScreen.start);
    final n = words.length;
    final items = queue.length;
    final m = ((items * 17 / 60) + .5).floor();
    showScreen(CoquiLabels.review, [
      RepasoStrings.startHint,
      if (n != 0) '$n word${n == 1 ? '' : 's'} · about ${m < 1 ? 1 : m} min',
    ]);
    loadVoice({
      // each scored item's sentence, and the clips of its word tiles said alone (¿Qué oyes?: a touch on a tile's speaker
      // plays one, and must not wait for a fetch)
      for (final q in queue)
        if (q.item case final it?) ...[?it.clip, ..._clipsOf(it)],
      course.fixedClip('review_praise_right'),
      course.fixedClip('review_praise_after_miss'),
    });
  }

  // ---- running it

  Future<void> run() async {
    beginRun();
    running = true;
    _started = true;
    _t0 = clock.nowMs();
    setScreen(LessonScreen.play);
    showScreen('');
    _speechOk = await _speechAvailable();
    await Future.any<void>([voiceReady, sleep(6000)]);
    try {
      for (var i = 0; i < queue.length; i++) {
        index = i;
        final q = queue[i];
        if (q.slot) {
          final recent = _recentFirst(i);
          q.item = planner.playItem(recent, canSay: _canSay);
          if (q.item == null) {
            // no game has material for this place: it is not asked, and the bar has no dash for it
            queue.removeAt(i);
            i--;
            makeDots(_planned.length);
            continue;
          }
          _last.writeKind(planner.nextKind);
          unawaited(clips.preload([?q.item!.clip, ..._clipsOf(q.item!)]));
        }
        final ok = await _play(q);
        if (!q.again && q.item!.scored && !ok && returns < repasoMaxReturns) {
          returns++;
          final at = i + repasoReturnAfter < queue.length
              ? i + repasoReturnAfter
              : queue.length;
          queue.insert(at, QueueEntry.again(_rearranged(q.item!), origin: q));
          changed();
        }
      }
    } on SessionStopped {
      return;
    }
    _clear();
    running = false;
    _addMinutes();
    _finish();
  }

  /// A missed item as it comes back: the same sentence and game, the pictures or tiles in another order (never the
  /// identical arrangement).
  GameItem _rearranged(GameItem it) => switch (it) {
    CualItem() => it.rearranged(),
    HearItem() => it.rearranged(planner.rng.next()),
    _ => it,
  };

  Future<bool> _speechAvailable() async {
    final s = speech;
    if (s == null) return false;
    try {
      return await s.available();
    } catch (_) {
      return false;
    }
  }

  bool get _canSay => !sayOff && _speechOk && progress.setting('habla') != 0;

  // the session's words, the three asked just before slot i first
  List<RepasoWord> _recentFirst(int i) {
    final recent = <RepasoWord>[];
    for (var k = i - 1; k >= 0 && recent.length < repasoPlayEvery; k--) {
      final it = queue[k].item;
      if (it == null || !it.scored || queue[k].again) continue;
      final w = data.word(it.word);
      if (w != null && !recent.contains(w)) recent.add(w);
    }
    return [
      ...recent,
      for (final w in words)
        if (!recent.contains(w)) w,
    ];
  }

  Iterable<String> _clipsOf(GameItem it) => switch (it) {
    MatchItem(:final sentences) => [for (final s in sentences) s.clip],
    HearItem(:final solo, :final speakers) => [if (speakers) ...solo.nonNulls],
    _ => const [],
  };

  void _clear() {
    choices = [];
    speakers = [];
    selectedSpeaker = null;
    placed = [];
    yourTurn = false;
    showText = false;
    canNext = false;
    mic = MicState.dead;
    heard = '';
    heardRight = false;
    notHeard = false;
    _praiseToken++;
    _onChoice = null;
    _onSpeaker = null;
    _onSentence = null;
    _onNext = null;
    _onMic = null;
    hideCaption();
  }

  Future<bool> _play(QueueEntry q) async {
    _clear();
    entry = q;
    played.add(q);
    changed();
    final it = q.item!;
    return switch (it) {
      CualItem() => _cual(it, q.again),
      HearItem() => _hear(it, q.again),
      BuildItem() => _build(it),
      MatchItem() => _match(it),
      WhereItem() => _where(it),
      SayItem() => _say(it),
    };
  }

  void _right() {
    streak++;
    changed();
  }

  void _wrong() {
    streak = 0;
    changed();
  }

  /// Waits for [p] or the silence of the scored games: 6 s after the sentence it plays again (a touch while it plays
  /// counts); 6 s more, and the answer is shown. A speaker touched on a tile counts as not silent. True: he touched.
  Future<bool> _silence(Completer<void> p, String clip) async {
    Future<void> quiet() async {
      for (;;) {
        await Future.any<void>([p.future, waitMs(reviewSilence)]);
        if (p.isCompleted) return;
        final since = clock.nowMs() - _lastSpeakerTap;
        if (_lastSpeakerTap < 0 || since >= reviewSilence) return;
      }
    }

    await quiet();
    if (p.isCompleted) return true;
    await Future.any<void>([p.future, say(clip, 0)]);
    if (p.isCompleted) return true;
    await quiet();
    return p.isCompleted;
  }

  /// Writes a scored answer (cual.js: an Ear answer; intro when the word is not due, as in a practice session).
  void _score(
    GameItem it, {
    required bool ok,
    required int ms,
    bool auto = false,
  }) {
    final due = progress.due(Skill.ear).contains(it.word);
    progress.answer(it.word, Skill.ear, ok: ok, ms: ms, intro: !due);
    if (it.clip != null) _last.write(it.word, it.clip!);
    answers.add(RepasoAnswer(it.word, it.kind, ok: ok, ms: ms, auto: auto));
  }

  /// A wrong touch: the red-orange ring and, at the corner where a right one has its check, the round X badge. It
  /// stays until the item is over.
  void _markWrong(Choice c) {
    c
      ..ring = OptionRing.bad
      ..cross = true;
  }

  /// The right one is marked with the sign (the pointing hand) and he must touch it. It has no ring until he does:
  /// a green ring before the touch would read as a hit. When he touches it, it gets the green ring and the check.
  Future<void> _touchShown(int k) async {
    choices[k].sign = true;
    changed();
    final p = Completer<void>();
    _onChoice = (j) {
      if (j == k && !p.isCompleted) p.complete();
    };
    await p.future;
    choices[k]
      ..sign = false
      ..ring = OptionRing.ok
      ..check = true;
    _onChoice = null;
    changed();
  }

  /// Waits for the Next button.
  Future<void> _waitNext() async {
    canNext = true;
    changed();
    final p = Completer<void>();
    _onNext = () {
      if (!p.isCompleted) p.complete();
    };
    await p.future;
    canNext = false;
    _onNext = null;
  }

  // the praise that plays while the item waits for Next; Next cuts it short, and a praise that has not started yet
  // when Next is pressed never does
  int _praiseToken = 0;

  Future<void> _praise(String clip) async {
    final my = ++_praiseToken;
    try {
      await waitMs(300);
      if (my != _praiseToken) return;
      await say(clip, 0);
    } on SessionStopped {
      // the lesson was left
    }
  }

  /// The item is answered: its reveal (the sentence as text, its story picture where it has one) and the Next button
  /// show at once, the praise plays meanwhile, and the item waits for Next.
  Future<void> _revealAndNext(String praiseClip) async {
    showText = true;
    canNext = true;
    changed();
    unawaited(_praise(praiseClip));
    final p = Completer<void>();
    _onNext = () {
      if (!p.isCompleted) p.complete();
    };
    await p.future;
    _praiseToken++;
    hush();
    canNext = false;
    _onNext = null;
  }

  /// The round speaker of a game that plays a sentence: while the sentence has not yet ended (and for a scored game
  /// while he cannot answer), a touch on it does nothing; after, it plays the sentence again.
  void _replayWith(String clip, bool Function() ready, {bool silence = false}) {
    _onSentence = () {
      if (!ready()) return;
      if (silence) _lastSpeakerTap = clock.nowMs();
      hush();
      unawaited(playClip(clip));
    };
  }

  // ---- ¿Cuál? (scored): cual.js cualItem, with this item's sentence

  Future<bool> _cual(CualItem it, bool again) async {
    final asset = it.asset;
    if (asset == null || !asset.isUsable) {
      // Unrenderable item: do not score or write Ear progress; return true only to suppress miss re-queueing.
      _mark(DashMark.skipped);
      return true;
    }
    choices = [for (var k = 0; k < 2; k++) Choice(right: k == it.rightPanel)];
    changed();
    await waitMs(500);
    int? got;
    var ms = 0;
    int? tEnd;
    final p = Completer<void>();
    _onChoice = (k) {
      if (tEnd == null || got != null) return;
      got = k;
      ms = clock.nowMs() - tEnd;
      if (!p.isCompleted) p.complete();
    };
    _lastSpeakerTap = -1;
    _replayWith(it.clip, () => tEnd != null && got == null, silence: true);
    await say(it.clip, 0);
    tEnd = clock.nowMs();
    for (final c in choices) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    final touched = await _silence(p, it.clip);
    final auto = !touched;
    if (auto) {
      ms = clock.nowMs() - tEnd;
    } else if (speaking > 0) {
      hush();
    }
    _onChoice = null;
    _onSentence = null;
    final right = !auto && choices[got!].right;
    _mark(right ? DashMark.right : DashMark.wrong);
    if (!again) {
      _score(it, ok: right, ms: ms, auto: auto);
    } else {
      secondAnswers.add(RepasoAnswer(it.word, it.kind, ok: right, ms: ms));
    }
    if (right) {
      _right();
      choices[got!]
        ..ring = OptionRing.ok
        ..check = true;
      choices[1 - got!].dim = true;
      changed();
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      final k = choices.indexWhere((c) => c.right);
      if (!auto) {
        sfxBonk();
        _markWrong(choices[got!]);
        changed();
        await waitMs(500);
      }
      await _touchShown(k);
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_after_miss'));
    }
    return right;
  }

  // ---- ¿Qué oyes? (scored)

  Future<bool> _hear(HearItem it, bool again) async {
    choices = [
      for (var k = 0; k < it.tiles.length; k++)
        Choice(
          label: it.tiles[k],
          // a speaker on the tiles only when every tile of the item has a clip of its word alone
          clip: it.speakers ? it.solo[k] : null,
          right: k == it.answer,
        ),
    ];
    changed();
    await waitMs(500);
    int? got;
    var ms = 0;
    int? tEnd;
    final p = Completer<void>();
    _onChoice = (k) {
      if (tEnd == null || got != null) return;
      got = k;
      ms = clock.nowMs() - tEnd;
      if (!p.isCompleted) p.complete();
    };
    _lastSpeakerTap = -1;
    // a tile's speaker plays the word alone, once the sentence has ended
    _onSpeaker = (k) {
      final c = choices[k].clip;
      if (tEnd == null || c == null || got != null) return;
      _lastSpeakerTap = clock.nowMs();
      hush();
      unawaited(playClip(c));
    };
    _replayWith(it.clip, () => tEnd != null && got == null, silence: true);
    await say(it.clip, 0);
    tEnd = clock.nowMs();
    for (final c in choices) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    final touched = await _silence(p, it.clip);
    final auto = !touched;
    if (auto) {
      ms = clock.nowMs() - tEnd;
    } else if (speaking > 0) {
      hush();
    }
    _onChoice = null;
    _onSpeaker = null;
    _onSentence = null;
    final right = !auto && choices[got!].right;
    _mark(right ? DashMark.right : DashMark.wrong);
    if (!again) {
      _score(it, ok: right, ms: ms, auto: auto);
    } else {
      secondAnswers.add(RepasoAnswer(it.word, it.kind, ok: right, ms: ms));
    }
    if (right) {
      _right();
      choices[got!]
        ..ring = OptionRing.ok
        ..check = true;
      for (var k = 0; k < choices.length; k++) {
        if (k != got) choices[k].dim = true;
      }
      changed();
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      if (!auto) {
        sfxBonk();
        _markWrong(choices[got!]);
        changed();
        await waitMs(500);
      }
      await _touchShown(it.answer);
      for (var k = 0; k < choices.length; k++) {
        if (k != it.answer && k != got) choices[k].dim = true;
      }
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_after_miss'));
    }
    return right;
  }

  // ---- Arma la frase (play)

  Future<bool> _build(BuildItem it) async {
    choices = [for (final t in it.pool) Choice(label: t)];
    placed = [];
    changed();
    var wrongs = 0;
    var listening = true;
    _replayWith(it.clip, () => !listening);
    final p = Completer<void>();
    _onChoice = (k) {
      if (listening || p.isCompleted) return;
      final c = choices[k];
      // a tile that is on the line is right, and stays: it cannot be taken back
      if (c.done) return;
      if (c.label == it.order[placed.length]) {
        // the next word of the sentence: it goes onto the line, with the green border at once
        c
          ..done = true
          ..ring = OptionRing.ok;
        placed.add(k);
        sfxBlip();
        changed();
        if (placed.length == it.order.length) p.complete();
      } else {
        // any other tile stays in the bank, red-orange with the X badge for about a second, then clears; the item
        // counts as missed, and he goes on
        wrongs++;
        _mark(DashMark.wrong);
        c
          ..shakes += 1
          ..ring = OptionRing.bad
          ..cross = true;
        sfxBonk();
        changed();
        final mine = c.shakes;
        unawaited(
          waitMs(1000).then((_) {
            if (c.shakes == mine && c.cross) {
              c
                ..cross = false
                ..ring = OptionRing.none;
              changed();
            }
          }, onError: (Object _) {}),
        );
      }
    };
    await waitMs(300);
    await say(it.clip, 0);
    listening = false;
    for (final c in choices) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    await p.future;
    _onChoice = null;
    _onSentence = null;
    _mark(wrongs == 0 ? DashMark.right : DashMark.wrong);
    if (wrongs == 0) {
      _right();
    } else {
      _wrong();
    }
    sfxRight();
    await _revealAndNext(course.fixedClip('review_praise_right'));
    return wrongs == 0;
  }

  // ---- Parejas (play)

  Future<bool> _match(MatchItem it) async {
    speakers = [
      for (var i = 0; i < it.words.length; i++)
        Choice(clip: it.sentences[i].clip),
    ];
    choices = [for (final k in it.wordOrder) Choice(label: it.words[k])];
    for (final c in [...speakers, ...choices]) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    var wrongs = 0;
    var found = 0;
    var flash = 0;
    final p = Completer<void>();
    // a wrong pair shows red-orange with the X on both tiles for about a second, then clears (a touch clears it too);
    // the sound stays chosen, so he can try another word
    void clearWrong() {
      for (var i = 0; i < speakers.length; i++) {
        if (speakers[i].cross) {
          speakers[i]
            ..cross = false
            ..ring = selectedSpeaker == i ? OptionRing.sel : OptionRing.none;
        }
      }
      for (final c in choices) {
        if (c.cross) {
          c
            ..cross = false
            ..ring = OptionRing.none;
        }
      }
    }

    _onSpeaker = (i) {
      if (speakers[i].done || p.isCompleted) return;
      clearWrong();
      selectedSpeaker = i;
      for (var j = 0; j < speakers.length; j++) {
        if (!speakers[j].done) {
          speakers[j].ring = j == i ? OptionRing.sel : OptionRing.none;
        }
      }
      changed();
      hush();
      unawaited(playClip(speakers[i].clip!));
    };
    _onChoice = (k) {
      final s = selectedSpeaker;
      if (s == null || choices[k].done || p.isCompleted) return;
      clearWrong();
      if (it.wordOrder[k] == s) {
        hush();
        found++;
        speakers[s]
          ..done = true
          ..ring = OptionRing.ok
          ..check = true
          ..number = found;
        choices[k]
          ..done = true
          ..ring = OptionRing.ok
          ..check = true
          ..number = found;
        selectedSpeaker = null;
        sfxRight();
        changed();
        if (found == it.words.length) p.complete();
      } else {
        // a slip resets the "in a row" count at once, like any wrong answer
        wrongs++;
        streak = 0;
        _mark(DashMark.wrong);
        speakers[s]
          ..ring = OptionRing.bad
          ..cross = true;
        choices[k]
          ..shakes += 1
          ..ring = OptionRing.bad
          ..cross = true;
        sfxBonk();
        changed();
        final mine = ++flash;
        unawaited(
          waitMs(1000).then((_) {
            if (mine == flash) {
              clearWrong();
              changed();
            }
          }, onError: (Object _) {}),
        );
      }
    };
    await p.future;
    _onChoice = null;
    _onSpeaker = null;
    _mark(wrongs == 0 ? DashMark.right : DashMark.wrong);
    if (wrongs == 0) _right();
    await _revealAndNext(course.fixedClip('review_praise_right'));
    return wrongs == 0;
  }

  // ---- ¿Dónde? (play)

  Future<bool> _where(WhereItem it) async {
    // as many pictures as the screen has room for (page 15: never three small ones; two big ones instead)
    final pics = it.picturesFor(wherePictures);
    if (pics.isEmpty || pics.any((p) => !isDedicatedWordAssetPath(p))) {
      _mark(DashMark.skipped);
      return true;
    }
    final answer = pics.indexOf(it.pictures[it.answer]);
    choices = [
      for (var k = 0; k < pics.length; k++)
        Choice(label: pics[k], right: k == answer),
    ];
    changed();
    var listening = true;
    _replayWith(it.clip, () => !listening);
    int? got;
    final p = Completer<void>();
    _onChoice = (k) {
      if (listening || got != null) return;
      got = k;
      if (!p.isCompleted) p.complete();
    };
    await waitMs(500);
    await say(it.clip, 0);
    listening = false;
    for (final c in choices) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    await p.future;
    _onChoice = null;
    if (speaking > 0) hush();
    final right = choices[got!].right;
    _mark(right ? DashMark.right : DashMark.wrong);
    if (right) {
      _right();
      choices[got!]
        ..ring = OptionRing.ok
        ..check = true;
      for (var k = 0; k < choices.length; k++) {
        if (k != got) choices[k].dim = true;
      }
      changed();
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      sfxBonk();
      _markWrong(choices[got!]);
      changed();
      await waitMs(500);
      await _touchShown(answer);
      for (var k = 0; k < choices.length; k++) {
        if (k != answer && k != got) choices[k].dim = true;
      }
      sfxRight();
      await _revealAndNext(course.fixedClip('review_praise_after_miss'));
    }
    _onSentence = null;
    return right;
  }

  // ---- Dilo (play): only a word open for speaking, a line with decided forms, the mic working, "Speak in
  // stories" on. Heard right: a Mouth answer right. Two spoken attempts not heard right: a Mouth miss. Mic
  // errors, silent/empty captures, and "Can't speak now" write nothing.

  /// "Can't speak now": no more Dilo this session; the item on screen ends.
  void cantSpeak() {
    sayOff = true;
    _cantSpeak?.call();
  }

  void Function()? _cantSpeak;

  Future<bool> _say(SayItem it) async {
    final done = Completer<void>();
    _cantSpeak = () {
      if (!done.isCompleted) done.complete();
    };
    var listening = false;
    _replayWith(it.line.clip, () => !listening && mic != MicState.ok);
    Future<void> turn() async {
      mic = MicState.dead;
      changed();
      await waitMs(300);
      await say(it.line.clip, 0);
      var spokenAttempts = 0;
      for (var attempt = 1; attempt <= 2 && !done.isCompleted; attempt++) {
        mic = MicState.ready;
        yourTurn = true;
        changed();
        final tap = Completer<void>();
        _onMic = () {
          if (mic == MicState.ready && !tap.isCompleted) tap.complete();
        };
        await Future.any<void>([tap.future, done.future]);
        _onMic = null;
        if (done.isCompleted) return;
        listening = true;
        hush();
        // the last try's line goes while the app listens again
        heard = '';
        notHeard = false;
        mic = MicState.listening;
        changed();
        SpeechResult r;
        final t = speech!.listen(
          locale: course.language.recognitionLocale,
          limit: const Duration(seconds: 6),
          maxAlternatives: 5,
        );
        unawaited(
          t.speechEnd.then((_) {
            if (mic == MicState.listening) {
              mic = MicState.processing;
              changed();
            }
          }, onError: (Object _) {}),
        );
        try {
          r = await Future.any<SpeechResult>([
            t.result,
            done.future.then((_) => SpeechResult(alternatives: const [])),
          ]);
        } catch (_) {
          r = SpeechResult(alternatives: const [], error: 'aborted');
        }
        listening = false;
        if (done.isCompleted) {
          t.cancel();
          return;
        }
        if (_nodisp.contains(r.error)) {
          // speaking cannot work here: no more Dilo this session, nothing written; the item is skipped
          sayOff = true;
          return;
        }
        final heardSpeech =
            r.error == null && r.alternatives.any((a) => a.trim().isNotEmpty);
        if (heardSpeech) spokenAttempts++;
        heard = r.alternatives.isEmpty ? '' : r.alternatives.first;
        if (repasoHeardRight(
          r.alternatives,
          it.line.forms,
          language: course.language,
        )) {
          heardRight = true;
          mic = MicState.ok;
          progress.answer(
            it.word,
            Skill.mouth,
            ok: true,
            ms: r.msToSound ?? 0,
            intro: false,
          );
          _mark(DashMark.right);
          _right();
          sfxRight();
          changed();
          return;
        }
        // not heard right: what the app heard shows, and "Try again" under the mic (with the X badge beside it) if a
        // try is left (the mic is ready again at once); after the second try the mic shows the X and rests a moment
        // before the model plays
        notHeard = true;
        if (attempt == 2) {
          if (spokenAttempts == 2) {
            progress.answer(
              it.word,
              Skill.mouth,
              ok: false,
              ms: r.msToSound ?? 0,
              intro: false,
            );
          }
          mic = MicState.missed;
          _mark(DashMark.wrong);
          changed();
          await waitMs(600);
        } else {
          changed();
        }
      }
      if (done.isCompleted) return;
      // two tries and not heard right: the line itself, the model (the mic keeps its X), and on
      await say(it.line.clip, 0);
    }

    await Future.any<void>([turn(), done.future]);
    _cantSpeak = null;
    _onMic = null;
    _onSentence = null;
    if (done.isCompleted || sayOff) {
      // "Can't speak now" (or speaking cannot work here): the item is skipped, neither right nor wrong
      hush();
      _mark(DashMark.skipped);
      return false;
    }
    showText = true;
    changed();
    await _waitNext();
    return heardRight;
  }

  // ---- the end

  void _finish() {
    final ups = <RepasoEndRow>[];
    final soon = <RepasoEndRow>[];
    for (final w in words) {
      RepasoAnswer? a;
      for (final x in answers) {
        if (x.word == w.word) {
          a = x;
          break;
        }
      }
      if (a == null) continue;
      GameItem? it;
      for (final q in played) {
        if (!q.again && q.item?.scored == true && q.item!.word == w.word) {
          it = q.item;
          break;
        }
      }
      final row = RepasoEndRow(w.word, it!.clip!, it.text!, ok: a.ok);
      (a.ok ? ups : soon).add(row);
    }
    final pr = practice;
    final total = ups.length + soon.length;
    end = RepasoEnd(
      right: ups.length,
      of: total,
      practice: pr,
      summary: RepasoStrings.rightFirst(ups.length, total),
      // the words he missed come first: they are what the end screen is for
      groups: [
        if (soon.isNotEmpty)
          RepasoEndGroup(
            pr ? ReviewStrings.missedHeading : ReviewStrings.comingBackHeading,
            pr ? '' : ReviewStrings.comingBackSub,
            soon,
          ),
        if (ups.isNotEmpty)
          RepasoEndGroup(
            pr ? ReviewStrings.rightHeading : RepasoStrings.gotItFirst,
            pr ? '' : ReviewStrings.movingUpSub,
            ups,
          ),
      ],
    );
    _clear();
    entry = null;
    setScreen(LessonScreen.end);
    showScreen(RepasoStrings.doneTitle, [end!.summary]);
  }

  /// A row of the end screen touched: its sentence plays.
  void playRow(RepasoEndRow r) {
    hush();
    unawaited(clips.play(r.clip));
  }

  void _addMinutes() {
    if (_minutesAdded || !_started) return;
    _minutesAdded = true;
    progress.addMinutes((clock.nowMs() - _t0) / 6e4);
  }

  @override
  void leave() {
    _addMinutes();
    super.leave();
  }

  @override
  void dispose() {
    if (running) _addMinutes();
    super.dispose();
  }
}

/// The errors that say speaking cannot work here (juego.js: `NODISP`).
const List<String> _nodisp = [
  'not-allowed',
  'service-not-allowed',
  'network',
  'audio-capture',
  'language-not-supported',
];

/// Heard right (docs/hablar/01-decisiones.md, "What counts as heard right"): one of the accepted [forms] is inside
/// one of the alternatives, whole words, accents/marks and case ignored through [language].
bool repasoHeardRight(
  List<String> alts,
  List<String> forms, {
  Language? language,
}) {
  final lang = language ?? Language.spanish;
  final ns = [for (final a in alts) lang.normalize(a)];
  return forms.any((f) {
    final g = lang.normalize(f).trim();
    return g.isNotEmpty && ns.any((a) => a.contains(' $g '));
  });
}
