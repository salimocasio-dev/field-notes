// Tests for tool/check_sitio.mjs static built-JS host checks, vendored SDK
// integrity, and CSP alignment.
//
// Run at coqui/:  dart test tool/test

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

const _expectedVendorSha256 =
    'ec975ddc738967e53b0e37346eef5488217ff4d50968030bd1c26f9fd63a9c3c';

const _tempWorkletUrl =
    'https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.2/dist/libsamplerate.worklet.js';

const _sha256K = <int>[
  0x428a2f98,
  0x71374491,
  0xb5c0fbcf,
  0xe9b5dba5,
  0x3956c25b,
  0x59f111f1,
  0x923f82a4,
  0xab1c5ed5,
  0xd807aa98,
  0x12835b01,
  0x243185be,
  0x550c7dc3,
  0x72be5d74,
  0x80deb1fe,
  0x9bdc06a7,
  0xc19bf174,
  0xe49b69c1,
  0xefbe4786,
  0x0fc19dc6,
  0x240ca1cc,
  0x2de92c6f,
  0x4a7484aa,
  0x5cb0a9dc,
  0x76f988da,
  0x983e5152,
  0xa831c66d,
  0xb00327c8,
  0xbf597fc7,
  0xc6e00bf3,
  0xd5a79147,
  0x06ca6351,
  0x14292967,
  0x27b70a85,
  0x2e1b2138,
  0x4d2c6dfc,
  0x53380d13,
  0x650a7354,
  0x766a0abb,
  0x81c2c92e,
  0x92722c85,
  0xa2bfe8a1,
  0xa81a664b,
  0xc24b8b70,
  0xc76c51a3,
  0xd192e819,
  0xd6990624,
  0xf40e3585,
  0x106aa070,
  0x19a4c116,
  0x1e376c08,
  0x2748774c,
  0x34b0bcb5,
  0x391c0cb3,
  0x4ed8aa4a,
  0x5b9cca4f,
  0x682e6ff3,
  0x748f82ee,
  0x78a5636f,
  0x84c87814,
  0x8cc70208,
  0x90befffa,
  0xa4506ceb,
  0xbef9a3f7,
  0xc67178f2,
];

int _rotr32(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xFFFFFFFF;

String _sha256Hex(List<int> bytes) {
  final bitLen = bytes.length * 8;
  final paddedLen = ((bytes.length + 9 + 63) ~/ 64) * 64;
  final padded = Uint8List(paddedLen);
  padded.setRange(0, bytes.length, bytes);
  padded[bytes.length] = 0x80;
  final bd = ByteData.sublistView(padded);
  bd.setUint64(paddedLen - 8, bitLen, Endian.big);

  var h0 = 0x6a09e667;
  var h1 = 0xbb67ae85;
  var h2 = 0x3c6ef372;
  var h3 = 0xa54ff53a;
  var h4 = 0x510e527f;
  var h5 = 0x9b05688c;
  var h6 = 0x1f83d9ab;
  var h7 = 0x5be0cd19;

  final w = Uint32List(64);
  for (var offset = 0; offset < paddedLen; offset += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = bd.getUint32(offset + i * 4, Endian.big);
    }
    for (var i = 16; i < 64; i++) {
      final s0 =
          _rotr32(w[i - 15], 7) ^ _rotr32(w[i - 15], 18) ^ (w[i - 15] >>> 3);
      final s1 =
          _rotr32(w[i - 2], 17) ^ _rotr32(w[i - 2], 19) ^ (w[i - 2] >>> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
    }

    var a = h0;
    var b = h1;
    var c = h2;
    var d = h3;
    var e = h4;
    var f = h5;
    var g = h6;
    var h = h7;

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr32(e, 6) ^ _rotr32(e, 11) ^ _rotr32(e, 25);
      final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
      final temp1 = (h + s1 + ch + _sha256K[i] + w[i]) & 0xFFFFFFFF;
      final s0 = _rotr32(a, 2) ^ _rotr32(a, 13) ^ _rotr32(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xFFFFFFFF;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xFFFFFFFF;
    }

    h0 = (h0 + a) & 0xFFFFFFFF;
    h1 = (h1 + b) & 0xFFFFFFFF;
    h2 = (h2 + c) & 0xFFFFFFFF;
    h3 = (h3 + d) & 0xFFFFFFFF;
    h4 = (h4 + e) & 0xFFFFFFFF;
    h5 = (h5 + f) & 0xFFFFFFFF;
    h6 = (h6 + g) & 0xFFFFFFFF;
    h7 = (h7 + h) & 0xFFFFFFFF;
  }

  return [
    h0,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    h7,
  ].map((v) => v.toRadixString(16).padLeft(8, '0')).join();
}

Directory _findCoquiRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (File('${dir.path}/tool/check_sitio.mjs').existsSync()) {
      return dir;
    }
    final nested = Directory('${dir.path}/coqui');
    if (File('${nested.path}/tool/check_sitio.mjs').existsSync()) {
      return nested;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        'could not locate coqui/ root from ${Directory.current}',
      );
    }
    dir = parent;
  }
}

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Map<String, dynamic> _runNodeCheckBuiltJsHosts(
  File checkSitioFile,
  Directory rootDir,
) {
  const script = r'''
const mod = await import(process.argv[1]);
const result = mod.checkBuiltJsHosts(process.argv[2]);
process.stdout.write(JSON.stringify(result));
''';
  final res = Process.runSync('node', [
    '--input-type=module',
    '-e',
    script,
    Uri.file(checkSitioFile.path).toString(),
    rootDir.path,
  ]);
  expect(res.exitCode, 0, reason: 'node failed: ${res.stderr}');
  return jsonDecode(res.stdout as String) as Map<String, dynamic>;
}

List<String> _extractUrlsViaArg(File checkSitioFile, String jsSource) {
  const script = r'''
const mod = await import(process.argv[1]);
const src = process.argv[2];
process.stdout.write(JSON.stringify(mod.extractExternalUrlsFromJs(src)));
''';
  final res = Process.runSync('node', [
    '--input-type=module',
    '-e',
    script,
    Uri.file(checkSitioFile.path).toString(),
    jsSource,
  ]);
  expect(res.exitCode, 0, reason: 'node failed: ${res.stderr}');
  return (jsonDecode(res.stdout as String) as List<dynamic>).cast<String>();
}

Map<String, dynamic> _readExportedAllowlists(File checkSitioFile) {
  const script = r'''
const mod = await import(process.argv[1]);
process.stdout.write(JSON.stringify({
  allowedScriptHosts: [...mod.ALLOWED_SCRIPT_HOSTS],
  temporaryAllowedScriptUrls: [...mod.TEMPORARY_ALLOWED_SCRIPT_URLS],
}));
''';
  final res = Process.runSync('node', [
    '--input-type=module',
    '-e',
    script,
    Uri.file(checkSitioFile.path).toString(),
  ]);
  expect(res.exitCode, 0, reason: 'node failed: ${res.stderr}');
  return jsonDecode(res.stdout as String) as Map<String, dynamic>;
}

void _populateCleanBuild(
  Directory coquiRoot,
  Directory outDir, {
  bool useLocalCanvasKit = true,
  String? extraMainJs = '',
  String? indexHtmlOverride,
}) {
  final realIndexHtml = File('${coquiRoot.path}/app/web/index.html')
      .readAsStringSync();
  _writeFile('${outDir.path}/index.html', indexHtmlOverride ?? realIndexHtml);

  _writeFile('${outDir.path}/flutter_bootstrap.js', '''
_flutter.buildConfig = {"engineRevision":"deadbeef","builds":[{"compileTarget":"dart2js","renderer":"canvaskit"}],"useLocalCanvasKit":$useLocalCanvasKit};
const cdnBase = "https://www.gstatic.com/flutter-canvaskit";
_flutter.loader.load();
''');

  _writeFile('${outDir.path}/flutter.js', '''
function resolveCanvasKit(config, buildConfig) {
  return buildConfig.useLocalCanvasKit ? "canvaskit" : "https://www.gstatic.com/flutter-canvaskit";
}
console.log("See https://web.dev/articles/coop-coep and https://wicg.github.io/cross-origin-storage/");
console.log("Issue https://github.com/flutter/flutter/issues/156910");
''');

  _writeFile('${outDir.path}/main.dart.js', '''
const baseUrl = "https://salimocasio-dev.github.io/field-notes/app/";
const fontFallback = "https://fonts.gstatic.com/s/";
const docs = ["https://api.flutter.dev/flutter/widgets/Text-class.html", "https://docs.flutter.dev/get-started", "https://flutter.dev/docs", "https://pub.dev/packages/web"];
${extraMainJs ?? ''}
''');

  _writeFile(
    '${outDir.path}/canvaskit/canvaskit.js',
    'var CanvasKitInit = function() {};\n',
  );

  final realVendor = File(
    '${coquiRoot.path}/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js',
  );
  final destVendor = File(
    '${outDir.path}/assets/packages/coqui_platform/assets/elevenlabs/lib.iife.js',
  );
  destVendor.parent.createSync(recursive: true);
  realVendor.copySync(destVendor.path);
}

void main() {
  late Directory coquiRoot;
  late File checkSitioFile;
  late Directory tmp;

  setUpAll(() {
    coquiRoot = _findCoquiRoot();
    checkSitioFile = File('${coquiRoot.path}/tool/check_sitio.mjs');
    expect(checkSitioFile.existsSync(), isTrue);
  });

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('coqui_check_sitio_test_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  group('pure-Dart SHA-256', () {
    test('matches NIST test vectors (empty, abc, multi-block >64 bytes)', () {
      expect(
        _sha256Hex(utf8.encode('')),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        _sha256Hex(utf8.encode('abc')),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        _sha256Hex(
          utf8.encode(
            'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
          ),
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
      expect(
        _sha256Hex(
          utf8.encode(
            'abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu',
          ),
        ),
        'cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1',
      );
    });

    test('detects a 1-byte mutation', () {
      final orig = Uint8List.fromList(utf8.encode('coqui-vendor-check'));
      final mutated = Uint8List.fromList(orig)..[5] ^= 0x01;
      expect(_sha256Hex(orig), isNot(_sha256Hex(mutated)));
    });
  });

  group('vendored ElevenLabs SDK integrity', () {
    test('lib.iife.js matches pinned SHA-256 and has no sourceMappingURL', () {
      final vendorFile = File(
        '${coquiRoot.path}/packages/core/coqui_platform/assets/elevenlabs/lib.iife.js',
      );
      expect(
        vendorFile.existsSync(),
        isTrue,
        reason: 'Expected vendored SDK at ${vendorFile.path} (#252/#253)',
      );

      final bytes = vendorFile.readAsBytesSync();
      final actualSha = _sha256Hex(bytes);
      expect(
        actualSha,
        _expectedVendorSha256,
        reason:
            'Vendored ElevenLabs SDK lib.iife.js SHA-256 mismatch! '
            'Per #252/#253, keep lib.iife.js unchanged until '
            'coqui/requests/253-tool-needs-coqui-platform-self-host-libsamplerate-worklet.md '
            'lands in coqui_platform (which updates this pinned hash intentionally).',
      );

      final tailLines = utf8.decode(bytes).trimRight().split(RegExp(r'\r?\n'));
      expect(
        tailLines.last.trimLeft().startsWith('//# sourceMappingURL='),
        isFalse,
        reason: 'lib.iife.js must not end with a //# sourceMappingURL= line (#252/#253)',
      );
    });
  });

  group('checkBuiltJsHosts & extractExternalUrlsFromJs', () {
    test('clean synthetic build including real lib.iife.js passes with 0 violations', () {
      _populateCleanBuild(coquiRoot, tmp);
      final result = _runNodeCheckBuiltJsHosts(checkSitioFile, tmp);
      expect(result['violations'], isEmpty);
      expect(result['filesScanned'], greaterThanOrEqualTo(5));
      expect(result['urlsChecked'], greaterThan(0));
    });

    test('exact temporary libsamplerate worklet URL passes, other cdn.jsdelivr.net URLs fail', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: 'const ok = "$_tempWorkletUrl";',
      );
      expect(
        _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations'],
        isEmpty,
      );

      for (final badUrl in [
        'https://cdn.jsdelivr.net/npm/@elevenlabs/client@1.25.0/+esm',
        'https://cdn.jsdelivr.net/npm/@alexanderolsen/libsamplerate-js@2.1.3/dist/libsamplerate.worklet.js',
        '$_tempWorkletUrl?v=2',
      ]) {
        final dir = Directory.systemTemp.createTempSync('coqui_bad_jsdelivr_')
          ..createSync(recursive: true);
        try {
          _populateCleanBuild(
            coquiRoot,
            dir,
            extraMainJs: 'const bad = "$badUrl";',
          );
          final res = _runNodeCheckBuiltJsHosts(checkSitioFile, dir);
          final violations = res['violations'] as List<dynamic>;
          expect(violations, isNotEmpty, reason: 'should reject $badUrl');
        } finally {
          dir.deleteSync(recursive: true);
        }
      }
    });

    test('rejects external script/worklet hosts and http:// URLs', () {
      for (final badUrl in [
        'https://unpkg.com/@elevenlabs/client@1.25.0/dist/lib.iife.js',
        'https://evil.example/worklet.js',
        'http://evil.example/a.js',
      ]) {
        final dir = Directory.systemTemp.createTempSync('coqui_bad_host_');
        try {
          _populateCleanBuild(
            coquiRoot,
            dir,
            extraMainJs: 'const u = "$badUrl";',
          );
          final violations =
              _runNodeCheckBuiltJsHosts(checkSitioFile, dir)['violations']
                  as List<dynamic>;
          expect(violations, hasLength(1), reason: 'should reject $badUrl');
          expect((violations.first as Map)['url'], badUrl);
        } finally {
          dir.deleteSync(recursive: true);
        }
      }
    });

    test('rejects protocol-relative URLs', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: 'const u = "//evil.example/a.js";',
      );
      final violations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(violations, hasLength(1));
      expect((violations.first as Map)['url'], '//evil.example/a.js');
    });

    test('rejects escaped URLs (slash escapes and unicode escapes)', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: r'''const a = "https:\/\/evil.example\/a.js"; const b = "https://\u0063dn.jsdelivr.net/evil.js";''',
      );
      final violations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(violations, hasLength(2));
      final urls = violations.map((v) => (v as Map)['url']).toSet();
      expect(urls, {
        'https://evil.example/a.js',
        'https://cdn.jsdelivr.net/evil.js',
      });
    });

    test('rejects template-literal external URLs', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs:
            'const v = "1"; const u = `https://evil.example/\${v}/a.js`;',
      );
      final violations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(violations, hasLength(1));
      expect((violations.first as Map)['url'], 'https://evil.example/');
    });

    test('rejects script-like paths on allowed doc hosts', () {
      for (final badUrl in [
        'https://docs.flutter.dev/evil.js',
        'https://github.com/attacker/repo/evil.js',
        'https://github.com/flutter/flutter/issues/evil.mjs',
        'https://pub.dev/packages/foo/+esm',
      ]) {
        final dir = Directory.systemTemp.createTempSync(
          'coqui_bad_doc_script_',
        );
        try {
          _populateCleanBuild(
            coquiRoot,
            dir,
            extraMainJs: 'const u = "$badUrl";',
          );
          final violations =
              _runNodeCheckBuiltJsHosts(checkSitioFile, dir)['violations']
                  as List<dynamic>;
          expect(violations, hasLength(1), reason: 'should reject $badUrl');
        } finally {
          dir.deleteSync(recursive: true);
        }
      }
    });

    test('rejects gstatic flutter-canvaskit in main.dart.js or when useLocalCanvasKit is false', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: 'const ck = "https://www.gstatic.com/flutter-canvaskit";',
      );
      final mainJsViolations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(mainJsViolations, hasLength(1));
      expect((mainJsViolations.first as Map)['file'], 'main.dart.js');

      final dirFalse = Directory.systemTemp.createTempSync('coqui_ck_false_');
      try {
        _populateCleanBuild(coquiRoot, dirFalse, useLocalCanvasKit: false);
        final violations =
            _runNodeCheckBuiltJsHosts(checkSitioFile, dirFalse)['violations']
                as List<dynamic>;
        // Violation for useLocalCanvasKit !== true AND for gstatic URLs in flutter_bootstrap.js / flutter.js.
        expect(violations.length, greaterThanOrEqualTo(3));
      } finally {
        dirFalse.deleteSync(recursive: true);
      }
    });

    test('rejects external <script src> in index.html', () {
      final baseHtml = File('${coquiRoot.path}/app/web/index.html')
          .readAsStringSync();
      final dirtyHtml = baseHtml.replaceFirst(
        '</body>',
        '  <script src="https://evil.example/x.js"></script>\n</body>',
      );
      _populateCleanBuild(coquiRoot, tmp, indexHtmlOverride: dirtyHtml);
      final violations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(violations, hasLength(1));
      expect((violations.first as Map)['file'], 'index.html');
      expect((violations.first as Map)['url'], 'https://evil.example/x.js');
    });

    test(
      'regex literals with quotes and comments do not break JS scanning',
      () {
        const js = r'''
// https://comment-only.example/ignored.js
/* https://block-comment.example/ignored.js */
const r1 = /"/g;
const r2 = /'/;
const r3 = /^https?:\/\//;
const after = "https://evil.example/caught.js";
''';
        final extracted = _extractUrlsViaArg(checkSitioFile, js);
        expect(extracted, ['https://evil.example/caught.js']);
      },
    );

    test('rejects case-insensitive schemes (HTTPS:// and Http://)', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: 'import("HTTPS://evil.example/a.js"); const b = "Http://evil.example/b.js";',
      );
      final violations =
          _runNodeCheckBuiltJsHosts(checkSitioFile, tmp)['violations']
              as List<dynamic>;
      expect(violations, hasLength(2));
      final urls = violations.map((v) => (v as Map)['url']).toSet();
      expect(urls, {'HTTPS://evil.example/a.js', 'Http://evil.example/b.js'});
    });

    test('regex literals after control-flow parens do not swallow URLs, and obj.if(x) / 2 parses as division', () {
      const js = r'''
if (ok) /"/.test(x); const u = "https://evil.example/a.js";
while (a && (b || c)) /'/.test(x); const v = "https://evil.example/b.js";
for (;;) /"/.test(x); const w = "https://evil.example/c.js";
const q = obj.if(x) / 2; const d = "https://evil.example/d.js";
if (obj.if(x) / 2 > 0) /"/.test(y); const e = "https://evil.example/e.js";
''';
      final extracted = _extractUrlsViaArg(checkSitioFile, js);
      expect(extracted, [
        'https://evil.example/a.js',
        'https://evil.example/b.js',
        'https://evil.example/c.js',
        'https://evil.example/d.js',
        'https://evil.example/e.js',
      ]);
    });
  });

  group('CLI --static-only smoke tests', () {
    test('exits 0 and prints all checks passed on clean build', () {
      _populateCleanBuild(coquiRoot, tmp);
      final res = Process.runSync('node', [
        checkSitioFile.path,
        tmp.path,
        '--static-only',
      ]);
      expect(res.exitCode, 0, reason: '${res.stdout}\n${res.stderr}');
      expect(res.stdout as String, contains('all checks passed'));
    });

    test('exits 1 and prints FAIL + offending URL on dirty build', () {
      _populateCleanBuild(
        coquiRoot,
        tmp,
        extraMainJs: 'const evil = "https://evil.example/injected.js";',
      );
      final res = Process.runSync('node', [
        checkSitioFile.path,
        tmp.path,
        '--static-only',
      ]);
      expect(res.exitCode, 1, reason: '${res.stdout}\n${res.stderr}');
      final out = res.stdout as String;
      expect(out, contains('FAIL'));
      expect(out, contains('https://evil.example/injected.js'));
    });
  });

  group('CSP alignment', () {
    test('index.html CSP script-src and worker-src have zero external hosts matching ALLOWED_SCRIPT_HOSTS', () {
      final html = File('${coquiRoot.path}/app/web/index.html')
          .readAsStringSync();
      final metaMatch = RegExp(
        '<meta[^>]+http-equiv="Content-Security-Policy"[^>]+content="([^"]+)"',
      ).firstMatch(html);
      expect(metaMatch, isNotNull, reason: 'CSP meta tag must exist');
      final csp = metaMatch!.group(1)!;

      final directives = <String, String>{};
      for (final part in csp.split(';')) {
        final trimmed = part.trim();
        if (trimmed.isEmpty) continue;
        final space = trimmed.indexOf(RegExp(r'\s'));
        if (space == -1) {
          directives[trimmed] = '';
        } else {
          directives[trimmed.substring(0, space)] = trimmed
              .substring(space + 1)
              .trim();
        }
      }

      expect(directives.containsKey('script-src'), isTrue);
      expect(directives.containsKey('worker-src'), isTrue);
      expect(
        RegExp(r'https?:').hasMatch(directives['script-src']!),
        isFalse,
        reason: 'script-src must not allow external http:/https: hosts',
      );
      expect(
        RegExp(r'https?:').hasMatch(directives['worker-src']!),
        isFalse,
        reason: 'worker-src must not allow external http:/https: hosts',
      );

      final allowlists = _readExportedAllowlists(checkSitioFile);
      expect(allowlists['allowedScriptHosts'], isEmpty);
      expect(allowlists['temporaryAllowedScriptUrls'], [_tempWorkletUrl]);
    });
  });
}
