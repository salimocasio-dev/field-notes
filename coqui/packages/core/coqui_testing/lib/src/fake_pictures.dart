import 'package:coqui_ui/coqui_ui.dart';
import 'package:flutter/rendering.dart' show RenderProxyBox;
import 'package:material_ui/material_ui.dart';

/// A saved picture for a ref, or null to show the grey box. Order 06's frames from `coqui/ref/` plug in here.
/// [width] and [height] are what `PictureSource.of` was asked for, in picture pixels.
typedef FakeFrame = Widget? Function(
  PictureRef ref, {
  required int width,
  required int height,
});

/// Pictures of scenes, for tests and dev entries, without any scene.
///
/// What it does: [of] shows a grey box the size the real one would be, [of]'s `width` x `height` picture pixels
/// (196 x 104 when none are given), laid out as `PixelView` lays a picture out: from the width its parent
/// allows, at the whole number of device pixels per picture pixel that width holds (`pixelViewScale`; with no
/// limit, the picture's own width in logical pixels), and a tight box is filled. So a caller that sizes the box
/// for the real source gets the same layout from the fake. The box is labelled with the scene and the camera, and
/// over them with the ref's name when it has one (`PictureRef.name`); or, when [frames] gives one, that saved
/// frame instead. Callers do not change when the frames come. It records every ref shown and warmed.
///
/// What it does not do: no drawing of a scene, no state (`set`) shown, no animation.
class FakePictureSource implements PictureSource {
  FakePictureSource({this.frames});

  /// Saved frames, when there are any.
  final FakeFrame? frames;

  /// Every ref [of] was asked for, in order.
  final List<PictureRef> shown = [];

  /// Every ref [warm] was given, in order.
  final List<PictureRef> warmed = [];

  @override
  Widget of(
    PictureRef ref, {
    int width = 196,
    int height = 104,
    bool animated = false,
  }) {
    shown.add(ref);
    final saved = frames?.call(ref, width: width, height: height);
    if (saved != null) return saved;
    return _PictureBox(
      pictureWidth: width,
      pictureHeight: height,
      child: ColoredBox(
        color: const Color(0xFF9E9E9E),
        child: Center(
          // scaled down, never wrapped or overflowing, whatever the box
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.name != null) _label(ref.name!),
                _label('${ref.scene} ${ref.cam.join(',')}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> warm(Iterable<PictureRef> refs) async => warmed.addAll(refs);
}

Widget _label(String text) => Text(
  text,
  textAlign: TextAlign.center,
  textDirection: TextDirection.ltr,
  style: const TextStyle(color: Color(0xFF212121), fontSize: 10),
);

/// Lays its child out in the box `PixelView` would take for a picture of [pictureWidth] x [pictureHeight]:
/// the picture's size times the whole number of device pixels per picture pixel the parent's width holds,
/// divided by the device pixel ratio, and then the parent's constraints (a tight box wins).
class _PictureBox extends SingleChildRenderObjectWidget {
  const _PictureBox({
    required this.pictureWidth,
    required this.pictureHeight,
    required super.child,
  });

  final int pictureWidth;
  final int pictureHeight;

  static double _ratio(BuildContext context) =>
      MediaQuery.maybeDevicePixelRatioOf(context) ??
      View.of(context).devicePixelRatio;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPictureBox(
    pictureWidth: pictureWidth,
    pictureHeight: pictureHeight,
    devicePixelRatio: _ratio(context),
  );

  @override
  void updateRenderObject(BuildContext context, _RenderPictureBox ro) {
    ro
      ..pictureWidth = pictureWidth
      ..pictureHeight = pictureHeight
      ..devicePixelRatio = _ratio(context);
  }
}

class _RenderPictureBox extends RenderProxyBox {
  _RenderPictureBox({
    required int pictureWidth,
    required int pictureHeight,
    required double devicePixelRatio,
  }) : _w = pictureWidth,
       _h = pictureHeight,
       _dpr = devicePixelRatio;

  int _w;
  int _h;
  double _dpr;

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
    return c.constrain(Size(_w * scale / _dpr, _h * scale / _dpr));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _desired(constraints);

  @override
  void performLayout() {
    size = _desired(constraints);
    child?.layout(BoxConstraints.tight(size));
  }
}
