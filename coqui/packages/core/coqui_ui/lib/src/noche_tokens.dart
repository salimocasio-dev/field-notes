/// Noche tokens: colours, font families, text styles and sizes.
library;

import 'package:coqui_ui/src/text_styles.dart';
import 'package:material_ui/material_ui.dart';

/// Book cover palette pair: spine, face and mark colours.
class NocheCoverColors {
  const NocheCoverColors({
    required this.spine,
    required this.face,
    required this.mark,
  });

  final Color spine;
  final Color face;
  final Color mark;
}

/// Noche colour tokens.
abstract final class NocheColors {
  static const ground = Color(0xFF0C1926);
  static const panel = Color(0xFF152A3D);
  static const chip = Color(0xFF213D57);
  static const line = Color(0xFF33506B);
  static const bar = Color(0xFF4A6C8C);
  static const text = Color(0xFFEEF3F7);
  static const label = Color(0xFFA7B8C8);
  static const dimLine = Color(0xFF8FA2B5);

  static const lessonGround = Color(0xFF12171D);
  static const lessonLine = Color(0xFF37424D);
  static const lessonBorder = Color(0xFF4A5663);
  static const lessonLabel = Color(0xFF8C99A6);
  static const lessonPanel = Color(0xFF1B232C);
  static const litSentence = Color(0xFF24313F);

  static const onAccent = Color(0xFF14110F);
  static const next = Color(0xFFE69F00);
  static const listening = Color(0xFF56B4E9);
  static const listeningSoft = Color(0xFF1D3A52);
  static const other = Color(0xFFCC79A7);
  static const otherSoft = Color(0xFF3A2433);
  static const right = Color(0xFF009E73);
  static const micResting = Color(0xFF28323C);
  static const scrim = Color(0xB80C1926);

  static const sepiaPage = Color(0xFFF2E8D5);
  static const sepiaText = Color(0xFF2E2519);
  static const sepiaLabel = Color(0xFF6B5B45);
  static const sepiaRule = Color(0xFFB9A682);
  static const dayPage = Color(0xFFFAF8F3);
  static const dayText = Color(0xFF1B1B1B);
  static const nightText = Color(0xFFD8DEE4);
  static const dayLabel = Color(0xFF5C5C5C);
  static const dayRule = Color(0xFFC9C4B8);
  static const dayLit = Color(0xFFE9E4D8);
  static const sepiaLit = Color(0xFFE4D6BA);

  static const coverPlum = NocheCoverColors(
    spine: Color(0xFF6B4059),
    face: Color(0xFF3A2433),
    mark: Color(0xFFCC79A7),
  );
  static const coverBlue = NocheCoverColors(
    spine: Color(0xFF4A6C8C),
    face: Color(0xFF213D57),
    mark: Color(0xFFE69F00),
  );
}

const String nocheFontAtkinson = 'Atkinson Hyperlegible Next';
const String nocheFontBricolage = 'Bricolage Grotesque';
const String nocheFontBricolageDisplay = 'Bricolage Grotesque Display';
const String nocheFontLiterata = 'Literata';
const String nocheFontLiterataItalic = 'Literata Italic';
const String nocheFontLexend = 'Lexend';
const String nocheFontNotoSansArabic = 'Noto Sans Arabic';

const Map<String, Map<int, String>> nocheFontFiles = {
  nocheFontAtkinson: {
    400: 'fonts/AtkinsonHyperlegibleNext-400.ttf',
    500: 'fonts/AtkinsonHyperlegibleNext-500.ttf',
    600: 'fonts/AtkinsonHyperlegibleNext-600.ttf',
    700: 'fonts/AtkinsonHyperlegibleNext-700.ttf',
    800: 'fonts/AtkinsonHyperlegibleNext-800.ttf',
  },
  nocheFontBricolage: {
    700: 'fonts/BricolageGrotesque-700.ttf',
    800: 'fonts/BricolageGrotesque-800.ttf',
  },
  nocheFontBricolageDisplay: {800: 'fonts/BricolageGrotesqueDisplay-800.ttf'},
  nocheFontLiterata: {
    400: 'fonts/Literata-400.ttf',
    500: 'fonts/Literata-500.ttf',
    600: 'fonts/Literata-600.ttf',
  },
  nocheFontLiterataItalic: {400: 'fonts/LiterataItalic-400.ttf'},
  nocheFontLexend: {400: 'fonts/Lexend-400.ttf', 500: 'fonts/Lexend-500.ttf'},
  nocheFontNotoSansArabic: {
    500: 'fonts/NotoSansArabic-500.ttf',
    700: 'fonts/NotoSansArabic-700.ttf',
  },
};

TextStyle _nocheStyle(
  String family,
  FontWeight weight,
  double size,
  double line, {
  double letterSpacing = 0,
}) => TextStyle(
  inherit: false,
  fontFamily: family,
  package: coquiFontPackage,
  fontSize: size,
  fontWeight: weight,
  height: line / size,
  leadingDistribution: TextLeadingDistribution.even,
  letterSpacing: letterSpacing,
  decoration: TextDecoration.none,
  fontFeatures: coquiNoLigatures,
);

/// Noche text styles and script-aware font fallback.
///
/// A style sets family, weight, size, line height and tracking, never a colour: the story's
/// table gives none, and each piece names its text colour beside the style. Use `copyWith(color:)`.
abstract final class NocheType {
  static final pageTitle = _nocheStyle(
    nocheFontBricolage,
    FontWeight.w700,
    24,
    24,
  );

  static final sheetTitle = _nocheStyle(
    nocheFontBricolage,
    FontWeight.w700,
    20,
    24,
  );

  static final bigNumber = _nocheStyle(
    nocheFontBricolageDisplay,
    FontWeight.w800,
    64,
    64,
  );

  static final statNumber = _nocheStyle(
    nocheFontBricolageDisplay,
    FontWeight.w800,
    56,
    48,
  );

  static final label = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w600,
    12,
    12,
    letterSpacing: 0.72,
  );

  static final labelStrong = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    12,
    12,
    letterSpacing: 0.72,
  );

  static final tabLabel = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w600,
    12,
    12,
  );

  static final tabLabelOn = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    12,
    12,
  );

  static final button = _nocheStyle(nocheFontAtkinson, FontWeight.w600, 14, 14);

  static final buttonStrong = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    14,
    14,
  );

  static final primary = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    18,
    18,
  );

  static final primarySmall = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    17,
    17,
  );

  static final body = _nocheStyle(nocheFontAtkinson, FontWeight.w500, 14, 20);

  static final bodySmall = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w500,
    13,
    16,
  );

  static final bodyLarge = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w500,
    16,
    24,
  );

  static final row = _nocheStyle(nocheFontAtkinson, FontWeight.w600, 18, 24);

  static final cardTitle = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    22,
    24,
  );

  static final rowTitle = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    16,
    20,
  );

  static final placeTitle = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w800,
    32,
    40,
  );

  static final lessonLine = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w600,
    28,
    36,
  );

  static final lessonPrompt = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w500,
    18,
    24,
  );

  static final transcript = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w500,
    17,
    24,
  );

  static final transcriptNow = _nocheStyle(
    nocheFontAtkinson,
    FontWeight.w700,
    24,
    32,
  );

  static final bookTitle = _nocheStyle(
    nocheFontLiterata,
    FontWeight.w600,
    26,
    32,
  );

  static final bookBody = _nocheStyle(
    nocheFontLiterata,
    FontWeight.w400,
    19,
    31,
  );

  static final dropCap = _nocheStyle(
    nocheFontLiterata,
    FontWeight.w600,
    60,
    52,
  );

  static final cover = _nocheStyle(nocheFontLiterata, FontWeight.w600, 13, 16);

  static final coverSmall = _nocheStyle(
    nocheFontLiterata,
    FontWeight.w600,
    10,
    12,
  );

  static Map<String, TextStyle> get all => {
    'pageTitle': pageTitle,
    'sheetTitle': sheetTitle,
    'bigNumber': bigNumber,
    'statNumber': statNumber,
    'label': label,
    'labelStrong': labelStrong,
    'tabLabel': tabLabel,
    'tabLabelOn': tabLabelOn,
    'button': button,
    'buttonStrong': buttonStrong,
    'primary': primary,
    'primarySmall': primarySmall,
    'body': body,
    'bodySmall': bodySmall,
    'bodyLarge': bodyLarge,
    'row': row,
    'cardTitle': cardTitle,
    'rowTitle': rowTitle,
    'placeTitle': placeTitle,
    'lessonLine': lessonLine,
    'lessonPrompt': lessonPrompt,
    'transcript': transcript,
    'transcriptNow': transcriptNow,
    'bookTitle': bookTitle,
    'bookBody': bookBody,
    'dropCap': dropCap,
    'cover': cover,
    'coverSmall': coverSmall,
  };

  /// Script codes requested through [forScript] that have no bundled font and
  /// fell back to the platform font.
  static final Set<String> unbundledScripts = <String>{};

  /// Optional callback invoked when [forScript] falls back to the platform
  /// font for an unbundled [script].
  static void Function(String script)? onUnbundledScript;

  /// Adapts [style] for an ISO 15924 [script] code (`'Latn'`, `'Arab'`, etc.).
  static TextStyle forScript(TextStyle style, String script) {
    if (script == 'Latn') {
      return style;
    }
    if (script == 'Arab') {
      final size = (style.fontSize ?? 14) + 2;
      final line = ((size * 1.7) / 4).round() * 4.0;
      final weight = (style.fontWeight?.value ?? 500) >= 600
          ? FontWeight.w700
          : FontWeight.w500;
      return TextStyle(
        inherit: false,
        fontFamily: nocheFontNotoSansArabic,
        package: coquiFontPackage,
        color: style.color,
        fontSize: size,
        fontWeight: weight,
        fontStyle: style.fontStyle,
        height: line / size,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: 0,
        decoration: style.decoration ?? TextDecoration.none,
        fontFeatures: style.fontFeatures,
      );
    }
    unbundledScripts.add(script);
    onUnbundledScript?.call(script);
    return TextStyle(
      inherit: style.inherit,
      color: style.color,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      fontStyle: style.fontStyle,
      height: style.height,
      leadingDistribution: style.leadingDistribution,
      letterSpacing: style.letterSpacing,
      decoration: style.decoration,
      fontFeatures: style.fontFeatures,
    );
  }
}

/// Noche spatial and dimension tokens.
abstract final class NocheSize {
  static const double touch = 48;
  static const double pill = 24;
  static const double pillRadius = 24;
  static const double card = 24;
  static const double cardRadius = 24;
  static const double tile = 16;
  static const double tileRadius = 16;
  static const double chip = 32;
  static const double chipHeight = 32;
  static const double chipRadius = 16;
  static const double tabBar = 64;
  static const double tabBarHeight = 64;
  static const double tabBarRadius = 32;
  static const double tabBarInset = 16;
  static const double primary = 56;
  static const double primaryHeight = 56;
  static const double primaryRadius = 28;
  static const double playBar = 72;
  static const double playBarHeight = 72;
  static const double playBarRadius = 36;
  static const double mic = 96;
  static const double disc = 64;
  static const double aboveTabBar = 104;
  static const double grid = 8;
}
