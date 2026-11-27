import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';
import 'package:material_ui/material_ui.dart';

const String coveragePhraseStretch = LibraryWording.coveragePhraseStretch;
const String coveragePhraseClose = LibraryWording.coveragePhraseClose;
const String coveragePhraseEasy = LibraryWording.coveragePhraseEasy;

/// Returns the Noche encouragement phrase for a coverage percentage.
String coveragePhrase(int percent) {
  if (percent >= 98) return coveragePhraseEasy;
  if (percent >= 90) return coveragePhraseClose;
  return coveragePhraseStretch;
}

/// How many running qualifying words in a book the learner has heard
/// (ear record at stage 1 or above).
class BookCoverage {
  const BookCoverage({required this.heardWords, required this.totalWords});

  final int heardWords;
  final int totalWords;

  double get ratio => totalWords <= 0 ? 0.0 : heardWords / totalWords;

  int get percent => totalWords <= 0 ? 0 : (heardWords * 100) ~/ totalWords;

  String get phrase => coveragePhrase(percent);

  String get headline => LibraryWording.coverageHeadline(percent);

  @override
  bool operator ==(Object other) =>
      other is BookCoverage &&
      other.heardWords == heardWords &&
      other.totalWords == totalWords;

  @override
  int get hashCode => Object.hash(BookCoverage, heardWords, totalWords);

  @override
  String toString() =>
      'BookCoverage(heardWords: $heardWords, totalWords: $totalWords)';
}

final RegExp _unicodeLetterRe = RegExp(r'\p{L}', unicode: true);
final RegExp _latinLetterRe = RegExp(r'\p{Script=Latin}', unicode: true);
final RegExp _arabicLetterRe = RegExp(r'\p{Script=Arabic}', unicode: true);

bool _isTargetScriptWord(String token, String script) {
  final letters = _unicodeLetterRe.allMatches(token).toList();
  if (letters.isEmpty) return false;
  final RegExp scriptRe;
  switch (script) {
    case 'Latn':
      scriptRe = _latinLetterRe;
    case 'Arab':
      scriptRe = _arabicLetterRe;
    default:
      return false;
  }
  for (final match in letters) {
    if (!scriptRe.hasMatch(match[0]!)) return false;
  }
  return true;
}

/// Computes how much of [book] the learner has heard based on [records]
/// and [language] tokenization/normalization rules.
BookCoverage coverage(
  ReaderDocument book,
  Iterable<WordRecord> records,
  Language language,
) {
  // Ensure unsupported scripts throw UnsupportedError even on empty inputs.
  language.normalize('');

  final heardKeys = <String>{};
  for (final record in records) {
    if (record.ear.etapa < 1) continue;
    final key = language.normalize(record.w).trim();
    if (key.isNotEmpty) {
      heardKeys.add(key);
    }
  }

  var heardWords = 0;
  var totalWords = 0;

  for (final chapter in book.chapters) {
    for (final paragraph in chapter.paragraphs) {
      for (final sentence in paragraph.sentences) {
        for (final token in language.tokens(sentence.text)) {
          if (!_isTargetScriptWord(token.text, language.script)) continue;
          final key = language.normalize(token.text).trim();
          if (key.isEmpty) continue;
          totalWords++;
          if (heardKeys.contains(key)) {
            heardWords++;
          }
        }
      }
    }
  }

  return BookCoverage(heardWords: heardWords, totalWords: totalWords);
}

/// Convenience wrapper for computing coverage of a personal [ReadingText].
BookCoverage coverageOfText(
  ReadingText book,
  Iterable<WordRecord> records,
  Language language,
) => coverage(ReaderDocument.fromPersonal(book), records, language);

/// Displays a book's coverage progress bar, percentage headline, and phrase.
class BookCoverageSummary extends StatelessWidget {
  const BookCoverageSummary({super.key, required this.coverage});

  final BookCoverage coverage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        NocheProgressBar(
          value: coverage.ratio,
          color: NocheColors.listening,
          semanticLabel: LibraryWording.coverageSemanticLabel(coverage.percent),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            style: NocheType.bodySmall.copyWith(color: NocheColors.label),
            children: [
              TextSpan(
                text: '${coverage.headline} ',
                style: NocheType.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: NocheColors.text,
                ),
              ),
              TextSpan(text: coverage.phrase),
            ],
          ),
        ),
      ],
    );
  }
}
