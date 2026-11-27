/// Noche motion tokens and reduced-motion resolution (epic N8, story N8.1).
library;

import 'package:material_ui/material_ui.dart';

/// Resolved set of Noche motion tokens for a given [BuildContext] (either
/// [NocheMotion.normal] or [NocheMotion.reduced]).
@immutable
class NocheMotionData {
  const NocheMotionData({
    required this.press,
    required this.pressBack,
    required this.quick,
    required this.move,
    required this.pageIn,
    required this.pageOut,
    required this.settle,
    required this.stagger,
    required this.nextDelay,
    required this.hop,
    required this.enter,
    required this.travel,
    required this.exit,
    required this.row,
    required this.tab,
    required this.page,
    required this.pressScale,
    required this.pressScaleDisc,
    required this.pressDim,
    required this.followAfter,
    required this.swapAfter,
    required this.rowsAfter,
    required this.lockHold,
    required this.loops,
    required this.reduced,
  });

  // Durations
  final Duration press;
  final Duration pressBack;
  final Duration quick;
  final Duration move;
  final Duration pageIn;
  final Duration pageOut;
  final Duration settle;
  final Duration stagger;
  final Duration nextDelay;
  final Duration hop;

  // Curves
  final Curve enter;
  final Curve travel;
  final Curve exit;

  // Distances & press
  final double row;
  final double tab;
  final double page;
  final double pressScale;
  final double pressScaleDisc;
  final double pressDim;

  // Waits
  final Duration followAfter;
  final Duration swapAfter;
  final Duration rowsAfter;
  final Duration lockHold;

  // Flags
  final bool loops;
  final bool reduced;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NocheMotionData &&
          runtimeType == other.runtimeType &&
          press == other.press &&
          pressBack == other.pressBack &&
          quick == other.quick &&
          move == other.move &&
          pageIn == other.pageIn &&
          pageOut == other.pageOut &&
          settle == other.settle &&
          stagger == other.stagger &&
          nextDelay == other.nextDelay &&
          hop == other.hop &&
          enter == other.enter &&
          travel == other.travel &&
          exit == other.exit &&
          row == other.row &&
          tab == other.tab &&
          page == other.page &&
          pressScale == other.pressScale &&
          pressScaleDisc == other.pressScaleDisc &&
          pressDim == other.pressDim &&
          followAfter == other.followAfter &&
          swapAfter == other.swapAfter &&
          rowsAfter == other.rowsAfter &&
          lockHold == other.lockHold &&
          loops == other.loops &&
          reduced == other.reduced;

  @override
  int get hashCode => Object.hashAll([
    press,
    pressBack,
    quick,
    move,
    pageIn,
    pageOut,
    settle,
    stagger,
    nextDelay,
    hop,
    enter,
    travel,
    exit,
    row,
    tab,
    page,
    pressScale,
    pressScaleDisc,
    pressDim,
    followAfter,
    swapAfter,
    rowsAfter,
    lockHold,
    loops,
    reduced,
  ]);
}

/// Noche motion tokens (`docs/proyecto/24-noche-motion.md` Part 1.2 & 1.4).
abstract final class NocheMotion {
  // Durations
  static const Duration press = Duration(milliseconds: 90);
  static const Duration pressBack = Duration(milliseconds: 140);
  static const Duration quick = Duration(milliseconds: 140);
  static const Duration move = Duration(milliseconds: 220);
  static const Duration pageIn = Duration(milliseconds: 320);
  static const Duration pageOut = Duration(milliseconds: 200);
  static const Duration settle = Duration(milliseconds: 480);
  static const Duration stagger = Duration(milliseconds: 30);
  static const Duration nextDelay = Duration(milliseconds: 80);
  static const Duration hop = Duration(milliseconds: 200);

  // Curves
  static const Cubic enter = Cubic(0.2, 0, 0, 1);
  static const Cubic travel = Cubic(0.4, 0, 0.2, 1);
  static const Cubic exit = Cubic(0.4, 0, 1, 1);

  // Distances & press
  static const double row = 8;
  static const double tab = 16;
  static const double page = 24;
  static const double pressScale = 0.97;
  static const double pressScaleDisc = 0.94;
  static const double pressDim = 0.10;

  // Waits
  static const Duration followAfter = Duration(milliseconds: 60);
  static const Duration swapAfter = Duration(milliseconds: 100);
  static const Duration rowsAfter = Duration(milliseconds: 120);
  static const Duration lockHold = Duration(milliseconds: 1400);

  // Flag
  static const bool loops = true;

  // Live-loop periods (`Noche-Motion-Cuento.dc.html`)
  static const Duration thinkingCycle = Duration(milliseconds: 900);
  static const Duration levelCycle = Duration(milliseconds: 640);

  /// Helper for feature `lib/src/motion.dart` files to declare screen-local
  /// waits without literal `Duration(` calls outside `coqui_ui`.
  static Duration ms(int milliseconds) {
    assert(milliseconds >= 0);
    return Duration(milliseconds: milliseconds);
  }

  /// Standard motion tokens.
  static const NocheMotionData normal = NocheMotionData(
    press: press,
    pressBack: pressBack,
    quick: quick,
    move: move,
    pageIn: pageIn,
    pageOut: pageOut,
    settle: settle,
    stagger: stagger,
    nextDelay: nextDelay,
    hop: hop,
    enter: enter,
    travel: travel,
    exit: exit,
    row: row,
    tab: tab,
    page: page,
    pressScale: pressScale,
    pressScaleDisc: pressScaleDisc,
    pressDim: pressDim,
    followAfter: followAfter,
    swapAfter: swapAfter,
    rowsAfter: rowsAfter,
    lockHold: lockHold,
    loops: true,
    reduced: false,
  );

  /// Reduced motion tokens (`docs/proyecto/24-noche-motion.md` Part 1.4).
  static const NocheMotionData reduced = NocheMotionData(
    press: quick,
    pressBack: quick,
    quick: quick,
    move: quick,
    pageIn: quick,
    pageOut: quick,
    settle: quick,
    stagger: Duration.zero,
    nextDelay: Duration.zero,
    hop: Duration.zero,
    enter: enter,
    travel: travel,
    exit: exit,
    row: 0,
    tab: 0,
    page: 0,
    pressScale: 1.0,
    pressScaleDisc: 1.0,
    pressDim: pressDim,
    followAfter: followAfter,
    swapAfter: swapAfter,
    rowsAfter: rowsAfter,
    lockHold: lockHold,
    loops: false,
    reduced: true,
  );

  /// Resolves the motion tokens for [context]. Reads
  /// [MediaQuery.disableAnimationsOf] (via `MediaQuery.maybeDisableAnimationsOf`)
  /// and returns [reduced] when true, otherwise [normal].
  static NocheMotionData of(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? reduced
      : normal;
}
