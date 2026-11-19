import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'compare.dart';
import 'ref_files.dart';

/// One entry of `coqui/ref/sprites/engine/sprites.json`.
class SpriteEntry {
  SpriteEntry(this.json);

  final Map<String, dynamic> json;

  String get id => json['id'] as String;
  String get fn => json['fn'] as String;
  String get call => json['call'] as String;
  List<dynamic> get args => json['args'] as List<dynamic>;
  int get w => json['w'] as int;
  int get h => json['h'] as int;
  String get file => json['file'] as String;
  int get offset => json['offset'] as int;
  int get bytes => json['bytes'] as int;
  Map<String, dynamic>? get target => json['target'] as Map<String, dynamic>?;
}

/// Every sprite of engine.js the reference holds, in the file's order.
List<SpriteEntry> loadSpriteEntries() {
  final doc = jsonDecode(
    refFileText('sprites/engine/sprites.json'),
  ) as Map<String, dynamic>;
  return [
    for (final s in doc['sprites'] as List<dynamic>)
      SpriteEntry(s as Map<String, dynamic>),
  ];
}

/// The pixels of a sprite as the reference holds them.
Uint32List referencePixels(SpriteEntry e) {
  final all = refFile('sprites/engine/${e.file}');
  return readU32(Uint8List.sublistView(all, e.offset, e.offset + e.bytes));
}

/// Makes the sprite the recorded call made: the same function with the same arguments, on a transparent canvas or
/// `Buf` of the target's size when it is a drawer.
Sprite replaySprite(SpriteLib lib, SpriteEntry e) {
  final a = e.args;
  final t = e.target;
  if (t == null) {
    switch (e.fn) {
      case 'mkCoqui':
        return mkCoqui(a[0] as num, a[1] as int, (a[2] as int) != 0);
      case 'mkAbuela':
        return mkAbuela(a[0] as String, (a[1] as int) != 0);
      case 'mkDog':
        return mkDog((a[0] as int) != 0);
      case 'mkTree':
        return mkTree();
      case 'mkPalm':
        return mkPalm();
      case 'mkBall':
        return mkBall();
      case 'mkCup':
        return mkCup();
      case 'mkBush':
        return mkBush();
      case 'mkPot':
        return mkPot();
      case 'bgCasa':
        return lib.bgCasa((a[0] as int) != 0);
      case 'bgParque':
        return lib.bgParque();
    }
    throw StateError('no maker ${e.fn}');
  }
  final w = t['w'] as int, h = t['h'] as int;
  if (t['kind'] == 'Buf') {
    final b = Buf(w, h);
    switch (e.fn) {
      case 'sky':
        sky(b, a[0] as num, a[1] as num);
      case 'grass':
        grass(b, a[0] as num, a[1] as num, a[2] as num);
      default:
        throw StateError('no Buf drawer ${e.fn}');
    }
    return b.done();
  }
  final sprite = Sprite(w, h, Uint32List(w * h));
  final c = Ctx(sprite.px, w, h);
  switch (e.fn) {
    case 'glyph':
      lib.glyph(c, a[0] as String, a[1] as num, a[2] as num);
    case 'face':
      face(c, a[0] as num, a[1] as num, a[2] as bool);
    case 'bubble':
      lib.bubble(
        c,
        [for (final k in a[0] as List<dynamic>) k as String],
        a[1] as num,
        a[2] as num,
        a[3] as int,
      );
    case 'shadow':
      shadow(c, a[0] as num, a[1] as num, a[2] as num);
    case 'pointer':
      pointer(c, [
        for (final v in a[0] as List<dynamic>) v as num,
      ], a[1] as int);
    case 'sparks':
      sparks(c, [
        for (final p in a[0] as List<dynamic>)
          [for (final v in p as List<dynamic>) v as num],
      ], a[1] as int);
    case 'talk':
      talk(c, a[0] as num, a[1] as num, a[2] as int, a[3] as int);
    default:
      throw StateError('no canvas drawer ${e.fn}');
  }
  return sprite;
}
