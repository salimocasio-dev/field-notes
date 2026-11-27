// N8.9 review motion tests and Request #261 key/addMinutes checks:
// Rule 1 press, choice miss/right & replay, dash fill delay, item transitions,
// end-screen arrival choreography + full-width NocheStageBar (RepasoScreen &
// ReviewScreen), reduced motion, Arabic RTL, and stable widget keys.
import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/motion.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../tool/support/scripted_clips.dart';
import '../tool/support/virtual_time.dart';
import 'support/lab.dart';
import 'support/recording_store.dart';
import 'support/repaso_course.dart';
import 'support/repaso_screen_rig.dart';

/// Builds a normal-motion (or reduced-motion) [RepasoScreen] test rig.
class _MotionRig {
  _MotionRig(
    this.t, {
    String? json,
    int seed = 3,
    this.disableAnimations = false,
  }) : vt = VirtualTime(settler: t.idle) {
    store = RecordingStore(
      vt,
      clock: FakeClock(curseNow),
      json: json ?? seedJson('curso'),
    );
    clips = ScriptedClips(vt);
    services = fakeServices(
      progress: store,
      course: RepasoTestCourse(),
      clips: clips,
      clock: vt,
      rng: FakeRng(seed),
      nav: nav,
      speech: FakeSpeechListener(isAvailable: false, instant: true),
      reduceMotion: disableAnimations,
    );
  }

  final WidgetTester t;
  final bool disableAnimations;
  final VirtualTime vt;
  late final RecordingStore store;
  late final ScriptedClips clips;
  late final Services services;
  final FakeNavigator nav = FakeNavigator();
  final GlobalKey<RepasoScreenState> key = GlobalKey();

  RepasoSession get s => key.currentState!.session;

  Future<void> open({double w = 390, double h = 844, double dpr = 2}) async {
    t.view.devicePixelRatio = dpr;
    t.view.physicalSize = Size(w * dpr, h * dpr);
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: disableAnimations);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: coquiTheme(),
        home: RepasoScreen(
          key: key,
          services: services,
          data: realRepaso,
          wait: vt.wait,
          imageProvider: (_) => dotPicture,
        ),
      ),
    );
    await vt.settle();
    await t.pump(const Duration(milliseconds: 200));
  }
}

double _scaleOf(WidgetTester t, Finder transformFinder) {
  final transform = t.widget<Transform>(transformFinder);
  return transform.transform.storage[0];
}

double _scaleYOf(WidgetTester t, Finder transformFinder) {
  final transform = t.widget<Transform>(transformFinder);
  return transform.transform.storage[5];
}

double _translateYOf(WidgetTester t, Finder riseFinder) {
  final transform = t.widget<Transform>(
    find.descendant(of: riseFinder, matching: find.byType(Transform)).first,
  );
  return transform.transform.storage[13];
}

double _opacityOf(WidgetTester t, Finder riseFinder) {
  final op = t.widget<Opacity>(
    find.descendant(of: riseFinder, matching: find.byType(Opacity)).first,
  );
  return op.opacity;
}

double _rotationAngleOf(WidgetTester t, Finder transformFinder) {
  final m = t.widget<Transform>(transformFinder).transform.storage;
  return math.atan2(m[1], m[0]);
}

Color _tileBorderColor(WidgetTester t, Finder tileFinder) {
  final container = t.widget<Container>(
    find.descendant(
      of: tileFinder,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.foregroundDecoration is BoxDecoration &&
            (w.foregroundDecoration! as BoxDecoration).border != null,
      ),
    ),
  );
  return (container.foregroundDecoration! as BoxDecoration).border!.top.color;
}

double _tileBorderWidth(WidgetTester t, Finder tileFinder) {
  final container = t.widget<Container>(
    find.descendant(
      of: tileFinder,
      matching: find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.foregroundDecoration is BoxDecoration &&
            (w.foregroundDecoration! as BoxDecoration).border != null,
      ),
    ),
  );
  return (container.foregroundDecoration! as BoxDecoration).border!.top.width;
}

RepasoData _arabicMotionData() => RepasoData(
  sentences: [
    RepasoSentence(
      clip: 'esta_casa',
      story: 'la-lluvia',
      text: 'هذا بيت جدة.',
      tokens: ['هذا', 'بيت', 'جدة'],
      forbidden: ['بيت', 'جدة'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'puerta',
      story: 'la-lluvia',
      text: 'هذا باب.',
      tokens: ['هذا', 'باب'],
      forbidden: ['باب'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
    RepasoSentence(
      clip: 'ventana',
      story: 'la-lluvia',
      text: 'هذه نافذة.',
      tokens: ['هذه', 'نافذة'],
      forbidden: ['نافذة'],
      picture: null,
      forHearing: true,
      forBuilding: true,
    ),
  ],
  words: [
    RepasoWord(
      word: 'بيت',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'esta_casa',
      sentences: [0],
    ),
    RepasoWord(
      word: 'باب',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'puerta',
      sentences: [1],
    ),
    RepasoWord(
      word: 'نافذة',
      place: 'casa',
      scoring: RepasoScoring.queOyes,
      solo: 'ventana',
      sentences: [2],
    ),
  ],
);

void main() {
  group('Rule 1 press feedback', () {
    testWidgets(
      'NocheWordTile and OptionTouch scale down in press (0.97) and return in pressBack (1.0)',
      (t) async {
        var optionTouched = -1;
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: NocheColors.lessonGround,
              body: Column(
                children: [
                  NocheWordTile(
                    key: const ValueKey('test-word-tile'),
                    word: 'casa',
                    onTap: () {},
                  ),
                  SizedBox(
                    width: 120,
                    height: 80,
                    child: OptionTouch(
                      key: const ValueKey('test-option-touch'),
                      index: 0,
                      onTouch: (k) => optionTouched = k,
                      child: const NochePictureChoice(
                        inside: true,
                        child: ColoredBox(color: NocheColors.lessonPanel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // 1) NocheWordTile (Pressable)
        final tileFinder = find.byKey(const ValueKey('test-word-tile'));
        final tileScaleFinder = find
            .descendant(of: tileFinder, matching: find.byType(Transform))
            .first;
        expect(_scaleOf(t, tileScaleFinder), closeTo(1.0, 0.001));

        final g1 = await t.startGesture(t.getCenter(tileFinder));
        await t.pump();
        await t.pump(NocheMotion.press ~/ 2);
        final midTileScale = _scaleOf(t, tileScaleFinder);
        expect(midTileScale, lessThan(1.0));
        expect(midTileScale, greaterThan(NocheMotion.pressScale));

        await t.pump(NocheMotion.press);
        expect(
          _scaleOf(t, tileScaleFinder),
          closeTo(NocheMotion.pressScale, 0.002),
        );

        await g1.up();
        await t.pump();
        await t.pump(NocheMotion.pressBack);
        expect(_scaleOf(t, tileScaleFinder), closeTo(1.0, 0.001));

        // 2) OptionTouch + NochePictureChoice: fires immediately on pointerDown
        final optFinder = find.byKey(const ValueKey('test-option-touch'));
        final optScaleFinder = find
            .descendant(of: optFinder, matching: find.byType(Transform))
            .first;
        expect(_scaleOf(t, optScaleFinder), closeTo(1.0, 0.001));
        expect(optionTouched, -1);

        final g2 = await t.startGesture(t.getCenter(optFinder));
        await t.pump();
        // Immediate pointerDown parity
        expect(optionTouched, 0);

        await t.pump(NocheMotion.press ~/ 2);
        final midOptScale = _scaleOf(t, optScaleFinder);
        expect(midOptScale, lessThan(1.0));
        expect(midOptScale, greaterThan(NocheMotion.pressScale));

        await t.pump(NocheMotion.press);
        expect(
          _scaleOf(t, optScaleFinder),
          closeTo(NocheMotion.pressScale, 0.002),
        );

        await g2.up();
        await t.pump();
        await t.pump(NocheMotion.pressBack);
        expect(_scaleOf(t, optScaleFinder), closeTo(1.0, 0.001));
      },
    );
  });

  group('Choice miss, replay arrow, and small level bars', () {
    testWidgets(
      'miss animates white outline & wrong badge in quick (zero red), replays line, spins replay arrow in settle, and animates level bars',
      (t) async {
        final rig = _MotionRig(t, json: everythingJson(realRepaso));
        await rig.open();
        final word = realRepaso.words.firstWhere(
          (w) => rig.s.planner.hearSentences(w).isNotEmpty,
        );
        final hear = rig.s.planner.hearItem(
          word,
          rig.s.planner.hearSentences(word).first,
        );
        rig.s.queue = [QueueEntry.scored(hear)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 500));
        await rig.vt.runUntil(() => rig.s.yourTurn);
        await t.pump(const Duration(milliseconds: 500));

        final wrongIdx = hear.answer == 0 ? 1 : 0;
        final wrongTile = find.byType(NocheWordTile).at(wrongIdx);
        final playsBefore = rig.clips.plays.length;
        final replayBefore = rig.s.replayCount;
        final arrowFinder = find.byKey(const ValueKey('review_replay_arrow'));
        expect(_rotationAngleOf(t, arrowFinder), closeTo(0.0, 0.01));

        // Tap wrong tile
        await t.tap(wrongTile);
        await rig.vt.settle();
        await t.pump();

        // Line replays immediately and replayCount increments
        expect(rig.s.replayCount, replayBefore + 1);
        expect(rig.clips.plays.length, playsBefore + 1);
        expect(rig.clips.plays.last['id'], hear.clip);
        expect(rig.s.sentencePlaying, isTrue);

        // Start of quick (t = 0): border still transitioning, badge starting
        final badgeFinder = find.byType(NocheWrongBadge);
        expect(badgeFinder, findsOneWidget);
        final badgeOpacityStart = t
            .widget<Opacity>(
              find
                  .ancestor(of: badgeFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(badgeOpacityStart, closeTo(0.0, 0.05));

        // Mid of quick (70 ms): border width between 1.5 and 3.0, badge mid-way
        await t.pump(NocheMotion.quick ~/ 2);
        final midWidth = _tileBorderWidth(t, wrongTile);
        expect(midWidth, greaterThan(nocheLessonBorder));
        expect(midWidth, lessThan(3.0));
        final midBadgeOp = t
            .widget<Opacity>(
              find
                  .ancestor(of: badgeFinder, matching: find.byType(Opacity))
                  .first,
            )
            .opacity;
        expect(midBadgeOp, greaterThan(0.0));
        expect(midBadgeOp, lessThan(1.0));

        // Mid of settle (240 ms total): arrow is rotating counter-clockwise & level bars animate
        await t.pump(const Duration(milliseconds: 170));
        expect(_tileBorderWidth(t, wrongTile), closeTo(3.0, 0.01));
        expect(_tileBorderColor(t, wrongTile), NocheColors.text);
        expect(_tileBorderColor(t, wrongTile), isNot(CoquiColors.lessonBad));
        final midAngle = _rotationAngleOf(t, arrowFinder);
        expect(midAngle.abs(), greaterThan(0.1));

        final bar0A = _scaleYOf(
          t,
          find.byKey(const ValueKey('review_level_bar_0')),
        );
        await t.pump(const Duration(milliseconds: 120));
        final bar0B = _scaleYOf(
          t,
          find.byKey(const ValueKey('review_level_bar_0')),
        );
        expect(bar0B, isNot(closeTo(bar0A, 0.001)));

        // End of settle (480 ms+): arrow completes 1 full turn (back to 0 mod 2pi)
        await t.pump(const Duration(milliseconds: 200));
        final endAngle = _rotationAngleOf(t, arrowFinder);
        expect(endAngle.abs(), lessThan(0.05));

        // Tile keeps its miss outline even after right tile is touched
        await rig.vt.runUntil(() => rig.s.choices.any((c) => c.sign));
        await t.pump(const Duration(milliseconds: 200));
        await t.tap(find.byType(NocheWordTile).at(hear.answer));
        await rig.vt.runUntil(() => rig.s.canNext);
        await t.pump(const Duration(milliseconds: 500));
        expect(_tileBorderColor(t, wrongTile), NocheColors.text);
        expect(_tileBorderWidth(t, wrongTile), closeTo(3.0, 0.01));
      },
    );
  });

  group('Choice right, expanding ring, fade to 40%, and dash fill delay', () {
    testWidgets(
      'right animates green outline + check in quick, expanding ring in settle, other tiles fade to 0.4 in move, dash waits 300 ms then fills in move',
      (t) async {
        final rig = _MotionRig(t, json: everythingJson(realRepaso));
        await rig.open();
        final word = realRepaso.words.firstWhere(
          (w) => rig.s.planner.hearSentences(w).isNotEmpty,
        );
        final hear = rig.s.planner.hearItem(
          word,
          rig.s.planner.hearSentences(word).first,
        );
        rig.s.queue = [QueueEntry.scored(hear)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 500));
        await rig.vt.runUntil(() => rig.s.yourTurn);
        await t.pump(const Duration(milliseconds: 500));

        final rightTile = find.byType(NocheWordTile).at(hear.answer);
        final otherIdx = hear.answer == 0 ? 1 : 0;
        final otherTile = find.byType(NocheWordTile).at(otherIdx);

        await t.tap(rightTile);
        await rig.vt.runUntil(() => rig.s.canNext);
        await t.pump();

        // Expanding ring starts at scale 1.0, opacity 0.9
        final ringFinder = find.byKey(const ValueKey('choice_right_ring'));
        expect(ringFinder, findsOneWidget);
        expect(_scaleOf(t, ringFinder), closeTo(1.0, 0.01));
        expect(
          t
              .widget<Opacity>(
                find.descendant(of: ringFinder, matching: find.byType(Opacity)),
              )
              .opacity,
          closeTo(0.9, 0.05),
        );

        // Other tile starts fading to 0.4 in move
        final otherAnimOp = t.widget<AnimatedOpacity>(
          find.descendant(
            of: otherTile,
            matching: find.byType(AnimatedOpacity),
          ),
        );
        expect(otherAnimOp.opacity, 0.4);
        expect(otherAnimOp.duration, NocheMotion.move);

        // Dash fill waits during the 300 ms dashFillDelay (checked at 150 ms)
        await t.pump(const Duration(milliseconds: 150));
        final dashFillFinder = find.byKey(const ValueKey('review_dash_fill_0'));
        expect(dashFillFinder, findsOneWidget);
        expect(
          t.widget<FractionallySizedBox>(dashFillFinder).widthFactor,
          closeTo(0.0, 0.001),
        );

        // Mid of settle (240 ms total): green border settled, ring mid-way (1.0..1.08, 0.0..0.9)
        await t.pump(const Duration(milliseconds: 90));
        expect(_tileBorderColor(t, rightTile), NocheColors.right);
        expect(_tileBorderWidth(t, rightTile), closeTo(3.0, 0.01));
        final midRingScale = _scaleOf(t, ringFinder);
        expect(midRingScale, greaterThan(1.0));
        expect(midRingScale, lessThan(1.08));
        final midRingOpacity = t
            .widget<Opacity>(
              find.descendant(of: ringFinder, matching: find.byType(Opacity)),
            )
            .opacity;
        expect(midRingOpacity, greaterThan(0.0));
        expect(midRingOpacity, lessThan(0.9));

        // Mid of dash fill (300 ms + move ~/ 2 = 410 ms total -> +170 ms)
        await t.pump(const Duration(milliseconds: 170));
        final midDashWidth = t
            .widget<FractionallySizedBox>(dashFillFinder)
            .widthFactor!;
        expect(midDashWidth, greaterThan(0.0));
        expect(midDashWidth, lessThan(1.0));

        // After settle (480 ms) & dash fill (300 + 220 = 520 ms): ring unmounted & dash overlay cleared
        await t.pump(const Duration(milliseconds: 150));
        expect(ringFinder, findsNothing);
        expect(dashFillFinder, findsNothing);
      },
    );
  });

  group('Item-to-item transition', () {
    testWidgets(
      'frame holds, old item fades out in quick, new item rows rise by row (8->0) stagger apart',
      (t) async {
        final rig = _MotionRig(t, json: everythingJson(realRepaso));
        await rig.open();
        final words = realRepaso.words
            .where((w) => rig.s.planner.hearSentences(w).isNotEmpty)
            .take(2)
            .toList();
        final h0 = rig.s.planner.hearItem(
          words[0],
          rig.s.planner.hearSentences(words[0]).first,
        );
        final h1 = rig.s.planner.hearItem(
          words[1],
          rig.s.planner.hearSentences(words[1]).first,
        );
        rig.s.queue = [QueueEntry.scored(h0), QueueEntry.scored(h1)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 500));
        await rig.vt.runUntil(() => rig.s.yourTurn);
        await t.pump(const Duration(milliseconds: 500));

        final frameBefore = t.getRect(find.byType(NocheReviewDashes));
        await t.tap(find.byType(NocheWordTile).at(h0.answer));
        await rig.vt.runUntil(() => rig.s.canNext);
        await t.pump(const Duration(milliseconds: 600));

        // Tap Next to move from item 0 to item 1
        await t.tap(find.byKey(const Key('review-next-button')));
        await rig.vt.settle();
        await t.pump();

        // Frame holds
        expect(t.getRect(find.byType(NocheReviewDashes)), frameBefore);
        expect(find.byKey(const Key('review-close-button')), findsOneWidget);

        // Outgoing item starts at opacity ~1.0, mid-way at quick/2, gone after quick
        final outgoing = find.byKey(const ValueKey('review_item_outgoing'));
        expect(outgoing, findsOneWidget);
        expect(t.widget<Opacity>(outgoing).opacity, closeTo(1.0, 0.05));

        await t.pump(NocheMotion.quick ~/ 2);
        final midOutOp = t.widget<Opacity>(outgoing).opacity;
        expect(midOutOp, greaterThan(0.0));
        expect(midOutOp, lessThan(1.0));

        // At 160 ms (past quick = 140 ms): outgoing unmounted, incoming rows at dy = row (8), opacity = 0
        await t.pump(const Duration(milliseconds: 90));
        expect(outgoing, findsNothing);
        final row0 = find.byKey(const ValueKey('review_item_row_0'));
        final row2 = find.byKey(const ValueKey('review_item_row_2'));
        expect(_translateYOf(t, row0), closeTo(NocheMotion.row, 0.1));
        expect(_opacityOf(t, row0), closeTo(0.0, 0.05));
        expect(_translateYOf(t, row2), closeTo(NocheMotion.row, 0.1));

        // Mid-rise (160 + 110 = 270 ms): row 0 is ahead of row 2 due to stagger
        await t.pump(const Duration(milliseconds: 110));
        final dy0 = _translateYOf(t, row0);
        final dy2 = _translateYOf(t, row2);
        expect(dy0, greaterThan(0.0));
        expect(dy0, lessThan(NocheMotion.row));
        expect(dy2, greaterThan(dy0));

        // Settled
        await t.pump(const Duration(milliseconds: 400));
        expect(_translateYOf(t, row0), closeTo(0.0, 0.01));
        expect(_opacityOf(t, row0), closeTo(1.0, 0.01));
        expect(_translateYOf(t, row2), closeTo(0.0, 0.01));
        expect(_opacityOf(t, row2), closeTo(1.0, 0.01));
      },
    );
  });

  group('End screen arrival and full-width NocheStageBar', () {
    testWidgets(
      'RepasoScreen end screen: last item fades out, rows rise with 5-word stagger cap, orange button lands last, and moved-up NocheStageBar grows 300 ms after word arrives while missed stands still',
      (t) async {
        // Make 7 due words so we have 1 missed (Coming back soon) + 6 right (Got it the first time, testing 5-word cap!)
        final baseDb = jsonDecode(seedJson('curso')) as Map<String, dynamic>;
        final palabras = baseDb['palabras'] as Map<String, dynamic>;
        for (final entry in palabras.values) {
          final ear =
              (entry as Map<String, dynamic>)['ear'] as Map<String, dynamic>;
          ear['etapa'] = 1;
          ear['paso'] = 1;
          ear['seguidas'] = 1;
          ear['due'] = curseNow - 86400000;
        }
        final rig = _MotionRig(t, json: jsonEncode(baseDb));
        await rig.open(h: 1200);

        final words = rig.s.words.take(7).toList();
        final items = [
          for (final w in words)
            rig.s.planner.hearItem(w, rig.s.planner.hearSentences(w).first),
        ];
        rig.s.queue = [for (final it in items) QueueEntry.scored(it)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 500));

        // Play all 7 items: item 0 wrong (then shown right), items 1..6 right, plus return of item 0
        QueueEntry? acted;
        for (
          var step = 0;
          step < 40 && rig.s.screen != LessonScreen.end;
          step++
        ) {
          await rig.vt.runUntil(
            () =>
                rig.s.screen == LessonScreen.end ||
                rig.s.canNext ||
                rig.s.choices.any((c) => c.sign) ||
                (rig.s.yourTurn && !identical(acted, rig.s.entry)),
          );
          if (rig.s.screen == LessonScreen.end) break;
          await t.pump(const Duration(milliseconds: 450));
          if (rig.s.canNext) {
            final isLastNext = rig.s.index == rig.s.queue.length - 1;
            await t.tap(find.byKey(const Key('review-next-button')));
            await rig.vt.settle();
            if (isLastNext) {
              // Stop right at t = 0 of the transition to end!
              await t.pump();
              break;
            }
            await t.pump(const Duration(milliseconds: 450));
          } else if (rig.s.choices.any((c) => c.sign)) {
            final k = rig.s.choices.indexWhere((c) => c.sign);
            await t.tap(find.byType(NocheWordTile).at(k));
            await rig.vt.settle();
            await t.pump(const Duration(milliseconds: 200));
          } else if (rig.s.yourTurn && !identical(acted, rig.s.entry)) {
            acted = rig.s.entry;
            final r = rig.s.choices.indexWhere((c) => c.right);
            final pick = rig.s.index == 0 ? (r == 0 ? 1 : 0) : r;
            await t.tap(find.byType(NocheWordTile).at(pick));
            await rig.vt.settle();
            await t.pump(const Duration(milliseconds: 200));
          }
        }

        expect(rig.s.screen, LessonScreen.end);
        final end = rig.s.end!;
        expect(end.stageMax, rig.store.stageMax);
        expect(end.groups, hasLength(2));
        final missedRow = end.groups[0].rows.single;
        final upRows = end.groups[1].rows;
        expect(upRows, hasLength(6));

        // 1) Last item fades out in quick
        final outgoing = find.byKey(const ValueKey('review_item_outgoing'));
        expect(outgoing, findsOneWidget);
        await t.pump(NocheMotion.quick ~/ 2);
        final outMid = t.widget<Opacity>(outgoing).opacity;
        expect(outMid, greaterThan(0.0));
        expect(outMid, lessThan(1.0));

        // 2) Verify schedule & 5-word stagger cap + orange button last
        final sched = ReviewEndSchedule(NocheMotion.normal, [
          for (final g in end.groups) g.rows.length,
        ]);
        // Group 1 word 4 and word 5 share the exact same start time (5-word cap)
        expect(sched.wordStart[1][5], sched.wordStart[1][4]);
        expect(sched.wordStart[1][4], greaterThan(sched.wordStart[1][3]));
        expect(
          sched.nextButtonStart,
          sched.wordStart[1][5] + NocheMotion.nextDelay,
        );

        // At 160 ms total (+90 ms): outgoing gone, "Done" starts rising while orange button still at dy = 8, op = 0
        await t.pump(const Duration(milliseconds: 90));
        expect(outgoing, findsNothing);

        final doneFinder = find.byKey(const ValueKey('end_done_title'));
        final actionFinder = find.byKey(
          const ValueKey('review_end_action_rise'),
        );
        expect(_translateYOf(t, doneFinder), closeTo(NocheMotion.row, 0.1));
        expect(_translateYOf(t, actionFinder), closeTo(NocheMotion.row, 0.1));

        // At 450 ms total (+290 ms): Done is finished, word 4 and word 5 of group 1 have identical rise progress, action button hasn't started yet
        await t.pump(const Duration(milliseconds: 290));
        expect(_translateYOf(t, doneFinder), closeTo(0.0, 0.05));
        final w4Finder = find.byKey(ValueKey('end_word_${upRows[4].word}'));
        final w5Finder = find.byKey(ValueKey('end_word_${upRows[5].word}'));
        expect(
          _translateYOf(t, w5Finder),
          closeTo(_translateYOf(t, w4Finder), 0.01),
        );
        // Orange action button starts at nextButtonStart (510 ms) -> still at dy = 8 at 450 ms
        expect(sched.nextButtonStart.inMilliseconds, greaterThan(450));
        expect(_translateYOf(t, actionFinder), closeTo(NocheMotion.row, 0.1));

        // 3) Check NocheStageBar on missed vs moved-up words
        final missedBarFinder = find.byKey(
          ValueKey('end_stage_bar_${missedRow.word}'),
        );
        final missedBar = t.widget<NocheStageBar>(missedBarFinder);
        expect(missedBar.animateFrom, isNull);
        expect(missedBar.max, rig.store.stageMax);

        final movedUpRow = upRows.firstWhere((r) => r.newStage > r.oldStage);
        final movedUpIdx = upRows.indexOf(movedUpRow);
        final movedUpStart = sched.wordStart[1][movedUpIdx];
        final movedBarFinder = find.byKey(
          ValueKey('end_stage_bar_${movedUpRow.word}'),
        );
        final movedBar = t.widget<NocheStageBar>(movedBarFinder);
        expect(movedBar.max, rig.store.stageMax);
        expect(
          movedBar.animateFrom,
          closeTo(movedUpRow.oldStage / rig.store.stageMax, 0.001),
        );
        expect(movedBar.delay, movedUpStart + ReviewMotion.stageBarDelay);

        // Before wordStart + 300 ms: fill stays at oldStage / stageMax
        final beforeBarMs = movedBar.delay.inMilliseconds - 450;
        if (beforeBarMs > 20) {
          await t.pump(Duration(milliseconds: beforeBarMs - 20));
        }
        final fillBoxFinder = find.descendant(
          of: movedBarFinder,
          matching: find.byType(FractionallySizedBox),
        );
        expect(
          t.widget<FractionallySizedBox>(fillBoxFinder).widthFactor,
          closeTo(movedUpRow.oldStage / rig.store.stageMax, 0.001),
        );

        // Mid-way through settle (wordStart + 300 + settle/2)
        await t.pump(
          Duration(milliseconds: 20 + NocheMotion.settle.inMilliseconds ~/ 2),
        );
        final midFrac = t
            .widget<FractionallySizedBox>(fillBoxFinder)
            .widthFactor!;
        expect(midFrac, greaterThan(movedUpRow.oldStage / rig.store.stageMax));
        expect(midFrac, lessThan(movedUpRow.newStage / rig.store.stageMax));

        // Settled: reaches newStage / stageMax, full-width matches word row tile width
        await t.pump(const Duration(milliseconds: 800));
        expect(
          t.widget<FractionallySizedBox>(fillBoxFinder).widthFactor,
          closeTo(movedUpRow.newStage / rig.store.stageMax, 0.001),
        );
        expect(_translateYOf(t, actionFinder), closeTo(0.0, 0.01));
        final rowRect = t.getRect(
          find.bySemanticsLabel('${movedUpRow.word}: ${movedUpRow.text}'),
        );
        final barRect = t.getRect(movedBarFinder);
        expect(barRect.width, closeTo(rowRect.width, 0.5));
      },
    );

    testWidgets(
      'ReviewScreen end screen: full-width NocheStageBar grows on Moving up and stands still on Coming back soon, with arrival choreography',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final d = dueRecs(4, kNow);
        // Set seguidas = 1 so a right answer advances stage 1 -> 2
        final recs = [
          for (final r in d.recs)
            {
              ...r,
              'ear': {...(r['ear'] as Map<String, dynamic>), 'seguidas': 1},
            },
        ];
        final lab = Lab(t, db: dbJson(recs));
        await lab.openReview();
        await lab.start();
        await lab.drive('wrrr', settleEnd: false);

        expect(lab.s.screen, LessonScreen.end);
        final end = lab.s.end!;
        expect(end.stageMax, lab.store.stageMax);
        expect(end.up, isNotEmpty);
        expect(end.soon, hasLength(1));

        final upWord = end.up.first;
        final soonWord = end.soon.first;
        final upBarFinder = find.byKey(ValueKey('end_stage_bar_$upWord'));
        final soonBarFinder = find.byKey(ValueKey('end_stage_bar_$soonWord'));
        expect(upBarFinder, findsOneWidget);
        expect(soonBarFinder, findsOneWidget);

        final upBar = t.widget<NocheStageBar>(upBarFinder);
        final soonBar = t.widget<NocheStageBar>(soonBarFinder);
        expect(upBar.animateFrom, isNotNull);
        expect(soonBar.animateFrom, isNull);
        expect(upBar.max, lab.store.stageMax);

        // Settle and verify full-width matches cell width
        await t.pump(const Duration(milliseconds: 1500));
        final upCellWidth = t
            .getSize(find.byKey(ValueKey('end_word_$upWord')))
            .width;
        expect(t.getSize(upBarFinder).width, closeTo(upCellWidth, 0.5));
        expect(find.byKey(const Key('review-end-action')), findsOneWidget);
      },
    );
  });

  group('Reduced motion', () {
    testWidgets(
      'disableAnimations: press scale 1.0, no expanding ring, level bars stand still, replay arrow stays 0, transitions have dy=0 & zero stagger',
      (t) async {
        final rig = _MotionRig(
          t,
          json: everythingJson(realRepaso),
          disableAnimations: true,
        );
        await rig.open();

        final words = realRepaso.words
            .where((w) => rig.s.planner.hearSentences(w).isNotEmpty)
            .take(2)
            .toList();
        final h0 = rig.s.planner.hearItem(
          words[0],
          rig.s.planner.hearSentences(words[0]).first,
        );
        final h1 = rig.s.planner.hearItem(
          words[1],
          rig.s.planner.hearSentences(words[1]).first,
        );
        rig.s.queue = [QueueEntry.scored(h0), QueueEntry.scored(h1)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 400));
        await rig.vt.runUntil(() => rig.s.yourTurn);
        await t.pump(const Duration(milliseconds: 400));

        // 1) Press scale stays 1.0 under reduced motion
        final wrongIdx = h0.answer == 0 ? 1 : 0;
        final wrongTile = find.byType(NocheWordTile).at(wrongIdx);
        final tileTransform = find
            .descendant(of: wrongTile, matching: find.byType(Transform))
            .first;
        final g = await t.startGesture(t.getCenter(wrongTile));
        await t.pump(NocheMotion.quick);
        expect(_scaleOf(t, tileTransform), closeTo(1.0, 0.001));
        await g.up();
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 60));

        // 2) Miss under reduced motion: replay arrow stays at 0.0, level bars stand still at 0.6
        final arrowFinder = find.byKey(const ValueKey('review_replay_arrow'));
        expect(_rotationAngleOf(t, arrowFinder), closeTo(0.0, 0.001));
        expect(
          _scaleYOf(t, find.byKey(const ValueKey('review_level_bar_0'))),
          closeTo(0.6, 0.001),
        );
        await t.pump(const Duration(milliseconds: 120));
        expect(_rotationAngleOf(t, arrowFinder), closeTo(0.0, 0.001));
        expect(
          _scaleYOf(t, find.byKey(const ValueKey('review_level_bar_0'))),
          closeTo(0.6, 0.001),
        );

        // 3) Right touch under reduced motion: zero expanding ring
        await rig.vt.runUntil(() => rig.s.choices.any((c) => c.sign));
        await t.pump(const Duration(milliseconds: 200));
        await t.tap(find.byType(NocheWordTile).at(h0.answer));
        await rig.vt.runUntil(() => rig.s.canNext);
        await t.pump();
        expect(find.byKey(const ValueKey('choice_right_ring')), findsNothing);
        await t.pump(const Duration(milliseconds: 200));
        expect(find.byKey(const ValueKey('choice_right_ring')), findsNothing);

        // 4) Item transition under reduced motion: dy == 0, zero stagger
        await t.tap(find.byKey(const Key('review-next-button')));
        await rig.vt.settle();
        await t.pump(const Duration(milliseconds: 200));
        final row0 = find.byKey(const ValueKey('review_item_row_0'));
        final row2 = find.byKey(const ValueKey('review_item_row_2'));
        expect(_translateYOf(t, row0), closeTo(0.0, 0.001));
        expect(_translateYOf(t, row2), closeTo(0.0, 0.001));
        expect(_opacityOf(t, row0), closeTo(_opacityOf(t, row2), 0.001));

        // 5) Reduced end-screen schedule: zero stagger and orange button arrives with rows
        final reducedSchedule = ReviewEndSchedule(NocheMotion.reduced, [2, 5]);
        expect(reducedSchedule.doneStart, ReviewMotion.endStartDelay);
        expect(reducedSchedule.summaryStart, ReviewMotion.endStartDelay);
        expect(reducedSchedule.nextButtonStart, ReviewMotion.endStartDelay);
        expect(reducedSchedule.wordStart[1][4], ReviewMotion.endStartDelay);
      },
    );
  });

  group('Arabic RTL motion & stage bars', () {
    testWidgets(
      'Arabic RepasoScreen: choice miss/right, RTL dash fill, and end screen stage bars render without overflow or errors',
      (t) async {
        t.view.devicePixelRatio = 2;
        t.view.physicalSize = const Size(390 * 2, 844 * 2);
        addTearDown(t.view.reset);

        final data = _arabicMotionData();
        final course = FakeCourseCatalog.arabic(repaso: data);
        await course.load();
        final vt = VirtualTime(settler: t.idle);
        final db = jsonEncode({
          'palabras': {
            for (final w in data.words)
              w.word: {
                'w': w.word,
                'primera': curseNow - 86400000,
                'oida': 1,
                'ear': {
                  'etapa': 1,
                  'paso': 1,
                  'seguidas': 1,
                  'fallos': 0,
                  'gap': 1,
                  'due': curseNow - 1000,
                  'aciertos': <int>[],
                  'ultima': 0,
                  'aparcada': 0,
                  'marca': 0,
                  'n': 1,
                  'bien': 1,
                },
                'mouth': {
                  'etapa': 0,
                  'paso': 1,
                  'seguidas': 0,
                  'fallos': 0,
                  'gap': 0,
                  'due': 0,
                  'aciertos': <int>[],
                  'ultima': 0,
                  'aparcada': 0,
                  'marca': 0,
                  'n': 0,
                  'bien': 0,
                },
              },
          },
          'dias': {},
          'cuentos': {
            'la-lluvia': {'n': 1, 'primera': curseNow - 86400000},
          },
          'ajustes': {'min': 30, 'todo': 0, 'bienvenida': 0, 'habla': 1},
          'minutos': 0,
          'v': 1,
        });
        final store = RecordingStore(vt, clock: FakeClock(curseNow), json: db);
        final clips = ScriptedClips(vt);
        final services = fakeServices(
          progress: store,
          course: course,
          clips: clips,
          clock: vt,
          rng: FakeRng(3),
          nav: FakeNavigator(),
          speech: FakeSpeechListener(isAvailable: false, instant: true),
          reduceMotion: false,
        );
        final key = GlobalKey<RepasoScreenState>();
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: coquiTheme(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: RepasoScreen(
                key: key,
                services: services,
                data: data,
                wait: vt.wait,
                imageProvider: (_) => dotPicture,
              ),
            ),
          ),
        );
        await vt.settle();
        await t.pump(const Duration(milliseconds: 200));

        final s = key.currentState!.session;
        final h0 = s.planner.hearItem(data.words[0], data.sentences[0]);
        final h1 = s.planner.hearItem(data.words[1], data.sentences[1]);
        s.queue = [QueueEntry.scored(h0), QueueEntry.scored(h1)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await vt.settle();
        await t.pump(const Duration(milliseconds: 450));

        // Item 0: answer right -> verify RTL dash fill alignment
        await vt.runUntil(() => s.yourTurn);
        await t.pump(const Duration(milliseconds: 450));
        await t.tap(find.byType(NocheWordTile).at(h0.answer));
        await vt.runUntil(() => s.canNext);
        await t.pump(const Duration(milliseconds: 350));
        final dashFill = find.byKey(const ValueKey('review_dash_fill_0'));
        expect(dashFill, findsOneWidget);
        final align = t.widget<Align>(
          find.ancestor(of: dashFill, matching: find.byType(Align)).first,
        );
        expect(align.alignment, AlignmentDirectional.centerStart);
        await t.pump(const Duration(milliseconds: 300));
        await t.tap(find.byKey(const Key('review-next-button')));
        await vt.settle();
        await t.pump(const Duration(milliseconds: 450));

        // Item 1: answer wrong, then touch shown right, then finish return
        await vt.runUntil(() => s.yourTurn);
        await t.pump(const Duration(milliseconds: 450));
        final wrongIdx = h1.answer == 0 ? 1 : 0;
        await t.tap(find.byType(NocheWordTile).at(wrongIdx));
        await vt.runUntil(() => s.choices.any((c) => c.sign));
        await t.pump(const Duration(milliseconds: 250));
        await t.tap(find.byType(NocheWordTile).at(h1.answer));
        await vt.runUntil(() => s.canNext);
        await t.pump(const Duration(milliseconds: 450));
        await t.tap(find.byKey(const Key('review-next-button')));
        await vt.settle();
        await t.pump(const Duration(milliseconds: 450));

        // Return of item 1
        await vt.runUntil(() => s.yourTurn);
        await t.pump(const Duration(milliseconds: 450));
        await t.tap(
          find.byType(NocheWordTile).at(s.choices.indexWhere((c) => c.right)),
        );
        await vt.runUntil(() => s.canNext);
        await t.pump(const Duration(milliseconds: 450));
        await t.tap(find.byKey(const Key('review-next-button')));
        await vt.runUntil(() => s.screen == LessonScreen.end);
        await t.pump(const Duration(milliseconds: 1500));

        expect(t.takeException(), isNull);
        expect(find.byType(NocheStageBar), findsNWidgets(2));
        expect(find.byKey(const Key('review-end-action')), findsOneWidget);
      },
    );
  });

  group('Request #261 keys and addMinutes', () {
    testWidgets(
      'RepasoScreen exposes review-start-disc, review-close-button, review-next-button, review-end-action and calls progress.addMinutes(> 0) on completion',
      (t) async {
        final sc = Screen(t);
        await sc.open();
        expect(find.byKey(const Key('review-start-disc')), findsOneWidget);
        expect(find.byKey(const Key('review-close-button')), findsOneWidget);

        // Run a single scored item to completion
        final word = realRepaso.words.firstWhere(
          (w) => sc.s.planner.hearSentences(w).isNotEmpty,
        );
        final hear = sc.s.planner.hearItem(
          word,
          sc.s.planner.hearSentences(word).first,
        );
        sc.s.queue = [QueueEntry.scored(hear)];

        await t.tap(find.byKey(const Key('review-start-disc')));
        await sc.settle();
        await sc.vt.runUntil(() => sc.s.yourTurn);
        await sc.settle();
        await t.tap(find.byType(NocheWordTile).at(hear.answer));
        await sc.vt.runUntil(() => sc.s.canNext);
        await sc.settle();

        expect(find.byKey(const Key('review-next-button')), findsOneWidget);
        await t.tap(find.byKey(const Key('review-next-button')));
        await sc.vt.runUntil(() => sc.s.screen == LessonScreen.end);
        await t.pump(const Duration(milliseconds: 1500));

        expect(find.byKey(const Key('review-end-action')), findsOneWidget);
        expect(sc.store.addedMinutes, isNotEmpty);
        expect(sc.store.addedMinutes.single, greaterThan(0));
      },
    );

    testWidgets(
      'ReviewScreen and LevelCheckScreen expose review-start-disc, review-close-button, review-end-action, and level-check-end-action',
      (t) async {
        setPhone(t, 412, 915, 2.625);
        final d = dueRecs(2, kNow);
        final reviewLab = Lab(t, db: dbJson(d.recs));
        await reviewLab.openReview();
        expect(find.byKey(const Key('review-start-disc')), findsOneWidget);
        expect(find.byKey(const Key('review-close-button')), findsOneWidget);
        await t.tap(find.byKey(const Key('review-start-disc')));
        await reviewLab.settle();
        await reviewLab.drive('rr');
        expect(find.byKey(const Key('review-end-action')), findsOneWidget);

        final levelLab = Lab(t, db: dbJson([]));
        await levelLab.openLevel();
        expect(find.byKey(const Key('review-start-disc')), findsOneWidget);
        expect(find.byKey(const Key('review-close-button')), findsOneWidget);
        await t.tap(find.byKey(const Key('review-start-disc')));
        await levelLab.settle();
        await levelLab.driveLevel((s, k) => s <= 1);
        expect(find.byKey(const Key('level-check-end-action')), findsOneWidget);
      },
    );
  });
}
