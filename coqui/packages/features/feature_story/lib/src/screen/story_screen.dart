/// The play screen: a Noche story lesson, full screen on `NocheColors.lessonGround`
/// (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`, `Noche-Mic.dc.html`,
/// `Noche-Motion-Cuento.dc.html`, `Noche-Motion-Tocar.dc.html`,
/// `Noche-Motion-Lugar.dc.html`).
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show displayH, displayW;
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/motion.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_check.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/frame_renderer.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_header.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_not_ready.dart';
import 'package:feature_story/src/screen/story_picture.dart';
import 'package:feature_story/src/wording.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:material_ui/material_ui.dart';

export 'package:feature_story/src/screen/story_header.dart';

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Three small `other`-coloured level bars beside a touch-turn line while the
/// line replays (`Noche-Motion-Tocar.dc.html`: 4 × 24, radius 2, gap 4).
/// Loops only while [playing] and `motion.loops`; stands still at middle height
/// under reduced motion.
class StorySmallLevelBars extends StatefulWidget {
  const StorySmallLevelBars({
    super.key,
    required this.playing,
    this.reduceMotion = false,
  });

  final bool playing;
  final bool reduceMotion;

  static const double barWidth = 4;
  static const double barHeight = 24;
  static const double barRadius = 2;
  static const double barGap = 4;

  @override
  State<StorySmallLevelBars> createState() => _StorySmallLevelBarsState();
}

class _StorySmallLevelBarsState extends State<StorySmallLevelBars>
    with TickerProviderStateMixin {
  late final AnimationController _barA = AnimationController(
    vsync: this,
    duration: StoryMotion.smallBarCycleA,
  );
  late final AnimationController _barB = AnimationController(
    vsync: this,
    duration: StoryMotion.smallBarCycleB,
  );
  late final AnimationController _barC = AnimationController(
    vsync: this,
    duration: StoryMotion.smallBarCycleC,
  );

  void _sync() {
    if (!mounted) return;
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    final loop = widget.playing && motion.loops;
    for (final c in [_barA, _barB, _barC]) {
      if (loop) {
        if (!c.isAnimating) c.repeat(reverse: true);
      } else if (c.isAnimating) {
        c.stop();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(StorySmallLevelBars old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _barA.dispose();
    _barB.dispose();
    _barC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    return ExcludeSemantics(
      child: AnimatedOpacity(
        key: const ValueKey('story_touch_level_bars'),
        opacity: widget.playing ? 1.0 : 0.0,
        duration: motion.quick,
        curve: motion.enter,
        child: SizedBox(
          height: StorySmallLevelBars.barHeight,
          child: AnimatedBuilder(
            animation: Listenable.merge([_barA, _barB, _barC]),
            builder: (context, _) {
              final scales = motion.loops
                  ? [
                      0.15 + 0.85 * _barA.value,
                      0.15 + 0.85 * _barB.value,
                      0.15 + 0.85 * _barC.value,
                    ]
                  : const [0.6, 0.6, 0.6];
              return Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0)
                      const SizedBox(width: StorySmallLevelBars.barGap),
                    Container(
                      key: ValueKey('story_touch_level_bar_$i'),
                      width: StorySmallLevelBars.barWidth,
                      height: StorySmallLevelBars.barHeight * scales[i],
                      decoration: BoxDecoration(
                        color: NocheColors.other,
                        borderRadius: BorderRadius.circular(
                          StorySmallLevelBars.barRadius,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Fades the TXT-controlled lines (`line` and `prompt`) over `quick` when
/// [visible] toggles, omitting them from the tree once fully faded out.
class _QuickTxtFade extends StatefulWidget {
  const _QuickTxtFade({
    required this.visible,
    required this.reduceMotion,
    required this.child,
  });

  final bool visible;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_QuickTxtFade> createState() => _QuickTxtFadeState();
}

class _QuickTxtFadeState extends State<_QuickTxtFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.visible ? 1.0 : 0.0,
  );

  @override
  void didUpdateWidget(_QuickTxtFade old) {
    super.didUpdateWidget(old);
    if (widget.visible != old.visible) {
      final motion = StoryMotion.resolve(
        context,
        serviceReduceMotion: widget.reduceMotion,
      );
      _controller.animateTo(
        widget.visible ? 1.0 : 0.0,
        duration: motion.quick,
        curve: motion.enter,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.visible && _controller.value <= 0.0) {
          return const SizedBox.shrink();
        }
        return Opacity(
          key: const ValueKey('story_txt_lines_opacity'),
          opacity: _controller.value.clamp(0.0, 1.0),
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: ExcludeSemantics(excluding: !widget.visible, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// The text section under the 400-high scene (`Noche-Cuento.dc.html`,
/// `Noche-Cuento-AR.dc.html`, `Noche-Motion-Cuento.dc.html`,
/// `Noche-Motion-Tocar.dc.html`): speaker (`labelStrong`, `label` colour),
/// line (`lessonLine`, `text` colour, with optional small level bars during
/// touch-turn replay), and speaking prompt (`lessonPrompt` in `label` colour
/// with bold `text` for the words to say). Rows rise by `row`, `stagger` apart;
/// toggling TXT fades the lines in `quick` while keeping the speaker visible.
class StoryLessonText extends StatelessWidget {
  const StoryLessonText({
    super.key,
    required this.language,
    required this.txtOn,
    this.speaker = '',
    this.line = '',
    this.promptPrefix = '',
    this.promptWords = '',
    this.showReplayBars = false,
    this.arriveDelay = Duration.zero,
    this.reduceMotion = false,
  });

  final Language language;
  final bool txtOn;
  final String speaker;
  final String line;
  final String promptPrefix;
  final String promptWords;
  final bool showReplayBars;
  final Duration arriveDelay;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final isArab = language.script == 'Arab';
    final topPad = isArab ? 16.0 : 24.0;
    final itemGap = isArab ? 0.0 : 8.0;

    final hasSpeaker = speaker.isNotEmpty;
    final hasLine = line.isNotEmpty;
    final hasPrompt = promptWords.isNotEmpty;
    if (!hasSpeaker && !hasLine && !hasPrompt) {
      return const SizedBox.shrink();
    }

    final speakerStyle = NocheType.forScript(
      NocheType.labelStrong,
      language.script,
    ).copyWith(color: NocheColors.label);
    final lineStyle = NocheType.forScript(
      NocheType.lessonLine,
      language.script,
    ).copyWith(color: NocheColors.text);
    final promptLabelStyle = NocheType.forScript(
      NocheType.lessonPrompt,
      language.script,
    ).copyWith(color: NocheColors.label);
    final promptBoldStyle = NocheType.forScript(
      NocheType.lessonPrompt.copyWith(fontWeight: FontWeight.w700),
      language.script,
    ).copyWith(color: NocheColors.text);

    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: reduceMotion,
    );
    final effectiveDelay = motion.reduced ? Duration.zero : arriveDelay;

    final lineWidget = hasLine
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              top: hasSpeaker && itemGap > 0 ? itemGap : 0,
            ),
            child: _QuickTxtFade(
              visible: txtOn,
              reduceMotion: reduceMotion,
              child: showReplayBars
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            line,
                            textAlign: TextAlign.start,
                            textDirection: language.textDirection,
                            locale: language.locale,
                            style: lineStyle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StorySmallLevelBars(
                          playing: showReplayBars,
                          reduceMotion: reduceMotion,
                        ),
                      ],
                    )
                  : Text(
                      line,
                      textAlign: TextAlign.start,
                      textDirection: language.textDirection,
                      locale: language.locale,
                      style: lineStyle,
                    ),
            ),
          )
        : null;

    final promptWidget = hasPrompt
        ? Padding(
            padding: EdgeInsetsDirectional.only(
              top: (hasSpeaker || hasLine) && itemGap > 0 ? itemGap : 0,
            ),
            child: _QuickTxtFade(
              visible: txtOn,
              reduceMotion: reduceMotion,
              child: Text.rich(
                TextSpan(
                  children: [
                    if (promptPrefix.isNotEmpty)
                      TextSpan(text: promptPrefix, style: promptLabelStyle),
                    TextSpan(text: promptWords, style: promptBoldStyle),
                  ],
                ),
                textAlign: TextAlign.start,
                textDirection: language.textDirection,
                locale: language.locale,
              ),
            ),
          )
        : null;

    final rows = <Widget>[
      if (hasSpeaker)
        Text(
          language.script == 'Latn' ? speaker.toUpperCase() : speaker,
          textAlign: TextAlign.start,
          textDirection: language.textDirection,
          locale: language.locale,
          style: speakerStyle,
        ),
      ?lineWidget,
      ?promptWidget,
    ];

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24, topPad, 24, 0),
      child: SizedBox(
        width: double.infinity,
        child: NocheArrive(
          delay: effectiveDelay,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }
}

/// Cross-transitions between turns: the outgoing turn fades out in `quick` on
/// `exit` while the incoming turn's rows rise via [NocheArrive] (`row`,
/// `stagger` apart).
class _StoryTurnTransition extends StatefulWidget {
  const _StoryTurnTransition({
    required this.turnKey,
    required this.reduceMotion,
    required this.child,
  });

  final String turnKey;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_StoryTurnTransition> createState() => _StoryTurnTransitionState();
}

class _StoryTurnTransitionState extends State<_StoryTurnTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _out = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_onOutStatus);

  Widget? _outgoing;
  GlobalKey? _outgoingKey;
  GlobalKey _currentKey = GlobalKey();

  void _onOutStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null && mounted) {
      setState(() {
        _outgoing = null;
        _outgoingKey = null;
      });
    }
  }

  @override
  void didUpdateWidget(_StoryTurnTransition old) {
    super.didUpdateWidget(old);
    if (widget.turnKey != old.turnKey) {
      final motion = StoryMotion.resolve(
        context,
        serviceReduceMotion: widget.reduceMotion,
      );
      if (old.turnKey.isNotEmpty) {
        _outgoing = old.child;
        _outgoingKey = _currentKey;
        _out.duration = motion.quick;
        _out.forward(from: 0.0);
      }
      _currentKey = GlobalKey();
    }
  }

  @override
  void dispose() {
    _out
      ..removeStatusListener(_onOutStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    return Stack(
      alignment: AlignmentDirectional.topStart,
      children: [
        if (_outgoing != null)
          AnimatedBuilder(
            animation: _out,
            builder: (context, child) {
              final opacity = (1.0 - motion.exit.transform(_out.value)).clamp(
                0.0,
                1.0,
              );
              return IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    key: const ValueKey('story_turn_outgoing'),
                    opacity: opacity,
                    child: child,
                  ),
                ),
              );
            },
            child: KeyedSubtree(key: _outgoingKey, child: _outgoing!),
          ),
        KeyedSubtree(key: _currentKey, child: widget.child),
      ],
    );
  }
}

/// Single-child arrival wrapper matching `NocheArrive` (`row` rise + fade in
/// `move` on `enter` after [delay]; `quick` fade in place under reduced motion)
/// while keeping `alwaysIncludeSemantics: true` so controls remain discoverable
/// to accessibility from frame 0.
class _StoryArriveSlot extends StatefulWidget {
  const _StoryArriveSlot({
    super.key,
    required this.delay,
    required this.reduceMotion,
    required this.child,
  });

  final Duration delay;
  final bool reduceMotion;
  final Widget child;

  @override
  State<_StoryArriveSlot> createState() => _StoryArriveSlotState();
}

class _StoryArriveSlotState extends State<_StoryArriveSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late NocheMotionData _motion;
  bool _started = false;
  double _totalUs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    final effectiveDelay = _motion.reduced ? Duration.zero : widget.delay;
    final total = effectiveDelay + _motion.move;
    _totalUs = total.inMicroseconds.toDouble();
    if (_totalUs <= 0) {
      _controller.value = 1.0;
    } else {
      _controller.duration = total;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDelay = _motion.reduced ? Duration.zero : widget.delay;
    final delayUs = effectiveDelay.inMicroseconds.toDouble();
    final moveUs = _motion.move.inMicroseconds.toDouble();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double p;
        if (_controller.isCompleted || _totalUs <= 0) {
          p = 1.0;
        } else {
          final elapsedUs = _controller.value * _totalUs;
          if (elapsedUs <= delayUs) {
            p = 0.0;
          } else if (moveUs <= 0 || elapsedUs >= delayUs + moveUs) {
            p = 1.0;
          } else {
            final raw = ((elapsedUs - delayUs) / moveUs).clamp(0.0, 1.0);
            p = _motion.enter.transform(raw);
          }
        }
        final dy = _motion.row * (1.0 - p);
        return Transform.translate(
          key: const ValueKey('story_arrive_controls'),
          offset: Offset(0, dy),
          child: Opacity(
            opacity: p.clamp(0.0, 1.0),
            alwaysIncludeSemantics: true,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Plays [route]'s story. Full screen on `NocheColors.lessonGround`, no tab bar.
///
/// [scenes] makes the scene the story file names. [txt] is the initial TXT
/// captions setting (`TxtMode.con` unless a caller says otherwise). [session]
/// is what speaking remembers until the app is closed.
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
    this.showPerf = false,
  });

  static const double sceneHeight = 400;
  static const double endSceneHeight = 296;
  static const double controlsBottom = 32;
  static const double startDiscSize = 72;

  final Services services;
  final StoryRoute route;
  final SceneFactory scenes;
  final TxtMode txt;
  final SpeechSession? session;

  /// The old page's address switches, for a check by machine; the route and [txt] fill in the rest.
  final StoryOptions? options;

  /// Told when the story is ready: the runner and the frame (for the dev entry and tests).
  final void Function(StoryRunner runner, FrameRenderer frame)? onOpen;

  /// Shows, in a small chip in a corner, how long the bake of the scene's state now on screen took (the app's
  /// `?perf=1`). Off by default.
  final bool showPerf;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  StoryRunner? _runner;
  FrameRenderer? _frame;
  Ticker? _ticker;
  final _Repaint _repaint = _Repaint();
  Size _stage = Size.zero;
  final GlobalKey _stageKey = GlobalKey(), _micKey = GlobalKey();

  /// Animates the scene window from `400` under the header (`0.0`) to `296` at
  /// the top (`1.0`) when entering the end of the story (`pageIn` on `enter`).
  late final AnimationController _endWindowAnim = AnimationController(
    vsync: this,
    value: 0.0,
  );

  /// Holds `notYet` for [StoryMotion.missHold] (`900 ms`) before replaying the
  /// prompt line on a speaking-turn miss.
  late final AnimationController _missHoldAnim = AnimationController(
    vsync: this,
    duration: StoryMotion.missHold,
  )..addStatusListener(_onMissHoldStatus);

  /// Holds any dash fill triggered during a speaking-turn `right` state for
  /// [StoryMotion.rightDashDelay] (`600 ms`) before letting `NocheDashes` fill.
  late final AnimationController _rightDashAnim = AnimationController(
    vsync: this,
    duration: StoryMotion.rightDashDelay,
  )..addStatusListener(_onRightDashStatus);

  /// The app is not in the foreground (its lifecycle state is not `resumed`): the story's clock is held.
  bool _held = false;

  /// The story's scene is not converted yet: the screen says so (`StoryNotReady`) instead of showing the empty frame.
  bool _notConverted = false;

  /// The story needs a newer app (unsupported `minApp` or an act the scene does not have): the screen says so without starting.
  bool _needsUpdate = false;

  StoryScreenState _lastScreen = StoryScreenState.start;
  NocheMicState? _lastMic;
  bool _rightDashHolding = false;
  int _heldDotsLit = 0;

  /// Snapshot taken right before the story runs so the end screen knows which
  /// focus words are new and how many minutes were logged before the story.
  Set<String> _knownBefore = const {};
  double _beforeMinutes = 0;
  StoryEndSummary? _endSummary;
  StoryFoot? _endSummaryFoot;
  String? _endSummaryTitle;

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

  void _snapshotBeforeRun(Map<String, dynamic> story) {
    final focus = <String>[
      for (final w in (story['focus_words'] as List?) ?? const [])
        if (w is String && w.isNotEmpty) w,
    ];
    _knownBefore = {
      for (final w in focus)
        if ((_s.progress.word(w)?.ear.etapa ?? 0) > 0) w,
    };
    final today = DateTime.fromMillisecondsSinceEpoch(
      _s.clock.nowMs(),
      isUtc: true,
    );
    final todayMins = _s.progress.minutesOn(today);
    _beforeMinutes = todayMins > 0 ? todayMins : _s.progress.minutes;
    _endSummary = null;
    _endSummaryFoot = null;
    _endSummaryTitle = null;
  }

  void _onMissHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final r = _runner;
    if (r == null) return;
    if (nocheMicStateOf(r.view) == NocheMicState.notYet && r.canHearAgain) {
      r.hearAgain();
    }
  }

  void _onRightDashStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _rightDashHolding = false;
    _repaint.ping();
  }

  void _onRunnerViewChanged() {
    final r = _runner;
    if (r == null || !mounted) return;
    final v = r.view;
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );

    if (v.screen != _lastScreen) {
      final enteringEnd = v.screen == StoryScreenState.end;
      final leavingEnd = _lastScreen == StoryScreenState.end;
      _lastScreen = v.screen;
      if (enteringEnd) {
        _rightDashHolding = false;
        _rightDashAnim.stop();
        _missHoldAnim.stop();
        _endSummary = null;
        _endSummaryFoot = null;
        _endSummaryTitle = null;
        if (motion.reduced) {
          _endWindowAnim.value = 1.0;
        } else {
          _endWindowAnim.duration = motion.pageIn;
          _endWindowAnim.forward(from: _endWindowAnim.value);
        }
      } else if (leavingEnd) {
        _endSummary = null;
        _endSummaryFoot = null;
        _endSummaryTitle = null;
        if (motion.reduced) {
          _endWindowAnim.value = 0.0;
        } else {
          _endWindowAnim.duration = motion.pageOut;
          _endWindowAnim.reverse(from: _endWindowAnim.value);
        }
      }
    }

    final mic = nocheMicStateOf(v);
    if (mic != _lastMic) {
      final enteredNotYet =
          mic == NocheMicState.notYet && _lastMic != NocheMicState.notYet;
      final enteredRight =
          mic == NocheMicState.right && _lastMic != NocheMicState.right;
      _lastMic = mic;

      if (enteredNotYet) {
        _missHoldAnim.duration = StoryMotion.missHold;
        _missHoldAnim.forward(from: 0.0);
      } else if (mic != NocheMicState.notYet && _missHoldAnim.isAnimating) {
        _missHoldAnim.stop();
        _missHoldAnim.value = 0.0;
      }

      if (enteredRight && !motion.reduced) {
        _rightDashHolding = true;
        _heldDotsLit = v.dotsLit;
        _rightDashAnim.duration = StoryMotion.rightDashDelay;
        _rightDashAnim.forward(from: 0.0);
      } else if (mic != NocheMicState.right && _rightDashHolding) {
        _rightDashHolding = false;
        _rightDashAnim.stop();
      }
    }

    _repaint.ping();
  }

  Future<void> _open() async {
    try {
      await _s.course.load();
      if (storyNeedsAppUpdate(
        course: _s.course,
        storyId: widget.route.id,
        info: _s.info,
      )) {
        if (mounted) setState(() => _needsUpdate = true);
        return;
      }
      final story = await _s.course.story(widget.route.id);
      final StoryScene scene;
      try {
        scene = await widget.scenes(story['scene'] as String, _s.rng);
      } on UnimplementedError {
        // the scene is not converted yet (`registryScenes`, coqui_scenes' `loadScene`): not a fault, the screen says so
        if (mounted) setState(() => _notConverted = true);
        return;
      }
      if (storyNeedsAppUpdate(
        course: _s.course,
        storyId: widget.route.id,
        info: _s.info,
        story: story,
        scene: scene.scene,
      )) {
        if (mounted) setState(() => _needsUpdate = true);
        return;
      }
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
      _snapshotBeforeRun(runner.S);
      runner.view.addListener(_onRunnerViewChanged);
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
      // no story, or no scene for it (any failure but a scene not converted yet): the frame stays as it is, with its way out;
      // the framework hears why
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
    _missHoldAnim
      ..removeStatusListener(_onMissHoldStatus)
      ..dispose();
    _rightDashAnim
      ..removeStatusListener(_onRightDashStatus)
      ..dispose();
    _endWindowAnim.dispose();
    final r = _runner;
    if (r != null) {
      r.view.removeListener(_onRunnerViewChanged);
      r.leave();
    }
    _repaint.dispose();
    super.dispose();
  }

  void _close() {
    _runner?.leave();
    _s.nav.back();
  }

  void _startOrReplay(StoryRunner r) {
    _snapshotBeforeRun(r.S);
    unawaited(r.start());
  }

  void _onEndPrimary(StoryRunner r, StoryEndNextAction action) {
    switch (action.kind) {
      case StoryEndNextKind.review:
        r.leave();
        _s.nav.go(const ReviewRoute());
      case StoryEndNextKind.story:
        _s.nav.go(StoryRoute(action.storyId!));
      case StoryEndNextKind.map:
        r.leave();
        _s.nav.go(const TabRoute('map'));
    }
  }

  void _onTapMic(StoryRunner r) {
    if (_missHoldAnim.isAnimating) {
      _missHoldAnim.stop();
      _missHoldAnim.value = 0.0;
    }
    r.tapMic();
  }

  void _onHearAgain(StoryRunner r) {
    if (_missHoldAnim.isAnimating) {
      _missHoldAnim.stop();
      _missHoldAnim.value = 0.0;
    }
    r.hearAgain();
  }

  int _displayedDotsLit(StoryView v) {
    if (_rightDashHolding && v.screen != StoryScreenState.end) {
      return _heldDotsLit;
    }
    return v.dotsLit;
  }

  ({String key, Widget child}) _buildPlayTextArea(
    StoryRunner r,
    Language lang,
    NocheMicState? mic,
  ) {
    final v = r.view;
    if (v.screen != StoryScreenState.play) {
      return (key: '', child: const SizedBox.shrink());
    }
    if (mic != null) {
      final speaker = v.turnSpeaker.isNotEmpty ? v.turnSpeaker : v.speaker;
      final key = 'speak|$speaker|${v.turnLine}|${v.turnPromptWords}';
      return (
        key: key,
        child: StoryLessonText(
          key: ValueKey('story_lesson_text_$key'),
          language: lang,
          txtOn: v.txtOn,
          speaker: speaker,
          line: v.turnLine,
          promptPrefix: v.turnPromptPrefix,
          promptWords: v.turnPromptWords,
          arriveDelay: StoryMotion.lessonArriveDelay,
          reduceMotion: _s.reduceMotion,
        ),
      );
    }
    final bubbleShowingWords = v.bubbleOn && v.bubbleKind == BubbleKind.words;
    final line =
        (v.caption.isNotEmpty &&
            !bubbleShowingWords &&
            (v.captionOn || !v.txtOn))
        ? v.caption
        : '';
    final isTouchReplay =
        v.speakingNow && v.touchFeedback?.kind == TouchFeedbackKind.miss;
    final key = (v.speaker.isEmpty && line.isEmpty)
        ? ''
        : 'play|${v.speaker}|$line';
    return (
      key: key,
      child: StoryLessonText(
        key: ValueKey('story_lesson_text_$key'),
        language: lang,
        txtOn: v.txtOn,
        speaker: v.speaker,
        line: line,
        showReplayBars: isTouchReplay,
        arriveDelay: StoryMotion.lessonArriveDelay,
        reduceMotion: _s.reduceMotion,
      ),
    );
  }

  Widget? _buildPlayControls(
    StoryRunner r,
    Language lang,
    NocheMicState? mic,
    NocheMotionData motion,
  ) {
    final v = r.view;
    final controlsDelay = motion.reduced
        ? Duration.zero
        : StoryMotion.controlsArriveDelay;

    if (v.screen == StoryScreenState.start && v.startShown) {
      return _StoryArriveSlot(
        key: const ValueKey('story_controls_start'),
        delay: controlsDelay,
        reduceMotion: _s.reduceMotion,
        child: NochePlayDisc(
          key: const Key('story-start-disc'),
          size: StoryScreen.startDiscSize,
          onPressed: () => _startOrReplay(r),
          semanticLabel: StoryWording.startStorySemantic,
        ),
      );
    }
    if (mic != null && v.screen == StoryScreenState.play) {
      return _StoryArriveSlot(
        key: const ValueKey('story_controls_mic'),
        delay: controlsDelay,
        reduceMotion: _s.reduceMotion,
        child: KeyedSubtree(
          key: _micKey,
          child: StoryMicControls(
            state: mic,
            language: lang,
            onTapMic: () => _onTapMic(r),
            onHearAgain: r.canHearAgain ? () => _onHearAgain(r) : null,
            replayCount: v.replayCount,
            reduceMotion: _s.reduceMotion,
          ),
        ),
      );
    }
    return null;
  }

  StoryEndSummary _currentEndSummary(StoryRunner r) {
    final v = r.view;
    if (_endSummary == null ||
        _endSummaryFoot != v.foot ||
        _endSummaryTitle != v.title) {
      _endSummaryFoot = v.foot;
      _endSummaryTitle = v.title;
      _endSummary = buildStoryEndSummary(
        storyId: widget.route.id,
        story: r.S,
        foot: v.foot,
        listen: r.OIR,
        course: _s.course,
        progress: _s.progress,
        clock: _s.clock,
        knownBefore: _knownBefore,
        beforeMinutes: _beforeMinutes,
      );
    }
    return _endSummary!;
  }

  Widget _buildEndPanel(StoryRunner r, Language lang) {
    final summary = _currentEndSummary(r);
    return StoryEndPanel(
      key: const ValueKey('story_end_panel'),
      summary: summary,
      foot: r.view.foot,
      language: lang,
      onAgain: () => _startOrReplay(r),
      onPrimary: () => _onEndPrimary(r, summary.nextAction),
      onMap: () {
        r.leave();
        _s.nav.go(const TabRoute('map'));
      },
      reduceMotion: _s.reduceMotion,
    );
  }

  Widget _buildPortrait(
    BuildContext context,
    StoryRunner r,
    FrameRenderer frame,
    Language lang,
  ) {
    final v = r.view;
    final mic = nocheMicStateOf(v);
    final isEnd = v.screen == StoryScreenState.end;
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    final controls = _buildPlayControls(r, lang, mic, motion);
    final playText = _buildPlayTextArea(r, lang, mic);
    final showBubble = mic == null && !isEnd;

    return ColoredBox(
      color: NocheColors.lessonGround,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) {
            final viewW = viewport.maxWidth.isFinite
                ? viewport.maxWidth
                : displayW.toDouble();
            final playSceneH = viewport.maxHeight.isFinite
                ? math.min(
                    StoryScreen.sceneHeight,
                    math.max(
                      180.0,
                      viewport.maxHeight - StoryHeader.height - 200,
                    ),
                  )
                : StoryScreen.sceneHeight;
            final endSceneH = math.min(StoryScreen.endSceneHeight, playSceneH);
            final maxW = math.min(viewW, playSceneH * displayW / displayH);
            final picSize = storyPictureSize(
              availableWidth: maxW,
              devicePixelRatio: dpr,
            );
            final windowTag = StoryMotion.storyWindowTag(widget.route.id);

            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. Play text & controls area (fades out in quick on exit at end)
                PositionedDirectional(
                  key: const ValueKey('story_play_body_slot'),
                  start: 0,
                  end: 0,
                  top: StoryHeader.height + playSceneH,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: isEnd,
                    child: AnimatedOpacity(
                      key: const ValueKey('story_play_body_opacity'),
                      opacity: isEnd ? 0.0 : 1.0,
                      duration: motion.quick,
                      curve: motion.exit,
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: AlignmentDirectional.topStart,
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: const EdgeInsetsDirectional.only(
                                  bottom: 8,
                                ),
                                child: _StoryTurnTransition(
                                  turnKey: playText.key,
                                  reduceMotion: _s.reduceMotion,
                                  child: playText.child,
                                ),
                              ),
                            ),
                          ),
                          if (controls != null)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                bottom: StoryScreen.controlsBottom,
                              ),
                              child: Center(child: controls),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. End-of-story summary panel under the 296-high window
                if (isEnd)
                  PositionedDirectional(
                    key: const ValueKey('story_end_panel_slot'),
                    start: 0,
                    end: 0,
                    top: endSceneH,
                    bottom: 0,
                    child: _buildEndPanel(r, lang),
                  )
                else
                  const SizedBox.shrink(key: ValueKey('story_end_empty_slot')),

                // 3. 64-high header (holds across turns; fades in quick at end)
                PositionedDirectional(
                  key: const ValueKey('story_header_slot'),
                  start: 0,
                  end: 0,
                  top: 0,
                  height: StoryHeader.height,
                  child: IgnorePointer(
                    ignoring: isEnd,
                    child: AnimatedOpacity(
                      key: const ValueKey('story_header_opacity'),
                      opacity: isEnd ? 0.0 : 1.0,
                      duration: motion.quick,
                      curve: motion.exit,
                      child: StoryHeader(
                        onClose: _close,
                        language: lang,
                        dots: v.dots,
                        dotsLit: _displayedDotsLit(v),
                        txtOn: v.txtOn,
                        onToggleTxt: r.toggleTxt,
                        reduceMotion: _s.reduceMotion,
                      ),
                    ),
                  ),
                ),

                // 4. Shared NocheWindow (400 under header -> 296 at top in pageIn,
                //    same whole-number PixelView scale throughout; keyed so the
                //    picture never remounts when entering the end screen)
                AnimatedBuilder(
                  key: const ValueKey('story_scene_window_slot'),
                  animation: _endWindowAnim,
                  builder: (context, child) {
                    final p = motion.reduced
                        ? _endWindowAnim.value
                        : motion.enter.transform(_endWindowAnim.value);
                    final winTop = ui.lerpDouble(StoryHeader.height, 0.0, p)!;
                    final winH = ui.lerpDouble(playSceneH, endSceneH, p)!;
                    final offset = Offset(
                      (viewW - picSize.width) / 2,
                      (winH - picSize.height) / 2,
                    );
                    return PositionedDirectional(
                      start: 0,
                      end: 0,
                      top: winTop,
                      height: winH,
                      child: NocheLtr(
                        child: NocheWindow(
                          tag: windowTag,
                          borderRadius: 0,
                          pictureSize: picSize,
                          pictureOffset: offset,
                          child: child!,
                        ),
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: _stageKey,
                    child: StoryPicture(
                      runner: r,
                      pixels: frame.display,
                      repaint: _repaint,
                      reduceMotion: _s.reduceMotion,
                      language: lang,
                      showBubble: showBubble,
                      availableWidth: maxW,
                      onSize: (s) => _stage = s,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    StoryRunner r,
    FrameRenderer frame,
    Language lang,
  ) {
    final v = r.view;
    final mic = nocheMicStateOf(v);
    final isEnd = v.screen == StoryScreenState.end;
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: _s.reduceMotion,
    );
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    final controls = _buildPlayControls(r, lang, mic, motion);
    final playText = _buildPlayTextArea(r, lang, mic);
    final showBubble = mic == null && !isEnd;
    final width = MediaQuery.sizeOf(context).width;
    final windowTag = StoryMotion.storyWindowTag(widget.route.id);

    return ColoredBox(
      color: NocheColors.lessonGround,
      child: SafeArea(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.5),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final maxW = c.maxHeight.isFinite
                        ? math.min(
                            c.maxWidth,
                            c.maxHeight * displayW / displayH,
                          )
                        : c.maxWidth;
                    final picSize = storyPictureSize(
                      availableWidth: maxW,
                      devicePixelRatio: dpr,
                    );
                    return Center(
                      child: SizedBox(
                        width: picSize.width,
                        height: picSize.height,
                        child: NocheLtr(
                          child: NocheWindow(
                            tag: windowTag,
                            borderRadius: 0,
                            pictureSize: picSize,
                            pictureOffset: Offset.zero,
                            child: KeyedSubtree(
                              key: _stageKey,
                              child: StoryPicture(
                                runner: r,
                                pixels: frame.display,
                                repaint: _repaint,
                                reduceMotion: _s.reduceMotion,
                                language: lang,
                                showBubble: showBubble,
                                availableWidth: maxW,
                                onSize: (s) => _stage = s,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  IgnorePointer(
                    ignoring: isEnd,
                    child: AnimatedOpacity(
                      key: const ValueKey('story_header_opacity'),
                      opacity: isEnd ? 0.0 : 1.0,
                      duration: motion.quick,
                      curve: motion.exit,
                      child: StoryHeader(
                        onClose: _close,
                        language: lang,
                        dots: v.dots,
                        dotsLit: _displayedDotsLit(v),
                        txtOn: v.txtOn,
                        onToggleTxt: r.toggleTxt,
                        reduceMotion: _s.reduceMotion,
                      ),
                    ),
                  ),
                  Expanded(
                    child: isEnd
                        ? _buildEndPanel(r, lang)
                        : v.screen == StoryScreenState.start && controls != null
                        ? Center(child: controls)
                        : Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.topStart,
                                  child: SingleChildScrollView(
                                    physics: const ClampingScrollPhysics(),
                                    padding: const EdgeInsetsDirectional.only(
                                      bottom: 8,
                                    ),
                                    child: _StoryTurnTransition(
                                      turnKey: playText.key,
                                      reduceMotion: _s.reduceMotion,
                                      child: playText.child,
                                    ),
                                  ),
                                ),
                              ),
                              if (controls != null)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    bottom: 16,
                                  ),
                                  child: Center(child: controls),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _s.course.language;
    final media = MediaQuery.maybeOf(context);
    final disableAnimations =
        (media?.disableAnimations ?? false) || _s.reduceMotion;
    Widget directional(Widget child) {
      final dir = Directionality(
        textDirection: lang.textDirection,
        child: child,
      );
      if (media == null || media.disableAnimations == disableAnimations) {
        return dir;
      }
      return MediaQuery(
        data: media.copyWith(disableAnimations: disableAnimations),
        child: dir,
      );
    }

    final r = _runner, frame = _frame;
    if (_needsUpdate) {
      return directional(
        StoryNotReady(
          onClose: _close,
          line: storyNeedsUpdateLine,
          language: lang,
        ),
      );
    }
    if (_notConverted) {
      return directional(StoryNotReady(onClose: _close, language: lang));
    }
    if (r == null || frame == null) {
      // loading, or no story: the Noche header alone, with its way out
      return directional(
        ColoredBox(
          color: NocheColors.lessonGround,
          child: SafeArea(
            child: Column(
              children: [
                StoryHeader(
                  onClose: _close,
                  language: lang,
                  dots: 5,
                  dotsLit: 0,
                  txtOn: widget.txt != TxtMode.no,
                  reduceMotion: _s.reduceMotion,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final story = ListenableBuilder(
      listenable: _repaint,
      builder: (context, _) {
        // where the mic button is, once it has been laid out
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => r.micAnchor = mounted ? _anchor() : null,
        );
        return CoquiLayout.lessonLandscape(context)
            ? _buildLandscape(context, r, frame, lang)
            : _buildPortrait(context, r, frame, lang);
      },
    );
    if (!widget.showPerf) return directional(story);
    return directional(
      Stack(
        fit: StackFit.expand,
        children: [
          story,
          PositionedDirectional(
            top: CoquiLayout.safeTop(context) + StoryHeader.height + 4,
            end: 4,
            child: ValueListenableBuilder<double?>(
              valueListenable: frame.currentBakeMs,
              builder: (context, ms, _) => StoryPerfChip(bakeMs: ms),
            ),
          ),
        ],
      ),
    );
  }
}

/// The corner chip of `showPerf`: the bake time of the scene's state now on screen, in ms. It takes no touch: it stands over
/// the picture, and the old page has no such chip to put a finger on.
class StoryPerfChip extends StatelessWidget {
  const StoryPerfChip({super.key, required this.bakeMs});

  /// Null before the first frame.
  final double? bakeMs;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      key: const Key('story-perf-chip'),
      decoration: BoxDecoration(
        color: NocheColors.lessonPanel,
        borderRadius: BorderRadius.circular(NocheSize.grid),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        child: Text(
          StoryWording.sceneBake(bakeMs),
          textDirection: TextDirection.ltr,
          style: NocheType.bodySmall.copyWith(color: NocheColors.text),
        ),
      ),
    ),
  );
}
