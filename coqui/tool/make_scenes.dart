// Generates shared scene lists and test fixtures from coqui_scenes/lib/src/<id>/<id>.dart.
// Pure Dart, no packages.
//
//   dart run tool/make_scenes.dart                    (at coqui/) writes the 7 generated files
//   dart run tool/make_scenes.dart --check            fails when any generated file is missing or stale
//   dart run tool/make_scenes.dart --check-committed  fails when any committed generated file is missing or stale
//   dart run tool/make_scenes.dart --list             prints discovered scene ids in canonical order

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SceneEntry {
  const SceneEntry({
    required this.id,
    required this.factory,
    required this.takesRng,
    required this.stateClass,
    required this.isSceneSheet,
  });

  final String id;
  final String factory;
  final bool takesRng;
  final String stateClass;
  final bool isSceneSheet;
}

class GeneratedScenes {
  const GeneratedScenes({
    required this.scenes,
    required this.registryDart,
    required this.convertedScenesDart,
    required this.sheetsDart,
    required this.oldHashesDart,
    required this.devMainDart,
    required this.makeSetFixtureDart,
    required this.refPpIndexJson,
  });

  final List<SceneEntry> scenes;
  final String registryDart;
  final String convertedScenesDart;
  final String sheetsDart;
  final String oldHashesDart;
  final String devMainDart;
  final String makeSetFixtureDart;
  final String refPpIndexJson;
}

final RegExp _sceneFactoryPattern = RegExp(
  r'^Scene\s+(create[A-Za-z0-9_]+)\s*\(([^)]*)\)',
  multiLine: true,
);
final RegExp _rngParamPattern = RegExp(r'^\s*\{\s*Rng\?\s+rng\s*,?\s*\}\s*$');
final RegExp _stateFromQueryPattern = RegExp(
  r'\b(?:factory\s+([A-Za-z0-9_]+)\.fromQuery|static\s+([A-Za-z0-9_]+)\s+fromQuery)\s*\(',
);

String _pascal(String id) => id
    .split('_')
    .where((p) => p.isNotEmpty)
    .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
    .join();

String _camel(String id) {
  final p = _pascal(id);
  return p.isEmpty ? p : '${p[0].toLowerCase()}${p.substring(1)}';
}

String _dartString(String value) {
  if (!value.contains("'") &&
      !value.contains(r'\') &&
      !value.contains(r'$') &&
      !value.contains('\n')) {
    return "'$value'";
  }
  if (!value.contains('"') &&
      !value.contains(r'\') &&
      !value.contains(r'$') &&
      !value.contains('\n')) {
    return '"$value"';
  }
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll("'", r"\'")
      .replaceAll(r'$', r'\$')
      .replaceAll('\n', r'\n');
  return "'$escaped'";
}

const _setFixtureWhat = <String, String>{
  'frente': "El frente's baked states",
  'balcon': "El balcón's baked states",
  'sala': "La sala's baked states",
  'patio': "El patio's baked states",
  'camino': "El camino's baked states",
  'campo':
      "El campo's baked state and two frames of it (its glints at two times)",
  'lago':
      "El lago's baked state and two frames of it (its glints at two times)",
  'banco': "El banco's reached baked states",
  'mesa': "La mesa's reached baked states, and the still of El colmado's stall under cocina.no",
  'estufa': "La estufa's baked states",
  'nevera': "La nevera's reached baked states",
  'comer': "A comer's baked state",
  'mostrador': "El mostrador's baked states, inside and in the street",
  'estantes': "Los estantes' baked states",
  'frutas': "Las frutas' baked states",
  'caja': "La caja's baked states",
  'esquina': "La esquina's baked states",
  'parada': "La parada's baked states",
  'tiendas': "Las tiendas' baked states, the row and story 55's buildings",
  'cruce': "El cruce's baked states",
  'plaza': "El banco de la plaza's baked states",
  'reloj': "El reloj's baked states",
  'quiosco': "El quiosco's baked states",
  'calendario': "El calendario's baked states",
  'orilla': "La orilla's baked states",
  'sombrilla': "La sombrilla's baked states",
};

List<SceneEntry> discoverScenes(Directory repoRoot) {
  final srcDir = Directory(
    '${repoRoot.path}/coqui/packages/core/coqui_scenes/lib/src',
  );
  if (!srcDir.existsSync()) {
    throw FormatException('scene folder root not found: ${srcDir.path}');
  }

  final discovered = <String, SceneEntry>{};
  final entries = srcDir.listSync(followLinks: false)
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final entity in entries) {
    if (entity is! Directory) continue;
    final id = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final mainDart = File('${entity.path}/$id.dart');
    if (!mainDart.existsSync()) continue;

    final source = mainDart.readAsStringSync();
    final match = _sceneFactoryPattern.firstMatch(source);
    if (match == null) {
      throw FormatException(
        '${mainDart.path}: missing top-level Scene create...(...) factory',
      );
    }
    final factory = match.group(1)!;
    final params = match.group(2)!;
    final takesRng = _rngParamPattern.hasMatch(params);
    if (!takesRng && params.trim().isNotEmpty) {
      throw FormatException(
        '${mainDart.path}: unsupported factory parameters "($params)"',
      );
    }

    final setDart = File('${entity.path}/${id}_set.dart');
    late final String stateClass;
    if (setDart.existsSync()) {
      final setSource = setDart.readAsStringSync();
      final stateMatch = _stateFromQueryPattern.firstMatch(setSource);
      final matchedName = stateMatch?.group(1) ?? stateMatch?.group(2);
      if (matchedName == null || !matchedName.endsWith('State')) {
        throw FormatException(
          '${setDart.path}: missing *State.fromQuery factory',
        );
      }
      stateClass = matchedName;
    } else {
      stateClass = '${_pascal(id)}State';
    }

    final assetsSheet = File(
      '${repoRoot.path}/coqui/packages/core/coqui_scenes/assets/sheets/$id-sheet.json',
    );
    final docsSheet = File(
      '${repoRoot.path}/docs/proyecto/pixel/$id-sheet.json',
    );
    var isSceneSheet = false;
    final sheetFile = assetsSheet.existsSync()
        ? assetsSheet
        : (docsSheet.existsSync() ? docsSheet : null);
    if (sheetFile != null) {
      final decoded = jsonDecode(sheetFile.readAsStringSync());
      isSceneSheet =
          decoded is Map<String, dynamic> &&
          !decoded.containsKey('pairPicture');
    }

    discovered[id] = SceneEntry(
      id: id,
      factory: factory,
      takesRng: takesRng,
      stateClass: stateClass,
      isSceneSheet: isSceneSheet,
    );
  }

  final order = <String>[];
  final seen = <String>{};
  void addOrder(String id) {
    if (seen.add(id)) order.add(id);
  }

  final cursoFile = File('${repoRoot.path}/historia/datos/curso.json');
  if (cursoFile.existsSync()) {
    final curso = jsonDecode(cursoFile.readAsStringSync());
    if (curso is Map<String, dynamic>) {
      final lugares = curso['lugares'];
      if (lugares is List) {
        for (final lugar in lugares) {
          if (lugar is! Map<String, dynamic>) continue;
          final cuentos = lugar['cuentos'];
          if (cuentos is! List) continue;
          for (final story in cuentos) {
            if (story is! String) continue;
            final storyFile = File(
              '${repoRoot.path}/historia/cuentos/$story.json',
            );
            if (!storyFile.existsSync()) continue;
            final storyJson = jsonDecode(storyFile.readAsStringSync());
            if (storyJson is Map<String, dynamic>) {
              final scene = storyJson['scene'];
              if (scene is String && scene.isNotEmpty) {
                addOrder(scene);
              }
            }
          }
        }
      }
    }
  }

  final placesFile = File('${repoRoot.path}/coqui/tool/scene_places.json');
  if (placesFile.existsSync()) {
    final placesJson = jsonDecode(placesFile.readAsStringSync());
    if (placesJson is Map<String, dynamic>) {
      final places = placesJson['places'];
      if (places is List) {
        for (final place in places) {
          if (place is! Map<String, dynamic>) continue;
          final scenes = place['scenes'];
          if (scenes is! List) continue;
          for (final scene in scenes) {
            if (scene is String && scene.isNotEmpty) {
              addOrder(scene);
            }
          }
        }
      }
    }
  }

  final remaining = discovered.keys.where((id) => !seen.contains(id)).toList()
    ..sort((a, b) => a.compareTo(b));
  for (final id in remaining) {
    addOrder(id);
  }

  return [
    for (final id in order)
      if (discovered.containsKey(id)) discovered[id]!,
  ];
}

GeneratedScenes buildGeneratedScenes(Directory repoRoot) {
  final scenes = discoverScenes(repoRoot);
  final scenesPkg = Directory(
    '${repoRoot.path}/coqui/packages/core/coqui_scenes',
  );

  final registryDart = _buildRegistryDart(scenes);
  final convertedScenesDart = _buildConvertedScenesDart(scenes);
  final sheetsDart = _buildSheetsDart(repoRoot, scenesPkg, scenes);
  final oldHashesDart = _buildOldHashesDart(repoRoot, scenes);
  final devMainDart = _buildDevMainDart(scenesPkg, scenes);
  final makeSetFixtureDart = _buildMakeSetFixtureDart(scenesPkg, scenes);
  final refPpIndexJson = buildRefPpIndex(repoRoot);

  return GeneratedScenes(
    scenes: scenes,
    registryDart: registryDart,
    convertedScenesDart: convertedScenesDart,
    sheetsDart: sheetsDart,
    oldHashesDart: oldHashesDart,
    devMainDart: devMainDart,
    makeSetFixtureDart: makeSetFixtureDart,
    refPpIndexJson: refPpIndexJson,
  );
}

String replaceGeneratedBlock(String source, String tag, String replacement) {
  final escapedTag = RegExp.escape(tag);
  final beginRe = RegExp(
    '^([ \\t]*)// BEGIN GENERATED BY coqui/tool/make_scenes\\.dart \\($escapedTag\\) — do not edit\\r?\$',
    multiLine: true,
  );
  final endRe = RegExp(
    '^([ \\t]*)// END GENERATED BY coqui/tool/make_scenes\\.dart \\($escapedTag\\)\\r?\$',
    multiLine: true,
  );

  final beginMatches = beginRe.allMatches(source).toList();
  if (beginMatches.isEmpty) {
    throw FormatException('missing BEGIN generated block marker for "$tag"');
  }
  if (beginMatches.length > 1) {
    throw FormatException('duplicate BEGIN generated block marker for "$tag"');
  }
  final endMatches = endRe.allMatches(source).toList();
  if (endMatches.isEmpty) {
    throw FormatException('missing END generated block marker for "$tag"');
  }
  if (endMatches.length > 1) {
    throw FormatException('duplicate END generated block marker for "$tag"');
  }

  final begin = beginMatches.single;
  final end = endMatches.single;
  if (end.start <= begin.end) {
    throw FormatException(
      'END generated block marker appears before BEGIN marker for "$tag"',
    );
  }

  final indent = begin.group(1)!;
  final lineSep = source.substring(begin.start, begin.end).endsWith('\r')
      ? '\r\n'
      : '\n';
  var afterBegin = begin.end;
  if (afterBegin < source.length && source[afterBegin] == '\n') {
    afterBegin++;
  } else {
    throw FormatException(
      'BEGIN generated block marker for "$tag" must end with a newline',
    );
  }

  final trimmed = replacement.endsWith('\n')
      ? replacement.substring(0, replacement.length - 1)
      : replacement;
  final body = trimmed.isEmpty
      ? ''
      : '${trimmed.split('\n').map((line) => line.isEmpty ? '' : '$indent$line').join(lineSep)}$lineSep';

  return '${source.substring(0, afterBegin)}$body${source.substring(end.start)}';
}

String _buildDevMainDart(Directory scenesPkg, List<SceneEntry> scenes) {
  final devMainFile = File('${scenesPkg.path}/tool/dev_main.dart');
  if (!devMainFile.existsSync()) {
    throw FormatException('missing ${devMainFile.path}');
  }
  final source = devMainFile.readAsStringSync();

  final imports = [
    for (final s in scenes)
      "import 'package:coqui_scenes/src/${s.id}/${s.id}_set.dart';",
  ].join('\n');

  final newIds = [
    for (final s in scenes)
      if (s.isSceneSheet) s.id,
  ];
  final newSetBuf = StringBuffer();
  if (newIds.isEmpty) {
    newSetBuf.writeln('const Set<String> _newSceneIds = {};');
  } else {
    newSetBuf.writeln('const Set<String> _newSceneIds = {');
    for (final id in newIds) {
      newSetBuf.writeln("  '$id',");
    }
    newSetBuf.writeln('};');
  }

  final hasFrente = scenes.any((s) => s.id == 'frente');
  final switchBuf = StringBuffer()
    ..writeln(
      'String _setKeyFromQuery(String id, String query) => switch (id) {',
    );
  for (final s in scenes) {
    if (s.id == 'frente') continue;
    switchBuf.writeln("  '${s.id}' => ${s.stateClass}.fromQuery(query).key,");
  }
  switchBuf
    ..writeln(
      hasFrente
          ? '  _ => FrenteState.fromQuery(query).key,'
          : "  _ => throw ArgumentError.value(id, 'id', 'unknown scene'),",
    )
    ..write('};');

  final sceneSwitch = '${newSetBuf.toString()}\n${switchBuf.toString()}';

  var out = replaceGeneratedBlock(source, 'dev_main_imports', imports);
  out = replaceGeneratedBlock(out, 'dev_main_scene_switch', sceneSwitch);
  return out;
}

String _buildMakeSetFixtureDart(Directory scenesPkg, List<SceneEntry> scenes) {
  final fixtureToolFile = File('${scenesPkg.path}/tool/make_set_fixture.dart');
  if (!fixtureToolFile.existsSync()) {
    throw FormatException('missing ${fixtureToolFile.path}');
  }
  final source = fixtureToolFile.readAsStringSync();

  final buf = StringBuffer();
  if (scenes.isEmpty) {
    buf.write(
      'const scenes = <String, ({String file, String constant, String what})>{};',
    );
  } else {
    buf.writeln(
      'const scenes = <String, ({String file, String constant, String what})>{',
    );
    for (final s in scenes) {
      final file = s.id == 'frente' ? 'set_refs.dart' : '${s.id}_set_refs.dart';
      final constant = s.id == 'frente' ? 'setRefs' : '${_camel(s.id)}SetRefs';
      final what = _setFixtureWhat[s.id] ?? "${s.id}'s baked states";
      buf
        ..writeln("  '${s.id}': (")
        ..writeln("    file: '$file',")
        ..writeln("    constant: '$constant',")
        ..writeln('    what: ${_dartString(what)},')
        ..writeln('  ),');
    }
    buf.write('};');
  }

  return replaceGeneratedBlock(source, 'set_fixture_scenes', buf.toString());
}

final RegExp _sha256HexPattern = RegExp(r'^[0-9a-f]{64}$');

String _basename(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final trimmed = normalized.endsWith('/') && normalized.length > 1
      ? normalized.substring(0, normalized.length - 1)
      : normalized;
  final slash = trimmed.lastIndexOf('/');
  return slash < 0 ? trimmed : trimmed.substring(slash + 1);
}

String buildRefPpIndex(Directory repoRoot) {
  final ppDir = Directory('${repoRoot.path}/coqui/ref/pp');
  if (!ppDir.existsSync()) {
    throw FormatException('ref/pp folder not found: ${ppDir.path}');
  }

  final topEntries = ppDir.listSync(followLinks: false);
  final subdirs = <Directory>[];
  for (final entity in topEntries) {
    final name = _basename(entity.path);
    if (entity is Directory) {
      subdirs.add(entity);
    } else if (name != 'index.json') {
      throw FormatException(
        'unexpected top-level file in ${ppDir.path}: $name',
      );
    }
  }
  subdirs.sort((a, b) => _basename(a.path).compareTo(_basename(b.path)));

  final allEntries = <Map<String, Object>>[];
  var grandTotalBytes = 0;

  for (final subdir in subdirs) {
    final folder = _basename(subdir.path);
    final indexFile = File('${subdir.path}/index.json');
    if (!indexFile.existsSync()) {
      throw FormatException('missing ${indexFile.path}');
    }
    final decoded = jsonDecode(indexFile.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('${indexFile.path}: expected JSON object');
    }
    final filesCount = decoded['files'];
    final totalBytes = decoded['totalBytes'];
    final rawEntries = decoded['entries'];
    if (filesCount is! int || totalBytes is! int || rawEntries is! List) {
      throw FormatException(
        '${indexFile.path}: expected int files/totalBytes and list entries',
      );
    }

    final seenPaths = <String>{};
    var sumBytes = 0;
    for (final raw in rawEntries) {
      if (raw is! Map<String, dynamic>) {
        throw FormatException('${indexFile.path}: entry must be a JSON object');
      }
      final relPath = raw['path'];
      final bytes = raw['bytes'];
      final sha256 = raw['sha256'];
      if (relPath is! String ||
          relPath.isEmpty ||
          relPath.startsWith('/') ||
          relPath.contains('\\') ||
          relPath == 'index.json') {
        throw FormatException('${indexFile.path}: invalid entry path $relPath');
      }
      final segments = relPath.split('/');
      if (segments.any((seg) => seg.isEmpty || seg == '.' || seg == '..')) {
        throw FormatException('${indexFile.path}: invalid entry path $relPath');
      }
      if (bytes is! int || bytes < 0) {
        throw FormatException(
          '${indexFile.path}: invalid bytes for $relPath: $bytes',
        );
      }
      if (sha256 is! String || !_sha256HexPattern.hasMatch(sha256)) {
        throw FormatException(
          '${indexFile.path}: invalid sha256 for $relPath: $sha256',
        );
      }
      if (!seenPaths.add(relPath)) {
        throw FormatException(
          '${indexFile.path}: duplicate entry path $relPath',
        );
      }

      final targetFile = File('${subdir.path}/$relPath');
      if (!targetFile.existsSync()) {
        throw FormatException(
          '${indexFile.path}: indexed file missing: $folder/$relPath',
        );
      }
      final actualBytes = targetFile.lengthSync();
      if (actualBytes != bytes) {
        throw FormatException(
          '${indexFile.path}: $folder/$relPath has $actualBytes bytes, index says $bytes',
        );
      }

      sumBytes += bytes;
      allEntries.add({
        'path': '$folder/$relPath',
        'bytes': bytes,
        'sha256': sha256,
      });
      grandTotalBytes += bytes;
    }

    if (filesCount != seenPaths.length) {
      throw FormatException(
        '${indexFile.path}: files count $filesCount != ${seenPaths.length}',
      );
    }
    if (totalBytes != sumBytes) {
      throw FormatException(
        '${indexFile.path}: totalBytes $totalBytes != $sumBytes',
      );
    }

    final actualPaths = <String>{};
    void walkFolder(Directory dir, String prefix) {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = _basename(entity.path);
        final rel = prefix.isEmpty ? name : '$prefix/$name';
        if (entity is Directory) {
          walkFolder(entity, rel);
        } else if (entity is File) {
          if (rel != 'index.json') actualPaths.add(rel);
        }
      }
    }

    walkFolder(subdir, '');
    for (final actual in actualPaths) {
      if (!seenPaths.contains(actual)) {
        throw FormatException(
          '${indexFile.path}: unindexed file in folder: $folder/$actual',
        );
      }
    }
  }

  allEntries.sort(
    (a, b) => (a['path'] as String).compareTo(b['path'] as String),
  );
  final out = <String, Object>{
    'what': 'engine reference: renders of docs/proyecto/pixel/ in headless Chrome, the island, and unit values',
    'files': allEntries.length,
    'totalBytes': grandTotalBytes,
    'entries': allEntries,
  };
  return '${const JsonEncoder.withIndent('  ').convert(out)}\n';
}

String _buildRegistryDart(List<SceneEntry> scenes) {
  final buf = StringBuffer()
    ..writeln("import 'package:coqui_contracts/coqui_contracts.dart' show Rng;")
    ..writeln("import 'package:coqui_pixel/coqui_pixel.dart';");
  for (final s in scenes) {
    buf.writeln("import 'package:coqui_scenes/src/${s.id}/${s.id}.dart';");
  }
  buf
    ..writeln()
    ..writeln(
      '/// What makes a scene: it is given the game\'s one random source ([rng]: the story runner\'s), which a scene that draws',
    )
    ..writeln(
      '/// random numbers (El balcón\'s `azar`) draws from, as the old one drew from `Math.random`. A scene that draws none ignores it.',
    )
    ..writeln('typedef SceneMaker = Scene Function({Rng? rng});')
    ..writeln()
    ..writeln(
      '// The factory of a scene that draws no random number: it ignores the source it is given.',
    )
    ..writeln('SceneMaker _plain(Scene Function() make) =>')
    ..writeln('    ({Rng? rng}) => make();')
    ..writeln()
    ..writeln(
      '/// The eleven scenes, by id, in this order. Each id maps to the factory of its',
    )
    ..writeln(
      '/// scene. A converted scene\'s factory needs its sheet read first (`loadScene`);',
    )
    ..writeln('/// every other factory throws until its scene is converted.');

  if (scenes.isEmpty) {
    buf.writeln(
      'final Map<String, SceneMaker> sceneRegistry = Map.unmodifiable({});',
    );
  } else {
    buf.writeln(
      'final Map<String, SceneMaker> sceneRegistry = Map.unmodifiable({',
    );
    for (final s in scenes) {
      final value = s.takesRng ? s.factory : '_plain(${s.factory})';
      buf.writeln("  '${s.id}': $value,");
    }
    buf.writeln('});');
  }
  return buf.toString();
}

String _buildConvertedScenesDart(List<SceneEntry> scenes) {
  final buf = StringBuffer()
    ..writeln(
      '/// The scenes that are converted: each has its sheet among this package\'s assets and its real scene in the registry.',
    )
    ..writeln(
      '/// Until a scene is here, its pictures are the old ones (`assets/old_pictures/<id>/`, made by',
    )
    ..writeln(
      '/// tool/make_old_pictures.dart); adding it here and running that tool removes them.',
    )
    ..writeln('///')
    ..writeln(
      '/// This file imports nothing, so the tools under `tool/` (plain Dart) read the same list the app does.',
    );

  if (scenes.isEmpty) {
    buf.writeln('const Set<String> convertedScenes = {};');
  } else {
    buf.writeln('const Set<String> convertedScenes = {');
    for (final s in scenes) {
      buf.writeln("  '${s.id}',");
    }
    buf.writeln('};');
  }
  return buf.toString();
}

String _buildSheetsDart(
  Directory repoRoot,
  Directory scenesPkg,
  List<SceneEntry> scenes,
) {
  final buf = StringBuffer()
    ..writeln(
      '// Made by tool/make_sheets.dart from docs/proyecto/pixel/<id>-sheet.json. Do not edit.',
    )
    ..writeln('// ignore_for_file: lines_longer_than_80_chars')
    ..writeln()
    ..writeln(
      '/// The sheets of the converted scenes, by id: the text of each file, for the tests that run in a browser.',
    );

  if (scenes.isEmpty) {
    buf.writeln('const Map<String, String> sheetTexts = {};');
    return buf.toString();
  }

  buf.writeln('const Map<String, String> sheetTexts = {');
  for (final s in scenes) {
    final assetsSheet = File(
      '${scenesPkg.path}/assets/sheets/${s.id}-sheet.json',
    );
    final docsSheet = File(
      '${repoRoot.path}/docs/proyecto/pixel/${s.id}-sheet.json',
    );
    final hasAssets = assetsSheet.existsSync();
    final hasDocs = docsSheet.existsSync();

    late final String want;
    if (hasAssets && hasDocs) {
      final aText = assetsSheet.readAsStringSync();
      final dText = docsSheet.readAsStringSync();
      if (aText != dText) {
        throw FormatException(
          'sheet mismatch for ${s.id}: ${assetsSheet.path} differs from ${docsSheet.path}',
        );
      }
      want = aText;
    } else if (hasAssets) {
      want = assetsSheet.readAsStringSync();
    } else if (hasDocs) {
      want = docsSheet.readAsStringSync();
    } else {
      throw FormatException('missing sheet for ${s.id}');
    }

    if (want.contains("'''")) {
      throw FormatException('sheet for ${s.id} holds three quotes in a row');
    }
    buf.writeln("  '${s.id}': r'''$want''',");
  }
  buf.writeln('};');
  return buf.toString();
}

String _buildOldHashesDart(Directory repoRoot, List<SceneEntry> scenes) {
  final convertedSet = {for (final s in scenes) s.id};
  final cursoFile = File('${repoRoot.path}/historia/datos/curso.json');
  final refRoot = '${repoRoot.path}/coqui/ref/escenas';

  final todo = <String>[];
  if (cursoFile.existsSync()) {
    final curso = jsonDecode(cursoFile.readAsStringSync());
    if (curso is Map<String, dynamic>) {
      final cual = curso['cual'];
      if (cual is List) {
        for (final f in cual) {
          if (f is! String) continue;
          final cualFile = File('${repoRoot.path}/historia/cuentos/$f.json');
          if (!cualFile.existsSync()) continue;
          final j = jsonDecode(cualFile.readAsStringSync());
          if (j is! Map<String, dynamic>) continue;
          final s = j['scene'];
          if (s is! String || s.isEmpty) continue;
          if (!convertedSet.contains(s) &&
              !todo.contains(s) &&
              File('$refRoot/$s/pairs.json').existsSync()) {
            todo.add(s);
          }
        }
      }
    }
  }

  final hashes = <String, String>{};
  for (final id in todo) {
    final pairsFile = File('$refRoot/$id/pairs.json');
    final j = jsonDecode(pairsFile.readAsStringSync()) as Map<String, dynamic>;
    final pictures = <String, String>{};

    void add(String name, Object? side, String what) {
      final m = side as Map<String, dynamic>;
      if (m['scene'] != id) return;
      final png = m['png'];
      if (png is! String) {
        throw FormatException('$id: $what has no png in ${pairsFile.path}');
      }
      if (pictures.containsKey(name) && pictures[name] != png) {
        throw FormatException(
          '$id: the name "$name" is two files, ${pictures[name]} and $png',
        );
      }
      pictures[name] = png;
    }

    for (final p in j['pairs'] as List) {
      for (final side in const ['si', 'no']) {
        add('${p['w']}.$side', p[side], 'review picture ${p['w']}.$side');
      }
    }
    for (final l in j['level'] as List) {
      final pics = l['pictures'] as List;
      for (var i = 0; i < pics.length; i++) {
        add('nivel.${l['w']}.$i', pics[i], 'level picture ${l['w']}.$i');
      }
    }

    for (final e in pictures.entries) {
      final src = File('$refRoot/$id/pairs/${e.value}');
      if (!src.existsSync()) continue;
      final bytes = src.readAsBytesSync();
      hashes['$id/${e.key}'] = _hashBytes(_decodePng(bytes));
    }
  }

  final buf = StringBuffer()
    ..writeln('// Made by tool/make_old_pictures.dart. Do not edit.')
    ..writeln()
    ..writeln(
      '/// The hash of the pixels of each old picture (`<scene>/<name>`), from the tool\'s own PNG decoder: R, G, B, A bytes,',
    )
    ..writeln('/// test/support/hash.dart\'s `hashBytes`.');

  if (hashes.isEmpty) {
    buf.writeln('const Map<String, String> oldHashes = {};');
  } else {
    final keys = hashes.keys.toList()..sort();
    buf.writeln('const Map<String, String> oldHashes = {');
    for (final k in keys) {
      buf.writeln("  '$k': '${hashes[k]}',");
    }
    buf.writeln('};');
  }
  return buf.toString();
}

(int, int) _pngSize(List<int> b) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    if (b.length < 24 || b[i] != sig[i]) throw const FormatException('PNG');
  }
  int u32(int at) =>
      (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
  return (u32(16), u32(20));
}

Uint8List _decodePng(List<int> b) {
  final (w, h) = _pngSize(b);
  var pos = 8;
  Uint8List? plte, trns;
  final idat = BytesBuilder();
  final bd = ByteData.sublistView(Uint8List.fromList(b));
  while (pos < b.length) {
    final len = bd.getUint32(pos);
    final type = String.fromCharCodes(b.sublist(pos + 4, pos + 8));
    final data = Uint8List.fromList(b.sublist(pos + 8, pos + 8 + len));
    if (type == 'IHDR' && (data[8] != 8 || data[9] != 3 || data[12] != 0)) {
      throw const FormatException('not an 8-bit indexed PNG without interlace');
    }
    if (type == 'PLTE') plte = data;
    if (type == 'tRNS') trns = data;
    if (type == 'IDAT') idat.add(data);
    pos += 12 + len;
  }
  final raw = ZLibDecoder().convert(idat.toBytes());
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    if (raw[y * (w + 1)] != 0) {
      throw const FormatException('a PNG row has a filter');
    }
    for (var x = 0; x < w; x++) {
      final i = raw[y * (w + 1) + 1 + x];
      final o = (y * w + x) * 4;
      out[o] = plte![i * 3];
      out[o + 1] = plte[i * 3 + 1];
      out[o + 2] = plte[i * 3 + 2];
      out[o + 3] = trns != null && i < trns.length ? trns[i] : 255;
    }
  }
  return out;
}

int _toInt32(num x) {
  if (x.isNaN || x.isInfinite) return 0;
  int u;
  if (x is int) {
    u = x & 0xFFFFFFFF;
  } else if (x.abs() >= 9007199254740992.0) {
    u = x.remainder(4294967296.0).truncate() & 0xFFFFFFFF;
  } else {
    u = x.truncate() & 0xFFFFFFFF;
  }
  return u >= 0x80000000 ? u - 0x100000000 : u;
}

int _imul(int a, int b) {
  final x = _toInt32(a);
  final y = _toInt32(b);
  final ah = (x >> 16) & 0xFFFF;
  final al = x & 0xFFFF;
  final bh = (y >> 16) & 0xFFFF;
  final bl = y & 0xFFFF;
  final mid = ((ah * bl + al * bh) & 0xFFFF) * 65536;
  return _toInt32(al * bl + mid);
}

String _hashBytes(Uint8List bytes) {
  var a = 0x811C9DC5;
  var b = 0x01234567;
  for (final x in bytes) {
    a = _imul(a ^ x, 0x01000193) & 0xFFFFFFFF;
    b = _imul(b ^ x, 0x5BD1E995) & 0xFFFFFFFF;
  }
  return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}

List<String> syncGeneratedScenes(
  Directory repoRoot, {
  required bool check,
  bool committedOnly = false,
}) {
  final generated = buildGeneratedScenes(repoRoot);
  final base = '${repoRoot.path}/coqui/packages/core/coqui_scenes';
  final committedTargets = <(String, String)>[
    ('$base/tool/dev_main.dart', generated.devMainDart),
    ('$base/tool/make_set_fixture.dart', generated.makeSetFixtureDart),
    ('${repoRoot.path}/coqui/ref/pp/index.json', generated.refPpIndexJson),
  ];
  final ignoredTargets = <(String, String)>[
    ('$base/lib/src/registry.dart', generated.registryDart),
    ('$base/lib/src/converted_scenes.dart', generated.convertedScenesDart),
    ('$base/test/support/fixtures/sheets.dart', generated.sheetsDart),
    ('$base/test/support/fixtures/old_hashes.dart', generated.oldHashesDart),
  ];
  final targets = committedOnly
      ? committedTargets
      : [...ignoredTargets, ...committedTargets];

  final problems = <String>[];
  for (final (path, content) in targets) {
    final file = File(path);
    if (check) {
      if (!file.existsSync()) {
        problems.add('$path is missing: run dart run tool/make_scenes.dart');
      } else if (file.readAsStringSync() != content) {
        problems.add(
          '$path is NOT current: run dart run tool/make_scenes.dart',
        );
      }
    } else {
      if (!file.existsSync() || file.readAsStringSync() != content) {
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(content);
      }
    }
  }
  return problems;
}

Directory _defaultRepoRoot() {
  final starts = <Directory>[
    File.fromUri(Platform.script).parent,
    Directory.current,
  ];
  for (final start in starts) {
    var dir = start.absolute;
    while (true) {
      final probe = Directory('${dir.path}/coqui/packages/core/coqui_scenes');
      if (probe.existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  return Directory.current;
}

void main(List<String> args) {
  var check = false;
  var checkCommitted = false;
  var list = false;
  Directory? root;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--check') {
      check = true;
    } else if (arg == '--check-committed') {
      checkCommitted = true;
    } else if (arg == '--list') {
      list = true;
    } else if (arg == '--root' && i + 1 < args.length) {
      root = Directory(args[++i]);
    } else {
      stderr.writeln(
        'usage: dart run tool/make_scenes.dart [--check | --check-committed | --list] [--root DIR]',
      );
      exit(64);
    }
  }

  final repoRoot = (root ?? _defaultRepoRoot()).absolute;

  if (list) {
    final scenes = discoverScenes(repoRoot);
    for (final s in scenes) {
      stdout.writeln(s.id);
    }
    return;
  }

  if (check || checkCommitted) {
    final problems = syncGeneratedScenes(
      repoRoot,
      check: true,
      committedOnly: checkCommitted && !check,
    );
    if (problems.isNotEmpty) {
      for (final p in problems) {
        stderr.writeln(p);
      }
      exit(1);
    }
    final count = discoverScenes(repoRoot).length;
    stdout.writeln('make_scenes: ok ($count scenes)');
    return;
  }

  syncGeneratedScenes(repoRoot, check: false);
  final count = discoverScenes(repoRoot).length;
  stdout.writeln('make_scenes: wrote 7 files for $count scenes');
}
