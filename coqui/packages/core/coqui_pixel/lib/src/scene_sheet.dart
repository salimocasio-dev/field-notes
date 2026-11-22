// The reader of the content lane's sheets: the `<id>-sheet.json` of the 28 new scenes of places 4 to 10 (orders 50 to
// 77), whose shape is not the old scenes' (no old scene file, no remap, no code: page 13, "From the content lane").
// The old [Sheet] stays as it is for the eleven old scenes; this is a second reader beside it (order 50b, El mostrador,
// its first writer). It reads what every new sheet has, typed, and gives the rest as plain data:
//
// - typed: scene, made, S, origin, picture, view, rules (words), setKey (params, key, baked), things, spots, groups,
//   views, front (the depth rule), shadows (radii, by character, who casts none), checks, notes;
// - plain: every other part (`alternatives`, `moved`, `moves`, `cards`, `surtidos`, `routes`, `calle`, ...) in
//   [SceneSheet.extras], and each typed entry's own fields in its `raw`.
//
// A state of a scene that the sheet gives as a part of its own, with its own origin, picture, setKey, spots, things,
// views and shadows (El mostrador's `calle`), is read by [SceneSheet.part]: what that part does not give is the sheet's.
// [SceneSheet.legacy] is the old [Sheet] a new scene hands to the code that reads one (the start frog, the pictures):
// the sheet's scene, scale, origin and sizes, and nothing else.
// The JSON's names are kept, capitals included: the lint on names is off in this file.
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:math' as math;

import 'package:coqui_pixel/src/pp_engine.dart';
import 'package:coqui_pixel/src/sheet.dart';

Map<String, dynamic> _o(Object? v, String at) {
  if (v is Map<String, dynamic>) return v;
  throw SheetError('$at: an object, not ${v.runtimeType}');
}

Object? _need(Map<String, dynamic> m, String k, String at) =>
    m.containsKey(k) ? m[k] : throw SheetError('$at: no "$k"');

List<double>? _ds(Object? v, String at, {int? length}) {
  if (v == null) return null;
  if (v is! List || v.any((x) => x is! num)) {
    throw SheetError('$at: a list of numbers, not $v');
  }
  if (length != null && v.length != length) {
    throw SheetError('$at: $length numbers, not ${v.length}');
  }
  return [for (final x in v) (x as num).toDouble()];
}

List<int>? _is(Object? v, String at, {int? length}) {
  final d = _ds(v, at, length: length);
  return d == null ? null : [for (final x in d) x.round()];
}

// setKey.baked: a list of page queries, or (La calle's tiendas) lists of them by a word: every query, in order
List<String> _queries(Object? v) => v is List
    ? [for (final q in v) '$q']
    : v is Map
    ? [for (final l in v.values) ..._queries(l)]
    : ['$v'];

String _words(Object? v) => v == null
    ? ''
    : v is String
    ? v
    : jsonEncode(v);

/// One parameter of a set's key (`setKey.params.<name>`): its values (numbers or words, as the sheet writes them), the
/// state it applies to (`only`), its note.
class SceneSetParam {
  SceneSetParam._(this.name, this.values, this.only, this.note, this.raw);

  final String name;

  /// The values, as written (`["manana", "tarde"]`, `[0, 1]`); empty when the sheet gives none (a dev-only parameter).
  final List<Object?> values;

  /// The state the parameter applies to (`"dentro"`), or null.
  final String? only;
  final String note;
  final Map<String, dynamic> raw;
}

/// A set's key (`setKey`): its parameters, the words saying how they join into a key, and the baked states as page
/// queries (`?donde=dentro&hora=manana&atras=shut&nevera=0`).
class SceneSetKey {
  SceneSetKey._(this.params, this.key, this.baked, this.raw);

  final Map<String, SceneSetParam> params;
  final String key;
  final List<String> baked;
  final Map<String, dynamic> raw;
}

/// A thing he can touch or that is poked (`things.<id>`): a sprite of the sprite layer (`"sprite"`, or an object with
/// `sprite: true`), or a part of the set (`set: true`) with its world box and its screen box.
class SceneThing {
  SceneThing._(
    this.id,
    this.sprite,
    this.set,
    this.world,
    this.box,
    this.what,
    this.when,
    this.raw,
  );

  final String id;
  final bool sprite, set;

  /// x0, y0, z0, x1, y1, z1 in the world, when the sheet gives them.
  final List<double>? world;

  /// [x, y, w, h] on the picture, when the sheet gives it.
  final List<int>? box;
  final String what;

  /// When it is there (`"nevera = 1"`), or null.
  final String? when;

  /// The entry as written (`{}` for a bare `"sprite"`).
  final Map<String, dynamic> raw;
}

/// A place (`spots.<name>`): the world point of the feet, its screen point and depth as the sheet's maker projected
/// them, the frog's scale, its kind; or a place not drawn (`drawn: false`, no world point).
class SceneSpot {
  SceneSpot._(
    this.name,
    this.world,
    this.screen,
    this.depth,
    this.scale,
    this.kind,
    this.what,
    this.drawn,
    this.raw,
  );

  final String name;
  final List<double>? world;

  /// The screen point, as written (whole pixels, or a fraction where the sheet gives one).
  final List<double>? screen;
  final double? depth;
  final num scale;
  final String kind, what;

  /// False for a place where nobody is drawn (don Pepe gone through the back door).
  final bool drawn;
  final Map<String, dynamic> raw;

  /// The screen point in whole pixels (the sheet's own rounding: `rules.project`, "screen is the projection rounded").
  ({int sx, int sy}) get at {
    final s = screen ?? (throw SheetError('spot $name has no screen point'));
    return (sx: s[0].round(), sy: s[1].round());
  }
}

/// A view (`views.<name>`): its zoom, x0 and region (the window over the picture), and the point it is centred on when
/// the sheet gives one.
class SceneView {
  SceneView._(
    this.name,
    this.zoom,
    this.x0,
    this.region,
    this.world,
    this.screen,
    this.what,
    this.raw,
  );

  final String name;
  final int zoom, x0;

  /// [x, y, w, h] of the window on the picture.
  final List<int> region;
  final List<double>? world, screen;
  final String what;
  final Map<String, dynamic> raw;

  /// The view as the runner's `cam` holds it: `[x, y, w, h]`.
  List<num> get cam => [region[0], region[1], region[2], region[3]];
}

/// The depth rule (`front`): no list of parts; a character is hidden by every set pixel nearer the camera than the
/// upright plane through its feet plus [bias]; between two sprites the nearer pixel wins.
class SceneFront {
  SceneFront._(
    this.list,
    this.how,
    this.bias,
    this.plane,
    this.sprites,
    this.raw,
  );

  final Object? list;
  final String how, plane, sprites;
  final double bias;
  final Map<String, dynamic> raw;

  /// front.plane: the depth of a character's pixel on picture row [r], for a character whose feet are at depth [d] on
  /// screen row [sy], at scale [S]: `d + (sy - (r + .5)) * tan(30 deg) / S`.
  static double depthAt(double d, num sy, int r, double S) =>
      d + (sy - (r + .5)) * math.tan(math.pi / 6) / S;
}

/// Who casts a shadow and how big (`shadows`): radii by kind and by character, the places where nobody casts one, and the
/// sheet's words for the rest (`onCounter`, `onSeat`, ...).
class SceneShadows {
  SceneShadows._(this.radius, this.byCharacter, this.at, this.none, this.raw);

  final Map<String, double> radius, byCharacter;
  final String at;
  final List<String> none;
  final Map<String, dynamic> raw;
}

/// One check of the sheet's maker (`checks.results[i]`).
class SceneCheck {
  SceneCheck._(this.name, this.ok, this.lines);

  final String name;
  final bool ok;
  final List<String> lines;
}

/// A new scene's sheet (places 4 to 10), read from its text. Throws [SheetError], naming where, when a part every new
/// sheet has is missing or of another shape.
class SceneSheet {
  SceneSheet._({
    required this.scene,
    required this.made,
    required this.S,
    required this.originX,
    required this.originY,
    required this.pictureW,
    required this.pictureH,
    required this.viewW,
    required this.viewH,
    required this.rules,
    required this.setKey,
    required this.things,
    required this.spots,
    required this.groups,
    required this.views,
    required this.front,
    required this.shadows,
    required this.checks,
    required this.notes,
    required this.extras,
    required this.raw,
  });

  final String scene, made;
  final double S, originX, originY;
  final int pictureW, pictureH, viewW, viewH;

  /// The sheet's rules, each as words (`project`, `spot`, `anchor`, `view`, `depth`, ...).
  final Map<String, String> rules;
  final SceneSetKey setKey;
  final Map<String, SceneThing> things;
  final Map<String, SceneSpot> spots;

  /// The groups of spots given as a list of names (a group given otherwise, as La casa's baño's `touch` and `persons`,
  /// is in `raw['groups']`).
  final Map<String, List<String>> groups;
  final Map<String, SceneView> views;
  final SceneFront front;
  final SceneShadows shadows;
  final List<SceneCheck> checks;
  final List<String> notes;

  /// Every top-level part this reader does not type, as written.
  final Map<String, Object?> extras;

  /// The whole sheet, as written.
  final Map<String, dynamic> raw;

  static const Set<String> _typed = {
    'scene',
    'made',
    'S',
    'origin',
    'picture',
    'view',
    'rules',
    'setKey',
    'things',
    'spots',
    'groups',
    'views',
    'front',
    'shadows',
    'checks',
    'notes',
  };

  /// A sheet from its text.
  factory SceneSheet.parse(String json) {
    final Object? v;
    try {
      v = jsonDecode(json);
    } on FormatException catch (e) {
      throw SheetError('the sheet is not JSON: ${e.message}');
    }
    return SceneSheet.fromJson(_o(v, 'the sheet'));
  }

  /// A sheet from decoded JSON; [parent]: the sheet a part ([part]) belongs to, whose parts fill what it does not give.
  factory SceneSheet.fromJson(
    Map<String, dynamic> m, {
    SceneSheet? parent,
    String at = r'$',
  }) {
    Object? need(String k) =>
        m.containsKey(k) || parent == null ? _need(m, k, at) : null;
    final origin = m.containsKey('origin') || parent == null
        ? _o(_need(m, 'origin', at), '$at.origin')
        : null;
    final picture = m.containsKey('picture') || parent == null
        ? _is(_need(m, 'picture', at), '$at.picture', length: 2)!
        : [parent.pictureW, parent.pictureH];
    final view = m.containsKey('view') || parent == null
        ? _is(_need(m, 'view', at), '$at.view', length: 2)!
        : [parent.viewW, parent.viewH];

    // setKey
    SceneSetKey? setKey;
    if (m.containsKey('setKey') || parent == null) {
      final sk = _o(_need(m, 'setKey', at), '$at.setKey');
      final params = _o(_need(sk, 'params', '$at.setKey'), '$at.setKey.params');
      setKey = SceneSetKey._(
        {
          for (final e in params.entries)
            e.key: () {
              final p = _o(e.value, '$at.setKey.params.${e.key}');
              final vs = p['values'];
              return SceneSetParam._(
                e.key,
                vs is List ? List<Object?>.of(vs) : const [],
                p['only'] as String?,
                _words(p['note']),
                p,
              );
            }(),
        },
        _words(_need(sk, 'key', '$at.setKey')),
        _queries(_need(sk, 'baked', '$at.setKey')),
        sk,
      );
    }

    // things
    Map<String, SceneThing>? things;
    if (m.containsKey('things') || parent == null) {
      things = {
        for (final e in _o(need('things'), '$at.things').entries)
          e.key: () {
            final a = '$at.things.${e.key}';
            if (e.value == 'sprite') {
              return SceneThing._(e.key, true, false, null, null, '', null, {});
            }
            final t = _o(e.value, a);
            final world = t['world'];
            return SceneThing._(
              e.key,
              t['sprite'] == true,
              t['set'] == true,
              world is List && world.length == 6 && world.every((x) => x is num)
                  ? _ds(world, '$a.world')
                  : null,
              t['box'] is List ? _is(t['box'], '$a.box', length: 4) : null,
              _words(t['what']),
              t['when'] as String?,
              t,
            );
          }(),
      };
    }

    // spots
    Map<String, SceneSpot>? spots;
    if (m.containsKey('spots') || parent == null) {
      spots = {
        for (final e in _o(need('spots'), '$at.spots').entries)
          e.key: () {
            final a = '$at.spots.${e.key}';
            final s = _o(e.value, a);
            final w = s['world'];
            return SceneSpot._(
              e.key,
              w is List && w.length == 3 && w.every((x) => x is num)
                  ? _ds(w, '$a.world')
                  : null,
              s['screen'] is List && (s['screen'] as List).length == 2
                  ? _ds(s['screen'], '$a.screen')
                  : null,
              (s['depth'] as num?)?.toDouble(),
              (s['scale'] as num?) ?? 1,
              _words(s['kind']),
              _words(s['what']),
              s['drawn'] != false,
              s,
            );
          }(),
      };
    }

    // views
    Map<String, SceneView>? views;
    if (m.containsKey('views') || parent == null) {
      views = {
        for (final e in _o(need('views'), '$at.views').entries)
          e.key: () {
            final a = '$at.views.${e.key}';
            final v = _o(e.value, a);
            final w = v['world'];
            return SceneView._(
              e.key,
              (_need(v, 'zoom', a) as num).toInt(),
              (_need(v, 'x0', a) as num).toInt(),
              _is(_need(v, 'region', a), '$a.region', length: 4)!,
              w is List && w.length == 3 && w.every((x) => x is num)
                  ? _ds(w, '$a.world')
                  : null,
              v['screen'] is List && (v['screen'] as List).length == 2
                  ? _ds(v['screen'], '$a.screen')
                  : null,
              _words(v['what']),
              v,
            );
          }(),
      };
    }

    // front, shadows
    SceneFront? front;
    if (m.containsKey('front') || parent == null) {
      final f = _o(_need(m, 'front', at), '$at.front');
      front = SceneFront._(
        f['list'],
        _words(f['how']),
        ((f['bias'] as num?) ?? 0).toDouble(),
        _words(f['plane']),
        _words(f['sprites']),
        f,
      );
    }
    SceneShadows? shadows;
    if (m.containsKey('shadows') || parent == null) {
      final sh = _o(_need(m, 'shadows', at), '$at.shadows');
      Map<String, double> radii(Object? v) => v is Map
          ? {
              for (final e in v.entries)
                if (e.value is num) '${e.key}': (e.value as num).toDouble(),
            }
          : const {};
      shadows = SceneShadows._(
        radii(sh['radius']),
        radii(sh['byCharacter']),
        _words(sh['at']),
        [for (final x in (sh['none'] as List? ?? const [])) '$x'],
        sh,
      );
    }

    final checksRaw = m['checks'];
    final results = checksRaw is Map ? checksRaw['results'] : null;
    final extras = <String, Object?>{
      for (final e in m.entries)
        if (!_typed.contains(e.key)) e.key: e.value,
    };
    return SceneSheet._(
      scene:
          m['scene'] as String? ?? parent?.scene ?? (need('scene') as String),
      made: m['made'] as String? ?? parent?.made ?? '',
      S: ((m['S'] as num?) ?? parent?.S ?? (need('S') as num)).toDouble(),
      originX: origin != null
          ? (_need(origin, 'originX', '$at.origin') as num).toDouble()
          : parent!.originX,
      originY: origin != null
          ? (_need(origin, 'originY', '$at.origin') as num).toDouble()
          : parent!.originY,
      pictureW: picture[0],
      pictureH: picture[1],
      viewW: view[0],
      viewH: view[1],
      rules: m.containsKey('rules') || parent == null
          ? {
              for (final e in _o(_need(m, 'rules', at), '$at.rules').entries)
                e.key: _words(e.value),
            }
          : parent.rules,
      setKey: setKey ?? parent!.setKey,
      things: things ?? parent!.things,
      spots: spots ?? parent!.spots,
      groups: m['groups'] is Map
          ? {
              for (final e in (m['groups'] as Map).entries)
                if (e.value is List)
                  '${e.key}': [for (final x in e.value as List) '$x'],
            }
          : (parent?.groups ?? const {}),
      views: views ?? parent!.views,
      front: front ?? parent!.front,
      shadows: shadows ?? parent!.shadows,
      checks: results is List
          ? [
              for (final r in results)
                SceneCheck._(_words((r as Map)['name']), r['ok'] == true, [
                  for (final l in (r['lines'] as List? ?? const [])) '$l',
                ]),
            ]
          : (parent?.checks ?? const []),
      notes: m['notes'] is List
          ? [for (final n in m['notes'] as List) _words(n)]
          : const [],
      extras: extras,
      raw: m,
    );
  }

  /// A state the sheet gives as a part of its own (El mostrador's `calle`): read as a sheet, its missing parts the
  /// sheet's. Throws [SheetError] when the sheet has no such part.
  SceneSheet part(String name) => SceneSheet.fromJson(
    _o(
      extras[name] ?? (throw SheetError('the sheet has no part "$name"')),
      '\$.$name',
    ),
    parent: this,
    at: '\$.$name',
  );

  /// The spot [name]; a name the sheet does not have throws [SheetError] (a place with no name is not placed by eye).
  SceneSpot spot(String name) =>
      spots[name] ?? (throw SheetError('$scene: no spot "$name"'));

  /// The thing [id]; one the sheet does not have throws [SheetError].
  SceneThing thing(String id) =>
      things[id] ?? (throw SheetError('$scene: no thing "$id"'));

  /// The view [name]; one the sheet does not have throws [SheetError].
  SceneView view(String name) =>
      views[name] ?? (throw SheetError('$scene: no view "$name"'));

  /// The spots of group [name], in order.
  List<SceneSpot> group(String name) => [
    for (final n
        in groups[name] ?? (throw SheetError('$scene: no group "$name"')))
      spot(n),
  ];

  /// The shadow radius of [character] (`byCharacter`), or null when the sheet gives none.
  double? radiusOf(String character) => shadows.byCharacter[character];

  /// An engine with the sheet's scale and origin (shadows to (.9, -.1), as every set page of places 4 to 10).
  PpEngine engine({bool still = false}) => PpEngine(
    w: pictureW,
    h: pictureH,
    s: S,
    originX: originX,
    originY: originY,
    shadowX: .9,
    shadowY: -.1,
    still: still,
  );

  /// The screen box of a world box (pp-engine.js: the bounding box of its 8 projected corners, `rules.project`).
  static List<int> boxOfWorld(PpEngine e, List<num> world) =>
      Sheet.boxOfWorld(e, world);

  /// The old [Sheet] that a new scene hands to the code that reads one: the sheet's scene, scale, origin and sizes, its
  /// shadows' radii by character, no places, no pictures, and the frog's start (`juego.js:16`) left as the runner's own
  /// (the scene's `fresh` puts him at its own spot).
  Sheet legacy() => Sheet.fromJson({
    'scene': scene,
    'made': 'SceneSheet.legacy, from: $made',
    'S': S,
    'origin': {'originX': originX, 'originY': originY},
    'picture': [pictureW, pictureH],
    'view': [viewW, viewH],
    'pairPicture': [196, 104],
    'rules': <String, dynamic>{},
    'setKey': {'params': <String, dynamic>{}, 'key': '', 'baked': <dynamic>[]},
    'things': <String, dynamic>{},
    'spots': <String, dynamic>{},
    'lugar': <String, dynamic>{},
    'points': <String, dynamic>{},
    'views': <String, dynamic>{},
    'remap': <dynamic>[],
    'pictures': <String, dynamic>{},
    'level': <dynamic>[],
    'clips': <String, dynamic>{},
    'front': {'things': <dynamic>[]},
    'shadows': <String, dynamic>{},
    'dropped': <dynamic>[],
    'code': [
      {'line': 'juego.js:16', 'old': '', 'to': 'unchanged'},
    ],
  });
}
