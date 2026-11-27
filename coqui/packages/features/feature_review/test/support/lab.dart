// The bench of the widget tests: a lesson screen on the fakes, on a virtual clock. The clip player's clips last as
// long as the old harness says; the store is the fake (a recording one); the learner is a script.
import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/level_check.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/ui/level_check_screen.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/review_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../tool/support/scripted_clips.dart';
import '../../tool/support/virtual_time.dart';
import 'fixture_catalog.dart';
import 'recording_store.dart';

const int kNow = 1900000000000;
const int kDay = 86400000;

Map<String, dynamic> skillJson({
  int etapa = 0,
  num gap = 0,
  num due = 0,
  int aparcada = 0,
}) => {
  'etapa': etapa,
  'paso': 1,
  'seguidas': 0,
  'fallos': 0,
  'gap': gap,
  'due': due,
  'aciertos': <int>[],
  'ultima': 0,
  'aparcada': aparcada,
  'marca': 0,
  'n': 0,
  'bien': 0,
};

Map<String, dynamic> rec(String w, num due, {int etapa = 1, num gap = 1}) => {
  'w': w,
  'primera': due - kDay,
  'oida': 1,
  'ear': skillJson(etapa: etapa, gap: gap, due: due),
  'mouth': skillJson(),
};

String dbJson(List<Map<String, dynamic>> recs, {Object? nivel}) => jsonEncode({
  'palabras': {for (final r in recs) r['w'] as String: r},
  'dias': {},
  'cuentos': {},
  'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
  'minutos': 0,
  'v': 1,
});

final FixtureCatalog course = FixtureCatalog();

/// The words that have a pair, in file order (repaso_check.py: pair_words).
List<String> pairWords() {
  final out = <String>[];
  for (final p in course.pairs) {
    if (!out.contains(p.word)) out.add(p.word);
  }
  return out;
}

/// n words due before [now], the first the most overdue, written shuffled (repaso_check.py: due_recs).
({List<String> words, List<Map<String, dynamic>> recs}) dueRecs(
  int n,
  int now,
) {
  final ws = pairWords().take(n).toList();
  final recs = [
    for (var i = 0; i < ws.length; i++) rec(ws[i], now - (n - i) * 3600000),
  ];
  return (
    words: ws,
    recs: [
      for (var i = 0; i < recs.length; i += 2) recs[i],
      for (var i = 1; i < recs.length; i += 2) recs[i],
    ],
  );
}

void setPhone(WidgetTester t, double w, double h, double dpr) {
  t.view.devicePixelRatio = dpr;
  t.view.physicalSize = Size(w * dpr, h * dpr);
  addTearDown(t.view.reset);
}

double luminance(Color c) {
  double f(double v) =>
      v <= .03928 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  return .2126 * f(c.r) + .7152 * f(c.g) + .0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final x = luminance(a);
  final y = luminance(b);
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

/// What the fake picture source was asked for: the ref, the size in picture pixels and whether it moves.
typedef PictureAsk = ({PictureRef ref, int width, int height, bool animated});

/// The fake picture source, which also keeps how every picture was asked for.
class RecordingPictures extends FakePictureSource {
  /// Every call of [of], in order.
  final List<PictureAsk> asked = [];

  @override
  Widget of(
    PictureRef ref, {
    int width = 196,
    int height = 104,
    bool animated = false,
  }) {
    asked.add((ref: ref, width: width, height: height, animated: animated));
    return super.of(ref, width: width, height: height, animated: animated);
  }
}

class Lab {
  Lab(
    this.tester, {
    String? db,
    int seed = 1,
    bool silent = false,
    int storeNow = kNow,
  }) : vt = VirtualTime(settler: tester.idle) {
    store = RecordingStore(vt, clock: FakeClock(storeNow), json: db);
    clips = ScriptedClips(vt, ready: !silent);
    rng = FakeRng(seed);
    pictures = RecordingPictures();
    services = fakeServices(
      progress: store,
      course: course,
      clips: clips,
      clock: vt,
      rng: rng,
      nav: nav,
      pictures: pictures,
    );
  }

  final WidgetTester tester;
  final VirtualTime vt;
  late final RecordingStore store;
  late final ScriptedClips clips;
  late final FakeRng rng;
  late final RecordingPictures pictures;
  final FakeNavigator nav = FakeNavigator();
  late final Services services;
  final GlobalKey<ReviewScreenState> reviewKey = GlobalKey();
  final GlobalKey<LevelCheckScreenState> levelKey = GlobalKey();

  ReviewSession get s => reviewKey.currentState!.session;
  LevelCheckSession get lv => levelKey.currentState!.session;

  Future<void> openReview({
    ReviewOptions options = const ReviewOptions(),
    CaptionMode captions = CaptionMode.during,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ReviewScreen(
          key: reviewKey,
          services: services,
          options: options,
          captions: captions,
          wait: vt.wait,
        ),
      ),
    );
    await settle();
  }

  Future<void> openLevel({
    LevelOptions options = const LevelOptions(),
    CaptionMode captions = CaptionMode.during,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LevelCheckScreen(
          key: levelKey,
          services: services,
          options: options,
          captions: captions,
          wait: vt.wait,
        ),
      ),
    );
    await settle();
  }

  Future<void> settle() async {
    await vt.settle();
    await tester.pump();
  }

  /// The start disc is touched.
  Future<void> start() async {
    await tester.tap(find.byType(NochePlayDisc));
    await settle();
  }

  Future<void> advance(int ms) async {
    await vt.advance(ms);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> until(bool Function() done) async {
    await vt.runUntil(done);
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// A finger down on picture [k] (the old page takes `pointerdown`).
  Future<void> touchPicture(int k) async {
    final g = await tester.startGesture(
      tester.getCenter(find.byType(NochePictureChoice).at(k)),
    );
    await g.up();
    await settle();
  }

  List<NochePictureChoice> get choices => tester
      .widgetList<NochePictureChoice>(find.byType(NochePictureChoice))
      .toList();

  int get right => s.panels!.indexWhere((p) => p.right);

  /// Plays the session on: plan[k] = 'r' right, 'w' wrong, 'n' no touch for the k-th ask of the queue (the second
  /// asks too; a shown picture is touched right after); the rest right. [every] is called when ask k is ready.
  Future<List<String>> drive(
    String plan, {
    Future<void> Function(int k)? every,
    int limit = 200000,
    bool settleEnd = true,
  }) async {
    final seen = <String>[];
    var acted = -1;
    var shown = -1;
    {
      for (var i = 0; i < limit && s.screen != LessonScreen.end; i++) {
        final ps = s.panels;
        if (ps != null && s.ready && acted != s.index) {
          acted = s.index;
          final q = s.queue[s.index];
          seen.add('${q.pair.word}${q.again ? '*' : ''}');
          final want = s.index < plan.length ? plan[s.index] : 'r';
          final r = ps.indexWhere((p) => p.right);
          if (every != null) {
            await every(s.index);
          }
          if (want == 'r') s.touch(r);
          if (want == 'w') s.touch(1 - r);
        }
        if (ps != null && shown != s.index && ps.any((p) => p.sign)) {
          shown = s.index;
          s.touch(ps.indexWhere((p) => p.sign));
        }
        if (!vt.fireNext()) break;
        await vt.settle();
      }
    }
    if (settleEnd) {
      await tester.pump(const Duration(milliseconds: 1500));
    } else {
      await tester.pump();
    }
    return seen;
  }

  Future<void> driveLevel(
    bool Function(int story, int k) right, {
    int limit = 200000,
  }) async {
    var acted = -1;
    {
      for (var i = 0; i < limit && lv.screen != LessonScreen.end; i++) {
        final ps = lv.panels;
        if (ps != null && lv.ready && acted != lv.index) {
          acted = lv.index;
          final r = ps.indexWhere((p) => p.right);
          lv.touch(right(lv.currentStory ?? 0, lv.index) ? r : (r + 1) % 4);
        }
        if (!vt.fireNext()) break;
        await vt.settle();
      }
    }
    await tester.pump(const Duration(milliseconds: 400));
  }

  List<Map<String, Object?>> answerCalls() => [
    for (final c in store.calls)
      if (c['op'] == 'responde') c,
  ];
}
