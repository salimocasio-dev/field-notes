// Gate A: what a person sees while playing stories 1 to 3 (La lluvia, El bizcocho, Dónde está el pájaro) in the real app,
// saved as pictures. Six plays: each story twice, every answer right ("right") and every answer wrong first ("wrong").
//
//   cd coqui/app && flutter test tool/gate_a_frames_test.dart --dart-define=OUT=<dir>
//   (--dart-define=ONLY=la-lluvia-right,el-bizcocho-wrong plays just those)
//   (--dart-define=STORIES=el-jugo,que-calor plays these stories instead of stories 1 to 3, each with both plans)
//   (--dart-define=TXT=con|tras|no starts the app as the address `?txt=con|tras|no` does: when the story's words show; con is
//   the default)
//   (--dart-define=ASKW=yes writes the story's W and frame number at each ask picture into index.json)
//
// The real app shell on the harness's fakes (silent clips, the scripted recogniser, the fake clock), at the story's address
// on a 390 x 844 screen at ratio 2 (pictures of 780 x 1688), the real fonts, motion on. The tool only watches and touches:
// every touch is `tester.tapAt` on a point of the screen, time moves only by `tester.pump`, and the story's own state is
// read, never written.
//
// What a touch is: the learner of feature_story's `play.dart` (the rule for right and wrong; see `_Learner`). Where the
// story's state is read (the pending touch, the caption, the camera, the scene's hit test), the runner is reached through
// the public `runner` field of the play screen's `StoryPicture`, found by its class name as `stateNamed` / `byTypeName` of
// `test/support/harness.dart` find a feature's screen: feature_story exports neither the class nor the runner.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:app/src/switches.dart';
import 'package:coqui_pixel/coqui_pixel.dart'
    show
        Thing,
        displayH,
        displayW,
        displayToPicture,
        jsTruthy,
        pictureToDisplay;
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/support/harness.dart';
import 'gate_a_sheets.dart';

const String _out = String.fromEnvironment('OUT');
const String _only = String.fromEnvironment('ONLY');

/// `?txt=` of the address: when the story's words show (`con` while the line is spoken, `tras` right after, `no` never).
const String _txt = String.fromEnvironment('TXT', defaultValue: 'con');

/// The stories given by `STORIES` (ids, comma-separated), or, without it, the three stories of Gate A, all at El frente.
const String _storiesArg = String.fromEnvironment('STORIES');

/// `ASKW=yes`: each ask picture's entry in index.json also holds the story's W and frame number at that moment (`askW`,
/// `askF`), for a scene's test of its asks against its JS preview (coqui_scenes' tool/estufa_asks_ref.mjs --plays).
const bool _askW = String.fromEnvironment('ASKW') == 'yes';
final List<String> _stories = _storiesArg.isEmpty
    ? const ['la-lluvia', 'el-bizcocho', 'donde-esta-el-pajaro']
    : _storiesArg.split(',');
const List<String> _plans = ['right', 'wrong'];

const Size _screen = Size(390, 844);
const double _ratio = 2;

/// ms of the story's time, by what the orchestrator asked for.
const int _lineDelay = 400, _askDelay = 1000, _tapDelay = 300, _endDelay = 2000;

/// play.dart: the learner thinks 700 ms after a choice is ready.
const int _think = 700;

/// The story's time after which a play that has not ended is given up.
const int _limitMs = 5 * 60 * 1000;

/// What is written to `summary.json`, play by play (the plays run one after the other in this isolate).
final Map<String, Map<String, dynamic>> _summary = {};

// ---------------------------------------------------------------------------------------------------------------------
// fonts

/// `flutter test` loads none of the pubspec's fonts (every glyph would be a box). The files of coqui_ui, under the family
/// names its text styles use (`packages/coqui_ui/...`, as `type_test.dart` of coqui_ui loads them), and Roboto under its
/// plain name too for what asks for it without the package.
Future<void> _loadFonts() async {
  final dir = '$repoRoot/coqui/packages/core/coqui_ui';
  Future<void> load(String family, Iterable<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('packages/coqui_ui/Roboto', coquiFontFiles.values);
  await load('Roboto', coquiFontFiles.values);
  const pixelify = [
    'fonts/PixelifySans-Regular.ttf',
    'fonts/PixelifySans-Bold.ttf',
  ];
  await load('packages/coqui_ui/Pixelify Sans', pixelify);
  await load('Pixelify Sans', pixelify);
}

// ---------------------------------------------------------------------------------------------------------------------
// the learner: play.dart's rule

/// El frente has no list of things (frente.js: `hit()` only): the order the wrong-touch rule reads them in, and the
/// condition `hit()` tests for each. Copied from `feature_story/tool/frente_order.dart` (`frenteThingOrder`), which is not
/// part of any package's public surface.
final List<(String, bool Function(Map<String, dynamic>))> _frenteOrder = [
  ('abuela', (W) => jsTruthy(W['ab'])),
  ('palma_pequena', (W) => jsTruthy(W['escondite'])),
  ('casa_pequena', (W) => jsTruthy(W['escondite'])),
  ('palma_grande', (W) => jsTruthy(W['escondite'])),
  ('casa_grande', (W) => jsTruthy(W['escondite'])),
  (
    'pajaro',
    (W) {
      final a = W['ave'];
      return a is Map && jsTruthy(a) && a['mode'] != 'none';
    },
  ),
  ('bizcocho', (W) => W['plato'] != null),
  ('nube', (W) => jsTruthy(W['storm']) && jsTruthy(W['nube'])),
  ('puerta', (W) => true),
  ('ventana', (W) => true),
  ('casa', (W) => true),
  ('sol', (W) => !jsTruthy(W['storm'])),
  ('palma', (W) => true),
];

/// What the learner knows of one pending touch (play.dart: `_EsperaInfo`): its role among the esperas of its step.
class _Info {
  _Info(this.role, this.step);

  /// play.dart's roles: `first` (the first wait of an ask, a decide or an elige), `again` (a later wait of the same step),
  /// `retry` (the wait for the right one after a wrong decide).
  final String role;

  /// The kind of the step that role `first` belongs to: `ask`, `decide` or `elige`.
  final String step;
  String? letter;
  String? poked;
}

/// What the learner will do next, and when it is the same situation as before (play.dart: `_Want`).
class _Want {
  _Want(this.key, this.kind, this.k, this.why, this.pn);

  final String key;

  /// `touch` or `mic`.
  final String kind;
  final String? k;
  final String why;
  final dynamic pn;
}

/// play.dart's `_Driver`, made to read the runner of the real screen (through [runner]) instead of being given the
/// observer's notes: the roles of the waits are read from the order they come in (see [_role]).
class _Learner {
  _Learner(this.plan, this.runner, this.speech);

  final String plan;
  final dynamic Function() runner;

  /// The harness's scripted recogniser: what it is to hear is written into its `results`, as play.dart writes into the
  /// stub.
  final dynamic speech;
  int letters = 0;
  final Map<Object, _Info> info = HashMap.identity();
  final Map<Object, String> turnLetter = HashMap.identity();
  final Map<Object, Map<String, Object>> keys = HashMap.identity();
  dynamic previous;
  final List<Map<String, dynamic>> speechEvents = [];

  dynamic get r => runner();
  Map<String, dynamic> get W => r.W as Map<String, dynamic>;

  String letterFor() {
    final k = letters++;
    return plan == 'right'
        ? 'r'
        : plan == 'wrong'
        ? 'w'
        : (k % 2 == 0 ? 'r' : 'w');
  }

  /// A new pending touch has appeared: which wait of its step it is. play.dart reads this off the observer, which the real
  /// screen does not give; here it comes from the wait's own fields and the one before it:
  /// - a `decide` wait right after a `decide` wait of the same things and the same pick that was answered wrongly is
  ///   `again` (an answer that costs nothing: the step asks again);
  /// - an `ask` wait for just the pick of the `decide` wait before it, that was answered wrongly, is `retry`;
  /// - everything else is the `first` wait of a step of its kind.
  _Info register(dynamic pn) {
    final prev = previous;
    var role = 'first';
    final kind = pn.kind as String;
    if (prev != null && prev.done == true) {
      final wrongBefore = prev.kind == 'decide' && prev.got != prev.pick;
      final live = (pn.live as List).cast<String>();
      if (kind == 'decide' &&
          wrongBefore &&
          pn.pick == prev.pick &&
          _same(live, (prev.live as List).cast<String>())) {
        role = 'again';
      } else if (kind == 'ask' &&
          wrongBefore &&
          live.length == 1 &&
          live.first == prev.pick) {
        role = 'retry';
      }
    }
    previous = pn;
    return info[pn] = _Info(role, kind);
  }

  bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // the things the wrong-touch rule reads, in order
  List<String> sceneList() {
    final W = this.W;
    if (r.S['scene'] == 'frente') {
      return [
        for (final e in _frenteOrder)
          if (e.$2(W)) e.$1,
      ];
    }
    return [
      for (final Thing t in (r.E.cosas as List).cast<Thing>())
        if ((t.si == null || t.si!(W)) && _boxOf(t, W) != null) t.id,
    ];
  }

  Object? _boxOf(Thing t, Map<String, dynamic> W) {
    final b = t.box;
    return b is Function ? b(W) : b;
  }

  // as tap() maps a touch
  bool counts(dynamic pn, String w) =>
      (pn.live as List).contains(r.touchedAs(pn, w));

  // an ask: the first thing in the scene's list that is not the asked one and that the touch would not count as it
  String? wrongPoke(dynamic pn) {
    final resp = W['resp'];
    for (final k in sceneList()) {
      if (k != 'coqui' &&
          !counts(pn, k) &&
          !(resp is List && resp.contains(k))) {
        return k;
      }
    }
    return null;
  }

  /// The story's own `decide` step for the wait [pn] (play.dart is handed it by the observer): the step of the story file
  /// whose options the wait's live things begin with and whose pick it is. Read from the file only.
  Map<String, dynamic>? decideStep(dynamic pn) {
    final live = (pn.live as List).cast<String>();
    Map<String, dynamic>? found;
    void walk(Object? x) {
      if (found != null) return;
      if (x is Map) {
        final opts = x['options'];
        if (x['decide'] != null && opts is List) {
          final ops = [for (final o in opts) r.fill(o as String) as String];
          final pickOk =
              !jsTruthy(x['pick']) ||
              r.fill(x['pick'] as String) == pn.pick ||
              ops.contains(pn.pick);
          if (ops.length <= live.length &&
              _same(ops, live.sublist(0, ops.length)) &&
              pickOk) {
            found = x.cast<String, dynamic>();
            return;
          }
        }
        x.values.forEach(walk);
      } else if (x is List) {
        x.forEach(walk);
      }
    }

    walk(r.S);
    return found;
  }

  // a decide: the first live thing that is not the right one, not also right ("vale") and not free ("gratis")
  String? wrongOption(dynamic pn, Map<String, dynamic> st) {
    final vale = [
      for (final v in (st['vale'] as List? ?? const []))
        r.fill(v as String) as String,
    ];
    final gratis = (st['gratis'] as Map? ?? const {}).keys
        .cast<String>()
        .toList();
    final al = pn.alias as Map?;
    for (final k in (pn.live as List).cast<String>()) {
      if (k != pn.pick &&
          !vale.contains(k) &&
          !gratis.contains(k) &&
          !(al != null && (al[k] == pn.pick || vale.contains(al[k])))) {
        return k;
      }
    }
    return null;
  }

  _Info infoOf(dynamic pn) => info[pn] ?? register(pn);

  /// The learner's next move, or null when nothing is waiting for him (play.dart: `learner()`).
  _Want? want() {
    final r = this.r;
    final hab = r.HAB;
    if (hab.est == 'ready' && hab.cur != null) {
      // a speaking turn waits for the mic
      final p = r.pending;
      final pn = p != null && p.done != true ? p : null;
      return _Want('mic|${identityHashCode(hab.cur)}', 'mic', null, 'turn', pn);
    }
    final pn = r.pending;
    if (pn == null ||
        pn.done == true ||
        pn.asked != true ||
        pn.tEnd == null ||
        pn.busy == true ||
        r.speaking != 0 ||
        hab.est == 'listening' ||
        hab.est == 'processing') {
      return null;
    }
    final I = infoOf(pn);
    if (I.role == 'first' && I.letter == null) I.letter = letterFor();
    final live = (pn.live as List).cast<String>();
    String k, why;
    if (I.role != 'first') {
      k =
          I.role == 'retry' &&
              pn.pick != null &&
              (pn.pick as String).isNotEmpty &&
              live.contains(pn.pick)
          ? pn.pick as String
          : live[0];
      why = I.role;
    } else if (I.step == 'ask') {
      if (I.letter == 'w' && I.poked == null) {
        final c = wrongPoke(pn);
        if (c != null) {
          k = c;
          why = 'wrong-poke';
        } else {
          k = live[0];
          why = 'right (no wrong thing to touch)';
        }
      } else {
        k = live[0];
        why = 'right';
      }
    } else if (I.step == 'decide') {
      if (I.letter == 'w') {
        final st = decideStep(pn);
        final c = st == null ? null : wrongOption(pn, st);
        if (c != null) {
          k = c;
          why = 'wrong';
        } else {
          k = pn.pick as String? ?? '';
          why = 'right (no wrong option)';
        }
      } else {
        k = pn.pick != null && (pn.pick as String).isNotEmpty
            ? pn.pick as String
            : live[0];
        why = 'right';
      }
    } else {
      k = I.letter == 'w' && live.length > 1 ? live[1] : live[0];
      why = I.letter == 'w' ? 'second' : 'first';
    }
    final kk = keys[pn] ??= <String, Object>{};
    final key = kk['$k|$why'] ??= Object();
    return _Want(
      '${identityHashCode(pn)}|${identityHashCode(key)}',
      'touch',
      k,
      why,
      pn,
    );
  }

  /// Whether the story took the answer of [pn] as the right one: what `decide` calls `first` (the pick, or a `vale`). A
  /// touch that answers an ask or an elige is right; one that answers a decide with anything else is not (the step
  /// goes on to its `wrong` branch, or asks again for a free answer).
  bool isRight(dynamic pn) {
    if (pn.kind != 'decide') return true;
    final st = decideStep(pn);
    final vale = [
      for (final v in (st?['vale'] as List? ?? const []))
        r.fill(v as String) as String,
    ];
    return pn.got == pn.pick || vale.contains(pn.got);
  }

  /// A touch has been made for [w] (play.dart: the act of a touch want).
  void touched(_Want w) {
    final I = info[w.pn];
    if (w.why == 'wrong-poke') I?.poked = w.k;
  }

  /// A speaking turn's answer, written into the recogniser before the mic is touched (play.dart's act of a mic want).
  /// Right plan: the right words; wrong plan: nothing is heard (an elige turn: the second option's words).
  Map<String, dynamic> scriptTurn(_Want w) {
    final r = this.r;
    final reg = (r.HAB.log as List).last as Map;
    final pn = w.pn;
    final i = pn != null ? info[pn] : null;
    if (turnLetter[reg] == null) {
      turnLetter[reg] = i != null ? (i.letter ??= letterFor()) : letterFor();
    }
    final letter = turnLetter[reg]!;
    var ans = 'none';
    if (letter == 'r' || reg['tipo'] == 'elige') {
      var id = reg['id'] as String;
      if (reg['tipo'] == 'elige') {
        final ids = id.split('|');
        id = ids[letter == 'r' ? 0 : (ids.length < 2 ? ids.length - 1 : 1)];
      }
      final targets = r.habMarca(id);
      ans = targets != null
          ? (targets as List).map((x) => (x.formas as List)[0]).join(' ')
          : 'none';
    }
    final results = speech.results as List<String>;
    final at = speech.used as int;
    while (results.length <= at) {
      results.add('none');
    }
    results[at] = ans;
    final ev = <String, dynamic>{
      'turn': reg['id'],
      'tipo': reg['tipo'],
      'letter': letter,
      'says': ans,
      'listen': at,
      'habSi': r.HAB.si,
    };
    speechEvents.add(ev);
    return ev;
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// where a touch lands

List<num> _nums(Object? x) => [for (final n in x! as List) n as num];

/// A point on the screen, with the story's own coordinates for it.
class _Point {
  _Point(this.screen, this.dx, this.dy, this.px, this.py, this.how, this.what);

  final Offset screen;
  final int dx, dy;
  final double px, py;

  /// What the story's rule for a touch gives at this point (it is the thing asked for).
  final String? what;

  /// `hand` / `box` (play.dart's own point for a touch), or `region` (the middle of what the hit test gives the thing).
  final String how;
}

/// Where on the screen a finger lands to touch the thing [k], or null when no point of the view does. The story takes a
/// touch as `StoryPicture` hands it over: the display pixel is mapped back to the picture with the camera, the answer
/// bubbles are looked at first (a finger's slop of 3), then the scene's hit test. A point is good for [k] when that is
/// what that rule gives for it.
_Point? _pointFor(WidgetTester tester, dynamic r, String k) {
  final cam = [for (final n in r.cam as List) n as num];
  final W = r.W as Map<String, dynamic>;
  final rect = tester.getRect(
    find.descendant(
      of: byTypeName('StoryPicture'),
      matching: find.byType(PixelView),
    ),
  );
  String? whatAt(int dx, int dy) {
    final p = displayToPicture(cam, dx, dy);
    final resp = W['resp'];
    if (resp is List) {
      for (final name in resp) {
        final raw = r.respBox(name as String);
        if (raw == null) continue;
        final b = _nums(raw);
        if (p.x >= b[0] - 3 &&
            p.x < b[0] + b[2] + 3 &&
            p.y >= b[1] - 3 &&
            p.y < b[1] + b[3] + 3) {
          return name;
        }
      }
    }
    return r.E.hit(p.x, p.y, W) as String?;
  }

  _Point at(int dx, int dy, String how) {
    final p = displayToPicture(cam, dx, dy);
    return _Point(
      Offset(
        rect.left + (dx + .5) * rect.width / displayW,
        rect.top + (dy + .5) * rect.height / displayH,
      ),
      dx,
      dy,
      p.x,
      p.y,
      how,
      whatAt(dx, dy),
    );
  }

  // play.dart's own point: the hand's point and 3 down, or the middle of the box
  final rb = r.respBox(k);
  final h = rb == null && r.E.handAt(k) != null ? _nums(r.E.handAt(k)) : null;
  num x, y;
  String how;
  if (h != null) {
    x = h[0];
    y = h[1] + 3;
    how = 'hand';
  } else {
    final b = _nums(r.bx(k));
    x = b[0] + b[2] / 2;
    y = b[1] + b[3] / 2;
    how = 'box';
  }
  final d = pictureToDisplay(cam, x, y);
  final dx = d.x.floor(), dy = d.y.floor();
  if (dx >= 0 && dx < displayW && dy >= 0 && dy < displayH) {
    if (whatAt(dx, dy) == k) return at(dx, dy, how);
  }
  // else the middle of the place the hit test gives to [k] in this view
  var n = 0;
  var sx = 0.0, sy = 0.0;
  final hits = <(int, int)>[];
  for (var j = 0; j < displayH; j++) {
    for (var i = 0; i < displayW; i++) {
      if (whatAt(i, j) == k) {
        hits.add((i, j));
        sx += i;
        sy += j;
        n++;
      }
    }
  }
  if (n == 0) return null;
  final mx = sx / n, my = sy / n;
  var best = hits.first;
  var bestD = double.infinity;
  for (final p in hits) {
    final dd = (p.$1 - mx) * (p.$1 - mx) + (p.$2 - my) * (p.$2 - my);
    if (dd < bestD) {
      bestD = dd;
      best = p;
    }
  }
  return at(best.$1, best.$2, 'region');
}

// ---------------------------------------------------------------------------------------------------------------------
// pictures

class _Shot {
  _Shot(this.kind, this.due, this.extra, this.seq);

  final String kind;
  final int due;
  final Map<String, dynamic> extra;
  final int seq;
}

/// One play's pictures on disk, and what the index says of them.
class _Recorder {
  _Recorder(this.tester, this.dir);

  final WidgetTester tester;
  final Directory dir;
  final List<Map<String, dynamic>> pictures = [];
  final List<Map<String, dynamic>> dropped = [];
  Uint8List? lastRaw;

  /// The whole screen now: PNG bytes and raw RGBA.
  Future<(Uint8List, Uint8List, int, int)> capture() async {
    // The display picture is turned into an image on a thread of the engine and arrives in real time: give it that, and
    // draw it, before the screen is read. No story time goes by (`pump()` with no duration).
    for (var i = 0; i < 2; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 12)),
      );
      await tester.pump();
    }
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final out = await tester.runAsync(() async {
      final image = await layer.toImage(view.paintBounds);
      final raw = Uint8List.fromList(
        (await image.toByteData())!.buffer.asUint8List(),
      );
      final png = Uint8List.fromList(
        (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
            .asUint8List(),
      );
      final r = (png, raw, image.width, image.height);
      image.dispose();
      return r;
    });
    return out!;
  }

  /// Takes a picture of kind [kind] at story time [ms]; keeps it unless it is the very picture before. Returns whether it
  /// was kept.
  Future<bool> shoot(String kind, int ms, Map<String, dynamic> extra) async {
    final (png, raw, w, h) = await capture();
    final prev = lastRaw;
    if (prev != null && prev.length == raw.length) {
      var same = true;
      for (var i = 0; i < raw.length; i++) {
        if (prev[i] != raw[i]) {
          same = false;
          break;
        }
      }
      if (same) {
        dropped.add({
          'kind': kind,
          'ms': ms,
          'sameAs': pictures.last['file'],
          ...extra,
        });
        return false;
      }
    }
    lastRaw = raw;
    final n = pictures.length + 1;
    final file = '${n.toString().padLeft(2, '0')}-$kind.png';
    File('${dir.path}/$file').writeAsBytesSync(png);
    pictures.add({
      'n': n,
      'file': file,
      'kind': kind,
      'ms': ms,
      'width': w,
      'height': h,
      ...extra,
    });
    return true;
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// a play

Future<Map<String, dynamic>> _play(
  WidgetTester tester,
  String story,
  String plan,
) async {
  final name = '$story-$plan';
  final dir = Directory('$_out/$name')..createSync(recursive: true);
  for (final f in dir.listSync().whereType<File>()) {
    if (RegExp(r'\.(png|json)$').hasMatch(f.path)) f.deleteSync();
  }
  final rec = _Recorder(tester, dir);
  final app = TestApp(tester);
  await app.open(
    stored: seed('vacio'),
    location: '/cuento/$story',
    // the switch the way the address carries it: the shell reads `?txt=` and hands it to the story
    switches: AppSwitches.fromQuery({'txt': _txt}),
    size: _screen,
    ratio: _ratio,
    reduceMotion: false,
  );
  await app.until(
    () =>
        find.byType(LessonStartButton).evaluate().isNotEmpty &&
        byTypeName('StoryPicture').evaluate().isNotEmpty,
    what: 'the story\'s start disc',
  );
  final dynamic runner =
      (tester.widget(byTypeName('StoryPicture')) as dynamic).runner;
  final learner = _Learner(plan, () => runner, app.speech);

  var t = 0; // the story's time: ms since the story opened
  var seq = 0;
  final queue = <_Shot>[];
  final touches = <Map<String, dynamic>>[];
  Map<String, dynamic>? stopped;
  int? startedAt, endAt;
  _Shot? askShot;
  String lastCap = '', lastBub = '';
  // The words the story holds for the line it is speaking, whether they show or not (with `TXT=no` the runner shows none, so
  // `caption` and `bubble` are empty): the text of the last line the clip player was asked for, from the story's own lines.
  var clipsSeen = 0;
  var lastSaid = '';
  var newLine = false;
  var lastCam = [for (final n in runner.cam as List) n as num];
  var lastCamChange = -100000;
  dynamic lastPn;
  String? wantKey;
  int? wantSince;

  Map<String, dynamic> screenInfo() {
    final cap = runner.cap as String, bub = runner.bubText as String;
    return {
      'caption': cap,
      'bubble': bub,
      'captionShown': cap.isEmpty ? null : find.text(cap).evaluate().isNotEmpty,
      'said': lastSaid,
      'cam': [for (final n in runner.cam as List) n],
    };
  }

  _Shot schedule(String kind, int due, [Map<String, dynamic>? extra]) {
    final s = _Shot(kind, due, extra ?? {}, seq++);
    queue.add(s);
    return s;
  }

  Future<void> shootNow(String kind, [Map<String, dynamic>? extra]) =>
      rec.shoot(kind, t, {
        ...screenInfo(),
        ...?extra,
        if (_askW && kind == 'ask') ...{
          'askW': jsonDecode(jsonEncode(runner.W, toEncodable: (_) => null)),
          'askF': runner.F,
        },
      });

  Future<void> fireDue() async {
    for (;;) {
      final due = [
        for (final s in queue)
          if (s.due <= t) s,
      ]..sort((a, b) => a.due != b.due ? a.due - b.due : a.seq - b.seq);
      if (due.isEmpty) return;
      final s = due.first;
      queue.remove(s);
      if (identical(s, askShot)) askShot = null;
      await shootNow(s.kind, s.extra);
    }
  }

  // 1. start
  await shootNow('start');

  // the start disc: a touch of the middle of the button
  Future<void> touchStart() async {
    final at = tester.getCenter(find.byType(LessonStartButton));
    await tester.tapAt(at);
    await tester.pump();
    startedAt = t;
    touches.add({
      'ms': t,
      'key': 'start',
      'why': 'start disc',
      'screen': [at.dx, at.dy],
    });
    schedule('tap', t + _tapDelay, {
      'touched': 'start',
      'right': null,
      'why': 'start disc',
    });
  }

  await touchStart();

  var endSeen = false;
  try {
    for (;;) {
      await app.advance(20);
      t += 20;

      // what changed on the screen
      final cap = runner.cap as String, bub = runner.bubText as String;
      if (cap != lastCap || bub != lastBub) {
        if (cap.isNotEmpty || bub.isNotEmpty) {
          schedule('line', t + _lineDelay);
        }
        lastCap = cap;
        lastBub = bub;
      }
      // a line the story began to speak (it reads the runner and the clip player, not the screen)
      final played = app.clips?.played ?? const <String>[];
      newLine = false;
      while (clipsSeen < played.length) {
        final line = (runner.LINES as Map)[played[clipsSeen++]];
        if (line is Map && line['text'] is String) {
          lastSaid = line['text'] as String;
          newLine = true;
        }
      }
      // with no words on the screen there is no caption change to take a 'line' picture on: take it as the line begins
      if (newLine && _txt == 'no') schedule('line', t + _lineDelay);
      final cam = [for (final n in runner.cam as List) n as num];
      var camSame = cam.length == lastCam.length;
      for (var i = 0; camSame && i < cam.length; i++) {
        camSame = cam[i] == lastCam[i];
      }
      if (!camSame) {
        // a slide is one change: a new one only after the view has stood still for a while
        if (t - lastCamChange >= 200) schedule('cut', t);
        lastCamChange = t;
        lastCam = cam;
      }
      final pn = runner.pending;
      if (pn != null && !identical(pn, lastPn)) {
        learner.infoOf(pn);
        lastPn = pn;
      }

      // the end screen
      if (!endSeen && find.text('Play again').evaluate().isNotEmpty) {
        endSeen = true;
        endAt = t;
        queue.removeWhere((s) => s.kind == 'ask' || s.kind == 'line');
        askShot = null;
        schedule('end', t);
        schedule('end', t + _endDelay);
      }

      await fireDue();
      if (endSeen) {
        if (t >= endAt! + _endDelay && queue.isEmpty) break;
        continue;
      }
      if (t > _limitMs) {
        stopped = {
          'ms': t,
          'reason':
              'the story did not reach its end screen in ${_limitMs ~/ 1000} s of story time',
          'pending': _pendingInfo(runner.pending),
        };
        await shootNow('stuck', {'stopped': stopped});
        break;
      }

      // the learner
      final want = learner.want();
      if (want == null) {
        wantKey = null;
        if (askShot != null) {
          queue.remove(askShot);
          askShot = null;
        }
        continue;
      }
      if (want.key != wantKey) {
        wantKey = want.key;
        wantSince = t;
        if (askShot != null) queue.remove(askShot);
        askShot = schedule('ask', t + _askDelay, {
          'waitingFor': want.k ?? 'mic',
          'live': want.pn == null ? null : [...(want.pn.live as List)],
        });
      }
      if (t - wantSince! < _think) continue;

      // act: the picture of the waiting screen, then the touch
      if (askShot != null) {
        final s = askShot!;
        queue.remove(s);
        askShot = null;
        await shootNow('ask', s.extra);
      }
      wantKey = null;
      if (want.kind == 'mic') {
        final mic = byTypeName('StoryMicButton');
        if (mic.evaluate().isEmpty) {
          stopped = {
            'ms': t,
            'reason': 'a speaking turn is waiting for the mic and there is no mic button on the screen',
            'pending': _pendingInfo(runner.pending),
          };
          await shootNow('stuck', {'stopped': stopped});
          break;
        }
        final said = learner.scriptTurn(want);
        final at = tester.getCenter(mic);
        await tester.tapAt(at);
        await tester.pump();
        touches.add({
          'ms': t,
          'key': 'mic',
          'why': 'turn',
          'screen': [at.dx, at.dy],
          'speech': said,
        });
        schedule('tap', t + _tapDelay, {
          'touched': 'mic',
          'right': null,
          'why': 'turn',
          'speech': said,
        });
        continue;
      }
      final k = want.k!;
      // an option no thing is named for is touched on the thing the step lets stand for it (`alias`: h-estufa's
      // olla_fria is olla0)
      final al = want.pn?.alias as Map?;
      final p =
          _pointFor(tester, runner, k) ??
          [
            for (final e in (al ?? const {}).entries)
              if (e.value == k) _pointFor(tester, runner, e.key as String),
          ].nonNulls.firstOrNull;
      if (p == null) {
        stopped = {
          'ms': t,
          'reason':
              'no point of the view touches "$k": the story waits for a touch the plan makes on it',
          'thing': k,
          'why': want.why,
          'pending': _pendingInfo(runner.pending),
          'cam': [for (final n in runner.cam as List) n],
        };
        await shootNow('stuck', {'stopped': stopped});
        break;
      }
      final pn2 = want.pn;
      final waiting = _pendingInfo(pn2);
      // what the finger meets at that point: the picture, or something over it (a speech bubble)
      final hitPath = _hitPath(tester, p.screen);
      final fxBefore = (runner.W['fx'] as List).length;
      await tester.tapAt(p.screen);
      await tester.pump();
      learner.touched(want);
      final answered = pn2.done == true && pn2.got != null;
      final right = answered && learner.isRight(pn2);
      final poked =
          (runner.W['fx'] as List).length > fxBefore || pn2.busy == true;
      final touch = {
        'ms': t,
        'key': k,
        'why': want.why,
        'right': right,
        'answered': answered,
        'result': answered
            ? (right ? 'answered right' : 'answered wrong')
            : poked
            ? 'poke: the story named it and asked again'
            : 'nothing happened',
        'reachesPicture': hitPath.$1,
        'hitPath': hitPath.$2,
        'got': pn2.got,
        'hitTest': p.what,
        'waiting': waiting,
        'after': {
          'busy': pn2.busy,
          'speaking': runner.speaking,
          'lastFx': (runner.W['fx'] as List).isEmpty
              ? null
              : (runner.W['fx'] as List).last['t'],
          'pendingIsSame': identical(runner.pending, pn2),
          'habEst': runner.HAB.est,
        },
        'screen': [p.screen.dx, p.screen.dy],
        'display': [p.dx, p.dy],
        'picture': [p.px, p.py],
        'point': p.how,
      };
      touches.add(touch);
      schedule('tap', t + _tapDelay, {
        'touched': k,
        'right': right,
        'why': want.why,
        'point': p.how,
        'result': touch['result'],
      });
    }
  } catch (e, s) {
    stopped = {'ms': t, 'reason': 'error: $e', 'stack': '$s'};
    try {
      await shootNow('stuck', {'stopped': stopped});
    } catch (_) {
      // no picture: the play stops anyway
    }
    tester.takeException();
  }
  final reached = endSeen;
  final sheets = await tester.runAsync(() => makeSheets(dir)) ?? 0;
  final index = {
    'story': story,
    'plan': plan,
    'txt': _txt,
    'screen': {
      'logical': [_screen.width, _screen.height],
      'ratio': _ratio,
      'pixels': [_screen.width * _ratio, _screen.height * _ratio],
    },
    'reachedEnd': reached,
    'stopped': stopped,
    'endMs': reached ? endAt : null,
    'storyMs': t,
    'pictures': rec.pictures,
    'dropped': rec.dropped,
    'touches': touches,
    'speech': learner.speechEvents,
    'letters': learner.letters,
    'sheets': sheets,
  };
  File('${dir.path}/index.json')
      .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(index));
  final result = <String, dynamic>{
    'pictures': rec.pictures.length,
    'sheets': sheets,
    'reachedEnd': reached,
    'storyMs': reached ? endAt : t,
    'playMs': reached && startedAt != null ? endAt! - startedAt! : null,
    'touches': touches.length,
    'duplicatesDropped': rec.dropped.length,
    'stopped': stopped,
  };
  await tester.pumpWidget(const SizedBox());
  return result;
}

/// Whether a touch at [at] reaches the picture (`RenderPixelView`), and the first render objects it meets.
(bool, List<String>) _hitPath(WidgetTester tester, Offset at) {
  final result = HitTestResult();
  tester.binding.hitTestInView(result, at, tester.view.viewId);
  final names = [for (final e in result.path) e.target.runtimeType.toString()];
  return (names.contains('RenderPixelView'), names.take(4).toList());
}

Map<String, dynamic>? _pendingInfo(dynamic pn) => pn == null
    ? null
    : {
        'kind': pn.kind,
        'live': [...(pn.live as List)],
        'pick': pn.pick,
        'sign': pn.sign,
        'lock': pn.lock,
        'voz': pn.voz,
        'asked': pn.asked,
        'busy': pn.busy,
        'done': pn.done,
        'tEnd': pn.tEnd,
      };

void _writeSummary() {
  File('$_out/summary.json').writeAsStringSync(
    const JsonEncoder.withIndent(' ').convert({
      'txt': _txt,
      'screen': {
        'logical': [_screen.width, _screen.height],
        'ratio': _ratio,
        'pixels': [_screen.width * _ratio, _screen.height * _ratio],
      },
      'plays': _summary,
    }),
  );
}

void main() {
  setUpAll(_loadFonts);
  final only = _only.isEmpty ? null : _only.split(',');
  for (final story in _stories) {
    for (final plan in _plans) {
      final name = '$story-$plan';
      if (only != null && !only.contains(name)) continue;
      testWidgets('gate A: $name', (tester) async {
        if (_out.isEmpty) {
          fail('give the folder: --dart-define=OUT=<dir>');
        }
        if (!const ['con', 'tras', 'no'].contains(_txt)) {
          fail('TXT is con, tras or no, not "$_txt"');
        }
        Directory(_out).createSync(recursive: true);
        _summary[name] = await _play(tester, story, plan);
        _writeSummary();
      }, timeout: const Timeout(Duration(minutes: 20)));
    }
  }
}
