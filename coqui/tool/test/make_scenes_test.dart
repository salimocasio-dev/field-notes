// Tests for tool/make_scenes.dart.
//
// Run at coqui/:  dart test tool/test

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import '../make_scenes.dart';

const _baselineOrder = [
  'frente',
  'balcon',
  'sala',
  'patio',
  'camino',
  'campo',
  'lago',
  'banco',
  'mesa',
  'estufa',
  'nevera',
  'comer',
  'mostrador',
  'estantes',
  'frutas',
  'caja',
  'esquina',
  'parada',
  'tiendas',
  'cruce',
  'plaza',
  'reloj',
  'quiosco',
  'calendario',
];

const _rngScenes = {'balcon', 'sala', 'patio', 'camino', 'lago', 'mesa'};

String _pascal(String id) =>
    id.split('_').map((p) => '${p[0].toUpperCase()}${p.substring(1)}').join();

void _writeFile(String path, String content) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _writeBytes(String path, List<int> bytes) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void _writeScenePlaces(Directory repo) {
  _writeFile('${repo.path}/coqui/tool/scene_places.json', '''
{
  "places": [
    {"id": "colmado", "scenes": ["mostrador", "estantes", "frutas", "caja"]},
    {"id": "calle", "scenes": ["esquina", "parada", "tiendas", "cruce"]},
    {"id": "plaza", "scenes": ["plaza", "reloj", "quiosco", "calendario"]},
    {"id": "playa", "scenes": ["orilla", "sombrilla", "ropa", "cielo"]},
    {"id": "fonda", "scenes": ["entrada", "pedido", "comida", "cuenta"]},
    {"id": "casa2", "scenes": ["cuarto", "bano", "sala_dia", "noche"]},
    {"id": "fuerte", "scenes": ["subida", "musica", "regalos", "muralla"]}
  ]
}
''');
}

void _writeCursoWithFirst12(Directory repo, {List<String> cual = const []}) {
  final first12 = _baselineOrder.take(12).toList();
  final stories = <String>[];
  for (final s in first12) {
    final storyId = 's-$s';
    stories.add(storyId);
    _writeFile(
      '${repo.path}/historia/cuentos/$storyId.json',
      jsonEncode({'id': storyId, 'scene': s}),
    );
  }
  _writeFile(
    '${repo.path}/historia/datos/curso.json',
    jsonEncode({
      'lugares': [
        {'id': 'published', 'cuentos': stories},
      ],
      'cual': cual,
    }),
  );
}

void _addScene(
  Directory repo,
  String id, {
  bool? takesRng,
  String? sheetJson,
  String? docsSheetJson,
}) {
  final rng = takesRng ?? _rngScenes.contains(id);
  final sig = rng ? '{Rng? rng}' : '';
  final fn = 'create${_pascal(id)}';
  _writeFile(
    '${repo.path}/coqui/packages/core/coqui_scenes/lib/src/$id/$id.dart',
    'Scene $fn($sig) => throw UnimplementedError();\n',
  );
  if (sheetJson != null) {
    _writeFile(
      '${repo.path}/coqui/packages/core/coqui_scenes/assets/sheets/$id-sheet.json',
      sheetJson,
    );
  }
  if (docsSheetJson != null) {
    _writeFile(
      '${repo.path}/docs/proyecto/pixel/$id-sheet.json',
      docsSheetJson,
    );
  }
}

List<int> _makeIndexedPng1x1({
  required int r,
  required int g,
  required int b,
  int? alpha,
}) {
  int crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : (crc >> 1);
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  List<int> chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    final out = BytesBuilder();
    final lenBd = ByteData(4)..setUint32(0, data.length);
    out.add(lenBd.buffer.asUint8List());
    out.add(typeBytes);
    out.add(data);
    final crcVal = crc32([...typeBytes, ...data]);
    final crcBd = ByteData(4)..setUint32(0, crcVal);
    out.add(crcBd.buffer.asUint8List());
    return out.toBytes();
  }

  final ihdr = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, 1)).buffer.asUint8List())
    ..add((ByteData(4)..setUint32(0, 1)).buffer.asUint8List())
    ..add([8, 3, 0, 0, 0]);
  final idatData = ZLibEncoder().convert([0, 0]);

  final png = BytesBuilder()
    ..add([137, 80, 78, 71, 13, 10, 26, 10])
    ..add(chunk('IHDR', ihdr.toBytes()))
    ..add(chunk('PLTE', [r, g, b]));
  if (alpha != null) {
    png.add(chunk('tRNS', [alpha]));
  }
  png
    ..add(chunk('IDAT', idatData))
    ..add(chunk('IEND', const []));
  return png.toBytes();
}

String _expectedHash(List<int> rgba) {
  int toInt32(num x) {
    final u = x.truncate() & 0xFFFFFFFF;
    return u >= 0x80000000 ? u - 0x100000000 : u;
  }

  int imul(int a, int b) {
    final x = toInt32(a);
    final y = toInt32(b);
    final ah = (x >> 16) & 0xFFFF;
    final al = x & 0xFFFF;
    final bh = (y >> 16) & 0xFFFF;
    final bl = y & 0xFFFF;
    final mid = ((ah * bl + al * bh) & 0xFFFF) * 65536;
    return toInt32(al * bl + mid);
  }

  var a = 0x811C9DC5;
  var b = 0x01234567;
  for (final x in rgba) {
    a = imul(a ^ x, 0x01000193) & 0xFFFFFFFF;
    b = imul(b ^ x, 0x5BD1E995) & 0xFFFFFFFF;
  }
  return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}

Directory _findRealRepoRoot() {
  var dir = Directory.current.absolute;
  while (true) {
    if (Directory('${dir.path}/coqui/packages/core/coqui_scenes')
        .existsSync()) {
      return dir;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('could not locate repo root from ${Directory.current}');
    }
    dir = parent;
  }
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('coqui_make_scenes_');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('isolated 24-scene baseline matches expected generated outputs', () {
    _writeScenePlaces(tmp);
    _writeCursoWithFirst12(tmp);
    for (final id in _baselineOrder) {
      _addScene(tmp, id, sheetJson: '{"scene":"$id"}\n');
    }
    // Helper folders without <dir>.dart must be ignored.
    _writeFile(
      '${tmp.path}/coqui/packages/core/coqui_scenes/lib/src/calle/calle_cast.dart',
      '// helper\n',
    );
    _writeFile(
      '${tmp.path}/coqui/packages/core/coqui_scenes/lib/src/colmado/colmado_cast.dart',
      '// helper\n',
    );

    final generated = buildGeneratedScenes(tmp);
    expect(generated.scenes.map((s) => s.id).toList(), _baselineOrder);

    final wantImports = _baselineOrder
        .map((id) => "import 'package:coqui_scenes/src/$id/$id.dart';")
        .join('\n');
    final wantRegistryEntries = _baselineOrder
        .map((id) {
          final fn = 'create${_pascal(id)}';
          return _rngScenes.contains(id)
              ? "  '$id': $fn,"
              : "  '$id': _plain($fn),";
        })
        .join('\n');

    expect(generated.registryDart, '''
import 'package:coqui_contracts/coqui_contracts.dart' show Rng;
import 'package:coqui_pixel/coqui_pixel.dart';
$wantImports

/// What makes a scene: it is given the game's one random source ([rng]: the story runner's), which a scene that draws
/// random numbers (El balcón's `azar`) draws from, as the old one drew from `Math.random`. A scene that draws none ignores it.
typedef SceneMaker = Scene Function({Rng? rng});

// The factory of a scene that draws no random number: it ignores the source it is given.
SceneMaker _plain(Scene Function() make) =>
    ({Rng? rng}) => make();

/// The eleven scenes, by id, in this order. Each id maps to the factory of its
/// scene. A converted scene's factory needs its sheet read first (`loadScene`);
/// every other factory throws until its scene is converted.
final Map<String, SceneMaker> sceneRegistry = Map.unmodifiable({
$wantRegistryEntries
});
''');

    final wantConvertedEntries = _baselineOrder
        .map((id) => "  '$id',")
        .join('\n');
    expect(generated.convertedScenesDart, '''
/// The scenes that are converted: each has its sheet among this package's assets and its real scene in the registry.
/// Until a scene is here, its pictures are the old ones (`assets/old_pictures/<id>/`, made by
/// tool/make_old_pictures.dart); adding it here and running that tool removes them.
///
/// This file imports nothing, so the tools under `tool/` (plain Dart) read the same list the app does.
const Set<String> convertedScenes = {
$wantConvertedEntries
};
''');

    final wantSheetEntries = _baselineOrder
        .map((id) => "  '$id': r'''{\"scene\":\"$id\"}\n''',")
        .join('\n');
    expect(generated.sheetsDart, '''
// Made by tool/make_sheets.dart from docs/proyecto/pixel/<id>-sheet.json. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// The sheets of the converted scenes, by id: the text of each file, for the tests that run in a browser.
const Map<String, String> sheetTexts = {
$wantSheetEntries
};
''');

    expect(generated.oldHashesDart, '''
// Made by tool/make_old_pictures.dart. Do not edit.

/// The hash of the pixels of each old picture (`<scene>/<name>`), from the tool's own PNG decoder: R, G, B, A bytes,
/// test/support/hash.dart's `hashBytes`.
const Map<String, String> oldHashes = {};
''');
  });

  test('real repo parity and --check pass on the workspace', () {
    final repoRoot = _findRealRepoRoot();
    expect(syncGeneratedScenes(repoRoot, check: true), isEmpty);

    final generated = buildGeneratedScenes(repoRoot);
    expect(generated.scenes.take(24).map((s) => s.id).toList(), _baselineOrder);
    for (final s in generated.scenes.take(24)) {
      expect(s.takesRng, _rngScenes.contains(s.id), reason: 'rng for ${s.id}');
    }
    final ids = generated.scenes.map((s) => s.id).toSet();
    expect(ids, isNot(contains('calle')));
    expect(ids, isNot(contains('colmado')));

    for (final s in generated.scenes) {
      final assetText = File(
        '${repoRoot.path}/coqui/packages/core/coqui_scenes/assets/sheets/${s.id}-sheet.json',
      ).readAsStringSync();
      expect(generated.sheetsDart, contains("'${s.id}': r'''$assetText''',"));
    }
    expect(
      generated.oldHashesDart,
      contains('const Map<String, String> oldHashes = {};'),
    );
  });

  test('zero-collision scene addition inserts in canonical order', () {
    _writeScenePlaces(tmp);
    _writeCursoWithFirst12(tmp);
    for (final id in _baselineOrder) {
      _addScene(tmp, id, sheetJson: '{"scene":"$id"}\n');
    }
    syncGeneratedScenes(tmp, check: false);
    expect(syncGeneratedScenes(tmp, check: true), isEmpty);

    // Add ONLY orilla folder + sheet.
    _addScene(
      tmp,
      'orilla',
      takesRng: false,
      sheetJson: '{"scene":"orilla"}\n',
    );
    final stale = syncGeneratedScenes(tmp, check: true);
    expect(stale, hasLength(3));

    syncGeneratedScenes(tmp, check: false);
    expect(syncGeneratedScenes(tmp, check: true), isEmpty);

    final generated = buildGeneratedScenes(tmp);
    expect(generated.scenes.map((s) => s.id).toList(), [
      ..._baselineOrder,
      'orilla',
    ]);
    expect(
      generated.registryDart,
      contains(
        "  'calendario': _plain(createCalendario),\n  'orilla': _plain(createOrilla),",
      ),
    );
    expect(
      generated.convertedScenesDart,
      contains("  'calendario',\n  'orilla',\n};"),
    );
    expect(
      generated.sheetsDart,
      contains("'orilla': r'''{\"scene\":\"orilla\"}\n''',"),
    );
  });

  test('unconverted cual scene computes expected FNV-1a oldHashes', () {
    _writeScenePlaces(tmp);
    _writeCursoWithFirst12(tmp, cual: ['cual-orilla']);
    for (final id in _baselineOrder) {
      _addScene(tmp, id, sheetJson: '{"scene":"$id"}\n');
    }
    _writeFile(
      '${tmp.path}/historia/cuentos/cual-orilla.json',
      jsonEncode({'id': 'cual-orilla', 'scene': 'orilla'}),
    );

    final siPng = _makeIndexedPng1x1(r: 10, g: 20, b: 30, alpha: 200);
    final noPng = _makeIndexedPng1x1(r: 40, g: 50, b: 60);
    final lvlPng = _makeIndexedPng1x1(r: 70, g: 80, b: 90, alpha: 128);
    _writeBytes('${tmp.path}/coqui/ref/escenas/orilla/pairs/si.png', siPng);
    _writeBytes('${tmp.path}/coqui/ref/escenas/orilla/pairs/no.png', noPng);
    _writeBytes('${tmp.path}/coqui/ref/escenas/orilla/pairs/lvl.png', lvlPng);
    _writeFile(
      '${tmp.path}/coqui/ref/escenas/orilla/pairs.json',
      jsonEncode({
        'pairs': [
          {
            'w': 'mar',
            'si': {'scene': 'orilla', 'png': 'si.png'},
            'no': {'scene': 'orilla', 'png': 'no.png'},
          },
        ],
        'level': [
          {
            'w': 'ola',
            'pictures': [
              {'scene': 'orilla', 'png': 'lvl.png'},
              {'scene': 'playa', 'png': 'other.png'},
            ],
          },
        ],
      }),
    );

    final generated = buildGeneratedScenes(tmp);
    expect(
      generated.oldHashesDart,
      contains("'orilla/mar.si': '${_expectedHash([10, 20, 30, 200])}',"),
    );
    expect(
      generated.oldHashesDart,
      contains("'orilla/mar.no': '${_expectedHash([40, 50, 60, 255])}',"),
    );
    expect(
      generated.oldHashesDart,
      contains("'orilla/nivel.ola.0': '${_expectedHash([70, 80, 90, 128])}',"),
    );
    expect(generated.oldHashesDart, isNot(contains('nivel.ola.1')));
  });

  group('error cases', () {
    test('throws FormatException when <id>/<id>.dart lacks Scene create...', () {
      _writeFile(
        '${tmp.path}/coqui/packages/core/coqui_scenes/lib/src/frente/frente.dart',
        'void notASceneFactory() {}\n',
      );
      expect(() => discoverScenes(tmp), throwsFormatException);
    });

    test('throws FormatException on positional or extra factory parameters', () {
      _writeFile(
        '${tmp.path}/coqui/packages/core/coqui_scenes/lib/src/frente/frente.dart',
        'Scene createFrente(Rng rng) => throw UnimplementedError();\n',
      );
      expect(() => discoverScenes(tmp), throwsFormatException);

      _writeFile(
        '${tmp.path}/coqui/packages/core/coqui_scenes/lib/src/frente/frente.dart',
        'Scene createFrente({Rng? rng, int extra = 0}) => throw UnimplementedError();\n',
      );
      expect(() => discoverScenes(tmp), throwsFormatException);
    });

    test('throws FormatException when sheet is missing', () {
      _addScene(tmp, 'frente');
      expect(() => buildGeneratedScenes(tmp), throwsFormatException);
    });

    test('throws FormatException when asset sheet differs from docs sheet', () {
      _addScene(
        tmp,
        'frente',
        sheetJson: '{"scene":"frente","v":1}\n',
        docsSheetJson: '{"scene":"frente","v":2}\n',
      );
      expect(() => buildGeneratedScenes(tmp), throwsFormatException);
    });
  });
}
