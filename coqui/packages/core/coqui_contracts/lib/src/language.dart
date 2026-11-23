import 'package:collection/collection.dart';
import 'package:coqui_contracts/src/course.dart';
import 'package:coqui_contracts/src/latin_rules.dart';

/// Which way a language's text runs. Screens read it; the word rules do not.
enum LanguageDirection { ltr, rtl }

/// One word of a text: [text] as written, [start] and [end] as UTF-16 offsets `[start, end)`.
/// Two tokens compare equal when text, start and end match.
final class WordToken {
  const WordToken(this.text, this.start, this.end);

  final String text;
  final int start;
  final int end;

  @override
  bool operator ==(Object other) =>
      other is WordToken &&
      other.text == text &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(WordToken, text, start, end);

  @override
  String toString() => 'WordToken($text, $start, $end)';
}

/// The five keys [Language.tabNames] must have, in the tab bar's order.
const List<String> languageTabKeys = ['library', 'words', 'map', 'speak', 'me'];

/// The six keys [Language.micWords] must have (the six states of N1.3).
const List<String> languageMicKeys = [
  'ready',
  'listening',
  'thinking',
  'theySpeak',
  'right',
  'notYet',
];

/// Today's Danny agent (`coqui_platform` `call_session.dart`: `dannyAgentId`, `llamada.js`: `AGENT`).
const String spanishCallAgentId = 'agent_3301m795q3xtfpx8c99zc0s870vm';

const _mapEq = MapEquality<String, String>();

/// A language the app teaches: its names, speech locale, reading direction,
/// script, conversation partner, chrome words ([micWords], [tabNames],
/// [a11yWords]), and word rules ([normalize], [tokens]).
///
/// The word rules dispatch on [script] (ISO 15924): `Latn` uses today's Spanish
/// rules unchanged, `Arab` keeps Arabic letters, and any other script throws
/// [UnsupportedError] naming the script when [normalize] or [tokens] is called.
final class Language {
  /// Throws [ArgumentError] when [tabNames] does not have exactly
  /// [languageTabKeys] with non-empty values, or [micWords] does not have
  /// exactly [languageMicKeys] with non-empty values: a course without them
  /// does not load.
  Language({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.recognitionLocale,
    required this.direction,
    required this.script,
    required this.partnerName,
    required this.callAgentId,
    required Map<String, String> micWords,
    required Map<String, String> tabNames,
    Map<String, String> a11yWords = const {},
  }) : micWords = Map.unmodifiable(
         _exactly('micWords', micWords, languageMicKeys),
       ),
       tabNames = Map.unmodifiable(
         _exactly('tabNames', tabNames, languageTabKeys),
       ),
       a11yWords = Map.unmodifiable(a11yWords);

  /// BCP-47 language tag (e.g. `es`).
  final String code;

  /// The language's name in English (e.g. `Spanish`).
  final String englishName;

  /// The language's name in itself (e.g. `Español`).
  final String nativeName;

  /// The speech recogniser's locale (e.g. `es-US`).
  final String recognitionLocale;

  /// Text direction (`ltr` or `rtl`).
  final LanguageDirection direction;

  /// ISO 15924 script code (e.g. `Latn`, `Arab`).
  final String script;

  /// The conversation partner's name (e.g. `Danny`).
  final String partnerName;

  /// The ElevenLabs call agent id (`CallBrief.agentId` default for this language).
  final String callAgentId;

  /// The six words of the mic, keyed by [languageMicKeys].
  final Map<String, String> micWords;

  /// The five tab names, keyed by [languageTabKeys].
  final Map<String, String> tabNames;

  /// Optional accessibility labels (`NocheA11y` keys). Empty for Spanish today.
  final Map<String, String> a11yWords;

  /// Spanish, today's course. [callAgentId] is today's `dannyAgentId`.
  static final Language spanish = Language(
    code: 'es',
    englishName: 'Spanish',
    nativeName: 'Español',
    recognitionLocale: 'es-US',
    direction: LanguageDirection.ltr,
    script: 'Latn',
    partnerName: 'Danny',
    callAgentId: spanishCallAgentId,
    micWords: const {
      'ready': 'Toca y habla',
      'listening': 'Te escucho',
      'thinking': 'Un momento',
      'theySpeak': 'Escucha',
      'right': '¡Muy bien!',
      'notYet': 'Otra vez',
    },
    tabNames: const {
      'library': 'Biblioteca',
      'words': 'Palabras',
      'map': 'Mapa',
      'speak': 'Hablar',
      'me': 'Yo',
    },
  );

  /// Normalises [s] for word matching (case, marks and punctuation removed,
  /// runs of non-word characters collapsed to one space, wrapped in single
  /// spaces). For `Latn` this is today's `PAL.norm` unchanged.
  ///
  /// Throws [UnsupportedError] naming [script] when [script] has no rules.
  String normalize(String? s) {
    switch (script) {
      case 'Latn':
        return normalizeLatin(s);
      case 'Arab':
        return _normalizeArabic(s);
      default:
        throw _unsupported();
    }
  }

  /// Splits [s] into [WordToken]s as written, with UTF-16 `[start, end)`
  /// offsets. For `Latn` this is today's token regex (`feature_words`
  /// `text_rules.dart`) unchanged.
  ///
  /// Throws [UnsupportedError] naming [script] when [script] has no rules.
  List<WordToken> tokens(String s) {
    final RegExp re;
    switch (script) {
      case 'Latn':
        re = _latinToken;
      case 'Arab':
        re = _arabicToken;
      default:
        throw _unsupported();
    }
    return [for (final m in re.allMatches(s)) WordToken(m[0]!, m.start, m.end)];
  }

  UnsupportedError _unsupported() =>
      UnsupportedError('No word rules for script "$script" ($englishName).');

  @override
  bool operator ==(Object other) =>
      other is Language &&
      other.code == code &&
      other.englishName == englishName &&
      other.nativeName == nativeName &&
      other.recognitionLocale == recognitionLocale &&
      other.direction == direction &&
      other.script == script &&
      other.partnerName == partnerName &&
      other.callAgentId == callAgentId &&
      _mapEq.equals(other.micWords, micWords) &&
      _mapEq.equals(other.tabNames, tabNames) &&
      _mapEq.equals(other.a11yWords, a11yWords);

  @override
  int get hashCode => Object.hash(
    Language,
    code,
    englishName,
    nativeName,
    recognitionLocale,
    direction,
    script,
    partnerName,
    callAgentId,
    _mapEq.hash(micWords),
    _mapEq.hash(tabNames),
    _mapEq.hash(a11yWords),
  );

  @override
  String toString() => 'Language($code)';
}

/// Today's token regex (`feature_words` `text_rules.dart`), moved unchanged.
final RegExp _latinToken = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// Arabic tokens: letters, combining marks (tashkeel) and numbers.
final RegExp _arabicToken = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);

Map<String, String> _exactly(
  String what,
  Map<String, String> given,
  List<String> keys,
) {
  final missing = [
    for (final k in keys)
      if (!given.containsKey(k)) k,
  ];
  final extra = [
    for (final k in given.keys)
      if (!keys.contains(k)) k,
  ];
  final empty = [
    for (final k in keys)
      if (given.containsKey(k) && given[k]!.trim().isEmpty) k,
  ];
  if (missing.isNotEmpty || extra.isNotEmpty || empty.isNotEmpty) {
    throw ArgumentError.value(
      given,
      what,
      'must have non-empty values for exactly ${keys.join(', ')}'
      '${missing.isEmpty ? '' : '; missing: ${missing.join(', ')}'}'
      '${extra.isEmpty ? '' : '; extra: ${extra.join(', ')}'}'
      '${empty.isEmpty ? '' : '; empty: ${empty.join(', ')}'}',
    );
  }
  return given;
}

// NOT CHECKED BY AN ARABIC SPEAKER. First-pass Arabic word normalisation:
// - lower-case (for any embedded Latin);
// - strip Arabic diacritics/tashkeel (U+0610-061A, U+064B-065F, U+0670,
//   U+06D6-06ED) and tatweel (U+0640);
// - fold alef variants (آ أ إ ٱ) to bare alef (ا);
// - collapse runs of non-letter/non-digit characters to one space, trim, and
//   wrap with one space on each side (same format as Latin).
// Ta marbuta (ة) and alef maksura (ى) are NOT folded.
String _normalizeArabic(String? s) {
  final out = StringBuffer();
  for (final rune in (s ?? '').toLowerCase().runes) {
    if ((rune >= 0x0610 && rune <= 0x061a) ||
        (rune >= 0x064b && rune <= 0x065f) ||
        rune == 0x0670 ||
        (rune >= 0x06d6 && rune <= 0x06ed) ||
        rune == 0x0640) {
      continue;
    }
    if (rune == 0x0622 || rune == 0x0623 || rune == 0x0625 || rune == 0x0671) {
      out.writeCharCode(0x0627);
    } else {
      out.writeCharCode(rune);
    }
  }
  return ' ${out.toString().replaceAll(_notArabicWord, ' ').trim()} ';
}

/// Anything other than a letter or digit (Arabic marks are stripped above).
final RegExp _notArabicWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Optional interface for a [CourseCatalog] that names its [Language].
///
/// Kept separate from [CourseCatalog] (same pattern as `RepasoCatalog`): adding
/// an abstract member directly to [CourseCatalog] would break every catalog
/// implemented in other packages. Catalogs that do not implement this default
/// to [Language.spanish] via [CourseLanguage.language].
abstract interface class LanguageCatalog {
  Language get language;
}

/// `course.language`: returns the catalog's own [Language] when it implements
/// [LanguageCatalog], or [Language.spanish] otherwise.
extension CourseLanguage on CourseCatalog {
  Language get language {
    final c = this;
    return c is LanguageCatalog
        ? (c as LanguageCatalog).language
        : Language.spanish;
  }
}
