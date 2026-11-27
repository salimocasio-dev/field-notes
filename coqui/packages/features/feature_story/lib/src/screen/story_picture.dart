/// The picture of the play screen: the display picture, touch-turn outline
/// feedback (`Noche-Motion-Tocar.dc.html`), and the speech bubble over it.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_pixel/coqui_pixel.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/motion.dart';
import 'package:feature_story/src/runner/bubble_place.dart';
import 'package:feature_story/src/runner/story_runner.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/screen/story_bubble.dart';
import 'package:material_ui/material_ui.dart';

/// Computes the whole-number scaled logical [Size] of the `196 × 216` display
/// picture for [availableWidth] and [devicePixelRatio].
Size storyPictureSize({
  required double availableWidth,
  required double devicePixelRatio,
}) {
  final scale = pixelViewScale(
    availableWidth: availableWidth,
    devicePixelRatio: devicePixelRatio,
    width: displayW,
  );
  return Size(
    displayW * scale / devicePixelRatio,
    displayH * scale / devicePixelRatio,
  );
}

/// `#stage`: the 196 × 216 display picture at a whole-number scale (`PixelView`),
/// never mirrored in RTL, with the touch-turn outline feedback and speech
/// bubble over it. A tap on it is mapped back to the scene's picture with
/// `displayToPicture` and the scene finds what is there.
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
        final size = storyPictureSize(
          availableWidth: avail,
          devicePixelRatio: dpr,
        );
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
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: repaint,
                    builder: (context, _) => StoryTouchFeedbackOverlay(
                      feedback: runner.view.touchFeedback,
                      cam: runner.cam,
                      stageSize: size,
                      speakingNow: runner.view.speakingNow,
                      reduceMotion: reduceMotion,
                    ),
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

/// Touch-turn feedback overlay drawn over the unmirrored pixel picture
/// (`Noche-Motion-Tocar.dc.html`, N8.8):
///
/// - 3 px outline with radius 12 around the touched thing's hint box.
/// - Wrong (`TouchFeedbackKind.miss`): `NocheColors.text` outline (never red),
///   drawn in `quick`, held for as long as the line plays again (or
///   [StoryMotion.touchMissHold] when no clip plays), then faded out in `move`.
/// - Right (`TouchFeedbackKind.right`): `NocheColors.right` outline drawn in
///   `quick` with one expanding 2 px `NocheColors.right` ring (`1.0 -> 1.08`,
///   opacity `0.9 -> 0`) in `settle` (omitted under reduced motion).
class StoryTouchFeedbackOverlay extends StatefulWidget {
  const StoryTouchFeedbackOverlay({
    super.key,
    required this.feedback,
    required this.cam,
    required this.stageSize,
    required this.speakingNow,
    this.reduceMotion = false,
  });

  final TouchFeedback? feedback;
  final List<num> cam;
  final Size stageSize;
  final bool speakingNow;
  final bool reduceMotion;

  static const double outlineWidth = 3;
  static const double outlineRadius = 12;
  static const double ringWidth = 2;
  static const double ringEndScale = 1.08;

  @override
  State<StoryTouchFeedbackOverlay> createState() =>
      _StoryTouchFeedbackOverlayState();
}

class _StoryTouchFeedbackOverlayState extends State<StoryTouchFeedbackOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _outline = AnimationController(vsync: this);
  late final AnimationController _hold = AnimationController(vsync: this)
    ..addStatusListener(_onHoldStatus);
  late final AnimationController _ring = AnimationController(vsync: this);

  TouchFeedback? _active;
  bool _fadingOut = false;
  bool _waitingClipEnd = false;
  bool _sawSpeakingAfterMiss = false;

  @override
  void initState() {
    super.initState();
    final fb = widget.feedback;
    if (fb != null && fb.kind != TouchFeedbackKind.none) {
      _active = fb;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _active?.seq == fb.seq) _startFeedback(fb);
      });
    }
  }

  @override
  void didUpdateWidget(StoryTouchFeedbackOverlay old) {
    super.didUpdateWidget(old);
    final next = widget.feedback;
    if (next == null) {
      if (_active != null) {
        _clearImmediate();
      }
      return;
    }
    if (next.seq != _active?.seq) {
      _startFeedback(next);
      return;
    }
    if (_active?.kind == TouchFeedbackKind.miss) {
      if (widget.speakingNow) {
        _sawSpeakingAfterMiss = true;
      } else if (_waitingClipEnd && !widget.speakingNow) {
        _waitingClipEnd = false;
        _fadeOut();
      } else if (_sawSpeakingAfterMiss &&
          !widget.speakingNow &&
          !_fadingOut &&
          _hold.isCompleted) {
        _fadeOut();
      }
    }
  }

  void _clearImmediate() {
    _hold.stop();
    _outline.stop();
    _ring.stop();
    _hold.value = 0;
    _outline.value = 0;
    _ring.value = 0;
    _active = null;
    _fadingOut = false;
    _waitingClipEnd = false;
    _sawSpeakingAfterMiss = false;
  }

  void _startFeedback(TouchFeedback fb) {
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    _active = fb;
    _fadingOut = false;
    _waitingClipEnd = false;
    _sawSpeakingAfterMiss = widget.speakingNow;

    _outline.duration = motion.quick;
    _outline.forward(from: 0.0);

    _hold.duration = fb.kind == TouchFeedbackKind.miss
        ? StoryMotion.touchMissHold
        : StoryMotion.touchHitHold;
    _hold.forward(from: 0.0);

    if (fb.kind == TouchFeedbackKind.right && !motion.reduced) {
      _ring.duration = motion.settle;
      _ring.forward(from: 0.0);
    } else {
      _ring.stop();
      _ring.value = 0.0;
    }
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || _active == null) {
      return;
    }
    if (_active!.kind == TouchFeedbackKind.miss && widget.speakingNow) {
      _waitingClipEnd = true;
      return;
    }
    _fadeOut();
  }

  void _fadeOut() {
    if (_fadingOut || !mounted) return;
    _fadingOut = true;
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    _outline.animateTo(
      0.0,
      duration: motion.reduced ? motion.quick : motion.move,
      curve: motion.exit,
    );
  }

  @override
  void dispose() {
    _hold.removeStatusListener(_onHoldStatus);
    _hold.dispose();
    _outline.dispose();
    _ring.dispose();
    super.dispose();
  }

  Rect? _stageRectFor(List<num> box) {
    if (box.length < 4 || widget.cam.length < 4) return null;
    final camX = widget.cam[0].toDouble();
    final camY = widget.cam[1].toDouble();
    final cw = widget.cam[2].toDouble();
    final ch = widget.cam[3].toDouble();
    if (cw <= 0 || ch <= 0) return null;
    final bx = box[0].toDouble();
    final by = box[1].toDouble();
    final bw = box[2].toDouble();
    final bh = box[3].toDouble();
    final zx = widget.stageSize.width / cw;
    final zy = widget.stageSize.height / ch;
    final left = ((bx - camX) * zx).clamp(0.0, widget.stageSize.width);
    final top = ((by - camY) * zy).clamp(0.0, widget.stageSize.height);
    final right = ((bx + bw - camX) * zx).clamp(left, widget.stageSize.width);
    final bottom = ((by + bh - camY) * zy).clamp(top, widget.stageSize.height);
    final w = math.max(16.0, right - left);
    final h = math.max(16.0, bottom - top);
    final clampedLeft = math.min(
      left,
      math.max(0.0, widget.stageSize.width - w),
    );
    final clampedTop = math.min(
      top,
      math.max(0.0, widget.stageSize.height - h),
    );
    return Rect.fromLTWH(clampedLeft, clampedTop, w, h);
  }

  @override
  Widget build(BuildContext context) {
    final fb = _active;
    if (fb == null || fb.kind == TouchFeedbackKind.none) {
      return const SizedBox.shrink();
    }
    final rect = _stageRectFor(fb.box);
    if (rect == null) return const SizedBox.shrink();

    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: widget.reduceMotion,
    );
    final color = fb.kind == TouchFeedbackKind.right
        ? NocheColors.right
        : NocheColors.text;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_outline, _ring]),
        builder: (context, _) {
          final outlineOpacity = _fadingOut
              ? _outline.value.clamp(0.0, 1.0)
              : motion.enter.transform(_outline.value).clamp(0.0, 1.0);
          final showRing =
              fb.kind == TouchFeedbackKind.right &&
              !motion.reduced &&
              _ring.isAnimating;
          if (outlineOpacity <= 0.0 && !showRing) {
            return const SizedBox.shrink();
          }
          final ringP = motion.enter.transform(_ring.value);
          final ringScale =
              1.0 + (StoryTouchFeedbackOverlay.ringEndScale - 1.0) * ringP;
          final ringOpacity = (0.9 * (1.0 - ringP)).clamp(0.0, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              PositionedDirectional(
                start: rect.left,
                top: rect.top,
                width: rect.width,
                height: rect.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showRing)
                      Positioned.fill(
                        child: Opacity(
                          opacity: ringOpacity,
                          child: Transform.scale(
                            scale: ringScale,
                            child: DecoratedBox(
                              key: const ValueKey('story_touch_right_ring'),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  StoryTouchFeedbackOverlay.outlineRadius,
                                ),
                                border: Border.all(
                                  color: NocheColors.right,
                                  width: StoryTouchFeedbackOverlay.ringWidth,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (outlineOpacity > 0.0)
                      Positioned.fill(
                        child: Opacity(
                          opacity: outlineOpacity,
                          child: DecoratedBox(
                            key: const ValueKey('story_touch_outline'),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                StoryTouchFeedbackOverlay.outlineRadius,
                              ),
                              border: Border.all(
                                color: color,
                                width: StoryTouchFeedbackOverlay.outlineWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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
