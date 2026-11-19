/// Where the old CSS changes with the screen: the media queries of app.html and
/// cual.html, and the safe area (`env(safe-area-inset-*)`).
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// The width, in logical pixels, that a browser draws a CSS border of [css] px. Chrome takes a border
/// width down to whole CSS pixels (1.5 becomes 1, never below 1) and draws exactly that: it does not round
/// it to whole device pixels. At ratio 2.625 a `1.5px` border is 2.625 device pixels, two solid rows and a
/// row of 62% coverage (measured on the reference pictures: the left edge of the minutes pills of Yo,
/// 069, is `C9C6BB` `C9C6BB` `DAD7CF` over `F6F5F1`; the bottom border of the map's chip bar, 012, is
/// `EDECE8` `E3E1DA` `E3E1DA` over white; the Mapa disc's 4 px ring is about 10.5 device pixels, not 11).
/// At ratio 3 the same border is 3 whole pixels. So the width is the whole CSS pixels, as they are, and
/// the border is painted with anti-aliasing from the box's outer edge inwards, as a browser paints it.
/// Every CSS border (not a `box-shadow` ring, which a browser draws as it is) goes through this.
double cssBorderWidth(double css, double devicePixelRatio) {
  final whole = css.floor() < 1 ? 1 : css.floor();
  final oneDevicePixel = 1 / devicePixelRatio;
  return whole < oneDevicePixel ? oneDevicePixel : whole.toDouble();
}

abstract final class CoquiLayout {
  /// [cssBorderWidth] for this screen's device pixel ratio.
  static double border(BuildContext context, double css) => cssBorderWidth(
    css,
    MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio,
  );

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
