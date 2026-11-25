/// The play screen: a Noche story lesson, full screen on `NocheColors.lessonGround`
/// (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`, `Noche-Mic.dc.html`).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart' show displayH, displayW;
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/speech_session.dart';
import 'package:feature_story/src/runner/story_check.dart';
import 'package:feature_story/src/runner/story_options.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/frame_renderer.dart';
import 'package:feature_story/src/screen/scene_frame.dart';
import 'package:feature_story/src/screen/story_end.dart';
import 'package:feature_story/src/screen/story_mic.dart';
import 'package:feature_story/src/screen/story_not_ready.dart';
import 'package:feature_story/src/screen/story_picture.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:material_ui/material_ui.dart';

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Close X button in the 64-high story header (`Noche-Cuento.dc.html`: 48 × 48,
/// 24 px X with stroke 2.5 in `NocheColors.text`).
class StoryCloseButton extends StatelessWidget {
  const StoryCloseButton({
    super.key,
    required this.onPressed,
    required this.language,
  });

  final VoidCallback? onPressed;
  final Language language;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: NocheA11y.label(
      NocheA11y.close,
      courseWords: language.a11yWords,
    ),
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.94 : 1,
      child: const SizedBox(
        width: NocheSize.touch,
        height: NocheSize.touch,
        child: Center(
          child: NocheIcon(
            NocheIcons.close,
            size: 24,
            strokeWidth: 2.5,
            color: NocheColors.text,
          ),
        ),
      ),
    ),
  );
}

/// TXT captions toggle pill in the 64-high story header (`Noche-Cuento.dc.html`:
/// 56 × 48, radius 24; on = `text` fill and `lessonGround` text, off = 1 px
/// `lessonBorder` outline and `text` colour).
class StoryTxtToggle extends StatelessWidget {
  const StoryTxtToggle({
    super.key,
    required this.on,
    required this.onPressed,
    required this.language,
  });

  final bool on;
  final VoidCallback? onPressed;
  final Language language;

  static const double width = 56;
  static const double height = NocheSize.touch;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    selected: on,
    semanticLabel: NocheA11y.label(
      NocheA11y.captions,
      courseWords: language.a11yWords,
    ),
    builder: (context, pressed) => Transform.scale(
      scale: pressed ? 0.96 : 1,
      child: Container(
        width: width,
        height: height,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          color: on ? NocheColors.text : null,
          border: on
              ? null
              : Border.all(color: NocheColors.lessonBorder, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.pillRadius),
        ),
        child: Text(
          'TXT',
          maxLines: 1,
          softWrap: false,
          textDirection: TextDirection.ltr,
          style: NocheType.buttonStrong.copyWith(
            letterSpacing: 0.84,
            color: on ? NocheColors.lessonGround : NocheColors.text,
          ),
        ),
      ),
    ),
  );
}

/// 64-high Noche story header (`Noche-Cuento.dc.html`, `Noche-Cuento-AR.dc.html`):
/// close X (48) at start, part dashes (`NocheDashes` on `lessonGround`) in the
/// middle, and the 56 × 48 TXT toggle pill at the end.
class StoryHeader extends StatelessWidget {
  const StoryHeader({
    super.key,
    required this.onClose,
    required this.language,
    this.dots = 5,
    this.dotsLit = 0,
    this.showProgress = true,
    this.showTxt = true,
    this.txtOn = true,
    this.onToggleTxt,
  });

  static const double height = 64;

  final VoidCallback? onClose;
  final Language language;
  final int dots;
  final int dotsLit;
  final bool showProgress;
  final bool showTxt;
  final bool txtOn;
  final VoidCallback? onToggleTxt;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 16, 0),
      child: Row(
        children: [
          StoryCloseButton(onPressed: onClose, language: language),
          if (showProgress) ...[
            const SizedBox(width: 8),
            Expanded(
              child: NocheDashes.progress(
                count: dots,
                done: dotsLit,
                onLessonGround: true,
                gap: dots > 24 ? 1 : 4,
                semanticLabel: NocheA11y.label(
                  NocheA11y.partProgress,
                  courseWords: language.a11yWords,
                  args: {'current': '$dotsLit', 'total': '$dots'},
                ),
              ),
            ),
          ] else
            const Spacer(),
          if (showTxt) ...[
            const SizedBox(width: 16),
            StoryTxtToggle(
              on: txtOn,
              onPressed: onToggleTxt,
              language: language,
            ),
          ],
        ],
      ),
    ),
  );
}

/// The text section under the 400-high scene (`Noche-Cuento.dc.html`,
/// `Noche-Cuento-AR.dc.html`): speaker (`labelStrong`, `label` colour),
/// line (`lessonLine`, `text` colour), and speaking prompt (`lessonPrompt` in
/// `label` colour with bold `text` for the words to say). With TXT off, only
/// the speaker shows.
class StoryLessonText extends StatelessWidget {
  const StoryLessonText({
    super.key,
    required this.language,
    required this.txtOn,
    this.speaker = '',
    this.line = '',
    this.promptPrefix = '',
    this.promptWords = '',
  });

  final Language language;
  final bool txtOn;
  final String speaker;
  final String line;
  final String promptPrefix;
  final String promptWords;

  @override
  Widget build(BuildContext context) {
    final isArab = language.script == 'Arab';
    final topPad = isArab ? 16.0 : 24.0;
    final itemGap = isArab ? 0.0 : 8.0;

    final showSpeaker = speaker.isNotEmpty;
    final showLine = txtOn && line.isNotEmpty;
    final showPrompt = txtOn && promptWords.isNotEmpty;
    if (!showSpeaker && !showLine && !showPrompt) {
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

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(24, topPad, 24, 0),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSpeaker)
              Text(
                language.script == 'Latn' ? speaker.toUpperCase() : speaker,
                textAlign: TextAlign.start,
                textDirection: language.textDirection,
                locale: language.locale,
                style: speakerStyle,
              ),
            if (showLine) ...[
              if (showSpeaker && itemGap > 0) SizedBox(height: itemGap),
              Text(
                line,
                textAlign: TextAlign.start,
                textDirection: language.textDirection,
                locale: language.locale,
                style: lineStyle,
              ),
            ],
            if (showPrompt) ...[
              if ((showSpeaker || showLine) && itemGap > 0)
                SizedBox(height: itemGap),
              Text.rich(
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
            ],
          ],
        ),
      ),
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  StoryRunner? _runner;
  FrameRenderer? _frame;
  Ticker? _ticker;
  final _Repaint _repaint = _Repaint();
  Size _stage = Size.zero;
  final GlobalKey _stageKey = GlobalKey(), _micKey = GlobalKey();

  /// The app is not in the foreground (its lifecycle state is not `resumed`): the story's clock is held.
  bool _held = false;

  /// The story's scene is not converted yet: the screen says so (`StoryNotReady`) instead of showing the empty frame.
  bool _notConverted = false;

  /// The story needs a newer app (unsupported `minApp` or an act the scene does not have): the screen says so without starting.
  bool _needsUpdate = false;

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

  Widget _buildTextArea(StoryView v, Language lang, NocheMicState? mic) {
    if (v.screen == StoryScreenState.end) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 0),
        child: StoryEndTitle(title: v.title, language: lang),
      );
    }
    if (v.screen != StoryScreenState.play) {
      return const SizedBox.shrink();
    }
    if (mic != null) {
      final speaker = v.turnSpeaker.isNotEmpty ? v.turnSpeaker : v.speaker;
      return StoryLessonText(
        language: lang,
        txtOn: v.txtOn,
        speaker: speaker,
        line: v.turnLine,
        promptPrefix: v.turnPromptPrefix,
        promptWords: v.turnPromptWords,
      );
    }
    final bubbleShowingWords = v.bubbleOn && v.bubbleKind == BubbleKind.words;
    final line = (v.captionOn && v.caption.isNotEmpty && !bubbleShowingWords)
        ? v.caption
        : '';
    return StoryLessonText(
      language: lang,
      txtOn: v.txtOn,
      speaker: v.speaker,
      line: line,
    );
  }

  Widget? _buildControls(StoryRunner r, Language lang, NocheMicState? mic) {
    final v = r.view;
    if (v.screen == StoryScreenState.start && v.startShown) {
      return NochePlayDisc(
        key: const Key('story-start-disc'),
        size: StoryScreen.startDiscSize,
        onPressed: () => unawaited(r.start()),
        semanticLabel: 'Start story',
      );
    }
    if (mic != null && v.screen == StoryScreenState.play) {
      return KeyedSubtree(
        key: _micKey,
        child: StoryMicControls(
          state: mic,
          language: lang,
          onTapMic: r.tapMic,
          onHearAgain: r.canHearAgain ? r.hearAgain : null,
          reduceMotion: _s.reduceMotion,
        ),
      );
    }
    if (v.screen == StoryScreenState.end) {
      final buttons = storyEndButtons(
        foot: v.foot,
        onAgain: () => unawaited(r.start()),
        onNext: () => _s.nav.go(StoryRoute(r.S['next'] as String)),
        onMap: () {
          r.leave();
          _s.nav.go(const TabRoute('map'));
        },
      );
      return Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                buttons[i],
              ],
            ],
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildPortrait(
    BuildContext context,
    StoryRunner r,
    FrameRenderer frame,
    Language lang,
  ) {
    final v = r.view;
    final mic = nocheMicStateOf(v);
    final controls = _buildControls(r, lang, mic);
    final showBubble = mic == null;

    return ColoredBox(
      color: NocheColors.lessonGround,
      child: SafeArea(
        child: Column(
          children: [
            StoryHeader(
              onClose: _close,
              language: lang,
              dots: v.dots,
              dotsLit: v.dotsLit,
              txtOn: v.txtOn,
              onToggleTxt: r.toggleTxt,
            ),
            SizedBox(
              width: double.infinity,
              height: StoryScreen.sceneHeight,
              child: LayoutBuilder(
                builder: (context, c) => ClipRect(
                  child: Center(
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: c.maxWidth,
                      minHeight: 0,
                      maxHeight: double.infinity,
                      child: KeyedSubtree(
                        key: _stageKey,
                        child: StoryPicture(
                          runner: r,
                          pixels: frame.display,
                          repaint: _repaint,
                          reduceMotion: _s.reduceMotion,
                          language: lang,
                          showBubble: showBubble,
                          availableWidth: c.maxWidth,
                          onSize: (s) => _stage = s,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsetsDirectional.only(bottom: 168),
                      child: _buildTextArea(v, lang, mic),
                    ),
                  ),
                  if (controls != null)
                    PositionedDirectional(
                      start: 0,
                      end: 0,
                      bottom: StoryScreen.controlsBottom,
                      child: Center(child: controls),
                    ),
                ],
              ),
            ),
          ],
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
    final controls = _buildControls(r, lang, mic);
    final showBubble = mic == null;
    final width = MediaQuery.sizeOf(context).width;

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
                    return Center(
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
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  StoryHeader(
                    onClose: _close,
                    language: lang,
                    dots: v.dots,
                    dotsLit: v.dotsLit,
                    txtOn: v.txtOn,
                    onToggleTxt: r.toggleTxt,
                  ),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Align(
                          alignment: AlignmentDirectional.topStart,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 144,
                            ),
                            child: _buildTextArea(v, lang, mic),
                          ),
                        ),
                        if (controls != null)
                          v.screen == StoryScreenState.start
                              ? Center(child: controls)
                              : PositionedDirectional(
                                  start: 0,
                                  end: 0,
                                  bottom: 16,
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
    Widget directional(Widget child) =>
        Directionality(textDirection: lang.textDirection, child: child);
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
          'scene bake ${bakeMs == null ? '-' : bakeMs!.toStringAsFixed(0)} ms',
          textDirection: TextDirection.ltr,
          style: NocheType.bodySmall.copyWith(color: NocheColors.text),
        ),
      ),
    ),
  );
}
