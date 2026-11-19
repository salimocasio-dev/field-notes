// The sheet's own names are kept (`S`, `setKey`, `lugar`, `fromW`): the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_pixel/src/camera.dart';
import 'package:coqui_pixel/src/frame.dart';
import 'package:coqui_pixel/src/pp_engine.dart';
import 'package:coqui_pixel/src/sprite.dart';

/// Something is wrong with a sheet, or the sheet does not say. The message names the path in the sheet, or the
/// position or name that was asked for. A builder who gets one stops: the sheet is not guessed at.
class SheetError implements Exception {
  SheetError(this.message);

  final String message;

  @override
  String toString() => 'SheetError: $message';
}

// ---------------------------------------------------------------------------------------------------------------------
// reading: each reader names where it is in the sheet when a value is not what the format says

String _what(Object? v) => v == null
    ? 'null'
    : v is String
    ? 'a string'
    : v is num
    ? 'a number'
    : v is bool
    ? 'a boolean'
    : v is List
    ? 'a list'
    : 'an object';

Map<String, dynamic> _obj(Object? v, String at) {
  if (v is Map<String, dynamic>) return v;
  throw SheetError('$at: an object was expected, found ${_what(v)}');
}

List<dynamic> _list(Object? v, String at) {
  if (v is List<dynamic>) return v;
  throw SheetError('$at: a list was expected, found ${_what(v)}');
}

String _str(Object? v, String at) {
  if (v is String) return v;
  throw SheetError('$at: a string was expected, found ${_what(v)}');
}

num _num(Object? v, String at) {
  if (v is num) return v;
  throw SheetError('$at: a number was expected, found ${_what(v)}');
}

int _int(Object? v, String at) {
  final n = _num(v, at);
  if (n != n.truncateToDouble()) {
    throw SheetError('$at: a whole number was expected, found $n');
  }
  return n.toInt();
}

bool _bool(Object? v, String at) {
  if (v is bool) return v;
  throw SheetError('$at: true or false was expected, found ${_what(v)}');
}

void _length(List<dynamic> l, int? length, String at) {
  if (length != null && l.length != length) {
    throw SheetError('$at: $length numbers were expected, found ${l.length}');
  }
}

List<num> _nums(Object? v, String at, {int? length}) {
  final l = _list(v, at);
  _length(l, length, at);
  return [for (var i = 0; i < l.length; i++) _num(l[i], '$at[$i]')];
}

List<double> _doubles(Object? v, String at, {int? length}) => [
  for (final n in _nums(v, at, length: length)) n.toDouble(),
];

List<int> _ints(Object? v, String at, {int? length}) {
  final l = _list(v, at);
  _length(l, length, at);
  return [for (var i = 0; i < l.length; i++) _int(l[i], '$at[$i]')];
}

List<String> _strs(Object? v, String at) {
  final l = _list(v, at);
  return [for (var i = 0; i < l.length; i++) _str(l[i], '$at[$i]')];
}

Object? _need(Map<String, dynamic> m, String key, String at) {
  if (!m.containsKey(key)) throw SheetError('$at.$key: is missing');
  return m[key];
}

T? _opt<T>(Map<String, dynamic> m, String key, T Function(Object?) read) =>
    m.containsKey(key) ? read(m[key]) : null;

Map<String, T> _byName<T>(
  Object? v,
  String at,
  T Function(String name, Map<String, dynamic> m, String at) make,
) {
  final m = _obj(v, at);
  return {
    for (final e in m.entries)
      e.key: make(e.key, _obj(e.value, '$at.${e.key}'), '$at.${e.key}'),
  };
}

// ---------------------------------------------------------------------------------------------------------------------
// the parts of a sheet

/// A world box, as the engine's `box` takes it: `x0, y0, z0, x1, y1, z1`; and the screen box of it that the sheet says.
class SheetHit {
  SheetHit._(this.world, this.box);

  /// `x0, y0, z0, x1, y1, z1`.
  final List<double> world;

  /// The sheet's screen box of [world]: `[x, y, w, h]`.
  final List<int> box;
}

/// Where abuela's box is at one of her places: from a frame (the old box moved by the frame's offset) or the opening of
/// a clip (the window).
class SheetPlaceBox {
  SheetPlaceBox._(this.frame, this.clip, this.old, this.box, this.what);

  /// The name of the frame (a key of [Sheet.frames]), or null.
  final String? frame;

  /// The name of the clip (a key of [Sheet.clips]), or null.
  final String? clip;

  /// The old box.
  final List<num> old;

  /// The new box (`new` in the sheet), when the sheet gives one.
  final List<int>? box;
  final String? what;
}

/// A shape in screen space: the sun's touch circle `[x, y, r]` and its box.
class SheetScreenShape {
  SheetScreenShape._(this.circle, this.box);

  final List<num> circle;
  final List<int> box;
}

/// One of the touch keys of the scene (`things`). Three kinds: part of the set (`set`, with a world box, or, for the
/// sun, a shape in the screen-space sky), a sprite (`sprite`: it moves; its box is made from the sprite), or drawn on
/// the display (`hud`).
class SheetThing {
  SheetThing._(
    this.id,
    this.set,
    this.sprite,
    this.hud,
    this.sky,
    this.world,
    this.box,
    this.hit,
    this.places,
    this.screen,
    this.old,
    this.what,
    this.why,
    this.raw,
  );

  final String id;

  /// It is part of the set: it has a world box (or, with [sky], a shape on the screen).
  final bool set;

  /// It stays in the sprite layer: today's sprite, its box made from it.
  final bool sprite;

  /// It is on the display, not in the picture.
  final bool hud;

  /// It lives in the sky, which is screen space.
  final bool sky;

  /// The world box, `x0, y0, z0, x1, y1, z1`, of a thing in the set.
  final List<double>? world;

  /// The sheet's screen box of [world]: `[x, y, w, h]`.
  final List<int>? box;

  /// What a touch hits, as a world box and its screen box.
  final SheetHit? hit;

  /// abuela only: her box at each of her places (`puerta`, `paso`, `ventana`).
  final Map<String, SheetPlaceBox>? places;

  /// The sun only: its shape in screen space.
  final SheetScreenShape? screen;

  /// The old numbers (`box`, `hit`, `circle`), as the sheet has them.
  final Map<String, dynamic>? old;
  final String? what, why;

  /// The thing as the sheet has it, every field.
  final Map<String, dynamic> raw;
}

/// A place a character stands, or the bird sits: a world point (`spots`: `scale` is the frog's, `frog` is where his
/// box goes, `abuela` where her sprite is drawn; `points`: `frame` and `nudge` say how it was made).
class SheetAnchor {
  SheetAnchor._(
    this.name,
    this.world,
    this.screen,
    this.old,
    this.what,
    this.scale,
    this.frog,
    this.abuela,
    this.frame,
    this.nudge,
    this.raw,
  );

  final String name;

  /// `x, y, z`.
  final List<double> world;

  /// The sheet's screen position of it (what [Sheet.screenOf] gives, rounded to hundredths; for a point made through
  /// a frame, the old point plus the frame's offset, which is the one to use).
  final List<double> screen;

  /// The old screen position.
  final List<num> old;
  final String? what;

  /// The frog's size there (a spot of the frog's).
  final num? scale;

  /// The frog's `q.x`, `q.y` there, and abuela's sprite's top left there.
  final List<int>? frog, abuela;

  /// A point made through a frame: its name, and the extra whole pixels.
  final String? frame;
  final List<num>? nudge;
  final Map<String, dynamic> raw;
}

/// `lugar`: a name of the old scene's `LUGAR`: the spot, where the frog's box is, his size.
class SheetLugar {
  SheetLugar._(this.name, this.spot, this.frog, this.scale, this.raw);

  final String name;

  /// A key of [Sheet.spots].
  final String spot;

  /// The frog's `q.x`, `q.y`.
  final List<int> frog;
  final num scale;
  final Map<String, dynamic> raw;
}

/// A translation frame: an old anchor and the new place of the same thing; every old point of the frame moves by
/// [offset].
class SheetFrame {
  SheetFrame._(
    this.name,
    this.old,
    this.world,
    this.spot,
    this.nudge,
    this.screen,
    this.offset,
    this.what,
    this.raw,
  );

  final String name;
  final List<num> old;

  /// Where it is in the world (a frame anchored on the set), or the name of the spot (a frame anchored on a character).
  final List<double>? world;
  final String? spot;
  final List<num>? nudge;

  /// The new place of [old], and the whole-pixel move from one to the other.
  final List<double> screen;
  final List<int> offset;
  final String? what;
  final Map<String, dynamic> raw;
}

/// A view of the scene (`CAM`): a centre in the world and a zoom of 1 or 2.
class SheetView {
  SheetView._(
    this.name,
    this.world,
    this.screen,
    this.zoom,
    this.x0,
    this.region,
    this.old,
    this.what,
    this.raw,
  );

  final String name;
  final List<double> world;
  final List<double> screen;

  /// 1: the 196 × 216 window at [x0]. 2: the 98 × 108 [region].
  final int zoom;
  final int x0;
  final List<int>? region;
  final List<num> old;
  final String? what;
  final Map<String, dynamic> raw;

  /// The camera value the sheet records: `[x, y, w, h]`.
  List<int> get cam => region ?? [x0, 0, displayW, displayH];
}

/// A review-pair picture: a centre and a zoom, and the crop the sheet records.
class SheetPicture {
  SheetPicture._(
    this.name,
    this.world,
    this.screen,
    this.zoom,
    this.crop,
    this.what,
    this.raw,
  );

  final String name;
  final List<double> world;
  final List<double> screen;
  final int zoom;

  /// `[x, y, w, h]`: 196 × 104 at zoom 1, 98 × 52 at zoom 2.
  final List<int> crop;
  final String? what;
  final Map<String, dynamic> raw;
}

/// A level-check picture: which review picture, in which word, and its crop.
class SheetLevel {
  SheetLevel._(
    this.word,
    this.index,
    this.picture,
    this.crop,
    this.zoom,
    this.old,
    this.raw,
  );

  /// The level word (`w`), the picture's place in it (`index`), and the key of [Sheet.pictures] it is.
  final String word;
  final int index;
  final String picture;
  final List<int> crop;
  final int zoom;

  /// The old crop rectangle of the level file.
  final List<num> old;
  final Map<String, dynamic> raw;
}

/// A clip region: a world polygon (four points) on a wall, as the old code clipped to a rectangle.
class SheetClip {
  SheetClip._(
    this.name,
    this.thing,
    this.face,
    this.world,
    this.screen,
    this.box,
    this.what,
    this.raw,
  );

  final String name;

  /// The thing it belongs to, and what part of it (`opening`, `gap`): names, as the sheet gives them.
  final String thing;
  final String face;

  /// The world points `x, y, z`, in order round the polygon.
  final List<List<double>> world;

  /// The sheet's screen points of them (hundredths), and the box of those.
  final List<List<double>> screen;
  final List<int> box;
  final String? what;
  final Map<String, dynamic> raw;
}

/// What the position a story or pair file writes is, today: one of `point` (a screen point of the old scene, with its
/// world point), `view` (a view of the sheet), `spot` (a spot of the sheet) or `none` (nothing: the position is
/// not used).
class RemapTo {
  RemapTo._(this.point, this.world, this.view, this.spot, this.none);

  final String? point;
  final List<double>? world;
  final String? view;
  final String? spot;

  /// Why nothing: the sheet's words.
  final String? none;
}

/// One entry of `remap`: a position written in a story, pair or level file, and its place today.
///
/// The table is keyed by [kind] and [old]: `point` (a frog's or bird's `x, y`: two numbers), `cam` (a pair picture's or a
/// story's rectangle `x, y, w, h`), `crop` (a level picture's rectangle `x, y, w, h`), `x` (a position's `x` only).
class SheetRemap {
  SheetRemap._(
    this.kind,
    this.old,
    this.uses,
    this.to,
    this.screen,
    this.crop,
    this.x,
    this.frog,
    this.scale,
    this.x0,
    this.what,
    this.raw,
  );

  final String kind;
  final List<num> old;

  /// Where it is written: files and keys, as strings.
  final List<String> uses;
  final RemapTo to;

  /// Its screen position, and what the kind needs of it: `crop` (a review crop: `cam` and `crop` kinds), `x` (the
  /// `x` kind), `frog` and `scale` (a `point` that is a spot), `x0` (a story's own wide view).
  final List<double>? screen;
  final List<int>? crop;
  final int? x;
  final List<int>? frog;
  final num? scale;
  final int? x0;
  final String? what;
  final Map<String, dynamic> raw;
}

/// How one parameter of the set's key reads W (`setKey.params`).
class SetKeyParam {
  SetKeyParam._(this.name, this.values, this.fromW, this.raw);

  final String name;

  /// The values it takes, as the strings of the state's name.
  final List<String> values;

  /// How W gives it: the sheet's words. The function from W to the key is the scene's, written from these.
  final String fromW;
  final Map<String, dynamic> raw;
}

/// One baked state: the reference folder and the page's query that made it.
class SheetBaked {
  SheetBaked._(this.ref, this.query);

  final String ref;
  final String query;
}

/// The set's states and how W maps to them (`setKey`): the parameters, the key's shape, the states baked.
class SheetSetKey {
  SheetSetKey._(
    this.params,
    this.key,
    this.baked,
    this.bakedWhy,
    this.notRead,
    this.old,
    this.raw,
  );

  /// In the sheet's order: `door`, `win`, `lights`, `sky`, `hide`, `rustle`, `side`.
  final Map<String, SetKeyParam> params;
  final String key;

  /// The states the stories, pairs and level pictures reach.
  final List<SheetBaked> baked;
  final String? bakedWhy, notRead, old;
  final Map<String, dynamic> raw;
}

/// Who casts a shadow (`shadows.<who>`): the radius as a number, and the sheet's words for where, when and how.
class SheetShadow {
  SheetShadow._(this.who, this.radius, this.at, this.when, this.cast, this.raw);

  final String who;
  final double radius;

  /// Where (`at`), when (`when`) and how (`cast`: the `castShadow` calls, heights included, in words). The scene
  /// decides when; the heights are only in [cast].
  final String? at, when, cast;
  final Map<String, dynamic> raw;
}

/// What a screen position of the old scene file becomes (`code`): the old file's line, the old numbers in words, and
/// what replaces them. Data for the porting builder, as the sheet has it.
class SheetCode {
  SheetCode._(this.line, this.old, this.to, this.note, this.raw);

  /// The old file's line (a number), or a line of another file (`"juego.js:16"`).
  final Object line;
  final String old;

  /// A string (what happens to it: `"sky: unchanged"`, `"dropped: the set"`) or an object (`point`, `spot`, `frame`,
  /// `clip`, `thing`, `view` with its numbers).
  final Object? to;
  final String? note;
  final Map<String, dynamic> raw;
}

// ---------------------------------------------------------------------------------------------------------------------

/// A sheet: the data of a scene's set (`<id>-sheet.json`), page 12 section 5. Parsed from the text of the file, which the
/// caller reads. It keeps every field it does not know in [raw] (and [unknown] for the top level) and ignores them.
///
/// Positions are world points. What a scene needs on the screen it asks the engine for ([boxOf], [screenOf], [viewOf],
/// ...): the sheet's own screen numbers are kept as data, to check against and for the places that use them as they are
/// (a point made through a frame).
class Sheet {
  Sheet._({
    required this.scene,
    required this.made,
    required this.S,
    required this.originX,
    required this.originY,
    required this.pictureW,
    required this.pictureH,
    required this.viewW,
    required this.viewH,
    required this.pairW,
    required this.pairH,
    required this.rules,
    required this.setKey,
    required this.things,
    required this.spots,
    required this.lugar,
    required this.frames,
    required this.points,
    required this.views,
    required this.remapTable,
    required this.pictures,
    required this.level,
    required this.clips,
    required this.front,
    required this.frontWhy,
    required this.shadows,
    required this.shadowsNote,
    required this.dropped,
    required this.code,
    required this.raw,
    required this.unknown,
  });

  /// Parses the text of a sheet. Throws [SheetError], naming where, when it is not a sheet.
  factory Sheet.parse(String json) {
    final Object? v;
    try {
      v = jsonDecode(json);
    } on FormatException catch (e) {
      throw SheetError('the sheet is not JSON: ${e.message}');
    }
    return Sheet.fromJson(v);
  }

  /// A sheet from decoded JSON.
  factory Sheet.fromJson(Object? json) {
    final m = _obj(json, 'the sheet');
    const at = r'$';
    final origin = _obj(_need(m, 'origin', at), '$at.origin');
    final picture = _ints(_need(m, 'picture', at), '$at.picture', length: 2);
    final view = _ints(_need(m, 'view', at), '$at.view', length: 2);
    final pair = _ints(
      _need(m, 'pairPicture', at),
      '$at.pairPicture',
      length: 2,
    );
    final rules = _obj(_need(m, 'rules', at), '$at.rules');
    final pictures = _byName(
      _need(m, 'pictures', at),
      '$at.pictures',
      _readPicture,
    );
    final front = _obj(_need(m, 'front', at), '$at.front');
    final shadowsRaw = _obj(_need(m, 'shadows', at), '$at.shadows');
    const known = {
      'scene',
      'made',
      'S',
      'origin',
      'picture',
      'view',
      'pairPicture',
      'rules',
      'setKey',
      'things',
      'spots',
      'lugar',
      'frames',
      'points',
      'views',
      'remap',
      'pictures',
      'level',
      'clips',
      'front',
      'shadows',
      'dropped',
      'code',
    };
    final sheet = Sheet._(
      scene: _str(_need(m, 'scene', at), '$at.scene'),
      made: _str(_need(m, 'made', at), '$at.made'),
      S: _num(_need(m, 'S', at), '$at.S').toDouble(),
      originX: _num(
        _need(origin, 'originX', '$at.origin'),
        '$at.origin.originX',
      ).toDouble(),
      originY: _num(
        _need(origin, 'originY', '$at.origin'),
        '$at.origin.originY',
      ).toDouble(),
      pictureW: picture[0],
      pictureH: picture[1],
      viewW: view[0],
      viewH: view[1],
      pairW: pair[0],
      pairH: pair[1],
      rules: {
        for (final e in rules.entries)
          e.key: _str(e.value, '$at.rules.${e.key}'),
      },
      setKey: _readSetKey(_need(m, 'setKey', at), '$at.setKey'),
      things: _byName(_need(m, 'things', at), '$at.things', _readThing),
      spots: _byName(_need(m, 'spots', at), '$at.spots', _readSpot),
      lugar: _byName(_need(m, 'lugar', at), '$at.lugar', _readLugar),
      frames: _byName(_need(m, 'frames', at), '$at.frames', _readFrame),
      points: _byName(_need(m, 'points', at), '$at.points', _readPoint),
      views: _byName(_need(m, 'views', at), '$at.views', _readView),
      remapTable: _readRemapTable(_need(m, 'remap', at), '$at.remap'),
      pictures: pictures,
      level: _readLevelList(_need(m, 'level', at), '$at.level', pictures),
      clips: _byName(_need(m, 'clips', at), '$at.clips', _readClip),
      front: _strs(_need(front, 'things', '$at.front'), '$at.front.things'),
      frontWhy: _opt(front, 'why', (v) => _str(v, '$at.front.why')),
      shadows: {
        for (final e in shadowsRaw.entries)
          if (e.value is Map<String, dynamic> &&
              (e.value as Map<String, dynamic>).containsKey('radius'))
            e.key: _readShadow(
              e.key,
              e.value as Map<String, dynamic>,
              '$at.shadows.${e.key}',
            ),
      },
      shadowsNote: shadowsRaw.containsKey('dropped')
          ? _str(shadowsRaw['dropped'], '$at.shadows.dropped')
          : null,
      dropped: _strs(_need(m, 'dropped', at), '$at.dropped'),
      code: _readCodeList(_need(m, 'code', at), '$at.code'),
      raw: m,
      unknown: {
        for (final e in m.entries)
          if (!known.contains(e.key)) e.key: e.value,
      },
    );
    sheet._checkReferences();
    return sheet;
  }

  /// The scene's id (`frente`) and how the sheet was made.
  final String scene, made;

  /// The engine's scale, and its origin: `PpEngine(w: pictureW, h: pictureH, s: S, originX: originX, originY: originY)`
  /// projects as the sheet's numbers do.
  final double S, originX, originY;

  /// The picture (240 × 216), the view (the display, 196 × 216), the review and level picture (196 × 104).
  final int pictureW, pictureH, viewW, viewH, pairW, pairH;

  /// The rules the sheet states in words (`project`, `frog`, `abuela`, `bird`, `frame`, `sky`, `view`, `viewChange`, `pair`).
  /// `viewChange` is documentation: a slide between views of one zoom, a cut between two zooms (`CamSlide`).
  final Map<String, String> rules;

  /// The set's states and how W maps to them: a table, not the function (the scene writes that from it).
  final SheetSetKey setKey;

  /// The touch keys: 14 for El frente.
  final Map<String, SheetThing> things;

  /// Where the characters stand (`spots`), and the old `LUGAR` names (`lugar`).
  final Map<String, SheetAnchor> spots;
  final Map<String, SheetLugar> lugar;

  /// The translation frames (`frames`) and the named points (`points`).
  final Map<String, SheetFrame> frames;
  final Map<String, SheetAnchor> points;

  /// The views (`CAM` and the stories' own).
  final Map<String, SheetView> views;

  /// The `remap` table, in the sheet's order.
  final List<SheetRemap> remapTable;

  /// The review-pair pictures, by `<word>.<side>`, and the level-check pictures.
  final Map<String, SheetPicture> pictures;
  final List<SheetLevel> level;

  /// The clip regions, by name.
  final Map<String, SheetClip> clips;

  /// `front`: the things that cover a character (none, for El frente) and why.
  final List<String> front;
  final String? frontWhy;

  /// Who casts a shadow, and the note the sheet adds (`dropped`).
  final Map<String, SheetShadow> shadows;
  final String? shadowsNote;

  /// The old code the set replaces, as the sheet lists it (`dropped`), and every old line with what replaces it (`code`).
  final List<String> dropped;
  final List<SheetCode> code;

  /// The sheet as decoded, every field; and the top-level fields this reader does not know.
  final Map<String, dynamic> raw;
  final Map<String, dynamic> unknown;

  // -------------------------------------------------------------------------------------------------------------------
  // what the engine gives

  SheetThing _thingNamed(String key) =>
      things[key] ?? (throw SheetError('the sheet has no thing "$key"'));

  /// The screen bounding box of a world box, from the engine's projection of its 8 corners, as the sheet makes it
  /// (page 11-pixel-engine, decision 12): `[floor(min x), floor(min y), ceil(max x) - floor(min x), ceil(max y) - floor(min y)]`.
  static List<int> boxOfWorld(PpEngine e, List<num> world) {
    final xs = <double>[], ys = <double>[];
    for (final x in [world[0], world[3]]) {
      for (final y in [world[1], world[4]]) {
        for (final z in [world[2], world[5]]) {
          final p = e.project(x, y, z);
          xs.add(p.sx);
          ys.add(p.sy);
        }
      }
    }
    return _boxOf(xs, ys);
  }

  /// The box of some screen points: floor of the least, ceil of the greatest.
  static List<int> boxOfPoints(Iterable<({double sx, double sy})> points) =>
      _boxOf([for (final p in points) p.sx], [for (final p in points) p.sy]);

  static List<int> _boxOf(List<double> xs, List<double> ys) {
    final x0 = xs.reduce(math.min).floor(), y0 = ys.reduce(math.min).floor();
    return [
      x0,
      y0,
      xs.reduce(math.max).ceil() - x0,
      ys.reduce(math.max).ceil() - y0,
    ];
  }

  /// The screen box of a touch key. For a thing in the set: the box of its world box ([boxOfWorld]). For the sun, its
  /// box in the screen-space sky. Throws [SheetError] for a sprite or the hud: they have no box in the set.
  List<int> boxOf(String key, PpEngine e) {
    final t = _thingNamed(key);
    if (t.world != null) return boxOfWorld(e, t.world!);
    if (t.screen != null) return t.screen!.box;
    throw SheetError(
      'thing "$key" is not in the set: it is a ${t.sprite
          ? 'sprite'
          : t.hud
          ? 'hud'
          : 'thing without a box'}, its box is not here',
    );
  }

  /// The screen box a touch hits ([SheetThing.hit]): the box of its world box. Null for a thing with none (the sun's
  /// hit is a circle: see [SheetThing.screen]).
  List<int>? hitBoxOf(String key, PpEngine e) {
    final h = _thingNamed(key).hit;
    return h == null ? null : boxOfWorld(e, h.world);
  }

  /// The world box of a thing in the set, or null.
  List<double>? worldOf(String key) => _thingNamed(key).world;

  /// The anchor [name] of [spots] or [points] (they share no name).
  SheetAnchor anchor(String name) =>
      spots[name] ??
      points[name] ??
      (throw SheetError('the sheet has no spot or point "$name"'));

  /// The screen position of a spot or a point: the engine's projection of its world point.
  ({double x, double y}) screenOf(String name, PpEngine e) {
    final w = anchor(name).world, p = e.project(w[0], w[1], w[2]);
    return (x: p.sx, y: p.sy);
  }

  /// The screen position the sheet records for a frame. A frame anchored on the set (`world`): the projection of its world
  /// point. A frame anchored on abuela (`spot`): where her sprite is drawn there ([abuelaAt]: its top left), as the sheet
  /// records it.
  ({double x, double y}) frameScreen(String name, PpEngine e) {
    final f =
        frames[name] ?? (throw SheetError('the sheet has no frame "$name"'));
    final w = f.world;
    if (w == null) {
      final a = abuelaAt(f.spot!, e);
      return (x: a.x.toDouble(), y: a.y.toDouble());
    }
    final p = e.project(w[0], w[1], w[2]);
    return (x: p.sx, y: p.sy);
  }

  /// Where the frog's box goes for a spot, and his size there (the sheet's rule: `q.x = round(sx) - 16`,
  /// `q.y = round(sy) - 25`). Throws if the spot has no scale: it is not a spot of the frog's.
  ({int x, int y, num scale}) frogAt(String spot, PpEngine e) {
    final s =
        spots[spot] ?? (throw SheetError('the sheet has no spot "$spot"'));
    final scale = s.scale;
    if (scale == null) {
      throw SheetError('spot "$spot" is not the frog\'s: it has no scale');
    }
    final p = screenOf(spot, e);
    return (
      x: (p.x + 0.5).floor() - 16,
      y: (p.y + 0.5).floor() - 25,
      scale: scale,
    );
  }

  /// Where abuela's sprite is drawn for a spot (`round(sx) - 30`, `round(sy) - 49`): its top left.
  ({int x, int y}) abuelaAt(String spot, PpEngine e) {
    final s =
        spots[spot] ?? (throw SheetError('the sheet has no spot "$spot"'));
    if (s.abuela == null) {
      throw SheetError('spot "$spot" is not abuela\'s');
    }
    final p = screenOf(spot, e);
    return (x: (p.x + 0.5).floor() - 30, y: (p.y + 0.5).floor() - 49);
  }

  /// An old `LUGAR` entry as the scene's `lugar` has it: `[x, y, scale]`, the frog's box and size.
  List<num> lugarOf(String name, PpEngine e) {
    final l =
        lugar[name] ?? (throw SheetError('the sheet has no lugar "$name"'));
    final f = frogAt(l.spot, e);
    return [f.x, f.y, f.scale];
  }

  /// The camera value of a view, `[x, y, w, h]`: [viewAt] of the projection of its world centre at its zoom.
  List<int> viewOf(String name, PpEngine e) {
    final v =
        views[name] ?? (throw SheetError('the sheet has no view "$name"'));
    final p = e.project(v.world[0], v.world[1], v.world[2]);
    return viewAt(p.sx, p.sy, v.zoom);
  }

  /// The region of the picture a review or level picture shows, `[x, y, w, h]`: [reviewRegion] of the projection of its
  /// centre at its zoom.
  List<int> pictureRegion(String name, PpEngine e) {
    final v =
        pictures[name] ??
        (throw SheetError('the sheet has no picture "$name"'));
    final p = e.project(v.world[0], v.world[1], v.world[2]);
    final r = reviewRegion(p.sx, p.sy, v.zoom);
    return [r.x, r.y, r.w, r.h];
  }

  /// The review or level picture itself: 196 × 104 pixels cut from [picture] (`pictureW` × `pictureH` of this
  /// sheet), at the zoom and centre of [name] ([reviewCrop]).
  Sprite pictureCrop(String name, PpEngine e, Uint32List picture) {
    final v =
        pictures[name] ??
        (throw SheetError('the sheet has no picture "$name"'));
    final p = e.project(v.world[0], v.world[1], v.world[2]);
    return reviewCrop(picture, pictureW, pictureH, p.sx, p.sy, v.zoom);
  }

  /// The screen polygon of a clip: the engine's projection of its world points.
  List<({double sx, double sy})> clipPolygon(String name, PpEngine e) {
    final c =
        clips[name] ?? (throw SheetError('the sheet has no clip "$name"'));
    return projectPoints(e, c.world);
  }

  // -------------------------------------------------------------------------------------------------------------------
  // remap

  /// Where a position written in a story, pair or level file is today. Keyed by [kind] (`point`, `cam`, `crop`, `x`)
  /// and the old numbers, as the file writes them. A position the table does not have throws [SheetError] naming it:
  /// the builder stops, it does not guess.
  SheetRemap remap(String kind, List<num> old) {
    for (final r in remapTable) {
      if (r.kind != kind || r.old.length != old.length) continue;
      var same = true;
      for (var i = 0; i < old.length; i++) {
        if (r.old[i] != old[i]) same = false;
      }
      if (same) return r;
    }
    throw SheetError(
      'the sheet of "$scene" does not say where the $kind position $old is today (it is not in remap): stop and ask, do not guess',
    );
  }

  /// A frog's or bird's `x, y` ([remap] of kind `point`).
  SheetRemap remapPoint(num x, num y) => remap('point', [x, y]);

  /// A pair picture's or a story's view rectangle `x, y, w, h` ([remap] of kind `cam`).
  SheetRemap remapCam(List<num> rect) => remap('cam', rect);

  /// A level picture's rectangle `x, y, w, h` ([remap] of kind `crop`).
  SheetRemap remapCrop(List<num> rect) => remap('crop', rect);

  /// A position's `x` alone ([remap] of kind `x`): its new `x`.
  int remapX(num x) => remap('x', [x]).x!;

  // -------------------------------------------------------------------------------------------------------------------
  // reading

  // every name the sheet uses to point at another part must be there
  void _checkReferences() {
    void need(bool ok, String what) {
      if (!ok) throw SheetError(what);
    }

    for (final l in lugar.values) {
      need(spots.containsKey(l.spot), 'lugar "${l.name}": no spot "${l.spot}"');
    }
    for (final f in frames.values) {
      if (f.spot != null) {
        need(
          spots.containsKey(f.spot),
          'frame "${f.name}": no spot "${f.spot}"',
        );
      }
    }
    for (final p in points.values) {
      if (p.frame != null) {
        need(
          frames.containsKey(p.frame),
          'point "${p.name}": no frame "${p.frame}"',
        );
      }
    }
    for (final l in level) {
      need(
        pictures.containsKey(l.picture),
        'level ${l.word}[${l.index}]: no picture "${l.picture}"',
      );
    }
    for (final r in remapTable) {
      final v = r.to.view;
      if (v != null) need(views.containsKey(v), 'remap ${r.old}: no view "$v"');
      final s = r.to.spot;
      if (s != null) need(spots.containsKey(s), 'remap ${r.old}: no spot "$s"');
    }
    for (final c in clips.values) {
      need(
        things.containsKey(c.thing),
        'clip "${c.name}": no thing "${c.thing}"',
      );
    }
  }
}

// ---------------------------------------------------------------------------------------------------------------------
// the parts, read

SheetThing _readThing(String id, Map<String, dynamic> m, String at) {
  bool flag(String k) => m.containsKey(k) && _bool(m[k], '$at.$k');
  final boxV = m['box'];
  List<int>? box;
  Map<String, SheetPlaceBox>? places;
  if (boxV is List) {
    box = _ints(boxV, '$at.box', length: 4);
  } else if (boxV is Map<String, dynamic>) {
    places = {
      for (final e in boxV.entries)
        e.key: () {
          final p = _obj(e.value, '$at.box.${e.key}');
          return SheetPlaceBox._(
            _opt(p, 'frame', (v) => _str(v, '$at.box.${e.key}.frame')),
            _opt(p, 'clip', (v) => _str(v, '$at.box.${e.key}.clip')),
            _nums(_need(p, 'old', '$at.box.${e.key}'), '$at.box.${e.key}.old'),
            _opt(p, 'new', (v) => _ints(v, '$at.box.${e.key}.new', length: 4)),
            _opt(p, 'what', (v) => _str(v, '$at.box.${e.key}.what')),
          );
        }(),
    };
  } else if (boxV != null) {
    throw SheetError(
      '$at.box: a list or an object was expected, found ${_what(boxV)}',
    );
  }
  SheetHit? hit;
  if (m.containsKey('hit')) {
    final h = _obj(m['hit'], '$at.hit');
    hit = SheetHit._(
      _doubles(_need(h, 'world', '$at.hit'), '$at.hit.world', length: 6),
      _ints(_need(h, 'box', '$at.hit'), '$at.hit.box', length: 4),
    );
  }
  SheetScreenShape? screen;
  if (m.containsKey('screen')) {
    final s = _obj(m['screen'], '$at.screen');
    screen = SheetScreenShape._(
      _nums(_need(s, 'circle', '$at.screen'), '$at.screen.circle', length: 3),
      _ints(_need(s, 'box', '$at.screen'), '$at.screen.box', length: 4),
    );
  }
  return SheetThing._(
    id,
    flag('set'),
    flag('sprite'),
    flag('hud'),
    flag('sky'),
    _opt(m, 'world', (v) => _doubles(v, '$at.world', length: 6)),
    box,
    hit,
    places,
    screen,
    _opt(m, 'old', (v) => _obj(v, '$at.old')),
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    _opt(m, 'why', (v) => _str(v, '$at.why')),
    m,
  );
}

SheetAnchor _readSpot(String name, Map<String, dynamic> m, String at) =>
    _readAnchor(name, m, at);

SheetAnchor _readPoint(String name, Map<String, dynamic> m, String at) =>
    _readAnchor(name, m, at);

SheetAnchor _readAnchor(String name, Map<String, dynamic> m, String at) =>
    SheetAnchor._(
      name,
      _doubles(_need(m, 'world', at), '$at.world', length: 3),
      _doubles(_need(m, 'screen', at), '$at.screen', length: 2),
      _nums(_need(m, 'old', at), '$at.old', length: 2),
      _opt(m, 'what', (v) => _str(v, '$at.what')),
      _opt(m, 'scale', (v) => _num(v, '$at.scale')),
      _opt(m, 'frog', (v) => _ints(v, '$at.frog', length: 2)),
      _opt(m, 'abuela', (v) => _ints(v, '$at.abuela', length: 2)),
      _opt(m, 'frame', (v) => _str(v, '$at.frame')),
      _opt(m, 'nudge', (v) => _nums(v, '$at.nudge', length: 2)),
      m,
    );

SheetLugar _readLugar(String name, Map<String, dynamic> m, String at) =>
    SheetLugar._(
      name,
      _str(_need(m, 'spot', at), '$at.spot'),
      _ints(_need(m, 'frog', at), '$at.frog', length: 2),
      _num(_need(m, 'scale', at), '$at.scale'),
      m,
    );

SheetFrame _readFrame(String name, Map<String, dynamic> m, String at) =>
    SheetFrame._(
      name,
      _nums(_need(m, 'old', at), '$at.old', length: 2),
      _opt(m, 'world', (v) => _doubles(v, '$at.world', length: 3)),
      _opt(m, 'spot', (v) => _str(v, '$at.spot')),
      _opt(m, 'nudge', (v) => _nums(v, '$at.nudge', length: 2)),
      _doubles(_need(m, 'screen', at), '$at.screen', length: 2),
      _ints(_need(m, 'offset', at), '$at.offset', length: 2),
      _opt(m, 'what', (v) => _str(v, '$at.what')),
      m,
    );

int _zoom(Object? v, String at) {
  final z = _int(v, at);
  if (z != 1 && z != 2) throw SheetError('$at: a zoom is 1 or 2, found $z');
  return z;
}

SheetView _readView(String name, Map<String, dynamic> m, String at) {
  final zoom = _zoom(_need(m, 'zoom', at), '$at.zoom');
  final region = _opt(
    m,
    'region',
    (v) => v == null ? null : _ints(v, '$at.region', length: 4),
  );
  if (zoom == 2 && region == null) {
    throw SheetError('$at: a view at zoom 2 has a region');
  }
  return SheetView._(
    name,
    _doubles(_need(m, 'world', at), '$at.world', length: 3),
    _doubles(_need(m, 'screen', at), '$at.screen', length: 2),
    zoom,
    _int(_need(m, 'x0', at), '$at.x0'),
    region,
    _nums(_need(m, 'old', at), '$at.old', length: 4),
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    m,
  );
}

SheetPicture _readPicture(String name, Map<String, dynamic> m, String at) =>
    SheetPicture._(
      name,
      _doubles(_need(m, 'world', at), '$at.world', length: 3),
      _doubles(_need(m, 'screen', at), '$at.screen', length: 2),
      _zoom(_need(m, 'zoom', at), '$at.zoom'),
      _ints(_need(m, 'crop', at), '$at.crop', length: 4),
      _opt(m, 'what', (v) => _str(v, '$at.what')),
      m,
    );

List<SheetLevel> _readLevelList(
  Object? v,
  String at,
  Map<String, SheetPicture> pictures,
) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final m = _obj(l[i], '$at[$i]');
        return SheetLevel._(
          _str(_need(m, 'w', '$at[$i]'), '$at[$i].w'),
          _int(_need(m, 'index', '$at[$i]'), '$at[$i].index'),
          _str(_need(m, 'picture', '$at[$i]'), '$at[$i].picture'),
          _ints(_need(m, 'crop', '$at[$i]'), '$at[$i].crop', length: 4),
          _zoom(_need(m, 'zoom', '$at[$i]'), '$at[$i].zoom'),
          _nums(_need(m, 'old', '$at[$i]'), '$at[$i].old', length: 4),
          m,
        );
      }(),
  ];
}

SheetClip _readClip(String name, Map<String, dynamic> m, String at) {
  List<List<double>> polygon(Object? v, String path, int dims) {
    final l = _list(v, path);
    if (l.length < 3) throw SheetError('$path: a polygon has 3 points or more');
    return [
      for (var i = 0; i < l.length; i++)
        _doubles(l[i], '$path[$i]', length: dims),
    ];
  }

  final world = polygon(_need(m, 'world', at), '$at.world', 3);
  final screen = polygon(_need(m, 'screen', at), '$at.screen', 2);
  if (screen.length != world.length) {
    throw SheetError(
      '$at: ${world.length} world points but ${screen.length} screen points',
    );
  }
  return SheetClip._(
    name,
    _str(_need(m, 'thing', at), '$at.thing'),
    _str(_need(m, 'face', at), '$at.face'),
    world,
    screen,
    _ints(_need(m, 'box', at), '$at.box', length: 4),
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    m,
  );
}

SheetShadow _readShadow(String who, Map<String, dynamic> m, String at) =>
    SheetShadow._(
      who,
      _num(_need(m, 'radius', at), '$at.radius').toDouble(),
      _opt(m, 'at', (v) => _str(v, '$at.at')),
      _opt(m, 'when', (v) => _str(v, '$at.when')),
      _opt(m, 'cast', (v) => _str(v, '$at.cast')),
      m,
    );

List<SheetRemap> _readRemapTable(Object? v, String at) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final p = '$at[$i]';
        final m = _obj(l[i], p);
        final kind = _str(_need(m, 'kind', p), '$p.kind');
        const kinds = {'point': 2, 'cam': 4, 'crop': 4, 'x': 1};
        final n = kinds[kind];
        if (n == null) {
          throw SheetError('$p.kind: "$kind" is not point, cam, crop or x');
        }
        final t = _obj(_need(m, 'to', p), '$p.to');
        return SheetRemap._(
          kind,
          _nums(_need(m, 'old', p), '$p.old', length: n),
          _strs(_need(m, 'uses', p), '$p.uses'),
          RemapTo._(
            _opt(t, 'point', (v) => _str(v, '$p.to.point')),
            _opt(t, 'world', (v) => _doubles(v, '$p.to.world', length: 3)),
            _opt(t, 'view', (v) => _str(v, '$p.to.view')),
            _opt(t, 'spot', (v) => _str(v, '$p.to.spot')),
            _opt(t, 'none', (v) => _str(v, '$p.to.none')),
          ),
          _opt(m, 'screen', (v) => _doubles(v, '$p.screen', length: 2)),
          _opt(m, 'crop', (v) => _ints(v, '$p.crop', length: 4)),
          _opt(m, 'x', (v) => _int(v, '$p.x')),
          _opt(m, 'frog', (v) => _ints(v, '$p.frog', length: 2)),
          _opt(m, 'scale', (v) => _num(v, '$p.scale')),
          _opt(m, 'x0', (v) => _int(v, '$p.x0')),
          _opt(m, 'what', (v) => _str(v, '$p.what')),
          m,
        );
      }(),
  ];
}

SheetSetKey _readSetKey(Object? v, String at) {
  final m = _obj(v, at);
  final params = _obj(_need(m, 'params', at), '$at.params');
  final baked = _list(_need(m, 'baked', at), '$at.baked');
  return SheetSetKey._(
    {
      for (final e in params.entries)
        e.key: () {
          final p = _obj(e.value, '$at.params.${e.key}');
          return SetKeyParam._(
            e.key,
            _strs(
              _need(p, 'values', '$at.params.${e.key}'),
              '$at.params.${e.key}.values',
            ),
            _str(
              _need(p, 'fromW', '$at.params.${e.key}'),
              '$at.params.${e.key}.fromW',
            ),
            p,
          );
        }(),
    },
    _str(_need(m, 'key', at), '$at.key'),
    [
      for (var i = 0; i < baked.length; i++)
        () {
          final b = _obj(baked[i], '$at.baked[$i]');
          return SheetBaked._(
            _str(_need(b, 'ref', '$at.baked[$i]'), '$at.baked[$i].ref'),
            _str(_need(b, 'query', '$at.baked[$i]'), '$at.baked[$i].query'),
          );
        }(),
    ],
    _opt(m, 'bakedWhy', (v) => _str(v, '$at.bakedWhy')),
    _opt(m, 'notRead', (v) => _str(v, '$at.notRead')),
    _opt(m, 'old', (v) => _str(v, '$at.old')),
    m,
  );
}

List<SheetCode> _readCodeList(Object? v, String at) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final m = _obj(l[i], '$at[$i]');
        final line = _need(m, 'line', '$at[$i]');
        if (line is! int && line is! String) {
          throw SheetError(
            '$at[$i].line: a number or a string was expected, found ${_what(line)}',
          );
        }
        final to = m['to'];
        if (to != null && to is! String && to is! Map<String, dynamic>) {
          throw SheetError(
            '$at[$i].to: a string or an object was expected, found ${_what(to)}',
          );
        }
        return SheetCode._(
          line!,
          _str(_need(m, 'old', '$at[$i]'), '$at[$i].old'),
          to,
          _opt(m, 'note', (v) => _str(v, '$at[$i].note')),
          m,
        );
      }(),
  ];
}
