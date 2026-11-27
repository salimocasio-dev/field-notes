import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/book_coverage.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';

/// File formats accepted by the importer in N5.4.
const List<String> supportedImportFormats = [LibraryWording.formatTxt];

const Set<String> _lockedStoreExtensions = {'azw', 'azw3', 'kfx', 'acsm'};

/// A file chosen by the learner for import.
class PickedImportFile {
  const PickedImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get byteSize => bytes.length;
}

/// Platform-provided file picker seam for importing learner files.
///
/// Pending `coqui/requests/115-feature-library-needs-coqui-platform-file-picker.md`.
abstract interface class ImportFilePicker {
  Future<PickedImportFile?> pick({required List<String> allowedExtensions});
}

/// Progress snapshot for a book or text currently being imported.
class ImportJobState {
  const ImportJobState({
    required this.id,
    required this.fileName,
    required this.byteSize,
    required this.step,
    required this.stepProgress,
    this.pagesDone,
    this.pagesTotal,
  });

  final String id;
  final String fileName;
  final int byteSize;

  /// 1-based step index in `1..3`.
  final int step;

  /// Fractional progress within [step], in `0.0..1.0`.
  final double stepProgress;
  final int? pagesDone;
  final int? pagesTotal;
}

/// A failed import displayed as a calm error card on the import screen.
class ImportErrorItem {
  const ImportErrorItem({
    required this.id,
    required this.fileName,
    required this.reason,
    this.locked = false,
  });

  final String id;
  final String fileName;
  final String reason;
  final bool locked;
}

/// Exception thrown when an import cannot proceed for a user-reportable reason.
class ImportFailure implements Exception {
  const ImportFailure(this.reason, {this.locked = false});

  final String reason;
  final bool locked;
}

/// Plain-text book content parsed and ready to persist.
class ParsedBook {
  const ParsedBook({
    required this.title,
    required this.paragraphs,
    required this.body,
    required this.format,
    required this.byteSize,
    required this.estimatedPages,
  });

  final String title;
  final List<String> paragraphs;
  final String body;
  final String format;
  final int byteSize;
  final int estimatedPages;
}

final RegExp _blankLineSplitRe = RegExp(r'\n[ \t]*\n+');
final RegExp _horizontalSpacesRe = RegExp(r'[ \t]+');
final RegExp _whitespaceSplitRe = RegExp(r'\s+');
final RegExp _pathSeparatorRe = RegExp(r'[/\\]');

/// Splits plain text into paragraphs strictly on blank lines, folding wrapped
/// lines within each paragraph into a single line separated by spaces.
///
/// Never guesses or invents chapter boundaries; heading-like lines stay normal
/// paragraphs.
List<String> parsePlainTextParagraphs(String rawText) {
  var normalized = rawText.startsWith('\uFEFF')
      ? rawText.substring(1)
      : rawText;
  normalized = normalized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  final blocks = normalized.split(_blankLineSplitRe);
  final paragraphs = <String>[];
  for (final block in blocks) {
    final lines = <String>[];
    for (final rawLine in block.split('\n')) {
      final cleaned = rawLine.trim().replaceAll(_horizontalSpacesRe, ' ');
      if (cleaned.isNotEmpty) {
        lines.add(cleaned);
      }
    }
    if (lines.isNotEmpty) {
      paragraphs.add(lines.join(' '));
    }
  }
  return paragraphs;
}

/// Derives a display title from a `.txt` file name.
String deriveBookTitleFromFileName(String fileName) {
  var name = fileName.trim();
  final slash = name.lastIndexOf(_pathSeparatorRe);
  if (slash >= 0 && slash + 1 < name.length) {
    name = name.substring(slash + 1).trim();
  }
  if (name.toLowerCase().endsWith('.txt')) {
    name = name.substring(0, name.length - 4).trim();
  }
  return name.isEmpty ? LibraryWording.untitledBook : name;
}

/// Uses [explicitTitle] when non-empty, or derives a short title (up to 6 words
/// / 48 characters) from the first paragraph.
String deriveBookTitleFromText(String? explicitTitle, List<String> paragraphs) {
  final trimmedExplicit = explicitTitle?.trim() ?? '';
  if (trimmedExplicit.isNotEmpty) return trimmedExplicit;
  if (paragraphs.isEmpty) return LibraryWording.untitledBook;

  final first = paragraphs.first.trim();
  if (first.isEmpty) return LibraryWording.untitledBook;

  final words = first.split(_whitespaceSplitRe);
  final buffer = StringBuffer();
  var count = 0;
  for (final word in words) {
    if (word.isEmpty) continue;
    if (count >= 6) break;
    final candidate = buffer.isEmpty ? word : '$buffer $word';
    if (candidate.length > 48) {
      if (buffer.isEmpty) {
        return String.fromCharCodes(word.runes.take(48)).trim();
      }
      break;
    }
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(word);
    count++;
  }
  final derived = buffer.toString().trim();
  return derived.isEmpty ? LibraryWording.untitledBook : derived;
}

/// Estimates reader page count for [doc] before the reader has paginated it at
/// a specific viewport size.
int estimateBookPages(ReaderDocument doc, Language language) {
  var words = 0;
  var paragraphs = 0;
  for (final chapter in doc.chapters) {
    for (final paragraph in chapter.paragraphs) {
      paragraphs++;
      for (final sentence in paragraph.sentences) {
        words += language.tokens(sentence.text).length;
      }
    }
  }
  final pages = ((words + paragraphs * 12) / 180).ceil();
  return pages < 1 ? 1 : pages;
}

/// Convenience wrapper estimating page count for a personal [ReadingText].
int estimateBookPagesFromText(ReadingText text, Language language) =>
    estimateBookPages(ReaderDocument.fromPersonal(text), language);

String _extensionOf(String fileName) {
  var base = fileName.trim();
  final slash = base.lastIndexOf(_pathSeparatorRe);
  if (slash >= 0 && slash + 1 < base.length) {
    base = base.substring(slash + 1);
  }
  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return '';
  return base.substring(dot + 1).toLowerCase();
}

/// Validates and decodes a plain-text `.txt` file into a [ParsedBook].
ParsedBook decodeTxtFile(PickedImportFile file, Language language) {
  final ext = _extensionOf(file.name);
  if (_lockedStoreExtensions.contains(ext)) {
    throw const ImportFailure(LibraryWording.errorLockedBook, locked: true);
  }
  if (ext != 'txt') {
    throw ImportFailure(
      LibraryWording.errorUnsupportedFormat(supportedImportFormats),
    );
  }
  if (file.bytes.contains(0)) {
    throw const ImportFailure(LibraryWording.errorInvalidText);
  }
  final String decoded;
  try {
    decoded = utf8.decode(file.bytes, allowMalformed: false);
  } on FormatException {
    throw const ImportFailure(LibraryWording.errorInvalidText);
  }

  final paragraphs = parsePlainTextParagraphs(decoded);
  if (paragraphs.isEmpty) {
    throw const ImportFailure(LibraryWording.errorEmptyText);
  }

  final title = deriveBookTitleFromFileName(file.name);
  final body = paragraphs.join('\n\n');
  final estimatedPages = estimateBookPagesFromText(
    ReadingText(
      id: '${personalBookPrefix}preview',
      title: title,
      body: body,
      generated: false,
    ),
    language,
  );
  return ParsedBook(
    title: title,
    paragraphs: paragraphs,
    body: body,
    format: LibraryWording.formatTxt,
    byteSize: file.byteSize,
    estimatedPages: estimatedPages,
  );
}

/// Parses pasted text into a [ParsedBook].
ParsedBook parsePastedBook({
  required String rawText,
  String? title,
  required Language language,
}) {
  final paragraphs = parsePlainTextParagraphs(rawText);
  if (paragraphs.isEmpty) {
    throw const ImportFailure(LibraryWording.errorEmptyText);
  }

  final resolvedTitle = deriveBookTitleFromText(title, paragraphs);
  final body = paragraphs.join('\n\n');
  final byteSize = utf8.encode(rawText).length;
  final estimatedPages = estimateBookPagesFromText(
    ReadingText(
      id: '${personalBookPrefix}preview',
      title: resolvedTitle,
      body: body,
      generated: false,
    ),
    language,
  );
  return ParsedBook(
    title: resolvedTitle,
    paragraphs: paragraphs,
    body: body,
    format: LibraryWording.formatPasted,
    byteSize: byteSize,
    estimatedPages: estimatedPages,
  );
}

/// Runs the three-step import pipeline (open, read pages, check words and save).
class BookImporter {
  BookImporter({
    required this.store,
    required this.progress,
    required this.language,
    required this.clock,
    Future<void> Function()? stepYield,
  }) : _stepYield = stepYield ?? _defaultYield;

  final ReadingStore store;
  final ProgressStore progress;
  final Language language;
  final Clock clock;
  final Future<void> Function() _stepYield;

  static Future<void> _defaultYield() => Future<void>.delayed(Duration.zero);

  Future<({ReadingText book, BookCoverage coverage})> importFile(
    PickedImportFile file, {
    required String jobId,
    void Function(ImportJobState state)? onProgress,
  }) async {
    onProgress?.call(
      ImportJobState(
        id: jobId,
        fileName: file.name,
        byteSize: file.byteSize,
        step: 1,
        stepProgress: 0.45,
      ),
    );
    await _stepYield();

    final parsed = decodeTxtFile(file, language);
    return _finishParsedImport(
      parsed: parsed,
      jobId: jobId,
      displayName: file.name,
      onProgress: onProgress,
    );
  }

  Future<({ReadingText book, BookCoverage coverage})> importPastedText({
    required String rawText,
    String? title,
    required String jobId,
    void Function(ImportJobState state)? onProgress,
  }) async {
    final byteSize = utf8.encode(rawText).length;
    final initialName = (title != null && title.trim().isNotEmpty)
        ? title.trim()
        : LibraryWording.pasteTextTile;
    onProgress?.call(
      ImportJobState(
        id: jobId,
        fileName: initialName,
        byteSize: byteSize,
        step: 1,
        stepProgress: 0.45,
      ),
    );
    await _stepYield();

    final parsed = parsePastedBook(
      rawText: rawText,
      title: title,
      language: language,
    );
    return _finishParsedImport(
      parsed: parsed,
      jobId: jobId,
      displayName: parsed.title,
      onProgress: onProgress,
    );
  }

  Future<({ReadingText book, BookCoverage coverage})> _finishParsedImport({
    required ParsedBook parsed,
    required String jobId,
    required String displayName,
    void Function(ImportJobState state)? onProgress,
  }) async {
    final pagesTotal = parsed.estimatedPages;
    final pagesDone = pagesTotal > 1 ? (pagesTotal / 2).ceil() : null;
    onProgress?.call(
      ImportJobState(
        id: jobId,
        fileName: displayName,
        byteSize: parsed.byteSize,
        step: 2,
        stepProgress: 0.55,
        pagesDone: pagesDone,
        pagesTotal: pagesTotal > 1 ? pagesTotal : null,
      ),
    );
    await _stepYield();

    onProgress?.call(
      ImportJobState(
        id: jobId,
        fileName: displayName,
        byteSize: parsed.byteSize,
        step: 3,
        stepProgress: 0.65,
        pagesDone: pagesTotal > 1 ? pagesTotal : null,
        pagesTotal: pagesTotal > 1 ? pagesTotal : null,
      ),
    );
    await _stepYield();

    final now = clock.nowMs();
    final ReadingText book;
    try {
      book = await store.add(
        now: now,
        title: parsed.title,
        body: parsed.body,
        generated: false,
        format: parsed.format,
        byteSize: parsed.byteSize,
        importedAt: now,
        estimatedPages: parsed.estimatedPages,
      );
    } on ReadingStorageFullException {
      throw const ImportFailure(LibraryWording.errorStorageFull);
    }

    final cov = coverageOfText(book, progress.words, language);
    return (book: book, coverage: cov);
  }
}
