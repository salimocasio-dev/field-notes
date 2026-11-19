import 'dart:typed_data';

/// Port of historia/engine.js: Buf, RP, OUT, bay, hs, rgb, fr, every mk* sprite, sky, grass, shadow, face, coqui, bubble, GL, GC.
///
/// For now only the picture a sprite is: w × h pixels, each 0xAABBGGRR. Order 11 writes the rest.
class Sprite {
  // DECISION(order 02): page 12 gives the fields and no constructor; this is the plain one.
  Sprite(this.w, this.h, this.px);

  final int w, h;
  final Uint32List px;
}
