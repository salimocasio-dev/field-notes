// What the tests of feature_words share: services on the fakes, a course made to measure, seeding, and helpers.
import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 86 400 000 ms.
const day = Duration(days: 1);

/// A clip player whose clips end when the test says so (or when they are stopped, cut off).
class GateClips extends FakeClipPlayer {
  final List<Completer<bool>> open = [];

  @override
  Future<bool> play(String clipId, {Duration? limit}) {
    played.add(clipId);
    final c = Completer<bool>();
    open.add(c);
    return c.future;
  }

  /// Every clip that is playing reaches its end (or is cut off).
  void finish({bool toEnd = true}) {
    for (final c in [...open]) {
      if (!c.isCompleted) c.complete(toEnd);
    }
    open.clear();
  }

  @override
  Future<void> stop() async {
    stops++;
    finish(toEnd: false);
  }
}

/// The services of a test, each fake within reach.
class Rig {
  Rig({FakeCourseCatalog? course, FakeClipPlayer? clips, FakeClock? clock})
    : clock = clock ?? FakeClock(),
      course = course ?? FakeCourseCatalog(),
      clips = clips ?? FakeClipPlayer() {
    progress = FakeProgressStore(clock: this.clock);
    services = fakeServices(
      clock: this.clock,
      progress: progress,
      course: this.course,
      clips: this.clips,
      nav: nav,
      haptics: haptics,
      pictures: pictures,
    );
  }

  final FakeClock clock;
  final FakeCourseCatalog course;
  final FakeClipPlayer clips;
  final FakeNavigator nav = FakeNavigator();
  final FakeHaptics haptics = FakeHaptics();
  final FakePictureSource pictures = FakePictureSource();
  late final FakeProgressStore progress;
  late final Services services;

  int get now => clock.nowMs();

  /// A record as the store keeps it: [ear] and [mouth] are stages, [due] is the ear's return in days from now
  /// (null: never), [mouthN] is how many times the mouth was asked.
  void word(
    String w, {
    int ear = 1,
    int mouth = 0,
    int mouthN = 0,
    double? due,
    double? dueMs,
  }) {
    final r = WordRecord(
      w: w,
      primera: now,
      ear: SkillRecord(
        etapa: ear,
        due: dueMs ?? (due == null ? 0 : now + due * 864e5),
      ),
      mouth: SkillRecord(etapa: mouth, n: mouthN),
    );
    progress.put(r);
  }

  /// A played story: its entry in the store says `n` 1.
  void played(String id) => progress.storyFinished(StoryResult(id: id));

  /// Stories 1 to 3 of the sample course played, and every word they bring heard (ear stage 1). Returns the
  /// words in the order the store has them.
  Future<List<String>> playSampleStories() async {
    for (final id in const [
      'la-lluvia',
      'el-bizcocho',
      'donde-esta-el-pajaro',
    ]) {
      final t = await course.story(id);
      progress.storyFinished(
        StoryResult(
          id: id,
          focusWords: [...(t['focus_words'] as List).cast<String>()],
          backAgain: [
            ...((t['back_again'] as List?) ?? const []).cast<String>(),
          ],
        ),
      );
    }
    return [for (final r in progress.words) r.w];
  }
}

/// A course made to measure: [places] are `{id, n, nombre, en, cuentos}`; [stories] by id are story files
/// (`title`, `focus_words`, `back_again`, `clips`, `leer`); [pairs] are the words that have a review pair.
/// A story id of a place that has no file in [stories] is a story whose file does not arrive.
FakeCourseCatalog madeCourse({
  required List<Map<String, Object?>> places,
  Map<String, Map<String, Object?>> stories = const {},
  List<String> pairs = const [],
}) {
  final files = <String, String>{
    'datos/curso.json': jsonEncode({
      'lugares': places,
      'cuentos': {
        for (final id in stories.keys)
          id: {'t': (stories[id]!['title'] as String?) ?? id, 'min': 1},
      },
      'cual': ['cual-t'],
    }),
    'cuentos/cual-t.json': jsonEncode({
      'scene': 'frente',
      'items': [
        for (final w in pairs)
          {
            'w': w,
            'say': 'x',
            'si': {
              'cam': [1, 2, 3, 4],
            },
            'no': {
              'cam': [5, 6, 7, 8],
            },
          },
      ],
    }),
    'datos/nivel.json': '[]',
    'datos/llamadas.json': '{}',
    'datos/fijos.json': '{"clips":{},"despedidas":[]}',
    'audio/marcas.json': '{}',
    for (final e in stories.entries)
      'cuentos/${e.key}.json': jsonEncode(e.value),
  };
  return FakeCourseCatalog(
    fetch: (p) async => files[p] ?? (throw StateError('no file $p')),
  );
}

Map<String, Object?> place(
  String id,
  int n,
  String name,
  List<String> stories,
) => {'id': id, 'n': n, 'nombre': name, 'en': name, 'cuentos': stories};

/// Opens the tab on a phone of [size] css px at [ratio], and waits until it is drawn.
Future<void> pumpTab(
  WidgetTester tester,
  Rig rig, {
  Size size = const Size(390, 844),
  double ratio = 3,
}) async {
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FeatureDevApp(module: const WordsModule(), services: rig.services),
  );
  await tester.pumpAndSettle();
}

Finder card(String word) =>
    find.byWidgetPredicate((w) => w is WordCard && w.word == word);

/// Touches a card: scrolled into view first.
Future<void> tapCard(WidgetTester tester, String word) async {
  await tester.ensureVisible(card(word));
  await tester.pumpAndSettle();
  await tester.tap(card(word));
  await tester.pumpAndSettle();
}

/// The words of the cards, from the top of the page to its foot (left before right).
List<String> cardOrder(WidgetTester tester) {
  final cs = tester.widgetList<WordCard>(find.byType(WordCard)).toList();
  final at = {for (final c in cs) c.word: tester.getTopLeft(card(c.word))};
  final ws = at.keys.toList()
    ..sort((a, b) {
      final dy = at[a]!.dy.compareTo(at[b]!.dy);
      return dy != 0 ? dy : at[a]!.dx.compareTo(at[b]!.dx);
    });
  return ws;
}

/// The headings of the places, in the order they stand.
List<String> placeHeadings(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    if (identical(t.style, CoquiText.h2) &&
        t.data != 'Add a word or a goal' &&
        t.data != 'Heard in')
      t.data!,
];

/// The text of the Repaso card's grey line and its button.
({String line, String button, bool enabled}) repaso(WidgetTester tester) {
  final b = tester.widget<CoquiButton>(
    find.byWidgetPredicate(
      (w) => w is CoquiButton && (w.label == 'Start' || w.label == 'Practice'),
    ),
  );
  final line = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .firstWhere(
        (t) => t == 'Nothing due today' || t.contains(' today · about '),
      );
  return (line: line, button: b.label, enabled: b.onPressed != null);
}

/// How many dots of each meter of [of] are filled: [ear, mouth].
List<int> dots(WidgetTester tester, Finder of) {
  final meters = find.descendant(of: of, matching: find.byType(SkillMeter));
  return [
    for (var i = 0; i < 2; i++)
      find
          .descendant(
            of: meters.at(i),
            matching: find.byWidgetPredicate(
              (w) =>
                  w.key is ValueKey &&
                  '${(w.key! as ValueKey).value}'.endsWith('on'),
            ),
          )
          .evaluate()
          .length,
  ];
}

/// The sheet and what is in it.
Finder get sheet => find.byType(CoquiSheet);
Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
