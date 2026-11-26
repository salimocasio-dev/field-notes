/// The picture of the play screen: the display picture, and the speech bubble over it.
library;

import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:material_ui/material_ui.dart';

/// `#stage`: the 196 × 216 display picture at a whole-number scale (`PixelView`),
/// never mirrored in RTL, with the speech bubble over it on non-speaking steps.
/// A tap on it is mapped back to the scene's picture with `displayToPicture`
/// and the scene finds what is there.
class StoryPicture extends StatelessWidget {
  const StoryPicture({
    super.key,
    required this.runner,
    required this.pixels,
    required this.repaint,
    required this.onSize,
    this.reduceMotion = false,
    this.language,
    this.showBubble = true,
    this.availableWidth,
  });

  final StoryRunner runner;

  /// The display picture the frame draws into.
  final Uint32List pixels;
  final Listenable repaint;

  /// Told the stage's size in logical pixels each time it is laid out.
  final void Function(Size stage) onSize;
  final bool reduceMotion;

  /// Course language for the text inside speech bubbles over the unmirrored scene.
  final Language? language;

  /// Whether to render the over-scene speech bubble (false on Noche speaking turns).
  final bool showBubble;

  /// Optional explicit width constraint for whole-number scaling when wrapped in
  /// a clipped 400-high stage container.
  final double? availableWidth;

  @override
  Widget build(BuildContext context) {
    final dpr =
        MediaQuery.maybeDevicePixelRatioOf(context) ??
        View.of(context).devicePixelRatio;
    return LayoutBuilder(
      builder: (context, c) {
        final avail =
            availableWidth ??
            (c.maxWidth.isFinite ? c.maxWidth : displayW.toDouble());
        final scale = pixelViewScale(
          availableWidth: avail,
          devicePixelRatio: dpr,
          width: displayW,
        );
        final size = Size(displayW * scale / dpr, displayH * scale / dpr);
        onSize(size);
        // Pixel scenes and scene-anchored bubble coordinates never mirror in RTL;
        // the text inside StoryBubbleLayer still reads in [language]'s direction.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: PixelView(
                    pixels: pixels,
                    width: displayW,
                    height: displayH,
                    repaint: repaint,
                    onTapPixel: (x, y) {
                      runner.pump();
                      final p = displayToPicture(runner.cam, x, y);
                      runner.tap(p.x, p.y);
                    },
                  ),
                ),
                if (showBubble)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: repaint,
                      builder: (context, _) {
                        final v = runner.view;
                        return StoryBubbleLayer(
                          visible: v.bubbleOn,
                          kind: v.bubbleKind,
                          text: v.bubbleText,
                          estate: v.bubbleEstate,
                          reduceMotion: reduceMotion,
                          language: language,
                          placementFor: (bubble) =>
                              placeFor(runner, size, bubble),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Where the bubble stands now (juego.js `placeBub`): beside or above who speaks, or above the mic button. Null: hidden.
BubblePlacement? placeFor(
  StoryRunner r,
  Size stage,
  Size bubble, {
  MicAnchor? mic,
}) {
  final who = r.BUBQ;
  if (who == null) return null;
  if (who == 'mic') return placeAboveMic(mic ?? r.micAnchor, bubble.width);
  final q = r.W['cq'] as Map<String, dynamic>;
  return placeBubble(
    who: who,
    cam: r.cam,
    cw: stage.width,
    ch: stage.height,
    bw: bubble.width,
    bh: bubble.height,
    frog: r.frogBox(q),
    frogDy: q['dy'] as num,
    at: r.donde(who),
  );
}
