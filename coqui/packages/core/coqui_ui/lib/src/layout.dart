/// Where the old CSS changes with the screen: the media queries of app.html and
/// cual.html, and the safe area (`env(safe-area-inset-*)`).
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

abstract final class CoquiLayout {
  /// `@media (orientation:landscape) and (max-height:500px)`: a phone on its
  /// side, in app.html (lower tab bar, smaller Mapa disc). app.html:49, 136
  static bool compact(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return s.width > s.height && s.height <= 500;
  }

  /// `@media (orientation:landscape) and (max-height:600px)`: a lesson on its
  /// side (the picture at the left, everything else in a column). cual.html:97
  static bool lessonLandscape(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return s.width > s.height && s.height <= 600;
  }

  /// `--navh`: 72, or 56 on its side. app.html:11, 50
  static double navHeight(BuildContext context) => compact(context)
      ? CoquiMetrics.navHeightLandscape
      : CoquiMetrics.navHeight;

  /// `--rise`: 14, or 18 on its side. app.html:11, 50
  static double rise(BuildContext context) =>
      compact(context) ? CoquiMetrics.riseLandscape : CoquiMetrics.rise;

  /// `env(safe-area-inset-bottom)`.
  static double safeBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// `env(safe-area-inset-top)`.
  static double safeTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  /// The tab bar's height with the safe area under it, without the Mapa disc's rise.
  static double tabBarHeight(BuildContext context) =>
      navHeight(context) + safeBottom(context);

  /// Where a tab's content stops: `.tab` padding at the foot,
  /// `calc(var(--navh) + env(safe-area-inset-bottom) + 68px)`, so the raised
  /// Mapa disc never covers content. app.html:15
  static double tabPageFoot(BuildContext context) =>
      tabBarHeight(context) + CoquiMetrics.tabPageFootExtra;
}
