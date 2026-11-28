import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:feature_library/src/book_importer.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';
import 'package:xml/xml.dart';

const int _maxEntryBytes = 16 * 1024 * 1024;
const int _maxTotalBytes = 50 * 1024 * 1024;

const List<int> _ole2Magic = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];

final RegExp _wsRe = RegExp(r'[\s\u00A0]+');
final RegExp _headingNameRe = RegExp(
  r'^heading\s*[1-6]$',
  caseSensitive: false,
);
final RegExp _headingStyleIdFallbackRe = RegExp(
  r'^(?:heading\s*[1-6]|h[1-6])$',
  caseSensitive: false,
);

const Set<String> _skippedParagraphChildren = {
  'pPr',
  'rPr',
  'del',
  'delText',
  'instrText',
  'footnoteReference',
  'endnoteReference',
  'commentReference',
  'commentRangeStart',
  'commentRangeEnd',
  'bookmarkStart',
  'bookmarkEnd',
  'proofErr',
  'moveFrom',
  'moveFromRangeStart',
  'moveFromRangeEnd',
  'Fallback',
};

const Set<String> _skippedBodyContainers = {
  'sectPr',
  'tblPr',
  'tblGrid',
  'trPr',
  'tcPr',
  'sdtPr',
  'sdtEndPr',
  'del',
  'moveFrom',
  'Fallback',
};

String _cleanText(String raw) => raw.replaceAll(_wsRe, ' ').trim();

bool _startsWithOle2Magic(Uint8List bytes) {
  if (bytes.length < _ole2Magic.length) return false;
  for (var i = 0; i < _ole2Magic.length; i++) {
    if (bytes[i] != _ole2Magic[i]) return false;
  }
  return true;
}

String _normalizeZipPath(String rawPath) {
  final posix = rawPath.replaceAll(r'\', '/').trim();
  final segments = <String>[];
  for (final segment in posix.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
      continue;
    }
    segments.add(segment);
  }
  return segments.join('/');
}

String _dirOf(String normalizedPath) {
  final slash = normalizedPath.lastIndexOf('/');
  if (slash < 0) return '';
  return normalizedPath.substring(0, slash);
}

String _resolveRelTarget(String baseDir, String target) {
  final trimmed = target.trim();
  if (trimmed.startsWith('/')) {
    return _normalizeZipPath(trimmed);
  }
  return _normalizeZipPath(baseDir.isEmpty ? trimmed : '$baseDir/$trimmed');
}

String? _attrLocal(XmlElement element, String localName) {
  for (final attr in element.attributes) {
    if (attr.name.local == localName) {
      return attr.value;
    }
  }
  return null;
}

Iterable<XmlElement> _descendantsLocal(XmlNode node, String localName) => node
    .descendants
    .whereType<XmlElement>()
    .where((e) => e.name.local == localName);

Iterable<XmlElement> _childrenLocal(XmlNode node, String localName) => node
    .children
    .whereType<XmlElement>()
    .where((e) => e.name.local == localName);

String _decodeXmlBytes(Uint8List data) {
  if (data.length >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
    final codeUnits = <int>[];
    for (var i = 2; i + 1 < data.length; i += 2) {
      codeUnits.add(data[i] | (data[i + 1] << 8));
    }
    return String.fromCharCodes(codeUnits);
  }
  if (data.length >= 2 && data[0] == 0xFE && data[1] == 0xFF) {
    final codeUnits = <int>[];
    for (var i = 2; i + 1 < data.length; i += 2) {
      codeUnits.add((data[i] << 8) | data[i + 1]);
    }
    return String.fromCharCodes(codeUnits);
  }
  var text = '';
  try {
    text = utf8.decode(data, allowMalformed: false);
  } on FormatException {
    text = latin1.decode(data);
  }
  if (text.startsWith('\uFEFF')) {
    return text.substring(1);
  }
  return text;
}

class _SafeDocxArchive {
  _SafeDocxArchive._(this._exact, this._lower);

  factory _SafeDocxArchive.decode(Uint8List bytes) {
    if (bytes.length < 4 || _startsWithOle2Magic(bytes)) {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }
    final exact = <String, ArchiveFile>{};
    final lower = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final normalized = _normalizeZipPath(file.name);
      if (normalized.isEmpty) continue;
      exact.putIfAbsent(normalized, () => file);
      lower.putIfAbsent(normalized.toLowerCase(), () => file);
    }
    if (exact.isEmpty) {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }
    return _SafeDocxArchive._(exact, lower);
  }

  final Map<String, ArchiveFile> _exact;
  final Map<String, ArchiveFile> _lower;
  final Map<String, Uint8List> _cache = {};
  int _totalExtractedBytes = 0;

  ArchiveFile? _lookup(String path) {
    final normalized = _normalizeZipPath(path);
    if (normalized.isEmpty) return null;
    return _exact[normalized] ?? _lower[normalized.toLowerCase()];
  }

  bool contains(String path) => _lookup(path) != null;

  Uint8List? readBytes(String path) {
    final entry = _lookup(path);
    if (entry == null) return null;
    final key = _normalizeZipPath(entry.name);
    final cached = _cache[key];
    if (cached != null) return cached;

    if (entry.size > _maxEntryBytes ||
        _totalExtractedBytes + entry.size > _maxTotalBytes) {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }

    final Uint8List? data;
    try {
      data = entry.readBytes();
    } on Object {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }
    if (data == null) {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }
    if (data.length > _maxEntryBytes ||
        _totalExtractedBytes + data.length > _maxTotalBytes) {
      throw const ImportFailure(LibraryWording.errorInvalidDocx);
    }

    _totalExtractedBytes += data.length;
    _cache[key] = data;
    return data;
  }
}

({String documentPath, String corePropsPath}) _resolvePackageRels(
  _SafeDocxArchive zip,
) {
  var documentPath = 'word/document.xml';
  var corePropsPath = 'docProps/core.xml';
  final relsBytes = zip.readBytes('_rels/.rels');
  if (relsBytes == null) {
    return (documentPath: documentPath, corePropsPath: corePropsPath);
  }
  final XmlDocument relsDoc;
  try {
    relsDoc = XmlDocument.parse(_decodeXmlBytes(relsBytes));
  } on Object {
    return (documentPath: documentPath, corePropsPath: corePropsPath);
  }

  for (final rel in _descendantsLocal(relsDoc, 'Relationship')) {
    final type = _attrLocal(rel, 'Type')?.trim() ?? '';
    final target = _attrLocal(rel, 'Target')?.trim() ?? '';
    if (target.isEmpty) continue;
    if (type.endsWith('/officeDocument')) {
      final candidate = _resolveRelTarget('', target);
      if (candidate.isNotEmpty) {
        documentPath = candidate;
      }
    } else if (type.endsWith('/core-properties')) {
      final candidate = _resolveRelTarget('', target);
      if (candidate.isNotEmpty) {
        corePropsPath = candidate;
      }
    }
  }
  return (documentPath: documentPath, corePropsPath: corePropsPath);
}

String _resolveStylesPath(_SafeDocxArchive zip, String documentPath) {
  final docDir = _dirOf(documentPath);
  final docBaseName = documentPath.split('/').last;
  final docRelsPath = docDir.isEmpty
      ? '_rels/$docBaseName.rels'
      : '$docDir/_rels/$docBaseName.rels';
  final relsBytes = zip.readBytes(docRelsPath);
  if (relsBytes != null) {
    try {
      final relsDoc = XmlDocument.parse(_decodeXmlBytes(relsBytes));
      for (final rel in _descendantsLocal(relsDoc, 'Relationship')) {
        final type = _attrLocal(rel, 'Type')?.trim() ?? '';
        final target = _attrLocal(rel, 'Target')?.trim() ?? '';
        if (target.isNotEmpty && type.endsWith('/styles')) {
          final candidate = _resolveRelTarget(docDir, target);
          if (candidate.isNotEmpty) return candidate;
        }
      }
    } on Object {
      // Fall back to default styles.xml location.
    }
  }
  return docDir.isEmpty ? 'styles.xml' : '$docDir/styles.xml';
}

/// An opened and validated `.docx` archive ready for document parsing.
class OpenedDocx {
  OpenedDocx._(
    this._zip, {
    required this.fileName,
    required this.byteSize,
    required this.documentPath,
    required this.corePropsPath,
  });

  final String fileName;
  final int byteSize;
  final String documentPath;
  final String corePropsPath;
  final _SafeDocxArchive _zip;
}

/// Step 1 of `.docx` import: validates ZIP structure, rejects OLE2 / corrupt
/// archives, and checks that the main Word document XML entry exists.
OpenedDocx openDocxArchive(PickedImportFile file) {
  final zip = _SafeDocxArchive.decode(file.bytes);
  final rels = _resolvePackageRels(zip);
  final docPath = zip.contains(rels.documentPath)
      ? rels.documentPath
      : 'word/document.xml';
  if (!zip.contains(docPath)) {
    throw const ImportFailure(LibraryWording.errorInvalidDocx);
  }
  return OpenedDocx._(
    zip,
    fileName: file.name,
    byteSize: file.byteSize,
    documentPath: docPath,
    corePropsPath: rels.corePropsPath,
  );
}

({String title, String? author}) _parseCoreProperties(
  _SafeDocxArchive zip,
  String corePropsPath,
  String fileName,
) {
  final bytes = zip.readBytes(corePropsPath);
  if (bytes == null) {
    return (title: deriveBookTitleFromFileName(fileName), author: null);
  }
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(_decodeXmlBytes(bytes));
  } on Object {
    return (title: deriveBookTitleFromFileName(fileName), author: null);
  }

  String? title;
  for (final el in _descendantsLocal(doc, 'title')) {
    final cleaned = _cleanText(el.innerText);
    if (cleaned.isNotEmpty) {
      title = cleaned;
      break;
    }
  }

  final creators = <String>[];
  final seen = <String>{};
  for (final el in _descendantsLocal(doc, 'creator')) {
    final cleaned = _cleanText(el.innerText);
    if (cleaned.isNotEmpty && seen.add(cleaned)) {
      creators.add(cleaned);
    }
  }

  return (
    title: title ?? deriveBookTitleFromFileName(fileName),
    author: creators.isEmpty ? null : creators.join(', '),
  );
}

class _StyleDef {
  const _StyleDef({
    required this.styleId,
    this.name,
    this.basedOn,
    this.outlineLvl,
  });

  final String styleId;
  final String? name;
  final String? basedOn;
  final int? outlineLvl;
}

Set<String> _parseHeadingStyleIds(_SafeDocxArchive zip, String documentPath) {
  final stylesPath = _resolveStylesPath(zip, documentPath);
  final bytes = zip.readBytes(stylesPath);
  if (bytes == null) return const {};
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(_decodeXmlBytes(bytes));
  } on Object {
    return const {};
  }

  final defs = <String, _StyleDef>{};
  for (final style in _descendantsLocal(doc, 'style')) {
    final type = _attrLocal(style, 'type')?.trim().toLowerCase();
    if (type != null && type.isNotEmpty && type != 'paragraph') continue;
    final styleId = _attrLocal(style, 'styleId')?.trim();
    if (styleId == null || styleId.isEmpty) continue;

    final nameEl = _childrenLocal(style, 'name').firstOrNull;
    final styleName = nameEl == null ? null : _attrLocal(nameEl, 'val')?.trim();

    final basedOnEl = _childrenLocal(style, 'basedOn').firstOrNull;
    final basedOn = basedOnEl == null
        ? null
        : _attrLocal(basedOnEl, 'val')?.trim();

    int? outlineLvl;
    final pPr = _childrenLocal(style, 'pPr').firstOrNull;
    if (pPr != null) {
      final outlineEl = _childrenLocal(pPr, 'outlineLvl').firstOrNull;
      final rawLvl = outlineEl == null
          ? null
          : _attrLocal(outlineEl, 'val')?.trim();
      if (rawLvl != null) {
        outlineLvl = int.tryParse(rawLvl);
      }
    }

    defs[styleId] = _StyleDef(
      styleId: styleId,
      name: styleName,
      basedOn: basedOn,
      outlineLvl: outlineLvl,
    );
  }

  final memo = <String, bool>{};
  bool isHeadingStyle(String styleId, Set<String> visiting) {
    final cached = memo[styleId];
    if (cached != null) return cached;
    if (!visiting.add(styleId)) return false;

    final def = defs[styleId];
    if (def == null) {
      visiting.remove(styleId);
      return false;
    }

    bool result;
    if (def.name != null && _headingNameRe.hasMatch(def.name!)) {
      result = true;
    } else if (def.outlineLvl != null) {
      result = def.outlineLvl! >= 0 && def.outlineLvl! <= 5;
    } else if (def.basedOn != null && def.basedOn!.isNotEmpty) {
      result = isHeadingStyle(def.basedOn!, visiting);
    } else {
      result = false;
    }

    visiting.remove(styleId);
    memo[styleId] = result;
    return result;
  }

  final headingIds = <String>{};
  for (final id in defs.keys) {
    if (isHeadingStyle(id, <String>{})) {
      headingIds.add(id);
    }
  }
  return headingIds;
}

bool _isHeadingParagraph(XmlElement p, Set<String> headingStyleIds) {
  final pPr = _childrenLocal(p, 'pPr').firstOrNull;
  if (pPr == null) return false;

  final outlineEl = _childrenLocal(pPr, 'outlineLvl').firstOrNull;
  if (outlineEl != null) {
    final lvl = int.tryParse(_attrLocal(outlineEl, 'val')?.trim() ?? '');
    if (lvl != null) return lvl >= 0 && lvl <= 5;
  }

  final styleEl = _childrenLocal(pPr, 'pStyle').firstOrNull;
  if (styleEl != null) {
    final styleId = _attrLocal(styleEl, 'val')?.trim();
    if (styleId != null && styleId.isNotEmpty) {
      if (headingStyleIds.contains(styleId)) return true;
      if (_headingStyleIdFallbackRe.hasMatch(styleId)) return true;
    }
  }

  return false;
}

void _extractParagraphInlineText(XmlNode node, StringBuffer buffer) {
  if (node is! XmlElement) return;
  final local = node.name.local;
  if (_skippedParagraphChildren.contains(local)) return;

  switch (local) {
    case 't':
      buffer.write(node.innerText);
      return;
    case 'tab':
    case 'br':
    case 'cr':
      buffer.write(' ');
      return;
    case 'noBreakHyphen':
      buffer.write('-');
      return;
    case 'softHyphen':
      return;
    default:
      for (final child in node.children) {
        _extractParagraphInlineText(child, buffer);
      }
  }
}

class _DocxParagraph {
  const _DocxParagraph({required this.text, required this.isHeading});

  final String text;
  final bool isHeading;
}

List<_DocxParagraph> _extractBodyParagraphs(
  XmlElement body,
  Set<String> headingStyleIds,
) {
  final paragraphs = <_DocxParagraph>[];

  void walk(XmlElement container) {
    for (final child in container.children.whereType<XmlElement>()) {
      final local = child.name.local;
      if (_skippedBodyContainers.contains(local)) continue;
      if (local == 'p') {
        final buf = StringBuffer();
        for (final pChild in child.children) {
          _extractParagraphInlineText(pChild, buf);
        }
        final text = _cleanText(buf.toString());
        if (text.isNotEmpty) {
          paragraphs.add(
            _DocxParagraph(
              text: text,
              isHeading: _isHeadingParagraph(child, headingStyleIds),
            ),
          );
        }
      } else {
        walk(child);
      }
    }
  }

  walk(body);
  return paragraphs;
}

/// Step 2 of `.docx` import: parses document XML, core properties, styles,
/// paragraphs, and heading-based chapters from an [OpenedDocx].
ParsedBook parseOpenedDocx(OpenedDocx opened, Language language) {
  final zip = opened._zip;
  final docBytes = zip.readBytes(opened.documentPath);
  if (docBytes == null) {
    throw const ImportFailure(LibraryWording.errorInvalidDocx);
  }
  final XmlDocument docXml;
  try {
    docXml = XmlDocument.parse(_decodeXmlBytes(docBytes));
  } on Object {
    throw const ImportFailure(LibraryWording.errorInvalidDocx);
  }

  final bodyEl = _descendantsLocal(docXml, 'body').firstOrNull;
  if (bodyEl == null) {
    throw const ImportFailure(LibraryWording.errorInvalidDocx);
  }

  final meta = _parseCoreProperties(zip, opened.corePropsPath, opened.fileName);
  final headingStyleIds = _parseHeadingStyleIds(zip, opened.documentPath);
  final rawParagraphs = _extractBodyParagraphs(bodyEl, headingStyleIds);

  if (rawParagraphs.isEmpty) {
    throw const ImportFailure(LibraryWording.errorEmptyText);
  }

  final preamble = <String>[];
  final headingChapters = <({String title, List<String> paragraphs})>[];
  ({String title, List<String> paragraphs})? current;

  for (final para in rawParagraphs) {
    if (para.isHeading) {
      current = (title: para.text, paragraphs: <String>[]);
      headingChapters.add(current);
    } else if (current == null) {
      preamble.add(para.text);
    } else {
      current.paragraphs.add(para.text);
    }
  }

  final nonEmptyHeadingChapters = [
    for (final chapter in headingChapters)
      if (chapter.paragraphs.isNotEmpty)
        ReadingChapter(
          label: null,
          title: chapter.title,
          paragraphs: chapter.paragraphs,
        ),
  ];

  final List<ReadingChapter>? chapters;
  final List<String> flatParagraphs;

  if (nonEmptyHeadingChapters.isNotEmpty) {
    chapters = [
      if (preamble.isNotEmpty)
        ReadingChapter(label: null, title: meta.title, paragraphs: preamble),
      ...nonEmptyHeadingChapters,
    ];
    flatParagraphs = [for (final c in chapters) ...c.paragraphs];
  } else {
    chapters = null;
    flatParagraphs = [for (final p in rawParagraphs) p.text];
  }

  final body = flatParagraphs.join('\n\n');
  final estimatedPages = estimateBookPagesFromText(
    ReadingText(
      id: '${personalBookPrefix}preview',
      title: meta.title,
      author: meta.author,
      body: body,
      generated: false,
      chapters: chapters,
    ),
    language,
  );

  return ParsedBook(
    title: meta.title,
    author: meta.author,
    paragraphs: flatParagraphs,
    body: body,
    chapters: chapters,
    format: LibraryWording.formatWord,
    byteSize: opened.byteSize,
    estimatedPages: estimatedPages,
  );
}

/// Validates and parses a Word `.docx` file into a [ParsedBook].
ParsedBook parseDocxFile(PickedImportFile file, Language language) {
  final opened = openDocxArchive(file);
  return parseOpenedDocx(opened, language);
}
