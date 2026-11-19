/// `PixelView`: shows a pixel picture at a whole-number scale with no smoothing
/// (page 12, section 3; page 11-pixel-engine, decision 3).
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

/// Device pixels per picture pixel:
/// `max(1, floor(availableWidth * devicePixelRatio / width))`.
///
/// [availableWidth] is in logical pixels. A hair (1e-6) is added before the floor
/// so that a width that is exactly a whole multiple, such as 980 device pixels
/// for 196 picture pixels, is not lost to floating point noise (373.333... *
/// 2.625 is 979.99999...).
int pixelViewScale({
  required double availableWidth,
  required double devicePixelRatio,
  required int width,
}) {
  final s = (availableWidth * devicePixelRatio / width + 1e-6).floor();
  return s < 1 ? 1 : s;
}

/// Shows a picture: [pixels] is `width * height` values, each `0xAABBGGRR` (the
/// engine's `rgb()`), so the bytes in memory are R, G, B, A.
///
/// The picture is drawn at a whole number of device pixels per picture pixel,
/// [pixelViewScale], from the width the parent allows (the available width; with
/// no limit, the picture's own width in logical pixels). It is not smoothed
/// (`FilterQuality.none`). It is laid out at that size divided by the device pixel
/// ratio, and drawn on whole device pixels (its position is snapped to the pixel
/// grid). If the parent forces a box smaller than scale 1 needs, the picture is
/// clipped to the box, not shrunk.
///
/// It repaints when [repaint] fires (the game ticks it) and not otherwise: the
/// pixels are read and uploaded at that moment, and when they arrive the new
/// picture is drawn. A still picture never repaints. A different [pixels] list (or
/// size) is a new picture and is uploaded at once.
///
/// [onTapPixel] gets the picture pixel (x, y), counted from the top left, under a
/// tap.
class PixelView extends StatefulWidget {
  const PixelView({
    super.key,
    required this.pixels,
    required this.width,
    required this.height,
    this.repaint,
    this.onTapPixel,
    this.semanticLabel,
  }) : assert(width > 0 && height > 0);

  final Uint32List pixels;
  final int width;
  final int height;
  final Listenable? repaint;
  final void Function(int x, int y)? onTapPixel;

  /// What a screen reader says about the picture, if anything.
  final String? semanticLabel;

  @override
  State<PixelView> createState() => _PixelViewState();
}

class _PixelViewState extends State<PixelView> {
  ui.Image? _image;
  int _token = 0;
  final _paintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.repaint?.addListener(_upload);
    _upload();
  }

  @override
  void didUpdateWidget(PixelView old) {
    super.didUpdateWidget(old);
    if (old.repaint != widget.repaint) {
      old.repaint?.removeListener(_upload);
      widget.repaint?.addListener(_upload);
    }
    if (!identical(old.pixels, widget.pixels) ||
        old.width != widget.width ||
        old.height != widget.height) {
      _upload();
    }
  }

  @override
  void dispose() {
    widget.repaint?.removeListener(_upload);
    _token++;
    _image?.dispose();
    _image = null;
    super.dispose();
  }

  /// Copies the pixels now (the game goes on drawing into the list) and turns them
  /// into an image; the newest upload wins.
  void _upload() {
    final w = widget.width;
    final h = widget.height;
    final src = widget.pixels;
    final bytes = Uint8List.fromList(
      src.buffer.asUint8List(src.offsetInBytes, w * h * 4),
    );
    final token = ++_token;
    ui.decodeImageFromPixels(bytes, w, h, ui.PixelFormat.rgba8888, (image) {
      if (!mounted || token != _token) {
        image.dispose();
        return;
      }
      setState(() {
        _image?.dispose();
        _image = image;
      });
    });
  }

  void _tap(TapUpDetails d) {
    final cb = widget.onTapPixel;
    if (cb == null) return;
    final box = _paintKey.currentContext?.findRenderObject();
    if (box is! RenderPixelView) return;
    final p = box.pixelAt(d.localPosition);
    if (p != null) cb(p.dx.toInt(), p.dy.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    Widget view = _PixelPaint(
      key: _paintKey,
      image: _image,
      width: widget.width,
      height: widget.height,
      devicePixelRatio: dpr,
    );
    if (widget.onTapPixel != null) {
      view = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _tap,
        child: view,
      );
    }
    return Semantics(
      image: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: view,
    );
  }
}

class _PixelPaint extends LeafRenderObjectWidget {
  const _PixelPaint({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    required this.devicePixelRatio,
  });

  final ui.Image? image;
  final int width;
  final int height;
  final double devicePixelRatio;

  @override
  RenderPixelView createRenderObject(BuildContext context) => RenderPixelView(
    image: image,
    pictureWidth: width,
    pictureHeight: height,
    devicePixelRatio: devicePixelRatio,
  );

  @override
  void updateRenderObject(BuildContext context, RenderPixelView ro) {
    ro
      ..image = image
      ..pictureWidth = width
      ..pictureHeight = height
      ..devicePixelRatio = devicePixelRatio;
  }
}

/// The render object of [PixelView].
@visibleForTesting
class RenderPixelView extends RenderBox {
  RenderPixelView({
    this._image,
    required int pictureWidth,
    required int pictureHeight,
    required double devicePixelRatio,
  }) : _w = pictureWidth,
       _h = pictureHeight,
       _dpr = devicePixelRatio;

  ui.Image? _image;
  int _w;
  int _h;
  double _dpr;
  int _scale = 1;

  /// How many times [paint] ran (for tests: a picture that nothing asked to be
  /// redrawn is not redrawn).
  int paintCount = 0;

  /// Device pixels per picture pixel as laid out.
  int get scale => _scale;

  /// The picture's size in device pixels as laid out (the picture's size times
  /// [scale]); the box may be smaller if the parent forced it.
  Size get deviceSize =>
      Size((_w * _scale).toDouble(), (_h * _scale).toDouble());

  set image(ui.Image? v) {
    if (identical(v, _image)) return;
    _image = v;
    markNeedsPaint();
  }

  set pictureWidth(int v) {
    if (v == _w) return;
    _w = v;
    markNeedsLayout();
  }

  set pictureHeight(int v) {
    if (v == _h) return;
    _h = v;
    markNeedsLayout();
  }

  set devicePixelRatio(double v) {
    if (v == _dpr) return;
    _dpr = v;
    markNeedsLayout();
  }

  Size _desired(BoxConstraints c) {
    final avail = c.maxWidth.isFinite ? c.maxWidth : _w.toDouble();
    final scale = pixelViewScale(
      availableWidth: avail,
      devicePixelRatio: _dpr,
      width: _w,
    );
    return Size(_w * scale / _dpr, _h * scale / _dpr);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(_desired(constraints));

  @override
  void performLayout() {
    final avail = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : _w.toDouble();
    _scale = pixelViewScale(
      availableWidth: avail,
      devicePixelRatio: _dpr,
      width: _w,
    );
    size = constraints.constrain(Size(_w * _scale / _dpr, _h * _scale / _dpr));
  }

  /// The picture pixel under [local] (a point in this box, logical pixels), or
  /// null outside the picture.
  Offset? pixelAt(Offset local) {
    final dx = (local.dx * _dpr / _scale).floor();
    final dy = (local.dy * _dpr / _scale).floor();
    if (dx < 0 || dy < 0 || dx >= _w || dy >= _h) return null;
    return Offset(dx.toDouble(), dy.toDouble());
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    paintCount++;
    final image = _image;
    if (image == null) return;
    final canvas = context.canvas;
    // Snap the origin to a whole device pixel: where the box lands on the screen
    // is rounded, so every picture pixel covers whole device pixels.
    var snapX = 0.0;
    var snapY = 0.0;
    try {
      final origin = localToGlobal(Offset.zero);
      snapX = ((origin.dx * _dpr).roundToDouble() - origin.dx * _dpr) / _dpr;
      snapY = ((origin.dy * _dpr).roundToDouble() - origin.dy * _dpr) / _dpr;
    } on Object {
      // Not attached to a render view (a bare test harness): no snapping.
    }
    canvas.save();
    final full = Size(_w * _scale / _dpr, _h * _scale / _dpr);
    if (size.width < full.width - 1e-9 || size.height < full.height - 1e-9) {
      canvas.clipRect(offset & size, doAntiAlias: false);
    }
    canvas.translate(offset.dx + snapX, offset.dy + snapY);
    canvas.scale(1 / _dpr);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
      Rect.fromLTWH(0, 0, (_w * _scale).toDouble(), (_h * _scale).toDouble()),
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    canvas.restore();
  }
}
