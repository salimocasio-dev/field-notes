// The old pictures of the scenes that are not converted yet, as assets of this package.
//
//   dart run tool/make_old_pictures.dart          (in this package) writes assets/old_pictures/<id>/ for every scene
//                                                 that is NOT in convertedScenes, and removes the folder of any other
//   dart run tool/make_old_pictures.dart --check  fails when an asset is not what it should be, and when a folder exists
//                                                 for a converted scene
//
// Until a scene is converted, its pictures (the review pictures and the level-check cells) are the ones order 06 saved:
// coqui/ref/escenas/<id>/pairs/*.png, 196 x 104 and 96 x 106, drawn by the old pages. ScenePictures shows them by name.
// Each folder holds those PNGs and `index.json`: the picture's name, as PictureRef.of / PictureRef.ofLevel make it
// (`<word>.si`, `<word>.no`, `nivel.<word>.<index>`: the word as the content writes it, accents and spaces included), to
// its file. A scene's folder holds the pictures that scene DRAWS: a pair whose other side is drawn by another scene
// (camino's `parque`, drawn by patio) has that side in the other scene's folder, as PictureRef.of's scene says.
//
// When a scene is converted: add it to convertedScenes (lib/src/converted_scenes.dart), run this tool; its folder goes.
//
// Also written: the assets listed in pubspec.yaml (one folder each); test/support/fixtures/old_sample.dart, the last
// scene's folder as text, for the tests that run in a browser (the root bundle never answers there); and
// test/support/fixtures/old_hashes.dart, the hash of every picture's pixels as this tool decodes the PNG itself (these
// files are indexed, with no filter), which the tests compare with what the engine's image codec gives.
//
// And it checks, against the content (historia/cuentos/cual-*.json, historia/datos/nivel.json): every review picture and
// every level-check cell a course item names, if its scene is not converted, has a file here. It prints each name that
// has none and fails.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart' show imul;
import 'package:coqui_scenes/src/converted_scenes.dart';
import 'package:coqui_scenes/src/registry.dart';

const refRoot = '../../../ref/escenas';
const historia = '../../../../historia';
const assetsRoot = 'assets/old_pictures';
const fixturePath = 'test/support/fixtures/old_sample.dart';
const hashesPath = 'test/support/fixtures/old_hashes.dart';

/// An old review picture, and an old cell of the level check: the sizes the old pages drew them in.
const reviewSize = (196, 104), levelSize = (96, 106);

late bool check;
final problems = <String>[];

void problem(String s) {
  problems.add(s);
  stdout.writeln(s);
}

Object? readJson(String path) => jsonDecode(File(path).readAsStringSync());

/// A PNG's size, from its header.
(int, int) pngSize(List<int> b) {
  const sig = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < 8; i++) {
    if (b.length < 24 || b[i] != sig[i]) throw const FormatException('PNG');
  }
  int u32(int at) =>
      (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
  return (u32(16), u32(20));
}

/// The pictures scene [id] draws: name to file, from `coqui/ref/escenas/<id>/pairs.json` (the old pages' own record of
/// which PNG is which picture).
Map<String, String> picturesOf(String id) {
  final j = readJson('$refRoot/$id/pairs.json') as Map<String, dynamic>;
  final out = <String, String>{};
  void add(String name, Object? side, String what) {
    final m = side as Map<String, dynamic>;
    if (m['scene'] != id) return;
    final png = m['png'];
    if (png is! String) {
      problem('$id: $what has no png in $refRoot/$id/pairs.json');
      return;
    }
    if (out.containsKey(name) && out[name] != png) {
      problem('$id: the name "$name" is two files, ${out[name]} and $png');
    }
    out[name] = png;
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
  return out;
}

/// What a picture of the content is called and which scene draws it, as PictureRef.of / PictureRef.ofLevel say (the
/// contract's rules, read from the content files): `(scene, name)` for every side of every review pair and every picture
/// of every level item.
List<(String, String)> contentNames() {
  final curso = readJson('$historia/datos/curso.json') as Map<String, dynamic>;
  final pairs = <Map<String, dynamic>>[];
  final scenes = <Map<String, dynamic>, String>{};
  final out = <(String, String)>[];
  for (final f in (curso['cual'] as List).cast<String>()) {
    final j = readJson('$historia/cuentos/$f.json') as Map<String, dynamic>;
    for (final it in j['items'] as List) {
      final item = it as Map<String, dynamic>;
      pairs.add(item);
      scenes[item] = j['scene'] as String;
      for (final side in const ['si', 'no']) {
        final esc = (item[side] as Map<String, dynamic>)['esc'] as String?;
        out.add((esc ?? scenes[item]!, '${item['w']}.$side'));
      }
    }
  }
  // app.html, pares(): the last item with a word is the one the word gives
  final byWord = {for (final p in pairs) p['w'] as String: p};
  for (final q in readJson('$historia/datos/nivel.json') as List) {
    final item = q as Map<String, dynamic>, ps = item['p'] as List;
    for (var i = 0; i < ps.length; i++) {
      final pic = ps[i] as List, pair = byWord[pic[0]];
      if (pair == null) {
        problem(
          'level item "${item['w']}" picture $i: no review pair "${pic[0]}"',
        );
        continue;
      }
      final esc =
          (pair[pic[1] == 'no' ? 'no' : 'si'] as Map<String, dynamic>)['esc']
              as String?;
      out.add((esc ?? scenes[pair]!, 'nivel.${item['w']}.$i'));
    }
  }
  return out;
}

/// The pixels of an indexed (palette), 8-bit, unfiltered, non-interlaced PNG as R, G, B, A bytes: all these files are.
Uint8List decodePng(List<int> b) {
  final (w, h) = pngSize(b);
  var pos = 8;
  Uint8List? plte, trns;
  final idat = BytesBuilder();
  final bd = ByteData.sublistView(Uint8List.fromList(b));
  while (pos < b.length) {
    final len = bd.getUint32(pos),
        type = String.fromCharCodes(b.sublist(pos + 4, pos + 8));
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
      final i = raw[y * (w + 1) + 1 + x], o = (y * w + x) * 4;
      out[o] = plte![i * 3];
      out[o + 1] = plte[i * 3 + 1];
      out[o + 2] = plte[i * 3 + 2];
      out[o + 3] = trns != null && i < trns.length ? trns[i] : 255;
    }
  }
  return out;
}

/// Two 32-bit hashes of bytes (FNV-1a, and the same with another prime), 8 hex digits each: test/support/hash.dart's
/// `hashBytes`.
String hashBytes(Uint8List bytes) {
  var a = 0x811C9DC5, b = 0x01234567;
  for (final x in bytes) {
    a = imul(a ^ x, 0x01000193) & 0xFFFFFFFF;
    b = imul(b ^ x, 0x5BD1E995) & 0xFFFFFFFF;
  }
  return '${a.toRadixString(16).padLeft(8, '0')}${b.toRadixString(16).padLeft(8, '0')}';
}

String indexText(Map<String, String> index) {
  final names = index.keys.toList()..sort();
  return '${const JsonEncoder.withIndent(' ').convert({for (final n in names) n: index[n]})}\n';
}

/// Makes (or checks) a file; [bytes] is what it should hold.
void put(File f, List<int> bytes) {
  if (check) {
    if (!f.existsSync()) {
      problem('${f.path} is missing: run dart run tool/make_old_pictures.dart');
    } else if (!_same(f.readAsBytesSync(), bytes)) {
      problem(
        '${f.path} is NOT current: run dart run tool/make_old_pictures.dart',
      );
    }
  } else {
    if (!f.existsSync() || !_same(f.readAsBytesSync(), bytes)) {
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
    }
  }
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main(List<String> args) {
  check = args.contains('--check');
  if (!Directory(refRoot).existsSync() ||
      !Directory(historia).existsSync() ||
      !File('pubspec.yaml').existsSync()) {
    stderr.writeln(
      'Run this in coqui/packages/core/coqui_scenes: $refRoot or $historia is not there.',
    );
    exit(2);
  }
  final ids = sceneRegistry.keys.toList();
  final todo = [
    for (final id in ids)
      if (!convertedScenes.contains(id)) id,
  ];
  final index = <String, Map<String, String>>{};
  final hashes = <String, String>{};
  var total = 0;
  for (final id in todo) {
    final pictures = picturesOf(id);
    index[id] = pictures;
    final dir = Directory('$assetsRoot/$id');
    final want = <String>{'index.json', ...pictures.values};
    for (final e in pictures.entries) {
      final src = File('$refRoot/$id/pairs/${e.value}');
      if (!src.existsSync()) {
        problem(
          '$id: ${e.key} is ${e.value}, which is not in $refRoot/$id/pairs/',
        );
        continue;
      }
      final bytes = src.readAsBytesSync();
      final (w, h) = pngSize(bytes);
      final size = e.key.startsWith('nivel.') ? levelSize : reviewSize;
      if ((w, h) != size) {
        problem(
          '$id: ${e.key} (${e.value}) is $w x $h, not ${size.$1} x ${size.$2}',
        );
      }
      put(File('${dir.path}/${e.value}'), bytes);
      total += bytes.length;
      hashes['$id/${e.key}'] = hashBytes(decodePng(bytes));
    }
    final text = utf8.encode(indexText(pictures));
    put(File('${dir.path}/index.json'), text);
    total += text.length;
    // a file that is not one of these is left over
    if (dir.existsSync()) {
      for (final f in dir.listSync()) {
        final name = f.uri.pathSegments.last;
        if (f is File && !want.contains(name)) {
          if (check) {
            problem('${f.path} is not one of $id\'s old pictures');
          } else {
            f.deleteSync();
          }
        }
      }
    }
  }
  // a folder for a scene that is converted (or is not a scene) goes
  final root = Directory(assetsRoot);
  if (root.existsSync()) {
    for (final d in root.listSync()) {
      final id = d.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (todo.contains(id) && d is Directory) continue;
      if (check) {
        problem(
          convertedScenes.contains(id)
              ? '${d.path} exists, and $id is converted: run dart run tool/make_old_pictures.dart'
              : '${d.path} is not the folder of a scene that is not converted',
        );
      } else {
        d.deleteSync(recursive: true);
        stdout.writeln('removed ${d.path}');
      }
    }
  }

  // pubspec.yaml: the assets, one folder per scene
  final pubspec = File('pubspec.yaml');
  final lines = pubspec.readAsStringSync().split('\n');
  final kept = [
    for (final l in lines)
      if (!RegExp(r'^\s+- assets/old_pictures/').hasMatch(l)) l,
  ];
  final at = kept.indexWhere((l) => l.trim() == '- assets/sheets/');
  if (at < 0) {
    problem(
      'pubspec.yaml has no "- assets/sheets/" line to put the old pictures after',
    );
  } else {
    kept.insertAll(at + 1, [
      for (final id in todo) '    - assets/old_pictures/$id/',
    ]);
    final text = kept.join('\n');
    if (check) {
      if (text != pubspec.readAsStringSync()) {
        problem(
          'pubspec.yaml does not list the old pictures: run dart run tool/make_old_pictures.dart',
        );
      }
    } else {
      pubspec.writeAsStringSync(text);
    }
  }

  // the content: every picture a course item names has a file
  final names = contentNames();
  var missing = 0, old = 0;
  for (final (scene, name) in names) {
    if (convertedScenes.contains(scene)) continue;
    old++;
    if (!ids.contains(scene)) {
      problem('$scene: "$name" is drawn by a scene that does not exist');
      missing++;
    } else if (!index[scene]!.containsKey(name)) {
      problem('$scene: no old picture for "$name"');
      missing++;
    }
  }

  // the fixture for the tests in a browser: the last scene's folder, as one JSON text
  if (todo.isNotEmpty) {
    final id = todo.last, pics = index[id]!;
    final names = pics.keys.toList()..sort();
    final files = <String, String>{
      for (final n in names)
        pics[n]!: base64Encode(
          File('$refRoot/$id/pairs/${pics[n]}').readAsBytesSync(),
        ),
    };
    final json = jsonEncode({'scene': id, 'index': pics, 'files': files});
    final text = [
      '// Made by tool/make_old_pictures.dart from the old pictures of the last scene that is not converted. Do not edit.',
      '// ignore_for_file: lines_longer_than_80_chars',
      '',
      '/// One scene\'s old pictures, for the tests that run in a browser: `{scene, index (name to file), files (file to base64)}`.',
      'const String oldSampleJson =',
      "    r'''$json''';",
      '',
    ].join('\n');
    put(File(fixturePath), utf8.encode(text));
  }

  {
    final keys = hashes.keys.toList()..sort();
    final text = [
      '// Made by tool/make_old_pictures.dart. Do not edit.',
      '',
      '/// The hash of the pixels of each old picture (`<scene>/<name>`), from the tool\'s own PNG decoder: R, G, B, A bytes,',
      '/// test/support/hash.dart\'s `hashBytes`.',
      'const Map<String, String> oldHashes = {',
      for (final k in keys) "  '$k': '${hashes[k]}',",
      '};',
      '',
    ].join('\n');
    put(File(hashesPath), utf8.encode(text));
  }

  stdout.writeln(
    '${todo.length} scenes are not converted (${todo.join(', ')}); '
    '${index.values.fold<int>(0, (a, m) => a + m.length)} old pictures, '
    '${(total / 1024).toStringAsFixed(1)} KB (assets/old_pictures/); '
    'the content names ${names.length} pictures, $old drawn by those scenes, $missing with no file',
  );
  if (problems.isNotEmpty) exit(1);
}
