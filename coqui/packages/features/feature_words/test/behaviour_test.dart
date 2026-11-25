// Behavioural tests for feature_words: WordsTab reactivity & race guards,
// AddBox sheet ("+ Add a word or goal"), WordSheet ("Heard in", comesBack,
// clip playback and closing).
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// A story file with the given lines (`id: text`).
Map<String, Object?> story(
  String title, {
  List<String> focus = const [],
  List<String> back = const [],
  Map<String, String> lines = const {},
  List<String>? leer,
}) => {
  'title': title,
  'focus_words': focus,
  'back_again': back,
  'clips': {
    for (final e in lines.entries) e.key: {'who': 'abuela', 'text': e.value},
  },
  'leer': ?leer,
};

void main() {
  group('WordsTab reactivity and review actions', () {
    testWidgets(
      'only tracked words appear in their skill tab (ear > 0 for Listening; mouth > 0 or mouth.n > 0 for Speaking)',
      (tester) async {
        final rig = Rig();
        rig.word('oida', ear: 1, due: 1);
        rig.word('dicha', ear: 0, mouth: 0, mouthN: 2, mouthDue: 1);
        rig.word('nada', ear: 0, mouth: 0, mouthN: 0);
        await pumpTab(tester, rig);
        expect(rowOrder(tester), ['oida']);

        await tester.tap(find.text('Speaking · 0'));
        await tester.pumpAndSettle();
        expect(rowOrder(tester), ['dicha']);
      },
    );

    testWidgets(
      'nothing met: empty message, due card 0, and Practice is disabled',
      (tester) async {
        final rig = Rig();
        await pumpTab(tester, rig);
        expect(dueCardCount(tester), '0');
        expect(find.text('words come\nback today'), findsOneWidget);
        expect(find.text('WHEN YOUR 0 WORDS COME BACK'), findsOneWidget);
        expect(
          find.text(
            'Play the first story on the map. Your words show up here.',
          ),
          findsOneWidget,
        );
        expect(
          (reviewButton(tester).label, reviewButton(tester).enabled),
          ('Practice', false),
        );
        expect(find.text('+ Add a word or goal'), findsOneWidget);
      },
    );

    testWidgets(
      'Start review asks for ReviewRoute() and ticks; Practice asks for ReviewRoute(practice: true)',
      (tester) async {
        final due = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['casa']),
            },
            pairs: ['casa'],
          ),
        );
        due.played('s1');
        due.word('casa', ear: 3, due: -1);
        await pumpTab(tester, due);
        await tester.tap(find.text('Start review'));
        await tester.pump();
        expect(due.nav.routes, [const ReviewRoute()]);
        expect(due.haptics.ticks, 1);

        final none = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['casa']),
            },
            pairs: ['casa'],
          ),
        );
        none.played('s1');
        none.word('casa', ear: 3, due: 4);
        await pumpTab(tester, none);
        await tester.tap(find.text('Practice'));
        await tester.pump();
        expect(none.nav.routes, [const ReviewRoute(practice: true)]);
      },
    );

    testWidgets(
      'Practice is disabled when nothing is due and nothing can be asked; tapping does nothing',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['con']),
            },
            pairs: ['casa'],
          ),
        );
        rig.played('s1');
        rig.word('con', ear: 1, due: 2);
        await pumpTab(tester, rig);
        expect(
          (reviewButton(tester).label, reviewButton(tester).enabled),
          ('Practice', false),
        );
        await tester.tap(find.text('Practice'));
        await tester.pump();
        expect(rig.nav.routes, isEmpty);
      },
    );

    testWidgets(
      'an answer saved elsewhere refreshes due count, stage bars, and word list',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['casa', 'puerta']),
            },
            pairs: ['casa', 'puerta'],
          ),
        );
        rig.played('s1');
        rig.word('casa', ear: 2, due: -1);
        await pumpTab(tester, rig);
        expect(dueCardCount(tester), '1');
        expect(stageBarValues(tester, wordRow('casa')), [2]);
        expect(wordRow('puerta'), findsNothing);

        rig.word('casa', ear: 4, mouth: 1, mouthN: 1, due: 21, mouthDue: 2);
        rig.word('puerta', ear: 1, due: -1);
        await tester.pumpAndSettle();
        expect(dueCardCount(tester), '1');
        expect(rowOrder(tester), ['puerta', 'casa']);
        expect(stageBarValues(tester, wordRow('puerta')), [1]);
        expect(stageBarValues(tester, wordRow('casa')), [4]);
        expect(find.text('Listening · 1'), findsOneWidget);
      },
    );

    testWidgets('a slower load overtaken by a newer save is dropped', (
      tester,
    ) async {
      final slow = _SlowCatalog(
        places: [
          place('a', 1, 'Place one', ['s1']),
        ],
        stories: {
          's1': story('S1', focus: ['uno', 'dos']),
        },
      );
      final rig = Rig(course: slow);
      rig.played('s1');
      rig.word('uno', ear: 1, due: 1);
      slow.hold = true;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        FeatureDevApp(module: const WordsModule(), services: rig.services),
      );
      await tester.pump();
      expect(wordRow('uno'), findsNothing, reason: 'first load is waiting');
      slow.hold = false;
      rig.word('dos', ear: 2, due: 2);
      await tester.pumpAndSettle();
      expect(rowOrder(tester), ['uno', 'dos']);
      slow.release();
      await tester.pumpAndSettle();
      expect(rowOrder(tester), ['uno', 'dos']);
    });

    testWidgets(
      'disposing the tab while an async load is in flight throws nothing',
      (tester) async {
        final slow = _SlowCatalog(
          places: [
            place('a', 1, 'Place one', ['s1']),
          ],
          stories: {
            's1': story('S1', focus: ['uno', 'dos']),
          },
        );
        final rig = Rig(course: slow);
        rig.played('s1');
        rig.word('uno', ear: 1, due: 1);
        await pumpTab(tester, rig);
        expect(rowOrder(tester), ['uno']);
        slow.hold = true;
        rig.word('dos', ear: 2, due: 2);
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        slow.release();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a tap on a word row ticks and opens its NocheSheet', (
      tester,
    ) async {
      final rig = Rig();
      await rig.playSampleStories();
      await pumpTab(tester, rig);
      await tapWordRow(tester, 'casa');
      expect(rig.haptics.ticks, 1);
      expect(sheet, findsOneWidget);
    });
  });

  group('Add a word or goal (header pill -> AddBox sheet)', () {
    Future<Rig> openAddSheet(WidgetTester tester, {Rig? rig}) async {
      final r = rig ?? Rig();
      await pumpTab(tester, r);
      await tester.tap(find.text('+ Add a word or goal'));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      return r;
    }

    testWidgets('an empty or whitespace-only field saves nothing', (
      tester,
    ) async {
      final rig = await openAddSheet(tester);
      await tester.tap(inSheet(find.text('Add')));
      await tester.pumpAndSettle();
      await tester.enterText(inSheet(find.byType(TextField)), '   ');
      await tester.tap(inSheet(find.text('Add')));
      await tester.pumpAndSettle();
      expect(rig.progress.added, isEmpty);
      expect(find.text('Saved. Material for it comes later.'), findsNothing);
    });

    testWidgets(
      'trimmed input is saved, field clears, and saved list updates live inside sheet',
      (tester) async {
        final rig = await openAddSheet(tester);
        await tester.enterText(
          inSheet(find.byType(TextField)),
          '  talk to my 1-year-old  ',
        );
        await tester.tap(inSheet(find.text('Add')));
        await tester.pumpAndSettle();
        expect(rig.progress.added, ['talk to my 1-year-old']);
        expect(
          tester
              .widget<TextField>(inSheet(find.byType(TextField)))
              .controller!
              .text,
          '',
        );
        expect(
          inSheet(find.text('Saved. Material for it comes later.')),
          findsOneWidget,
        );
        expect(inSheet(find.text('· talk to my 1-year-old')), findsOneWidget);

        await tester.enterText(inSheet(find.byType(TextField)), 'abuela');
        await tester.tap(inSheet(find.text('Add')));
        await tester.pumpAndSettle();
        expect(rig.progress.added, ['talk to my 1-year-old', 'abuela']);
        expect(
          tester.getTopLeft(inSheet(find.text('· talk to my 1-year-old'))).dy,
          lessThan(tester.getTopLeft(inSheet(find.text('· abuela'))).dy),
        );
      },
    );

    testWidgets('previously saved items show when the sheet opens', (
      tester,
    ) async {
      final rig = Rig();
      rig.progress.add('uno');
      rig.progress.add('dos');
      await openAddSheet(tester, rig: rig);
      expect(inSheet(find.text('· uno')), findsOneWidget);
      expect(inSheet(find.text('· dos')), findsOneWidget);
      expect(
        inSheet(find.text('Saved. Material for it comes later.')),
        findsOneWidget,
      );
    });
  });

  group('WordSheet: Heard in (oidoEn)', () {
    Rig made(
      Map<String, Map<String, Object?>> stories, {
      List<String> played = const [],
    }) {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1', 's2']),
            place('b', 2, 'Place two', ['s3']),
          ],
          stories: stories,
        ),
        clips: GateClips(),
      );
      for (final id in played) {
        rig.played(id);
      }
      rig.word('casa', ear: 2, due: 1);
      return rig;
    }

    List<String> heardLines(WidgetTester tester) =>
        [
              for (final r in tester.widgetList<RichText>(
                inSheet(find.byType(RichText)),
              ))
                r.text.toPlainText(),
            ]
            .where(
              (t) =>
                  t != 'casa' &&
                  Language.spanish.normalize(t).contains(' casa '),
            )
            .toList();

    testWidgets(
      'only played stories; round-robin across stories; at most five lines',
      (tester) async {
        final rig = made(
          {
            's1': story(
              'S1',
              lines: {
                'a1': 'Una casa.',
                'a2': 'Otra casa.',
                'a3': 'Tercera casa.',
              },
            ),
            's2': story(
              'S2',
              lines: {
                'b1': 'La casa de b.',
                'b2': 'Casa dos.',
                'b3': 'Casa tres.',
              },
            ),
            's3': story('S3', lines: {'c1': 'No jugada: casa.'}),
          },
          played: ['s1', 's2'],
        );
        await pumpTab(tester, rig);
        await tapWordRow(tester, 'casa');
        expect(heardLines(tester), [
          'Una casa.',
          'La casa de b.',
          'Otra casa.',
          'Casa dos.',
          'Tercera casa.',
        ]);
        expect(sheetPlayButtons, findsNWidgets(5));
      },
    );

    testWidgets('stories appear in course order, not play order', (
      tester,
    ) async {
      final rig = made({
        's1': story('S1', lines: {'a1': 'Casa de s1.'}),
        's2': story('S2', lines: {'b1': 'Casa de s2.'}),
        's3': story('S3', lines: {'c1': 'Casa de s3.'}),
      });
      for (final id in ['s3', 's2', 's1']) {
        rig.played(id);
      }
      await pumpTab(tester, rig);
      await tapWordRow(tester, 'casa');
      expect(heardLines(tester), ['Casa de s1.', 'Casa de s2.', 'Casa de s3.']);
    });

    testWidgets('deduplicates lines and ignores accents/case', (tester) async {
      final rig = made(
        {
          's1': story('S1', lines: {'a1': '¡CASA!', 'a2': 'Mi casa.'}),
          's2': story('S2', lines: {'b1': '¡Casa!', 'b2': 'Tu Casa.'}),
        },
        played: ['s1', 's2'],
      );
      await pumpTab(tester, rig);
      await tapWordRow(tester, 'casa');
      expect(heardLines(tester), ['¡CASA!', 'Mi casa.', 'Tu Casa.']);
    });

    testWidgets('a story\'s leer list comes first, then its other lines', (
      tester,
    ) async {
      final rig = made(
        {
          's1': story(
            'S1',
            lines: {'a1': 'Casa uno.', 'a2': 'Casa dos.'},
            leer: ['a2'],
          ),
        },
        played: ['s1'],
      );
      await pumpTab(tester, rig);
      await tapWordRow(tester, 'casa');
      expect(heardLines(tester), ['Casa dos.', 'Casa uno.']);
    });

    testWidgets('word heard in no line omits Heard in section', (tester) async {
      final rig = made(
        {
          's1': story('S1', lines: {'a1': 'Una puerta.'}),
        },
        played: ['s1'],
      );
      await pumpTab(tester, rig);
      await tapWordRow(tester, 'casa');
      expect(inSheet(find.text('HEARD IN')), findsNothing);
      expect(sheetPlayButtons, findsNothing);
      expect(inSheet(find.byType(NocheStageBar)), findsNWidgets(2));
    });
  });

  group('WordSheet: picture, meters, closing, comesBack, and audio', () {
    Future<Rig> rigged(WidgetTester tester, {FakeClipPlayer? clips}) async {
      final rig = Rig(
        clips: clips,
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1']),
          ],
          stories: {
            's1': story(
              'S1',
              focus: ['casa', 'con'],
              lines: {'a1': 'Una casa.', 'a2': 'Con la casa.'},
            ),
          },
          pairs: ['casa'],
        ),
      );
      rig.played('s1');
      rig.word('casa', ear: 3, mouth: 1, mouthN: 1, due: 2);
      rig.word('con', ear: 1, due: 1);
      await pumpTab(tester, rig);
      return rig;
    }

    testWidgets('opening sheet stops current clip playback', (tester) async {
      final rig = await rigged(tester);
      final before = rig.clips.stops;
      await tapWordRow(tester, 'casa');
      expect(rig.clips.stops, greaterThan(before));
    });

    testWidgets('pair word shows yes picture; plain word shows no picture', (
      tester,
    ) async {
      final rig = await rigged(tester);
      final pair = rig.course.pairs.single;
      rig.pictures.shown.clear();
      await tapWordRow(tester, 'casa');
      expect(rig.pictures.shown.map((r) => r.toString()).toSet(), {
        PictureRef.of(pair, pair.yes).toString(),
      });
      await closeSheet(tester);
      rig.pictures.shown.clear();
      await tapWordRow(tester, 'con');
      expect(rig.pictures.shown, isEmpty);
    });

    testWidgets('close button, scrim tap, and downward drag close the sheet', (
      tester,
    ) async {
      final rig = await rigged(tester);
      await tapWordRow(tester, 'casa');
      expect(sheet, findsOneWidget);
      await closeSheet(tester);
      expect(sheet, findsNothing);

      await tapWordRow(tester, 'casa');
      await tester.tapAt(const Offset(195, 60));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);

      await tapWordRow(tester, 'casa');
      await tester.drag(sheetCloseButton, const Offset(0, 200));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(rig.nav.routes, isEmpty);
    });

    testWidgets('sheet shows snapshot of Ear and Mouth stages on open', (
      tester,
    ) async {
      final rig = await rigged(tester);
      await tapWordRow(tester, 'casa');
      expect(stageBarValues(tester, sheet), [3, 1]);
      rig.word('casa', ear: 4, mouth: 4, mouthN: 4, due: 9);
      await tester.pumpAndSettle();
      expect(stageBarValues(tester, sheet), [3, 1]);
      await closeSheet(tester);
      expect(stageBarValues(tester, wordRow('casa')), [4]);
    });

    testWidgets('comesBack formats return line inside WordSheet', (
      tester,
    ) async {
      Future<String?> back({double? due}) async {
        final rig = Rig();
        rig.word('casa', ear: 3, due: due);
        await pumpTab(tester, rig);
        await tapWordRow(tester, 'casa');
        final t = tester
            .widgetList<Text>(inSheet(find.byType(Text)))
            .map((w) => w.data)
            .whereType<String>()
            .where((s) => s.startsWith('Comes back'));
        final res = t.isEmpty ? null : t.single;
        await closeSheet(tester);
        return res;
      }

      expect(await back(), isNull);
      expect(await back(due: -3), 'Comes back today');
      expect(await back(due: 1), 'Comes back in 1 day');
      expect(await back(due: 4.4), 'Comes back in 4 days');
    });

    testWidgets(
      'Heard in play button preloads, plays, toggles pause, switches lines, and stops on close',
      (tester) async {
        final clips = GateClips();
        final rig = Rig(
          clips: clips,
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story(
                'S1',
                focus: ['casa'],
                lines: {'a1': 'Una casa.', 'a2': 'Otra casa.'},
              ),
            },
          ),
        );
        rig.played('s1');
        rig.word('casa', ear: 3, due: 1);
        await pumpTab(tester, rig);
        await tapWordRow(tester, 'casa');

        NocheIconData iconOf(int index) => tester
            .widget<NocheIcon>(
              find.descendant(
                of: sheetPlayButtons.at(index),
                matching: find.byType(NocheIcon),
              ),
            )
            .data;

        expect(iconOf(0), NocheIcons.play);
        await tester.tap(sheetPlayButtons.at(0));
        await tester.pump();
        expect(clips.preloaded, ['a1']);
        expect(clips.played, ['a1']);
        expect(iconOf(0), NocheIcons.pause);
        expect(iconOf(1), NocheIcons.play);

        // Tap second line switches playback.
        await tester.tap(sheetPlayButtons.at(1));
        await tester.pump();
        await tester.pump();
        expect(clips.played, ['a1', 'a2']);
        expect(iconOf(0), NocheIcons.play);
        expect(iconOf(1), NocheIcons.pause);

        // Second tap on active line stops playback.
        await tester.tap(sheetPlayButtons.at(1));
        await tester.pump();
        expect(iconOf(1), NocheIcons.play);

        // Tap again, then close sheet -> stops clip immediately.
        await tester.tap(sheetPlayButtons.at(0));
        await tester.pump();
        expect(iconOf(0), NocheIcons.pause);
        final stopsBeforeClose = clips.stops;
        await closeSheet(tester);
        expect(clips.stops, greaterThan(stopsBeforeClose));
        expect(clips.open.where((c) => !c.isCompleted), isEmpty);
      },
    );
  });
}

/// A catalog whose `load()` waits while [hold] is true, until [release].
class _SlowCatalog extends FakeCourseCatalog {
  _SlowCatalog({
    required List<Map<String, Object?>> places,
    required Map<String, Map<String, Object?>> stories,
  }) : super(
         fetch: madeCourse(places: places, stories: stories).fetch,
       );

  bool hold = false;
  final List<Completer<void>> _waiting = [];

  void release() {
    for (final c in _waiting) {
      c.complete();
    }
    _waiting.clear();
  }

  @override
  Future<void> load() async {
    if (hold) {
      final c = Completer<void>();
      _waiting.add(c);
      await c.future;
    }
    return super.load();
  }
}
