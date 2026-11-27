/// Noche mic and its six states (story N1.3 + N8.2 motion, boards
/// `Noche-Mic.dc.html`, `Noche-Cuento.dc.html`, and `Noche-Motion-Cuento.dc.html`).
///
/// Zero timers or delays: `thinking` renders immediately on frame 0, `notYet`
/// stays calm and still with no red colour, and the only loops are the live
/// voice bars (`listening`/`theySpeak`) and thinking dots (`thinking`), which
/// stop when their state ends or under reduced motion.
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/src/noche_a11y.dart';
import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_motion.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:coqui_ui/src/speech_bubble.dart';
import 'package:material_ui/material_ui.dart';

/// The six states of [NocheMic].
enum NocheMicState {
  /// The learner's turn: amber disc, tap to talk.
  ready,

  /// Recording the learner's voice: sky-blue disc with halo and five voice
  /// bars on each side.
  listening,

  /// Waiting on speech recognition: plum-tinted disc with three dots, rendered
  /// immediately with no delay.
  thinking,

  /// The character or system is speaking: muted resting disc with five voice
  /// bars in `other` on each side.
  theySpeak,

  /// Heard right: green disc with bold check mark.
  right,

  /// Not yet: outlined disc with replay icon, never red and never shaking.
  notYet;

  /// Key into [Language.micWords] for this state.
  String get wordKey => switch (this) {
    NocheMicState.ready => 'ready',
    NocheMicState.listening => 'listening',
    NocheMicState.thinking => 'thinking',
    NocheMicState.theySpeak => 'theySpeak',
    NocheMicState.right => 'right',
    NocheMicState.notYet => 'notYet',
  };

  /// Accessibility role key in [NocheA11y] for this state.
  String get a11yRole => switch (this) {
    NocheMicState.ready => NocheA11y.micReady,
    NocheMicState.listening => NocheA11y.micListening,
    NocheMicState.thinking => NocheA11y.micThinking,
    NocheMicState.theySpeak => NocheA11y.micTheySpeak,
    NocheMicState.right => NocheA11y.micRight,
    NocheMicState.notYet => NocheA11y.micNotYet,
  };

  /// Whether the five start and five end level bars flank the disc.
  bool get showsBars =>
      this == NocheMicState.listening || this == NocheMicState.theySpeak;
}

enum _MicIconKind { mic, thinkingDots, check, replay }

class _MicVisualSpec {
  const _MicVisualSpec({
    required this.fill,
    required this.border,
    required this.hasHalo,
    required this.iconKind,
    required this.iconColor,
    required this.wordColor,
  });

  final Color? fill;
  final Color? border;
  final bool hasHalo;
  final _MicIconKind iconKind;
  final Color? iconColor;
  final Color wordColor;

  static _MicVisualSpec forState(NocheMicState state) => switch (state) {
    NocheMicState.ready => const _MicVisualSpec(
      fill: NocheColors.next,
      border: null,
      hasHalo: false,
      iconKind: _MicIconKind.mic,
      iconColor: NocheColors.onAccent,
      wordColor: NocheColors.next,
    ),
    NocheMicState.listening => const _MicVisualSpec(
      fill: NocheColors.listening,
      border: null,
      hasHalo: true,
      iconKind: _MicIconKind.mic,
      iconColor: NocheColors.ground,
      wordColor: NocheColors.listening,
    ),
    NocheMicState.thinking => const _MicVisualSpec(
      fill: NocheColors.otherSoft,
      border: NocheColors.other,
      hasHalo: false,
      iconKind: _MicIconKind.thinkingDots,
      iconColor: null,
      wordColor: NocheColors.other,
    ),
    NocheMicState.theySpeak => const _MicVisualSpec(
      fill: NocheColors.micResting,
      border: null,
      hasHalo: false,
      iconKind: _MicIconKind.mic,
      iconColor: NocheColors.lessonLabel,
      wordColor: NocheColors.other,
    ),
    NocheMicState.right => const _MicVisualSpec(
      fill: NocheColors.right,
      border: null,
      hasHalo: false,
      iconKind: _MicIconKind.check,
      iconColor: NocheColors.onAccent,
      wordColor: NocheColors.right,
    ),
    NocheMicState.notYet => const _MicVisualSpec(
      fill: null,
      border: NocheColors.text,
      hasHalo: false,
      iconKind: _MicIconKind.replay,
      iconColor: NocheColors.text,
      wordColor: NocheColors.text,
    ),
  };
}

/// The Noche speaking microphone disc, flanking voice bars, and status word.
///
/// The word under the disc is read from [Language.micWords] for [language]
/// (or [micWords] when constructed via [NocheMic.custom]) and formatted with
/// [NocheType.forScript].
class NocheMic extends StatefulWidget {
  const NocheMic({
    super.key,
    required this.state,
    required Language this.language,
    this.level = 0.0,
    this.onPressed,
    this.compactLabel = false,
    this.labelGap = 16,
    this.barGroupGap = defaultBarGroupGap,
    this.semanticLabel,
  }) : micWords = null,
       script = null,
       textDirection = null,
       locale = null,
       a11yWords = null;

  /// Creates a [NocheMic] without requiring a `coqui_contracts` [Language].
  const NocheMic.custom({
    super.key,
    required this.state,
    required Map<String, String> this.micWords,
    String this.script = 'Latn',
    TextDirection this.textDirection = TextDirection.ltr,
    this.locale,
    this.a11yWords,
    this.level = 0.0,
    this.onPressed,
    this.compactLabel = false,
    this.labelGap = 16,
    this.barGroupGap = defaultBarGroupGap,
    this.semanticLabel,
  }) : language = null;

  final NocheMicState state;
  final Language? language;
  final Map<String, String>? micWords;
  final String? script;
  final TextDirection? textDirection;
  final Locale? locale;
  final Map<String, String>? a11yWords;
  final double level;
  final VoidCallback? onPressed;
  final bool compactLabel;
  final double labelGap;
  final double barGroupGap;
  final String? semanticLabel;

  Map<String, String> get _effectiveMicWords => language?.micWords ?? micWords!;
  String get _effectiveScript => language?.script ?? script ?? 'Latn';
  TextDirection get _effectiveTextDirection =>
      language?.textDirection ?? textDirection ?? TextDirection.ltr;
  Locale? get _effectiveLocale =>
      language != null ? Locale(language!.code) : locale;
  Map<String, String>? get _effectiveA11yWords =>
      language?.a11yWords ?? a11yWords;

  static const double discSize = NocheSize.mic;
  static const double haloSpread = 8;
  static const double borderWidth = 2;
  static const double iconSize = 40;
  static const double checkIconSize = 44;
  static const double checkStrokeWidth = 3;
  static const double thinkingDotSize = 12;
  static const double thinkingDotGap = 8;
  static const int barsPerSide = 5;
  static const double barWidth = 4;
  static const double barRadius = 2;
  static const double barGap = 4;
  static const double defaultBarGroupGap = 16;
  static const double minBarHeight = 8;
  static const double maxBarHeight = 56;

  static const List<double> _startBarWeights = [
    1 / 6,
    3 / 6,
    5 / 6,
    2 / 6,
    4 / 6,
  ];

  static const List<double> _endBarWeights = [
    4 / 6,
    2 / 6,
    6 / 6,
    3 / 6,
    1 / 6,
  ];

  /// Computes the five bar heights (in `minBarHeight..maxBarHeight`) for
  /// [level] on the start (`startSide: true`) or end (`startSide: false`) side
  /// of the disc.
  static List<double> barHeightsForLevel(
    double level, {
    required bool startSide,
  }) {
    final clamped = level.isFinite ? level.clamp(0.0, 1.0) : 0.0;
    final weights = startSide ? _startBarWeights : _endBarWeights;
    return [
      for (final w in weights)
        (minBarHeight + (maxBarHeight - minBarHeight) * clamped * w).clamp(
          minBarHeight,
          maxBarHeight,
        ),
    ];
  }

  @override
  State<NocheMic> createState() => _NocheMicState();
}

class _NocheMicState extends State<NocheMic> with TickerProviderStateMixin {
  late final AnimationController _quickController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _haloController = AnimationController(
    vsync: this,
    value: widget.state == NocheMicState.listening ? 1.0 : 0.0,
  );
  late final AnimationController _rightRingController = AnimationController(
    vsync: this,
    value: 0.0,
  );
  late final AnimationController _thinkingController = AnimationController(
    vsync: this,
    duration: NocheMotion.thinkingCycle,
  );
  late final AnimationController _levelController = AnimationController(
    vsync: this,
    duration: NocheMotion.levelCycle,
  );

  late NocheMicState _fromState = widget.state;
  late String _fromWord = widget._effectiveMicWords[widget.state.wordKey]!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLoops();
  }

  @override
  void didUpdateWidget(NocheMic oldWidget) {
    super.didUpdateWidget(oldWidget);
    final motion = NocheMotion.of(context);
    if (widget.state != oldWidget.state) {
      _fromState = oldWidget.state;
      _fromWord = oldWidget._effectiveMicWords[oldWidget.state.wordKey]!;
      _quickController.duration = motion.quick;
      _quickController.forward(from: 0.0);

      final haloTarget = widget.state == NocheMicState.listening ? 1.0 : 0.0;
      if (_haloController.value != haloTarget || _haloController.isAnimating) {
        _haloController.animateTo(
          haloTarget,
          duration: motion.reduced ? motion.quick : motion.move,
          curve: motion.enter,
        );
      }

      if (widget.state == NocheMicState.right && !motion.reduced) {
        _rightRingController.duration = motion.settle;
        _rightRingController.forward(from: 0.0);
      } else if (_rightRingController.isAnimating ||
          _rightRingController.value > 0) {
        _rightRingController.stop();
        _rightRingController.value = 0.0;
      }
    }
    _syncLoops();
  }

  void _syncLoops() {
    final motion = NocheMotion.of(context);
    if (widget.state == NocheMicState.thinking && motion.loops) {
      if (!_thinkingController.isAnimating) {
        _thinkingController.repeat();
      }
    } else if (_thinkingController.isAnimating ||
        _thinkingController.value != 0.0) {
      _thinkingController.stop();
      _thinkingController.value = 0.0;
    }

    if (widget.state.showsBars && motion.loops) {
      if (!_levelController.isAnimating) {
        _levelController.repeat();
      }
    } else if (_levelController.isAnimating || _levelController.value != 0.0) {
      _levelController.stop();
      _levelController.value = 0.0;
    }

    if (motion.reduced &&
        (_rightRingController.isAnimating || _rightRingController.value > 0)) {
      _rightRingController.stop();
      _rightRingController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _quickController.dispose();
    _haloController.dispose();
    _rightRingController.dispose();
    _thinkingController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Color? _lerpFill(Color? a, Color? b, double p) {
    if (p >= 1.0) return b;
    if (a == null && b == null) return null;
    final from = a ?? b!.withValues(alpha: 0);
    final to = b ?? a!.withValues(alpha: 0);
    return Color.lerp(from, to, p);
  }

  BoxBorder? _lerpBorder(Color? a, Color? b, double p) {
    if (p >= 1.0) {
      return b == null
          ? null
          : Border.all(color: b, width: NocheMic.borderWidth);
    }
    if (a == null && b == null) return null;
    final from = a ?? b!.withValues(alpha: 0);
    final to = b ?? a!.withValues(alpha: 0);
    final c = Color.lerp(from, to, p)!;
    return Border.all(color: c, width: NocheMic.borderWidth);
  }

  Widget _buildIconForKind(
    _MicIconKind kind,
    Color? color, {
    required bool thinkingLooping,
  }) => switch (kind) {
    _MicIconKind.mic => NocheIcon(
      NocheIcons.mic,
      size: NocheMic.iconSize,
      strokeWidth: 2,
      color: color ?? NocheColors.onAccent,
    ),
    _MicIconKind.thinkingDots => _ThinkingDots(
      phase: _thinkingController.value,
      looping: thinkingLooping,
    ),
    _MicIconKind.check => NocheIcon(
      NocheIcons.check,
      size: NocheMic.checkIconSize,
      strokeWidth: NocheMic.checkStrokeWidth,
      color: color ?? NocheColors.onAccent,
    ),
    _MicIconKind.replay => NocheIcon(
      NocheIcons.replay,
      size: NocheMic.iconSize,
      strokeWidth: 2,
      color: color ?? NocheColors.text,
    ),
  };

  List<double> _modulatedBarHeights({
    required bool startSide,
    required bool looping,
  }) {
    final clamped = widget.level.isFinite ? widget.level.clamp(0.0, 1.0) : 0.0;
    if (!looping) {
      // Reduced motion: stand still at barHeightsForLevel(level) when level > 0,
      // or a middle height (0.5) when level == 0.
      final stillLevel = clamped > 0 ? clamped : 0.5;
      return NocheMic.barHeightsForLevel(stillLevel, startSide: startSide);
    }
    final base = NocheMic.barHeightsForLevel(clamped, startSide: startSide);
    final phase = _levelController.value;
    if (phase == 0.0) return base;

    final weights = startSide
        ? NocheMic._startBarWeights
        : NocheMic._endBarWeights;
    final sideOffset = startSide ? 0.0 : 0.35;
    return [
      for (var i = 0; i < NocheMic.barsPerSide; i++)
        () {
          if (clamped == 0.0) {
            final pulse = 0.5 * (1.0 - math.cos(2 * math.pi * phase));
            final idle = (4.0 + 12.0 * weights[i]) * pulse;
            return (base[i] + idle).clamp(
              NocheMic.minBarHeight,
              NocheMic.maxBarHeight,
            );
          }
          final offset = i * 0.17 + sideOffset;
          final delta =
              math.sin(2 * math.pi * (phase + offset)) -
              math.sin(2 * math.pi * offset);
          final amp = 8.0 + 8.0 * clamped;
          return (base[i] + amp * 0.5 * delta).clamp(
            NocheMic.minBarHeight,
            NocheMic.maxBarHeight,
          );
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final fromSpec = _MicVisualSpec.forState(_fromState);
    final toSpec = _MicVisualSpec.forState(widget.state);

    final effectiveSemanticLabel =
        widget.semanticLabel ??
        NocheA11y.label(
          widget.state.a11yRole,
          courseWords: widget._effectiveA11yWords,
        );

    final disc = Stack(
      alignment: AlignmentDirectional.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _rightRingController,
          builder: (context, _) {
            if (!_rightRingController.isAnimating || motion.reduced) {
              return const SizedBox.shrink();
            }
            final p = motion.enter.transform(_rightRingController.value);
            final scale = 1.0 + 0.5 * p;
            final opacity = (0.9 * (1.0 - p)).clamp(0.0, 1.0);
            return IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    key: const ValueKey('noche_mic_right_ring'),
                    width: NocheMic.discSize,
                    height: NocheMic.discSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NocheColors.right,
                        width: NocheMic.borderWidth,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Pressable(
          onPressed: widget.onPressed,
          semanticLabel: effectiveSemanticLabel,
          disc: true,
          builder: (context, _) => AnimatedBuilder(
            animation: Listenable.merge([
              _quickController,
              _haloController,
              _thinkingController,
            ]),
            builder: (context, _) {
              final p = motion.enter.transform(_quickController.value);
              final fillColor = _lerpFill(fromSpec.fill, toSpec.fill, p);
              final border = _lerpBorder(fromSpec.border, toSpec.border, p);

              final haloVal = _haloController.value;
              final List<BoxShadow>? boxShadow;
              if (haloVal <= 0.0) {
                boxShadow = null;
              } else if (motion.reduced) {
                final c = haloVal >= 1.0
                    ? NocheColors.listeningSoft
                    : NocheColors.listeningSoft.withValues(
                        alpha: NocheColors.listeningSoft.a * haloVal,
                      );
                boxShadow = [
                  BoxShadow(color: c, spreadRadius: NocheMic.haloSpread),
                ];
              } else {
                boxShadow = [
                  BoxShadow(
                    color: NocheColors.listeningSoft,
                    spreadRadius: NocheMic.haloSpread * haloVal,
                  ),
                ];
              }

              final thinkingLooping =
                  widget.state == NocheMicState.thinking && motion.loops;

              final Widget discChild;
              if (_quickController.value >= 1.0) {
                discChild = _buildIconForKind(
                  toSpec.iconKind,
                  toSpec.iconColor,
                  thinkingLooping: thinkingLooping,
                );
              } else if (fromSpec.iconKind == toSpec.iconKind) {
                final iconColor = Color.lerp(
                  fromSpec.iconColor,
                  toSpec.iconColor,
                  p,
                );
                discChild = _buildIconForKind(
                  toSpec.iconKind,
                  iconColor,
                  thinkingLooping: thinkingLooping,
                );
              } else {
                final outScale = motion.reduced ? 1.0 : (1.0 - 0.2 * p);
                final inScale = motion.reduced ? 1.0 : (0.8 + 0.2 * p);
                discChild = Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Opacity(
                      opacity: (1.0 - p).clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: outScale,
                        child: _buildIconForKind(
                          fromSpec.iconKind,
                          fromSpec.iconColor,
                          thinkingLooping: false,
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: p.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: inScale,
                        child: _buildIconForKind(
                          toSpec.iconKind,
                          toSpec.iconColor,
                          thinkingLooping: thinkingLooping,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Container(
                key: const ValueKey('noche_mic_disc'),
                width: NocheMic.discSize,
                height: NocheMic.discSize,
                alignment: AlignmentDirectional.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fillColor,
                  border: border,
                  boxShadow: boxShadow,
                ),
                child: discChild,
              );
            },
          ),
        ),
      ],
    );

    final Widget discRow;
    if (widget.state.showsBars) {
      final barColor = widget.state == NocheMicState.listening
          ? NocheColors.listening
          : NocheColors.other;
      final barsLooping = motion.loops;
      discRow = SizedBox(
        height: NocheMic.discSize,
        child: AnimatedBuilder(
          animation: _levelController,
          builder: (context, child) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MicLevelBars(
                key: const ValueKey('noche_mic_bars_start'),
                heights: _modulatedBarHeights(
                  startSide: true,
                  looping: barsLooping,
                ),
                color: barColor,
                sidePrefix: 'start',
              ),
              SizedBox(width: widget.barGroupGap),
              child!,
              SizedBox(width: widget.barGroupGap),
              _MicLevelBars(
                key: const ValueKey('noche_mic_bars_end'),
                heights: _modulatedBarHeights(
                  startSide: false,
                  looping: barsLooping,
                ),
                color: barColor,
                sidePrefix: 'end',
              ),
            ],
          ),
          child: disc,
        ),
      );
    } else {
      discRow = SizedBox(height: NocheMic.discSize, child: disc);
    }

    final toWord = widget._effectiveMicWords[widget.state.wordKey]!;
    final baseStyle = widget.compactLabel
        ? NocheType.buttonStrong
        : NocheType.buttonStrong.copyWith(fontSize: 16, height: 24 / 16);
    final scriptStyle = NocheType.forScript(baseStyle, widget._effectiveScript);

    final statusWord = AnimatedBuilder(
      animation: _quickController,
      builder: (context, _) {
        final p = motion.enter.transform(_quickController.value);
        final incomingText = Text(
          toWord,
          maxLines: 1,
          softWrap: false,
          textDirection: widget._effectiveTextDirection,
          locale: widget._effectiveLocale,
          style: scriptStyle.copyWith(color: toSpec.wordColor),
        );
        if (_quickController.value >= 1.0 || _fromWord == toWord) {
          final color = Color.lerp(fromSpec.wordColor, toSpec.wordColor, p)!;
          return Text(
            toWord,
            maxLines: 1,
            softWrap: false,
            textDirection: widget._effectiveTextDirection,
            locale: widget._effectiveLocale,
            style: scriptStyle.copyWith(color: color),
          );
        }
        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(
                  opacity: (1.0 - p).clamp(0.0, 1.0),
                  child: Text(
                    _fromWord,
                    maxLines: 1,
                    softWrap: false,
                    textDirection: widget._effectiveTextDirection,
                    locale: widget._effectiveLocale,
                    style: scriptStyle.copyWith(color: fromSpec.wordColor),
                  ),
                ),
              ),
            ),
            Opacity(opacity: p.clamp(0.0, 1.0), child: incomingText),
          ],
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        discRow,
        SizedBox(height: widget.labelGap),
        statusWord,
      ],
    );
  }
}

class _ThinkingDots extends StatelessWidget {
  const _ThinkingDots({required this.phase, required this.looping});

  final double phase;
  final bool looping;

  double _opacityForDot(int index) {
    if (!looping) return 1.0;
    final shifted = ((phase - index / 6.0) % 1.0 + 1.0) % 1.0;
    final wave = 0.5 + 0.5 * math.cos(2 * math.pi * shifted);
    return 0.35 + 0.65 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: NocheMic.thinkingDotGap),
          Opacity(
            opacity: _opacityForDot(i),
            child: Container(
              key: ValueKey('noche_mic_thinking_dot_$i'),
              width: NocheMic.thinkingDotSize,
              height: NocheMic.thinkingDotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: NocheColors.other,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MicLevelBars extends StatelessWidget {
  const _MicLevelBars({
    super.key,
    required this.heights,
    required this.color,
    required this.sidePrefix,
  });

  final List<double> heights;
  final Color color;
  final String sidePrefix;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: NocheMic.barGap),
            _MicLevelBar(
              key: ValueKey('noche_mic_bar_${sidePrefix}_$i'),
              height: heights[i],
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

class _MicLevelBar extends StatelessWidget {
  const _MicLevelBar({super.key, required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: NocheMic.barWidth,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(NocheMic.barRadius),
      ),
    );
  }
}
