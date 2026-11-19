import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:material_ui/material_ui.dart';

/// nivel.js: `CW,CH`: the cells of the level check are 96 x 106 art pixels (nivel.js:66).
const int _levelCellWidth = 96;
const int _levelCellHeight = 106;

/// nivel.js: `E2.SW`: the width of a scene, which every scene file takes from the scene kit
/// (`SW=KIT.SW`, 240).
const int _kitSceneWidth = 240;

/// A scene in a given state, seen through a camera: a review pair's side, a
/// word's picture. scene: the scene id; set: the keys a pair file's `set` writes
/// into the scene's world; cam: the view, as the pair file gives it; name: what the picture is
/// called in a scene's sheet.
///
/// Two pictures are the same when their scene, set, cam and name are (a value, not an identity: a
/// [PictureSource] may key a cache by it). The name is there because two different pictures can share
/// scene, state and view and differ only in their crop (abuela.si and cierra.no in El frente), so
/// the source needs it to tell them apart.
class PictureRef {
  const PictureRef({
    required this.scene,
    this.set = const {},
    required this.cam,
    this.name,
  });

  /// One side of a review pair, drawn by [PictureSpec.scene] or else the pair's own scene. Named
  /// `"<pair.word>.si"` for the pair's yes picture and `"<pair.word>.no"` for its no picture
  /// (the keys of a pair file: `si`, `no`). [side] is told apart by being the pair's own [ReviewPair.yes]
  /// or [ReviewPair.no] (the same object, or else one with the same scene, set and cam when only one of
  /// the two has them); a [side] that is neither leaves the name null.
  factory PictureRef.of(ReviewPair pair, PictureSpec side) => PictureRef(
    scene: side.scene ?? pair.scene,
    set: side.set,
    cam: side.cam,
    name: _sideName(pair, side),
  );

  /// Picture number [index] of a level-check [item] (nivel.js, `NV[n].p[index]`), as `nivelPanel()` draws
  /// it: [pairs] holds the review pairs by their word, since a picture of the check is
  /// `[the pair's word, "si" or "no", the x the square crop is centred on]` (nivel.js:14-15). Its scene and
  /// set are those of that side of the pair; its view is a square crop of the pair's own: as tall as the pair's
  /// camera, [_levelCellWidth] / [_levelCellHeight] as wide as it is tall, centred on the given x (or, with none,
  /// on the middle of the pair's camera) and kept inside the scene, `[0, sceneWidth - width]`. Named
  /// `"nivel.<item.word>.<index>"`.
  ///
  /// [sceneWidth] is nivel.js's `E2.SW` (240 for every scene built so far). Throws an [ArgumentError] when
  /// [index] is not one of the item's pictures or [pairs] has no pair for the picture's word.
  factory PictureRef.ofLevel(
    LevelItem item,
    int index, {
    required Map<String, ReviewPair> pairs,
    int sceneWidth = _kitSceneWidth,
  }) {
    if (index < 0 || index >= item.pictures.length) {
      throw ArgumentError.value(
        index,
        'index',
        'the level item "${item.word}" has ${item.pictures.length} pictures',
      );
    }
    final pic = item.pictures[index];
    final word = pic[0] as String;
    final pair = pairs[word];
    if (pair == null) {
      throw ArgumentError.value(
        word,
        'pairs',
        'the level item "${item.word}" picture $index needs the review pair "$word"',
      );
    }
    final spec = pic[1] == 'no' ? pair.no : pair.yes;
    final cm = spec.cam;
    final h = cm[3];
    final w = h * _levelCellWidth / _levelCellHeight;
    final cx = (pic.length > 2 && pic[2] != null)
        ? pic[2]! as num
        : cm[0] + cm[2] / 2;
    final x = math.max(0, math.min(sceneWidth - w, cx - w / 2));
    return PictureRef(
      scene: spec.scene ?? pair.scene,
      set: spec.set,
      cam: [x, cm[1], w, h],
      name: 'nivel.${item.word}.$index',
    );
  }

  final String scene;
  final Map<String, dynamic> set;
  final List<num> cam;

  /// The picture's name in its scene's sheet: `"<word>.si"`, `"<word>.no"`, `"nivel.<word>.<index>"`.
  /// Null for a picture made by hand.
  final String? name;

  @override
  bool operator ==(Object other) =>
      other is PictureRef &&
      other.scene == scene &&
      other.name == name &&
      _deepEquals(other.set, set) &&
      _deepEquals(other.cam, cam);

  @override
  int get hashCode => Object.hash(scene, name, _deepHash(set), _deepHash(cam));

  @override
  String toString() => 'PictureRef($scene, $set, $cam, $name)';
}

String? _sideName(ReviewPair pair, PictureSpec side) {
  if (identical(side, pair.yes)) return '${pair.word}.si';
  if (identical(side, pair.no)) return '${pair.word}.no';
  final isYes = _sameSpec(side, pair.yes);
  final isNo = _sameSpec(side, pair.no);
  if (isYes && !isNo) return '${pair.word}.si';
  if (isNo && !isYes) return '${pair.word}.no';
  return null;
}

bool _sameSpec(PictureSpec a, PictureSpec b) =>
    a.scene == b.scene &&
    _deepEquals(a.set, b.set) &&
    _deepEquals(a.cam, b.cam);

/// Equality of the JSON-like values a pair file holds: maps (in any order), lists, numbers (1 equals 1.0),
/// strings, booleans, null.
bool _deepEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k) || !_deepEquals(a[k], b[k])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// A hash that agrees with [_deepEquals]: a map's does not depend on its order, and 1 hashes as 1.0.
int _deepHash(Object? v) {
  if (v is Map) {
    var h = 0;
    for (final e in v.entries) {
      h += Object.hash(_deepHash(e.key), _deepHash(e.value));
    }
    return Object.hash('map', h);
  }
  if (v is List) return Object.hash('list', Object.hashAll(v.map(_deepHash)));
  if (v is num) return v.toDouble().hashCode;
  return v.hashCode;
}

/// Where features get pictures of scenes. They never import a scene.
abstract interface class PictureSource {
  /// A scene in a given state, the 196-wide window at cam (section 5, "The camera"), cropped to height.
  Widget of(
    PictureRef ref, {
    int height = 104,
    int? scale,
    bool animated = false,
  });
  Future<void> warm(Iterable<PictureRef> refs); // bake ahead
}

/// Everything a feature is given. The shell builds one from the real packages;
/// tests and dev entries build one from the fakes in coqui_testing.
class Services {
  const Services({
    required this.progress,
    required this.course,
    required this.clips,
    required this.speech,
    required this.call,
    required this.nav,
    required this.clock,
    required this.rng,
    required this.haptics,
    required this.info,
    required this.pictures,
    required this.storage,
    this.reduceMotion = false,
  });

  final ProgressStore progress;
  final CourseCatalog course;
  final ClipPlayer clips;
  final SpeechListener speech;
  final CallSession call;
  final AppNavigator nav;
  final Clock clock;
  final Rng rng;
  final Haptics haptics;
  final AppInfo info;
  final PictureSource pictures;
  final KeyValueStore Function(String space) storage;
  final bool reduceMotion;
}

/// A feature's tab in the tab bar.
class FeatureTab {
  const FeatureTab({
    required this.id,
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String id;
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// What a feature exports: its one module. The shell holds the only list of modules.
abstract interface class FeatureModule {
  String get id;
  FeatureTab? tab(Services s);
  Widget? screenFor(AppRoute route, Services s); // null: not mine
}
