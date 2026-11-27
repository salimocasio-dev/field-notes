// Captures 28 Noche screenshots of every screen of feature_review across 390x844 and 412x915 at dpr 2,
// including Arabic RTL Repaso, with real Roboto and Noche fonts loaded from coqui_ui.
//
//   flutter test tool/noche_shots_test.dart --dart-define=OUT=/tmp/coqui_108_after
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test/support/lab.dart';
import '../test/support/recording_store.dart';
import '../test/support/repaso_course.dart';
import '../test/support/repaso_screen_rig.dart';
import 'support/scripted_clips.dart';
import 'support/virtual_time.dart';

const String _out = String.fromEnvironment('OUT');

Future<void> _loadFonts() async {
  final dir = '${repoRoot.path}/coqui/packages/core/coqui_ui';
  Future<void> load(String family, Iterable<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File('$dir/$f').readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await load('packages/coqui_ui/$coquiFontFamily', coquiFontFiles.values);
  await load(coquiFontFamily, coquiFontFiles.values);
  for (final entry in nocheFontFiles.entries) {
    await load('packages/coqui_ui/${entry.key}', entry.value.values);
    await load(entry.key, entry.value.values);
  }
}

RepasoData _arabicRepasoData() => RepasoData(
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

Future<void> _saveShot(
  WidgetTester t,
  Directory? dir,
  String file,
  double w,
  double h,
) async {
  for (var i = 0; i < 2; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
    await t.pump();
  }
  expect(t.takeException(), isNull, reason: file);
  expect(find.byType(ErrorWidget), findsNothing, reason: file);
  if (dir == null) return;
  final view = t.binding.renderViews.first;
  final layer = view.debugLayer! as OffsetLayer;
  final shot = await t.runAsync(() async {
    final image = await layer.toImage(view.paintBounds);
    final width = image.width;
    final height = image.height;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
    image.dispose();
    return (width: width, height: height, bytes: Uint8List.fromList(bytes));
  });
  expect(shot!.width, (w * 2).round(), reason: file);
  expect(shot.height, (h * 2).round(), reason: file);
  File('${dir.path}/$file').writeAsBytesSync(shot.bytes);
}

void main() {
  const sizes = <(double, double)>[(390, 844), (412, 915)];

  testWidgets(
    'captures Noche feature_review screenshots across both phone sizes',
    (t) async {
      await t.runAsync(_loadFonts);
      Directory? dir;
      if (_out.isNotEmpty) {
        dir = Directory(_out)..createSync(recursive: true);
      }

      for (final (w, h) in sizes) {
        final tag = '${w.round()}x${h.round()}';

        // 1. RepasoScreen start screen (seeded curso via Screen(t))
        {
          final sc = Screen(t);
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          expect(sc.s.screen, LessonScreen.start);
          await _saveShot(t, dir, 'repaso_start_$tag.png', w, h);
        }

        // 2. RepasoScreen ¿Qué oyes? right after touching a WRONG tile
        {
          final sc = Screen(t, json: everythingJson(realRepaso));
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          final word = realRepaso.words.firstWhere(
            (x) => sc.s.planner.hearSentences(x).isNotEmpty,
          );
          final sentence = sc.s.planner.hearSentences(word).first;
          final hear = sc.s.planner.hearItem(word, sentence);
          sc.s.queue = [QueueEntry.scored(hear)];
          await t.tap(find.byType(NochePlayDisc));
          await sc.settle();
          await sc.vt.runUntil(() => sc.s.yourTurn);
          await sc.settle();
          final wrongIdx = hear.answer == 0 ? 1 : 0;
          await t.tap(find.byType(NocheWordTile).at(wrongIdx));
          await sc.vt.runUntil(() => sc.s.choices.any((c) => c.sign));
          await sc.settle();
          expect(sc.s.choices[wrongIdx].ring, OptionRing.bad);
          expect(sc.s.choices[wrongIdx].cross, isTrue);
          expect(sc.s.choices[hear.answer].sign, isTrue);
          await _saveShot(t, dir, 'repaso_hear_wrong_$tag.png', w, h);
        }

        // 3. RepasoScreen Arma la frase with first word placed and a wrong word tapped
        {
          final sc = Screen(t, json: everythingJson(realRepaso));
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          sc.s.planner.nextKind = 0;
          final build = sc.s.planner.playItem(
            sc.s.planner.met,
            canSay: false,
          ) as BuildItem;
          sc.s.queue = [QueueEntry.play(build)];
          await t.tap(find.byType(NochePlayDisc));
          await sc.settle();
          await sc.vt.runUntil(() => sc.s.yourTurn);
          await sc.settle();
          final firstK = sc.s.choices.indexWhere(
            (c) => !c.done && c.label == build.order.first,
          );
          final bankTiles = find.descendant(
            of: find.byType(NocheTileTray).last,
            matching: find.byType(NocheWordTile),
          );
          await t.ensureVisible(bankTiles.at(firstK));
          await t.tap(bankTiles.at(firstK));
          await sc.settle();
          final wrongK = sc.s.choices.indexWhere(
            (c) => !c.done && c.label != build.order[1],
          );
          await t.ensureVisible(bankTiles.at(wrongK));
          await t.tap(bankTiles.at(wrongK));
          await sc.settle();
          expect(sc.s.placed, hasLength(1));
          expect(sc.s.choices[wrongK].ring, OptionRing.bad);
          expect(sc.s.choices[wrongK].cross, isTrue);
          await _saveShot(t, dir, 'repaso_build_$tag.png', w, h);
        }

        // 4. RepasoScreen Parejas with 1 pair matched
        {
          final sc = Screen(t, json: everythingJson(realRepaso));
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          sc.s.planner.nextKind = 1;
          final match = sc.s.planner.playItem(
            sc.s.planner.met,
            canSay: false,
          ) as MatchItem;
          sc.s.queue = [QueueEntry.play(match)];
          await t.tap(find.byType(NochePlayDisc));
          await sc.settle();
          await sc.vt.runUntil(() => sc.s.yourTurn);
          await sc.settle();
          await t.ensureVisible(find.byType(NocheSpeakerTile).at(0));
          await t.tap(find.byType(NocheSpeakerTile).at(0));
          await sc.settle();
          final wordTile = find
              .descendant(
                of: find.byType(Row),
                matching: find.byType(NocheWordTile),
              )
              .at(match.wordOrder.indexOf(0));
          await t.ensureVisible(wordTile);
          await t.tap(wordTile);
          await sc.settle();
          expect(sc.s.speakers[0].done, isTrue);
          expect(sc.s.speakers[0].number, 1);
          await _saveShot(t, dir, 'repaso_match_$tag.png', w, h);
        }

        // 5, 6, 7. RepasoScreen Dilo: ready, listening, and not-yet
        {
          const sentence = '¡Abre la puerta, abuela!';
          final word = realRepaso.word('puerta')!;
          final line = word.say.firstWhere((l) => l.text == sentence);
          final speech = HeldSpeech();
          final sc = Screen(
            t,
            json: everythingJson(realRepaso),
            listener: speech,
          );
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          sc.s.queue = [QueueEntry.play(SayItem(word: word.word, line: line))];
          await t.tap(find.byType(NochePlayDisc));
          await sc.settle();
          await sc.vt.runUntil(() => sc.s.mic == MicState.ready);
          await sc.settle();
          expect(sc.s.mic, MicState.ready);
          await _saveShot(t, dir, 'repaso_say_ready_$tag.png', w, h);

          await t.tap(find.byType(NocheMic));
          await sc.vt.runUntil(() => sc.s.mic == MicState.listening);
          await sc.settle();
          expect(sc.s.mic, MicState.listening);
          await _saveShot(t, dir, 'repaso_say_listening_$tag.png', w, h);

          speech.hear('algo');
          await sc.vt.runUntil(
            () => sc.s.notHeard && sc.s.mic == MicState.ready,
          );
          await sc.settle();
          expect(find.text('Heard: algo'), findsOneWidget);
          expect(find.text(RepasoStrings.tryAgain), findsOneWidget);
          await _saveShot(t, dir, 'repaso_say_not_yet_$tag.png', w, h);
        }

        // 8. RepasoScreen end screen
        {
          final sc = Screen(t);
          await sc.open(w: w, h: h, dpr: 2, text: 1);
          await sc.play();
          await t.pump(const Duration(milliseconds: 1600));
          expect(sc.s.screen, LessonScreen.end);
          await _saveShot(t, dir, 'repaso_end_$tag.png', w, h);
        }

        // 9. Fallback ReviewScreen during play right after touching the WRONG picture
        {
          setPhone(t, w, h, 2);
          final d = dueRecs(9, kNow);
          final lab = Lab(t, db: dbJson(d.recs));
          await lab.openReview();
          await lab.start();
          await lab.until(() => lab.s.ready);
          final wrongIdx = 1 - lab.right;
          await lab.touchPicture(wrongIdx);
          await t.pump(const Duration(milliseconds: 500));
          expect(lab.s.rings[wrongIdx], OptionRing.bad);
          await _saveShot(t, dir, 'review_cual_wrong_$tag.png', w, h);
        }

        // 10. Fallback ReviewScreen end screen with Moving up & Coming back soon
        {
          setPhone(t, w, h, 2);
          final d = dueRecs(9, kNow);
          final lab = Lab(t, db: dbJson(d.recs));
          await lab.openReview();
          await lab.start();
          await lab.drive('wrrrw');
          await t.pump(const Duration(milliseconds: 1600));
          expect(lab.s.screen, LessonScreen.end);
          expect(find.text('Moving up'), findsOneWidget);
          expect(find.text('Coming back soon'), findsOneWidget);
          await _saveShot(t, dir, 'review_end_$tag.png', w, h);
        }

        // 11, 12. LevelCheckScreen start screen & during play with 1 selected
        {
          setPhone(t, w, h, 2);
          final lab = Lab(t, db: dbJson([]));
          await lab.openLevel();
          expect(lab.lv.screen, LessonScreen.start);
          await _saveShot(t, dir, 'level_start_$tag.png', w, h);

          await lab.start();
          await lab.until(() => lab.lv.ready);
          await lab.touchPicture(1);
          await lab.advance(100);
          expect(lab.choices, hasLength(4));
          expect(lab.choices[1].ring, ChoiceRing.selected);
          await _saveShot(t, dir, 'level_play_$tag.png', w, h);
        }

        // 13. LevelCheckScreen end screen (right for s <= 11)
        {
          setPhone(t, w, h, 2);
          final lab = Lab(t, db: dbJson([]));
          await lab.openLevel();
          await lab.start();
          await lab.driveLevel((s, k) => s <= 11);
          expect(lab.lv.screen, LessonScreen.end);
          expect(
            find.text('You already understand the first 11 stories.'),
            findsOneWidget,
          );
          expect(find.text('To the map'), findsOneWidget);
          await _saveShot(t, dir, 'level_end_$tag.png', w, h);
        }

        // 14. Arabic RTL RepasoScreen (¿Qué oyes? answered with reveal)
        {
          setPhone(t, w, h, 2);
          final data = _arabicRepasoData();
          final course = FakeCourseCatalog.arabic(repaso: data);
          await course.load();
          final vt = VirtualTime(settler: t.idle);
          final db = jsonEncode({
            'palabras': {
              for (final word in data.words)
                word.word: {
                  'w': word.word,
                  'primera': curseNow - 86400000,
                  'oida': 1,
                  'ear': {
                    'etapa': 3,
                    'paso': 1,
                    'seguidas': 0,
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
          final store = RecordingStore(
            vt,
            clock: FakeClock(curseNow),
            json: db,
          );
          final clips = ScriptedClips(vt);
          final services = fakeServices(
            progress: store,
            course: course,
            clips: clips,
            clock: vt,
            rng: FakeRng(3),
            nav: FakeNavigator(),
            reduceMotion: true,
          );
          final key = GlobalKey<RepasoScreenState>();
          await t.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: coquiTheme(),
              home: RepasoScreen(
                key: key,
                services: services,
                data: data,
                wait: vt.wait,
                imageProvider: (_) => dotPicture,
              ),
            ),
          );
          await vt.settle();
          await t.pump(const Duration(milliseconds: 50));
          final session = key.currentState!.session;
          final hear = session.planner.hearItem(
            data.words[0],
            data.sentences[0],
          );
          session.queue = [QueueEntry.scored(hear)];
          await t.tap(find.byType(NochePlayDisc));
          await vt.settle();
          await vt.runUntil(() => session.yourTurn);
          await t.pump(const Duration(milliseconds: 50));
          await t.tap(find.byType(NocheWordTile).at(hear.answer));
          await vt.runUntil(() => session.canNext);
          await vt.settle();
          await t.pump(const Duration(milliseconds: 500));
          await _saveShot(t, dir, 'repaso_arabic_$tag.png', w, h);
        }
      }
    },
  );
}
