import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/reading.dart';

/// Indexes existing recordings. A sentence never substitutes for a tapped word.
class ReadingAudio {
  ReadingAudio(CourseCatalog course) {
    final catalog = course as Object;
    final review = catalog is RepasoCatalog ? catalog.repaso : null;
    for (final word in review?.words ?? const <RepasoWord>[]) {
      final recording = word.solo;
      if (recording != null && course.clip(recording) != null) {
        _words[readingKey(word.word)] = (clip: recording, word: word.word);
      }
    }
    for (final pair in course.pairs) {
      final clip = course.clip(pair.say);
      if (clip != null && readingKey(clip.text) == readingKey(pair.word)) {
        _words.putIfAbsent(
          readingKey(pair.word),
          () => (clip: pair.say, word: pair.word),
        );
      }
    }
    for (final sentence in review?.sentences ?? const <RepasoSentence>[]) {
      if (course.clip(sentence.clip) != null) {
        _lines.putIfAbsent(readingKey(sentence.text), () => sentence.clip);
      }
    }
  }

  final _words = <String, ({String clip, String word})>{};
  final _lines = <String, String>{};

  ({String clip, String word})? word(String token) => _words[token];

  String? line(String text) {
    final key = readingKey(text);
    return _lines[key] ?? _words[key]?.clip;
  }
}
