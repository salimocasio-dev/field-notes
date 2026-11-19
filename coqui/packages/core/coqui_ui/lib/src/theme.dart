/// A Material theme for the shell's `MaterialApp`: the light screens' colours.
///
/// The widgets of this package draw themselves from [CoquiColors] and
/// [CoquiText] and do not read the theme; this exists so that anything built from
/// Material widgets (a text field in "Add a word or a goal", a scroll bar, the
/// page background behind everything) starts from the old look. There is one
/// theme because the old app has one light look (app.html) and one dark lesson
/// frame (cual.html), which [LessonFrame] draws itself.
library;

import 'package:coqui_ui/src/text_styles.dart';
import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A [TextTheme] with every style carrying [coquiNoLigatures]. A `Text` that sets no style of its
/// own draws with the theme's `bodyMedium` (through the `DefaultTextStyle` of a `Material`), so the
/// default text style, and every Material widget's, has no "fi" ligature either.
TextTheme _plainLetters(TextTheme t) {
  TextStyle? plain(TextStyle? s) => s?.copyWith(fontFeatures: coquiNoLigatures);
  return t.copyWith(
    displayLarge: plain(t.displayLarge),
    displayMedium: plain(t.displayMedium),
    displaySmall: plain(t.displaySmall),
    headlineLarge: plain(t.headlineLarge),
    headlineMedium: plain(t.headlineMedium),
    headlineSmall: plain(t.headlineSmall),
    titleLarge: plain(t.titleLarge),
    titleMedium: plain(t.titleMedium),
    titleSmall: plain(t.titleSmall),
    bodyLarge: plain(t.bodyLarge),
    bodyMedium: plain(t.bodyMedium),
    bodySmall: plain(t.bodySmall),
    labelLarge: plain(t.labelLarge),
    labelMedium: plain(t.labelMedium),
    labelSmall: plain(t.labelSmall),
  );
}

/// The theme: `--bg` behind the page, `--ink` text, `--ok` as the primary colour,
/// `--info` as the secondary, `--bad` for errors. No ripples: the old buttons
/// show a pressed state, not a ripple (app.html:30). Roboto, with ligatures off
/// ([coquiNoLigatures]), in every style of the text theme.
ThemeData coquiTheme() {
  final base = _theme();
  return base.copyWith(
    textTheme: _plainLetters(base.textTheme),
    primaryTextTheme: _plainLetters(base.primaryTextTheme),
  );
}

ThemeData _theme() => ThemeData(
  useMaterial3: true,
  fontFamily: coquiFontFamily,
  package: coquiFontPackage,
  brightness: Brightness.light,
  scaffoldBackgroundColor: CoquiColors.bg,
  canvasColor: CoquiColors.bg,
  splashFactory: NoSplash.splashFactory,
  highlightColor: const Color(0x00000000),
  colorScheme: const ColorScheme.light(
    primary: CoquiColors.ok,
    onPrimary: CoquiColors.white,
    secondary: CoquiColors.info,
    onSecondary: CoquiColors.white,
    error: CoquiColors.bad,
    surface: CoquiColors.card,
    onSurface: CoquiColors.ink,
    outline: CoquiColors.line2,
    outlineVariant: CoquiColors.line,
  ),
);
