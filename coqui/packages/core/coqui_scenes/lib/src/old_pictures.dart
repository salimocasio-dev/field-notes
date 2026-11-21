import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coqui_scenes/src/picture_error.dart';
import 'package:flutter/services.dart';

/// Where an old picture of a scene that is not converted yet is, as an asset of this package: `assets/old_pictures/<id>/`,
/// made by tool/make_old_pictures.dart from `coqui/ref/escenas/<id>/pairs/` (order 06).
String oldPictureAsset(String id, String file) =>
    'packages/coqui_scenes/assets/old_pictures/$id/$file';

/// The scenes that are not in the registry yet but whose old pictures are here (the content asks for them before the
/// scene is ported): tool/make_old_pictures.dart makes their folders after the registry's scenes.
const Set<String> oldPictureScenes = {'comer'};

/// The size of an old review picture, and of an old cell of the level check.
const int oldReviewWidth = 196, oldReviewHeight = 104;
const int oldLevelWidth = 96, oldLevelHeight = 106;

/// An old picture, decoded: [width] x [height] pixels, each `0xAABBGGRR` (what `PixelView` shows).
class OldPicture {
  OldPicture(this.width, this.height, this.pixels);

  final int width, height;
  final Uint32List pixels;
}

// the package's own assets have no `packages/coqui_scenes/` in front when it is run as the app itself (its dev entry)
Future<ByteData> _read(AssetBundle bundle, String id, String file) async {
  try {
    return await bundle.load(oldPictureAsset(id, file));
  } catch (_) {
    return bundle.load('assets/old_pictures/$id/$file');
  }
}

Uint8List _bytes(ByteData d) =>
    d.buffer.asUint8List(d.offsetInBytes, d.lengthInBytes);

/// The old pictures of the scenes that are not converted yet: each scene's index (picture name to file), and each picture
/// decoded, once. [bundle] is the asset bundle to read from (the root bundle when null).
class OldPictures {
  OldPictures({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  final AssetBundle bundle;

  final Map<String, Future<Map<String, String>>> _indexes = {};
  final Map<String, Future<OldPicture>> _pictures = {};

  /// The index of scene [id]: picture name (`<word>.si`, `<word>.no`, `nivel.<word>.<index>`) to file.
  Future<Map<String, String>> indexOf(String id) => _indexes[id] ??= () async {
    try {
      final text = utf8.decode(_bytes(await _read(bundle, id, 'index.json')));
      return (jsonDecode(text) as Map<String, dynamic>).cast<String, String>();
    } catch (e) {
      _indexes.remove(id);
      throw PictureError('$id: it has no old pictures to show ($e)');
    }
  }();

  /// The old picture [name] of scene [id], decoded.
  Future<OldPicture> picture(String id, String name) {
    final key = '$id/$name';
    return _pictures[key] ??= () async {
      try {
        final file = (await indexOf(id))[name];
        if (file == null) {
          throw PictureError('$id: there is no old picture "$name"');
        }
        return await _decode(_bytes(await _read(bundle, id, file)));
      } catch (e) {
        _pictures.remove(key);
        if (e is PictureError) rethrow;
        throw PictureError('$id: the old picture "$name" cannot be read ($e)');
      }
    }();
  }
}

Future<OldPicture> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final image = (await codec.getNextFrame()).image;
    try {
      final data = await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (data == null) throw PictureError('an old picture cannot be decoded');
      // a copy: the view onto the bytes may not start on a multiple of 4
      final px = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return OldPicture(image.width, image.height, px.buffer.asUint32List());
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
