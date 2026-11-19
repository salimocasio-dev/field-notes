import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_scenes/src/load_scene.dart';
import 'package:coqui_scenes/src/scene_set.dart';
import 'package:coqui_scenes/src/still_frame.dart';
import 'package:coqui_scenes/src/still_host.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// The frame counter of a still review or level picture (order 06: "review pictures at F=8"; frente-preview.html draws
/// its pairs at F 8).
const int pictureF = 8;

/// One picture made ready: the scene's frame, the picture's name in the sheet (`pictures.<word>.<side>`), and the W it
/// draws.
class _Shot {
  _Shot(this.frame, this.name, this.W);

  final StillFrame frame;
  final String name;
  final Map<String, dynamic> W;
}

/// Why a picture cannot be drawn: the scene is not converted, or the sheet does not say which of its pictures a
/// reference is.
class PictureError implements Exception {
  PictureError(this.message);

  final String message;

  @override
  String toString() => message;
}

// JSON-shaped values, deep-copied (the old code's JSON.parse(JSON.stringify(...)))
Object? _copy(Object? v) => v is Map
    ? {for (final e in v.entries) e.key as String: _copy(e.value)}
    : v is List
    ? [for (final e in v) _copy(e)]
    : v;

// one string for a JSON-shaped value, its keys in order, a number written as JavaScript writes it
String _canon(Object? v) {
  if (v is Map) {
    final keys = v.keys.map((k) => k as String).toList()..sort();
    return '{${keys.map((k) => '${jsonEncode(k)}:${_canon(v[k])}').join(',')}}';
  }
  if (v is List) return '[${v.map(_canon).join(',')}]';
  if (v is num) return jsNum(v);
  return jsonEncode(v);
}

/// The pictures other features ask for (page 12, section 3, `PictureSource`), drawn by the converted scenes on a still
/// host: waits return at once, sound is silent. One engine per scene; each state of a set is baked once, on first use or
/// by [warm] (cached by scene and set key, `SetBakes`).
///
/// A review or level picture is cut from the scene's picture as its sheet says (`pictures.<word>.<side>`: a centre and a
/// zoom of 1 or 2; 196 × 104). A [PictureRef] holds a scene, a state and the old view rectangle, not which picture of
/// the sheet it is, so the pictures are found by the review pairs given here ([pairs]): the side of a pair whose scene,
/// state and view are the reference's. [ofPicture] takes the picture's name itself.
class ScenePictures implements PictureSource {
  ScenePictures({
    Iterable<ReviewPair> pairs = const [],
    this.bundle,
    this.still = false,
  }) {
    for (final p in pairs) {
      for (final (side, spec) in [('si', p.yes), ('no', p.no)]) {
        final ref = PictureRef.of(p, spec);
        (_index[_key(ref)] ??= []).add('${p.word}.$side');
      }
    }
  }

  /// Where the scenes' sheets are read from (the root bundle when null).
  final AssetBundle? bundle;

  /// The OS asks for reduced motion: no wind, even in an animated picture.
  final bool still;

  final Map<String, List<String>> _index = {};
  final Map<String, Future<StillFrame>> _frames = {};

  static String _key(PictureRef r) =>
      '${r.scene}|${_canon(r.set)}|${r.cam.map(jsNum).join(',')}';

  /// The frame of scene [id], made once.
  Future<StillFrame> frameOf(String id) => _frames[id] ??= () async {
    final scene = await loadScene(id, bundle: bundle);
    if (scene is! SetScene) {
      throw PictureError('$id: not converted yet');
    }
    final f = StillFrame(scene, still: still);
    f.host.fresh();
    return f;
  }();

  /// The name in the sheet of the picture [ref] is (`<word>.<side>`), from the review pairs.
  String pictureName(PictureRef ref, Sheet sheet) {
    final names = [
      for (final n in _index[_key(ref)] ?? const <String>[])
        if (sheet.pictures.containsKey(n)) n,
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
    }
    w.addAll(own);
    return w;
  }

  Future<_Shot> _prepare(PictureRef ref, String? name) async {
    final frame = await frameOf(ref.scene);
    final sheet = frame.scene.sheet;
    final n = name ?? pictureName(ref, sheet);
    if (!sheet.pictures.containsKey(n)) {
      throw PictureError('${ref.scene}: its sheet has no picture "$n"');
    }
    return _Shot(frame, n, pictureW(frame.scene, ref.set));
  }

  /// Draws [shot] at frame [F] and cuts its picture: 196 × 104 pixels.
  static Uint32List _draw(_Shot shot, int F, {bool wind = false}) {
    final frame = shot.frame;
    frame.draw(
      _copy(shot.W) as Map<String, dynamic>,
      F: F,
      cam: frame.scene.CAM['wide']!,
      tick: wind ? frame.host.TICK : 0,
      allSigns: false,
    );
    return frame.scene.sheet
        .pictureCrop(shot.name, frame.engine, frame.picture)
        .px;
  }

  /// The picture of [ref] (or of the sheet's picture [name]) at frame [F], 196 × 104 pixels, drawn now.
  Future<Uint32List> pixels(
    PictureRef ref, {
    String? name,
    int F = pictureF,
  }) async => _draw(await _prepare(ref, name), F);

  @override
  Future<void> warm(Iterable<PictureRef> refs) async {
    for (final r in refs) {
      final shot = await _prepare(r, null);
      shot.frame.bakes.bake(shot.W);
    }
  }

  @override
  Widget of(
    PictureRef ref, {
    int height = 104,
    int? scale,
    bool animated = false,
  }) => _ScenePicture(
    source: this,
    ref: ref,
    name: null,
    height: height,
    scale: scale,
    animated: animated,
  );

  /// [of] for the sheet's picture [name] (`<word>.<side>`, as `pictures` in the sheet names it).
  Widget ofPicture(
    PictureRef ref,
    String name, {
    int height = 104,
    int? scale,
    bool animated = false,
  }) => _ScenePicture(
    source: this,
    ref: ref,
    name: name,
    height: height,
    scale: scale,
    animated: animated,
  );
}

class _ScenePicture extends StatefulWidget {
  const _ScenePicture({
    required this.source,
    required this.ref,
    required this.name,
    required this.height,
    required this.scale,
    required this.animated,
  });

  final ScenePictures source;
  final PictureRef ref;
  final String? name;
  final int height;
  final int? scale;
  final bool animated;

  @override
  State<_ScenePicture> createState() => _ScenePictureState();
}

class _ScenePictureState extends State<_ScenePicture>
    with SingleTickerProviderStateMixin {
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
        old.ref.toString() != widget.ref.toString() ||
        old.name != widget.name ||
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
      if (widget.height != reviewH) {
        throw PictureError(
          'a review picture is $reviewW x $reviewH (the sheet\'s pictures); height ${widget.height} is not one',
        );
      }
      final shot = await widget.source._prepare(widget.ref, widget.name);
      if (!mounted || gen != _gen) return;
      setState(() {
        _shot = shot;
        _pixels = ScenePictures._draw(shot, _frameNo);
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
    px.setAll(0, ScenePictures._draw(shot, F, wind: !widget.source.still));
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
    Widget child;
    if (err != null) {
      child = AspectRatio(
        aspectRatio: reviewW / reviewH,
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
    } else if (_pixels == null) {
      child = const AspectRatio(aspectRatio: reviewW / reviewH);
    } else {
      child = PixelView(
        pixels: _pixels!,
        width: reviewW,
        height: reviewH,
        repaint: _tick,
      );
    }
    final s = widget.scale;
    if (s == null) return child;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    return SizedBox(width: reviewW * s / dpr, child: child);
  }
}
