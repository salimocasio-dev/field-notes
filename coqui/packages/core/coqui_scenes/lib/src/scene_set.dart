import 'package:coqui_pixel/coqui_pixel.dart';

/// A converted scene: its set is built by the engine from a set reference, and every place on the screen comes from its
/// sheet (page 12, section 5). What a frame needs of a scene beyond the page's [Scene]: the sheet, the engine the set is
/// built on, the set built from a key, and the characters' shadows.
abstract class SetScene extends Scene {
  /// The scene's sheet (`<id>-sheet.json`).
  Sheet get sheet;

  /// A new engine with the settings the set reference gives (`PP_SCENE`): size, scale, origin, shadow direction.
  /// [still]: the OS asks for reduced motion (no wind).
  PpEngine newEngine({bool still = false});

  /// An engine with the set's settings, kept for its projection (where the sheet's world points are on the screen).
  PpEngine get projection;

  /// Builds the set in the state [key] names (one of [setKey]'s values) into [e]: the port of the set reference, call
  /// for call. Ends as every set builder does, with `bakedPix` and `bakedZ` set.
  void buildSetFor(PpEngine e, PpBuild b, String key);

  @override
  void buildSet(PpEngine e, PpBuild b, Map<String, dynamic> W) =>
      buildSetFor(e, b, setKey(W));

  /// The shadows the characters cast in [W] (page 12, section 5, "The frame", step 3): who the sheet's `shadows`
  /// names, where and how it says.
  List<ShadowCast> shadows(Map<String, dynamic> W);

  /// Whether the frog keeps the old shadow juego.js's `frog()` draws under him. Not when the sheet names him in its
  /// `shadows`: the engine casts his shadow then (`shadows.dropped`).
  bool get frogShadow => !sheet.shadows.containsKey('coqui');
}

/// A converted scene whose review pictures hold places deeper in W than a top-level `{x, y}` (El campo's, order 34b:
/// `gente.<id>`, `bolas.<k>` and the flower `flor: [x, y]`). [ScenePictures]' `pictureW` remaps the top-level ones as for
/// every scene, then gives the scene the rest of the picture's own W ([placePair]), which sends each place through its
/// sheet's remap as campo-preview.html's `remapW` moves them.
abstract interface class PairPlaces {
  void placePair(Map<String, dynamic> set);
}

/// The baked states of one scene's set, each baked once on first use (page 12, section 5, step 1: "bake it first if
/// not cached"), with the engine they were baked on. A [BakedSet] is put back into the engine before each frame.
class SetBakes {
  SetBakes(this.scene, {bool still = false})
    : engine = scene.newEngine(still: still) {
    build = PpBuild(engine);
  }

  final SetScene scene;

  /// The engine the states are baked on and the frames are drawn on.
  final PpEngine engine;
  late final PpBuild build;

  final Map<String, BakedSet> _baked = {};

  /// How long each state's bake took, in ms, by key.
  final Map<String, double> bakeMs = {};

  /// The keys baked so far.
  Iterable<String> get keys => _baked.keys;

  /// The baked state [key], baked now if it is not yet.
  BakedSet bakeKey(String key) {
    final had = _baked[key];
    if (had != null) return had;
    final sw = Stopwatch()..start();
    scene.buildSetFor(engine, build, key);
    final baked = BakedSet.capture(engine);
    bakeMs[key] = sw.elapsedMicroseconds / 1000;
    return _baked[key] = baked;
  }

  /// The baked state that [W] needs (`scene.setKey(W)`).
  BakedSet bake(Map<String, dynamic> W) => bakeKey(scene.setKey(W));
}
