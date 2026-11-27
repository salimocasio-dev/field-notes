// The names of the old file are kept, Spanish ones and capitals included, so the port reads line for line against it
// (page 12, sections 4 and 6): the lints on names are off in this file and its parts.
// ignore_for_file: non_constant_identifier_names

/// The story game: a story file, played step by step. A port of historia/juego.js (everything that orders 12 and 18 did
/// not take: the step function and every kind of step, `decide`, `espera`, the marks, `lost`, the endings, `LOG`, the
/// story memory, `$name` filling, the speaking turns above the recogniser, the captions and bubbles' timing, the
/// fallback to timed lines when a clip is missing, `tap`).
///
/// Pure Dart: it never reads a real clock, never sleeps for real and never draws on a screen. Time is [StoryTimers],
/// moved by a host. The frame is a [StoryRenderer]. What the screen shows is a [StoryView].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart'
    hide hand, heart, star, spot, frogBox;
import 'package:coqui_pixel/coqui_pixel.dart'
    as px
    show hand, heart, star, spot, frogBox;
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/js.dart';
import 'package:feature_story/src/runner/observer.dart';
import 'package:feature_story/src/runner/pending.dart';
import 'package:feature_story/src/runner/renderer.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/split_story.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/runner/timers.dart';

part 'steps.dart';
part 'turns.dart';

/// Thrown when a play is left while a wait is going on (juego.js: `throw "stop"`).
class StopSignal implements Exception {
  const StopSignal();

  @override
  String toString() => 'stop';
}

/// A story file the game cannot play: a step it does not know, an act the scene has not, a missing story key.
class StoryError extends Error {
  StoryError(this.message);

  final String message;

  @override
  String toString() => 'StoryError: $message';
}

/// juego.js: the options `espera` takes (its `o`).
class EsperaOpts {
  EsperaOpts({
    this.loose = false,
    this.lock = false,
    this.voces,
    this.orden,
    this.turno,
    this.sign,
    this.kind,
    this.pick,
    this.alias,
    this.mudo = false,
    this.ayuda,
    this.ronda,
  });

  factory EsperaOpts.fromMap(Map<String, dynamic>? o) {
    if (o == null) return EsperaOpts();
    final v = o['voces'];
    final ord = o['orden'];
    return EsperaOpts(
      loose: jsTruthy(o['loose']),
      lock: jsTruthy(o['lock']),
      voces: v == null
          ? null
          : {
              for (final e in (v as Map).entries)
                e.key as String: e.value as String,
            },
      orden: ord == null ? null : [for (final e in ord as List) e as String],
      sign: o['sign'] as String?,
      kind: o['kind'] as String?,
      pick: o['pick'] as String?,
      alias: o['alias'] as Map<String, dynamic>?,
      mudo: jsTruthy(o['mudo']),
      ayuda: o['ayuda'] as String?,
    );
  }

  final bool loose, lock, mudo;
  final Map<String, String>? voces;
  final List<String>? orden;
  final Turno? turno;
  final String? sign, kind, pick, ayuda;
  final Map<String, dynamic>? alias;

  /// A decision's round: the lines said since its `dots` step, said again in order when he waits (null or one line:
  /// the `line` alone, as before).
  final List<String>? ronda;
}

/// The targets of a marked clip (a `tu_turno` entry): a word and the forms that count.
typedef Target = ({String palabra, List<String> formas});

/// A speaking turn waiting inside an ask or an elige (juego.js: `turno`).
class Turno {
  Turno.ask(this.id, this.T)
    : kind = 'ask',
      ids = const [],
      ops = const [],
      Ts = const {};
  Turno.elige(this.ids, this.ops, this.Ts)
    : kind = 'elige',
      id = null,
      T = const [];

  final String kind;
  final String? id;
  final List<Target> T;
  final List<String> ids, ops;
  final Map<String, List<Target>> Ts;
}

/// What speaking turns keep (juego.js: `HAB`).
class Hab {
  /// Turns this play.
  int n = 0;

  /// The clips that have been a turn this play.
  Set<String> hechos = {};

  /// The mic's state: "", dead, ready, listening, processing, ok.
  String est = '';

  /// Where the turn's bubble sits, decided once for the turn: "", "coqui" or "mic".
  String q = '';
  HabAttempt? cur;
  SpeechTurn? rec;

  /// An index into the stub's results.
  int si = 0;

  /// A turn has used the mic: clips then get a time limit.
  bool guard = false;
  List<Map<String, dynamic>> log = [];

  /// The stub's timers.
  List<int> t = [];
}

/// One attempt at a turn (juego.js: `C`).
class HabAttempt {
  HabAttempt(this.res);

  final Completer<HabResult> res;
  int? idle;
  bool listo = false;
}

/// What an attempt gave (juego.js: `{alts, err, ms}` or `{cancel: 1}`).
class HabResult {
  HabResult({this.alts, this.err = '', this.ms = 0, this.cancel = false});

  final List<String>? alts;
  final String err;
  final int ms;
  final bool cancel;
}

/// The words of a line, split as the old page splits them (juego.js: `partes`).
typedef Partes = ({String? cap, String? quien, String? bub, String all});

/// The one camera move in progress (juego.js: `camA`).
class _CamMove {
  _CamMove(this.slide) : done = Completer<void>();

  final CamSlide slide;
  final Completer<void> done;
}

/// The story game. One per play of a story. See the library comment.
class StoryRunner implements SceneHost {
  StoryRunner({
    required this.storyId,
    required Map<String, dynamic> story,
    Map<String, dynamic>? lines,
    this.wordTable = const {},
    required this.E,
    required this.course,
    required this.clips,
    required this.speech,
    required this.progress,
    required this.rng,
    required this.clock,
    required this.memory,
    this.options = const StoryOptions(),
    StoryTimers? timers,
    StoryRenderer? renderer,
    StoryObserver observer = const StoryObserver(),
    SpeechSession? session,
    Sfx? sfx,
    StoryView? view,
    this.startFrog,
    this.frogShadow = true,
  }) : // `S._lost` is written on the story (juego.js: `S._lost=W.lost`): on a copy, the catalog's stays as it is
       S = assembleStory(
         story,
         lines: lines,
         wordTable: wordTable,
         expectedLang: lines != null ? course.language.code : null,
       ),
       timers = timers ?? StoryTimers(),
       renderer = renderer ?? HeadlessRenderer(),
       obs = observer,
       session = session ?? SpeechSession(),
       view = view ?? StoryView() {
    SFX = sfx ?? Sfx(clips);
    final sp = SpriteLib();
    lib = sp;
    E.host = this;
    _signs = Signs(host: this, scene: E);
    _origin = clock.nowMs() - this.timers.now;
    this.view.txtOn = txtOn;
    _loadMemory();
  }

  /// The story's id (juego.js: `CUENTO`).
  final String storyId;
  @override
  final Map<String, dynamic> S;

  /// Per-language ID-to-word fallback table (`lines/<lang>/words.json`).
  final Map<String, String> wordTable;

  /// The scene (juego.js: `E`).
  final Scene E;
  final CourseCatalog course;
  final ClipPlayer clips;
  final SpeechListener speech;
  final ProgressStore progress;
  final Rng rng;
  final Clock clock;

  /// `Services.storage('juego')`: the keys `mem` and `ult`.
  final KeyValueStore memory;
  final StoryOptions options;
  final StoryTimers timers;
  final StoryRenderer renderer;
  final StoryObserver obs;
  final SpeechSession session;
  final StoryView view;
  late final Signs _signs;
  late int _origin;

  /// The clock's time when the story's clock was held, or null while it runs ([holdClock]).
  int? _heldAt;

  /// Where the game puts the frog when a play starts (juego.js, `fresh`: `cq x 150 y 178 s 1`), as the scene's sheet says
  /// (its `code` entry for `juego.js:16`: a spot). Null: the old numbers.
  final ({int x, int y, num scale}) Function()? startFrog;

  /// Whether the frog keeps the old flat shadow juego.js's `frog()` draws under him. A converted scene (a `SetScene`) casts his
  /// shadow in the engine, so the old one is not drawn (its sheet: `shadows.dropped`).
  final bool frogShadow;

  // ---------- the globals of juego.js ----------

  /// `OIR`: told straight through, nothing to touch.
  bool get OIR => options.listen;

  @override
  num get FAST => options.fast;
  @override
  final int TICK = 70;
  @override
  int get SW => E.SW;
  @override
  int get SH => E.SH;
  @override
  final int DW = displayW;
  @override
  final int DH = displayH;
  @override
  Map<String, dynamic> W = {'fx': <dynamic>[]};
  @override
  Map<String, dynamic> V = {};

  /// The lines said since the round began (the last `dots` step): when he waits at a decision whose round holds more
  /// than one line (two people speak, or one says two things), the whole round is said again, in order (page 13,
  /// orders 58 to 61; before, only the decision's `line`).
  final List<String> ronda = [];
  @override
  int F = 0;
  @override
  List<num> cam = [0, 0, displayW, displayH];
  @override
  int runId = 0;
  @override
  final Set<Object> live = {};
  @override
  String? TALK;
  @override
  final Map<String, List<String>> BUBL = newBUBL();
  @override
  late final SpriteLib lib;
  @override
  late final Sfx SFX;

  /// `pending`: the touch the story waits for, if any.
  Pending? pending;
  bool running = false;
  _CamMove? _camA;
  List<Decision> LOG = [];
  Map<String, dynamic> ULT = {};
  Map<String, dynamic> MEM = {};
  Map<String, List<num>> _cams = {};
  int speaking = 0;
  int _inSay = 0;
  final Map<Object, void Function(bool)> _ends = {};
  int _t0 = 0;

  // the voice
  Map<String, dynamic> LINES = {};
  final Set<String> _have = {};
  bool VOICE = false;
  Future<void> voiceReady = Future<void>.value();

  // the words on screen
  bool SINLETRAS = false;
  String? BUBQ;
  int? _capT, _bubT;
  bool MBUB = false;
  late TxtMode _txt = options.txt;
  late TxtMode _lastOnTxt = options.txt == TxtMode.no
      ? TxtMode.con
      : options.txt;
  TxtMode get TXT => _txt;

  /// Whether captions (TXT) are currently enabled.
  bool get txtOn => _txt != TxtMode.no;

  // Noche speaker, line, and "hear it again" tracking
  String? _lastLineClip;
  String _lastSpeaker = '';
  String _lastLine = '';
  String? _turnReplayClip;
  int _untimedSpeaking = 0;
  int _touchSeq = 0;

  // speaking
  final Hab HAB = Hab();
  bool _speechOk = false;

  /// Asked by a turn's bubble: the stage's size and the bubble's, and where the mic button is, as the screen has them
  /// (juego.js measured the page's elements). Null: no screen. Then a turn's bubble never counts as covering anyone.
  BubbleMetrics? Function()? bubbleMetrics;

  /// Where the mic button is, in the stage's pixels, when the screen knows (a turn's bubble that sits above it).
  MicAnchor? micAnchor;

  // ---------- starting ----------

  // juego.js: arranca (after the story is fetched and its scene loaded)
  /// Gets the story ready to be played: the scene's views, the progress dashes, the tick, and the voice, which loads while
  /// the start disc is shown ([run] waits for it, 6 s at most). Call once, before [start].
  Future<void> init() async {
    final camOver = S['cam'];
    _cams = {for (final e in E.CAM.entries) e.key: List<num>.of(e.value)};
    if (camOver is Map) {
      camOver.forEach((k, v) {
        _cams[k as String] = List<num>.of(
          E.remap([for (final n in v as List) n as num]),
        );
      });
    }
    view.dots = S['dots'] != null && S['dots'] != 0
        ? (S['dots'] as num).toInt()
        : 5;
    view.dotsLit = 0;
    fresh();
    voiceReady = loadVoice();
    timers.setInterval(_loop, TICK);
    draw();
  }

  void _loadMemory() {
    try {
      final u = memory.read('ult');
      ULT = u == null || u.isEmpty
          ? {}
          : Map<String, dynamic>.of(
              (jsonDecode(u) as Map).cast<String, dynamic>(),
            );
      final m = memory.read('mem');
      MEM = m == null || m.isEmpty
          ? {}
          : Map<String, dynamic>.of(
              (jsonDecode(m) as Map).cast<String, dynamic>(),
            );
    } catch (_) {
      // juego.js: `try{...}catch(e){}`
    }
  }

  void _saveMemory(String key, Map<String, dynamic> value) {
    try {
      unawaited(memory.write(key, jsonEncode(value)).catchError((Object _) {}));
    } catch (_) {
      // juego.js: `try{localStorage.setItem(...)}catch(e){}`
    }
  }

  // juego.js: loadVoice
  /// Reads the story's lines and gets their recordings ready. [VOICE] is true when every line has one.
  Future<void> loadVoice() async {
    LINES = Map<String, dynamic>.of(
      (S['clips'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    try {
      final ahoraTu = course.fixedClip('story_your_turn');
      final info = course.clip(ahoraTu);
      // a story with speaking turns can say "Ahora tú." even when it does not list the clip
      if (info != null &&
          !LINES.containsKey(ahoraTu) &&
          LINES.values.any((c) => c is Map && jsTruthy(c['tu_turno']))) {
        LINES = {
          ...LINES,
          ahoraTu: {'who': info.who, 'text': info.text},
        };
      }
      final ids = LINES.keys.toList();
      final failed = (await clips.preload(ids)).toSet();
      for (final id in ids) {
        if (!failed.contains(id) && course.clip(id) != null) _have.add(id);
      }
      VOICE = ids.every(_have.contains);
      await _refreshSpeech();
    } catch (_) {
      // juego.js: `try{...}catch(e){}`: no voice, the lines are timed
    }
  }

  Future<void> _refreshSpeech() async {
    try {
      _speechOk = await speech.available();
    } catch (_) {
      _speechOk = false;
    }
  }

  // juego.js: fresh
  @override
  void fresh() {
    final f = startFrog?.call();
    final base = <String, dynamic>{
      'cq': <String, dynamic>{
        'x': f?.x ?? 150,
        'y': f?.y ?? 178,
        's': f?.scale ?? 1,
        'dy': 0,
        'al': 1,
        'vis': 1,
        'bub': null,
      },
      'spot': null,
      'twinkle': null,
      'glow': null,
      'fx': <dynamic>[],
      'heart': 0,
      'lost': 0,
      'resp': null,
    };
    W = {...base, ...E.fresh(S)};
    cam = List<num>.of(_cams['wide']!);
    _camA = null;
    pending = null;
    V = {};
    ronda.clear();
    _lastLineClip = null;
    _lastSpeaker = '';
    _lastLine = '';
    _turnReplayClip = null;
    view.touchFeedback = null;
    LOG = [];
    for (final k in MEM.keys) {
      V['mem_$k'] = MEM[k];
    }
    options.mem.forEach((k, v) => V['mem_$k'] = v);
  }

  /// The time, in ms (juego.js: `performance.now()`).
  int now() => timers.now;

  /// The live host's tick: moves the story's time to the clock's. Call it from the frame callback and before a tap.
  /// While the clock is held ([holdClock]) it does nothing: no timer fires and the story's time stays where it is.
  void pump() {
    if (_heldAt != null) return;
    timers.advanceTo(clock.nowMs() - _origin);
  }

  /// The app has left the foreground: the story's time stops, and [pump] with it. A story is a play on a clock the
  /// app moves; time the app spent out of sight is not time of the story. Does nothing when it is held already.
  void holdClock() => _heldAt ??= clock.nowMs();

  /// The app is back: the story goes on from where it stopped, at the pace of the clock again. The time spent away
  /// is taken out of the clock's, so the first [pump] after it fires nothing that was not due before the app left
  /// (no burst of timers, no jump), and what was waiting fires in its order, as the frames go by. Does nothing when
  /// the clock is not held.
  void resumeClock() {
    final h = _heldAt;
    if (h == null) return;
    _heldAt = null;
    _origin += clock.nowMs() - h;
  }

  // ---------- one frame ----------

  void _loop() {
    F++;
    draw();
    view.changed();
  }

  // juego.js: draw
  @override
  void draw() {
    List<num>? hp = _signs.handPoint();
    if (hp != null) hp = List<num>.of(hp);
    renderer.frame(
      scene: E,
      W: W,
      F: F,
      cam: cam,
      handPoint: hp,
      signs: (c, a) {
        _signs.drawSigns(c, a);
        final m = _camA;
        if (m != null) {
          final r = m.slide.at(F);
          cam.setAll(0, r.cam);
          if (r.done) {
            _camA = null;
            m.done.complete();
          }
        }
        // the hand is placed with the view as it is after the move
        final h2 = hp == null ? null : _signs.handPoint();
        if (hp != null && h2 != null) {
          hp[0] = h2[0];
          hp[1] = h2[1];
        }
      },
    );
  }

  // ---------- time ----------

  // juego.js: sleep
  @override
  Future<void> sleep(num ms) {
    final c = Completer<void>();
    timers.setTimeout(c.complete, ms);
    return c.future;
  }

  // juego.js: wait
  @override
  Future<void> wait(num ms) async {
    final my = runId;
    await sleep(ms / FAST);
    if (my != runId) throw const StopSignal();
  }

  // ---------- sound ----------

  // juego.js: tone
  @override
  void tone(num f0, num at, num dur, [String? type, num? vol, num? f1]) {
    obs.tone(['tone', f0, at, dur, type, vol, f1]);
    clips.tone(
      f0.toDouble(),
      at: at.toDouble(),
      dur: dur.toDouble(),
      wave: type == null || type.isEmpty ? 'square' : type,
      vol: vol == null || vol == 0 ? .05 : vol.toDouble(),
      toHz: f1 == null || f1 == 0 ? null : f1.toDouble(),
    );
  }

  /// The sound button (juego.js: `#snd` click).
  void toggleMute() {
    clips.muted = !clips.muted;
    view.muted = clips.muted;
    view.changed();
  }

  /// The Noche TXT captions toggle pill in the story header.
  void toggleTxt() {
    if (_txt == TxtMode.no) {
      _txt = _lastOnTxt;
      if (view.speakingNow &&
          _lastLineClip != null &&
          !SINLETRAS &&
          _txt == TxtMode.con) {
        muestra(_lastLineClip!);
      }
    } else {
      _lastOnTxt = _txt;
      _txt = TxtMode.no;
      timers.clear(_capT);
      if (!MBUB) timers.clear(_bubT);
      view.captionOn = false;
      if (!MBUB) {
        view.bubbleOn = false;
        BUBQ = null;
        view.bubbleWho = null;
      }
    }
    view.txtOn = txtOn;
    view.changed();
  }

  /// Whether the "hear it again" control can replay a clip right now.
  bool get canHearAgain {
    if (!running || view.speakingNow || _habOcupado() || HAB.est == 'ok') {
      return false;
    }
    return _replayClipId() != null;
  }

  String? _replayClipId() {
    final c = _turnReplayClip;
    if (c != null && c.isNotEmpty) return c;
    final pLine = pendingNow?.line;
    if (pLine != null && pLine.isNotEmpty) return pLine;
    final last = _lastLineClip;
    if (last != null && last.isNotEmpty) return last;
    return null;
  }

  /// Replays the current prompt/question clip when the learner taps "hear it again".
  void hearAgain() {
    if (!canHearAgain) return;
    final id = _replayClipId();
    if (id == null) return;
    view.replayCount++;
    view.micMissed = false;
    view.changed();
    if (VOICE && _has(id)) {
      unawaited(playClip(id));
    } else if (LINES[id] != null) {
      unawaited(say(id, 0).catchError((Object _) {}));
    }
  }

  void _emitTouchFeedback(TouchFeedbackKind kind, String thing) {
    final box = respBox(thing) ?? _signs.hintBoxOf(thing) ?? bx(thing);
    if (box.length < 4) return;
    view.touchFeedback = TouchFeedback(
      seq: ++_touchSeq,
      kind: kind,
      thing: thing,
      box: List<num>.unmodifiable(box),
    );
    view.changed();
  }

  void _syncSpeakingNow() {
    final nowSpeaking = speaking > 0 || _untimedSpeaking > 0;
    if (view.speakingNow != nowSpeaking) {
      view.speakingNow = nowSpeaking;
      view.changed();
    }
  }

  String? _yourTurnClipId() {
    try {
      return course.fixedClip('story_your_turn');
    } catch (_) {
      return null;
    }
  }

  String _clipText(String id) {
    final cl = LINES[id];
    if (cl is Map && cl['text'] is String) return (cl['text'] as String).trim();
    return course.clip(id)?.text.trim() ?? '';
  }

  ({String speaker, String line}) _speakerAndLine(String id) {
    final cl = LINES[id];
    if (cl is! Map) return (speaker: '', line: '');
    final rawText = cl['text'] is String ? (cl['text'] as String).trim() : '';
    final explicitSpeaker = cl['speaker'] is String
        ? (cl['speaker'] as String).trim()
        : '';
    if (explicitSpeaker.isNotEmpty) {
      return (speaker: explicitSpeaker, line: rawText);
    }
    final habla = cl['habla'];
    if (jsTruthy(habla)) {
      final i = rawText.indexOf(': ');
      if (i > 0) {
        return (
          speaker: rawText.substring(0, i).trim(),
          line: rawText.substring(i + 2).trim(),
        );
      }
    }
    return (speaker: '', line: rawText);
  }

  String _promptPrefixFor(String id) {
    final cl = LINES[id];
    if (cl is Map && cl['prompt'] is String) {
      final p = (cl['prompt'] as String).trim();
      if (p.isNotEmpty) return '$p ';
    }
    final ytId = _yourTurnClipId();
    if (ytId != null) {
      var yt = _clipText(ytId);
      while (yt.endsWith('.') || yt.endsWith(':')) {
        yt = yt.substring(0, yt.length - 1).trimRight();
      }
      if (yt.isNotEmpty) return '$yt: ';
    }
    return '';
  }

  void _recordSpokenClip(String id) {
    if (SINLETRAS) return;
    final sl = _speakerAndLine(id);
    final changed = view.speaker != sl.speaker;
    view.speaker = sl.speaker;
    final ytId = _yourTurnClipId();
    if (id != ytId && (sl.line.isNotEmpty || sl.speaker.isNotEmpty)) {
      _lastLineClip = id;
      _lastSpeaker = sl.speaker;
      _lastLine = sl.line;
    }
    if (changed) view.changed();
  }

  // juego.js: words
  int _words(String id) {
    final cl = LINES[id];
    var t = cl is Map ? cl['text'] : null;
    if (t is! String || t.isEmpty) t = 'x x';
    return t.split(RegExp(r'\s+')).length;
  }

  bool _has(String id) => _have.contains(id);

  // juego.js: dur
  /// How long a line lasts, seconds: its recording's length, or a guess from its words when it has none.
  double dur(String id) {
    if (VOICE && _has(id)) {
      final c = course.clip(id)!;
      return (c.endMs - c.startMs) / 1000;
    }
    return (360 * _words(id) + 300) / 1000;
  }

  // juego.js: playClip
  Future<bool> playClip(String id) {
    if (_inSay == 0) {
      final cl = LINES[id];
      obs.clip(
        id,
        'clip',
        cl is Map ? cl['who'] as String? : null,
        cl is Map ? partes(id).quien : null,
        !(VOICE && _has(id)),
      );
    }
    return _playClip(id);
  }

  Future<bool> _playClip(String id) {
    if (!VOICE || !_has(id)) return Future<bool>.value(false);
    final token = Object(), c = Completer<bool>();
    speaking++;
    _syncSpeakingNow();
    live.add(token);
    TALK = partes(id).quien;
    _recordSpokenClip(id);
    letras(id);
    var done = false;
    void end(bool v) {
      if (done) return;
      done = true;
      speaking = math.max(0, speaking - 1);
      live.remove(token);
      _ends.remove(token);
      TALK = null;
      _syncSpeakingNow();
      letrasFin(id, v);
      c.complete(v);
    }

    _ends[token] = end;
    // after a speaking turn (iPhone) a clip may never report its end: every clip gets its length + 1 s, so the story
    // cannot hang
    Duration? limit;
    if (HAB.guard) {
      final i = course.clip(id)!;
      limit = Duration(milliseconds: i.endMs - i.startMs + 1000);
    }
    clips.play(id, limit: limit).then(end, onError: (Object _) => end(false));
    return c.future;
  }

  // juego.js: hush
  /// Stops what is playing: each line ends, as not heard to its end.
  void hush() {
    final was = live.isNotEmpty;
    for (final t in List.of(live)) {
      _ends[t]?.call(false);
    }
    if (was) unawaited(clips.stop());
  }

  // juego.js: say
  @override
  Future<void> say(String id, [num? gap]) {
    final cl = LINES[id];
    obs.clip(
      id,
      'say',
      cl is Map ? cl['who'] as String? : null,
      cl is Map ? partes(id).quien : null,
      !(VOICE && _has(id)),
    );
    _inSay++;
    try {
      return _say(id, gap);
    } finally {
      _inSay--;
    }
  }

  Future<void> _say(String id, num? gap) async {
    final my = runId, g = (gap ?? 420) / FAST;
    if (VOICE && _has(id)) {
      final ok = await _playClip(id);
      if (ok) await sleep(g);
    } else {
      TALK = partes(id).quien;
      _untimedSpeaking++;
      _syncSpeakingNow();
      _recordSpokenClip(id);
      letras(id);
      try {
        await sleep(dur(id) * 1000 / FAST);
      } finally {
        _untimedSpeaking = math.max(0, _untimedSpeaking - 1);
        TALK = null;
        _syncSpeakingNow();
      }
      letrasFin(id, true);
      await sleep(g);
    }
    if (my != runId) throw const StopSignal();
  }

  // ---------- the words on screen: speech bubbles and captions ----------

  // juego.js: partes
  Partes partes(String id) {
    final cl = LINES[id] is Map ? LINES[id] as Map : const {};
    final text = cl['text'];
    final t = text is String ? text : '';
    if (cl['who'] == 'tu') return (cap: null, quien: 'coqui', bub: t, all: t);
    final habla = cl['habla'];
    if (jsTruthy(habla)) {
      final i = t.indexOf(': ');
      if (i > 0) {
        return (
          cap: t.substring(0, i + 1),
          quien: habla as String,
          bub: t.substring(i + 2),
          all: t,
        );
      }
    }
    return (cap: t, quien: null, bub: null, all: t);
  }

  // juego.js: donde
  @override
  List<num>? donde(String? quien) {
    if (quien == null || quien.isEmpty) return null;
    if (quien == 'coqui') {
      final q = W['cq'] as Map<String, dynamic>;
      if (!jsTruthy(q['vis'])) return null;
      final b = frogBox(q);
      return [
        b.x + b.w / 2,
        b.y + jsRound(q['dy'] as num) - (jsTruthy(q['bub']) ? 19 : 1),
      ];
    }
    return E.talkAt(quien, W);
  }

  // juego.js: muestra
  @override
  void muestra(String id) {
    final p = partes(id);
    var cap = p.cap, bub = p.bub;
    if (bub != null && bub.isNotEmpty && donde(p.quien) == null) {
      cap = p.all;
      bub = null;
    }
    timers.clear(_capT);
    if (!MBUB) timers.clear(_bubT);
    view.caption = cap ?? '';
    view.captionOn = cap != null && cap.isNotEmpty;
    if (MBUB) {
      view.changed();
      return;
    }
    // while a speaking turn shows its mic bubble, the caption may change but the bubble stays
    if (bub != null && bub.isNotEmpty) {
      BUBQ = p.quien;
      view.bubbleKind = BubbleKind.words;
      view.bubbleText = bub;
      view.bubbleOn = true;
      view.bubbleWho = BUBQ;
      view.bubbleEstate = '';
    } else {
      BUBQ = null;
      view.bubbleOn = false;
      view.bubbleWho = null;
      view.bubbleEstate = '';
    }
    view.changed();
  }

  // juego.js: borra
  void borra(num ms) {
    timers.clear(_capT);
    timers.clear(_bubT);
    _capT = timers.setTimeout(() {
      view.captionOn = false;
      view.changed();
    }, ms);
    _bubT = timers.setTimeout(() {
      if (MBUB) return;
      view.bubbleOn = false;
      BUBQ = null;
      view.bubbleWho = null;
      view.changed();
    }, ms * .7);
  }

  // juego.js: letras
  void letras(String id) {
    if (TXT == TxtMode.con && !SINLETRAS) muestra(id);
  }

  // juego.js: letrasFin
  void letrasFin(String id, bool done) {
    if (TXT == TxtMode.no || SINLETRAS) return;
    if (TXT == TxtMode.tras) {
      if (!done) return;
      muestra(id);
      final cl = LINES[id] is Map ? LINES[id] as Map : const {};
      final t = cl['text'] is String ? cl['text'] as String : '';
      borra(math.max(1800, t.length * 70) / FAST);
      return;
    }
    borra(1700 / FAST);
  }

  // juego.js: callaLetras
  void callaLetras() {
    timers.clear(_capT);
    timers.clear(_bubT);
    view.captionOn = false;
    view.speaker = '';
    view.bubbleOn = false;
    view.bubbleEstate = '';
    BUBQ = null;
    view.bubbleWho = null;
    MBUB = false;
    view.changed();
  }

  // ---------- the signs ----------

  @override
  ({num x, num y, num w, num h}) frogBox(Map<String, dynamic> q) =>
      px.frogBox(q);

  // juego.js: frog
  // `shadow: false` where the scene casts the frog's shadow in the engine (`frogShadow`): the old flat shadow is
  // then not drawn, and nothing else changes.
  @override
  void frog(Ctx g, Map<String, dynamic> q, int a) =>
      _signs.frog(g, q, a, shadow: frogShadow);

  @override
  void star(Ctx g, num x, num y, num s, [bool hot = false]) =>
      px.star(g, x, y, s, hot);

  @override
  void hand(Ctx g, num x, num y, bool down, num k) => px.hand(g, x, y, down, k);

  @override
  void heart(Ctx g, num x, num y, num s) => px.heart(g, x, y, s);

  @override
  void spot(Ctx g, List<num> b, int a) => px.spot(g, b, a, E.SW, E.SH);

  @override
  void bub(Ctx g, String k, num tx, num ty, int a) =>
      _signs.bub(g, k, tx, ty, a);

  // juego.js: respBox
  /// An answer bubble's box, or null.
  List<num>? respBox(String k) => _signs.respBox(k);

  @override
  List<num> bx(String k) => _signs.bx(k);

  // juego.js: fx
  @override
  void fx(Map<String, dynamic> e) {
    e['f0'] = F;
    (W['fx'] as List<dynamic>).add(e);
  }

  // ---------- moving things ----------

  // juego.js: at
  @override
  bool at(String k) => atView(cam, _cams[k]!);

  // juego.js: camGo
  @override
  Future<void> camGo(String k, [int? n]) {
    if (at(k)) return Future<void>.value();
    final m = _camA = _CamMove(CamSlide(from: cam, to: _cams[k]!, f0: F, n: n));
    return m.done.future;
  }

  // juego.js: hopTo
  @override
  Future<void> hopTo(num x, num y, int hops, [num? s1]) async {
    final q = W['cq'] as Map<String, dynamic>,
        x0 = q['x'] as num,
        y0 = q['y'] as num,
        s0 = q['s'] as num;
    s1 ??= s0;
    for (var h = 0; h < hops; h++) {
      SFX.hop();
      q['s'] = jsRound((s0 + (s1 - s0) * (h + 1) / hops) * 100) / 100;
      const n = 5;
      for (var i = 1; i <= n; i++) {
        final t = (h + i / n) / hops;
        q['x'] = jsRound(x0 + (x - x0) * t);
        q['y'] = jsRound(y0 + (y - y0) * t);
        q['dy'] = -7 * math.sin(math.pi * i / n);
        await wait(TICK);
      }
      q['dy'] = 0;
      await wait(110);
    }
  }

  // juego.js: bounce
  @override
  void bounce([num? h]) {
    final q = W['cq'] as Map<String, dynamic>;
    var i = 0;
    late final int t;
    t = timers.setInterval(() {
      i++;
      q['dy'] = -(h == null || h == 0 ? 6 : h) * math.sin(math.pi * i / 5);
      if (i >= 5) {
        q['dy'] = 0;
        timers.clear(t);
      }
    }, TICK);
  }

  // juego.js: poke
  /// A touch that is not an answer: it reacts and gets its name. Poking around is free.
  @override
  void poke(String what, ({int x, int y}) p) {
    if (what == 'coqui') {
      bounce(6);
      final names = S['names'];
      final nm = names is Map ? names['coqui'] as String? : null;
      if (nm != null && nm.isNotEmpty && VOICE && _has(nm)) {
        if (speaking == 0) unawaited(playClip(nm));
      } else {
        SFX.coqui();
      }
      return;
    }
    SFX.blip();
    fx({
      't': 'star',
      'n': 7,
      'pts': [
        [p.x - 7, p.y - 4],
        [p.x + 8, p.y + 2],
        [p.x, p.y - 10],
      ],
    });
    E.poke(what);
  }

  // ---------- a touch ----------

  /// A touch on the picture at ([x], [y]) in the scene's own pixels (juego.js: `tap`). The screen maps a tap on the
  /// display picture to the scene's picture with `displayToPicture` first.
  void tap(num x, num y) {
    bool inb(List<num>? b) =>
        b != null &&
        x >= b[0] - 3 &&
        x < b[0] + b[2] + 3 &&
        y >= b[1] - 3 &&
        y < b[1] + b[3] + 3;
    String? what;
    final resp = W['resp'];
    if (resp is List) {
      for (final k in resp) {
        if (inb(respBox(k as String))) {
          what = k;
          break;
        }
      }
    }
    what ??= E.hit(x, y, W);
    if (what == null) return;
    tapThing(what, x, y);
  }

  // juego.js: tap (the start of its `if(pn&&!pn.done)` branch)
  /// What a touch on [what] counts as while [pn] is waited for: before the door has a name, the door is the house
  /// (`loose`), and a story may let one thing stand for another (`alias`).
  String touchedAs(Pending pn, String what) {
    var w = what;
    if (pn.loose && (w == 'puerta' || w == 'ventana')) w = 'casa';
    final al = pn.alias;
    if (al != null && jsTruthy(al[w])) w = al[w] as String;
    return w;
  }

  // juego.js: tap, from the hit test on
  /// A touch on a named thing, at ([x], [y]). [tap] finds the thing by the hit test; a player with no screen names it.
  void tapThing(String what, num x, num y) {
    final p = (x: jsRound(x), y: jsRound(y));
    if (_habOcupado() &&
        !(pending != null &&
            !pending!.done &&
            pending!.kind == 'elige' &&
            pending!.live.contains(what))) {
      return; // listening or processing a speaking turn: a touch does nothing
    }
    final pn = pending;
    final apodo = W['apodo'];
    final names = S['names'];
    String? nm;
    if (apodo is Map && jsTruthy(apodo[what])) {
      nm = apodo[what] as String;
    } else if (names is Map && jsTruthy(names[what])) {
      nm = names[what] as String;
    }
    if (pn != null && !pn.done) {
      final w = touchedAs(pn, what);
      if (pn.live.contains(w) && !(pn.lock && !pn.asked)) {
        pn.done = true;
        pn.ms = pn.tEnd != null && pn.tEnd != 0
            ? jsRound((now() - pn.tEnd!) * FAST)
            : 0;
        pn.p = p;
        pn.got = w;
        hush();
        pn.res();
        return;
      }
      final resp = W['resp'];
      if (resp is List && resp.contains(what)) {
        return; // a bubble that is still speaking
      }
      if (pn.voz && what == 'coqui' && pn.asked) {
        bounce(5);
        pn.repite(); // touch the frog: the bubbles speak again
        return;
      }
      poke(what, p);
      if (what == 'coqui') return;
      if (pn.asked && !pn.turnoOn) {
        _emitTouchFeedback(TouchFeedbackKind.miss, what);
      }
      if (nm != null && speaking == 0 && !pn.busy) {
        pn.busy = true;
        // name what was touched, then ask again
        unawaited(() async {
          await playClip(nm!);
          await sleep(300);
          if (identical(pending, pn) &&
              !pn.done &&
              pn.asked &&
              pn.line != null &&
              pn.line!.isNotEmpty) {
            await playClip(pn.line!);
          }
          pn.busy = false;
        }());
      }
      return;
    }
    if (running) {
      final busy = speaking;
      poke(what, p);
      if (what != 'coqui' && nm != null && busy == 0) unawaited(playClip(nm));
    }
  }

  // ---------- the signal for a right move ----------

  // juego.js: senal
  void senal(String t, ({int x, int y})? p, bool quieto) {
    if (OIR) {
      if (!quieto) bounce(4);
      return;
    }
    final rb = respBox(t);
    List<num> b;
    if (rb != null) {
      final f = px.frogBox(W['cq'] as Map<String, dynamic>);
      b = [f.x, f.y, f.w, f.h];
    } else {
      b = bx(t);
    }
    if (rb != null || p == null) {
      p = (x: jsRound(b[0] + b[2] / 2), y: jsRound(b[1] + b[3] / 2));
    }
    final callado = jsTruthy(S['callado']);
    if (!callado) SFX.right();
    if (!quieto && !callado) bounce(8);
    fx({
      't': 'star',
      'n': 16,
      'pts': [
        [b[0] + 4, b[1] + 2],
        [b[0] + b[2] - 4, b[1] + 4],
        [jsRound(b[0] + b[2] / 2), b[1] - 6],
        [b[0] - 4, jsRound(b[1] + b[3] / 2)],
        [b[0] + b[2] + 4, jsRound(b[1] + b[3] / 2)],
        [p.x, p.y - 9],
      ],
    });
  }

  // juego.js: bien
  @override
  Future<void> bien([String? id]) {
    if (OIR || jsTruthy(S['callado'])) return Future<void>.value();
    return wait(300).then((_) {
      final own = S['bien'];
      return say(
        id != null && id.isNotEmpty
            ? id
            : (own is String && own.isNotEmpty
                  ? own
                  : course.fixedClip('story_praise')),
        350,
      );
    });
  }

  // ---------- the story ----------

  /// `$name` filled from the story's variables (juego.js: `sub`).
  String fill(String s) => subS(s);

  // juego.js: pasos
  @override
  Future<void> pasos(List<Object?>? list) async {
    final L = list ?? const <Object?>[];
    for (var i = 0; i < L.length; i++) {
      obs.pasosItem(L, i);
      await paso(L[i]);
    }
  }

  // juego.js: paso
  @override
  Future<void> paso(Object? st) {
    final kind = stepKind(st);
    String? id, act;
    if (kind == 'line') {
      id = subS(st);
    } else if (kind == 'say') {
      id = subS((st as Map)['say']);
    } else if (kind == 'act') {
      act = (st as Map)['act'] as String?;
    }
    return obs.step(st, kind, id, act, () => paso0(st));
  }

  // juego.js: espera
  @override
  Future<Map<String, dynamic>> espera(
    List<String> liveSet,
    List<Object?>? lead,
    String? line, [
    Map<String, dynamic>? o,
  ]) async =>
      (await _esperaW(liveSet, lead, line, EsperaOpts.fromMap(o))).asMap();

  // juego.js: baraja
  @override
  List<T> baraja<T>(List<T> a) => barajaList(a);

  // ---------- running it ----------

  // juego.js: step
  /// Lights the first [n] progress dashes.
  void step(num n) {
    // `dots.forEach((d, i) => d.classList.toggle("on", i < n))`: a dash is lit when its index is under n
    view.dotsLit = n <= 0 ? 0 : n.ceil();
    view.changed();
  }

  // juego.js: foot
  @override
  void foot(bool a, bool b, bool c, [bool d = false]) {
    view.foot = StoryFoot(next: a, again: b, home: c, map: d);
    view.changed();
  }

  // juego.js: estado
  @override
  void estado(String s, [bool nopic = false]) {
    view.screen = switch (s) {
      'play' => StoryScreenState.play,
      'end' => StoryScreenState.end,
      _ => StoryScreenState.start,
    };
    view.noPic = nopic;
    view.changed();
  }

  // juego.js: pantalla
  void _pantalla(String? h) {
    view.title = h ?? '';
    view.changed();
  }

  /// The start disc (juego.js: `#go` click).
  Future<void> start() {
    unawaited(clips.unlock().catchError((Object _) {}));
    return run();
  }

  // juego.js: run
  /// Plays the story from its beginning. Completes when the end screen is up, or at once when the play was left.
  Future<void> run() async {
    _t0 = now();
    runId++;
    final my = runId;
    hush();
    habLimpia();
    HAB.log = [];
    SFX.calla();
    callaLetras();
    fresh();
    running = true;
    step(0);
    view.startShown = false;
    foot(false, false, false);
    estado('play');
    _pantalla('');
    unawaited(_refreshSpeech());
    await Future.any<void>([voiceReady, sleep(6000)]);
    if (my != runId) return;
    try {
      await pasos(S['beats'] as List<Object?>?);
      await pasos(S['final'] as List<Object?>?);
    } on StopSignal {
      return;
    }
    if (options.recordsProgress) {
      if (!OIR && !jsTruthy(S['tipo'])) {
        S['_lost'] = W['lost'];
        progress.storyFinished(
          StoryResult(
            id: S['id'] as String,
            focusWords: [
              for (final w in (S['focus_words'] as List?) ?? const [])
                w as String,
            ],
            backAgain: [
              for (final w in (S['back_again'] as List?) ?? const [])
                w as String,
            ],
            lost: (W['lost'] as num).toInt(),
            log: LOG,
          ),
        );
      } else {
        progress.listened(storyId);
      }
      progress.addMinutes((now() - _t0) / 6e4);
    }
    step(view.dots);
    await sleep(1200 / FAST);
    if (my != runId) return;
    running = false;
    // juego.js: `!!(S.next&&!OIR)`. One difference, on purpose: a story the course (datos/curso.json) does not name does not
    // exist for the app (the shell opens no address for it), so a `next` that is not one of the course's stories is no next:
    // the end screen is the one of a story with no `next` (Map takes the main place). This is how a story file can lead on to
    // a staged story before the course lists it (coqui/AGENTS.md, "Stories staged by another session").
    final next = S['next'];
    final nx =
        jsTruthy(next) && !OIR && next is String && course.meta(next) != null;
    estado('end');
    _pantalla(S['title'] as String?);
    foot(nx, true, !nx, nx);
  }

  // juego.js: salir
  /// The X: all sound stops. The caller then goes where he came from.
  void leave() {
    runId++;
    try {
      hush();
      SFX.calla();
    } catch (_) {
      // juego.js: `try{hush();SFX.calla();}catch(e){}`
    }
    habLimpia();
    view.touchFeedback = null;
    callaLetras();
  }

  // ---------- what a test or a player reads (juego.js: window.Story) ----------

  /// `Story.pending`: the touch the story waits for, or null.
  Pending? get pendingNow => pending != null && !pending!.done ? pending : null;

  /// `Story.cap`: the caption shown, or "".
  String get cap => view.captionOn ? view.caption : '';

  /// `Story.bub`: the bubble's words shown, or "".
  String get bubText => view.bubbleOn && view.bubbleKind == BubbleKind.words
      ? view.bubbleText
      : '';

  /// `Story.hab`: the turns' state.
  Map<String, dynamic> get hab => {
    'est': HAB.est,
    'n': HAB.n,
    'hechos': HAB.hechos.toList(),
    'log': [for (final r in HAB.log) Map<String, dynamic>.of(r)],
    'bub': view.bubbleOn
        ? (view.bubbleKind == BubbleKind.words
              ? 'texto'
              : view.bubbleKind == BubbleKind.tick
              ? 'ok'
              : 'mic')
        : '',
    'at': BUBQ,
    'mic': view.mic,
    'disp': _habDisp(),
  };

  /// Can this phone take a turn? (juego.js: `habDisp`; also what Yo asks, for its once-a-day note)
  bool habDisp() => _habDisp();

  // juego.js: `MICB` click
  /// The mic button. The tap starts the recogniser inside the tap itself (the phone wants that).
  void tapMic() {
    final C = HAB.cur;
    if (C != null && HAB.est == 'ready') habEmpieza(C);
  }

  // juego.js: habMarca
  /// The targets of a marked clip, or null.
  List<Target>? habMarca(String id) {
    final cl = LINES[id];
    final t = cl is Map ? cl['tu_turno'] : null;
    if (t is! List || t.isEmpty) return null;
    final out = <Target>[];
    for (final x in t) {
      if (x is! Map) return null;
      final p = x['palabra'], f = x['formas'];
      if (p is! String || f is! List || f.isEmpty) return null;
      out.add((palabra: p, formas: [for (final e in f) e as String]));
    }
    return out;
  }

  /// The turns' record (juego.js: `HAB.log`).
  List<Map<String, dynamic>> get habLog => HAB.log;
}
