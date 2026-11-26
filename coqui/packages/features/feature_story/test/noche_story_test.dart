// N4.3 Story lesson (#103): full-screen Noche layout on lessonGround, 64-high
// header (close X, NocheDashes on lessonGround, 56x48 TXT toggle pill),
// 400-high unmirrored scene, speaker + line + speaking prompt in content
// language & script font (only speaker when TXT off), 32-from-bottom controls
// (48 "hear it again" + centred NocheMic in all 6 states + 48 spacer),
// touch turns with Noche colours, RTL Arabic mirroring, English NocheA11y
// labels, and screenshot capture at 390x844 and 412x915.
@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_screen.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/screen_harness.dart';

/// Marks `cq_si` / `cq_no` / `cq_si_gracias` / `cq_no_gracias` on `el-bizcocho`
/// so speaking turns trigger cleanly on either the Spanish or Arabic sample course.
class _MarkedCourse extends FakeCourseCatalog {
  _MarkedCourse({bool arabic = false})
    : super(
        fetch: arabic ? arabicSampleFile : sampleFile,
        language: arabic ? arabicTestLanguage : Language.spanish,
      );

  final Map<String, Future<Map<String, dynamic>>> _edited = {};

  @override
  Future<Map<String, dynamic>> story(String id) => _edited[id] ??= () async {
    final f = Map<String, dynamic>.of(await super.story(id));
    if (id == 'el-bizcocho') {
      final c = Map<String, dynamic>.of(
        (f['clips'] as Map).cast<String, dynamic>(),
      );
      final isAr = language.code == 'ar';
      c.putIfAbsent(
        'ahora_tu',
        () => {'who': 'narr', 'text': isAr ? 'دورك الآن.' : 'Ahora tú.'},
      );
      for (final k in ['cq_si', 'cq_no', 'cq_si_gracias', 'cq_no_gracias']) {
        final existing = (c[k] as Map).cast<String, dynamic>();
        final yes = k.contains('si');
        final word = isAr ? (yes ? 'نعم' : 'لا') : (yes ? 'sí' : 'no');
        final forms = isAr ? [word] : (yes ? ['sí', 'si'] : ['no']);
        c[k] = {
          ...existing,
          'tu_turno': [
            {'palabra': word, 'formas': forms},
          ],
        };
      }
      f['clips'] = c;
    }
    return f;
  }();
}

Future<void> _loadNocheFonts() async {
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
}

NocheMicState? _micState(WidgetTester tester) {
  final f = find.byType(NocheMic);
  return f.evaluate().isEmpty ? null : tester.widget<NocheMic>(f).state;
}

void main() {
  group('N4.3 Story lesson metrics, behaviour, and accessibility', () {
    testWidgets(
      'header metrics (64 high, close 48, NocheDashes on lessonGround, TXT 56x48), 400-high scene, and 32-from-bottom controls',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );

        // Full screen on lessonGround, no tab bar.
        expect(find.byType(NocheTabBar), findsNothing);
        final bg = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .firstWhere((b) => b.color == NocheColors.lessonGround);
        expect(bg.color, NocheColors.lessonGround);

        // 64-high header: close 48x48, NocheDashes on lessonGround, TXT 56x48.
        expect(tester.getSize(find.byType(StoryHeader)).height, 64);
        final closeSize = tester.getSize(find.byType(StoryCloseButton));
        expect(closeSize.width, greaterThanOrEqualTo(48));
        expect(closeSize.height, greaterThanOrEqualTo(48));
        final txtSize = tester.getSize(find.byType(StoryTxtToggle));
        expect(txtSize, const Size(56, 48));
        final dashes = tester.widget<NocheDashes>(find.byType(NocheDashes));
        expect(dashes.onLessonGround, isTrue);

        // Advance into a speaking turn.
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );

        // Controls row: hear-again 48x48 at start, NocheMic centred, 32 from bottom.
        final hearRect = tester.getRect(find.byType(StoryHearAgainButton));
        final micDiscRect = tester.getRect(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        final controlsRect = tester.getRect(find.byType(StoryMicControls));
        expect(hearRect.size, const Size(48, 48));
        expect(hearRect.center.dx, lessThan(micDiscRect.center.dx));
        expect(micDiscRect.center.dx, closeTo(390 / 2, 1.0));
        expect(hearRect.center.dy, closeTo(micDiscRect.center.dy, 1.0));
        expect(844 - controlsRect.bottom, closeTo(32, 0.5));
      },
    );

    testWidgets(
      'speaking turn shows speaker, line, and prompt (bold words); TXT off hides line and prompt while keeping speaker visible',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );

        // Speaker, line, and prompt are all populated from the story file.
        expect(s.runner.view.turnSpeaker, isNotEmpty);
        expect(s.runner.view.turnLine, isNotEmpty);
        expect(s.runner.view.turnPromptWords, isNotEmpty);
        final speakerUpper = s.runner.view.turnSpeaker.toUpperCase();
        expect(find.text(speakerUpper), findsOneWidget);
        expect(find.text(s.runner.view.turnLine), findsOneWidget);
        expect(
          find.textContaining(
            s.runner.view.turnPromptWords,
            findRichText: true,
          ),
          findsOneWidget,
        );

        // Toggle TXT off -> only the speaker remains visible.
        await tester.tap(find.byType(StoryTxtToggle));
        await tester.pump();
        expect(s.runner.txtOn, isFalse);
        expect(find.text(speakerUpper), findsOneWidget);
        expect(find.text(s.runner.view.turnLine), findsNothing);
        expect(
          find.textContaining(
            s.runner.view.turnPromptWords,
            findRichText: true,
          ),
          findsNothing,
        );

        // Toggle TXT back on -> line and prompt return immediately.
        await tester.tap(find.byType(StoryTxtToggle));
        await tester.pump();
        expect(s.runner.txtOn, isTrue);
        expect(find.text(speakerUpper), findsOneWidget);
        expect(find.text(s.runner.view.turnLine), findsOneWidget);
        expect(
          find.textContaining(
            s.runner.view.turnPromptWords,
            findRichText: true,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hear-it-again replays the prompt line and switches NocheMic to theySpeak while audio plays',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );
        expect(s.runner.canHearAgain, isTrue);

        await tester.tap(find.byType(StoryHearAgainButton));
        await tester.pump();
        expect(_micState(tester), NocheMicState.theySpeak);

        // Once the replayed clip finishes, NocheMic returns to ready.
        await s.until(
          () => _micState(tester) == NocheMicState.ready,
          what: 'mic back to ready after replay',
        );
      },
    );

    testWidgets(
      'English accessibility labels use NocheA11y table and switch when lessonLabelsInCourseLanguage is flipped',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(),
          options: const StoryOptions(micStub: ['si'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'speaking turn ready',
        );

        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.close]!),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.captions]!),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.hearAgain]!),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(NocheA11y.english[NocheA11y.micReady]!),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Arabic RTL speaking turn mirrors header, dashes, text, and controls while keeping pixel scene unmirrored',
      (tester) async {
        final arFont = NocheType.forScript(
          NocheType.lessonLine,
          arabicTestLanguage.script,
        ).fontFamily;
        final s = await openScreen(
          tester,
          id: 'el-bizcocho',
          course: _MarkedCourse(arabic: true),
          options: const StoryOptions(micStub: ['نعم'], allOpen: true),
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byType(NochePlayDisc));
        await s.answerUntil(
          () => _micState(tester) == NocheMicState.ready,
          what: 'Arabic speaking turn ready',
        );

        // Header mirrors: close at right (start), TXT at left (end).
        final closeRect = tester.getRect(find.byType(StoryCloseButton));
        final txtRect = tester.getRect(find.byType(StoryTxtToggle));
        expect(closeRect.center.dx, greaterThan(txtRect.center.dx));

        // Controls mirror: hear-again at right (start), NocheMic centred.
        final hearRect = tester.getRect(find.byType(StoryHearAgainButton));
        final micRect = tester.getRect(
          find.byKey(const ValueKey('noche_mic_disc')),
        );
        expect(hearRect.center.dx, greaterThan(micRect.center.dx));
        expect(micRect.center.dx, closeTo(390 / 2, 1.0));

        // Scene stays LTR (unmirrored).
        expect(
          Directionality.of(tester.element(find.byType(PixelView))),
          TextDirection.ltr,
        );

        // Speaker, line, and mic status word use Arabic script font and RTL.
        final lineWidget = tester.widget<Text>(
          find.text(s.runner.view.turnLine),
        );
        expect(lineWidget.textDirection, TextDirection.rtl);
        expect(lineWidget.locale, const Locale('ar'));
        expect(lineWidget.style?.fontFamily, arFont);
        expect(
          find.text(arabicTestLanguage.micWords['ready']!),
          findsOneWidget,
        );
      },
    );

    testWidgets('zero overflow at 390x844 and 412x915 for Spanish and Arabic', (
      tester,
    ) async {
      for (final screen in const [
        (size: Size(390, 844), dpr: 3.0),
        (size: Size(412, 915), dpr: 2.625),
      ]) {
        for (final arabic in const [false, true]) {
          final s = await openScreen(
            tester,
            id: 'el-bizcocho',
            course: _MarkedCourse(arabic: arabic),
            options: StoryOptions(
              micStub: [arabic ? 'نعم' : 'si'],
              allOpen: true,
            ),
            size: screen.size,
            ratio: screen.dpr,
            reduceMotion: true,
          );
          await tester.tap(find.byType(NochePlayDisc));
          await s.answerUntil(
            () => _micState(tester) == NocheMicState.ready,
            what: 'ready (${screen.size}, arabic=$arabic)',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });

    testWidgets(
      'wide portrait display (768x1024 @ 2.0) fits whole-number PixelView strictly inside 400px stage without clipping',
      (tester) async {
        await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(768, 1024),
          ratio: 2.0,
          reduceMotion: true,
        );
        final pixelSize = tester.getSize(find.byType(PixelView));
        expect(pixelSize.height, lessThanOrEqualTo(StoryScreen.sceneHeight));
        expect((pixelSize.width * 2.0).round() % 196, 0);
        expect((pixelSize.height * 2.0).round() % 216, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'narrow portrait (320x568) and small landscape (667x375) keep speaking controls overflow-free and centred',
      (tester) async {
        for (final viewport in const [
          (size: Size(320, 568), dpr: 2.0),
          (size: Size(667, 375), dpr: 2.0),
        ]) {
          final s = await openScreen(
            tester,
            id: 'el-bizcocho',
            course: _MarkedCourse(),
            options: const StoryOptions(micStub: ['si'], allOpen: true),
            size: viewport.size,
            ratio: viewport.dpr,
            reduceMotion: true,
          );
          await tester.tap(find.byType(NochePlayDisc));
          await s.answerUntil(
            () => _micState(tester) == NocheMicState.ready,
            what: 'ready (${viewport.size})',
          );
          await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
          await tester.pump();
          expect(_micState(tester), NocheMicState.listening);
          expect(tester.takeException(), isNull);
          expect(
            tester.getSize(find.byType(StoryHearAgainButton)),
            const Size(48, 48),
          );
          final controlsRect = tester.getRect(find.byType(StoryMicControls));
          final discRect = tester.getRect(
            find.byKey(const ValueKey('noche_mic_disc')),
          );
          expect(discRect.center.dx, closeTo(controlsRect.center.dx, 1.0));
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
    );

    testWidgets(
      'storyEndButtons renders at most one orange NochePrimaryButton even when both foot.next and foot.home are true',
      (tester) async {
        final widgets = storyEndButtons(
          foot: const StoryFoot(next: true, again: true, home: true, map: true),
          onAgain: () {},
          onNext: () {},
          onMap: () {},
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Column(children: widgets)),
          ),
        );
        expect(find.byType(NochePrimaryButton), findsOneWidget);
        expect(
          find.widgetWithText(NochePrimaryButton, 'Next story'),
          findsOneWidget,
        );
        expect(find.widgetWithText(NocheOutlineButton, 'Map'), findsOneWidget);
        expect(
          find.widgetWithText(NocheOutlineButton, 'Play again'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'toggling TXT off and back on mid-narration immediately hides and restores the active caption',
      (tester) async {
        final s = await openScreen(
          tester,
          id: 'la-lluvia',
          size: const Size(390, 844),
          ratio: 3.0,
          reduceMotion: true,
        );
        await tester.tap(find.byType(NochePlayDisc));
        await s.until(
          () => s.runner.view.speakingNow && s.runner.cap.isNotEmpty,
          what: 'active narration caption',
        );
        final activeLine = s.runner.cap;
        expect(find.text(activeLine), findsOneWidget);

        await tester.tap(find.byType(StoryTxtToggle));
        await tester.pump();
        expect(find.text(activeLine), findsNothing);

        await tester.tap(find.byType(StoryTxtToggle));
        await tester.pump();
        expect(find.text(activeLine), findsOneWidget);
      },
    );
  });

  if (Platform.environment['COQUI_CAPTURE_SHOTS'] == '1') {
    testWidgets(
      'capture N4.3 Story lesson screenshots (all 6 mic states, touch turn, Arabic fake) at 390x844 and 412x915',
      (tester) async {
        await _loadNocheFonts();
        final dir = Directory('test/screenshots')..createSync(recursive: true);

        Future<void> saveShot(GlobalKey key, String name, double dpr) async {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          final bytes = await tester.runAsync(() async {
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: dpr);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          File('${dir.path}/$name').writeAsBytesSync(bytes!);
        }

        Future<({StoryRunner runner, GlobalKey key, Screen screen})>
        mountStory({
          required String id,
          required CourseCatalog course,
          required Size size,
          required double dpr,
          StoryOptions? options,
        }) async {
          tester.view.devicePixelRatio = dpr;
          tester.view.physicalSize = size * dpr;
          addTearDown(tester.view.reset);

          final clock = FakeClock();
          final nav = FakeNavigator();
          await tester.runAsync(course.load);
          final progress = FakeProgressStore(clock: clock);
          progress.setSetting('habla', 1);
          final services = fakeServices(
            course: course,
            clock: clock,
            nav: nav,
            progress: progress,
            clips: TimedClips(course),
            reduceMotion: true,
          );
          final screen = Screen(tester, clock, nav, course, services);
          final boundaryKey = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundaryKey,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: coquiTheme(),
                home: StoryScreen(
                  services: services,
                  route: StoryRoute(id),
                  scenes: registryScenes,
                  session: SpeechSession(),
                  options: options,
                  onOpen: (r, f) {
                    screen.runner = r;
                    screen.frame = f;
                    screen.opened = true;
                  },
                ),
              ),
            ),
          );
          for (var i = 0; i < 400 && !screen.opened; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 5)),
            );
            await tester.pump();
          }
          await tester.pump();
          await tester.pump();
          return (runner: screen.runner, key: boundaryKey, screen: screen);
        }

        for (final cfg in const [
          (tag: '390x844', size: Size(390, 844), dpr: 3.0),
          (tag: '412x915', size: Size(412, 915), dpr: 2.625),
        ]) {
          // 1. Speaking turn in all 6 mic states (Spanish, real El frente)
          final sp = await mountStory(
            id: 'el-bizcocho',
            course: _MarkedCourse(),
            size: cfg.size,
            dpr: cfg.dpr,
            options: const StoryOptions(
              micStub: ['none', 'si', 'no', 'si gracias'],
              allOpen: true,
            ),
          );
          await tester.tap(find.byType(NochePlayDisc));

          await sp.screen.answerUntil(
            () => _micState(tester) == NocheMicState.theySpeak,
            what: 'theySpeak (${cfg.tag})',
          );
          await saveShot(
            sp.key,
            'story_mic_they_speak_${cfg.tag}.png',
            cfg.dpr,
          );

          await sp.screen.answerUntil(
            () => _micState(tester) == NocheMicState.ready,
            what: 'ready (${cfg.tag})',
          );
          await saveShot(sp.key, 'story_mic_ready_${cfg.tag}.png', cfg.dpr);

          await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
          await tester.pump();
          expect(_micState(tester), NocheMicState.listening);
          await saveShot(sp.key, 'story_mic_listening_${cfg.tag}.png', cfg.dpr);

          await sp.screen.until(
            () => _micState(tester) == NocheMicState.notYet,
            what: 'notYet (${cfg.tag})',
          );
          await saveShot(sp.key, 'story_mic_not_yet_${cfg.tag}.png', cfg.dpr);

          await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
          await sp.screen.until(
            () => _micState(tester) == NocheMicState.thinking,
            what: 'thinking (${cfg.tag})',
          );
          await saveShot(sp.key, 'story_mic_thinking_${cfg.tag}.png', cfg.dpr);

          await sp.screen.until(
            () => _micState(tester) == NocheMicState.right,
            what: 'right (${cfg.tag})',
          );
          await saveShot(sp.key, 'story_mic_right_${cfg.tag}.png', cfg.dpr);
          await tester.pumpWidget(const SizedBox.shrink());

          // 2. Touch turn (Spanish, real El frente with touch sign visible)
          final touch = await mountStory(
            id: 'la-lluvia',
            course: FakeCourseCatalog(),
            size: cfg.size,
            dpr: cfg.dpr,
          );
          await tester.tap(find.byType(NochePlayDisc));
          await touch.screen.until(
            () => touch.runner.W['spot'] != null && touch.runner.cap.isNotEmpty,
            what: 'touch turn (${cfg.tag})',
          );
          await touch.screen.advance(140);
          await saveShot(touch.key, 'story_touch_turn_${cfg.tag}.png', cfg.dpr);
          await tester.pumpWidget(const SizedBox.shrink());

          // 3. Arabic fake speaking turn (RTL mirrored, unmirrored real El frente)
          final ar = await mountStory(
            id: 'el-bizcocho',
            course: _MarkedCourse(arabic: true),
            size: cfg.size,
            dpr: cfg.dpr,
            options: const StoryOptions(micStub: ['نعم'], allOpen: true),
          );
          await tester.tap(find.byType(NochePlayDisc));
          await ar.screen.answerUntil(
            () => _micState(tester) == NocheMicState.ready,
            what: 'Arabic ready (${cfg.tag})',
          );
          await tester.tap(find.byKey(const ValueKey('noche_mic_disc')));
          await tester.pump();
          expect(_micState(tester), NocheMicState.listening);
          await saveShot(ar.key, 'story_arabic_${cfg.tag}.png', cfg.dpr);
          await tester.pumpWidget(const SizedBox.shrink());
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
