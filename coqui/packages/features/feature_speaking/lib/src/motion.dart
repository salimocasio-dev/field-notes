/// Screen-local motion timings, helpers, and route builder for
/// `feature_speaking` (epic N8, story N8.15, `Noche-Motion-Llamada.dc.html`).
///
/// This is the only file under `feature_speaking/lib/` permitted to call
/// [NocheMotion.ms]. All other durations, curves, and distances come directly
/// from [NocheMotion] / [NocheMotionData].
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_speaking/src/call_controller.dart' show tickMs;
import 'package:material_ui/material_ui.dart';

/// Feature-local motion constants and curve/opacity helpers for the Speak tab
/// and live call screen.
abstract final class SpeakingMotion {
  /// Delay before the call screen's close button and timer fade in on arrival.
  static final Duration callChromeAfter = NocheMotion.ms(200);

  /// Delay before the call screen's picture rises into place on arrival.
  static final Duration callPictureAfter = NocheMotion.ms(160);

  /// Delay before returning Speak chrome fades in on back navigation (`pageOut`).
  static final Duration backFadeAfter = NocheMotion.ms(40);

  /// Delay before the "Call done" summary or error message begins arriving
  /// after the live call fades out in `quick`.
  static final Duration doneStartAfter = NocheMotion.ms(160);

  /// 50 ms tick loop interval for [CallController.tick].
  static final Duration callTick = NocheMotion.ms(tickMs);

  /// Shared Hero tag connecting the Speak tab's call disc to the call screen's
  /// shared [NocheMic].
  static const Object callMicHeroTag = 'coqui_speaking_call_mic_disc';

  /// Vertical rise distance (in logical px) for the small `"After <place>"`
  /// locked-place pill under the locked place tab.
  static const double lockHintRise = 4;

  /// Resolves the effective [NocheMotionData], honouring both ambient
  /// `MediaQuery.disableAnimations` and `services.reduceMotion`.
  static NocheMotionData resolve(
    BuildContext context, {
    required bool serviceReduceMotion,
  }) {
    final ambient = NocheMotion.of(context);
    if (ambient.reduced || serviceReduceMotion) return NocheMotion.reduced;
    return ambient;
  }

  /// Direction [NocheFollow] enters from when switching reached place pills.
  static NocheFollowSide placeFollowSide({
    required int fromIndex,
    required int toIndex,
  }) => toIndex >= fromIndex ? NocheFollowSide.end : NocheFollowSide.start;

  /// Evaluates a single timed segment (`0 -> 1`) at [elapsedUs] microseconds,
  /// starting at [start], running for [duration] on [curve].
  static double segmentProgressUs({
    required double elapsedUs,
    required Duration start,
    required Duration duration,
    required Curve curve,
  }) {
    final startUs = start.inMicroseconds.toDouble();
    final durationUs = duration.inMicroseconds.toDouble();
    if (elapsedUs <= startUs) return 0.0;
    if (durationUs <= 0 || elapsedUs >= startUs + durationUs) return 1.0;
    final raw = ((elapsedUs - startUs) / durationUs).clamp(0.0, 1.0);
    return curve.transform(raw).clamp(0.0, 1.0);
  }

  /// Opacity (`1 -> 0`) for outgoing screen chrome fading out in `motion.quick`
  /// on `motion.exit` over a route transition of [totalDuration].
  static double outgoingFadeOpacity({
    required double routeValue,
    required NocheMotionData motion,
    required Duration totalDuration,
  }) {
    final clamped = routeValue.clamp(0.0, 1.0);
    if (clamped <= 0.0) return 1.0;
    final totalUs = totalDuration.inMicroseconds.toDouble();
    if (totalUs <= 0) return clamped >= 1.0 ? 0.0 : 1.0;
    final elapsedUs = clamped * totalUs;
    final progress = segmentProgressUs(
      elapsedUs: elapsedUs,
      start: Duration.zero,
      duration: motion.quick,
      curve: motion.exit,
    );
    return (1.0 - progress).clamp(0.0, 1.0);
  }

  /// Opacity (`0 -> 1`) for Speak content returning via Back (`pageOut`): waits
  /// [backFadeAfter] (`Duration.zero` under reduced motion), then fades in over
  /// `motion.quick` on `motion.enter`.
  static double backReturnOpacity({
    required double reverseProgress,
    required NocheMotionData motion,
  }) {
    final clamped = reverseProgress.clamp(0.0, 1.0);
    if (clamped <= 0.0) return 0.0;
    final totalUs = motion.pageOut.inMicroseconds.toDouble();
    if (totalUs <= 0) return 1.0;
    final delay = motion.reduced ? Duration.zero : backFadeAfter;
    final elapsedUs = clamped * totalUs;
    return segmentProgressUs(
      elapsedUs: elapsedUs,
      start: delay,
      duration: motion.quick,
      curve: motion.enter,
    );
  }
}

/// Builds an opaque Noche [PageRoute] with `motion.pageIn` forward duration,
/// `motion.pageOut` reverse duration, and a pass-through transition builder so
/// `HablarTab` fades in `quick` while the Hero call disc becomes `CallScreen`'s
/// [NocheMic].
PageRoute<T> buildNocheCallRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool serviceReduceMotion = false,
  RouteSettings? settings,
}) {
  final motion = SpeakingMotion.resolve(
    context,
    serviceReduceMotion: serviceReduceMotion,
  );
  return PageRouteBuilder<T>(
    settings: settings,
    opaque: true,
    transitionDuration: motion.pageIn,
    reverseTransitionDuration: motion.pageOut,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
  );
}
