import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_pixel/coqui_pixel.dart';

import 'compare.dart';
import 'kit_files.dart';
import 'sprite_replay.dart' show SpriteEntry;

/// Every sprite of `coqui/ref/sprites/kit/sprites.json`, in the file's order.
List<SpriteEntry> loadKitEntries() {
  final doc = jsonDecode(kitFileText('sprites.json')) as Map<String, dynamic>;
  return [
    for (final s in doc['sprites'] as List<dynamic>)
      SpriteEntry(s as Map<String, dynamic>),
  ];
}

/// `FAM` of the reference, as data (colours as `"#RRGGBB"`; the one function as its source text).
Map<String, dynamic> loadKitFam() {
  final doc = jsonDecode(kitFileText('sprites.json')) as Map<String, dynamic>;
  return doc['FAM'] as Map<String, dynamic>;
}

/// The pixels of a kit sprite as the reference holds them.
Uint32List kitReferencePixels(SpriteEntry e) {
  final all = kitFile(e.file);
  return readU32(Uint8List.sublistView(all, e.offset, e.offset + e.bytes));
}

/// `Object.assign({}, KIT.FAM[fam], assign)`: the person the recorded call made.
Who whoOf(Map<String, dynamic> w) {
  var who = FAM[w['fam'] as String]!;
  final assign = w['assign'] as Map<String, dynamic>?;
  if (assign != null) {
    assign.forEach((k, v) {
      switch (k) {
        case 'dormido':
          who = who.copyWith(dormido: v != 0);
        case 'gafas':
          who = who.copyWith(gafas: v);
        default:
          throw StateError('no assign $k');
      }
    });
  }
  return who;
}

/// Makes the sprite the recorded call made: the same function with the same arguments, on a transparent canvas of the
/// target's size when it is a drawer. A flag the old code tests for truth is a `bool` here.
Sprite replayKitSprite(SpriteEntry e) {
  final a = e.args;
  bool flag(int i) => (a[i] as int) != 0;
  final t = e.target;
  if (t == null) {
    switch (e.fn) {
      case 'mkAve':
        return mkAve(a[0] as String, flag(1));
      case 'mkAbuelaS':
        return mkAbuelaS(a[0] as String, flag(1), flag(2));
      case 'mkPersona':
        return mkPersona(
          whoOf(a[0] as Map<String, dynamic>),
          a[1] as String,
          flag(2),
          flag(3),
        );
      case 'mkBebe':
        return mkBebe(a[0] as String, flag(1));
      case 'mkPerro':
        return mkPerro(a[0] as String, flag(1));
      case 'mkCesta':
        return mkCesta();
    }
    throw StateError('no maker ${e.fn}');
  }
  final w = t['w'] as int, h = t['h'] as int;
  final sprite = Sprite(w, h, Uint32List(w * h));
  final c = Ctx(sprite.px, w, h);
  switch (e.fn) {
    case 'tarjeta':
      tarjeta(c, a[0] as num, a[1] as num, a[2] as num, a[3] as num);
    case 'mano':
      mano(c, a[0] as num, a[1] as num);
    default:
      throw StateError('no drawer ${e.fn}');
  }
  return sprite;
}
