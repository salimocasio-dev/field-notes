@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/words_tab.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

/// Builds a deterministic 96-word rig matching the distribution on
/// `Noche-Palabras.dc.html` (14 today, 9 tomorrow, 21 in 3 days, 30 this week,
/// 22 later) plus speaking words across buckets.
Rig _build96WordRig() {
  final words = <String>[
    'la cuchara',
    'la leche',
    'la mesa',
    'el vaso',
    'el agua',
    'el jugo',
    'la silla',
    'la puerta',
    'la ventana',
    'la casa',
    'el plato',
    'el pan',
    'el queso',
    'el huevo',
    for (var i = 15; i <= 96; i++) 'palabra $i',
  ];
  final rig = Rig(
    course: madeCourse(
      places: [
        place('casa', 1, 'La casa', ['s1']),
      ],
      stories: {
        's1': {'title': 'La cocina', 'focus_words': words, 'clips': {}},
      },
      pairs: words.take(20).toList(),
    ),
  );
  rig.played('s1');

  // Listening distribution: 14 today, 9 tomorrow, 21 in 3 days, 30 this week, 22 later = 96.
  for (var i = 0; i < words.length; i++) {
    final double earDue;
    final int earStage;
    if (i < 14) {
      earDue = i == 0 ? 0 : -(i % 3).toDouble();
      earStage = i < 4 ? 1 : (i < 10 ? 2 : 3);
    } else if (i < 23) {
      earDue = 1;
      earStage = 2 + (i % 2);
    } else if (i < 44) {
      earDue = i.isEven ? 2 : 3;
      earStage = 2 + (i % 2);
    } else if (i < 74) {
      earDue = 4 + (i % 4).toDouble();
      earStage = i < 55 ? 3 : 4;
    } else {
      earDue = 14 + (i % 15).toDouble();
      earStage = 4;
    }

    // Give 32 words speaking records, 17 of which are at top stage (4).
    final hasMouth = i < 32;
    final mouthStage = !hasMouth ? 0 : (i < 17 ? 4 : 1 + (i % 3));
    final mouthDue = !hasMouth
        ? null
        : (i < 5
              ? 0.0
              : i < 10
              ? 1.0
              : i < 16
              ? 3.0
              : i < 24
              ? 5.0
              : 21.0);

    rig.word(
      words[i],
      ear: earStage,
      due: earDue,
      mouth: mouthStage,
      mouthN: hasMouth ? 2 : 0,
      mouthDue: mouthDue,
    );
  }
  return rig;
}

Rig _buildFewWordsRig() {
  final rig = Rig(
    course: madeCourse(
      places: [
        place('casa', 1, 'La casa', ['s1']),
      ],
      stories: {
        's1': {
          'title': 'La cocina',
          'focus_words': ['la cuchara', 'la leche', 'la mesa'],
          'clips': {
            'c1': {'who': 'abuela', 'text': 'Aquí está la cuchara.'},
          },
        },
      },
      pairs: ['la cuchara', 'la mesa'],
    ),
  );
  rig.played('s1');
  rig.word('la cuchara', ear: 2, due: 0, mouth: 1, mouthN: 1, mouthDue: 0);
  rig.word('la leche', ear: 3, due: 2, mouth: 2, mouthN: 2, mouthDue: 3);
  rig.word('la mesa', ear: 4, due: 21, mouth: 4, mouthN: 4, mouthDue: 14);
  return rig;
}

void main() {
  group('N4.4 bucket math and due-line formatting', () {
    const now = 1795104000000;
    const dayMs = 86400000;

    test('bucket test: words due yesterday, today, tomorrow, in 3, 5, and 20 days land in the right columns', () {
      expect(dueBucketFor(now - dayMs, now), DueBucket.today);
      expect(dueBucketFor(now, now), DueBucket.today);
      expect(dueBucketFor(now + dayMs, now), DueBucket.tomorrow);
      expect(dueBucketFor(now + 3 * dayMs, now), DueBucket.threeDays);
      expect(dueBucketFor(now + 5 * dayMs, now), DueBucket.thisWeek);
      expect(dueBucketFor(now + 20 * dayMs, now), DueBucket.later);
    });

    test('bucket boundary edges: 2d, 4d, 7d, 8d, unscheduled, and parked', () {
      expect(dueBucketFor(0, now), isNull);
      expect(dueBucketFor(double.nan, now), isNull);
      expect(dueBucketFor(now + 2 * dayMs, now), DueBucket.threeDays);
      expect(dueBucketFor(now + 4 * dayMs, now), DueBucket.thisWeek);
      expect(dueBucketFor(now + 7 * dayMs, now), DueBucket.thisWeek);
      expect(dueBucketFor(now + 8 * dayMs, now), DueBucket.later);

      // Parked word with overdue `due` uses `aparcada` (+7 days -> thisWeek).
      final parked = SkillRecord(
        etapa: 2,
        due: now - dayMs,
        aparcada: now + 7 * dayMs,
      );
      expect(effectiveDueMs(parked, now), now + 7 * dayMs);
      expect(
        dueBucketFor(effectiveDueMs(parked, now), now),
        DueBucket.thisWeek,
      );
    });

    test('formatWordDueLine covers all spec formats and top stage prefix', () {
      expect(formatWordDueLine(days: 0, isGood: false), 'back today');
      expect(formatWordDueLine(days: 0, isGood: true), 'good · back today');
      expect(formatWordDueLine(days: 1, isGood: false), 'back tomorrow');
      expect(formatWordDueLine(days: 2, isGood: false), 'back in 2 days');
      expect(formatWordDueLine(days: 13, isGood: false), 'back in 13 days');
      expect(formatWordDueLine(days: 14, isGood: false), 'back in 2 weeks');
      expect(
        formatWordDueLine(days: 21, isGood: true),
        'good · back in 3 weeks',
      );
      expect(
        formatWordDueLine(days: 20, isGood: true),
        'good · back in 3 weeks',
      );
      expect(formatWordDueLine(days: null, isGood: true), 'good');
      expect(formatWordDueLine(days: null, isGood: false), '');
    });

    testWidgets(
      'rendered NocheBarChart puts yesterday, today, tomorrow, 3d, 5d, and 20d in exact columns',
      (tester) async {
        final rig = Rig();
        rig.word('ayer', ear: 1, due: -1); // Today
        rig.word('hoy', ear: 2, due: 0); // Today
        rig.word('manana', ear: 2, due: 1); // Tomorrow
        rig.word('tres', ear: 3, due: 3); // 3 days
        rig.word('cinco', ear: 3, due: 5); // This week
        rig.word('veinte', ear: 4, due: 20); // Later
        await pumpTab(tester, rig);

        expect(dueCardCount(tester), '2');
        expect(find.text('WHEN YOUR 6 WORDS COME BACK'), findsOneWidget);

        final chart = tester.widget<NocheBarChart>(find.byType(NocheBarChart));
        expect(
          [for (final i in chart.items) (i.label, i.value, i.highlighted)],
          [
            ('Today', 2, true),
            ('Tomorrow', 1, false),
            ('3 days', 1, false),
            ('This week', 1, false),
            ('Later', 1, false),
          ],
        );
        expect(
          chart.semanticLabel,
          'Words coming back: 2 today, 1 tomorrow, 1 in 3 days, 1 this week, 1 later',
        );
        // Soonest-first ordering on the screen: ayer (-1) before hoy (0) before manana (1)...
        expect(rowOrder(tester).take(3).toList(), ['ayer', 'hoy', 'manana']);
      },
    );
  });

  group('N4.4 UI structure, skill switching, stageMax, and touch targets', () {
    testWidgets(
      'renders header, due card, chart, segmented skills, soonest-first rows, and Start review with no minutes estimate',
      (tester) async {
        final rig = _buildFewWordsRig();
        await pumpTab(tester, rig);

        expect(find.text('SPANISH'), findsOneWidget);
        expect(find.text('Words'), findsOneWidget);
        expect(find.text('+ Add a word or goal'), findsOneWidget);

        expect(dueCardCount(tester), '1');
        expect(find.text('word comes\nback today'), findsOneWidget);
        expect(find.text('WHEN YOUR 3 WORDS COME BACK'), findsOneWidget);

        expect(find.text('Listening · 1'), findsOneWidget);
        expect(find.text('Speaking · 1'), findsOneWidget);
        expect(find.text('Reading · A2'), findsOneWidget);

        // Soonest-first rows with exact due lines and colours.
        expect(rowOrder(tester), ['la cuchara', 'la leche', 'la mesa']);
        final todayLine = tester.widget<Text>(find.text('back today'));
        expect(todayLine.style?.color, NocheColors.next);
        final twoDaysLine = tester.widget<Text>(find.text('back in 2 days'));
        expect(twoDaysLine.style?.color, NocheColors.label);
        final goodLine = tester.widget<Text>(
          find.text('good · back in 3 weeks'),
        );
        expect(goodLine.style?.color, NocheColors.label);

        // Content language locale on words.
        expect(
          tester.widget<Text>(find.text('la cuchara')).locale,
          const Locale('es'),
        );

        // Stage bars respect defaultStageMax (4).
        expect(
          [
            for (final b in tester.widgetList<NocheStageBar>(
              find.byType(NocheStageBar),
            ))
              (b.stage, b.max),
          ],
          [(2, 4), (3, 4), (4, 4)],
        );

        // Orange Start review button has no minutes estimate.
        expect(find.text('Start review'), findsOneWidget);
        expect(find.textContaining('min'), findsNothing);

        // Every word row is at least 56 high.
        for (final w in ['la cuchara', 'la leche', 'la mesa']) {
          expect(tester.getSize(wordRow(w)).height, greaterThanOrEqualTo(56));
        }

        // Every interactive target is at least 48x48.
        expect(
          tester.getSize(find.byKey(const Key('words-add-pill'))).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          tester.getSize(find.byKey(const Key('words-review-button'))).height,
          greaterThanOrEqualTo(48),
        );
      },
    );

    testWidgets(
      'switching skills updates due card, chart, and word list; Reading shows A2 gate message below A2',
      (tester) async {
        final rig = Rig();
        rig.word('uno', ear: 4, due: 0, mouth: 2, mouthN: 1, mouthDue: 3);
        rig.word('dos', ear: 2, due: 1, mouth: 4, mouthN: 3, mouthDue: 20);
        rig.word('tres', ear: 1, due: 0);
        await pumpTab(tester, rig);

        // Listening: 2 due today, 3 total, 1 good.
        expect(dueCardCount(tester), '2');
        expect(find.text('WHEN YOUR 3 WORDS COME BACK'), findsOneWidget);
        expect(find.text('Listening · 1'), findsOneWidget);
        expect(find.text('Speaking · 1'), findsOneWidget);

        // Switch to Speaking: 0 due today, 2 total, rows ['uno', 'dos'].
        await tester.tap(find.text('Speaking · 1'));
        await tester.pumpAndSettle();
        expect(dueCardCount(tester), '0');
        expect(find.text('WHEN YOUR 2 WORDS COME BACK'), findsOneWidget);
        expect(rowOrder(tester), ['uno', 'dos']);

        // Reading option is muted below A2 and tapping shows A2 gate message.
        final seg = tester.widget<NocheSegmented<WordsSkill>>(
          find.byType(NocheSegmented<WordsSkill>),
        );
        expect(seg.role, NocheSegmentedRole.tabList);
        expect(seg.options[2].label, 'Reading · A2');
        expect(seg.options[2].muted, isTrue);

        await tester.tap(find.text('Reading · A2'));
        await tester.pumpAndSettle();
        expect(dueCardCount(tester), '0');
        expect(find.text('Reading opens for tracking at A2.'), findsOneWidget);
        expect(rowOrder(tester), isEmpty);

        // Once learner reaches A2, Reading is unmuted and does not show the gate line.
        rig.setCefr('A2');
        await tester.pumpAndSettle();
        expect(find.text('Reading · 0'), findsOneWidget);
        expect(find.text('Reading opens for tracking at A2.'), findsNothing);
      },
    );

    testWidgets(
      'respects custom stageMax (Part 1.7 switch, no hardcoded 4/5)',
      (tester) async {
        final rig = Rig();
        rig.word('cuatro', ear: 4, due: 5);
        rig.word('cinco', ear: 5, due: 21);
        await pumpTab(tester, rig, stageMax: 5);

        // With stageMax = 5, stage 4 is NOT good yet; only stage 5 is good.
        expect(find.text('Listening · 1'), findsOneWidget);
        expect(find.text('back in 5 days'), findsOneWidget);
        expect(find.text('good · back in 3 weeks'), findsOneWidget);
        expect(
          [
            for (final b in tester.widgetList<NocheStageBar>(
              find.byType(NocheStageBar),
            ))
              (b.stage, b.max),
          ],
          [(4, 5), (5, 5)],
        );
      },
    );

    testWidgets(
      'zero overflow across 0, a few, and 96 words, all 3 skills, and both phone sizes',
      (tester) async {
        final configs = [
          (name: 'empty', make: () => Rig()),
          (name: 'few', make: _buildFewWordsRig),
          (name: '96', make: _build96WordRig),
        ];
        for (final screen in const [
          (size: Size(390, 844), dpr: 3.0),
          (size: Size(412, 915), dpr: 2.625),
        ]) {
          for (final cfg in configs) {
            for (final skill in WordsSkill.values) {
              await pumpTab(
                tester,
                cfg.make(),
                size: screen.size,
                ratio: screen.dpr,
                initialSkill: skill,
              );
              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${cfg.name} / $skill at ${screen.size.width}x${screen.size.height}',
              );
              await tester.pumpWidget(const SizedBox.shrink());
            }
          }
        }
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets('capture N4.4 Words screenshots (0, few, 96, Arabic)', (
      tester,
    ) async {
      for (final entry in nocheFontFiles.entries) {
        for (final prefix in ['', 'packages/coqui_ui/']) {
          final loader = FontLoader('$prefix${entry.key}');
          for (final path in entry.value.values) {
            loader.addFont(
              Future.value(
                ByteData.sublistView(
                  File('../../core/coqui_ui/$path').readAsBytesSync(),
                ),
              ),
            );
          }
          await loader.load();
        }
      }

      final dir = Directory('test/screenshots')..createSync(recursive: true);

      Future<void> capture({
        required String filename,
        required Rig rig,
        required WordsSkill skill,
        required Size size,
        required double dpr,
      }) async {
        tester.view.devicePixelRatio = dpr;
        tester.view.physicalSize = size * dpr;
        addTearDown(tester.view.reset);

        final lang = rig.services.course.language;
        final boundaryKey = GlobalKey();

        await tester.pumpWidget(
          RepaintBoundary(
            key: boundaryKey,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: Scaffold(
                backgroundColor: NocheColors.ground,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    WordsTab(services: rig.services, initialSkill: skill),
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: 0,
                      child: NocheTabBar(
                        selectedId: NocheTabs.words,
                        tabNames: lang.tabNames,
                        script: lang.script,
                        languageCode: lang.code,
                        onTap: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final bytes = await tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: dpr);
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          image.dispose();
          return byteData!.buffer.asUint8List();
        });
        File('${dir.path}/$filename').writeAsBytesSync(bytes!);
        await tester.pumpWidget(const SizedBox.shrink());
      }

      final sizes = const [
        (tag: '390x844', size: Size(390, 844), dpr: 3.0),
        (tag: '412x915', size: Size(412, 915), dpr: 2.625),
      ];

      for (final screen in sizes) {
        for (final dataset in [
          (tag: 'empty', make: () => Rig()),
          (tag: 'few', make: _buildFewWordsRig),
          (tag: '96', make: _build96WordRig),
        ]) {
          for (final skill in WordsSkill.values) {
            await capture(
              filename: 'words_${dataset.tag}_${skill.name}_${screen.tag}.png',
              rig: dataset.make(),
              skill: skill,
              size: screen.size,
              dpr: screen.dpr,
            );
          }
        }

        // Arabic RTL screenshot.
        final arRig = Rig(course: FakeCourseCatalog.arabic());
        arRig.played('la-lluvia');
        arRig.word('باب', ear: 2, mouth: 1, mouthN: 1, due: 0, mouthDue: 0);
        arRig.word('مرحباً', ear: 2, mouth: 1, mouthN: 1, due: 2, mouthDue: 1);
        arRig.word('شمس', ear: 3, due: 5);
        arRig.word('بيت', ear: 4, mouth: 2, mouthN: 2, due: 21, mouthDue: 3);
        await capture(
          filename: 'words_arabic_listening_${screen.tag}.png',
          rig: arRig,
          skill: WordsSkill.listening,
          size: screen.size,
          dpr: screen.dpr,
        );
      }
    });
  }
}
