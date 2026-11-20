import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/converted_scenes.dart';
import 'package:coqui_scenes/src/load_scene.dart';
import 'package:coqui_scenes/src/old_pictures.dart';
import 'package:coqui_scenes/src/picture_cut.dart';
import 'package:coqui_scenes/src/picture_error.dart';
import 'package:coqui_scenes/src/registry.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/still_frame.dart';
import 'package:coqui_scenes/src/still_host.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// The frame counter of a still review or level picture (order 06: "review pictures at F=8"; frente-preview.html draws
/// its pairs at F 8).
const int pictureF = 8;

/// Where a picture is cut from the scene's picture: the sheet's `crop` for it (its centre is the picture's centre) and
/// its zoom. [name] is the sheet's picture (`<word>.<side>`) or level entry (`nivel.<word>.<index>`) they came from; a
/// [level] cell is drawn at zoom 1 whatever the entry's zoom (picture_cut.dart).
class _Cut {
  _Cut(this.name, this.crop, this.zoom, {this.level = false});

  final String name;
  final List<int> crop;
  final int zoom;
  final bool level;
}

/// One picture made ready: the scene's frame, where its picture is cut from, and the W it draws.
class _Shot {
  _Shot(this.frame, this.cut, this.W);

  final StillFrame frame;
  final _Cut cut;
  final Map<String, dynamic> W;
}

// JSON-shaped values, deep-copied (the old code's JSON.parse(JSON.stringify(...)))
Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

// one string for a JSON-shaped value, its keys in order, a number written as JavaScript writes it
/// The name a review picture has in [sheet]: [n] (`<word>.<side>`) as it is, or, when the sheet has no picture of that
/// name, with its accents folded (`mamá.si` is `mama.si`): La sala's sheet names its pictures so, as sala-preview.html's
/// `PV.pair` finds a pair's pictures (order 31b). [n] as it is when the sheet has neither.
String sheetPictureName(Sheet sheet, String n) {
  if (sheet.pictures.containsKey(n)) return n;
  const from = 'áéíóú', to = 'aeiou';
  final folded = n.split('').map((c) {
    final i = from.indexOf(c);
    return i < 0 ? c : to[i];
  }).join();
  return sheet.pictures.containsKey(folded) ? folded : n;
}

String _canon(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k as String).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_canon(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.map(_canon).join(',')}]';
  if (v is num) return jsNum(v);
  return jsonEncode(v);
}

/// The pictures other features ask for (page 12, section 3, `PictureSource`).
///
/// A converted scene draws its pictures: its engine on a still host (waits return at once, sound is silent), one engine
/// per scene, each state of a set baked once, on first use or by [warm] (cached by scene and set key, `SetBakes`). The
/// picture is cut from the scene's 240 x 216 picture as its sheet says and as the size rule says ([pictureRegion]): the
/// picture is `width` x `height` picture pixels; it shows the region of `width / zoom` x `height / zoom` pixels centred on
/// the centre of the sheet's `crop` for it, each pixel drawn `zoom` x `zoom` (zoom 1 or 2, the sheet's). Never a fraction.
/// A cell of the level check (`nivel.<word>.<index>`) is always zoom 1: a `width` x `height` region at the centre of the
/// level entry's `crop`, one picture pixel per pixel.
///
/// Which picture of the sheet a [PictureRef] is: its [PictureRef.name] (`<word>.si`, `<word>.no`: the sheet's
/// `pictures`; `nivel.<word>.<index>`: the sheet's `level`, which names the pair picture it uses). A reference with no
/// name is found by the review pairs given here ([pairs]): the side of a pair whose scene, state and view are the
/// reference's (it fails when the sheet crops two of them differently). [ofPicture] takes the picture's name itself.
///
/// A scene that is not converted yet shows its old picture (order 06's, `assets/old_pictures/<id>/`), found by the
/// reference's name, in the size it was drawn in (196 x 104 for a review picture, 96 x 106 for a cell of the level
/// check); any other size, and a reference with no name, fail. `animated` does nothing for it.
class ScenePictures implements PictureSource {
  ScenePictures({
    Iterable<ReviewPair> pairs = const [],
    this.bundle,
    this.still = false,
  }) : _old = OldPictures(bundle: bundle) {
    for (final p in pairs) {
      for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
        final ref = PictureRef.of(p, spec);
        (_index[_key(ref)] ??= []).add('${p.word}.$side');
      }
    }
  }

  /// Where the scenes' sheets and old pictures are read from (the root bundle when null).
  final AssetBundle? bundle;

  /// The OS asks for reduced motion: no wind, even in an animated picture.
  final bool still;

  final OldPictures _old;
  final Map<String, List<String>> _index = {};
  final Map<String, Future<StillFrame>> _frames = {};

  static String _key(PictureRef r) =>
      '${r.scene}|${_canon(r.set)}|${r.cam.map(jsNum).join(',')}';

  /// The frame of scene [id] (a converted scene), made once.
  Future<StillFrame> frameOf(String id) {
    if (!convertedScenes.contains(id)) {
      return Future.error(PictureError('$id: not converted yet'));
    }
    return _frames[id] ??= () async {
      final scene = await loadScene(id, bundle: bundle);
      if (scene is! SetScene) {
        throw PictureError('$id: not converted yet');
      }
      final f = StillFrame(scene, still: still);
      f.host.fresh();
      return f;
    }();
  }

  /// The name in the sheet of the picture [ref] is (`<word>.<side>`), from the review pairs: the fallback for a reference
  /// that has no name.
  String pictureName(PictureRef ref, Sheet sheet) {
    final names = [
      for (final n0 in _index[_key(ref)] ?? const <String>[])
        if (sheet.pictures.containsKey(sheetPictureName(sheet, n0)))
          sheetPictureName(sheet, n0),
    ];
    if (names.isEmpty) {
      throw PictureError(
        '${ref.scene}: no picture of its sheet is this reference ($ref)',
      );
    }
    final crops = {
      for (final n in names)
        '${sheet.pictures[n]!.zoom}:${sheet.pictures[n]!.crop.join(',')}',
    };
    if (crops.length > 1) {
      throw PictureError(
        '${ref.scene}: this reference is ${names.join(' and ')}, which the sheet crops differently ($ref)',
      );
    }
    return names.first;
  }

  // the sheet's picture [n] (`<word>.<side>`), or its level entry (`nivel.<word>.<index>`: its own centre; the cell is always zoom 1)
  _Cut _cutNamed(Sheet sheet, String scene, String n0) {
    final n = sheetPictureName(sheet, n0);
    final pic = sheet.pictures[n];
    if (pic != null) return _Cut(n, pic.crop, pic.zoom);
    if (n.startsWith('nivel.')) {
      final rest = n.substring('nivel.'.length), dot = rest.lastIndexOf('.');
      final index = dot < 0 ? null : int.tryParse(rest.substring(dot + 1));
      if (index != null) {
        final word = rest.substring(0, dot);
        for (final l in sheet.level) {
          if (l.word == word && l.index == index) {
            return _Cut(n, l.crop, l.zoom, level: true);
          }
        }
      }
    }
    throw PictureError('$scene: its sheet has no picture "$n"');
  }

  // cual.js: panelW. The world of a review picture: the scene's fresh world, the frog where a pair picture has him
  // (the sheet's code entry for cual.js:21), seen only with answer bubbles, then the picture's own state, every
  // position in it passed through the scene's remap.
  static Map<String, dynamic> pictureW(
    SetScene scene,
    Map<String, dynamic> set,
  ) {
    final f = frogOfCode(scene.sheet, scene.projection, 'cual.js:21');
    final w = <String, dynamic>{
      'cq': <String, dynamic>{
        'x': 0,
        'y': 0,
        's': 1,
        'dy': 0,
        'al': 1,
        'vis': 0,
        'bub': null,
      },
      'spot': null,
      'twinkle': null,
      'fx': <Map<String, dynamic>>[],
      'heart': 0,
      'lost': 0,
      'resp': null,
      ...scene.fresh(const {}),
    };
    w['cq'] = <String, dynamic>{
      'x': f.x,
      'y': f.y,
      's': f.scale,
      'dy': 0,
      'al': 1,
      'vis': jsTruthy(set['resp']) ? 1 : 0,
      'bub': null,
    };
    final own = _copy(set) as Map<String, dynamic>;
    for (final v in own.values) {
      if (v is Map && v['x'] is num && v['y'] is num) {
        final r = scene.remap([v['x'] as num, v['y'] as num]);
        v['x'] = r[0];
        v['y'] = r[1];
        if (r.length > 2) v['s'] = r[2];
      }
      // a list of things placed by their x alone (El balcón's glasses and jugs on the table: the remap's `x` kind)
      if (v is List) {
        for (final t in v) {
          if (t is Map && t['x'] is num && !t.containsKey('y')) {
            t['x'] = scene.remap([t['x'] as num])[0];
          }
        }
      }
    }
    w.addAll(own);
    return w;
  }

  // a converted scene's picture, ready to draw: [name] (ofPicture) wins over the reference's own name, which wins over
  // the review pairs
  Future<_Shot> _prepare(PictureRef ref, String? name) async {
    final frame = await frameOf(ref.scene);
    final sheet = frame.scene.sheet;
    final cut = _cutNamed(
      sheet,
      ref.scene,
      name ?? ref.name ?? pictureName(ref, sheet),
    );
    return _Shot(frame, cut, pictureW(frame.scene, ref.set));
  }

  // an old picture of a scene that is not converted yet; [width] x [height] null: whatever size it is (to decode ahead)
  Future<OldPicture> _oldOf(
    PictureRef ref,
    String? name,
    int? width,
    int? height,
  ) async {
    final id = ref.scene;
    if (!sceneRegistry.containsKey(id)) {
      throw PictureError('"$id" is not a scene');
    }
    final n = name ?? ref.name;
    if (n == null) {
      throw PictureError(
        '$id: not converted yet, so its pictures are the old ones, found by name; this reference has no name: make it with '
        'PictureRef.of or PictureRef.ofLevel ($ref)',
      );
    }
    final pic = await _old.picture(id, n);
    if (width != null && (pic.width != width || pic.height != height)) {
      throw PictureError(
        '$id: not converted yet; its old picture "$n" is ${pic.width} x ${pic.height}, and a $width x $height picture '
        'cannot be made of it',
      );
    }
    return pic;
  }

  /// Draws [shot] at frame [F] and cuts its picture: [width] x [height] pixels.
  static Uint32List _draw(
    _Shot shot,
    int F,
    int width,
    int height, {
    bool wind = false,
  }) {
    final frame = shot.frame;
    frame.draw(
      _copy(shot.W) as Map<String, dynamic>,
      F: F,
      cam: frame.scene.CAM['wide']!,
      tick: wind ? frame.host.TICK : 0,
      allSigns: false,
    );
    final sheet = frame.scene.sheet;
    return cutPicture(
      frame.picture,
      crop: shot.cut.crop,
      zoom: shot.cut.zoom,
      level: shot.cut.level,
      width: width,
      height: height,
      picW: sheet.pictureW,
      picH: sheet.pictureH,
    );
  }

  /// The picture of [ref] (or of the sheet's picture [name]) at frame [F], [width] x [height] pixels, drawn now (a scene
  /// that is not converted: its old picture, which has the size it was drawn in).
  Future<Uint32List> pixels(
    PictureRef ref, {
    String? name,
    int F = pictureF,
    int width = reviewW,
    int height = reviewH,
  }) async {
    if (!convertedScenes.contains(ref.scene)) {
      final old = await _oldOf(ref, name, width, height);
      return Uint32List.fromList(old.pixels);
    }
    return _draw(await _prepare(ref, name), F, width, height);
  }

  @override
  Future<void> warm(Iterable<PictureRef> refs) async {
    for (final r in refs) {
      if (!convertedScenes.contains(r.scene)) {
        await _oldOf(r, null, null, null);
        continue;
      }
      final shot = await _prepare(r, null);
      shot.frame.bakes.bake(shot.W);
    }
  }

  @override
  Widget of(
    PictureRef ref, {
    int width = reviewW,
    int height = reviewH,
    bool animated = false,
  }) => _ScenePicture(
    source: this,
    ref: ref,
    name: null,
    width: width,
    height: height,
    animated: animated,
  );

  /// [of] for the sheet's picture [name] (`<word>.<side>` or `nivel.<word>.<index>`, as the sheet names them).
  Widget ofPicture(
    PictureRef ref,
    String name, {
    int width = reviewW,
    int height = reviewH,
    bool animated = false,
  }) => _ScenePicture(
    source: this,
    ref: ref,
    name: name,
    width: width,
    height: height,
    animated: animated,
  );
}

class _ScenePicture extends StatefulWidget {
  const _ScenePicture({
    required this.source,
    required this.ref,
    required this.name,
    required this.width,
    required this.height,
    required this.animated,
  });

  final ScenePictures source;
  final PictureRef ref;
  final String? name;
  final int width;
  final int height;
  final bool animated;

  @override
  State<_ScenePicture> createState() => _ScenePictureState();
}

// A TickerProviderStateMixin, not a single-ticker one: a picture handed another picture in place (`didUpdateWidget`)
// disposes its ticker and starts another, and a single-ticker state refuses a second ticker in its life.
class _ScenePictureState extends State<_ScenePicture>
    with TickerProviderStateMixin {
  _Shot? _shot;
  Uint32List? _pixels;
  Object? _error;
  final ValueNotifier<int> _tick = ValueNotifier<int>(0);
  Ticker? _ticker;
  int _frameNo = pictureF;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_ScenePicture old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source ||
        old.ref != widget.ref ||
        old.name != widget.name ||
        old.width != widget.width ||
        old.height != widget.height ||
        old.animated != widget.animated) {
      _ticker?.dispose();
      _ticker = null;
      _shot = null;
      _pixels = null;
      _error = null;
      _frameNo = pictureF;
      _start();
    }
  }

  // a newer start (the widget changed meanwhile) wins
  int _gen = 0;

  Future<void> _start() async {
    final gen = ++_gen;
    try {
      final source = widget.source;
      if (!convertedScenes.contains(widget.ref.scene)) {
        // its old picture: shown as it is (the sheet and the engine are not asked); `animated` does nothing
        final old = await source._oldOf(
          widget.ref,
          widget.name,
          widget.width,
          widget.height,
        );
        if (!mounted || gen != _gen) return;
        setState(() => _pixels = old.pixels);
        return;
      }
      final shot = await source._prepare(widget.ref, widget.name);
      // the size rule fails before anything is drawn
      pictureRegion(
        crop: shot.cut.crop,
        zoom: shot.cut.zoom,
        level: shot.cut.level,
        width: widget.width,
        height: widget.height,
        picW: shot.frame.scene.sheet.pictureW,
        picH: shot.frame.scene.sheet.pictureH,
      );
      if (!mounted || gen != _gen) return;
      setState(() {
        _shot = shot;
        _pixels = ScenePictures._draw(
          shot,
          _frameNo,
          widget.width,
          widget.height,
        );
      });
      if (widget.animated) {
        final ticker = createTicker(_onTick);
        _ticker = ticker;
        unawaited(ticker.start());
      }
    } catch (e) {
      if (mounted && gen == _gen) setState(() => _error = e);
    }
  }

  // juego.js: one frame a tick (TICK ms): the wind and the scene's own idle motion go on
  void _onTick(Duration elapsed) {
    final shot = _shot, px = _pixels;
    if (shot == null || px == null) return;
    final F = pictureF + elapsed.inMilliseconds ~/ shot.frame.host.TICK;
    if (F == _frameNo) return;
    _frameNo = F;
    px.setAll(
      0,
      ScenePictures._draw(
        shot,
        F,
        widget.width,
        widget.height,
        wind: !widget.source.still,
      ),
    );
    _tick.value++;
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final err = _error;
    final aspect = widget.width / widget.height;
    if (err != null) {
      return AspectRatio(
        aspectRatio: aspect,
        child: ColoredBox(
          color: const Color(0xFF3A1E24),
          child: Center(
            child: Text(
              '$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11),
            ),
          ),
        ),
      );
    }
    final px = _pixels;
    if (px == null) return AspectRatio(aspectRatio: aspect);
    return PixelView(
      pixels: px,
      width: widget.width,
      height: widget.height,
      repaint: _tick,
    );
  }
}
