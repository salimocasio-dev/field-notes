// The sheet's own names are kept (`S`, `setKey`, `lugar`, `fromW`): the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names

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
    this.raw, {
    this.hand,
    this.hintBox,
    this.screenRect,
  });

  final String id;

  /// El camino's (order 33b): the part of the touch box the hint frame and its twinkle are drawn round (`hintBox`,
  /// `[x, y, w, h]`), where the box runs off the picture; touches still answer in [box]. Null for a thing with none.
  final List<int>? hintBox;

  /// El camino's (order 33b): the screen box of a set thing given as its corners (`screen`: `[x0, y0, x1, y1]`); the
  /// same rectangle as [box]. Null when `screen` is a shape (the sun's, [screen]) or absent.
  final List<int>? screenRect;

  /// El patio's (order 32b): the point the hint hand points at (`hand`, kit.js cosas: `hand`, given as `[x, y]`), when
  /// the box's middle is not the place; null for a thing with none (or one that gives it otherwise: El balcón's door).
  final List<int>? hand;

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
    this.raw, {
    this.ab,
    this.now,
  });

  final String name;

  /// `x, y, z`.
  final List<double> world;

  /// The sheet's screen position of it (what [Sheet.screenOf] gives, rounded to hundredths; for a point made through
  /// a frame, the old point plus the frame's offset, which is the one to use). A sheet that writes no `screen` for it
  /// (La sala's spots, whose `new` is the old scene's place): the projection of [world] by the sheet's own scale and
  /// origin, which is what [Sheet.screenOf] gives.
  final List<double> screen;

  /// The sheet's `new` (La sala's, order 31b): the place the old scene file writes, today. A frog's spot: his `q.x`,
  /// `q.y` (the floor point under `q.x + 16`, `q.y + 25` is [world]); a person's: their `x`, `y` (the floor point
  /// under `x`, `y - 1`). The room is built round the old picture, so it is the old place but where the sheet moves it.
  final List<num>? now;

  /// The old screen position; empty for a point the old scene had no place for (El camino's `arco`).
  final List<num> old;
  final String? what;

  /// The frog's size there (a spot of the frog's).
  final num? scale;

  /// The frog's `q.x`, `q.y` there, and abuela's sprite's top left there.
  final List<int>? frog, abuela;

  /// Abuela's `ab.x`, `ab.y` there (a sheet whose scene moves her by the point under her feet, El balcón's: `ab.x =
  /// round(sx)`, `ab.y = round(sy) + 1`, her sprite drawn at `ab.x - 30`, `ab.y - 50`, which is [Sheet.abuelaAt]).
  final List<int>? ab;

  /// A point made through a frame: its name, and the extra whole pixels.
  final String? frame;
  final List<num>? nudge;
  final Map<String, dynamic> raw;
}

/// `lugar`: a name of the old scene's `LUGAR`: the spot, where the frog's box is, his size.
class SheetLugar {
  SheetLugar._(
    this.name,
    this.spot,
    this.frog,
    this.scale,
    this.raw, {
    this.old,
  });

  final String name;

  /// A key of [Sheet.spots].
  final String spot;

  /// The frog's `q.x`, `q.y` (the sheet's `frog`, or `q` as El balcón's sheet writes it).
  final List<int> frog;
  final num scale;

  /// The old `LUGAR` entry `[x, y, scale]`, when the sheet gives it.
  final List<num>? old;
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
  RemapTo._(
    this.point,
    this.world,
    this.view,
    this.spot,
    this.none, {
    this.pictures,
    this.level = false,
    this.floor,
    this.screen,
  });

  final String? point;
  final List<double>? world;
  final String? view;
  final String? spot;

  /// Why nothing: the sheet's words.
  final String? none;

  /// The review pictures an old pair rectangle was (keys of [Sheet.pictures]): their crops are [SheetRemap.crops].
  final List<String>? pictures;

  /// The position is a level picture's: the level pictures take [Sheet.level] whole, so it has no place of its own.
  final bool level;

  /// The floor point under a place that keeps its screen place (La sala's `to.floor`: the frog's or a person's feet);
  /// the place today is [SheetRemap.now].
  final List<double>? floor;

  /// El patio's (order 32b): a screen point that stays as it is (`to.screen`: in the air, the bird's loop), or null.
  final List<double>? screen;
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
    this.raw, {
    this.ab,
    this.crops,
    this.now,
    this.moved = false,
    this.cropsElsewhere = const {},
  });

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

  /// Abuela's `ab.x`, `ab.y` at the spot (a `point` that is one of her spots: [SheetAnchor.ab]).
  final List<int>? ab;

  /// The crop and zoom of each picture of [RemapTo.pictures].
  final Map<String, ({List<int> crop, int zoom})>? crops;

  /// The sheet's `new` (La sala's): the place today, as the file writes it (`x, y`).
  final List<int>? now;

  /// El patio's (order 32b): the place today is not the old one (`moved`: a story's own position the sheet moved;
  /// [now] says where).
  final bool moved;

  /// El patio's: the pictures of [RemapTo.pictures] another scene draws (`crops.<name>.scene`: cual-camino's
  /// `parque.si`, El camino's), by name, their scene.
  final Map<String, String> cropsElsewhere;
}

/// How one parameter of the set's key reads W (`setKey.params`).
class SetKeyParam {
  SetKeyParam._(
    this.name,
    this.values,
    this.fromW,
    this.raw, {
    this.valuesWhat,
  });

  final String name;

  /// The values it takes, as the strings of the state's name. Empty when the sheet says them in words ([valuesWhat]).
  final List<String> values;

  /// The values in the sheet's words, when it writes them so (La sala's `fotos`: "three characters, 0 or 1, one a
  /// frame, left to right").
  final String? valuesWhat;

  /// How W gives it: the sheet's words. The function from W to the key is the scene's, written from these.
  final String fromW;
  final Map<String, dynamic> raw;
}

/// One baked state: the reference folder and the page's query that made it.
class SheetBaked {
  SheetBaked._(this.ref, this.query, this.reached);

  /// The reference folder (`coqui/ref/pp/frente/<state>`), when the sheet names it.
  final String? ref;
  final String query;

  /// What reaches the state (the stories, the pictures), when the sheet says.
  final String? reached;
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

/// Who casts a shadow (`shadows.<who>`): the radius as a number (or one by kind, [radii]), and the sheet's words for
/// where, when and how.
class SheetShadow {
  SheetShadow._(
    this.who,
    this._radius,
    this.at,
    this.when,
    this.cast,
    this.raw, {
    this.radii,
    this.tree,
  });

  final String who;

  /// El campo's balls (`shadows.bola.tree`, order 34b): where a ball is in the tree's crown and casts none: its height
  /// at least `z`, its x within `dx` of `x`, its row at most `y`. Null for every other shadow.
  final ({num x, num dx, num y, num z})? tree;
  final double? _radius;

  /// The radius. Throws [SheetError] for a shadow whose radius is by kind ([radii]).
  double get radius =>
      _radius ??
      (throw SheetError(
        'the shadow of "$who" has a radius by kind (${radii!.keys.join(', ')}): read radii',
      ));

  /// A radius by kind (La sala's `people`: `grown`, `nino`, `bebe`), or null.
  final Map<String, double>? radii;

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

/// A part of the set that covers a character (`front.parts`, El balcón's): at [line] of the old scene file, where the old
/// code drew that piece as a sprite ([replaces]), the set's own pixels of the part (the set reference's `part(name)`) are
/// drawn again over what the sprite layer has drawn so far, where the sheet's `front.how` says (a depth test on the
/// set's own pixels).
class SheetFrontPart {
  SheetFrontPart._(
    this.name,
    this.line,
    this.replaces,
    this.raw, {
    this.sortY,
    this.boxes,
    this.insert,
  });

  /// The part's name in the set reference (`part(name, ...)`).
  final String name;

  /// The old scene file's line (a number, or a string such as `"balcon.js:127"`); null for a part that gives where it
  /// goes in its [insert] words instead (El camino's).
  final Object? line;

  /// El camino's (order 33b): where the part's entry goes in the list the old `draw` sorts by y, in the sheet's words.
  final String? insert;

  /// The old call it replaces, as the sheet quotes it.
  final String? replaces;
  final Map<String, dynamic> raw;

  /// La sala's: the part's place in the old list sorted by y (`sortY`), and the box round each character where its
  /// pixels are drawn again, in the sheet's words (`boxes`).
  final num? sortY;
  final String? boxes;
}

/// A named point of a sheet given on the screen only, with no world point (La sala's `points`, order 31b: what the old
/// code draws at a place of the picture, the cake on the low table, a photo's frame, the stars over the cake). Its
/// [screen] is one point (`x, y`), a rectangle (`x, y, w, h`: [rect]) or a list of points ([points]).
class SheetScreenPoint {
  SheetScreenPoint._(
    this.name,
    this.screen,
    this.points,
    this.old,
    this.what,
    this.angle,
    this.nail,
    this.raw, {
    this.heights,
    this.v,
    this.radius,
    this.radii,
    this.hollow,
    this.line,
  });

  final String name;

  /// El campo's crown (`points.copa.radii`, order 34b): its radii on the screen, `[rx, ry]`.
  final List<double>? radii;

  /// El campo's fork (`points.horq.hollow`, order 34b): the hollow in the crown over it, `[cx, cy, rx, ry]` on the screen.
  final List<double>? hollow;

  /// El campo's shore (`points.orilla_linea`, order 34b): a line on the ground, `x = line` in the world (its `world` is
  /// that one number); its two ends on the screen are [points].
  final double? line;

  /// El camino's cat on the bench (`points.gato_banco.v`, order 33b): the depth the sheet's front test takes for
  /// whoever is at this point, `v = (x + y) / R2` of the seat's front edge.
  final double? v;

  /// El camino's sun (`points.sol.radius`, order 33b): its radius in pixels.
  final double? radius;

  /// The numbers of a point or a rectangle; empty for a list of points. A point that moves up and down (El patio's sun,
  /// order 32b) has its `x` only, and its rows are [heights].
  final List<double> screen;

  /// El patio's sun (`points.sol`): the rows it stands at (`heights`), its `x` the one number of [screen].
  final List<double>? heights;

  /// The `x` of a point given by its `x` and its [heights]. Throws [SheetError] when it is not one.
  double get x => heights != null && screen.length == 1
      ? screen[0]
      : (throw SheetError('point "$name" is not an x with heights'));

  /// A list of points (`[[x, y], ...]`; El camino's clouds `[[x, y, size], ...]`), or null.
  final List<List<double>>? points;

  /// The old place, as the sheet writes it (a point, a rectangle or a list of points).
  final Object? old;
  final String? what;

  /// A photo's frame (La sala's `foto.<i>`): the turn the photo is drawn at, and the nail the frame hangs from.
  final double? angle;
  final List<int>? nail;
  final Map<String, dynamic> raw;

  /// The point `x, y`. Throws [SheetError] when it is not one.
  List<double> get xy => screen.length == 2
      ? screen
      : (throw SheetError('point "$name" is not one point'));

  /// The rectangle `x, y, w, h`. Throws [SheetError] when it is not one.
  List<double> get rect => screen.length == 4
      ? screen
      : (throw SheetError('point "$name" is not a rectangle'));
}

/// A place of the old scene file the sheet moves (`moves`, La sala's): at [line] of the old file, act [act], the old
/// source [src] becomes [to] (the sheet's exact pieces of source), and each person's old and new place.
class SheetMove {
  SheetMove._(
    this.line,
    this.act,
    this.src,
    this.to,
    this.places,
    this.why,
    this.raw, {
    this.values = const [],
    this.respEn,
  });

  final int line;
  final String act;
  final String src, to;

  /// Who moves from where to where (none for a move that is not a person's place: El patio's sun, stars, flowers). [z]:
  /// the row a person is sorted by when it is not their feet (El patio's baby in mamá's arms), or null.
  final List<
    ({String who, List<num> old, List<num> now, List<double> world, num? z})
  >
  places;
  final String? why;
  final Map<String, dynamic> raw;

  /// El patio's (order 32b): a value of W the move changes (`values`: `W.soly` 24 is 26), each its key and its old and
  /// new value.
  final List<({String key, num old, num now})> values;

  /// El patio's: where the answer cards stand after this act (`respEn`, juego.js `W.respEn`), or null.
  final List<int>? respEn;
}

/// One place where the old code turns smoothing on (`smoothing.places`): where ([at], "sala.js:120"), what it does, and
/// how it is kept, in the sheet's words.
class SheetSmoothingPlace {
  SheetSmoothingPlace._(this.at, this.what, this.keep, this.raw);

  final String at;
  final String? what, keep;
  final Map<String, dynamic> raw;
}

/// Where a bubble goes (`talk`, La sala's): the first of [places] whose bubble is wholly inside the view, clear of the
/// corner cards shown and of every face; else the first. The rules are the sheet's words ([what], [top], [faces],
/// [boards]); the numbers are [places], [heads] and the boards' rectangles ([board]).
class SheetTalk {
  SheetTalk._(
    this.what,
    this.top,
    this.places,
    this.faces,
    this.heads,
    this.boards,
    this.raw, {
    this.boardRect,
  });

  final String? what, top, faces;

  /// El campo's (order 34b): its one corner card's rectangle in the display (`board`: W.tarjeta, the rounds card),
  /// `[x, y, w, h]`, plus the view's x0 on the picture; null for a sheet that gives its cards in words ([boards]).
  final List<int>? boardRect;

  /// `[side, dy]`: the tail's tip at `top.x + side * (h + 16)`, `top.y + dy`.
  final List<({int side, int dy})> places;

  /// Each sprite's head (`idle`; `<who>.sent`: sitting): `top`, its first opaque row relative to the feet; `head`, the
  /// middle of its top rows relative to x.
  final Map<String, ({int top, int head})> heads;

  /// The corner cards, in the sheet's words: `W.<name> [x, y, w, h]` in the display, a term of `p + q * <field>` taking a
  /// field of W ([board]).
  final String boards;
  final Map<String, dynamic> raw;

  /// The rectangle of the corner card [name] (`plato`, `cafe`, `visor`, `retrato`) in the display, a term `p + q * f`
  /// read with [field] (W's number `f`, 0 when it has none). Null when the sheet names no such card.
  List<num>? board(String name, num Function(String field) field) {
    final m = RegExp('W\\.$name \\[([^\\]]*)\\]').firstMatch(boards);
    if (m == null) return null;
    num term(String t) {
      final n = num.tryParse(t.trim());
      if (n != null) return n;
      final e = RegExp(r'^\s*(-?[\d.]+)\s*\+\s*(-?[\d.]+)\s*\*\s*(\w+)\s*$')
          .firstMatch(t);
      if (e == null) {
        throw SheetError(
          'talk.boards: "$t" of W.$name is not a number or p + q * field',
        );
      }
      return num.parse(e[1]!) + num.parse(e[2]!) * field(e[3]!);
    }

    final parts = m[1]!.split(',');
    if (parts.length != 4) {
      throw SheetError('talk.boards: W.$name is not 4 numbers');
    }
    return [for (final t in parts) term(t)];
  }

  /// Every rectangle of the corner card [name] in the display (El patio's, order 32b): `W.<name> [x, y, w, h]`, or
  /// `W.<name>: [...] and [...]` for a card of two parts (the scores: the basket's and the nest's). A term is a number,
  /// `p + q * f`, or `p + q max(m, f)` (`26 + 15 max(3, canasta.length)`), [field] giving W's number `f` (0 when it has
  /// none; `canasta.length` the length of W's list). Empty when the sheet names no such card.
  List<List<num>> boardsOf(String name, num Function(String field) field) {
    final m = RegExp(
      'W\\.${RegExp.escape(name)}:? (\\[[^\\]]*\\](?: and \\[[^\\]]*\\])*)',
    ).firstMatch(boards);
    if (m == null) return const [];
    num term(String t) {
      final n = num.tryParse(t.trim());
      if (n != null) return n;
      final e = RegExp(r'^\s*(-?[\d.]+)\s*\+\s*(-?[\d.]+)\s*\*\s*([\w.]+)\s*$')
          .firstMatch(t);
      if (e != null) return num.parse(e[1]!) + num.parse(e[2]!) * field(e[3]!);
      final x = RegExp(
        r'^\s*(-?[\d.]+)\s*\+\s*(-?[\d.]+)\s*\*?\s*max\(\s*(-?[\d.]+)\s*,\s*([\w.]+)\s*\)\s*$',
      ).firstMatch(t);
      if (x != null) {
        return num.parse(x[1]!) +
            num.parse(x[2]!) * math.max(num.parse(x[3]!), field(x[4]!));
      }
      throw SheetError(
        'talk.boards: "$t" of W.$name is not a number, p + q * field or p + q max(m, field)',
      );
    }

    // the numbers of one rectangle, split at the commas outside brackets
    List<String> split(String s) {
      final out = <String>[];
      var depth = 0, from = 0;
      for (var i = 0; i < s.length; i++) {
        if (s[i] == '(') depth++;
        if (s[i] == ')') depth--;
        if (s[i] == ',' && depth == 0) {
          out.add(s.substring(from, i));
          from = i + 1;
        }
      }
      return out..add(s.substring(from));
    }

    return [
      for (final r in RegExp(r'\[([^\]]*)\]').allMatches(m[1]!))
        () {
          final parts = split(r[1]!);
          if (parts.length != 4) {
            throw SheetError('talk.boards: W.$name is not 4 numbers');
          }
          return [for (final t in parts) term(t)];
        }(),
    ];
  }
}

/// A number of the old scene file and what it is today: a top-level entry of the sheet with a number `old` and a number
/// `new` (El balcón's `MESA_Y`, the row the drinks stand on, and `behind`, the row that says who is drawn behind the
/// furniture).
class SheetNumber {
  SheetNumber._(this.name, this.old, this.now, this.what, this.raw);

  final String name;
  final num old;

  /// The sheet's `new`.
  final num now;
  final String? what;
  final Map<String, dynamic> raw;
}

/// One pair of the frog's places (`lugar`) and the hops between them (`hops`, `hopsAll`): kit.js acts.ir hops
/// `round(d / 30)` times (1 to 4), d the screen distance between the two places. [old] and [now] are the counts with the
/// old places and today's, [dOld] and [dNow] the distances.
class SheetHop {
  SheetHop._(
    this.a,
    this.b,
    this.old,
    this.now,
    this.dOld,
    this.dNow,
    this.raw,
  );

  final String a, b;
  final int old, now;
  final double dOld, dNow;
  final Map<String, dynamic> raw;
}

/// What the sprite layer draws behind the set (`behind`, El patio's, order 32b): each item is drawn first, then the
/// set's own pixels again wherever the set has drawn anything (its depth over -1e8, the leaves of that frame
/// included). [what] is the rule in the sheet's words; [items] each old line (`at`), what, and its boxes in words.
class SheetBehind {
  SheetBehind._(this.what, this.items, this.raw);

  final String what;
  final List<({String at, String what, String? boxes})> items;
  final Map<String, dynamic> raw;
}

/// One stage of a flower's leaves (`flowerLeaves.stages`): pixel `(x + x0 + col, y + y0 + row)` of `rows[row][col]` is
/// the palette's colour of that letter, `.` none. [head]: where the flower's head is, `[dx, dy, w, h]` from its foot.
class SheetLeafStage {
  SheetLeafStage._(this.name, this.x0, this.y0, this.rows, this.head, this.raw);

  final String name;
  final int x0, y0;
  final List<String> rows;
  final List<int>? head;
  final Map<String, dynamic> raw;
}

/// A flower's own leaves (`flowerLeaves`, El patio's round 6): drawn by the sprite layer immediately before every
/// flower planted in a bed, at its foot, 1:1, not dimmed. [palette]: each letter's colour (`0xFFBBGGRR`, made once);
/// [stages]: `open` and `bud`; [gets] and [not]: the old lines that get them and those that do not (a number, or a
/// string such as `"juego.js"`), with what they are.
class SheetFlowerLeaves {
  SheetFlowerLeaves._(
    this.what,
    this.palette,
    this.stages,
    this.gets,
    this.not,
    this.raw,
  );

  final String? what;
  final Map<String, int> palette;
  final Map<String, SheetLeafStage> stages;
  final List<({Object line, String what})> gets, not;
  final Map<String, dynamic> raw;

  /// The stage [name] (`open`, `bud`). Throws [SheetError] when there is none.
  SheetLeafStage stage(String name) =>
      stages[name] ?? (throw SheetError('flowerLeaves has no stage "$name"'));
}

/// A ripple ring on the water (`helps.ring`, El campo's): every pixel `(x, y)` with
/// `inner < ((x + .5 - cx) / rx)^2 + ((y + .5 - cy) / ry)^2 <= 1` takes [colour]. A ball's ring has `rx` its radius plus
/// [ball]'s `rx` and `ry` [ball]'s; Canelo's is [dog]'s, its middle `dy` rows under his feet.
class SheetRing {
  SheetRing._(
    this.inner,
    this.colour,
    this.kinds,
    this.patches,
    this.when,
    this.how,
    this.raw,
  );

  final double inner;

  /// `0xFFBBGGRR`, made once from the sheet's `[r, g, b]`.
  final int colour;

  /// The ring of each kind of thing, by the sheet's name (El campo's `ball` and `dog`; El lago's `pato`, `bote` and
  /// `pan`, order 35b): its radii and how far below the thing's point it lies (`dy`, 0 when the sheet gives none).
  final Map<String, ({double rx, double ry, double dy})> kinds;

  /// El lago's fish (`helps.ring.pez`, order 35b): not a ring but a patch of paler water, by the sheet's name.
  final Map<String, SheetPatch> patches;

  /// El campo's ball ring (`ring.ball`).
  ({double rx, double ry}) get ball {
    final k = kind('ball');
    return (rx: k.rx, ry: k.ry);
  }

  /// El campo's dog ring (`ring.dog`).
  ({double rx, double ry, double dy}) get dog => kind('dog');

  /// The ring of a kind. Throws [SheetError] when the sheet gives none.
  ({double rx, double ry, double dy}) kind(String name) =>
      kinds[name] ?? (throw SheetError('the sheet gives no ring for "$name"'));

  /// The patch of a kind. Throws [SheetError] when the sheet gives none.
  SheetPatch patch(String name) =>
      patches[name] ?? (throw SheetError('the sheet gives no patch for "$name"'));
  final String? when, how;
  final Map<String, dynamic> raw;
}

/// A patch of paler water under a thing at the surface (El lago's fish, `helps.ring.pez`, order 35b): an ellipse of
/// radii [rx], [ry] centred [centre] from the thing's point, filled with [patch] and, where the lake's ripple dashes
/// fall, [dash] (both `0xFFBBGGRR`); its outer [soft] px broken into the lake by a Bayer dither. No rim.
class SheetPatch {
  SheetPatch._(
    this.centre,
    this.rx,
    this.ry,
    this.soft,
    this.patch,
    this.dash,
    this.raw,
  );

  final List<double> centre;
  final double rx, ry, soft;
  final int patch, dash;
  final Map<String, dynamic> raw;
}

/// What the sprite layer draws just before a thing to help it read (`helps`, El campo's, order 34b): [ring], the ripple
/// ring round whatever floats or wades; [margin] and [edge] (px), the room every place near the shore keeps (checked by
/// the sheet maker); [lines], the old scene file's lines that gain the help, as pairs of source (old, new).
class SheetHelps {
  SheetHelps._(
    this.what,
    this.ring,
    this.margin,
    this.edge,
    this.shore,
    this.lines,
    this.raw,
  );

  final String? what, shore;
  final SheetRing ring;
  final num? margin, edge;
  final List<({String src, String to})> lines;
  final Map<String, dynamic> raw;
}

SheetHelps _readHelps(Object? v, String at) {
  final m = _obj(v, at);
  final r = _obj(_need(m, 'ring', at), '$at.ring');
  double n(Map<String, dynamic> o, String k, String a) =>
      _num(_need(o, k, a), '$a.$k').toDouble();
  int rgb(Object? v, String a) {
    final c = _ints(v, a, length: 3);
    return 0xFF000000 | (c[2] << 16) | (c[1] << 8) | c[0];
  }

  final c = _ints(_need(r, 'colour', '$at.ring'), '$at.ring.colour', length: 3);
  final lines = m.containsKey('lines')
      ? _list(m['lines'], '$at.lines')
      : const [];
  // each kind: an object with its radii (El campo's ball and dog, El lago's duck, boat and bread); one with a `patch`
  // colour is a patch (El lago's fish)
  final kinds = <String, ({double rx, double ry, double dy})>{};
  final patches = <String, SheetPatch>{};
  for (final e in r.entries) {
    final o = e.value, a = '$at.ring.${e.key}';
    if (o is! Map<String, dynamic> || !o.containsKey('rx')) continue;
    if (o.containsKey('patch')) {
      patches[e.key] = SheetPatch._(
        _doubles(_need(o, 'centre', a), '$a.centre', length: 2),
        n(o, 'rx', a),
        n(o, 'ry', a),
        n(o, 'soft', a),
        rgb(o['patch'], '$a.patch'),
        rgb(_need(o, 'dash', a), '$a.dash'),
        o,
      );
    } else {
      kinds[e.key] = (
        rx: n(o, 'rx', a),
        ry: n(o, 'ry', a),
        dy: o.containsKey('dy') ? n(o, 'dy', a) : 0,
      );
    }
  }
  return SheetHelps._(
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    SheetRing._(
      n(r, 'inner', '$at.ring'),
      0xFF000000 | (c[2] << 16) | (c[1] << 8) | c[0],
      kinds,
      patches,
      _opt(r, 'when', (v) => _str(v, '$at.ring.when')),
      _opt(r, 'how', (v) => _str(v, '$at.ring.how')),
      r,
    ),
    _opt(m, 'margin', (v) => _num(v, '$at.margin')),
    _opt(m, 'edge', (v) => _num(v, '$at.edge')),
    _opt(m, 'shore', (v) => _str(v, '$at.shore')),
    [
      for (var i = 0; i < lines.length; i++)
        () {
          final l = _strs(lines[i], '$at.lines[$i]');
          if (l.length != 2) {
            throw SheetError(
              '$at.lines[$i]: two pieces of source were expected',
            );
          }
          return (src: l[0], to: l[1]);
        }(),
    ],
    m,
  );
}

/// Everyone leaving through a gate in a file (`sevan`, El camino's, order 33b: acts.sevan as the sheet's `moves` gives
/// it): each one's [delay] in ticks after the first, and each one's two [points] on the screen, just inside the
/// opening and just past it (a person's or an animal's feet, the frog's `q`); [a], [b]: the same, from the opening's
/// middle in world units (a into the park, b towards its first post), as the sheet writes it.
class SheetSevan {
  SheetSevan._(this.delay, this.points, this.a, this.b, this.what, this.raw);

  final Map<String, int> delay;
  final Map<String, List<List<int>>> points;
  final List<double> a;
  final double b;
  final String? what;
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
    required this.frontParts,
    required this.frontHow,
    required this.frontPlane,
    required this.numbers,
    required this.shadows,
    required this.shadowsNote,
    required this.dropped,
    this.droppedCode = const [],
    required this.code,
    required this.raw,
    required this.unknown,
    this.screenPoints = const {},
    this.moves = const [],
    this.smoothing = const [],
    this.smoothingWhat,
    this.notSmoothing,
    this.bubbleRects = const {},
    this.talk,
    this.hops = const [],
    this.hopsAll = const [],
    this.behind,
    this.flowerLeaves,
    this.sevan,
    this.helps,
    this.frontWaterDepth,
    this.frontTags = const [],
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
    // a place the sheet gives as a world point only (La sala's spots and views): its screen place is the projection by
    // the sheet's own scale and origin (pp-engine.js project)
    final pw = picture[0], ph = picture[1];
    final S0 = _num(_need(m, 'S', at), '$at.S').toDouble(),
        OX =
            pw / 2 +
            _num(_need(origin, 'originX', '$at.origin'), '$at.origin.originX'),
        OY =
            ph / 2 +
            _num(_need(origin, 'originY', '$at.origin'), '$at.origin.originY');
    List<double> project(List<double> w) {
      const SIN = .5;
      final COS = math.sqrt(3) / 2, R2 = math.sqrt2;
      final u = (w[0] - w[1]) / R2, v = (w[0] + w[1]) / R2;
      return [OX + u * S0, OY + (v * SIN - w[2] * COS) * S0];
    }

    final pointsRaw = _obj(_need(m, 'points', at), '$at.points');
    final smoothingRaw = m.containsKey('smoothing')
        ? _obj(m['smoothing'], '$at.smoothing')
        : null;
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
      'smoothing',
      'moves',
      'bubbles',
      'talk',
      'hops',
      'hopsAll',
      'flowerLeaves',
      'sevan',
      'helps',
    };
    // El patio's `behind` (a part: what is drawn behind the set) is not El balcón's (a number, old and new)
    final behindPart =
        m['behind'] is Map<String, dynamic> &&
            (m['behind'] as Map<String, dynamic>).containsKey('items')
        ? _readBehind(m['behind'], '$at.behind')
        : null;
    final partsRaw = front.containsKey('parts')
        ? _obj(front['parts'], '$at.front.parts')
        : const <String, dynamic>{};
    final numbers = <String, SheetNumber>{
      for (final e in m.entries)
        if (!known.contains(e.key) &&
            e.value is Map<String, dynamic> &&
            (e.value as Map<String, dynamic>)['old'] is num &&
            (e.value as Map<String, dynamic>)['new'] is num)
          e.key: SheetNumber._(
            e.key,
            (e.value as Map<String, dynamic>)['old'] as num,
            (e.value as Map<String, dynamic>)['new'] as num,
            _opt(
              e.value as Map<String, dynamic>,
              'what',
              (v) => _str(v, '$at.${e.key}.what'),
            ),
            e.value as Map<String, dynamic>,
          ),
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
      spots: _byName(
        _need(m, 'spots', at),
        '$at.spots',
        (n, v, a) => _readAnchor(n, v, a, project),
      ),
      lugar: _byName(_need(m, 'lugar', at), '$at.lugar', _readLugar),
      frames: m.containsKey('frames')
          ? _byName(m['frames'], '$at.frames', _readFrame)
          : const {},
      points: {
        for (final e in pointsRaw.entries)
          if (_isWorldPoint(_obj(e.value, '$at.points.${e.key}')['world']))
            e.key: _readAnchor(
              e.key,
              e.value as Map<String, dynamic>,
              '$at.points.${e.key}',
              project,
            ),
      },
      screenPoints: {
        for (final e in pointsRaw.entries)
          // El campo's shore (`orilla_linea`, order 34b) is a line, its world a number (x = c): a screen point; El lago's
          // dock (a box, six numbers) and mooring posts (a list of points), order 35b, too
          if (!_isWorldPoint((e.value as Map<String, dynamic>)['world']))
            e.key: _readScreenPoint(
              e.key,
              e.value as Map<String, dynamic>,
              '$at.points.${e.key}',
            ),
      },
      views: _byName(
        _need(m, 'views', at),
        '$at.views',
        (n, v, a) => _readView(n, v, a, project),
      ),
      remapTable: _readRemapTable(_need(m, 'remap', at), '$at.remap'),
      pictures: pictures,
      level: _readLevelList(_need(m, 'level', at), '$at.level', pictures),
      clips: _byName(_need(m, 'clips', at), '$at.clips', _readClip),
      front: front.containsKey('things') || !front.containsKey('parts')
          ? _strs(_need(front, 'things', '$at.front'), '$at.front.things')
          : [...partsRaw.keys],
      frontWhy: _opt(front, 'why', (v) => _str(v, '$at.front.why')),
      frontParts: {
        for (final e in partsRaw.entries)
          e.key: () {
            final p = _obj(e.value, '$at.front.parts.${e.key}');
            // El camino's parts (order 33b) give no line: their `insert` says where they go in the sorted list
            final line = p.containsKey('insert')
                ? p['line']
                : _need(p, 'line', '$at.front.parts.${e.key}');
            if (line != null && line is! int && line is! String) {
              throw SheetError(
                '$at.front.parts.${e.key}.line: a number or a string was expected, found ${_what(line)}',
              );
            }
            return SheetFrontPart._(
              e.key,
              line,
              _opt(
                p,
                'replaces',
                (v) => _str(v, '$at.front.parts.${e.key}.replaces'),
              ),
              p,
              sortY: _opt(
                p,
                'sortY',
                (v) => _num(v, '$at.front.parts.${e.key}.sortY'),
              ),
              boxes: _opt(
                p,
                'boxes',
                (v) => _str(v, '$at.front.parts.${e.key}.boxes'),
              ),
              insert: _opt(
                p,
                'insert',
                (v) => _str(v, '$at.front.parts.${e.key}.insert'),
              ),
            );
          }(),
      },
      frontHow: _opt(front, 'how', (v) => _str(v, '$at.front.how')),
      frontPlane: _opt(front, 'plane', (v) => _str(v, '$at.front.plane')),
      numbers: numbers,
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
      dropped: [
        for (final (i, d) in _list(
          _need(m, 'dropped', at),
          '$at.dropped',
        ).indexed)
          d is Map<String, dynamic>
              ? '${d['line']}: ${_str(_need(d, 'why', '$at.dropped[$i]'), '$at.dropped[$i].why')}'
              : _str(d, '$at.dropped[$i]'),
      ],
      droppedCode: [
        for (final (i, d) in _list(
          _need(m, 'dropped', at),
          '$at.dropped',
        ).indexed)
          if (d is Map<String, dynamic>)
            (
              line: _int(
                _need(d, 'line', '$at.dropped[$i]'),
                '$at.dropped[$i].line',
              ),
              src: _str(
                _need(d, 'src', '$at.dropped[$i]'),
                '$at.dropped[$i].src',
              ),
              to: _str(_need(d, 'to', '$at.dropped[$i]'), '$at.dropped[$i].to'),
            ),
      ],
      code: _readCodeList(_need(m, 'code', at), '$at.code'),
      moves: m.containsKey('moves')
          ? _readMoves(m['moves'], '$at.moves')
          : const [],
      smoothing: smoothingRaw == null
          ? const []
          : [
              for (final (i, v) in _list(
                _need(smoothingRaw, 'places', '$at.smoothing'),
                '$at.smoothing.places',
              ).indexed)
                () {
                  final o = _obj(v, '$at.smoothing.places[$i]');
                  return SheetSmoothingPlace._(
                    _str(
                      _need(o, 'at', '$at.smoothing.places[$i]'),
                      '$at.smoothing.places[$i].at',
                    ),
                    _opt(
                      o,
                      'what',
                      (v) => _str(v, '$at.smoothing.places[$i].what'),
                    ),
                    _opt(
                      o,
                      'keep',
                      (v) => _str(v, '$at.smoothing.places[$i].keep'),
                    ),
                    o,
                  );
                }(),
            ],
      smoothingWhat: smoothingRaw == null
          ? null
          : _opt(smoothingRaw, 'what', (v) => _str(v, '$at.smoothing.what')),
      notSmoothing: smoothingRaw == null
          ? null
          : _opt(
              smoothingRaw,
              'notSmoothing',
              (v) => _str(v, '$at.smoothing.notSmoothing'),
            ),
      bubbleRects: m.containsKey('bubbles')
          ? {
              for (final e in _obj(
                _need(
                  _obj(m['bubbles'], '$at.bubbles'),
                  'rects',
                  '$at.bubbles',
                ),
                '$at.bubbles.rects',
              ).entries)
                e.key: _ints(e.value, '$at.bubbles.rects.${e.key}', length: 4),
            }
          : const {},
      talk: m.containsKey('talk') ? _readTalk(m['talk'], '$at.talk') : null,
      hops: m.containsKey('hops') ? _readHops(m['hops'], '$at.hops') : const [],
      hopsAll: m.containsKey('hopsAll')
          ? _readHops(m['hopsAll'], '$at.hopsAll')
          : const [],
      behind: behindPart,
      flowerLeaves: m.containsKey('flowerLeaves')
          ? _readFlowerLeaves(m['flowerLeaves'], '$at.flowerLeaves')
          : null,
      sevan: m.containsKey('sevan')
          ? _readSevan(m['sevan'], '$at.sevan')
          : null,
      helps: m.containsKey('helps')
          ? _readHelps(m['helps'], '$at.helps')
          : null,
      frontWaterDepth: _opt(
        front,
        'waterDepth',
        (v) => _num(v, '$at.front.waterDepth').toDouble(),
      ),
      frontTags: front.containsKey('tags')
          ? [
              for (final (i, t) in _list(
                front['tags'],
                '$at.front.tags',
              ).indexed)
                () {
                  final l = _strs(t, '$at.front.tags[$i]');
                  if (l.length != 2) {
                    throw SheetError(
                      '$at.front.tags[$i]: two pieces of source were expected',
                    );
                  }
                  return (src: l[0], to: l[1]);
                }(),
            ]
          : const [],
      raw: m,
      unknown: {
        for (final e in m.entries)
          if (!known.contains(e.key) &&
              !numbers.containsKey(e.key) &&
              !(e.key == 'behind' && behindPart != null))
            e.key: e.value,
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

  /// `front`: the things that cover a character (none, for El frente) and why. For a sheet that gives them as `parts`
  /// (El balcón's), the names of [frontParts].
  final List<String> front;
  final String? frontWhy;

  /// `front.parts`: the parts of the set drawn again over the sprite layer, by name, each at its old line; `front.how`
  /// and `front.plane`: how, in the sheet's words (the depth test). Empty and null for a sheet without them.
  final Map<String, SheetFrontPart> frontParts;
  final String? frontHow, frontPlane;

  /// The old scene file's numbers the sheet gives the new value of, by name (`MESA_Y`, `behind`): top-level entries
  /// with a number `old` and a number `new`. Not in [unknown].
  final Map<String, SheetNumber> numbers;

  /// The number [name] of [numbers], today's value. Throws [SheetError] when the sheet has no such number.
  num numberOf(String name) =>
      (numbers[name] ?? (throw SheetError('the sheet has no number "$name"')))
          .now;

  /// Who casts a shadow, and the note the sheet adds (`dropped`).
  final Map<String, SheetShadow> shadows;
  final String? shadowsNote;

  /// The old code the set replaces, as the sheet lists it (`dropped`), and every old line with what replaces it (`code`).
  final List<String> dropped;

  /// El campo's (order 34b): the old lines the sheet drops given as pieces of source (`dropped`: each its line, the
  /// exact source and what it becomes, `""`); empty for a sheet that lists them in words. [dropped] holds their `why`.
  final List<({int line, String src, String to})> droppedCode;
  final List<SheetCode> code;

  /// La sala's (order 31b): the named points given on the screen only (`points` with no world point); [points] holds
  /// those with one.
  final Map<String, SheetScreenPoint> screenPoints;

  /// The places of the old scene file the sheet moves (`moves`), in the sheet's order.
  final List<SheetMove> moves;

  /// Where the old code turns smoothing on and how each is kept (`smoothing.places`), the sheet's words on it
  /// (`smoothing.what`), and what does not smooth (`smoothing.notSmoothing`).
  final List<SheetSmoothingPlace> smoothing;
  final String? smoothingWhat, notSmoothing;

  /// Each bubble's rectangle relative to its tail's tip (`bubbles.rects`): `[dx, dy, w, h]`.
  final Map<String, List<int>> bubbleRects;

  /// Where a bubble goes (`talk`), or null.
  final SheetTalk? talk;

  /// The pairs of the frog's places whose hop count is not the old one (`hops`: El patio's 8; El balcón's and La sala's
  /// list every pair), and every pair (`hopsAll`, El patio's 91). Empty when the sheet has none.
  final List<SheetHop> hops, hopsAll;

  /// What the sprite layer draws behind the set (`behind`, El patio's), or null.
  final SheetBehind? behind;

  /// A flower's own leaves (`flowerLeaves`, El patio's), or null.
  final SheetFlowerLeaves? flowerLeaves;

  /// Everyone leaving in a file (`sevan`, El camino's), or null.
  final SheetSevan? sevan;

  /// What the sprite layer draws just before a thing to help it read (`helps`, El campo's, order 34b: the ripple ring
  /// round whatever floats or wades), or null.
  final SheetHelps? helps;

  /// El campo's (order 34b): how far the water's surface lies under the lawn, for the front test of whoever stands over
  /// it (`front.waterDepth`); null for a set with no water.
  final double? frontWaterDepth;

  /// El campo's (order 34b): the pieces of the old scene file the sheet's preview gives a tag (`front.tags`: each item of
  /// the sorted list says what it is, for the front test), as pairs of source; empty for the others.
  final List<({String src, String to})> frontTags;

  /// A screen point of [screenPoints]. Throws [SheetError] when the sheet has none of that name.
  SheetScreenPoint screenPoint(String name) =>
      screenPoints[name] ??
      (throw SheetError('the sheet has no screen point "$name"'));

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
    if (s.abuela == null && s.ab == null) {
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
  List<int>? screenRect;
  if (m['screen'] is List) {
    // El camino's set things: the box's corners, x0, y0, x1, y1
    screenRect = _ints(m['screen'], '$at.screen', length: 4);
  } else if (m.containsKey('screen')) {
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
    // El lago's water (order 35b) gives its world as null: the ground under the horizon, no box of its own
    m['world'] == null
        ? null
        : _doubles(m['world'], '$at.world', length: 6),
    box,
    hit,
    places,
    screen,
    _opt(m, 'old', (v) => _obj(v, '$at.old')),
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    _opt(m, 'why', (v) => _str(v, '$at.why')),
    m,
    // (El balcón's door gives its hand as an object, a point's name: kept in raw)
    hand: m['hand'] is List ? _ints(m['hand'], '$at.hand', length: 2) : null,
    hintBox: _opt(m, 'hintBox', (v) => _ints(v, '$at.hintBox', length: 4)),
    screenRect: screenRect,
  );
}

SheetAnchor _readAnchor(
  String name,
  Map<String, dynamic> m,
  String at,
  List<double> Function(List<double> world) project,
) {
  final world = _doubles(_need(m, 'world', at), '$at.world', length: 3);
  return SheetAnchor._(
    name,
    world,
    m.containsKey('screen') || !m.containsKey('new')
        ? _doubles(_need(m, 'screen', at), '$at.screen', length: 2)
        : project(world),
    // a point the old scene had no place for (El camino's arch, order 33b) has no `old`: an empty list
    _opt(m, 'old', (v) => _nums(v, '$at.old', length: 2)) ?? const <num>[],
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    _opt(m, 'scale', (v) => _num(v, '$at.scale')),
    _opt(m, 'frog', (v) => _ints(v, '$at.frog', length: 2)),
    _opt(m, 'abuela', (v) => _ints(v, '$at.abuela', length: 2)),
    _opt(m, 'frame', (v) => _str(v, '$at.frame')),
    _opt(m, 'nudge', (v) => _nums(v, '$at.nudge', length: 2)),
    m,
    ab: _opt(m, 'ab', (v) => _ints(v, '$at.ab', length: 2)),
    now: _opt(m, 'new', (v) => _nums(v, '$at.new', length: 2)),
  );
}

// A point's `world` that is one world point (x, y, z), so the point is an anchor: not El campo's shore (one number), not
// El lago's dock (a box of six) or its mooring posts (a list of points)
bool _isWorldPoint(Object? w) => w is List && w.length == 3 && w.every((v) => v is num);

SheetScreenPoint _readScreenPoint(
  String name,
  Map<String, dynamic> m,
  String at,
) {
  final sc = _list(_need(m, 'screen', at), '$at.screen');
  final many = sc.isNotEmpty && sc.first is List;
  // a point that moves up and down (El patio's sun): `screen` is [x, null] and its rows are `heights`
  final heights = _opt(m, 'heights', (v) => _doubles(v, '$at.heights'));
  if (heights != null && (sc.length != 2 || sc[1] != null)) {
    throw SheetError('$at.screen: a point with heights is [x, null]');
  }
  return SheetScreenPoint._(
    name,
    many
        ? const []
        : heights != null
        ? [_num(sc[0], '$at.screen[0]').toDouble()]
        : _doubles(sc, '$at.screen'),
    many
        ? [
            for (var i = 0; i < sc.length; i++)
              // El camino's clouds (`nubes`, order 33b): x, y and a size each
              _list(sc[i], '$at.screen[$i]').length == 3
                  ? _doubles(sc[i], '$at.screen[$i]', length: 3)
                  : _doubles(sc[i], '$at.screen[$i]', length: 2),
          ]
        : null,
    m['old'],
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    _opt(m, 'angle', (v) => _num(v, '$at.angle').toDouble()),
    _opt(m, 'nail', (v) => _ints(v, '$at.nail', length: 2)),
    m,
    heights: heights,
    v: _opt(m, 'v', (v) => _num(v, '$at.v').toDouble()),
    radius: _opt(m, 'radius', (v) => _num(v, '$at.radius').toDouble()),
    radii: _opt(m, 'radii', (v) => _doubles(v, '$at.radii', length: 2)),
    hollow: _opt(m, 'hollow', (v) => _doubles(v, '$at.hollow', length: 4)),
    line: m['world'] is num ? (m['world'] as num).toDouble() : null,
  );
}

SheetSevan _readSevan(Object? v, String at) {
  final m = _obj(v, at);
  final d = _obj(_need(m, 'delay', at), '$at.delay');
  final pts = _obj(_need(m, 'points', at), '$at.points');
  return SheetSevan._(
    {for (final e in d.entries) e.key: _int(e.value, '$at.delay.${e.key}')},
    {
      for (final e in pts.entries)
        e.key: () {
          final l = _list(e.value, '$at.points.${e.key}');
          if (l.length != 2) {
            throw SheetError('$at.points.${e.key}: two points were expected');
          }
          return [
            for (var i = 0; i < 2; i++)
              _ints(l[i], '$at.points.${e.key}[$i]', length: 2),
          ];
        }(),
    },
    _doubles(_need(m, 'a', at), '$at.a', length: 2),
    _num(_need(m, 'b', at), '$at.b').toDouble(),
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    m,
  );
}

List<SheetMove> _readMoves(Object? v, String at) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final p = '$at[$i]', o = _obj(l[i], p);
        final places = o.containsKey('places')
            ? _list(o['places'], '$p.places')
            : const [];
        final values = o.containsKey('values')
            ? _list(o['values'], '$p.values')
            : const [];
        return SheetMove._(
          _int(_need(o, 'line', p), '$p.line'),
          _str(_need(o, 'act', p), '$p.act'),
          _str(_need(o, 'src', p), '$p.src'),
          _str(_need(o, 'to', p), '$p.to'),
          [
            for (var j = 0; j < places.length; j++)
              () {
                final q = '$p.places[$j]', pl = _obj(places[j], q);
                return (
                  who: _str(_need(pl, 'who', q), '$q.who'),
                  old: _nums(_need(pl, 'old', q), '$q.old', length: 2),
                  now: _nums(_need(pl, 'new', q), '$q.new', length: 2),
                  world: _doubles(_need(pl, 'world', q), '$q.world', length: 3),
                  z: _opt(pl, 'z', (v) => _num(v, '$q.z')),
                );
              }(),
          ],
          _opt(o, 'why', (v) => _str(v, '$p.why')),
          o,
          values: [
            for (var j = 0; j < values.length; j++)
              () {
                final q = '$p.values[$j]', vl = _obj(values[j], q);
                return (
                  key: _str(_need(vl, 'key', q), '$q.key'),
                  old: _num(_need(vl, 'old', q), '$q.old'),
                  now: _num(_need(vl, 'new', q), '$q.new'),
                );
              }(),
          ],
          respEn: _opt(o, 'respEn', (v) => _ints(v, '$p.respEn', length: 2)),
        );
      }(),
  ];
}

List<SheetHop> _readHops(Object? v, String at) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final p = '$at[$i]', o = _obj(l[i], p);
        return SheetHop._(
          _str(_need(o, 'a', p), '$p.a'),
          _str(_need(o, 'b', p), '$p.b'),
          _int(_need(o, 'old', p), '$p.old'),
          _int(_need(o, 'new', p), '$p.new'),
          _num(_need(o, 'dOld', p), '$p.dOld').toDouble(),
          _num(_need(o, 'dNew', p), '$p.dNew').toDouble(),
          o,
        );
      }(),
  ];
}

SheetBehind _readBehind(Object? v, String at) {
  final m = _obj(v, at);
  final items = _list(_need(m, 'items', at), '$at.items');
  return SheetBehind._(_str(_need(m, 'what', at), '$at.what'), [
    for (var i = 0; i < items.length; i++)
      () {
        final p = '$at.items[$i]', o = _obj(items[i], p);
        return (
          at: _str(_need(o, 'at', p), '$p.at'),
          what: _str(_need(o, 'what', p), '$p.what'),
          boxes: _opt(o, 'boxes', (v) => _str(v, '$p.boxes')),
        );
      }(),
  ], m);
}

SheetFlowerLeaves _readFlowerLeaves(Object? v, String at) {
  final m = _obj(v, at);
  final palette = _obj(_need(m, 'palette', at), '$at.palette');
  final stages = _obj(_need(m, 'stages', at), '$at.stages');
  List<({Object line, String what})> lines(String key) {
    final l = _list(_need(m, key, at), '$at.$key');
    return [
      for (var i = 0; i < l.length; i++)
        () {
          final p = '$at.$key[$i]', o = _obj(l[i], p);
          final line = _need(o, 'line', p);
          if (line is! int && line is! String) {
            throw SheetError(
              '$p.line: a number or a string was expected, found ${_what(line)}',
            );
          }
          return (line: line!, what: _str(_need(o, 'what', p), '$p.what'));
        }(),
    ];
  }

  final pal = <String, int>{
    for (final e in palette.entries)
      e.key: () {
        final c = _ints(e.value, '$at.palette.${e.key}', length: 3);
        return 0xFF000000 | (c[2] << 16) | (c[1] << 8) | c[0];
      }(),
  };
  final st = <String, SheetLeafStage>{
    for (final e in stages.entries)
      e.key: () {
        final p = '$at.stages.${e.key}', o = _obj(e.value, p);
        final rows = _strs(_need(o, 'rows', p), '$p.rows');
        for (var r = 0; r < rows.length; r++) {
          for (final ch in rows[r].split('')) {
            if (ch != '.' && !pal.containsKey(ch)) {
              throw SheetError('$p.rows[$r]: "$ch" is not in the palette');
            }
          }
        }
        return SheetLeafStage._(
          e.key,
          _int(_need(o, 'x0', p), '$p.x0'),
          _int(_need(o, 'y0', p), '$p.y0'),
          rows,
          _opt(o, 'head', (v) => _ints(v, '$p.head', length: 4)),
          o,
        );
      }(),
  };
  return SheetFlowerLeaves._(
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    pal,
    st,
    lines('gets'),
    lines('not'),
    m,
  );
}

SheetTalk _readTalk(Object? v, String at) {
  final m = _obj(v, at);
  final places = _list(_need(m, 'places', at), '$at.places');
  final heads = _obj(_need(m, 'heads', at), '$at.heads');
  return SheetTalk._(
    _opt(m, 'what', (v) => _str(v, '$at.what')),
    _opt(m, 'top', (v) => _str(v, '$at.top')),
    [
      for (var i = 0; i < places.length; i++)
        () {
          final p = _ints(places[i], '$at.places[$i]', length: 2);
          return (side: p[0], dy: p[1]);
        }(),
    ],
    _opt(m, 'faces', (v) => _str(v, '$at.faces')),
    {
      for (final e in heads.entries)
        e.key: () {
          final h = _obj(e.value, '$at.heads.${e.key}');
          return (
            top: _int(
              _need(h, 'top', '$at.heads.${e.key}'),
              '$at.heads.${e.key}.top',
            ),
            head: _int(
              _need(h, 'head', '$at.heads.${e.key}'),
              '$at.heads.${e.key}.head',
            ),
          );
        }(),
    },
    // El campo's (order 34b): one corner card, its rectangle `board` and its words `boardWhat`
    m.containsKey('boards') || !m.containsKey('board')
        ? _str(_need(m, 'boards', at), '$at.boards')
        : _str(_need(m, 'boardWhat', at), '$at.boardWhat'),
    m,
    boardRect: _opt(m, 'board', (v) => _ints(v, '$at.board', length: 4)),
  );
}

SheetLugar _readLugar(String name, Map<String, dynamic> m, String at) {
  final key = m.containsKey('frog') || !m.containsKey('q') ? 'frog' : 'q';
  return SheetLugar._(
    name,
    _str(_need(m, 'spot', at), '$at.spot'),
    _ints(_need(m, key, at), '$at.$key', length: 2),
    _num(_need(m, 'scale', at), '$at.scale'),
    m,
    old: _opt(m, 'old', (v) => _nums(v, '$at.old')),
  );
}

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

SheetView _readView(
  String name,
  Map<String, dynamic> m,
  String at,
  List<double> Function(List<double> world) project,
) {
  final zoom = _zoom(_need(m, 'zoom', at), '$at.zoom');
  final region = _opt(
    m,
    'region',
    (v) => v == null ? null : _ints(v, '$at.region', length: 4),
  );
  if (zoom == 2 && region == null) {
    throw SheetError('$at: a view at zoom 2 has a region');
  }
  final world = _doubles(_need(m, 'world', at), '$at.world', length: 3);
  return SheetView._(
    name,
    world,
    // a view with no screen (La sala's): the projection of its world centre
    m.containsKey('screen')
        ? _doubles(_need(m, 'screen', at), '$at.screen', length: 2)
        : project(world),
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

SheetShadow _readShadow(String who, Map<String, dynamic> m, String at) {
  final r = _need(m, 'radius', at);
  // a radius by kind (La sala's people: grown, nino, bebe)
  final radii = r is Map<String, dynamic>
      ? {
          for (final e in r.entries)
            e.key: _num(e.value, '$at.radius.${e.key}').toDouble(),
        }
      : null;
  return SheetShadow._(
    who,
    radii == null ? _num(r, '$at.radius').toDouble() : null,
    _opt(m, 'at', (v) => _str(v, '$at.at')),
    _opt(m, 'when', (v) => _str(v, '$at.when')),
    _opt(m, 'cast', (v) => _str(v, '$at.cast')),
    m,
    radii: radii,
    tree: m.containsKey('tree')
        ? () {
            final t = _obj(m['tree'], '$at.tree');
            num n(String k) => _num(_need(t, k, '$at.tree'), '$at.tree.$k');
            return (x: n('x'), dx: n('dx'), y: n('y'), z: n('z'));
          }()
        : null,
  );
}

List<SheetRemap> _readRemapTable(Object? v, String at) {
  final l = _list(v, at);
  return [
    for (var i = 0; i < l.length; i++)
      () {
        final p = '$at[$i]';
        final m = _obj(l[i], p);
        final kind = _str(_need(m, 'kind', p), '$p.kind');
        // `numbers` (El camino's, order 33b): three counts a pair file writes (W.pajaros), no place
        const kinds = {'point': 2, 'cam': 4, 'crop': 4, 'x': 1, 'numbers': 3};
        final n = kinds[kind];
        if (n == null) {
          throw SheetError(
            '$p.kind: "$kind" is not point, cam, crop, x or numbers',
          );
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
            // `none` is the sheet's words, or (El patio's) `true`, its words then in the entry's `what`
            _opt(
              t,
              'none',
              (v) => v == true
                  ? (m['what'] is String ? m['what'] as String : '')
                  : _str(v, '$p.to.none'),
            ),
            pictures: _opt(t, 'pictures', (v) => _strs(v, '$p.to.pictures')),
            level: t.containsKey('level') && _bool(t['level'], '$p.to.level'),
            floor: _opt(
              t,
              'floor',
              (v) => _doubles(v, '$p.to.floor', length: 3),
            ),
            screen: _opt(
              t,
              'screen',
              (v) => _doubles(v, '$p.to.screen', length: 2),
            ),
          ),
          _opt(m, 'screen', (v) => _doubles(v, '$p.screen', length: 2)),
          _opt(m, 'crop', (v) => _ints(v, '$p.crop', length: 4)),
          _opt(m, 'x', (v) => _int(v, '$p.x')),
          _opt(m, 'frog', (v) => _ints(v, '$p.frog', length: 2)),
          _opt(m, 'scale', (v) => _num(v, '$p.scale')),
          _opt(m, 'x0', (v) => _int(v, '$p.x0')),
          _opt(m, 'what', (v) => _str(v, '$p.what')),
          m,
          ab: _opt(m, 'ab', (v) => _ints(v, '$p.ab', length: 2)),
          now: _opt(m, 'new', (v) => _ints(v, '$p.new', length: 2)),
          moved: m.containsKey('moved') && _bool(m['moved'], '$p.moved'),
          cropsElsewhere: m.containsKey('crops')
              ? {
                  for (final e in _obj(m['crops'], '$p.crops').entries)
                    if (_obj(e.value, '$p.crops.${e.key}').containsKey('scene'))
                      e.key: _str(
                        (e.value as Map<String, dynamic>)['scene'],
                        '$p.crops.${e.key}.scene',
                      ),
                }
              : const {},
          crops: _opt(m, 'crops', (v) {
            final c = _obj(v, '$p.crops');
            return {
              for (final e in c.entries)
                if (!_obj(e.value, '$p.crops.${e.key}').containsKey('scene'))
                  e.key: () {
                    final o = _obj(e.value, '$p.crops.${e.key}');
                    return (
                      crop: _ints(
                        _need(o, 'crop', '$p.crops.${e.key}'),
                        '$p.crops.${e.key}.crop',
                        length: 4,
                      ),
                      zoom: _zoom(
                        _need(o, 'zoom', '$p.crops.${e.key}'),
                        '$p.crops.${e.key}.zoom',
                      ),
                    );
                  }(),
            };
          }),
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
          final values = _need(p, 'values', '$at.params.${e.key}');
          return SetKeyParam._(
            e.key,
            values is String
                ? const []
                : _strs(values, '$at.params.${e.key}.values'),
            _str(
              _need(p, 'fromW', '$at.params.${e.key}'),
              '$at.params.${e.key}.fromW',
            ),
            p,
            valuesWhat: values is String ? values : null,
          );
        }(),
    },
    _str(_need(m, 'key', at), '$at.key'),
    [
      for (var i = 0; i < baked.length; i++)
        () {
          final b = _obj(baked[i], '$at.baked[$i]');
          return SheetBaked._(
            _opt(b, 'ref', (v) => _str(v, '$at.baked[$i].ref')),
            _str(_need(b, 'query', '$at.baked[$i]'), '$at.baked[$i].query'),
            _opt(b, 'reached', (v) => _str(v, '$at.baked[$i].reached')),
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
