import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/reading.dart';

/// Indexes existing recordings. A sentence never substitutes for a tapped word.
class ReadingAudio {
  ReadingAudio(CourseCatalog course) : _language = course.language {
    final catalog = course as Object;
    final review = catalog is RepasoCatalog ? catalog.repaso : null;
    for (final word in review?.words ?? const <RepasoWord>[]) {
      final recording = word.solo;
      if (recording != null && course.clip(recording) != null) {
        final normKey = _norm(word.word);
        if (normKey.isNotEmpty) {
          _words[normKey] = (clip: recording, word: word.word);
        }
        final rawKey = readingKey(word.word);
        if (rawKey.isNotEmpty) {
          _exactWords[rawKey] = (clip: recording, word: word.word);
        }
      }
    }
    for (final pair in course.pairs) {
      final clip = course.clip(pair.say);
      if (clip == null) continue;
      final normWord = _norm(pair.word);
      final normClip = _norm(clip.text);
      final rawWord = readingKey(pair.word);
      final rawClip = readingKey(clip.text);
      if ((normWord.isNotEmpty && normClip == normWord) ||
          (rawWord.isNotEmpty && rawClip == rawWord)) {
        if (normWord.isNotEmpty) {
          _words.putIfAbsent(normWord, () => (clip: pair.say, word: pair.word));
        }
        if (rawWord.isNotEmpty) {
          _exactWords.putIfAbsent(
            rawWord,
            () => (clip: pair.say, word: pair.word),
          );
        }
      }
    }
    for (final sentence in review?.sentences ?? const <RepasoSentence>[]) {
      if (course.clip(sentence.clip) != null) {
        final normKey = _norm(sentence.text);
        if (normKey.isNotEmpty) {
          _lines.putIfAbsent(normKey, () => sentence.clip);
        }
        final rawKey = readingKey(sentence.text);
        if (rawKey.isNotEmpty) {
          _exactLines.putIfAbsent(rawKey, () => sentence.clip);
        }
      }
    }
  }

  final Language _language;
  final _words = <String, ({String clip, String word})>{};
  final _exactWords = <String, ({String clip, String word})>{};
  final _lines = <String, String>{};
  final _exactLines = <String, String>{};

  String _norm(String text) => _language.normalize(text).trim();

  ({String clip, String word})? word(String token) {
    final rawKey = readingKey(token);
    if (rawKey.isNotEmpty) {
      final exact = _exactWords[rawKey];
      if (exact != null) return exact;
    }
    final normKey = _norm(token);
    if (normKey.isEmpty) return null;
    return _words[normKey];
  }

  String? line(String text) {
    final rawKey = readingKey(text);
    if (rawKey.isNotEmpty) {
      final exact = _exactLines[rawKey] ?? _exactWords[rawKey]?.clip;
      if (exact != null) return exact;
    }
    final normKey = _norm(text);
    if (normKey.isEmpty) return null;
    return _lines[normKey] ?? _words[normKey]?.clip;
  }
}
