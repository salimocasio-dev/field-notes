/// Type: the old app's text styles.
///
/// The old CSS sets the system font stack (`system-ui, -apple-system, "Segoe UI",
/// Roboto, ...`, app.html:13; cual.html:9 `--sys`); the app ships Roboto instead, so that every
/// platform draws the same letters, and every style here names it. Every style is complete
/// (`inherit: false`), so it looks the same under any `DefaultTextStyle`.
///
/// CSS gives a line height in px (`font: 600 24px/32px`); Flutter wants a
/// multiplier, so `height` is `lineHeight / fontSize`, and the leading is split
/// above and below the line as CSS does (`TextLeadingDistribution.even`).
///
/// Ligatures are off in every style ([coquiNoLigatures], added by [_s] and by
/// [pixelifyStyle]): Roboto joins "f" and "i" into one glyph with no dot ("fi" reads as "f" and a dotless i), and
/// Pixelify Sans' "fi" reads as "A". An app for learning to read a language draws every letter plain.
///
/// Pixelify Sans: no rule of app.html, cual.html, index.html, nivel.html or
/// habla-prueba.html uses it (they never name a font other than the system
/// stack), so no style here does. [pixelifyStyle] exists for the one place the
/// pages allow it (signs on the map, never learning content).
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// The text font: Roboto, shipped in `fonts/` in the four weights below, the same on web, Android and
/// iOS. The family is declared in this package's pubspec; `package: 'coqui_ui'` lets any app find it.
const String coquiFontFamily = 'Roboto';
const String coquiFontPackage = 'coqui_ui';

/// The Roboto file that draws each CSS weight the tokens use (pubspec.yaml declares the same four):
/// 400 Regular, 500 Medium, 600 SemiBold, 700 Bold, all cut from one source (@fontsource/roboto 5.3.0)
/// so they match each other. No weight is synthesised, and none is drawn with a neighbour's file.
const Map<int, String> coquiFontFiles = {
  400: 'fonts/Roboto-Regular.ttf',
  500: 'fonts/Roboto-Medium.ttf',
  600: 'fonts/Roboto-SemiBold.ttf',
  700: 'fonts/Roboto-Bold.ttf',
};

/// `liga` and `clig` switched off: no "fi", "fl", "ffi" or "ffl" ligature, every letter plain. Every
/// text style of this package, and the default text style of [coquiTheme], carries these.
const List<FontFeature> coquiNoLigatures = [
  FontFeature.disable('liga'),
  FontFeature.disable('clig'),
];

TextStyle _s(
  double size,
  double line,
  FontWeight weight,
  Color color, {
  double letterSpacing = 0,
  List<FontFeature>? features,
}) => TextStyle(
  inherit: false,
  fontFamily: coquiFontFamily,
  package: coquiFontPackage,
  color: color,
  fontSize: size,
  fontWeight: weight,
  height: line / size,
  leadingDistribution: TextLeadingDistribution.even,
  letterSpacing: letterSpacing,
  decoration: TextDecoration.none,
  fontFeatures: [...coquiNoLigatures, ...?features],
);

/// The text styles of the light screens (app.html) and of the lesson screens
/// (cual.html, index.html, habla-prueba.html). Each says its CSS source.
abstract final class CoquiText {
  // ---- the light screens: app.html ----

  /// `html,body` `font:400 16px/1.5` ink. app.html:13
  static final body = _s(16, 24, FontWeight.w400, CoquiColors.ink);

  /// `h1` 24/32 semibold: a screen's title. app.html:17
  static final h1 = _s(24, 32, FontWeight.w600, CoquiColors.ink);

  /// `h2` 18/24 medium: a section. app.html:18
  static final h2 = _s(18, 24, FontWeight.w500, CoquiColors.ink);

  /// `.small` 14 px (line height 1.5 inherited from the body: 21 px). app.html:19
  static final small = _s(14, 21, FontWeight.w400, CoquiColors.ink);

  /// `.mut.small` 14 px secondary. app.html:19
  static final smallMuted = _s(14, 21, FontWeight.w400, CoquiColors.mut);

  /// `.mut` 16 px secondary. app.html:19
  static final bodyMuted = _s(16, 24, FontWeight.w400, CoquiColors.mut);

  /// `.lab` 12 px medium, `letter-spacing:.02em`, uppercase (the widget upcases the text). app.html:19
  static final label = _s(
    12,
    18,
    FontWeight.w500,
    CoquiColors.mut,
    letterSpacing: 0.24,
  );

  /// `.play .lab` the Today card's eyebrow: the same, line height 16. app.html:56
  static final eyebrow = _s(
    12,
    16,
    FontWeight.w500,
    CoquiColors.mut,
    letterSpacing: 0.24,
  );

  /// `.chip` 14/20 semibold. app.html:39
  static final chip = _s(14, 20, FontWeight.w600, CoquiColors.ink);

  /// `.btn` 16 px semibold (line height 1.5). app.html:22
  static final button = _s(16, 24, FontWeight.w600, CoquiColors.white);

  /// `.btn.out` 16 px semibold ink. app.html:22, 24
  static final buttonOutline = _s(16, 24, FontWeight.w600, CoquiColors.ink);

  /// `.btn:disabled` text. app.html:25
  static final buttonDisabled = _s(16, 24, FontWeight.w600, CoquiColors.mut);

  /// `.tb` the tab label: 12/16 medium, secondary. app.html:62
  static final tab = _s(12, 16, FontWeight.w500, CoquiColors.mut);

  /// `.tb.on` the active tab's label. app.html:63
  static final tabOn = _s(12, 16, FontWeight.w500, CoquiColors.info);

  /// `.wc .w` the word on a card: 18/24 semibold. app.html:92
  static final cardWord = _s(18, 24, FontWeight.w600, CoquiColors.ink);

  /// `.wc .npw` a word with no picture, the word large: 24/32 semibold. app.html:90
  static final cardWordLarge = _s(24, 32, FontWeight.w600, CoquiColors.ink);

  /// `.ml` the meter's label: 12/16 medium, secondary. app.html:93
  static final meterLabel = _s(12, 16, FontWeight.w500, CoquiColors.mut);

  /// `.play b` the Today card's title: 18/24 semibold. app.html:57
  static final todayTitle = _s(18, 24, FontWeight.w600, CoquiColors.ink);

  /// `.play .sub` the Today card's line: 14/20 secondary. app.html:58
  static final todaySub = _s(14, 20, FontWeight.w400, CoquiColors.mut);

  /// `.cc .ct`, `b` titles in rows: 18/24 semibold. app.html:131
  static final rowTitle = _s(18, 24, FontWeight.w600, CoquiColors.ink);

  /// `b` inside a row or card: 16 px bold (the browser's `b`, 700). app.html:430, 337
  static final rowBold = _s(16, 24, FontWeight.w700, CoquiColors.ink);

  /// `.okc` "Played" / the read check: green semibold. app.html:29
  static final ok = _s(14, 21, FontWeight.w600, CoquiColors.ok);

  /// `#shead .st` the sheet's title: 24/32 semibold. app.html:79
  static final sheetTitle = _s(24, 32, FontWeight.w600, CoquiColors.ink);

  /// `.seg button` the minutes pills: 16 px semibold. app.html:31
  static final segment = _s(16, 24, FontWeight.w600, CoquiColors.ink);

  /// `.yo` stat number: 24 px semibold. app.html:472 (the inline `font-size:24px;font-weight:600`)
  static final stat = _s(24, 36, FontWeight.w600, CoquiColors.ink);

  // ---- the lesson screens: cual.html, index.html ----

  /// `#cap` the caption under the picture: 18/24 medium white. cual.html:32
  static final lessonCaption = _s(
    18,
    24,
    FontWeight.w500,
    CoquiColors.lessonInk,
  );

  /// `#fin h1` a start or end screen's title: 24/32 semibold white. cual.html:36
  static final lessonH1 = _s(24, 32, FontWeight.w600, CoquiColors.lessonInk);

  /// `#fin p` the line under it: 16/24 `--ink2`. cual.html:37
  static final lessonBody = _s(16, 24, FontWeight.w400, CoquiColors.lessonInk2);

  /// `#fin b` bold inside it: white semibold. cual.html:38
  static final lessonBodyStrong = _s(
    16,
    24,
    FontWeight.w600,
    CoquiColors.lessonInk,
  );

  /// `#fin h2` a group's heading: 18/24 semibold white. cual.html:42
  static final lessonH2 = _s(18, 24, FontWeight.w600, CoquiColors.lessonInk);

  /// `#fin p.sub` the grey line under a heading: 14/20 `--ink2`. cual.html:43
  static final lessonSub = _s(14, 20, FontWeight.w400, CoquiColors.lessonInk2);

  /// `.gw span` a word under its picture: 16/24 white. cual.html:50
  static final lessonWord = _s(16, 24, FontWeight.w400, CoquiColors.lessonInk);

  /// `.pri` the 56 px button: 16/24 semibold white. cual.html:55
  static final lessonButton = _s(
    16,
    24,
    FontWeight.w600,
    CoquiColors.lessonInk,
  );

  /// `.sec` the 48 px outline button: 16/24 medium white. cual.html:58
  static final lessonButtonOutline = _s(
    16,
    24,
    FontWeight.w500,
    CoquiColors.lessonInk,
  );

  /// `.ib.aa` the "Aa" text size button: 18/24 semibold. app.html:107
  static final lessonAa = _s(18, 24, FontWeight.w600, CoquiColors.lessonInk2);

  /// `.lbcnt` the page count "3 / 9": 14/20 medium, tabular figures. app.html:108
  static final lessonCount = _s(
    14,
    20,
    FontWeight.w500,
    CoquiColors.lessonInk2,
    features: const [FontFeature.tabularFigures()],
  );

  /// `.lbfin` "Fin": 24/32 semibold white. app.html:121
  static final lessonFin = _s(24, 32, FontWeight.w600, CoquiColors.lessonInk);

  /// `.lbl` a book line: 20 on 30 (24 on 36 with the text size button). app.html:114
  static final bookLine = _s(20, 30, FontWeight.w400, CoquiColors.lessonInk);
  static final bookLineBig = _s(24, 36, FontWeight.w400, CoquiColors.lessonInk);

  /// `.lbl .who` the speaker label above a line: 12/16 semibold `--ink2`. app.html:115
  static final bookWho = _s(12, 16, FontWeight.w600, CoquiColors.lessonInk2);

  /// `#line` the line to say (speaking test): 24/32 semibold white. habla-prueba.html:24
  static final lessonLine = _s(24, 32, FontWeight.w600, CoquiColors.lessonInk);

  /// `#st` a state label under the mic: 12/16 medium `--ink2`. habla-prueba.html:33
  static final lessonStateLabel = _s(
    12,
    16,
    FontWeight.w500,
    CoquiColors.lessonInk2,
  );

  /// Every style above by name (the font test walks it: each style's weight must have a real font file).
  static Map<String, TextStyle> get all => {
    'body': body,
    'h1': h1,
    'h2': h2,
    'small': small,
    'smallMuted': smallMuted,
    'bodyMuted': bodyMuted,
    'label': label,
    'eyebrow': eyebrow,
    'chip': chip,
    'button': button,
    'buttonOutline': buttonOutline,
    'buttonDisabled': buttonDisabled,
    'tab': tab,
    'tabOn': tabOn,
    'cardWord': cardWord,
    'cardWordLarge': cardWordLarge,
    'meterLabel': meterLabel,
    'todayTitle': todayTitle,
    'todaySub': todaySub,
    'rowTitle': rowTitle,
    'rowBold': rowBold,
    'ok': ok,
    'sheetTitle': sheetTitle,
    'segment': segment,
    'stat': stat,
    'lessonCaption': lessonCaption,
    'lessonH1': lessonH1,
    'lessonBody': lessonBody,
    'lessonBodyStrong': lessonBodyStrong,
    'lessonH2': lessonH2,
    'lessonSub': lessonSub,
    'lessonWord': lessonWord,
    'lessonButton': lessonButton,
    'lessonButtonOutline': lessonButtonOutline,
    'lessonAa': lessonAa,
    'lessonCount': lessonCount,
    'lessonFin': lessonFin,
    'bookLine': bookLine,
    'bookLineBig': bookLineBig,
    'bookWho': bookWho,
    'lessonLine': lessonLine,
    'lessonStateLabel': lessonStateLabel,
  };
}

/// The one way to write Pixelify Sans, with ligatures OFF.
///
/// Pixelify Sans' "fi" ligature reads as "A" (page 13, order 00, "State"), so
/// `liga` and `clig` are disabled ([coquiNoLigatures]). Nobody writes `TextStyle(fontFamily: 'Pixelify Sans')`
/// by hand. Weights are 400 and 700 (the two files in `fonts/`).
TextStyle pixelifyStyle({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = CoquiColors.ink,
  double? height,
  double letterSpacing = 0,
}) => TextStyle(
  inherit: false,
  fontFamily: 'Pixelify Sans',
  package: 'coqui_ui',
  fontSize: fontSize,
  fontWeight: fontWeight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
  leadingDistribution: TextLeadingDistribution.even,
  decoration: TextDecoration.none,
  fontFeatures: coquiNoLigatures,
);
