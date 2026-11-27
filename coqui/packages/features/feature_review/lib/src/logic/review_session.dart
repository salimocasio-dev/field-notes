/// Repaso (¿Cuál?): the session. A port of historia/cual.js (the logic of cualLista, cualRun, cualItem, cualFin),
/// page 10 "Repaso (¿Cuál?): the session".
///
/// A sentence plays, two pictures, only one fits; he touches it. It asks up to 10 words a session: the ones that
/// are due, most overdue first (the progress store decides); with nothing due it plays words he has heard, and
/// those answers do not move the schedule. No touch 6 s after the sentence: it plays again; 6 s after that the
/// right picture is shown and he touches it (a miss). A miss comes back once, three items later, unscored.
///
/// Plain Dart: the random source, the clock, the catalog, the store, the clip player and the host's wait are all
/// handed in, so a session can be run without a screen and compared with the old code.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show CoquiLabels, PictureRef;
import 'package:feature_review/src/logic/js_sort.dart';
import 'package:feature_review/src/logic/lesson_base.dart';

/// cual.js: CAP, SIX: the most words in a session; the silence (ms) after a sentence before it plays again, and
/// again before the answer is shown.
const int reviewCap = 10;
const int reviewSilence = 6000;

/// The old page's address switches (cual.js: `?n=`, `?solo=`, `?todo=`), which the machine checks use.
class ReviewOptions {
  const ReviewOptions({this.cap = reviewCap, this.only, this.all = false});

  /// `?n=`: the most words asked.
  final int cap;

  /// `?solo=`: only these words.
  final List<String>? only;

  /// `?todo=`: with nothing due, every pair is a word to ask (not only the words he has heard).
  final bool all;
}

/// How a picture's frame shows the answer (cual.html: `.opt.ok`, `.bad`, `.sel`).
enum OptionRing { none, ok, bad, sel }

/// cual.js: PAN[k]: one of the two pictures of an ask.
class ReviewPanel {
  ReviewPanel({required this.right, required this.ref});

  /// Whether this is the picture that fits.
  final bool right;
  final PictureRef ref;

  /// `dim`: the one that is not it. `pre`: both, while the sentence plays. `sign`: the right one is shown.
  bool dim = false;
  bool pre = true;
  bool sign = false;
}

/// cual.js: CQ.cola: one place in the queue.
class QueueItem {
  QueueItem(this.pair, {required this.again});
  final ReviewPair pair;

  /// The second ask of a missed word.
  final bool again;
}

/// cual.js: CQ.hecho: the answer to a scored ask. `auto`: he did not touch, the right picture was shown.
class ReviewAnswer {
  ReviewAnswer(
    this.word, {
    required this.ok,
    required this.ms,
    this.auto = false,
  });
  final String word;
  final bool ok;
  final int ms;
  final bool auto;
}

/// cual.js: CQ.tt: when things happened in one ask (ms of the clock).
class ReviewAsk {
  ReviewAsk(this.i, this.word, this.again);
  final int i;
  final String word;
  final bool again;
  int? fin; // the sentence ended
  int? rep; // it started again
  int? repFin; // it ended again
  int? auto; // the right picture was shown
  bool? ok;
}

/// One group of the end screen.
class ReviewGroup {
  ReviewGroup(this.title, this.sub, this.pairs);
  final String title;

  /// The grey line under the heading ("" in a practice session).
  final String sub;
  final List<ReviewPair> pairs;
  List<String> get words => [for (final p in pairs) p.word];
}

/// cual.js: CQ.fin and what cualFin writes on the end screen.
class ReviewEnd {
  ReviewEnd({
    required this.up,
    required this.soon,
    required this.practice,
    required this.summary,
    required this.groups,
    required this.stageMax,
    this.stages = const {},
  });
  final List<String> up;
  final List<String> soon;
  final bool practice;

  /// "8 moving up · 2 coming back soon" ("6 right · 2 missed").
  final String summary;
  final List<ReviewGroup> groups;
  final int stageMax;
  final Map<String, ({int before, int after})> stages;
}

class ReviewSession extends LessonBase {
  ReviewSession({
    required this.rng,
    required super.clock,
    required super.course,
    required this.progress,
    required super.clips,
    required super.wait,
    super.captions,
    this.options = const ReviewOptions(),
    this.warm,
  });

  final Rng rng;
  final ProgressStore progress;
  final ReviewOptions options;

  /// Called with the next ask's pictures while a sentence plays, so they can be made ready (PictureSource.warm).
  final void Function(List<PictureRef> refs)? warm;

  // ---- state of the page (cual.js: CQ, PAN, OPT)

  /// CQ.lista: the words of this session.
  List<ReviewPair> list = const [];

  /// CQ.practica: nothing was due.
  bool practice = false;

  /// CQ.cola: the queue, with the second asks.
  List<QueueItem> queue = const [];

  /// CQ.i
  int index = 0;
  bool running = false;
  List<ReviewAnswer> answers = [];
  List<ReviewAnswer> secondAnswers = [];
  List<ReviewAsk> asks = [];
  ReviewEnd? end;
  final Map<String, ({int before, int after})> _stages = {};

  /// PAN: the two pictures now on screen, or null.
  List<ReviewPanel>? panels;

  /// OPT[k] classes: the ring, and the check badge.
  final List<OptionRing> rings = [OptionRing.none, OptionRing.none];
  final List<bool> checks = [false, false];

  /// CQ.listo === CQ.i + 1: the sentence of this ask has ended (his turn).
  int _listo = 0;
  bool get ready => _listo == index + 1;

  // CQ.toque
  void Function(int k)? _toque;

  /// Cual.toca(k): he touched picture [k]. A touch before the sentence ends does not count.
  void touch(int k) => _toque?.call(k);

  // ---- the start screen

  /// cual.js: cualArranca (the part that is logic): the words, the bar, the start screen's lines.
  void prepare() {
    list = _makeList();
    makeDots(list.length);
    setScreen(LessonScreen.start);
    final n = list.length;
    final rounded = _round(n * 10 / 60);
    final min = rounded < 1 ? 1 : rounded; // about 10 s a word
    showScreen(CoquiLabels.review, [
      ReviewStrings.startHint,
      if (n != 0) '$n word${n == 1 ? '' : 's'} · about $min min',
    ]);
    loadVoice([
      for (final p in list) p.say,
      course.fixedClip('review_praise_right'),
      course.fixedClip('review_praise_after_miss'),
    ]);
  }

  // Math.round for a number that is not negative
  static int _round(num x) => (x + 0.5).floor();

  // cual.js: cualLista: which words this pass asks: the ones due, most overdue first; with nothing due, every word
  // he has heard (those answers do not move the schedule)
  List<ReviewPair> _makeList() {
    final due = progress.due(Skill.ear);
    final byWord = <String, ReviewPair>{
      for (final it in course.pairs) it.word: it,
    };
    var lista = <ReviewPair>[
      for (final w in due)
        if (byWord.containsKey(w)) byWord[w]!,
    ];
    practice = lista.isEmpty;
    if (lista.isEmpty) {
      final oidas = <String>[
        for (final r in progress.words)
          if (byWord.containsKey(r.w)) r.w,
      ];
      lista = oidas.isNotEmpty && !options.all
          ? [for (final w in oidas) byWord[w]!]
          : List<ReviewPair>.of(course.pairs);
      jsSort<ReviewPair>(lista, (a, b) => rng.next() - .5);
    }
    final only = options.only;
    if (only != null) {
      lista = [
        for (final it in course.pairs)
          if (only.contains(it.word)) it,
      ];
    }
    return lista.take(options.cap).toList();
  }

  // ---- the rings

  // cual.js: anillo(k, c): no ring on any option with null
  void _anillo(int? k, [OptionRing? c]) {
    for (var i = 0; i < rings.length; i++) {
      if (k == null || i == k) rings[i] = OptionRing.none;
    }
    if (k != null && c != null) rings[k] = c;
  }

  // ---- running it

  /// cual.js: cualRun. Runs the session to its end screen; ends early (and quietly) if the lesson is left.
  Future<void> run() async {
    beginRun(); // runId++; hush(); callaLetras()
    running = true;
    // foot(0,0,0); estado("play"); pantalla("")
    setScreen(LessonScreen.play);
    showScreen('');
    await Future.any<void>([voiceReady, sleep(6000)]);
    final q = queue = [for (final it in list) QueueItem(it, again: false)];
    answers = [];
    secondAnswers = [];
    asks = [];
    end = null;
    _stages.clear();
    try {
      for (var i = 0; i < q.length; i++) {
        step(answers.length); // one segment per word, lit as each is answered
        index = i;
        changed();
        final ok = await _item(q[i].pair, q[i].again);
        if (!ok && !q[i].again) {
          // a miss comes back once, three items later (at the end when fewer are left); it adds no segment
          final at = i + 3 < q.length ? i + 3 : q.length;
          q.insert(at, QueueItem(q[i].pair, again: true));
        }
      }
      step(list.length);
    } on SessionStopped {
      return;
    }
    panels = null;
    running = false;
    _finish();
  }

  // cual.js: cualItem
  Future<bool> _item(ReviewPair it, bool again) async {
    _anillo(null);
    checks.fillRange(0, checks.length, false);
    final ok = rng.next() < .5
        ? 0
        : 1; // which panel holds the right picture: drawn fresh at every ask
    panels = [
      for (var k = 0; k < 2; k++)
        ReviewPanel(
          right: k == ok,
          ref: PictureRef.of(it, k == ok ? it.yes : it.no),
        ),
    ];
    changed();
    await waitMs(500);
    int? got;
    var ms = 0;
    int? tEnd;
    final p = Completer<void>();
    final t = ReviewAsk(index, it.word, again);
    asks.add(t);
    _toque = (k) {
      // a touch before the sentence ends does not count
      if (tEnd == null || got != null) return;
      got = k;
      ms = clock.nowMs() - tEnd;
      p.complete();
    };
    _warmNext();
    await say(it.say, 0);
    tEnd = t.fin = clock.nowMs();
    for (final x in panels!) {
      x.pre = false;
    }
    _listo = index + 1;
    changed();
    // he waits: 6 s after the sentence ends it plays again (a touch while it plays counts); 6 s after that the
    // right picture is shown, and that is a miss
    await Future.any<void>([p.future, waitMs(reviewSilence)]);
    if (got == null) {
      t.rep = clock.nowMs();
      await Future.any<void>([p.future, say(it.say, 0)]);
      if (got == null) {
        t.repFin = clock.nowMs();
        await Future.any<void>([p.future, waitMs(reviewSilence)]);
      }
    }
    final auto = got == null;
    if (auto) {
      ms = clock.nowMs() - tEnd;
      t.auto = clock.nowMs();
    } else if (speaking > 0) {
      hush(); // a touch while the sentence plays again stops it
    }
    final right = auto ? false : panels![got!].right;
    t.ok = right;
    if (!again) {
      // due now, by the store's clock
      final before = progress.word(it.word)?.ear.etapa ?? 0;
      final vence = progress.due(Skill.ear).contains(it.word);
      final rec = progress.answer(
        it.word,
        Skill.ear,
        ok: right,
        ms: ms,
        intro: !vence,
      );
      _stages[it.word] = (before: before, after: rec.etapa);
      answers.add(
        auto
            ? ReviewAnswer(it.word, ok: false, ms: ms, auto: true)
            : ReviewAnswer(it.word, ok: right, ms: ms),
      );
    } else {
      // the second ask of a missed word is not scored: nothing is written
      secondAnswers.add(ReviewAnswer(it.word, ok: right, ms: ms));
    }
    if (right) {
      // the green ring and a small check badge on the right one, the other dims
      _anillo(got, OptionRing.ok);
      checks[got!] = true;
      panels![1 - got!].dim = true;
      changed();
      sfxRight();
      await bien(course.fixedClip('review_praise_right'));
    } else {
      int k;
      if (auto) {
        k = panels!.indexWhere(
          (x) => x.right,
        ); // he did not touch: the right picture is shown at once
      } else {
        sfxBonk();
        panels![got!].dim = true;
        _anillo(got, OptionRing.bad);
        changed();
        await waitMs(500);
        k =
            1 -
            got!; // red-orange on his, then the green ring shows the right one
      }
      panels![k].sign = true;
      _anillo(k, OptionRing.ok);
      changed();
      final p2 = Completer<void>();
      _toque = (j) {
        // resolving a promise twice does nothing in JavaScript: a second touch on the shown picture is fine
        if (j == k && !p2.isCompleted) p2.complete();
      };
      await p2.future;
      panels![k].sign = false;
      changed();
      sfxRight();
      await bien(course.fixedClip('review_praise_after_miss'));
    }
    await waitMs(400);
    return right;
  }

  // The next ask's pictures, made ready while this sentence plays (not in the old page).
  void _warmNext() {
    final w = warm;
    if (w == null) return;
    final next = index + 1;
    if (next >= queue.length) return;
    final it = queue[next].pair;
    w([PictureRef.of(it, it.yes), PictureRef.of(it, it.no)]);
  }

  // cual.js: cualFin: the end: the session's words, each with its picture, under "Moving up" (right on the
  // scored ask) and "Coming back soon" (missed) - "Right" and "Missed" in a practice session - and the way back to
  // Palabras. No score.
  void _finish() {
    final up = <ReviewPair>[];
    final soon = <ReviewPair>[];
    for (final it in list) {
      ReviewAnswer? h;
      for (final x in answers) {
        if (x.word == it.word) {
          h = x;
          break;
        }
      }
      if (h != null) (h.ok ? up : soon).add(it);
    }
    final pr = practice;
    final line = [
      if (up.isNotEmpty)
        '${up.length} ${pr ? ReviewStrings.right : ReviewStrings.movingUp}',
      if (soon.isNotEmpty)
        '${soon.length} ${pr ? ReviewStrings.missed : ReviewStrings.comingBackSoon}',
    ].join(' · ');
    end = ReviewEnd(
      up: [for (final x in up) x.word],
      soon: [for (final x in soon) x.word],
      practice: pr,
      summary: line,
      stageMax: progress.stageMax,
      stages: Map.unmodifiable(_stages),
      groups: [
        if (up.isNotEmpty)
          ReviewGroup(
            pr ? ReviewStrings.rightHeading : ReviewStrings.movingUpHeading,
            pr ? '' : ReviewStrings.movingUpSub,
            up,
          ),
        if (soon.isNotEmpty)
          ReviewGroup(
            pr ? ReviewStrings.missedHeading : ReviewStrings.comingBackHeading,
            pr ? '' : ReviewStrings.comingBackSub,
            soon,
          ),
      ],
    );
    setScreen(LessonScreen.end);
    showScreen(ReviewStrings.doneTitle, [line]);
  }
}
