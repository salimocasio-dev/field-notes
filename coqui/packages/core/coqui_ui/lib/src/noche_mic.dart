/// Noche mic and its six states (story N1.3, boards `Noche-Mic.dc.html` and
/// `Noche-Cuento.dc.html`).
///
/// Stateless with zero timers or delays: `thinking` renders immediately on
/// frame 0, and `notYet` stays calm and still with no red colour.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/src/noche_a11y.dart';
import 'package:coqui_ui/src/noche_icons.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
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

/// The Noche speaking microphone disc, flanking voice bars, and status word.
///
/// The word under the disc is read from [Language.micWords] for [language]
/// and formatted with [NocheType.forScript] using [Language.script] and
/// `Locale(language.code)`.
class NocheMic extends StatelessWidget {
  const NocheMic({
    super.key,
    required this.state,
    required this.language,
    this.level = 0.0,
    this.onPressed,
    this.compactLabel = false,
    this.labelGap = 16,
    this.barGroupGap = defaultBarGroupGap,
    this.semanticLabel,
  });

  final NocheMicState state;
  final Language language;
  final double level;
  final VoidCallback? onPressed;
  final bool compactLabel;
  final double labelGap;
  final double barGroupGap;
  final String? semanticLabel;

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
  Widget build(BuildContext context) {
    final Color? fillColor;
    final Color? borderColor;
    final bool hasHalo;
    final Widget discChild;
    final Color wordColor;

    switch (state) {
      case NocheMicState.ready:
        fillColor = NocheColors.next;
        borderColor = null;
        hasHalo = false;
        discChild = NocheIcon(
          NocheIcons.mic,
          size: iconSize,
          strokeWidth: 2,
          color: NocheColors.onAccent,
        );
        wordColor = NocheColors.next;
      case NocheMicState.listening:
        fillColor = NocheColors.listening;
        borderColor = null;
        hasHalo = true;
        discChild = NocheIcon(
          NocheIcons.mic,
          size: iconSize,
          strokeWidth: 2,
          color: NocheColors.ground,
        );
        wordColor = NocheColors.listening;
      case NocheMicState.thinking:
        fillColor = NocheColors.otherSoft;
        borderColor = NocheColors.other;
        hasHalo = false;
        discChild = const _ThinkingDots();
        wordColor = NocheColors.other;
      case NocheMicState.theySpeak:
        fillColor = NocheColors.micResting;
        borderColor = null;
        hasHalo = false;
        discChild = NocheIcon(
          NocheIcons.mic,
          size: iconSize,
          strokeWidth: 2,
          color: NocheColors.lessonLabel,
        );
        wordColor = NocheColors.other;
      case NocheMicState.right:
        fillColor = NocheColors.right;
        borderColor = null;
        hasHalo = false;
        discChild = const NocheIcon(
          NocheIcons.check,
          size: checkIconSize,
          strokeWidth: checkStrokeWidth,
          color: NocheColors.onAccent,
        );
        wordColor = NocheColors.right;
      case NocheMicState.notYet:
        fillColor = null;
        borderColor = NocheColors.text;
        hasHalo = false;
        discChild = const NocheIcon(
          NocheIcons.replay,
          size: iconSize,
          strokeWidth: 2,
          color: NocheColors.text,
        );
        wordColor = NocheColors.text;
    }

    final effectiveSemanticLabel =
        semanticLabel ??
        NocheA11y.label(state.a11yRole, courseWords: language.a11yWords);

    final disc = Pressable(
      onPressed: onPressed,
      semanticLabel: effectiveSemanticLabel,
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.96 : 1,
        child: Container(
          key: const ValueKey('noche_mic_disc'),
          width: discSize,
          height: discSize,
          alignment: AlignmentDirectional.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor, width: borderWidth),
            boxShadow: hasHalo
                ? const [
                    BoxShadow(
                      color: NocheColors.listeningSoft,
                      spreadRadius: haloSpread,
                    ),
                  ]
                : null,
          ),
          child: discChild,
        ),
      ),
    );

    final Widget discRow;
    if (state.showsBars) {
      final barColor = state == NocheMicState.listening
          ? NocheColors.listening
          : NocheColors.other;
      discRow = SizedBox(
        height: discSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MicLevelBars(
              key: const ValueKey('noche_mic_bars_start'),
              heights: barHeightsForLevel(level, startSide: true),
              color: barColor,
              sidePrefix: 'start',
            ),
            SizedBox(width: barGroupGap),
            disc,
            SizedBox(width: barGroupGap),
            _MicLevelBars(
              key: const ValueKey('noche_mic_bars_end'),
              heights: barHeightsForLevel(level, startSide: false),
              color: barColor,
              sidePrefix: 'end',
            ),
          ],
        ),
      );
    } else {
      discRow = SizedBox(height: discSize, child: disc);
    }

    final word = language.micWords[state.wordKey]!;
    final baseStyle = compactLabel
        ? NocheType.buttonStrong
        : NocheType.buttonStrong.copyWith(fontSize: 16, height: 24 / 16);
    final wordStyle = NocheType.forScript(
      baseStyle,
      language.script,
    ).copyWith(color: wordColor);

    final statusWord = Text(
      word,
      maxLines: 1,
      softWrap: false,
      locale: Locale(language.code),
      style: wordStyle,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        discRow,
        SizedBox(height: labelGap),
        statusWord,
      ],
    );
  }
}

class _ThinkingDots extends StatelessWidget {
  const _ThinkingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: NocheMic.thinkingDotGap),
          Container(
            key: ValueKey('noche_mic_thinking_dot_$i'),
            width: NocheMic.thinkingDotSize,
            height: NocheMic.thinkingDotSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: NocheColors.other,
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
