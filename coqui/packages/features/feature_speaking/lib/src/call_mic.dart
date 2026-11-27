/// Shared Noche microphone stage for the live call screen.
library;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart';
import 'package:material_ui/material_ui.dart';

/// Maps a [CallState] to the corresponding shared [NocheMicState].
NocheMicState nocheMicStateForCall(CallState state) => switch (state) {
  CallState.idle => NocheMicState.ready,
  CallState.connecting => NocheMicState.thinking,
  CallState.danny => NocheMicState.theySpeak,
  CallState.you => NocheMicState.listening,
  CallState.proc => NocheMicState.thinking,
  CallState.done => NocheMicState.right,
  CallState.err => NocheMicState.notYet,
};

/// Normalizes live call audio level metrics (`ring` in 3..12, `wave` in 1.3..1.9)
/// into the `0.0..1.0` level expected by [NocheMic].
double callMicLevel({
  required CallState state,
  required double ring,
  required double wave,
}) => switch (state) {
  CallState.you => ((ring - 3.0) / 9.0).clamp(0.0, 1.0),
  CallState.danny => ((wave - 1.3) / 0.6).clamp(0.0, 1.0),
  _ => 0.0,
};

/// Call microphone stage backed by [NocheMic].
class CallMicStage extends StatelessWidget {
  const CallMicStage({
    super.key,
    required this.state,
    required this.language,
    this.ring = 3,
    this.wave = 1.5,
    this.reduceMotion = false,
    this.compactLabel = true,
    this.labelGap = 8,
    this.barGroupGap = NocheMic.defaultBarGroupGap,
    this.semanticLabel,
    required this.onTap,
  });

  final CallState state;
  final Language language;

  /// Microphone level spread (`3..12`) during [CallState.you].
  final double ring;

  /// Partner speech level scale (`1.3..1.9`) during [CallState.danny].
  final double wave;

  /// Forces reduced motion in addition to ambient [MediaQueryData.disableAnimations].
  final bool reduceMotion;

  /// Uses compact typography for the status word under the disc.
  final bool compactLabel;

  /// Gap between the disc and the status word under it.
  final double labelGap;

  /// Gap between the disc and each flanking five-bar level group.
  final double barGroupGap;

  /// Optional screen-reader label override for the mic button.
  final String? semanticLabel;

  /// Starts the call when tapped in [CallState.idle].
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.maybeOf(context);
    final ambientReduce = mq?.disableAnimations ?? false;
    final reduce = reduceMotion || ambientReduce;
    final mic = NocheMic(
      state: nocheMicStateForCall(state),
      language: language,
      level: callMicLevel(state: state, ring: ring, wave: wave),
      compactLabel: compactLabel,
      labelGap: labelGap,
      barGroupGap: barGroupGap,
      semanticLabel: semanticLabel,
      onPressed: state == CallState.idle ? onTap : null,
    );
    if (mq == null || reduce != ambientReduce) {
      return MediaQuery(
        data: (mq ?? const MediaQueryData()).copyWith(
          disableAnimations: reduce,
        ),
        child: mic,
      );
    }
    return mic;
  }
}
