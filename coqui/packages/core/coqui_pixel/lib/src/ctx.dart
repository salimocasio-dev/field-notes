import 'dart:typed_data';

import 'package:coqui_pixel/src/sprite.dart';

/// The software canvas the sprite layer draws with. Same operations and meaning as the browser's 2D canvas,
/// writing into a picture. Images are sampled nearest-neighbour unless `smoothing` is on (the old code turns
/// it on in three places in sala.js; nowhere else).
///
/// A shell for now: order 11 writes it.
class Ctx {
  Ctx(Uint32List target, int w, int h) {
    throw UnimplementedError('order 11');
  }

  // DECISION(order 02): the starting values are the browser canvas's (alpha 1, black, line width 1),
  // except `smoothing`, off as the sentence above says.
  double globalAlpha = 1;
  int fillStyle = 0xFF000000;
  int strokeStyle = 0xFF000000;
  double lineWidth = 1;
  bool smoothing = false;

  void save() => throw UnimplementedError('order 11');
  void restore() => throw UnimplementedError('order 11');
  void translate(double x, double y) => throw UnimplementedError('order 11');
  void scale(double x, double y) => throw UnimplementedError('order 11');
  void rotate(double a) => throw UnimplementedError('order 11');
  void fillRect(num x, num y, num w, num h) =>
      throw UnimplementedError('order 11');
  void clearRect(num x, num y, num w, num h) =>
      throw UnimplementedError('order 11');
  void drawImage(Sprite s, num dx, num dy, [num? dw, num? dh]) =>
      throw UnimplementedError('order 11');
  void drawImageRect(
    Sprite s,
    num sx,
    num sy,
    num sw,
    num sh,
    num dx,
    num dy,
    num dw,
    num dh,
  ) => throw UnimplementedError('order 11');
  void beginPath() => throw UnimplementedError('order 11');
  void rect(num x, num y, num w, num h) => throw UnimplementedError('order 11');
  void arc(num x, num y, num r, num a0, num a1) =>
      throw UnimplementedError('order 11');
  void ellipse(num x, num y, num rx, num ry, num rot, num a0, num a1) =>
      throw UnimplementedError('order 11');
  void moveTo(num x, num y) => throw UnimplementedError('order 11');
  void lineTo(num x, num y) => throw UnimplementedError('order 11');
  void fill() => throw UnimplementedError('order 11');
  void stroke() => throw UnimplementedError('order 11');
  void clip() => throw UnimplementedError('order 11');
  Sprite snapshot(int x, int y, int w, int h) => throw UnimplementedError(
    'order 11',
  ); // a copy of part of the picture (sala.js, banco.js)
}
