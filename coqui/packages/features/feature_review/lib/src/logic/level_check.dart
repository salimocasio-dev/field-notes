/// The level check. A port of historia/nivel.js (nivelRun, nivelItem, nivelPanel, nivelFrontera), the plan's
/// "The level check and the fort check".
///
/// For someone who already understands some Spanish. Touch only. A sentence; four pictures; he touches one. Items
/// run easy to hard, in the order of the stories. A right answer moves it up, a miss moves it down. It stops where
/// he starts to miss, or after 16 items. Nothing says right or wrong while it runs. What it presumes he knows
/// starts at "se queda" and opens for speaking at once (`progress.presume`, PAL.presume).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart' show PictureRef;
import 'package:feature_review/src/logic/js_sort.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/review_session.dart' show OptionRing;

/// nivel.js: CW, CH: four cells, two by two, each 96 x 106 art pixels.
const int levelCellWidth = 96;
const int levelCellHeight = 106;

/// nivel.js: `E2.SW`: the width of a scene. Every scene file takes it from the scene kit (`SW=KIT.SW`, 240).
const int levelSceneWidth = 240;

/// nivel.js: the most pictures it asks, unless every item is asked (`?todo=1`).
const int levelCap = 16;

/// nivel.js: the replay of a sentence nobody has answered (ms).
const int levelReplayEvery = 9000;

/// The old page's address switch (nivel.js: `?todo=`): every item, in order.
class LevelOptions {
  const LevelOptions({this.all = false});
  final bool all;
}

/// nivel.js: PAN[k]: one of the four pictures.
class LevelPanel {
  LevelPanel({required this.right, required this.ref});
  final bool right;

  /// The square crop of one picture of a pair (nivelPanel).
  final PictureRef ref;
}

/// nivel.js: NQ.hecho[n]: {i, w, s, ok, ms}. `i`: the item's place in the list; `w`: the word; `s`: its story.
class LevelAnswer {
  LevelAnswer({
    required this.i,
    required this.word,
    required this.story,
    required this.ok,
    required this.ms,
  });
  final int i;
  final String word;
  final int story;
  final bool ok;
  final int ms;

  /// As PAL.presume is given it: {i, w, s, ok, ms}, in that order.
  Map<String, Object?> toJson() => {
    'i': i,
    'w': word,
    's': story,
    'ok': ok,
    'ms': ms,
  };
}

/// nivel.js: NQ.fin.
class LevelResult {
  LevelResult({required this.frontier, required this.stories, required this.words});

  /// S0: how many stories he is presumed to understand.
  final int frontier;
  final List<String> stories;
  final List<String> words;
}

class LevelCheckSession extends LessonBase {
  LevelCheckSession({
    required this.rng,
    required super.clock,
    required super.course,
    required this.progress,
    required super.clips,
    required super.wait,
    super.captions,
    this.options = const LevelOptions(),
    this.warm,
  });

  final Rng rng;
  final ProgressStore progress;
  final LevelOptions options;

  /// Called with the next item's pictures while a sentence plays (PictureSource.warm).
  final void Function(List<PictureRef> refs)? warm;

  // ---- nivel.js: NN, PASO

  List<LevelItem> get items => course.levelItems;

  /// NN: how many pictures it asks at most.
  int get total => options.all ? items.length : math.min(levelCap, items.length);

  /// PASO: how far a right answer moves him up: the list grows with every scene, the check must still reach its
  /// top in about a dozen items.
  int get upStep => math.max(2, (items.length / 14).ceil());

  // ---- state (nivel.js: NQ, PAN, OPT)
  bool running = false;
  int index = 0;
  List<LevelAnswer> answers = [];
  List<LevelPanel>? panels;
  final List<OptionRing> rings = List.filled(4, OptionRing.none);
  LevelResult? result;
  int _listo = -1;
  bool get ready => _listo == index;
  void Function(int k)? _toque;

  /// Nivel.toca(k)
  void touch(int k) => _toque?.call(k);

  // ---- the start screen

  /// nivel.js: nivelArranca (the part that is logic).
  void prepare() {
    makeDots(total);
    setScreen(LessonScreen.start);
    final rounded = ((total * 11 / 60) + 0.5).floor();
    final min = rounded < 1 ? 1 : rounded; // about 11 s a picture
    showScreen(ReviewStrings.levelTitle, ['$total pictures · about $min min']);
    final ids = <String>{};
    for (final q in items) {
      final pair = _pairs[q.pictures[0][0] as String];
      if (pair != null) ids.add(pair.say); // the sentence of the first picture's word is the one that plays
    }
    loadVoice(ids);
  }

  Map<String, ReviewPair>? _byWordCache;
  Map<String, ReviewPair> get _pairs =>
      _byWordCache ??= {for (final it in course.pairs) it.word: it};

  // ---- the rings (cual.js: anillo)
  void _anillo(int? k, [OptionRing? c]) {
    for (var i = 0; i < rings.length; i++) {
      if (k == null || i == k) rings[i] = OptionRing.none;
    }
    if (k != null && c != null) rings[k] = c;
  }

  // nivel.js: nivelFrontera: which stories he is presumed to know: every story up to the highest one where he was
  // right on all its items and on three in four of everything asked up to there
  static int frontier(List<LevelAnswer> h, List<LevelItem> nv) {
    var s0 = 0;
    if (nv.isEmpty) return s0;
    final top = nv.map((q) => q.step).reduce(math.max);
    for (var s = 1; s <= top; s++) {
      final de = h.where((x) => x.story == s).toList();
      final hasta = h.where((x) => x.story <= s).toList();
      if (de.isEmpty) continue;
      final bien = hasta.where((x) => x.ok).length / hasta.length;
      // one slip low down does not hold him back if he is right on what comes after
      if (de.every((x) => x.ok) && bien >= .75) s0 = s;
    }
    return s0;
  }

  // nivel.js: nivelPanel: the square crop of one picture of a pair
  LevelPanel _panel(List<Object?> pic, bool right) {
    final word = pic[0] as String;
    final it = _pairs[word];
    if (it == null) throw StateError('the level check has no review pair for "$word"');
    final spec = pic[1] == 'no' ? it.no : it.yes;
    final cm = spec.cam;
    final h = cm[3];
    final w = h * levelCellWidth / levelCellHeight;
    final cx = (pic.length > 2 && pic[2] != null)
        ? pic[2] as num
        : cm[0] + cm[2] / 2;
    final x = math.max(0, math.min(levelSceneWidth - w, cx - w / 2));
    return LevelPanel(
      right: right,
      ref: PictureRef(
        scene: spec.scene ?? it.scene,
        set: spec.set,
        cam: [x, cm[1], w, h],
      ),
    );
  }

  // ---- running it

  /// nivel.js: nivelRun.
  Future<void> run() async {
    beginRun();
    running = true;
    answers = [];
    result = null;
    _listo = -1;
    index = 0;
    setScreen(LessonScreen.play);
    showScreen('');
    await Future.any<void>([voiceReady, sleep(6000)]);
    final nv = items;
    final usados = <int>{};
    var pos = 0;
    var seguidos = 0;
    var giros = 0;
    bool? ultimo;
    try {
      for (var n = 0; n < total; n++) {
        // the next item: the nearest one not yet asked, in the direction the last answer points
        var i = pos;
        final dir = ultimo == false ? -1 : 1;
        while (i >= 0 && i < nv.length && usados.contains(i)) {
          i += dir;
        }
        if (i < 0 || i >= nv.length) {
          i = pos;
          while (i >= 0 && i < nv.length && usados.contains(i)) {
            i -= dir;
          }
        }
        if (i < 0 || i >= nv.length) break;
        if (options.all) {
          i = n; // every item in order, for checking the pictures
          if (i >= nv.length) break;
        }
        usados.add(i);
        step(n);
        index = n;
        changed();
        final r = await _item(nv[i], i);
        answers.add(r);
        step(answers.length); // the bar fills with the items he has answered
        if (ultimo != null && ultimo != r.ok) giros++;
        ultimo = r.ok;
        seguidos = r.ok ? 0 : seguidos + 1;
        pos = r.ok ? i + upStep : i - 1;
        if (pos < 0) pos = 0;
        if (pos >= nv.length) pos = nv.length - 1;
        bool arriba(int k) => answers.any((h) => h.i == k && h.ok);
        // three misses in a row, it has gone up and down enough, or he is right at the very top: this is his level
        if (!options.all &&
            (seguidos >= 3 ||
                giros >= 5 ||
                (arriba(nv.length - 1) && arriba(nv.length - 2)))) {
          break;
        }
      }
      // it can stop early: the bar then shows exactly the items he was asked, all done
      makeDots(answers.isEmpty ? 1 : answers.length);
      step(answers.length);
    } on SessionStopped {
      return;
    }
    panels = null;
    final s0 = frontier(answers, nv);
    final ids = [
      for (final l in course.places) ...l.stories,
    ].take(s0).toList();
    final pal = <String>[];
    for (final id in ids) {
      try {
        final j = await course.story(id);
        for (final w in (j['focus_words'] as List?) ?? const []) {
          if (!pal.contains(w)) pal.add(w as String);
        }
      } catch (_) {
        // a story with no file is skipped (nivel.js: try/catch around the fetch)
      }
    }
    progress.presume(pal, ids, [for (final a in answers) a.toJson()]);
    result = LevelResult(frontier: s0, stories: ids, words: pal);
    running = false;
    setScreen(LessonScreen.end);
    // the title and one short line; what happens to those words is explained in the app's Yo tab
    showScreen(ReviewStrings.levelDoneTitle, [
      s0 != 0
          ? 'You already understand the first $s0 ${s0 == 1 ? 'story' : 'stories'}.'
          : ReviewStrings.levelStart,
    ]);
  }

  // nivel.js: nivelItem
  Future<LevelAnswer> _item(LevelItem q, int place) async {
    _anillo(null);
    final orden = [0, 1, 2, 3];
    jsSort<int>(orden, (a, b) => rng.next() - .5); // where the right picture sits is drawn fresh
    final it = _pairs[q.pictures[0][0] as String];
    if (it == null) {
      throw StateError('the level check has no review pair for "${q.pictures[0][0]}"');
    }
    panels = [for (final k in orden) _panel(q.pictures[k], k == 0)];
    changed();
    await waitMs(450);
    final my = runId;
    int? got;
    var ms = 0;
    int? tEnd;
    final p = Completer<void>();
    _toque = (k) {
      if (tEnd == null || got != null || k < 0 || k >= panels!.length) return;
      got = k;
      ms = clock.nowMs() - tEnd;
      // the ring round the picture he touched: white, it only shows which one he touched (a check never says
      // right or wrong)
      _anillo(k, OptionRing.sel);
      changed();
      p.complete();
    };
    _warmNext(place);
    await say(it.say, 0);
    tEnd = clock.nowMs();
    _listo = index;
    changed();
    // the sentence plays again every 9 s while he has not answered
    var done = false;
    unawaited(() async {
      while (!done) {
        await sleep(levelReplayEvery);
        if (done) break;
        if (got == null && speaking == 0 && my == runId) unawaited(playClip(it.say));
      }
    }());
    await p.future;
    done = true;
    sfxBlip();
    await waitMs(350);
    panels = null;
    changed();
    return LevelAnswer(
      i: place,
      word: q.word,
      story: q.step,
      ok: orden[got!] == 0,
      ms: ms,
    );
  }

  // Not in the old page: the pictures of the item that can come next, made ready while the sentence plays. Which
  // one it is depends on the answer (right: `upStep` up the list; wrong: the one below), so both are made ready.
  void _warmNext(int place) {
    final w = warm;
    if (w == null) return;
    final refs = <PictureRef>[];
    for (final next in [place + upStep, place - 1]) {
      if (next < 0 || next >= items.length) continue;
      for (final pic in items[next].pictures) {
        if (_pairs[pic[0] as String] == null) continue;
        refs.add(_panel(pic, false).ref);
      }
    }
    if (refs.isNotEmpty) w(refs);
  }
}
