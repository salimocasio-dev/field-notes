/// Motion timing helpers and Noche route builder for `feature_map` (N8.4).
///
/// This is the only file under `feature_map/lib/` permitted to call
/// [NocheMotion.ms]. All other durations, curves, and distances come directly
/// from [NocheMotion] / [NocheMotionData].
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Feature-local motion constants and curve/opacity math for the map and place
/// transitions (`docs/proyecto/24-noche-motion.md`, N8.4).
abstract final class MapMotion {
  /// Delay before the place screen's back button and counter pill fade in.
  static final Duration placeChromeAfter = NocheMotion.ms(200);

  /// Delay before returning rows fade in on back navigation (`pageOut`).
  static final Duration backFadeAfter = NocheMotion.ms(40);

  /// Wait after tapping an open place before the coquí starts hopping or fading.
  static final Duration tripStartDelay = NocheMotion.ms(90);

  /// Pause after the coquí lands before switching pills and bottom card.
  static final Duration tripSettleDelay = NocheMotion.ms(250);

  /// Delay before `"You are here"` rises into place over the destination stop.
  static const Duration hereRiseAfter = NocheMotion.rowsAfter;

  /// Starting scale of the destination place-name pill as it enters (`0.92 -> 1.0`).
  static const double destEnterScale = 0.92;

  /// Vertical rise/drop distance for the progress-closed lock pill (`4 px`).
  static const double lockDropOffset = 4.0;

  /// Cold-load arrival stagger waits (`Noche-Motion-Carga.dc.html`).
  static final Duration loadChipsAfter = NocheMotion.ms(180);
  static final Duration loadHereAfter = NocheMotion.ms(210);
  static final Duration loadCardAfter = NocheMotion.ms(240);
  static final Duration loadPlayAfter = NocheMotion.ms(400);

  /// Shared [NocheWindow] tag connecting a story picture across map, place,
  /// and lesson screens.
  static String storyWindowTag(String storyId) => storyId;

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

  /// Opacity (`1 -> 0`) for outgoing screen chrome and rows fading out in
  /// `motion.quick` on `motion.exit` over a route transition of [totalDuration].
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

  /// Opacity (`0 -> 1`) for content returning via Back (`pageOut`): waits
  /// [backFadeAfter] (`Duration.zero` under reduced motion), then fades in over
  /// `motion.quick` on `motion.enter` with zero vertical rise.
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
/// screens own their own fade and [NocheWindow] travel choreography.
PageRoute<T> buildNocheMapRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool serviceReduceMotion = false,
  RouteSettings? settings,
}) {
  final motion = MapMotion.resolve(
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
