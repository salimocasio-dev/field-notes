import 'dart:convert';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/feature_speaking.dart';
import 'package:feature_speaking/src/call_mic.dart';
import 'package:feature_speaking/src/call_screen.dart';
import 'package:feature_speaking/src/call_text.dart';
import 'package:feature_speaking/src/entitlements_hook.dart';
import 'package:feature_speaking/src/hablar_tab.dart';
import 'package:feature_speaking/src/voice_test_controller.dart';
import 'package:feature_speaking/src/voice_test_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/call_rig.dart';
import 'support/scripted_call.dart';
import 'support/world.dart';

class _ArabicWorld {
  _ArabicWorld._({
    required this.clock,
    required this.progress,
    required this.course,
    required this.call,
    required this.nav,
    required this.haptics,
    required this.speech,
    required this.storage,
    required this.services,
  });

  final FakeClock clock;
  final RecordingProgress progress;
  final FakeCourseCatalog course;
  final ScriptedCall call;
  final FakeNavigator nav;
  final FakeHaptics haptics;
  final FakeSpeechListener speech;
  final Map<String, FakeKeyValueStore> storage;
  final Services services;

  static Future<_ArabicWorld> create({
    bool casaUnlocked = true,
    bool callAvailable = true,
    Set<String> stub = const {'manual'},
    FakeSpeechListener? speech,
    bool reduceMotion = true,
  }) async {
    final clock = FakeClock();
    final progress = RecordingProgress(clock: clock);
    final course = FakeCourseCatalog.arabic();
    await course.load();
    if (casaUnlocked) {
      for (final id in course.places.first.stories) {
        progress.storyFinished(StoryResult(id: id));
      }
    }
    final call = ScriptedCall(stub: stub, available: callAvailable);
    final nav = FakeNavigator();
    final haptics = FakeHaptics();
    final sp = speech ?? FakeSpeechListener();
    final stores = <String, FakeKeyValueStore>{};
    return _ArabicWorld._(
      clock: clock,
      progress: progress,
      course: course,
      call: call,
      nav: nav,
      haptics: haptics,
      speech: sp,
      storage: stores,
      services: fakeServices(
        progress: progress,
        course: course,
        call: call,
        nav: nav,
        haptics: haptics,
        speech: sp,
        clock: clock,
        storage: (space) => stores.putIfAbsent(space, FakeKeyValueStore.new),
        reduceMotion: reduceMotion,
      ),
    );
  }

  Widget app(Widget screen) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: coquiTheme(),
    home: Scaffold(body: screen),
  );

  Future<void> elapse(WidgetTester tester, int ms, {int step = 50}) async {
    var left = ms;
    while (left > 0) {
      final d = left < step ? left : step;
      clock.advance(Duration(milliseconds: d));
      await tester.pump(Duration(milliseconds: d));
      left -= d;
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    call.dispose();
  }
}

const _arabicVoiceContent = VoiceTestContent(
  lines: [
    VoiceLine('مرحباً يا جدة', [
      VoiceTarget('مرحباً', ['مرحبا', 'مرحباً']),
      VoiceTarget('جدة', ['جدة']),
    ]),
    VoiceLine('باب البيت', [
      VoiceTarget('باب', ['باب']),
    ]),
  ],
  labels: VoiceTestLabels(
    listening: 'أسمعك…',
    processing: 'لحظة…',
    unavailable: 'الميكروفون غير متاح.',
    again: 'مرة أخرى',
    mic: 'ميكروفون',
    next: 'التالي',
    progress: 'التقدم',
  ),
);

void main() {
  group('SpeakingModule and HablarTab on FakeCourseCatalog.arabic()', () {
    test(
      'tab label uses arabicTestLanguage.tabNames["speak"] (تكلم)',
      () async {
        final w = await _ArabicWorld.create();
        final tab = const SpeakingModule().tab(w.services);
        expect(tab, isNotNull);
        expect(tab!.label, 'تكلم');
        w.call.dispose();
      },
    );

    testWidgets('locked state displays English menus and never Danny', (
      tester,
    ) async {
      Phone.android.use(tester);
      final w = await _ArabicWorld.create(casaUnlocked: false);
      await tester.pumpWidget(w.app(HablarTab(services: w.services)));
      expect(tester.takeException(), isNull);
      expect(find.text('ARABIC'), findsOneWidget);
      expect(find.text('Speak'), findsOneWidget);
      expect(find.text('0 words ready to say'), findsOneWidget);
      expect(find.text('Opens when you finish البيت'), findsOneWidget);
      expect(find.textContaining('Danny'), findsNothing);
      await tester.tap(find.text('0 words ready to say'));
      await tester.pumpAndSettle();
      expect(find.text('Words open for speaking'), findsOneWidget);
      await w.close(tester);
    });

    testWidgets(
      'open state shows Tariq in eyebrow, job text, and call label, and mirrors cleanly under RTL',
      (tester) async {
        Phone.android.use(tester);
        final w = await _ArabicWorld.create(casaUnlocked: true);
        await tester.pumpWidget(w.app(HablarTab(services: w.services)));
        expect(tester.takeException(), isNull);
        expect(find.text('NEXT CALL WITH TARIQ · 5 MIN'), findsOneWidget);
        expect(find.text('Call Tariq'), findsOneWidget);
        expect(find.byKey(const Key('speak-call-disc')), findsOneWidget);
        expect(find.textContaining('Tariq'), findsWidgets);
        expect(find.textContaining('Danny'), findsNothing);
        expect(
          find.text('Greet Tariq, introduce yourself, and accept a drink.'),
          findsOneWidget,
        );

        // HablarTab sets Directionality from course.language.direction (RTL for Arabic).
        final rtlTitle = tester.getRect(find.text('Speak'));
        final rtlWords = tester.getRect(find.text('0 words ready to say'));
        expect(rtlTitle.left, greaterThan(rtlWords.right));
        await w.close(tester);
      },
    );

    testWidgets('tierLocked and callAvailable: false reference Tariq', (
      tester,
    ) async {
      Phone.android.use(tester);
      final lockedTier = await _ArabicWorld.create(casaUnlocked: true);
      await tester.pumpWidget(
        lockedTier.app(
          HablarTab(
            services: lockedTier.services,
            entitlementCheck: () => CallEntitlement.upgradeRequired,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.text('Live calls with Tariq are included in the top plan.'),
        findsOneWidget,
      );
      expect(find.textContaining('Danny'), findsNothing);
      await lockedTier.close(tester);

      final unavailable = await _ArabicWorld.create(
        casaUnlocked: true,
        callAvailable: false,
      );
      await tester.pumpWidget(
        unavailable.app(HablarTab(services: unavailable.services)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Calls with Tariq open later.'), findsOneWidget);
      expect(find.textContaining('Danny'), findsNothing);
      await unavailable.close(tester);
    });
  });

  group('CallScreen and CallController on FakeCourseCatalog.arabic()', () {
    testWidgets(
      'main flow: semantics, brief agentId/variables, Tariq label/help, Arabic picture tool, mouth answers, Arabic goodbye, summary Back to تكلم',
      (tester) async {
        Phone.android.use(tester);
        final semantics = tester.ensureSemantics();
        final w = await _ArabicWorld.create(stub: {'manual'});
        await tester.pumpWidget(
          w.app(CallScreen(services: w.services, placeId: 'casa')),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel(RegExp('Call Tariq')), findsWidgets);
        expect(find.bySemanticsLabel(RegExp('Call Danny')), findsNothing);
        expect(find.text('البيت · about 5 min'), findsOneWidget);
        semantics.dispose();

        // Start call
        await tester.tap(find.byType(CallMicStage));
        await tester.pump();
        expect(w.call.brief, isNotNull);
        expect(w.call.brief!.agentId, 'agent_arabic_test');
        expect(w.call.variables?['place'], 'البيت');
        final wordsOpen = w.call.variables?['words_open'] ?? '';
        expect(wordsOpen, contains('مرحباً'));
        expect(wordsOpen, contains('باب'));
        expect(wordsOpen, contains('بيت'));

        // Connected -> label Tariq; Help -> note for Tariq
        w.call.go('connect');
        await w.elapse(tester, 100);
        expect(find.text('Tariq'), findsOneWidget);

        await tester.tap(find.text('Help'));
        await w.elapse(tester, 50);
        expect(find.text('Tariq will say it again, slowly.'), findsOneWidget);

        // Tool show_picture with Arabic diacritics matches normalized Arabic word 'باب'
        final pics = w.services.pictures as FakePictureSource;
        final shownBefore = pics.shown.length;
        w.call.emit(const Tool('show_picture', {'picture': 'بَاب'}));
        await w.elapse(tester, 100);
        expect(find.byType(PictureFrame), findsOneWidget);
        expect(pics.shown.length, greaterThan(shownBefore));
        expect(pics.shown.last.cam, w.course.pairFor('باب')!.yes.cam);

        // Learner turn & Heard with Arabic diacritics records Skill.mouth answers
        w.call.emit(const Mode('listening'));
        await w.elapse(tester, 100);
        w.call.emit(const Heard('مرحباً! هذا بَاب و بَيْت.'));
        await w.elapse(tester, 50);
        expect(w.progress.word('مرحباً')?.mouth.bien, 1);
        expect(w.progress.word('باب')?.mouth.bien, 1);
        expect(w.progress.word('بيت')?.mouth.bien, 1);
        expect(
          w.progress.answers
              .where((a) => a[1] == Skill.mouth.name && a[2] == true)
              .map((a) => a[0]),
          containsAll(['مرحباً', 'باب', 'بيت']),
        );

        // Arabic goodbye triggers sendEnd; FakeCallSession sends speaking->listening after 400+2000 ms
        w.call.emit(const Heard('وداعاً!'));
        await w.elapse(tester, 50);
        expect(w.call.sent, contains(CallTexts.sendEnd));

        await w.elapse(tester, 3000);

        // End summary
        expect(find.text('Call done'), findsOneWidget);
        expect(find.text('مرحباً'), findsOneWidget);
        expect(find.text('باب'), findsOneWidget);
        expect(find.text('بيت'), findsOneWidget);
        expect(find.text('Back to تكلم'), findsOneWidget);

        await w.close(tester);
      },
    );

    testWidgets(
      'RTL directional layout: portrait places close button right of timer; landscape places PictureFrame at start/right and unflipped',
      (tester) async {
        Phone.android.use(tester);
        final portrait = await _ArabicWorld.create(stub: {'manual'});
        await tester.pumpWidget(
          portrait.app(
            CallScreen(services: portrait.services, placeId: 'casa'),
          ),
        );
        await tester.pump();
        final closeRect = tester.getRect(find.byType(LessonCloseButton));
        final timerRect = tester.getRect(find.text('00:00'));
        expect(closeRect.center.dx, greaterThan(timerRect.center.dx));
        await portrait.close(tester);
        await tester.pump();

        Phone.side.use(tester);
        final land = await _ArabicWorld.create(stub: {'manual'});
        await tester.pumpWidget(
          land.app(CallScreen(services: land.services, placeId: 'casa')),
        );
        await tester.pump();
        final picRect = tester.getRect(find.byType(PictureFrame));
        final micRect = tester.getRect(find.byType(CallMicStage));
        expect(picRect.left, greaterThan(micRect.right));

        // PictureFrame has no horizontal flip transform (m[0] >= 0)
        final picTransforms = tester.widgetList<Transform>(
          find.ancestor(
            of: find.byType(PictureFrame),
            matching: find.byType(Transform),
          ),
        );
        for (final t in picTransforms) {
          expect(t.transform.storage[0], greaterThanOrEqualTo(0));
        }
        await land.close(tester);
        await tester.pump();
      },
    );
  });

  group(
    'VoiceTestScreen and VoiceTestController on FakeCourseCatalog.arabic()',
    () {
      testWidgets(
        'instruction mentions Arabic, uses ar-SA recognitionLocale, saves lang ar-SA, matches Arabic normalization, and mirrors RTL layout',
        (tester) async {
          Phone.android.use(tester);
          final speech = FakeSpeechListener(results: ['مرحبا يا جدة', 'نافذة']);
          final w = await _ArabicWorld.create(speech: speech);
          await tester.pumpWidget(
            w.app(
              VoiceTestScreen(
                services: w.services,
                content: _arabicVoiceContent,
              ),
            ),
          );
          await tester.pump();
          await tester.pump();

          expect(
            find.text('Tap the mic and say each Arabic line.'),
            findsOneWidget,
          );

          // Progress bar dash 0 is right of the last dash in RTL
          Rect dash(int k) => tester.getRect(
            find
                .byWidgetPredicate(
                  (x) =>
                      x is AnimatedContainer && x.constraints?.maxHeight == 6,
                )
                .at(k),
          );
          final firstDash = dash(0);
          final lastDash = dash(1);
          expect(firstDash.left, greaterThan(lastDash.right));

          // Attempt line 1 (matches via Arabic diacritic/alef normalization)
          await tester.tap(
            find.byWidgetPredicate(
              (x) => x is Semantics && x.properties.label == 'ميكروفون',
            ),
          );
          await w.elapse(tester, 700);
          expect(
            speech.listens.single.locale,
            arabicTestLanguage.recognitionLocale,
          );
          expect(speech.listens.single.locale, 'ar-SA');

          final saved = jsonDecode(
            w.storage[voiceTestSpace]!.values[voiceTestRunKey]!,
          ) as Map<String, dynamic>;
          expect(saved['lang'], 'ar-SA');
          final line0 = (saved['lines'] as List).first as Map<String, dynamic>;
          expect(line0['ok'], isTrue);

          // Next -> line 2 (non-matching Arabic is rejected)
          await tester.tap(
            find.byWidgetPredicate(
              (x) => x is Semantics && x.properties.label == 'التالي',
            ),
          );
          await tester.pump();
          await tester.tap(
            find.byWidgetPredicate(
              (x) => x is Semantics && x.properties.label == 'ميكروفون',
            ),
          );
          await w.elapse(tester, 700);

          final saved2 = jsonDecode(
            w.storage[voiceTestSpace]!.values[voiceTestRunKey]!,
          ) as Map<String, dynamic>;
          final line1 = (saved2['lines'] as List)[1] as Map<String, dynamic>;
          expect(line1['ok'], isFalse);

          // Next -> end screen
          await tester.tap(
            find.byWidgetPredicate(
              (x) => x is Semantics && x.properties.label == 'التالي',
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(find.text('Heard right: 1 of 2'), findsOneWidget);

          // Row status icon is right of row text in RTL
          final rowIconRect = tester.getRect(
            find
                .byWidgetPredicate(
                  (w) =>
                      w is Container &&
                      w.constraints?.maxWidth == 24 &&
                      w.constraints?.maxHeight == 24,
                )
                .first,
          );
          final rowTextRect = tester.getRect(find.text('مرحباً يا جدة'));
          expect(rowIconRect.left, greaterThan(rowTextRect.right));

          await w.close(tester);
        },
      );
    },
  );
}
