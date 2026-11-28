import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_testing/coqui_testing.dart';
import 'package:feature_library/src/book_importer.dart';
import 'package:feature_library/src/docx_parser.dart';
import 'package:feature_library/src/epub_parser.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _zipFromStrings(Map<String, String> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    archive.addFile(ArchiveFile.string(entry.key, entry.value));
  }
  return ZipEncoder().encodeBytes(archive);
}

Uint8List _buildMinimalEpub3({
  String? encryptionXml,
  String opfPath = 'OEBPS/content.opf',
  String titleXml = '''
    <dc:title id="t1">La isla de noche</dc:title>
    <meta refines="#t1" property="title-type">main</meta>
    <dc:title id="t2">Un cuento breve</dc:title>
    <meta refines="#t2" property="title-type">subtitle</meta>
    <dc:creator>Ana Rivera</dc:creator>
    <dc:creator>Luis Ortiz</dc:creator>
  ''',
  Map<String, String>? extraEntries,
  String? navXhtml,
  String? ch1Xhtml,
  String? ch2Xhtml,
  bool includeNonLinear = false,
}) {
  final files = <String, String>{
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml':
        '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="$opfPath" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
    opfPath:
        '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    $titleXml
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    ${includeNonLinear ? '<item id="notes" href="text/notes.xhtml" media-type="application/xhtml+xml"/>' : ''}
  </manifest>
  <spine>
    <itemref idref="nav"/>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
    ${includeNonLinear ? '<itemref idref="notes" linear="no"/>' : ''}
  </spine>
</package>''',
    'OEBPS/nav.xhtml':
        navXhtml ??
        '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head><title>Contenido</title></head>
  <body>
    <nav epub:type="toc">
      <h1>Contenido</h1>
      <ol>
        <li><a href="text/ch1.xhtml">El puerto</a></li>
        <li><a href="text/ch2.xhtml#sec1">La loma</a></li>
        <li><a href="text/ch2.xhtml#sec2">El regreso</a></li>
      </ol>
    </nav>
  </body>
</html>''',
    'OEBPS/text/ch1.xhtml':
        ch1Xhtml ??
        '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>El puerto</title>
    <style>.x { color: black; }</style>
    <script>alert('ignore');</script>
  </head>
  <body>
    <h1>El puerto</h1>
    <p>Casa&nbsp;&mdash; &ldquo;ni&ntilde;o&rdquo; y &aacute;rbol.<br/>Sol de tarde.</p>
    <p>Agua clara <ruby>mar<rt>ignorar</rt></ruby>.</p>
    <svg><text>SVG ignorado</text></svg>
  </body>
</html>''',
    'OEBPS/text/ch2.xhtml':
        ch2Xhtml ??
        '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
    <section id="sec1">
      <h2>La loma</h2>
      <p>Subimos la loma despacio.</p>
    </section>
    <a id="sec2"/>
    <h2>El regreso</h2>
    <p>Volvimos antes de la noche.</p>
  </body>
</html>''',
  };
  if (includeNonLinear) {
    files['OEBPS/text/notes.xhtml'] = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><p>Nota no lineal.</p></body>
</html>''';
  }
  if (encryptionXml != null) {
    files['META-INF/encryption.xml'] = encryptionXml;
  }
  if (extraEntries != null) {
    files.addAll(extraEntries);
  }
  return _zipFromStrings(files);
}

Uint8List _buildDocx({
  required String documentXml,
  String? stylesXml,
  String? coreXml,
  String? relsXml,
  String documentPath = 'word/document.xml',
}) {
  final files = <String, String>{
    '[Content_Types].xml': '''<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"/>''',
    '_rels/.rels':
        relsXml ??
        '''<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="$documentPath"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
</Relationships>''',
    documentPath: documentXml,
  };
  if (stylesXml != null) {
    files['word/styles.xml'] = stylesXml;
  }
  if (coreXml != null) {
    files['docProps/core.xml'] = coreXml;
  }
  return _zipFromStrings(files);
}

class _QuotaDropStore implements KeyValueStore, DeletableKeyValueStore {
  _QuotaDropStore({this.dropPrefix, this.dropKey});

  final String? dropPrefix;
  final String? dropKey;
  final Map<String, String> data = {};
  final List<String> deletedKeys = [];

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    if (dropKey != null && key == dropKey) return;
    if (dropPrefix != null && key.startsWith(dropPrefix!)) return;
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    deletedKeys.add(key);
    data.remove(key);
  }
}

class _NonDeletableFailTextsStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  String? read(String key) => data[key];

  @override
  Future<void> write(String key, String value) async {
    if (key == 'texts') throw StateError('QuotaExceededError');
    data[key] = value;
  }
}

void main() {
  final spanish = Language.spanish;

  group('EPUB 3 parsing', () {
    test('parses nav TOC, fragment splits, metadata title/author, HTML5 entities, heading deduplication, and skips non-content nodes', () {
      final bytes = _buildMinimalEpub3(includeNonLinear: true);
      final progressEvents = <(int, int)>[];

      final parsed = parseEpubFile(
        PickedImportFile(name: 'fallback_name.epub', bytes: bytes),
        spanish,
        onPageProgress: (done, total) => progressEvents.add((done, total)),
      );

      expect(parsed.format, LibraryWording.formatEpub);
      expect(parsed.title, 'La isla de noche');
      expect(parsed.author, 'Ana Rivera, Luis Ortiz');
      expect(parsed.byteSize, bytes.length);
      expect(parsed.estimatedPages, greaterThanOrEqualTo(1));

      // 3 linear spine documents: nav, ch1, ch2 (notes has linear="no").
      expect(progressEvents, [(1, 3), (2, 3), (3, 3)]);

      expect(parsed.chapters, isNotNull);
      expect(parsed.chapters!.length, 3);

      // Chapter 1: leading <h1>El puerto</h1> deduplicated; entities decoded; <br/> -> space; <rt>, <svg>, <style>, <script>, TOC <nav> skipped.
      expect(parsed.chapters![0].label, isNull);
      expect(parsed.chapters![0].title, 'El puerto');
      expect(parsed.chapters![0].paragraphs, [
        'Casa — “niño” y árbol. Sol de tarde.',
        'Agua clara mar.',
      ]);

      // Chapter 2 & 3 split by #sec1 and #sec2 fragments within shared ch2.xhtml.
      expect(parsed.chapters![1].label, isNull);
      expect(parsed.chapters![1].title, 'La loma');
      expect(parsed.chapters![1].paragraphs, ['Subimos la loma despacio.']);

      expect(parsed.chapters![2].label, isNull);
      expect(parsed.chapters![2].title, 'El regreso');
      expect(parsed.chapters![2].paragraphs, ['Volvimos antes de la noche.']);

      expect(parsed.body, contains('Casa — “niño” y árbol. Sol de tarde.'));
      expect(parsed.body, isNot(contains('Nota no lineal')));
      expect(parsed.body, isNot(contains('SVG ignorado')));
      expect(parsed.body, isNot(contains('ignorar')));
    });

    test('keeps leading heading when chapter has no following body paragraphs and drops empty chapters', () {
      final bytes = _buildMinimalEpub3(
        navXhtml: '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <ol>
        <li><a href="text/ch1.xhtml">Solo encabezado</a></li>
        <li><a href="text/ch2.xhtml#empty">Vacío</a></li>
        <li><a href="text/ch2.xhtml#real">Real</a></li>
      </ol>
    </nav>
  </body>
</html>''',
        ch1Xhtml: '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><h1>Solo encabezado</h1></body>
</html>''',
        ch2Xhtml: '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
    <div id="empty"></div>
    <div id="real"><p>Texto real del capítulo.</p></div>
  </body>
</html>''',
      );

      final parsed = parseEpubFile(
        PickedImportFile(name: 'libro.epub', bytes: bytes),
        spanish,
      );

      expect(parsed.chapters, isNotNull);
      expect(parsed.chapters!.map((c) => c.title).toList(), [
        'Solo encabezado',
        'Real',
      ]);
      expect(parsed.chapters![0].paragraphs, ['Solo encabezado']);
      expect(parsed.chapters![1].paragraphs, ['Texto real del capítulo.']);
    });
  });

  group('EPUB 2 (NCX) parsing & path handling', () {
    test('parses EPUB 2 NCX TOC with subdir relative paths, URL-encoded filenames, and nested navPoints', () {
      final bytes = _zipFromStrings({
        'META-INF/container.xml': '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/meta/book.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
        'OPS/meta/book.opf': '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Cuentos del mar</dc:title>
    <dc:creator>Marta Vega</dc:creator>
  </metadata>
  <manifest>
    <item id="ncx" href="../toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="c1" href="../Text/cap%201.xhtml" media-type="application/xhtml+xml"/>
    <item id="c2" href="../Text/cap%202.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>''',
        'OPS/toc.ncx': '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>Primera parte</text></navLabel>
      <content src="Text/cap%201.xhtml"/>
      <navPoint id="np2" playOrder="2">
        <navLabel><text>Segunda parte</text></navLabel>
        <content src="Text/cap%202.xhtml"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''',
        'OPS/Text/cap 1.xhtml': '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><p>Olas suaves en la playa.</p></body>
</html>''',
        'OPS/Text/cap 2.xhtml': '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><p>El barco llega al amanecer.</p></body>
</html>''',
      });

      final parsed = parseEpubFile(
        PickedImportFile(name: 'archivo.epub', bytes: bytes),
        spanish,
      );

      expect(parsed.title, 'Cuentos del mar');
      expect(parsed.author, 'Marta Vega');
      expect(parsed.chapters, isNotNull);
      expect(parsed.chapters!.length, 2);
      expect(parsed.chapters![0].title, 'Primera parte');
      expect(parsed.chapters![0].label, isNull);
      expect(parsed.chapters![0].paragraphs, ['Olas suaves en la playa.']);
      expect(parsed.chapters![1].title, 'Segunda parte');
      expect(parsed.chapters![1].paragraphs, ['El barco llega al amanecer.']);
    });

    test('sets chapters to null and falls back to filename title when TOC and dc:title are absent', () {
      final bytes = _zipFromStrings({
        'META-INF/container.xml': '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
        'content.opf': '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"/>
  <manifest>
    <item id="c1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
  </spine>
</package>''',
        'ch1.xhtml': '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <body><p>Un texto sin índice.</p></body>
</html>''',
      });

      final parsed = parseEpubFile(
        PickedImportFile(name: 'dir/Mi Diario.EPUB', bytes: bytes),
        spanish,
      );

      expect(parsed.title, 'Mi Diario');
      expect(parsed.author, isNull);
      expect(parsed.chapters, isNull);
      expect(parsed.paragraphs, ['Un texto sin índice.']);
    });
  });

  group('EPUB DRM & encryption.xml handling', () {
    test('allows font-only obfuscation (IDPF and Adobe font URIs)', () {
      const fontEncryption = '''<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
            xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/fonts/Literata.otf"/>
    </enc:CipherData>
  </enc:EncryptedData>
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://ns.adobe.com/pdf/enc#RC"/>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/fonts/Body.TTF?v=2#subset"/>
    </enc:CipherData>
  </enc:EncryptedData>
</encryption>''';

      final bytes = _buildMinimalEpub3(encryptionXml: fontEncryption);
      final parsed = parseEpubFile(
        PickedImportFile(name: 'fuentes.epub', bytes: bytes),
        spanish,
      );

      expect(parsed.title, 'La isla de noche');
      expect(parsed.chapters, isNotNull);
    });

    test(
      'rejects DRM-locked EPUB with locked: true and exact locked-book copy',
      () {
        const drmEncryption = '''<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
            xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.w3.org/2001/04/xmlenc#aes128-cbc"/>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/text/ch1.xhtml"/>
    </enc:CipherData>
  </enc:EncryptedData>
</encryption>''';

        final bytes = _buildMinimalEpub3(encryptionXml: drmEncryption);

        expect(
          () => parseEpubFile(
            PickedImportFile(name: 'protegido.epub', bytes: bytes),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>()
                .having((e) => e.locked, 'locked', isTrue)
                .having(
                  (e) => e.reason,
                  'reason',
                  "Locked by the store it came from. Coquí can't open locked books.",
                ),
          ),
        );
      },
    );

    test('rejects IDPF algorithm targeting non-font XHTML and malformed encryption.xml as locked', () {
      const nonFontTarget = '''<?xml version="1.0" encoding="UTF-8"?>
<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
            xmlns:enc="http://www.w3.org/2001/04/xmlenc#">
  <enc:EncryptedData>
    <enc:EncryptionMethod Algorithm="http://www.idpf.org/2008/embedding"/>
    <enc:CipherData>
      <enc:CipherReference URI="OEBPS/text/ch1.xhtml"/>
    </enc:CipherData>
  </enc:EncryptedData>
</encryption>''';

      expect(
        () => parseEpubFile(
          PickedImportFile(
            name: 'truco.epub',
            bytes: _buildMinimalEpub3(encryptionXml: nonFontTarget),
          ),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>()
              .having((e) => e.locked, 'locked', isTrue)
              .having(
                (e) => e.reason,
                'reason',
                LibraryWording.errorLockedBook,
              ),
        ),
      );

      expect(
        () => parseEpubFile(
          PickedImportFile(
            name: 'roto_drm.epub',
            bytes: _buildMinimalEpub3(encryptionXml: '<encryption><broken'),
          ),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>()
              .having((e) => e.locked, 'locked', isTrue)
              .having(
                (e) => e.reason,
                'reason',
                LibraryWording.errorLockedBook,
              ),
        ),
      );
    });
  });

  group('Word (.docx) parsing', () {
    test('parses headings via Heading1/Heading2, localized styles.xml, basedOn inheritance, outlineLvl, preamble, core.xml, tables/SDT, and ignores tracked deletions/field codes', () {
      const coreXml = '''<?xml version="1.0" encoding="UTF-8"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
                   xmlns:dc="http://purl.org/dc/elements/1.1/">
  <dc:title>Cartas de la sierra</dc:title>
  <dc:creator>Elena Cruz</dc:creator>
</cp:coreProperties>''';

      const stylesXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Titulo1">
    <w:name w:val="heading 1"/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="MiCapitulo">
    <w:name w:val="Mi Estilo Capitulo"/>
    <w:basedOn w:val="Titulo1"/>
  </w:style>
</w:styles>''';

      const documentXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r><w:t>Prólogo breve.</w:t></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:pStyle w:val="Titulo1"/></w:pPr>
      <w:r><w:t>Primera carta</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Hola</w:t><w:tab/><w:t>mundo</w:t><w:br/><w:t>bien</w:t><w:noBreakHyphen/><w:t>venido.</w:t></w:r>
      <w:del><w:r><w:delText>Texto borrado.</w:delText></w:r></w:del>
      <w:r><w:instrText> PAGE \\* MERGEFORMAT </w:instrText></w:r>
      <w:r><w:footnoteReference w:id="1"/></w:r>
    </w:p>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading2"/></w:pPr>
      <w:r><w:t>Encabezado vacío</w:t></w:r>
    </w:p>
    <w:sdt>
      <w:sdtContent>
        <w:p>
          <w:pPr><w:pStyle w:val="MiCapitulo"/></w:pPr>
          <w:r><w:t>Segunda carta</w:t></w:r>
        </w:p>
        <w:tbl>
          <w:tr>
            <w:tc>
              <w:p><w:r><w:t>En la tabla.</w:t></w:r></w:p>
            </w:tc>
          </w:tr>
        </w:tbl>
      </w:sdtContent>
    </w:sdt>
    <w:p>
      <w:pPr><w:outlineLvl w:val="1"/></w:pPr>
      <w:r><w:t>Tercera carta</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Últimas líneas.</w:t></w:r>
    </w:p>
  </w:body>
</w:document>''';

      final bytes = _buildDocx(
        documentXml: documentXml,
        stylesXml: stylesXml,
        coreXml: coreXml,
      );

      final parsed = parseDocxFile(
        PickedImportFile(name: 'archivo.docx', bytes: bytes),
        spanish,
      );

      expect(parsed.format, LibraryWording.formatWord);
      expect(parsed.title, 'Cartas de la sierra');
      expect(parsed.author, 'Elena Cruz');
      expect(parsed.chapters, isNotNull);
      expect(parsed.chapters!.length, 4);

      expect(parsed.chapters![0].label, isNull);
      expect(parsed.chapters![0].title, 'Cartas de la sierra');
      expect(parsed.chapters![0].paragraphs, ['Prólogo breve.']);

      expect(parsed.chapters![1].title, 'Primera carta');
      expect(parsed.chapters![1].paragraphs, ['Hola mundo bien-venido.']);

      // 'Encabezado vacío' dropped because it had 0 body paragraphs.
      expect(parsed.chapters![2].title, 'Segunda carta');
      expect(parsed.chapters![2].paragraphs, ['En la tabla.']);

      expect(parsed.chapters![3].title, 'Tercera carta');
      expect(parsed.chapters![3].paragraphs, ['Últimas líneas.']);

      expect(parsed.body, isNot(contains('Texto borrado')));
      expect(parsed.body, isNot(contains('MERGEFORMAT')));
    });

    test('keeps paragraphs flat (chapters == null) when docx has no headings and derives title from filename', () {
      const documentXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>Primer párrafo sin título.</w:t></w:r></w:p>
    <w:p><w:r><w:t>Segundo párrafo.</w:t></w:r></w:p>
  </w:body>
</w:document>''';

      final bytes = _buildDocx(
        documentXml: documentXml,
        documentPath: 'word/custom_main.xml',
      );

      final parsed = parseDocxFile(
        PickedImportFile(name: 'Notas de viaje.DOCX', bytes: bytes),
        spanish,
      );

      expect(parsed.title, 'Notas de viaje');
      expect(parsed.author, isNull);
      expect(parsed.chapters, isNull);
      expect(parsed.paragraphs, [
        'Primer párrafo sin título.',
        'Segundo párrafo.',
      ]);
    });
  });

  group('Malformed archives & edge cases', () {
    test('rejects corrupt ZIP bytes for EPUB and DOCX', () {
      final garbage = Uint8List.fromList(utf8.encode('not a zip archive'));

      expect(
        () => parseEpubFile(
          PickedImportFile(name: 'malo.epub', bytes: garbage),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>()
              .having((e) => e.locked, 'locked', isFalse)
              .having(
                (e) => e.reason,
                'reason',
                LibraryWording.errorInvalidEpub,
              ),
        ),
      );

      expect(
        () => parseDocxFile(
          PickedImportFile(name: 'malo.docx', bytes: garbage),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>()
              .having((e) => e.locked, 'locked', isFalse)
              .having(
                (e) => e.reason,
                'reason',
                LibraryWording.errorInvalidDocx,
              ),
        ),
      );
    });

    test('rejects OLE2 binary .doc renamed to .docx', () {
      final ole2 = Uint8List.fromList([
        0xD0,
        0xCF,
        0x11,
        0xE0,
        0xA1,
        0xB1,
        0x1A,
        0xE1,
        0x00,
        0x00,
      ]);

      expect(
        () => parseDocxFile(
          PickedImportFile(name: 'viejo.docx', bytes: ole2),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>().having(
            (e) => e.reason,
            'reason',
            LibraryWording.errorInvalidDocx,
          ),
        ),
      );
    });

    test(
      'rejects missing container.xml, OPF, document.xml, and malformed XML',
      () {
        final noContainer = _zipFromStrings({'hello.txt': 'world'});
        expect(
          () => parseEpubFile(
            PickedImportFile(name: 'sin_container.epub', bytes: noContainer),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>().having(
              (e) => e.reason,
              'reason',
              LibraryWording.errorInvalidEpub,
            ),
          ),
        );

        final missingOpf = _zipFromStrings({
          'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="missing.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''',
        });
        expect(
          () => parseEpubFile(
            PickedImportFile(name: 'sin_opf.epub', bytes: missingOpf),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>().having(
              (e) => e.reason,
              'reason',
              LibraryWording.errorInvalidEpub,
            ),
          ),
        );

        final badXhtml = _buildMinimalEpub3(
          ch1Xhtml: '<html><body><p>unclosed',
        );
        expect(
          () => parseEpubFile(
            PickedImportFile(name: 'xml_roto.epub', bytes: badXhtml),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>().having(
              (e) => e.reason,
              'reason',
              LibraryWording.errorInvalidEpub,
            ),
          ),
        );

        final missingDocXml = _zipFromStrings({
          '[Content_Types].xml': '<Types/>',
        });
        expect(
          () => parseDocxFile(
            PickedImportFile(name: 'sin_doc.docx', bytes: missingDocXml),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>().having(
              (e) => e.reason,
              'reason',
              LibraryWording.errorInvalidDocx,
            ),
          ),
        );

        final badDocXml = _buildDocx(documentXml: '<w:document><w:body><w:p>');
        expect(
          () => parseDocxFile(
            PickedImportFile(name: 'roto.docx', bytes: badDocXml),
            spanish,
          ),
          throwsA(
            isA<ImportFailure>().having(
              (e) => e.reason,
              'reason',
              LibraryWording.errorInvalidDocx,
            ),
          ),
        );
      },
    );

    test('rejects empty EPUB and empty DOCX with errorEmptyText', () {
      final emptyEpub = _buildMinimalEpub3(
        ch1Xhtml: '<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><body>   </body></html>',
        ch2Xhtml: '<?xml version="1.0"?><html xmlns="http://www.w3.org/1999/xhtml"><body><p>   </p></body></html>',
      );
      expect(
        () => parseEpubFile(
          PickedImportFile(name: 'vacio.epub', bytes: emptyEpub),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>().having(
            (e) => e.reason,
            'reason',
            LibraryWording.errorEmptyText,
          ),
        ),
      );

      final emptyDocx = _buildDocx(
        documentXml: '<?xml version="1.0"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>   </w:t></w:r></w:p></w:body></w:document>',
      );
      expect(
        () => parseDocxFile(
          PickedImportFile(name: 'vacio.docx', bytes: emptyDocx),
          spanish,
        ),
        throwsA(
          isA<ImportFailure>().having(
            (e) => e.reason,
            'reason',
            LibraryWording.errorEmptyText,
          ),
        ),
      );
    });

    test('deriveBookTitleFromFileName strips .txt, .epub, and .docx case-insensitively', () {
      expect(deriveBookTitleFromFileName('Mi libro.epub'), 'Mi libro');
      expect(deriveBookTitleFromFileName('dir/CUENTO.EPUB'), 'CUENTO');
      expect(deriveBookTitleFromFileName('Apuntes.docx'), 'Apuntes');
      expect(deriveBookTitleFromFileName(r'C:\docs\INFORME.DOCX'), 'INFORME');
      expect(
        deriveBookTitleFromFileName(' .epub '),
        LibraryWording.untitledBook,
      );
      expect(
        deriveBookTitleFromFileName(' .docx '),
        LibraryWording.untitledBook,
      );
    });
  });

  group('ReadingStore split chaptersKey + author persistence & rollback', () {
    test('persists chapters under chapters:<id> and author, hydrates across fresh store, and reads legacy inline chapters', () async {
      final kv = FakeKeyValueStore();
      final store = ReadingStore(kv);

      // Legacy inline chapters remain readable.
      await kv.write(
        'texts',
        jsonEncode([
          {
            'id': 'biblioteca-legacy-1',
            'title': 'Viejo con capítulos',
            'author': 'Autor Antiguo',
            'body': 'Uno.\n\nDos.',
            'generated': false,
            'chapters': [
              {
                'title': 'Primero',
                'paragraphs': ['Uno.'],
              },
            ],
          },
        ]),
      );

      final added = await store.add(
        now: 900,
        title: 'Libro dividido',
        author: 'Sofía Méndez',
        body: 'Párrafo A.\n\nPárrafo B.',
        chapters: const [
          ReadingChapter(title: 'Uno', paragraphs: ['Párrafo A.']),
          ReadingChapter(title: 'Dos', paragraphs: ['Párrafo B.']),
        ],
        generated: false,
        format: LibraryWording.formatEpub,
        byteSize: 2048,
        importedAt: 900,
        estimatedPages: 4,
      );

      final chaptersKey = ReadingStore.chaptersKeyFor(added.id);
      expect(kv.read(chaptersKey), isNotNull);
      final rawIndex = jsonDecode(kv.read('texts')!) as List;
      final addedEntry = rawIndex.first as Map;
      expect(addedEntry['chaptersKey'], chaptersKey);
      expect(addedEntry.containsKey('chapters'), isFalse);
      expect(addedEntry['author'], 'Sofía Méndez');

      final fresh = ReadingStore(kv);
      final hydrated = fresh.text(added.id);
      expect(hydrated, isNotNull);
      expect(hydrated!.author, 'Sofía Méndez');
      expect(hydrated.chapters, isNotNull);
      expect(hydrated.chapters!.length, 2);
      expect(hydrated.chapters![0].title, 'Uno');
      expect(hydrated.chapters![1].paragraphs, ['Párrafo B.']);

      final legacy = fresh.text('biblioteca-legacy-1');
      expect(legacy?.author, 'Autor Antiguo');
      expect(legacy?.chapters?.length, 1);
      expect(legacy?.chapters?.first.title, 'Primero');
    });

    test('rolls back BOTH body:<id> and chapters:<id> when chapters write or index write fails', () async {
      // 1. Silent drop on chapters:<id> cleans up body:<id> and chapters:<id>.
      final dropChaptersKv = _QuotaDropStore(dropPrefix: 'chapters:');
      final dropChaptersStore = ReadingStore(dropChaptersKv);
      await expectLater(
        dropChaptersStore.add(
          now: 10,
          title: 'Con capítulos',
          body: 'Hola.',
          chapters: const [
            ReadingChapter(title: 'Cap 1', paragraphs: ['Hola.']),
          ],
          generated: false,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );
      expect(dropChaptersKv.data, isEmpty);
      expect(
        dropChaptersKv.deletedKeys,
        containsAll([
          ReadingStore.bodyKeyFor('biblioteca-10-0'),
          ReadingStore.chaptersKeyFor('biblioteca-10-0'),
        ]),
      );

      // 2. Silent drop on texts index cleans up BOTH body:<id> and chapters:<id>.
      final dropTextsKv = _QuotaDropStore(dropKey: 'texts');
      final dropTextsStore = ReadingStore(dropTextsKv);
      await expectLater(
        dropTextsStore.add(
          now: 20,
          title: 'Con capítulos 2',
          body: 'Hola.',
          chapters: const [
            ReadingChapter(title: 'Cap 1', paragraphs: ['Hola.']),
          ],
          generated: false,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );
      expect(dropTextsKv.data, isEmpty);
      expect(
        dropTextsKv.deletedKeys,
        containsAll([
          ReadingStore.bodyKeyFor('biblioteca-20-0'),
          ReadingStore.chaptersKeyFor('biblioteca-20-0'),
        ]),
      );

      // 3. Non-deletable store shrinks both body:<id> and chapters:<id> to ''.
      final nonDeletable = _NonDeletableFailTextsStore();
      final nonDelStore = ReadingStore(nonDeletable);
      await expectLater(
        nonDelStore.add(
          now: 30,
          title: 'Sin delete',
          body: 'Contenido largo.',
          chapters: const [
            ReadingChapter(title: 'Cap 1', paragraphs: ['Contenido largo.']),
          ],
          generated: false,
        ),
        throwsA(isA<ReadingStorageFullException>()),
      );
      expect(nonDeletable.data[ReadingStore.bodyKeyFor('biblioteca-30-0')], '');
      expect(
        nonDeletable.data[ReadingStore.chaptersKeyFor('biblioteca-30-0')],
        '',
      );
      expect(nonDeletable.data['texts'], isNull);
    });
  });
}
