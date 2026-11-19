import 'dart:typed_data';

/// Port of pixel/pp-engine.js. Every function there becomes a method with the same name and parameters.
///
/// A shell for now: order 10 writes the body and adds the engine's methods (rgb, rampOf, bayerAt, tint, hash,
/// noise, project, unproject, sphere, capsule, box, castShadow, applyShadows, shadeEdges, growGrass, drawTufts,
/// drawLeaves, bakeOcclusion, plot, growTree, figure, flushShadows, drawDots, haloDots, drawArrow).
class PpEngine {
  PpEngine({
    required int w,
    required int h,
    required double s,
    double originX = 0,
    double originY = 0,
    double shadowX = 1.3,
    double shadowY = -.12,
    bool still = false,
  }) : pix = Uint32List(0),
       bakedPix = Uint32List(0),
       zb = Float32List(0),
       bakedZ = Float32List(0),
       groundZ = Float32List(0),
       ground = Uint8List(0),
       shadowMask = Uint8List(0),
       staticShadow = Uint8List(0),
       kinds = Uint8List(0) {
    throw UnimplementedError('order 10');
  }

  final Uint32List pix, bakedPix;
  final Float32List zb, bakedZ, groundZ;
  final Uint8List ground, shadowMask, staticShadow, kinds;
}
