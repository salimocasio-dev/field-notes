// One test for each behaviour of the old functions (app.html: palabras, extra, oidoEn, vuelve, palabra, oyeLinea)
// that leer_check.py does not cover. Each group is named after its function.
import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/feature_words.dart';
import 'package:feature_words/src/word_tile.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
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
  group('app.html: palabras', () {
    testWidgets(
      'only a word he has heard or said has a card (ear stage above 0 or mouth asked)',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['oida', 'dicha', 'nada']),
            },
          ),
        );
        rig.played('s1');
        rig.word('oida', ear: 1);
        rig.word('dicha', ear: 0, mouth: 0, mouthN: 2); // asked by mouth only
        rig.word(
          'nada',
          ear: 0,
          mouth: 0,
          mouthN: 0,
        ); // a record with nothing yet
        await pumpTab(tester, rig);
        expect(cardOrder(tester), ['oida', 'dicha']);
        expect(dots(tester, card('dicha')), [0, 0]);
      },
    );

    testWidgets(
      'nothing met: the tab says to play the first story, and Practice is off',
      (tester) async {
        final rig = Rig();
        await pumpTab(tester, rig);
        expect(
          find.text(
            'Play the first story on the map. Every word you hear shows up here, with how well you know it.',
          ),
          findsOneWidget,
        );
        expect(find.byType(WordTile), findsNothing);
        expect(find.byType(SkillKey), findsNothing);
        expect(find.text('All'), findsNothing, reason: 'no pills');
        expect(placeHeadings(tester), isEmpty);
        final r = repaso(tester);
        expect(
          (r.line, r.button, r.enabled),
          ('Nothing due today', 'Practice', false),
        );
        // "Add a word or a goal" is there all the same
        expect(find.text('Add a word or a goal'), findsOneWidget);
        expect(
          find.text('For example: "talk to my 1-year-old around the house".'),
          findsOneWidget,
        );
        expect(find.text('A word or a goal'), findsOneWidget);
      },
    );

    testWidgets(
      'a word no played story brings goes last, under "More words", in the store\'s order',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['uno']),
            },
          ),
        );
        rig.played('s1');
        rig.word('zeta');
        rig.word('uno');
        rig.word('alfa');
        await pumpTab(tester, rig);
        expect(placeHeadings(tester), ['Place one', 'More words']);
        expect(cardOrder(tester), ['uno', 'zeta', 'alfa']);
      },
    );

    testWidgets(
      'places in the course\'s order, words by the first story that brings them; a place with no word has no heading',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1', 's2']),
              place('b', 2, 'Place two', ['s3']),
              place('c', 3, 'Place three', ['s4']),
            ],
            stories: {
              's1': story('S1', focus: ['a1', 'a2']),
              's2': story('S2', focus: ['a3']),
              's3': story('S3', focus: ['b1']),
              's4': story('S4', focus: ['c1']),
            },
          ),
        );
        // played in another order than the course's, and the last place has no word in the store
        for (final id in ['s3', 's2', 's1', 's4']) {
          rig.played(id);
        }
        for (final w in ['b1', 'a3', 'a2', 'a1']) {
          rig.word(w);
        }
        await pumpTab(tester, rig);
        expect(placeHeadings(tester), ['Place one', 'Place two']);
        expect(cardOrder(tester), ['a1', 'a2', 'a3', 'b1']);
      },
    );

    testWidgets(
      'a word is placed by the focus-word pass first: a later story that brings it as a focus word wins over an earlier one that only brings it back',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
              place('b', 2, 'Place two', ['s2']),
            ],
            stories: {
              's1': story('S1', focus: ['p'], back: ['q']),
              's2': story('S2', focus: ['q'], back: ['r']),
            },
          ),
        );
        rig.played('s1');
        rig.played('s2');
        for (final w in ['r', 'q', 'p']) {
          rig.word(w);
        }
        await pumpTab(tester, rig);
        // q: focus word of s2 (place two), though s1 brings it back; r: back again, after the focus words
        expect(placeHeadings(tester), ['Place one', 'Place two']);
        expect(cardOrder(tester), ['p', 'q', 'r']);
        final two = tester.getTopLeft(find.text('Place two')).dy;
        expect(tester.getTopLeft(card('p')).dy < two, isTrue);
        expect(tester.getTopLeft(card('q')).dy > two, isTrue);
      },
    );

    testWidgets('a story he has not played brings nothing', (tester) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1', 's2']),
          ],
          stories: {
            's1': story('S1', focus: ['uno']),
            's2': story('S2', focus: ['dos']),
          },
        ),
      );
      rig.played('s1');
      rig.word('uno');
      rig.word('dos'); // heard some other way (the level check, a call)
      await pumpTab(tester, rig);
      expect(placeHeadings(tester), ['Place one', 'More words']);
      expect(cardOrder(tester), ['uno', 'dos']);
    });

    testWidgets('a played story whose file does not arrive is left out', (
      tester,
    ) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1', 'gone']),
          ],
          stories: {
            's1': story('S1', focus: ['uno']),
          },
        ),
      );
      rig.played('s1');
      rig.played('gone');
      rig.word('uno');
      rig.word('perdida');
      await pumpTab(tester, rig);
      expect(tester.takeException(), isNull);
      expect(placeHeadings(tester), ['Place one', 'More words']);
      expect(cardOrder(tester), ['uno', 'perdida']);
    });

    testWidgets('the key stands once, above the first heading', (tester) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1']),
            place('b', 2, 'Place two', ['s2']),
          ],
          stories: {
            's1': story('S1', focus: ['uno']),
            's2': story('S2', focus: ['dos']),
          },
        ),
      );
      rig.played('s1');
      rig.played('s2');
      rig.word('uno');
      rig.word('dos');
      rig.word('suelta');
      await pumpTab(tester, rig);
      for (final line in [SkillKey.ear, SkillKey.mouth]) {
        expect(find.text(line), findsOneWidget);
        expect(
          tester.getTopLeft(find.text(line)).dy,
          lessThan(tester.getTopLeft(find.text('Place one')).dy),
        );
      }
    });

    testWidgets(
      'a word is a pair word on its exact spelling (an accent or a capital makes it another word)',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['esta', 'está']),
            },
            pairs: ['está'],
          ),
        );
        rig.played('s1');
        rig.word('esta', ear: 3, due: -1);
        rig.word('está', ear: 3, due: -1);
        await pumpTab(tester, rig);
        expect(tester.widget<WordTile>(card('esta')).picture, isNull);
        expect(tester.widget<WordTile>(card('está')).picture, isNotNull);
        expect(
          repaso(tester).line,
          '1 word today · about 1 min',
          reason: 'only está can be asked',
        );
      },
    );

    testWidgets(
      'only words with a picture pair count as due: a due word without one is not "due today"',
      (tester) async {
        final rig = Rig(
          course: madeCourse(
            places: [
              place('a', 1, 'Place one', ['s1']),
            ],
            stories: {
              's1': story('S1', focus: ['con', 'casa']),
            },
            pairs: ['casa'],
          ),
        );
        rig.played('s1');
        rig.word('con', ear: 3, due: -2); // due, no pair
        rig.word('casa', ear: 3, due: 5); // a pair, not due
        await pumpTab(tester, rig);
        expect(rig.progress.due(Skill.ear), ['con']);
        final r = repaso(tester);
        expect((r.line, r.button), ('Nothing due today', 'Practice'));
        expect(r.enabled, isTrue, reason: 'casa can be asked');
      },
    );

    testWidgets('one due word: singular, and at least a minute', (
      tester,
    ) async {
      final rig = Rig(
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
      rig.played('s1');
      rig.word('casa', ear: 3, due: -1);
      await pumpTab(tester, rig);
      expect(repaso(tester).line, '1 word today · about 1 min');
    });

    testWidgets(
      'the minutes are n * 10 / 60 rounded, never under one; a session is at most 10 words',
      (tester) async {
        final expected = {1: 1, 3: 1, 5: 1, 6: 1, 8: 1, 9: 2, 10: 2, 12: 2};
        for (final e in expected.entries) {
          final words = [for (var i = 0; i < e.key; i++) 'w$i'];
          final rig = Rig(
            course: madeCourse(
              places: [
                place('a', 1, 'Place one', ['s1']),
              ],
              stories: {'s1': story('S1', focus: words)},
              pairs: words,
            ),
          );
          rig.played('s1');
          for (final w in words) {
            rig.word(w, ear: 3, due: -1);
          }
          await pumpTab(tester, rig);
          final n = e.key > 10 ? 10 : e.key;
          expect(
            repaso(tester).line,
            '$n word${n > 1 ? 's' : ''} today · about ${e.value} min',
            reason: '${e.key} due',
          );
        }
      },
    );

    testWidgets(
      'Start asks for a review session and a tap ticks; Practice asks for a practice session',
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
        await tester.tap(find.text('Start'));
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
      'Practice is off when nothing is due and nothing can be asked (only plain words heard); a touch does nothing',
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
        rig.word('con', ear: 1);
        await pumpTab(tester, rig);
        final r = repaso(tester);
        expect(
          (r.line, r.button, r.enabled),
          ('Nothing due today', 'Practice', false),
        );
        await tester.tap(find.text('Practice'));
        await tester.pump();
        expect(rig.nav.routes, isEmpty);
      },
    );

    testWidgets(
      'an answer given elsewhere (the store saves): the list and the Repaso card follow',
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
        expect(dots(tester, card('casa')), [2, 0]);
        expect(repaso(tester).line, '1 word today · about 1 min');
        expect(card('puerta'), findsNothing);

        rig.word(
          'casa',
          ear: 3,
          mouth: 1,
          mouthN: 1,
          due: 4,
        ); // answered right, and said once
        rig.word('puerta', ear: 1, due: -1);
        await tester.pumpAndSettle();
        expect(dots(tester, card('casa')), [3, 1]);
        expect(dots(tester, card('puerta')), [1, 0]);
        expect(repaso(tester).line, '1 word today · about 1 min');
        expect(cardOrder(tester), ['casa', 'puerta']);
      },
    );

    testWidgets('a drawing a newer one has overtaken is dropped', (
      tester,
    ) async {
      final slow = _SlowStories(
        places: [
          place('a', 1, 'Place one', ['s1']),
        ],
        stories: {
          's1': story('S1', focus: ['uno', 'dos']),
        },
      );
      final rig = Rig(course: slow);
      rig.played('s1');
      rig.word('uno');
      slow.hold = true; // the first drawing waits for the story file
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        FeatureDevApp(module: const WordsModule(), services: rig.services),
      );
      await tester.pump();
      expect(
        find.byType(WordTile),
        findsNothing,
        reason: 'the first drawing is waiting',
      );
      slow.hold = false;
      rig.word('dos'); // a save: the second drawing, which does not wait
      await tester.pump();
      await tester.pumpAndSettle();
      expect(cardOrder(tester), ['uno', 'dos']);
      slow.release(); // the first drawing arrives late, with one word fewer
      await tester.pumpAndSettle();
      expect(cardOrder(tester), ['uno', 'dos']);
    });

    testWidgets(
      'while it reads again after a save the page keeps what it showed; and a tab that is gone by then draws nothing and throws nothing',
      (tester) async {
        final slow = _SlowStories(
          places: [
            place('a', 1, 'Place one', ['s1']),
          ],
          stories: {
            's1': story('S1', focus: ['uno', 'dos']),
          },
        );
        final rig = Rig(course: slow);
        rig.played('s1');
        rig.word('uno');
        await pumpTab(tester, rig);
        expect(cardOrder(tester), ['uno']);
        slow.hold = true;
        rig.word('dos');
        await tester.pumpAndSettle();
        expect(cardOrder(tester), [
          'uno',
        ], reason: 'the second reading waits for the story file');
        await tester.pumpWidget(const SizedBox());
        slow.release();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a touch on a card ticks and opens its sheet', (tester) async {
      final rig = Rig();
      await rig.playSampleStories();
      await pumpTab(tester, rig);
      await tapCard(tester, 'casa');
      expect(rig.haptics.ticks, 1);
      expect(sheet, findsOneWidget);
    });
  });

  group('app.html: extra', () {
    Future<Rig> open(WidgetTester tester) async {
      final rig = Rig();
      await rig.playSampleStories();
      await pumpTab(tester, rig);
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('an empty field, or only spaces, saves nothing', (
      tester,
    ) async {
      final rig = await open(tester);
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      expect(rig.progress.added, isEmpty);
      expect(rig.progress.saves, greaterThan(0)); // (the story seeding saved)
      expect(find.text('Saved. Material for it comes later.'), findsNothing);
    });

    testWidgets(
      'what he typed is saved trimmed, the field is emptied, and the saved list grows in order',
      (tester) async {
        final rig = await open(tester);
        await tester.enterText(
          find.byType(TextField),
          '  talk to my 1-year-old  ',
        );
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        expect(rig.progress.added, ['talk to my 1-year-old']);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '',
        );
        await tester.enterText(find.byType(TextField), 'abuela');
        await tester.tap(find.text('Add'));
        await tester.pumpAndSettle();
        expect(rig.progress.added, ['talk to my 1-year-old', 'abuela']);
        expect(
          find.text('Saved. Material for it comes later.'),
          findsOneWidget,
        );
        expect(
          tester.getTopLeft(find.text('· talk to my 1-year-old')).dy <
              tester.getTopLeft(find.text('· abuela')).dy,
          isTrue,
        );
        // "Saved." is above the list, under the button
        expect(
          tester.getTopLeft(find.text('Add')).dy <
              tester
                  .getTopLeft(find.text('Saved. Material for it comes later.'))
                  .dy,
          isTrue,
        );
      },
    );

    testWidgets(
      'the field is 48 px high and the Add button 16 px under it, whatever the platform (a web build on a desktop platform would be compact; coquiTheme sets the standard density)',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        // the premise: left to itself, Flutter picks the compact density here (a field 40 px high)
        expect(ThemeData().visualDensity, VisualDensity.compact);
        final rig = Rig();
        tester.view.physicalSize = const Size(390 * 3, 844 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: coquiTheme(),
            home: Scaffold(
              body: Builder(
                builder: (c) =>
                    const WordsModule().tab(rig.services)!.builder(c),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final field = tester.getRect(find.byType(TextField));
        expect(field.height, 48);
        final add = tester.getRect(
          find.byWidgetPredicate((w) => w is CoquiButton && w.label == 'Add'),
        );
        expect(add.top - field.bottom, 16);
      },
    );

    testWidgets(
      'the field stays white under the pointer and with the focus (Material would grey it)',
      (tester) async {
        await open(tester);
        final d = tester.widget<TextField>(find.byType(TextField)).decoration!;
        expect((d.filled, d.fillColor), (true, CoquiColors.white));
        expect(d.hoverColor, const Color(0x00000000));
        expect(d.focusColor, const Color(0x00000000));
      },
    );

    testWidgets('what was saved before shows when the tab opens', (
      tester,
    ) async {
      final rig = Rig();
      rig.progress.add('uno');
      rig.progress.add('dos');
      await pumpTab(tester, rig);
      expect(find.text('· uno'), findsOneWidget);
      expect(find.text('· dos'), findsOneWidget);
      expect(find.text('Saved. Material for it comes later.'), findsOneWidget);
    });
  });

  group('app.html: oidoEn (Heard in)', () {
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

    List<String> rows(WidgetTester tester) => [
      for (final r in tester.widgetList<RichText>(
        inSheet(find.byType(RichText)),
      ))
        r.text.toPlainText(),
    ].where((t) => t != 'casa' && normalize(t).contains(' casa ')).toList();

    testWidgets(
      'only the stories he has played; from each one a line before the next of each; at most five',
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
        await tapCard(tester, 'casa');
        expect(rows(tester), [
          'Una casa.',
          'La casa de b.',
          'Otra casa.',
          'Casa dos.',
          'Tercera casa.',
        ]);
        expect(inSheet(find.byType(PlayButton)), findsNWidgets(5));
      },
    );

    testWidgets(
      'the stories are given in the course\'s order, not the order he played them in',
      (tester) async {
        final rig = made({
          's1': story('S1', lines: {'a1': 'Casa de s1.'}),
          's2': story('S2', lines: {'b1': 'Casa de s2.'}),
          's3': story('S3', lines: {'c1': 'Casa de s3.'}),
        });
        for (final id in ['s3', 's2', 's1']) {
          rig.played(id);
        }
        await pumpTab(tester, rig);
        await tapCard(tester, 'casa');
        expect(rows(tester), ['Casa de s1.', 'Casa de s2.', 'Casa de s3.']);
      },
    );

    testWidgets(
      'the same line twice is heard once; a word is found inside a line whatever its accents and case',
      (tester) async {
        final rig = made(
          {
            's1': story('S1', lines: {'a1': '¡CASA!', 'a2': 'Mi casa.'}),
            's2': story('S2', lines: {'b1': '¡Casa!', 'b2': 'Tu Casa.'}),
          },
          played: ['s1', 's2'],
        );
        await pumpTab(tester, rig);
        await tapCard(tester, 'casa');
        expect(rows(tester), ['¡CASA!', 'Mi casa.', 'Tu Casa.']);
      },
    );

    testWidgets('a story\'s "leer" list comes first, then its other lines', (
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
      await tapCard(tester, 'casa');
      expect(rows(tester), ['Casa dos.', 'Casa uno.']);
    });

    testWidgets(
      'a word heard in no line: the sheet has no "Heard in", only the word and its meters',
      (tester) async {
        final rig = made(
          {
            's1': story('S1', lines: {'a1': 'Una puerta.'}),
          },
          played: ['s1'],
        );
        await pumpTab(tester, rig);
        await tapCard(tester, 'casa');
        expect(inSheet(find.text('Heard in')), findsNothing);
        expect(inSheet(find.byType(PlayButton)), findsNothing);
        expect(inSheet(find.byType(SkillMeter)), findsNWidgets(2));
      },
    );
  });

  group('app.html: palabra (the word sheet)', () {
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

    testWidgets('opening it stops what is playing (paraLeer)', (tester) async {
      final rig = await rigged(tester);
      final before = rig.clips.stops;
      await tapCard(tester, 'casa');
      expect(rig.clips.stops, greaterThan(before));
    });

    testWidgets(
      'a pair word shows the "si" picture of its pair, a plain word none',
      (tester) async {
        final rig = await rigged(tester);
        final pair = rig.course.pairs.single;
        rig.pictures.shown.clear();
        await tapCard(tester, 'casa');
        expect(rig.pictures.shown.map((r) => r.toString()).toSet(), {
          PictureRef.of(pair, pair.yes).toString(),
        });
        await tester.tap(find.byType(CoquiCloseButton));
        await tester.pumpAndSettle();
        await tapCard(tester, 'con');
        expect(inSheet(find.byType(PictureFrame)), findsNothing);
      },
    );

    testWidgets(
      'the X, a touch on the scrim and the drag of the header close it; the page is as it was',
      (tester) async {
        final rig = await rigged(tester);
        await tapCard(tester, 'casa');
        expect(sheet, findsOneWidget);
        await tester.tap(find.byType(CoquiCloseButton));
        await tester.pump(const Duration(milliseconds: 100));
        expect(sheet, findsOneWidget, reason: 'it slides out for 200 ms');
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        await tapCard(tester, 'casa');
        await tester.tapAt(const Offset(195, 60)); // the scrim, above the sheet
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        await tapCard(tester, 'casa');
        await tester.drag(find.byType(CoquiCloseButton), const Offset(0, 200));
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
        expect(find.byType(WordTile), findsNWidgets(2));
        expect(rig.nav.routes, isEmpty);
      },
    );

    testWidgets('two touches on a card open one sheet', (tester) async {
      await rigged(tester);
      await tester.tap(card('casa'));
      await tester.tap(card('casa'));
      await tester.pumpAndSettle();
      expect(sheet, findsOneWidget);
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets(
      'the sheet shows the record as it was when the card was touched',
      (tester) async {
        final rig = await rigged(tester);
        await tapCard(tester, 'casa');
        expect(dots(tester, sheet), [3, 1]);
        rig.word('casa', ear: 4, mouth: 4, mouthN: 4, due: 9);
        await tester.pumpAndSettle();
        expect(dots(tester, sheet), [3, 1]);
        // the list under it has moved on
        await tester.tap(find.byType(CoquiCloseButton));
        await tester.pumpAndSettle();
        expect(dots(tester, card('casa')), [4, 4]);
      },
    );

    testWidgets(
      'the sheet\'s word is the big word, in the header only once scrolled',
      (tester) async {
        await rigged(tester);
        await tapCard(tester, 'con');
        final big = find.descendant(
          of: sheet,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Text &&
                w.data == 'con' &&
                w.style!.fontSize == 24 &&
                w.style!.fontWeight == FontWeight.w600 &&
                w.maxLines == null,
          ),
        );
        expect(big, findsOneWidget);
      },
    );
  });

  group('app.html: vuelve, as the sheet says it', () {
    Future<String?> back(
      WidgetTester tester, {
      double? due,
      double? dueMs,
    }) async {
      final rig = Rig(
        course: madeCourse(
          places: [
            place('a', 1, 'Place one', ['s1']),
          ],
          stories: {
            's1': story('S1', focus: ['casa']),
          },
        ),
      );
      rig.played('s1');
      rig.word('casa', ear: 3, due: due, dueMs: dueMs);
      await pumpTab(tester, rig);
      await tapCard(tester, 'casa');
      final t = tester
          .widgetList<Text>(inSheet(find.byType(Text)))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s.startsWith('Comes back'));
      return t.isEmpty ? null : t.single;
    }

    testWidgets('no return date: no line at all', (tester) async {
      expect(await back(tester), isNull);
    });

    testWidgets('past or now: today', (tester) async {
      expect(await back(tester, due: -3), 'Comes back today');
    });

    testWidgets('a day: "1 day"; days: "N days"', (tester) async {
      expect(await back(tester, due: 1), 'Comes back in 1 day');
    });

    testWidgets('days, with a fraction of a millisecond in the date', (
      tester,
    ) async {
      expect(await back(tester, due: 4.4), 'Comes back in 4 days');
    });
  });

  group('app.html: oyeLinea (a "Heard in" line plays)', () {
    Future<({Rig rig, GateClips clips})> two(WidgetTester tester) async {
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
      await tapCard(tester, 'casa');
      return (rig: rig, clips: clips);
    }

    PlayButton button(WidgetTester tester, int i) =>
        tester.widget<PlayButton>(inSheet(find.byType(PlayButton)).at(i));

    testWidgets(
      'a touch loads the line\'s recording, plays it, and the button shows a stop square meanwhile',
      (tester) async {
        final x = await two(tester);
        expect(button(tester, 0).icon, CoquiIcons.play);
        await tester.tap(inSheet(find.byType(PlayButton)).at(0));
        await tester.pump();
        expect(x.clips.preloaded, ['a1']);
        expect(x.clips.played, ['a1']);
        expect(button(tester, 0).icon, CoquiIcons.stop);
        expect(button(tester, 1).icon, CoquiIcons.play);
        expect(
          x.rig.haptics.ticks,
          greaterThanOrEqualTo(2),
        ); // the card, then the line
      },
    );

    testWidgets('when the recording ends the button is a play triangle again', (
      tester,
    ) async {
      final x = await two(tester);
      await tester.tap(inSheet(find.byType(PlayButton)).at(0));
      await tester.pump();
      x.clips.finish();
      await tester.pump();
      await tester.pump();
      expect(button(tester, 0).icon, CoquiIcons.play);
    });

    testWidgets(
      'a touch on another line stops the first and plays the second; the first one\'s end does not undo the second',
      (tester) async {
        final x = await two(tester);
        await tester.tap(inSheet(find.byType(PlayButton)).at(0));
        await tester.pump();
        await tester.tap(inSheet(find.byType(PlayButton)).at(1));
        await tester.pump();
        await tester.pump();
        expect(x.clips.played, ['a1', 'a2']);
        expect(button(tester, 0).icon, CoquiIcons.play);
        expect(button(tester, 1).icon, CoquiIcons.stop);
      },
    );

    testWidgets(
      'a second touch on the same line stops it and plays nothing; a third plays it again',
      (tester) async {
        final x = await two(tester);
        final play = inSheet(find.byType(PlayButton)).at(0);
        await tester.tap(play);
        await tester.pump();
        await tester.tap(play);
        await tester.pump();
        expect(button(tester, 0).icon, CoquiIcons.play);
        expect(x.clips.played, ['a1']);
        await tester.tap(play);
        await tester.pump();
        expect(x.clips.played, ['a1', 'a1']);
        expect(button(tester, 0).icon, CoquiIcons.stop);
      },
    );

    testWidgets('closing the sheet while a line plays stops it', (
      tester,
    ) async {
      final x = await two(tester);
      await tester.tap(inSheet(find.byType(PlayButton)).at(0));
      await tester.pump();
      final stops = x.clips.stops;
      await tester.tap(find.byType(CoquiCloseButton));
      await tester.pumpAndSettle();
      expect(x.clips.stops, greaterThan(stops));
      expect(x.clips.open.where((c) => !c.isCompleted), isEmpty);
    });

    testWidgets(
      'the sound stops as the sheet starts to slide out, not 200 ms later; the stop square stays while it slides (cierra)',
      (tester) async {
        final x = await two(tester);
        await tester.tap(inSheet(find.byType(PlayButton)).at(0));
        await tester.pump();
        final stops = x.clips.stops;
        await tester.tap(find.byType(CoquiCloseButton));
        await tester.pump(const Duration(milliseconds: 20));
        expect(sheet, findsOneWidget, reason: 'it is still sliding out');
        expect(x.clips.stops, greaterThan(stops));
        expect(x.clips.open.where((c) => !c.isCompleted), isEmpty);
        expect(button(tester, 0).icon, CoquiIcons.stop);
        await tester.pumpAndSettle();
        expect(sheet, findsNothing);
      },
    );
  });
}

/// A catalog whose story files wait while [hold] is set, until [release].
class _SlowStories extends FakeCourseCatalog {
  _SlowStories({
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
  Future<Map<String, dynamic>> story(String id) async {
    if (hold && loaded) {
      final c = Completer<void>();
      _waiting.add(c);
      await c.future;
    }
    return super.story(id);
  }
}
