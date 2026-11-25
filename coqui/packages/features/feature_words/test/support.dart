// Shared test helpers for feature_words: services on the fakes, custom course
// builder, seeding, and widget finders for Noche Words.
import 'dart:async';
import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:feature_words/src/words_tab.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 86 400 000 ms.
const day = Duration(days: 1);

/// A clip player whose clips end when the test says so (or when stopped).
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

  /// Seeds a word record: [ear] and [mouth] are stages, [due] is ear return in
  /// days from now (null: unscheduled), [mouthDue] is mouth return in days from
  /// now (null: unscheduled), [mouthN] is how many times mouth was asked.
  void word(
    String w, {
    int ear = 1,
    int mouth = 0,
    int mouthN = 0,
    double? due,
    double? dueMs,
    double? mouthDue,
    double? mouthDueMs,
    int earAparc = 0,
    int mouthAparc = 0,
  }) {
    final r = WordRecord(
      w: w,
      primera: now,
      ear: SkillRecord(
        etapa: ear,
        due: dueMs ?? (due == null ? 0 : now + due * 864e5),
        aparcada: earAparc,
      ),
      mouth: SkillRecord(
        etapa: mouth,
        n: mouthN,
        due: mouthDueMs ?? (mouthDue == null ? 0 : now + mouthDue * 864e5),
        aparcada: mouthAparc,
      ),
    );
    progress.put(r);
  }

  /// Sets the stored CEFR level band (e.g. `'A1'` or `'A2'`).
  void setCefr(String cefr) {
    final raw = jsonDecode(progress.export()) as Map<String, dynamic>;
    raw['nivel'] = <String, dynamic>{
      't': now,
      'log': <Object?>[],
      'historias': 0,
      'cefr': cefr,
    };
    progress.import(jsonEncode(raw));
  }

  /// A played story: its entry in the store says `n` 1.
  void played(String id) => progress.storyFinished(StoryResult(id: id));

  /// Stories 1 to 3 of the sample course played, and every word they bring heard.
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

/// A custom course catalog for tests.
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

/// Opens the tab on a phone of [size] logical px at [ratio], and waits until drawn.
Future<void> pumpTab(
  WidgetTester tester,
  Rig rig, {
  Size size = const Size(390, 844),
  double ratio = 3,
  int? stageMax,
  WordsSkill initialSkill = WordsSkill.listening,
}) async {
  tester.view.physicalSize = size * ratio;
  tester.view.devicePixelRatio = ratio;
  addTearDown(tester.view.reset);
  if (stageMax == null && initialSkill == WordsSkill.listening) {
    await tester.pumpWidget(
      FeatureDevApp(module: const WordsModule(), services: rig.services),
    );
  } else {
    await tester.pumpWidget(
      MaterialApp(
        theme: coquiTheme(),
        home: Scaffold(
          backgroundColor: NocheColors.ground,
          body: WordsTab(
            services: rig.services,
            stageMax: stageMax,
            initialSkill: initialSkill,
          ),
        ),
      ),
    );
  }
  await tester.pumpAndSettle();
}

/// Finder for one word row on the Words screen.
Finder wordRow(String word) => find.byKey(ValueKey('word-row:$word'));

/// Scrolls a word row into view and taps it.
Future<void> tapWordRow(WidgetTester tester, String word) async {
  final finder = wordRow(word);
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Visible word rows ordered from top to bottom.
List<String> rowOrder(WidgetTester tester) {
  final rows = tester
      .widgetList<Pressable>(
        find.byWidgetPredicate(
          (w) =>
              w is Pressable &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('word-row:'),
        ),
      )
      .toList();
  final at = {
    for (final r in rows)
      (r.key! as ValueKey<String>).value.substring('word-row:'.length): tester
          .getTopLeft(find.byWidget(r)),
  };
  final words = at.keys.toList()
    ..sort((a, b) => at[a]!.dy.compareTo(at[b]!.dy));
  return words;
}

/// The bottom "Start review" / "Practice" button state.
({String label, bool enabled}) reviewButton(WidgetTester tester) {
  final button = tester.widget<NochePrimaryButton>(
    find.byKey(const Key('words-review-button')),
  );
  return (label: button.label, enabled: button.onPressed != null);
}

/// The number shown in the due card.
String dueCardCount(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('words-due-count'))).data!;

/// The open [NocheSheet] and widgets inside it.
Finder get sheet => find.byType(NocheSheet);
Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);

/// The close button inside the open [NocheSheet].
Finder get sheetCloseButton =>
    inSheet(find.bySemanticsLabel(NocheA11y.label(NocheA11y.closeSheet)));

/// Closes the currently open [NocheSheet].
Future<void> closeSheet(WidgetTester tester) async {
  await tester.tap(sheetCloseButton);
  await tester.pumpAndSettle();
}

/// All play buttons inside the open [WordSheet].
Finder get sheetPlayButtons => inSheet(
  find.byWidgetPredicate(
    (w) => w is Pressable && (w.semanticLabel?.startsWith('Play: ') ?? false),
  ),
);

/// Stage values of every [NocheStageBar] inside [of].
List<int> stageBarValues(WidgetTester tester, Finder of) => [
  for (final bar in tester.widgetList<NocheStageBar>(
    find.descendant(of: of, matching: find.byType(NocheStageBar)),
  ))
    bar.stage,
];
