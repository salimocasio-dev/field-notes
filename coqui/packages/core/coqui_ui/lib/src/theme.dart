/// A Material theme for the shell's `MaterialApp`: the light screens' colours.
///
/// The widgets of this package draw themselves from [CoquiColors] and
/// [CoquiText] and do not read the theme; this exists so that anything built from
/// Material widgets (a text field in "Add a word or a goal", a scroll bar, the
/// page background behind everything) starts from the old look. There is one
/// theme because the old app has one light look (app.html) and one dark lesson
/// frame (cual.html), which [LessonFrame] draws itself.
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// The theme: `--bg` behind the page, `--ink` text, `--ok` as the primary colour,
/// `--info` as the secondary, `--bad` for errors. No ripples: the old buttons
/// show a pressed state, not a ripple (app.html:30).
ThemeData coquiTheme() => ThemeData(
  useMaterial3: true,
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
