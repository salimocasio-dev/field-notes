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

const String _idpfFontObfuscationAlgorithm =
    'http://www.idpf.org/2008/embedding';
const String _adobeFontObfuscationAlgorithm = 'http://ns.adobe.com/pdf/enc#RC';

const Set<String> _fontExtensions = {'.ttf', '.otf', '.woff', '.woff2'};

const Set<String> _skippedHtmlElements = {
  'head',
  'script',
  'style',
  'noscript',
  'svg',
  'math',
  'rt',
  'rp',
};

const Set<String> _headingElements = {'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

const Set<String> _blockElements = {
  'p',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'li',
  'blockquote',
  'pre',
  'dt',
  'dd',
  'figcaption',
  'tr',
  'td',
  'th',
  'div',
  'section',
  'article',
  'aside',
  'main',
  'header',
  'footer',
  'nav',
  'ul',
  'ol',
  'dl',
  'table',
  'thead',
  'tbody',
  'tfoot',
  'figure',
  'hr',
  'address',
};

const Set<String> _tocNavTokens = {
  'toc',
  'landmarks',
  'page-list',
  'doc-toc',
  'doc-landmarks',
  'doc-pagelist',
};

final RegExp _wsRe = RegExp(r'[\s\u00A0]+');
final RegExp _tokenSplitRe = RegExp(r'\s+');

String _cleanText(String raw) => raw.replaceAll(_wsRe, ' ').trim();

String _normalizeForMatch(String raw) => _cleanText(raw).toLowerCase();

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

String _decodePathSegments(String rawPath) {
  final posix = rawPath.replaceAll(r'\', '/');
  return posix
      .split('/')
      .map((segment) {
        try {
          return Uri.decodeComponent(segment);
        } on ArgumentError {
          return segment;
        }
      })
      .join('/');
}

String _dirOf(String normalizedPath) {
  final slash = normalizedPath.lastIndexOf('/');
  if (slash < 0) return '';
  return normalizedPath.substring(0, slash);
}

({String path, String rawPath, String? fragment}) _resolveHref(
  String baseDir,
  String href, {
  String? currentDocPath,
}) {
  var working = href.trim();
  String? fragment;
  final hashIdx = working.indexOf('#');
  if (hashIdx >= 0) {
    final rawFrag = working.substring(hashIdx + 1).trim();
    if (rawFrag.isNotEmpty) {
      fragment = rawFrag;
    }
    working = working.substring(0, hashIdx);
  }
  final queryIdx = working.indexOf('?');
  if (queryIdx >= 0) {
    working = working.substring(0, queryIdx);
  }
  working = working.trim();

  if (working.isEmpty && currentDocPath != null) {
    final norm = _normalizeZipPath(currentDocPath);
    return (path: norm, rawPath: norm, fragment: fragment);
  }

  final isRootRelative = working.startsWith('/');
  final rawCombined = isRootRelative || baseDir.isEmpty
      ? working
      : '$baseDir/$working';
  final decodedCombined = isRootRelative || baseDir.isEmpty
      ? _decodePathSegments(working)
      : '$baseDir/${_decodePathSegments(working)}';

  return (
    path: _normalizeZipPath(decodedCombined),
    rawPath: _normalizeZipPath(rawCombined),
    fragment: fragment,
  );
}

class _SafeZipArchive {
  _SafeZipArchive._(this._exact, this._lower);

  factory _SafeZipArchive.decode(Uint8List bytes) {
    if (bytes.length < 4) {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
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
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }
    return _SafeZipArchive._(exact, lower);
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
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }

    final Uint8List? data;
    try {
      data = entry.readBytes();
    } on Object {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }
    if (data == null) {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }
    if (data.length > _maxEntryBytes ||
        _totalExtractedBytes + data.length > _maxTotalBytes) {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }

    _totalExtractedBytes += data.length;
    _cache[key] = data;
    return data;
  }

  Uint8List? readBytesAny(List<String> candidates) {
    for (final candidate in candidates) {
      final data = readBytes(candidate);
      if (data != null) return data;
    }
    return null;
  }
}

String _decodeXmlBytes(Uint8List data, {bool strictUtf8 = false}) {
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
    if (strictUtf8) rethrow;
    text = latin1.decode(data);
  }
  if (text.startsWith('\uFEFF')) {
    return text.substring(1);
  }
  return text;
}

bool _isFontOnlyObfuscation(String? algorithm, String? uri) {
  if (algorithm != _idpfFontObfuscationAlgorithm &&
      algorithm != _adobeFontObfuscationAlgorithm) {
    return false;
  }
  if (uri == null || uri.trim().isEmpty) return false;
  final stripped = uri.split('#').first.split('?').first.trim().toLowerCase();
  for (final ext in _fontExtensions) {
    if (stripped.endsWith(ext)) return true;
  }
  return false;
}

void _checkDrm(_SafeZipArchive zip) {
  if (!zip.contains('META-INF/encryption.xml')) return;

  final bytes = zip.readBytes('META-INF/encryption.xml');
  if (bytes == null) return;

  final XmlDocument doc;
  try {
    final text = _decodeXmlBytes(bytes, strictUtf8: true);
    doc = XmlDocument.parse(text);
  } on Object {
    throw const ImportFailure(LibraryWording.errorLockedBook, locked: true);
  }

  for (final encrypted in _descendantsLocal(doc, 'EncryptedData')) {
    final method = _descendantsLocal(encrypted, 'EncryptionMethod').firstOrNull;
    final algorithm = method == null ? null : _attrLocal(method, 'Algorithm');
    final cipherRef = _descendantsLocal(
      encrypted,
      'CipherReference',
    ).firstOrNull;
    final uri = cipherRef == null ? null : _attrLocal(cipherRef, 'URI');
    if (!_isFontOnlyObfuscation(algorithm, uri)) {
      throw const ImportFailure(LibraryWording.errorLockedBook, locked: true);
    }
  }
}

/// An opened and DRM-checked EPUB archive ready for page/chapter extraction.
class OpenedEpub {
  OpenedEpub._(this._zip, {required this.fileName, required this.byteSize});

  final String fileName;
  final int byteSize;
  final _SafeZipArchive _zip;
}

/// Step 1 of EPUB import: opens the ZIP archive and checks `META-INF/encryption.xml`
/// for DRM before parsing book content.
OpenedEpub openEpubArchive(PickedImportFile file) {
  final zip = _SafeZipArchive.decode(file.bytes);
  _checkDrm(zip);
  return OpenedEpub._(zip, fileName: file.name, byteSize: file.byteSize);
}

class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.path,
    required this.rawPath,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String path;
  final String rawPath;
  final String mediaType;
  final Set<String> properties;
}

class _TocEntry {
  const _TocEntry({
    required this.title,
    required this.path,
    required this.rawPath,
    this.fragment,
  });

  final String title;
  final String path;
  final String rawPath;
  final String? fragment;
}

class _ExtractedParagraph {
  const _ExtractedParagraph({
    required this.text,
    required this.isHeading,
    required this.anchors,
  });

  final String text;
  final bool isHeading;
  final Set<String> anchors;
}

String _resolveOpfPath(_SafeZipArchive zip) {
  final containerBytes = zip.readBytes('META-INF/container.xml');
  if (containerBytes == null) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }
  final XmlDocument containerDoc;
  try {
    containerDoc = XmlDocument.parse(_decodeXmlBytes(containerBytes));
  } on Object {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }

  String? fallbackPath;
  for (final rootfile in _descendantsLocal(containerDoc, 'rootfile')) {
    final fullPath = _attrLocal(rootfile, 'full-path')?.trim();
    if (fullPath == null || fullPath.isEmpty) continue;
    final mediaType = _attrLocal(rootfile, 'media-type')?.trim().toLowerCase();
    if (mediaType == 'application/oebps-package+xml') {
      return fullPath;
    }
    fallbackPath ??= fullPath;
  }
  if (fallbackPath == null) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }
  return fallbackPath;
}

({String title, String? author}) _parseMetadata(
  XmlDocument opfDoc,
  String fileName,
) {
  final metadata = _descendantsLocal(opfDoc, 'metadata').firstOrNull;
  if (metadata == null) {
    return (title: deriveBookTitleFromFileName(fileName), author: null);
  }

  final mainTitleIds = <String>{};
  for (final meta in _descendantsLocal(metadata, 'meta')) {
    final prop = _attrLocal(meta, 'property')?.trim().toLowerCase();
    if (prop != 'title-type') continue;
    if (_cleanText(meta.innerText).toLowerCase() != 'main') continue;
    final refines = _attrLocal(meta, 'refines')?.trim();
    if (refines != null && refines.isNotEmpty) {
      mainTitleIds.add(
        refines.startsWith('#') ? refines.substring(1) : refines,
      );
    }
  }

  String? firstTitle;
  String? mainTitle;
  for (final titleEl in _descendantsLocal(metadata, 'title')) {
    final text = _cleanText(titleEl.innerText);
    if (text.isEmpty) continue;
    firstTitle ??= text;
    final id = _attrLocal(titleEl, 'id')?.trim();
    if (id != null && mainTitleIds.contains(id)) {
      mainTitle ??= text;
    }
  }

  final creators = <String>[];
  final seenCreators = <String>{};
  for (final creatorEl in _descendantsLocal(metadata, 'creator')) {
    final text = _cleanText(creatorEl.innerText);
    if (text.isNotEmpty && seenCreators.add(text)) {
      creators.add(text);
    }
  }

  return (
    title: mainTitle ?? firstTitle ?? deriveBookTitleFromFileName(fileName),
    author: creators.isEmpty ? null : creators.join(', '),
  );
}

List<_TocEntry> _parseNavToc(_SafeZipArchive zip, _ManifestItem navItem) {
  final bytes = zip.readBytesAny([navItem.path, navItem.rawPath]);
  if (bytes == null) return const [];
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(
      _decodeXmlBytes(bytes),
      entityMapping: const XmlDefaultEntityMapping.html5(),
    );
  } on Object {
    return const [];
  }

  XmlElement? tocNav;
  XmlElement? firstNav;
  for (final nav in _descendantsLocal(doc, 'nav')) {
    firstNav ??= nav;
    final epubType = _attrLocal(nav, 'type')?.toLowerCase() ?? '';
    final role = _attrLocal(nav, 'role')?.toLowerCase() ?? '';
    final tokens = {
      ...epubType.split(_tokenSplitRe),
      ...role.split(_tokenSplitRe),
    };
    if (tokens.contains('toc') || tokens.contains('doc-toc')) {
      tocNav = nav;
      break;
    }
  }
  final targetNav = tocNav ?? firstNav;
  if (targetNav == null) return const [];

  final navDir = _dirOf(navItem.path);
  final entries = <_TocEntry>[];

  void walkList(XmlElement listEl) {
    for (final li in _childrenLocal(listEl, 'li')) {
      XmlElement? anchor;
      for (final child in li.children.whereType<XmlElement>()) {
        final local = child.name.local.toLowerCase();
        if (local == 'ol' || local == 'ul') break;
        if (local == 'a') {
          anchor = child;
          break;
        }
        final nestedAnchor = child.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local.toLowerCase() == 'a')
            .firstOrNull;
        if (nestedAnchor != null) {
          anchor = nestedAnchor;
          break;
        }
      }

      if (anchor != null) {
        final href = _attrLocal(anchor, 'href')?.trim();
        final titleBuf = StringBuffer();
        _collectInlineText(anchor, titleBuf, <String>{});
        final title = _cleanText(titleBuf.toString());
        if (title.isNotEmpty && href != null && href.isNotEmpty) {
          final resolved = _resolveHref(
            navDir,
            href,
            currentDocPath: navItem.path,
          );
          entries.add(
            _TocEntry(
              title: title,
              path: resolved.path,
              rawPath: resolved.rawPath,
              fragment: resolved.fragment,
            ),
          );
        }
      }

      for (final child in li.children.whereType<XmlElement>()) {
        final local = child.name.local.toLowerCase();
        if (local == 'ol' || local == 'ul') {
          walkList(child);
        }
      }
    }
  }

  for (final child in targetNav.children.whereType<XmlElement>()) {
    final local = child.name.local.toLowerCase();
    if (local == 'ol' || local == 'ul') {
      walkList(child);
    }
  }
  return entries;
}

List<_TocEntry> _parseNcxToc(_SafeZipArchive zip, _ManifestItem ncxItem) {
  final bytes = zip.readBytesAny([ncxItem.path, ncxItem.rawPath]);
  if (bytes == null) return const [];
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(
      _decodeXmlBytes(bytes),
      entityMapping: const XmlDefaultEntityMapping.html5(),
    );
  } on Object {
    return const [];
  }

  final navMap = _descendantsLocal(doc, 'navMap').firstOrNull;
  if (navMap == null) return const [];

  final ncxDir = _dirOf(ncxItem.path);
  final entries = <_TocEntry>[];

  void walkNavPoint(XmlElement navPoint) {
    final label = _childrenLocal(navPoint, 'navLabel').firstOrNull;
    final textEl = label == null
        ? null
        : _childrenLocal(label, 'text').firstOrNull;
    final content = _childrenLocal(navPoint, 'content').firstOrNull;
    final title = textEl == null ? '' : _cleanText(textEl.innerText);
    final src = content == null ? null : _attrLocal(content, 'src')?.trim();
    if (title.isNotEmpty && src != null && src.isNotEmpty) {
      final resolved = _resolveHref(ncxDir, src, currentDocPath: ncxItem.path);
      entries.add(
        _TocEntry(
          title: title,
          path: resolved.path,
          rawPath: resolved.rawPath,
          fragment: resolved.fragment,
        ),
      );
    }
    for (final child in _childrenLocal(navPoint, 'navPoint')) {
      walkNavPoint(child);
    }
  }

  for (final navPoint in _childrenLocal(navMap, 'navPoint')) {
    walkNavPoint(navPoint);
  }
  return entries;
}

bool _isSkippedNav(XmlElement element) {
  if (element.name.local.toLowerCase() != 'nav') return false;
  final epubType = _attrLocal(element, 'type')?.toLowerCase() ?? '';
  final role = _attrLocal(element, 'role')?.toLowerCase() ?? '';
  final tokens = {
    ...epubType.split(_tokenSplitRe),
    ...role.split(_tokenSplitRe),
  };
  return tokens.any(_tocNavTokens.contains);
}

void _recordElementAnchors(XmlElement element, Set<String> anchors) {
  final id = _attrLocal(element, 'id')?.trim();
  if (id != null && id.isNotEmpty) anchors.add(id);
  if (element.name.local.toLowerCase() == 'a') {
    final name = _attrLocal(element, 'name')?.trim();
    if (name != null && name.isNotEmpty) anchors.add(name);
  }
}

void _collectInlineText(
  XmlNode node,
  StringBuffer buffer,
  Set<String> pendingAnchors,
) {
  if (node is XmlText || node is XmlCDATA) {
    buffer.write(node.value);
    return;
  }
  if (node is! XmlElement) return;
  final local = node.name.local.toLowerCase();
  if (_skippedHtmlElements.contains(local) || _isSkippedNav(node)) return;
  _recordElementAnchors(node, pendingAnchors);
  if (local == 'br') {
    buffer.write(' ');
    return;
  }
  for (final child in node.children) {
    _collectInlineText(child, buffer, pendingAnchors);
  }
}

bool _hasBlockChild(XmlElement element) {
  for (final child in element.children) {
    if (child is XmlElement) {
      final local = child.name.local.toLowerCase();
      if (_blockElements.contains(local)) return true;
    }
  }
  return false;
}

List<_ExtractedParagraph> _extractXhtmlParagraphs(XmlDocument doc) {
  final body = _descendantsLocal(doc, 'body').firstOrNull ?? doc.rootElement;
  final paragraphs = <_ExtractedParagraph>[];
  final pendingAnchors = <String>{};

  void emitText(String raw, {required bool isHeading}) {
    final cleaned = _cleanText(raw);
    if (cleaned.isEmpty) return;
    paragraphs.add(
      _ExtractedParagraph(
        text: cleaned,
        isHeading: isHeading,
        anchors: Set<String>.of(pendingAnchors),
      ),
    );
    pendingAnchors.clear();
  }

  void walkContainer(XmlElement container) {
    final inlineBuf = StringBuffer();

    void flushInline() {
      if (inlineBuf.isEmpty) return;
      emitText(inlineBuf.toString(), isHeading: false);
      inlineBuf.clear();
    }

    for (final child in container.children) {
      if (child is XmlText || child is XmlCDATA) {
        inlineBuf.write(child.value);
        continue;
      }
      if (child is! XmlElement) continue;
      final local = child.name.local.toLowerCase();
      if (_skippedHtmlElements.contains(local) || _isSkippedNav(child)) {
        continue;
      }

      if (_blockElements.contains(local)) {
        flushInline();
        _recordElementAnchors(child, pendingAnchors);
        if (_hasBlockChild(child)) {
          walkContainer(child);
        } else {
          final blockBuf = StringBuffer();
          for (final grandChild in child.children) {
            _collectInlineText(grandChild, blockBuf, pendingAnchors);
          }
          emitText(
            blockBuf.toString(),
            isHeading: _headingElements.contains(local),
          );
        }
      } else {
        _collectInlineText(child, inlineBuf, pendingAnchors);
      }
    }
    flushInline();
  }

  _recordElementAnchors(body, pendingAnchors);
  walkContainer(body);
  return paragraphs;
}

/// Step 2 of EPUB import: parses OPF metadata, TOC, and spine XHTML documents
/// from an already opened [OpenedEpub].
ParsedBook parseOpenedEpub(
  OpenedEpub opened,
  Language language, {
  void Function(int done, int total)? onPageProgress,
}) {
  final zip = opened._zip;
  final rawOpfPath = _resolveOpfPath(zip);
  final decodedOpfPath = _normalizeZipPath(_decodePathSegments(rawOpfPath));
  final normalizedRawOpfPath = _normalizeZipPath(rawOpfPath);
  final opfBytes = zip.readBytesAny([decodedOpfPath, normalizedRawOpfPath]);
  if (opfBytes == null) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }
  final opfPath = zip.contains(decodedOpfPath)
      ? decodedOpfPath
      : normalizedRawOpfPath;
  final opfDir = _dirOf(opfPath);

  final XmlDocument opfDoc;
  try {
    opfDoc = XmlDocument.parse(_decodeXmlBytes(opfBytes));
  } on Object {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }

  final meta = _parseMetadata(opfDoc, opened.fileName);

  final manifestEl = _descendantsLocal(opfDoc, 'manifest').firstOrNull;
  if (manifestEl == null) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }
  final manifest = <String, _ManifestItem>{};
  _ManifestItem? navItem;
  _ManifestItem? ncxByMediaType;
  for (final itemEl in _descendantsLocal(manifestEl, 'item')) {
    final id = _attrLocal(itemEl, 'id')?.trim();
    final href = _attrLocal(itemEl, 'href')?.trim();
    if (id == null || id.isEmpty || href == null || href.isEmpty) continue;
    final mediaType = _attrLocal(itemEl, 'media-type')?.trim() ?? '';
    final propsRaw = _attrLocal(itemEl, 'properties')?.trim() ?? '';
    final properties = propsRaw.isEmpty
        ? const <String>{}
        : propsRaw.split(_tokenSplitRe).where((s) => s.isNotEmpty).toSet();
    final resolved = _resolveHref(opfDir, href);
    final item = _ManifestItem(
      id: id,
      path: resolved.path,
      rawPath: resolved.rawPath,
      mediaType: mediaType,
      properties: properties,
    );
    manifest[id] = item;
    if (navItem == null && properties.contains('nav')) {
      navItem = item;
    }
    if (ncxByMediaType == null &&
        mediaType.toLowerCase() == 'application/x-dtbncx+xml') {
      ncxByMediaType = item;
    }
  }

  final spineEl = _descendantsLocal(opfDoc, 'spine').firstOrNull;
  if (spineEl == null) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }
  final spineTocId = _attrLocal(spineEl, 'toc')?.trim();

  final allSpineRefs = <({_ManifestItem item, bool linear})>[];
  for (final itemref in _descendantsLocal(spineEl, 'itemref')) {
    final idref = _attrLocal(itemref, 'idref')?.trim();
    if (idref == null || idref.isEmpty) continue;
    final item = manifest[idref];
    if (item == null) continue;
    final linear = _attrLocal(itemref, 'linear')?.trim().toLowerCase() != 'no';
    allSpineRefs.add((item: item, linear: linear));
  }
  final linearItems = [
    for (final ref in allSpineRefs)
      if (ref.linear) ref.item,
  ];
  final spineItems = linearItems.isNotEmpty
      ? linearItems
      : [for (final ref in allSpineRefs) ref.item];

  if (spineItems.isEmpty) {
    throw const ImportFailure(LibraryWording.errorInvalidEpub);
  }

  var tocEntries = navItem != null
      ? _parseNavToc(zip, navItem)
      : const <_TocEntry>[];
  if (tocEntries.isEmpty) {
    final ncxItem =
        (spineTocId != null ? manifest[spineTocId] : null) ?? ncxByMediaType;
    if (ncxItem != null) {
      tocEntries = _parseNcxToc(zip, ncxItem);
    }
  }

  final allParagraphs = <_ExtractedParagraph>[];
  final firstIndexByPath = <String, int>{};
  final firstIndexByPathLower = <String, int>{};
  final anchorsByPath = <String, Map<String, int>>{};
  final anchorsByPathLower = <String, Map<String, int>>{};

  for (var i = 0; i < spineItems.length; i++) {
    final item = spineItems[i];
    final xhtmlBytes = zip.readBytesAny([item.path, item.rawPath]);
    if (xhtmlBytes == null) {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }
    final XmlDocument xhtmlDoc;
    try {
      xhtmlDoc = XmlDocument.parse(
        _decodeXmlBytes(xhtmlBytes),
        entityMapping: const XmlDefaultEntityMapping.html5(),
      );
    } on Object {
      throw const ImportFailure(LibraryWording.errorInvalidEpub);
    }

    final startIndex = allParagraphs.length;
    final extracted = _extractXhtmlParagraphs(xhtmlDoc);
    final anchorMap = <String, int>{};
    for (var j = 0; j < extracted.length; j++) {
      final globalIndex = startIndex + j;
      for (final anchor in extracted[j].anchors) {
        anchorMap.putIfAbsent(anchor, () => globalIndex);
      }
    }
    allParagraphs.addAll(extracted);

    for (final key in {item.path, item.rawPath}) {
      firstIndexByPath.putIfAbsent(key, () => startIndex);
      firstIndexByPathLower.putIfAbsent(key.toLowerCase(), () => startIndex);
      anchorsByPath.putIfAbsent(key, () => anchorMap);
      anchorsByPathLower.putIfAbsent(key.toLowerCase(), () => anchorMap);
    }

    onPageProgress?.call(i + 1, spineItems.length);
  }

  if (allParagraphs.isEmpty) {
    throw const ImportFailure(LibraryWording.errorEmptyText);
  }

  // Resolve TOC entries to global paragraph start indices.
  final matchedToc = <({String title, int startIndex, int order})>[];
  for (var i = 0; i < tocEntries.length; i++) {
    final entry = tocEntries[i];
    final baseStart =
        firstIndexByPath[entry.path] ??
        firstIndexByPath[entry.rawPath] ??
        firstIndexByPathLower[entry.path.toLowerCase()] ??
        firstIndexByPathLower[entry.rawPath.toLowerCase()];
    if (baseStart == null) continue;

    var startIndex = baseStart;
    final fragment = entry.fragment;
    if (fragment != null && fragment.isNotEmpty) {
      final anchorMap =
          anchorsByPath[entry.path] ??
          anchorsByPath[entry.rawPath] ??
          anchorsByPathLower[entry.path.toLowerCase()] ??
          anchorsByPathLower[entry.rawPath.toLowerCase()];
      if (anchorMap != null) {
        String? decodedFragment;
        try {
          decodedFragment = Uri.decodeComponent(fragment);
        } on ArgumentError {
          decodedFragment = null;
        }
        final anchorIdx =
            anchorMap[fragment] ??
            (decodedFragment != null ? anchorMap[decodedFragment] : null);
        if (anchorIdx != null) {
          startIndex = anchorIdx;
        }
      }
    }
    matchedToc.add((title: entry.title, startIndex: startIndex, order: i));
  }

  matchedToc.sort((a, b) {
    final byStart = a.startIndex.compareTo(b.startIndex);
    return byStart != 0 ? byStart : a.order.compareTo(b.order);
  });

  List<ReadingChapter>? chapters;
  if (matchedToc.isNotEmpty) {
    final built = <ReadingChapter>[];
    final firstStart = matchedToc.first.startIndex;
    if (firstStart > 0) {
      final preamble = [
        for (final p in allParagraphs.sublist(0, firstStart)) p.text,
      ];
      if (preamble.isNotEmpty) {
        built.add(
          ReadingChapter(label: null, title: meta.title, paragraphs: preamble),
        );
      }
    }

    for (var i = 0; i < matchedToc.length; i++) {
      final current = matchedToc[i];
      final endIndex = i + 1 < matchedToc.length
          ? matchedToc[i + 1].startIndex
          : allParagraphs.length;
      if (endIndex <= current.startIndex) continue;

      final slice = allParagraphs.sublist(current.startIndex, endIndex);
      if (slice.isEmpty) continue;

      var dropLeadingHeading = false;
      if (slice.length > 1 &&
          slice.first.isHeading &&
          _normalizeForMatch(slice.first.text) ==
              _normalizeForMatch(current.title)) {
        dropLeadingHeading = true;
      }

      final paraTexts = [
        for (var j = dropLeadingHeading ? 1 : 0; j < slice.length; j++)
          slice[j].text,
      ];
      if (paraTexts.isEmpty) continue;

      built.add(
        ReadingChapter(
          label: null,
          title: current.title,
          paragraphs: paraTexts,
        ),
      );
    }

    if (built.isNotEmpty) {
      chapters = built;
    }
  }

  final flatParagraphs = chapters != null
      ? [for (final c in chapters) ...c.paragraphs]
      : [for (final p in allParagraphs) p.text];

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
    format: LibraryWording.formatEpub,
    byteSize: opened.byteSize,
    estimatedPages: estimatedPages,
  );
}

/// Validates, DRM-checks, and parses an EPUB file into a [ParsedBook].
ParsedBook parseEpubFile(
  PickedImportFile file,
  Language language, {
  void Function(int done, int total)? onPageProgress,
}) {
  final opened = openEpubArchive(file);
  return parseOpenedEpub(opened, language, onPageProgress: onPageProgress);
}
