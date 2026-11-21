import 'dart:typed_data';

import 'package:coqui_pixel/src/pp_engine.dart';

/// One baked state of a set, with everything the frame needs that a bake leaves behind in the engine.
///
/// A set's bake (`buildSet`) leaves more than the picture. The frame reads, from the engine: the baked picture and its
/// depth (`bakedPix`, `bakedZ`), which pixels are ground (`ground`), the ground's own depth (`groundZ`: `applyShadows`
/// and `drawTufts` test `zb == groundZ`), what kind of surface each pixel is (`kinds`: the tufts grow on grass), what
/// was in shadow at the bake (`staticShadow`: a tuft in it is drawn dark), the tufts and leaves that sway
/// (`tufts`, `leaves`), the colours the tufts are drawn in (`tuftLit`, `tuftDark`), and the glints on the water
/// (`glints`, `glintColour`). Two states of a set differ in all of these. A [BakedSet] holds a copy of them, taken from the
/// engine right after the bake ([capture]), and puts them back ([restoreInto]) before a frame of that state.
///
/// What a frame reads and the bake does not leave behind is not here: the picture (`pix`, `zb`: copied from the baked
/// ones), `shadowMask` (zero after `applyShadows`), the engine's settings (fixed for the scene).
class BakedSet {
  BakedSet({
    required this.pix,
    required this.zb,
    required this.ground,
    required this.groundZ,
    required this.kinds,
    required this.staticShadow,
    this.tufts = const [],
    this.leaves = const [],
    this.tuftLit,
    this.tuftDark,
    this.glints = const [],
    this.glintColour = 0,
  });

  /// A copy of what the engine holds after a bake. Call it when the bake is done and has set `bakedPix` and `bakedZ`
  /// (every set builder ends with `bakedPix.set(pix); bakedZ.set(zb)`).
  factory BakedSet.capture(PpEngine e) => BakedSet(
    pix: Uint32List.fromList(e.bakedPix),
    zb: Float32List.fromList(e.bakedZ),
    ground: Uint8List.fromList(e.ground),
    groundZ: Float32List.fromList(e.groundZ),
    kinds: Uint8List.fromList(e.kinds),
    staticShadow: Uint8List.fromList(e.staticShadow),
    tufts: List.of(e.tufts),
    leaves: List.of(e.leaves),
    tuftLit: List.of(e.tuftLit),
    tuftDark: List.of(e.tuftDark),
    glints: List.of(e.glints),
    glintColour: e.glintColour,
  );

  /// The baked picture and its depth.
  final Uint32List pix;
  final Float32List zb;

  /// Which pixels are ground, and the ground's depth.
  final Uint8List ground;
  final Float32List groundZ;

  /// The kind of surface of each pixel, and what was in shadow when the set was baked.
  final Uint8List kinds;
  final Uint8List staticShadow;

  /// The blades of grass and the leaves that sway. They are shared, not copied: a frame does not change them.
  final List<Tuft> tufts;
  final List<Leaf> leaves;

  /// The colours the blades are drawn in (the engine's `tuftLit` and `tuftDark`) when this state was baked: a set whose
  /// blades take the light of its hour sets them in its bake (El patio, order 32b: patio-set.html sets them when the
  /// page loads, one hour a page). Null: the engine's are left as they are.
  final List<int>? tuftLit, tuftDark;

  /// The glints on the set's water and their colour (the engine's `glints`, `glintColour`: set-kit.js `waterPixel`
  /// collects them at the bake, `drawGlints` draws them each frame; El campo's, order 34b). Empty for a set with no
  /// water. Shared, not copied: a frame does not change them.
  final List<Glint> glints;
  final int glintColour;

  /// Puts every one of these into [e], and the baked picture and depth into its `pix` and `zb`, so that the engine is
  /// as it was when this state was baked. The frame does this first.
  void restoreInto(PpEngine e) {
    e.bakedPix.setAll(0, pix);
    e.bakedZ.setAll(0, zb);
    e.ground.setAll(0, ground);
    e.groundZ.setAll(0, groundZ);
    e.kinds.setAll(0, kinds);
    e.staticShadow.setAll(0, staticShadow);
    e.tufts
      ..clear()
      ..addAll(tufts);
    e.leaves
      ..clear()
      ..addAll(leaves);
    final lit = tuftLit, dark = tuftDark;
    if (lit != null) e.tuftLit.setAll(0, lit);
    if (dark != null) e.tuftDark.setAll(0, dark);
    e.glints
      ..clear()
      ..addAll(glints);
    e.glintColour = glintColour;
    e.pix.setAll(0, pix);
    e.zb.setAll(0, zb);
  }
}
