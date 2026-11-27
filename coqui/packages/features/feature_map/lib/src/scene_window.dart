/// Shared clipped scene picture window for `feature_map` (N8.4).
///
/// Computes the same whole-number device-pixel scale on both the map card
/// (`72 x 72`, radius `16`) and the place hero (`screenWidth x (296 + topPad)`,
/// radius `0`), so [NocheWindow] moves only the clipped aperture while the
/// underlying `PixelView` never zooms.
library;

import 'dart:math' as math;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Native scene picture width in picture pixels.
const int scenePictureWidth = 196;

/// Native scene picture height in picture pixels.
const int scenePictureHeight = 104;

/// Base logical height of the full-bleed hero window on `PlaceScreen` before
/// adding top safe-area padding.
const double placeHeroBaseHeight = 296;

/// Computes the whole-number device-pixel [scale] and logical [pictureSize]
/// needed for a `196 x 104` scene picture to cover [viewportWidth] by
/// [heroHeight] at device pixel ratio [dpr].
@visibleForTesting
({int scale, Size pictureSize}) computeScenePictureGeometry({
  required double viewportWidth,
  required double heroHeight,
  required double dpr,
}) {
  final scale = math.max(
    1,
    math.max(
      (viewportWidth * dpr / scenePictureWidth - 1e-6).ceil(),
      (heroHeight * dpr / scenePictureHeight - 1e-6).ceil(),
    ),
  );
  return (
    scale: scale,
    pictureSize: Size(
      scenePictureWidth * scale / dpr,
      scenePictureHeight * scale / dpr,
    ),
  );
}

/// Renders a scene picture inside a [NocheWindow] at a shared whole-number
/// pixel scale across the map card thumbnail and the place hero.
class MapSceneWindow extends StatelessWidget {
  const MapSceneWindow({
    super.key,
    required this.pictures,
    required this.pictureRef,
    required this.placeholder,
    this.borderRadius = 0,
    this.tag,
  });

  final PictureSource pictures;
  final PictureRef? pictureRef;
  final Widget placeholder;
  final double borderRadius;
  final Object? tag;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? View.of(context).devicePixelRatio;
    final padTop = media?.padding.top ?? 0;
    final screenW = media?.size.width ?? 0;
    final heroH = placeHeroBaseHeight + padTop;

    return NocheLtr(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final winW = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : screenW;
          final winH = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : heroH;
          final ref = pictureRef;
          if (ref == null) {
            return NocheWindow(
              tag: tag,
              borderRadius: borderRadius,
              pictureSize: Size(winW, winH),
              pictureOffset: Offset.zero,
              child: placeholder,
            );
          }
          final geom = computeScenePictureGeometry(
            viewportWidth: math.max(screenW, winW),
            heroHeight: math.max(heroH, winH),
            dpr: dpr,
          );
          final picSize = geom.pictureSize;
          final offset = Offset(
            (winW - picSize.width) / 2,
            (winH - picSize.height) / 2,
          );
          return NocheWindow(
            tag: tag,
            borderRadius: borderRadius,
            pictureSize: picSize,
            pictureOffset: offset,
            child: NocheLtr(
              child: pictures.of(
                ref,
                width: scenePictureWidth,
                height: scenePictureHeight,
              ),
            ),
          );
        },
      ),
    );
  }
}
