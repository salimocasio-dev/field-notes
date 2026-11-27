// The rig of the screen tests of Repaso's games: a screen on the fakes (the real data, the mid-course learner, a virtual
// clock), played by touches. Shared by repaso_screen_test.dart and repaso_fixes_test.dart.
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/word_picture.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/repaso_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../tool/support/scripted_clips.dart';
import '../../tool/support/virtual_time.dart';
import 'recording_store.dart';
import 'repaso_course.dart';

/// A 1 x 1 picture (the book pictures are not read in a widget test).
final MemoryImage dotPicture = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
);

/// A picture of a book page's size, 196 x 216 picture pixels, drawn in one colour (made in a real async zone: pass it
/// as `bookPicture` where the size of a book picture matters; [dotPicture] is one pixel).
Future<MemoryImage> bookPageStandIn(WidgetTester t) async {
  final bytes = await t.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 196, 216),
      Paint()..color = const Color(0xFF9E9E9E),
    );
    final image = await recorder.endRecording().toImage(196, 216);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return MemoryImage(bytes!);
}

/// A dedicated single-word asset stand-in of size 196 x 104 picture pixels.
Future<MemoryImage> wordAssetStandIn(
  WidgetTester t, {
  Color color = NocheColors.right,
}) async {
  final bytes = await t.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
        .drawRect(const Rect.fromLTWH(0, 0, 196, 104), Paint()..color = color);
    final image = await recorder.endRecording().toImage(196, 104);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return MemoryImage(bytes!);
}

/// A recogniser that listens until the test says what it heard (so the listening state can be looked at).
class HeldSpeech implements SpeechListener {
  final List<_HeldTurn> _waiting = [];

  /// How many turns were started and have not been answered.
  int get waiting => _waiting.length;

  @override
  Future<bool> available() async => true;

  @override
  SpeechTurn listen({
    required String locale,
    required Duration limit,
    int maxAlternatives = 5,
  }) {
    final turn = _HeldTurn();
    _waiting.add(turn);
    return turn;
  }

  /// The oldest turn that is listening ends: the app heard [what] (nothing, when empty).
  void hear(String what) {
    final turn = _waiting.removeAt(0);
    turn._end.complete();
    turn._result.complete(
      SpeechResult(alternatives: [if (what.isNotEmpty) what], msToSound: 100),
    );
  }
}

class _HeldTurn implements SpeechTurn {
  final Completer<SpeechResult> _result = Completer();
  final Completer<void> _end = Completer();

  @override
  Future<SpeechResult> get result => _result.future;

  @override
  Future<void> get speechEnd => _end.future;

  @override
  void cancel() {}
}

class Screen {
  Screen(
    this.t, {
    String? json,
    int seed = 3,
    bool speech = true,
    List<String> heard = const [],
    this.pictures,
    this.wordAssets = const {},
    SpeechListener? listener,
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
      speech:
          listener ??
          FakeSpeechListener(
            results: heard,
            isAvailable: speech,
            instant: true,
          ),
      reduceMotion: true,
      pictures: pictures,
    );
  }

  final WidgetTester t;
  final PictureSource? pictures;
  final Map<String, WordPictureAsset> wordAssets;
  final VirtualTime vt;
  late final RecordingStore store;
  late final ScriptedClips clips;
  late final Services services;
  final FakeNavigator nav = FakeNavigator();
  final GlobalKey<RepasoScreenState> key = GlobalKey();

  RepasoSession get s => key.currentState!.session;

  Future<void> open({
    double w = 390,
    double h = 844,
    double dpr = 3,
    double text = 1,
    ImageProvider? bookPicture,
    ImageProvider Function(String url)? imageProvider,
  }) async {
    t.view.devicePixelRatio = dpr;
    t.view.physicalSize = Size(w * dpr, h * dpr);
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: coquiTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(text)),
            child: RepasoScreen(
              key: key,
              services: services,
              data: realRepaso,
              wait: vt.wait,
              wordAssets: wordAssets,
              imageProvider: imageProvider ?? (_) => bookPicture ?? dotPicture,
            ),
          ),
        ),
      ),
    );
    await settle();
  }

  Future<void> settle() async {
    await vt.settle();
    await t.pump(const Duration(milliseconds: 200));
    expect(t.takeException(), isNull);
  }

  Future<void> down(Finder f) async {
    final g = await t.startGesture(t.getCenter(f));
    await g.up();
    await settle();
  }

  bool _needsMe(QueueEntry? acted) =>
      s.canNext ||
      s.choices.any((c) => c.sign) ||
      s.mic == MicState.ready ||
      (s.yourTurn && !identical(acted, s.entry));

  /// Plays the session to its end by touches: everything right, the first scored item wrong. [each] sees every
  /// moment where he acts: 'asked KIND' the moment an item is asked (before its sentence has ended), 'turn KIND',
  /// 'shown KIND' (the sign is on the right one), 'next KIND' (Next is there), 'mic'.
  Future<void> play({Future<void> Function(String moment)? each}) async {
    await t.tap(find.byType(NochePlayDisc));
    await settle();
    QueueEntry? acted;
    QueueEntry? asked;
    var n = 0;
    bool newEntry() =>
        each != null &&
        s.screen == LessonScreen.play &&
        s.entry != null &&
        !identical(asked, s.entry);
    for (var g = 0; g < 3000 && s.screen != LessonScreen.end; g++) {
      await vt.runUntil(
        () => s.screen == LessonScreen.end || newEntry() || _needsMe(acted),
      );
      await t.pump(const Duration(milliseconds: 200));
      expect(t.takeException(), isNull);
      if (s.screen == LessonScreen.end) break;
      final it = s.item!;
      if (newEntry()) {
        asked = s.entry;
        await each!.call('asked ${it.kind.name}');
        continue;
      }
      if (s.canNext) {
        await each?.call('next ${it.kind.name}');
        await t.tap(find.text(RepasoStrings.next));
      } else if (s.choices.any((c) => c.sign)) {
        await each?.call('shown ${it.kind.name}');
        final k = s.choices.indexWhere((c) => c.sign);
        await _touch(it, k);
      } else if (s.mic == MicState.ready) {
        await each?.call('mic');
        final mic = find.byKey(const ValueKey('noche_mic_disc'));
        await t.ensureVisible(mic);
        await settle();
        await t.tap(mic);
      } else if (s.yourTurn && !identical(acted, s.entry)) {
        acted = s.entry;
        await each?.call('turn ${it.kind.name}');
        final r = s.choices.indexWhere((c) => c.right);
        switch (it) {
          case CualItem() || HearItem() || WhereItem():
            await _touch(it, n == 0 ? (r == 0 ? 1 : 0) : r);
          case BuildItem():
            for (final w in it.order) {
              final k = s.choices.indexWhere((c) => !c.done && c.label == w);
              final tile = find
                  .descendant(
                    of: find.byType(NocheTileTray).last,
                    matching: find.byType(NocheWordTile),
                  )
                  .at(k);
              // the bank can reach below the visible part of the screen (the test font is wider than the real one)
              await t.ensureVisible(tile);
              await t.tap(tile);
              await settle();
            }
          case MatchItem():
            for (var i = 0; i < 4; i++) {
              await t.ensureVisible(find.byType(NocheSpeakerTile).at(i));
              await t.tap(find.byType(NocheSpeakerTile).at(i));
              await settle();
              final word = find
                  .descendant(
                    of: find.byType(Row),
                    matching: find.byType(NocheWordTile),
                  )
                  .at(it.wordOrder.indexOf(i));
              await t.ensureVisible(word);
              await t.tap(word);
              await settle();
            }
          case SayItem():
            break;
        }
        n++;
      }
      await settle();
    }
    await t.pump(const Duration(milliseconds: 1500));
  }

  Future<void> _touch(GameItem it, int k) async {
    if (it is HearItem) {
      await t.tap(find.byType(NocheWordTile).at(k));
      await settle();
    } else {
      await down(find.byType(NochePictureChoice).at(k));
    }
  }
}
