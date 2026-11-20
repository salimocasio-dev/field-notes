/// Repaso as games: the running session (docs/proyecto/15-repaso-juegos.md, "The session", "The games", "What is
/// written to his progress"). The plan (repaso_plan.dart) decides what is asked; this plays it and writes what page
/// 15 says: an Ear answer for ¿Cuál? and ¿Qué oyes? exactly as Repaso writes today, a Mouth answer for Dilo heard
/// right, nothing for the other play games, and the session's time to the day's minutes.
///
/// Plain Dart on the host's wait, like the old session: a test runs it on a virtual clock with no screen.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show CoquiLabels, PictureRef;
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/review_session.dart'
    show OptionRing, ReviewOptions, reviewSilence;

/// The page's own English lines (menus and labels; nothing in a game is English but these).
abstract final class RepasoStrings {
  static const startHint =
      'Listen, then answer. Each word comes back in a new sentence.';
  static const doneTitle = 'Done';
  static const next = 'Next';
  static const cantSpeak = "Can't speak now";
  static const nothingHeard = 'Nothing heard';
  static String rightFirst(int n, int of) => '$n of $of right the first time';
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

  /// The one that is not it, after an answer; or a tile already placed.
  bool dim = false;
  OptionRing ring = OptionRing.none;

  /// The check badge of a right answer.
  bool check = false;

  /// The big sign: touch this one.
  bool sign = false;

  /// Arma la frase: the tile has gone up into the sentence. Parejas: the pair is found.
  bool done = false;

  /// Counts wrong touches, so the screen can shake the tile back.
  int shakes = 0;
}

/// The state of a Dilo turn's mic.
enum MicState { dead, ready, listening, processing, ok }

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
  }) : super(captions: CaptionMode.during) {
    // one seed for the session: every choice of the plan follows from it
    seed = (rng.next() * 4294967296).floor();
    _last = LastAsked(storage);
    planner = RepasoPlanner(
      data: data,
      progress: progress,
      pairs: course.pairs,
      rng: Mulberry32(seed),
      lastAsked: _last.read(),
      nextKind: _last.readKind(),
    );
  }

  final RepasoData data;
  final ProgressStore progress;
  final SpeechListener? speech;

  /// The feature's own storage space (the last sentence of each word).
  final KeyValueStore? storage;
  final ReviewOptions options;
  final void Function(List<PictureRef> refs)? warm;

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

  /// Right answers in a row (shown from three up).
  int streak = 0;

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

  /// Arma la frase: the words put in order so far.
  List<String> built = [];

  /// His turn: the sentence has ended.
  bool yourTurn = false;

  /// The sentence shows as text (with the word lit, ¿Qué oyes?).
  bool showText = false;

  /// The Next button is there.
  bool canNext = false;

  /// Dilo.
  MicState mic = MicState.dead;
  String heard = '';
  bool heardRight = false;

  // touches go here
  void Function(int k)? _onChoice;
  void Function(int k)? _onSpeaker;
  void Function()? _onNext;
  void Function()? _onMic;

  void touch(int k) => _onChoice?.call(k);
  void touchSpeaker(int k) => _onSpeaker?.call(k);
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
    makeDots(words.length);
    setScreen(LessonScreen.start);
    final n = words.length;
    final items = queue.length;
    final m = ((items * 17 / 60) + .5).floor();
    showScreen(CoquiLabels.review, [
      RepasoStrings.startHint,
      if (n != 0) '$n word${n == 1 ? '' : 's'} · about ${m < 1 ? 1 : m} min',
    ]);
    loadVoice({
      for (final q in queue) ?q.item?.clip,
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
      var scoredDone = 0;
      for (var i = 0; i < queue.length; i++) {
        index = i;
        final q = queue[i];
        if (q.slot) {
          final recent = _recentFirst(i);
          q.item = planner.playItem(recent, canSay: _canSay);
          if (q.item == null) continue;
          _last.writeKind(planner.nextKind);
          unawaited(clips.preload([?q.item!.clip, ..._clipsOf(q.item!)]));
        }
        step(scoredDone);
        final ok = await _play(q);
        if (q.item!.scored && !q.again) {
          scoredDone++;
          step(scoredDone);
          if (!ok && returns < repasoMaxReturns) {
            returns++;
            final at = i + repasoReturnAfter < queue.length
                ? i + repasoReturnAfter
                : queue.length;
            queue.insert(at, QueueEntry.again(q.item!));
          }
        }
      }
      step(words.length);
    } on SessionStopped {
      return;
    }
    _clear();
    running = false;
    _addMinutes();
    _finish();
  }

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
    SayItem(:final line) => [line.clip],
    HearItem(:final solo) => [for (final c in solo) ?c],
    _ => const [],
  };

  void _clear() {
    choices = [];
    speakers = [];
    selectedSpeaker = null;
    built = [];
    yourTurn = false;
    showText = false;
    canNext = false;
    mic = MicState.dead;
    heard = '';
    heardRight = false;
    _onChoice = null;
    _onSpeaker = null;
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

  /// The touch on a shown answer: the big sign is on [k]; he touches it.
  Future<void> _touchShown(int k) async {
    choices[k]
      ..sign = true
      ..ring = OptionRing.ok;
    changed();
    final p = Completer<void>();
    _onChoice = (j) {
      if (j == k && !p.isCompleted) p.complete();
    };
    await p.future;
    choices[k].sign = false;
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

  // ---- ¿Cuál? (scored): cual.js cualItem, with this item's sentence

  Future<bool> _cual(CualItem it, bool again) async {
    choices = [for (var k = 0; k < 2; k++) Choice(right: k == it.rightPanel)];
    changed();
    _warmNext();
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
    final right = !auto && choices[got!].right;
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
      await bien(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      final k = choices.indexWhere((c) => c.right);
      if (!auto) {
        sfxBonk();
        choices[got!]
          ..dim = true
          ..ring = OptionRing.bad;
        changed();
        await waitMs(500);
      }
      await _touchShown(k);
      sfxRight();
      await bien(course.fixedClip('review_praise_after_miss'));
    }
    await waitMs(400);
    return right;
  }

  void _warmNext() {
    final w = warm;
    if (w == null) return;
    for (var k = index + 1; k < queue.length; k++) {
      final it = queue[k].item;
      if (it is CualItem) {
        w([
          PictureRef.of(it.pair, it.pair.yes),
          PictureRef.of(it.pair, it.pair.no),
        ]);
        return;
      }
    }
  }

  // ---- ¿Qué oyes? (scored)

  Future<bool> _hear(HearItem it, bool again) async {
    choices = [
      for (var k = 0; k < it.tiles.length; k++)
        Choice(label: it.tiles[k], clip: it.solo[k], right: k == it.answer),
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
    await _sayQuiet(it.clip);
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
    final right = !auto && choices[got!].right;
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
      await bien(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      if (!auto) {
        sfxBonk();
        choices[got!]
          ..dim = true
          ..ring = OptionRing.bad;
        changed();
        await waitMs(500);
      }
      await _touchShown(it.answer);
      choices[it.answer].check = true;
      sfxRight();
      await bien(course.fixedClip('review_praise_after_miss'));
    }
    showText = true;
    changed();
    await _waitNext();
    return right;
  }

  /// A sentence with no caption under it (the screen shows captions in ¿Cuál? only: the other games would show their
  /// answer in it).
  Future<void> _sayQuiet(String clip) async {
    await say(clip, 0);
    hideCaption();
  }

  // ---- Arma la frase (play)

  Future<bool> _build(BuildItem it) async {
    choices = [for (final t in it.pool) Choice(label: t)];
    changed();
    var wrongs = 0;
    var listening = true;
    _onSpeaker = (_) {
      if (listening) return;
      hush();
      unawaited(playClip(it.clip));
    };
    final p = Completer<void>();
    _onChoice = (k) {
      if (listening || p.isCompleted) return;
      final c = choices[k];
      if (c.done) return;
      if (c.label == it.order[built.length]) {
        c.done = true;
        built = [...built, c.label];
        sfxBlip();
        changed();
        if (built.length == it.order.length) p.complete();
      } else {
        wrongs++;
        c.shakes++;
        sfxBonk();
        changed();
      }
    };
    await waitMs(300);
    await _sayQuiet(it.clip);
    listening = false;
    for (final c in choices) {
      c.pre = false;
    }
    yourTurn = true;
    changed();
    await p.future;
    _onChoice = null;
    _onSpeaker = null;
    if (wrongs == 0) {
      _right();
    } else {
      _wrong();
    }
    sfxRight();
    showText = true;
    changed();
    await bien(course.fixedClip('review_praise_right'));
    await _waitNext();
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
    final p = Completer<void>();
    _onSpeaker = (i) {
      if (speakers[i].done || p.isCompleted) return;
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
      if (it.wordOrder[k] == s) {
        hush();
        speakers[s]
          ..done = true
          ..ring = OptionRing.ok
          ..check = true;
        choices[k]
          ..done = true
          ..ring = OptionRing.ok
          ..check = true;
        selectedSpeaker = null;
        found++;
        sfxRight();
        changed();
        if (found == it.words.length) p.complete();
      } else {
        wrongs++;
        choices[k].shakes++;
        sfxBonk();
        changed();
      }
    };
    await p.future;
    _onChoice = null;
    _onSpeaker = null;
    if (wrongs == 0) {
      _right();
    } else {
      _wrong();
    }
    await bien(course.fixedClip('review_praise_right'));
    await _waitNext();
    return wrongs == 0;
  }

  // ---- ¿Dónde? (play)

  Future<bool> _where(WhereItem it) async {
    choices = [
      for (var k = 0; k < it.pictures.length; k++)
        Choice(label: it.pictures[k], right: k == it.answer),
    ];
    changed();
    var listening = true;
    _onSpeaker = (_) {
      if (listening) return;
      hush();
      unawaited(playClip(it.clip));
    };
    int? got;
    final p = Completer<void>();
    _onChoice = (k) {
      if (listening || got != null) return;
      got = k;
      if (!p.isCompleted) p.complete();
    };
    await waitMs(500);
    await _sayQuiet(it.clip);
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
      await bien(course.fixedClip('review_praise_right'));
    } else {
      _wrong();
      sfxBonk();
      choices[got!]
        ..dim = true
        ..ring = OptionRing.bad;
      changed();
      await waitMs(500);
      await _touchShown(it.answer);
      choices[it.answer].check = true;
      sfxRight();
      await bien(course.fixedClip('review_praise_after_miss'));
    }
    _onSpeaker = null;
    showText = true;
    changed();
    await _waitNext();
    return right;
  }

  // ---- Dilo (play): only a word open for speaking, a line with decided forms, the mic working, "Speak in
  // stories" on. Heard right: a Mouth answer right. Anything else writes nothing.

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
    _onSpeaker = (_) {
      if (listening || mic == MicState.ok) return;
      hush();
      unawaited(playClip(it.line.before));
    };
    Future<void> turn() async {
      mic = MicState.dead;
      changed();
      await waitMs(300);
      await _sayQuiet(it.line.before);
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
        mic = MicState.listening;
        changed();
        SpeechResult r;
        final t = speech!.listen(
          locale: 'es-US',
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
          // speaking cannot work here: no more Dilo this session, nothing written
          sayOff = true;
          return;
        }
        heard = r.alternatives.isEmpty ? '' : r.alternatives.first;
        if (repasoHeardRight(r.alternatives, it.line.forms)) {
          heardRight = true;
          mic = MicState.ok;
          progress.answer(
            it.word,
            Skill.mouth,
            ok: true,
            ms: r.msToSound ?? 0,
            intro: false,
          );
          _right();
          sfxRight();
          changed();
          await waitMs(750);
          return;
        }
        mic = MicState.dead;
        changed();
        await waitMs(600);
      }
      if (done.isCompleted) return;
      // two tries and not heard right: the line itself, the model, and on
      mic = MicState.dead;
      changed();
      await _sayQuiet(it.line.clip);
    }

    await Future.any<void>([turn(), done.future]);
    _cantSpeak = null;
    _onMic = null;
    _onSpeaker = null;
    if (done.isCompleted || sayOff) {
      hush();
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
      groups: [
        if (ups.isNotEmpty)
          RepasoEndGroup(
            pr ? ReviewStrings.rightHeading : ReviewStrings.movingUpHeading,
            pr ? '' : ReviewStrings.movingUpSub,
            ups,
          ),
        if (soon.isNotEmpty)
          RepasoEndGroup(
            pr ? ReviewStrings.missedHeading : ReviewStrings.comingBackHeading,
            pr ? '' : ReviewStrings.comingBackSub,
            soon,
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
/// one of the alternatives, whole words, accents and case ignored.
bool repasoHeardRight(List<String> alts, List<String> forms) {
  final ns = [for (final a in alts) normalize(a)];
  return forms.any((f) {
    final g = normalize(f).trim();
    return g.isNotEmpty && ns.any((a) => a.contains(' $g '));
  });
}
