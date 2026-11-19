/// The play screen: a story, full screen on the dark lesson frame (index.html, docs/proyecto/09-ui-plan.md).
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/frame_renderer.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_picture.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:material_ui/material_ui.dart';

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Plays [route]'s story. The tab bar is the shell's to hide: this screen fills its box with the lesson frame.
///
/// [scenes] makes the scene the story file names. [txt] is the TXT setting (when the words show); the old page had it only
/// as `?txt=`, so it is "con" unless a caller says otherwise. [session] is what speaking remembers until the app is closed.
class StoryScreen extends StatefulWidget {
  const StoryScreen({
    super.key,
    required this.services,
    required this.route,
    required this.scenes,
    this.txt = TxtMode.con,
    this.session,
    this.options,
    this.onOpen,
  });

  final Services services;
  final StoryRoute route;
  final SceneFactory scenes;
  final TxtMode txt;
  final SpeechSession? session;

  /// The old page's address switches, for a check by machine; the route and [txt] fill in the rest.
  final StoryOptions? options;

  /// Told when the story is ready: the runner and the frame (for the dev entry and tests).
  final void Function(StoryRunner runner, FrameRenderer frame)? onOpen;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  StoryRunner? _runner;
  FrameRenderer? _frame;
  Ticker? _ticker;
  final _Repaint _repaint = _Repaint();
  Size _stage = Size.zero;
  final GlobalKey _stageKey = GlobalKey(), _micKey = GlobalKey();

  /// The app is not in the foreground (its lifecycle state is not `resumed`): the story's clock is held.
  bool _held = false;

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _held = lifecycle != null && lifecycle != AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_open());
  }

  // The story's clock does not advance while the app is out of sight: the runner stops pumping its timers and
  // holds its virtual clock, and on the return it goes on from where it stopped.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _held = state != AppLifecycleState.resumed;
    final r = _runner;
    if (r == null) return;
    if (_held) {
      r.holdClock();
    } else {
      r.resumeClock();
    }
  }

  Future<void> _open() async {
    try {
      await _s.course.load();
      final story = await _s.course.story(widget.route.id);
      final scene = await widget.scenes(story['scene'] as String, _s.rng);
      final frame = FrameRenderer(
        setup: scene.frame,
        reduceMotion: _s.reduceMotion,
      );
      final base = widget.options ?? const StoryOptions();
      final runner = StoryRunner(
        storyId: widget.route.id,
        story: story,
        E: scene.scene,
        course: _s.course,
        clips: _s.clips,
        speech: _s.speech,
        progress: _s.progress,
        rng: _s.rng,
        clock: _s.clock,
        memory: _s.storage('juego'),
        options: StoryOptions(
          fast: base.fast,
          listen: widget.route.listen || base.listen,
          txt: widget.txt,
          micOff: base.micOff,
          micStub: base.micStub,
          allOpen: base.allOpen,
          recordsProgress: base.recordsProgress,
          forced: base.forced,
          mem: base.mem,
        ),
        renderer: frame,
        session: widget.session,
        startFrog: scene.startFrog,
        frogShadow: scene.frogShadow,
      );
      runner.view.addListener(_repaint.ping);
      runner.bubbleMetrics = _metrics;
      if (_held) runner.holdClock(); // opened while the app was out of sight
      await runner.init();
      if (!mounted) {
        runner.leave();
        return;
      }
      widget.onOpen?.call(runner, frame);
      _ticker = createTicker((_) => runner.pump())..start();
      setState(() {
        _runner = runner;
        _frame = frame;
      });
    } catch (e, st) {
      // no story, or no scene for it: the frame stays as it is, with its way out; the framework hears why
      FlutterError.reportError(
        FlutterErrorDetails(exception: e, stack: st, library: 'feature_story'),
      );
    }
  }

  // what juego.js read from the page's elements when a turn's bubble chose where to stand
  BubbleMetrics? _metrics() {
    if (_stage == Size.zero) return null;
    return BubbleMetrics(
      cw: _stage.width,
      ch: _stage.height,
      bw: 56,
      bh: 45,
      mic: _anchor(),
    );
  }

  MicAnchor? _anchor() {
    final stage = _stageKey.currentContext?.findRenderObject(),
        mic = _micKey.currentContext?.findRenderObject();
    if (stage is! RenderBox ||
        mic is! RenderBox ||
        !stage.attached ||
        !mic.attached) {
      return null;
    }
    final sp = stage.localToGlobal(Offset.zero),
        mp = mic.localToGlobal(Offset.zero);
    final view = MediaQuery.sizeOf(context);
    return MicAnchor(
      cx: mp.dx + mic.size.width / 2 - sp.dx,
      top: mp.dy - sp.dy,
      viewLeft: -sp.dx,
      viewRight: view.width - sp.dx,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    final r = _runner;
    if (r != null) {
      r.view.removeListener(_repaint.ping);
      r.leave();
    }
    _repaint.dispose();
    super.dispose();
  }

  void _close() {
    _runner?.leave();
    _s.nav.back();
  }

  @override
  Widget build(BuildContext context) {
    final r = _runner, frame = _frame;
    if (r == null || frame == null) {
      // loading, or no story: the frame alone, with its way out
      return LessonFrame(
        onClose: _close,
        progress: const LessonProgressDashes(segments: 5, done: 0),
      );
    }
    return ListenableBuilder(
      listenable: _repaint,
      builder: (context, _) {
        // where the mic button is, once it has been laid out: a turn's bubble that stands above it needs it
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => r.micAnchor = mounted ? _anchor() : null,
        );
        final v = r.view;
        final ended = v.screen == StoryScreenState.end;
        final mic = micStateOf(v.mic);
        return LessonFrame(
          onClose: _close,
          onSound: r.toggleMute,
          muted: v.muted,
          progress: LessonProgressDashes(
            segments: v.dots,
            done: v.dotsLit,
            dense: v.dots > 24,
          ),
          picture: KeyedSubtree(
            key: _stageKey,
            child: StoryPicture(
              runner: r,
              pixels: frame.display,
              repaint: _repaint,
              reduceMotion: _s.reduceMotion,
              onSize: (s) => _stage = s,
            ),
          ),
          caption: v.captionOn ? v.caption : null,
          startState: v.screen == StoryScreenState.start,
          overlay: ended ? StoryEndTitle(title: v.title) : null,
          bottom: [
            if (v.screen == StoryScreenState.start && v.startShown)
              LessonStartButton(onPressed: () => unawaited(r.start())),
            if (mic != null && v.screen == StoryScreenState.play)
              KeyedSubtree(
                key: _micKey,
                child: StoryMicButton(
                  state: mic,
                  onPressed: r.tapMic,
                  reduceMotion: _s.reduceMotion,
                ),
              ),
            if (ended)
              ...storyEndButtons(
                foot: v.foot,
                onAgain: () => unawaited(r.start()),
                onNext: () => _s.nav.go(StoryRoute(r.S['next'] as String)),
                onMap: () {
                  r.leave();
                  _s.nav.go(const TabRoute('map'));
                },
              ),
          ],
        );
      },
    );
  }
}
