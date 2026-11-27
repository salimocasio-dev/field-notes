/// The pieces cual.html and nivel.html share, built from coqui_ui: the block of pictures with a frame each, the
/// words of a start or end screen (`#fin`), and the one-line semantics of an option.
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/review_session.dart' show OptionRing;
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:flutter/rendering.dart' show ColorFilterLayer, RenderProxyBox;
import 'package:material_ui/material_ui.dart';

ChoiceRing choiceRing(OptionRing r) => switch (r) {
  OptionRing.none => ChoiceRing.none,
  OptionRing.ok => ChoiceRing.right,
  OptionRing.bad => ChoiceRing.wrong,
  OptionRing.sel => ChoiceRing.selected,
};

/// The block of pictures (`#stage`): [fit] says how big it is and where each frame is. [cell] draws one.
class PictureBlock extends StatelessWidget {
  const PictureBlock({super.key, required this.fit, required this.cell});

  final BlockFit fit;
  final Widget Function(BuildContext context, int k, CellRect r) cell;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(bottom: fit.marginBottom),
    child: SizedBox(
      width: fit.width,
      height: fit.height,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var k = 0; k < fit.cells.length; k++)
              PositionedDirectional(
                start: fit.cells[k].left,
                top: fit.cells[k].top,
                width: fit.cells[k].width,
                height: fit.cells[k].height,
                child: cell(context, k, fit.cells[k]),
              ),
          ],
        ),
      ),
    ),
  );
}

/// One option: a picture that takes the touch the moment a finger goes down (cual.js: `pointerdown`),
/// with Noche Rule 1 press feedback (`press` / `pressBack`, `pressScale`, `pressDim`).
class OptionTouch extends StatefulWidget {
  const OptionTouch({
    super.key,
    required this.index,
    required this.onTouch,
    required this.child,
  });

  final int index;
  final void Function(int k) onTouch;
  final Widget child;

  @override
  State<OptionTouch> createState() => _OptionTouchState();
}

class _OptionTouchState extends State<OptionTouch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  void _pressDown() {
    final motion = NocheMotion.of(context);
    _controller.animateTo(1.0, duration: motion.press, curve: motion.enter);
    widget.onTouch(widget.index);
  }

  void _pressUp() {
    if (!mounted) return;
    final motion = NocheMotion.of(context);
    _controller.animateTo(0.0, duration: motion.pressBack, curve: motion.enter);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return Semantics(
      button: true,
      label: 'Picture ${widget.index + 1}',
      onTap: () => widget.onTouch(widget.index),
      child: ExcludeSemantics(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _pressDown(),
          onPointerUp: (_) => _pressUp(),
          onPointerCancel: (_) => _pressUp(),
          child: AnimatedBuilder(
            animation: _controller,
            child: widget.child,
            builder: (context, child) {
              final t = _controller.value;
              final scale = 1.0 + (motion.pressScale - 1.0) * t;
              final brightness = 1.0 - motion.pressDim * t;
              return Transform.scale(
                scale: scale,
                child: _OptionDimFilter(brightness: brightness, child: child!),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Permanent render wrapper that applies a brightness [ColorFilterLayer] only
/// when [brightness] < 1.0, keeping the child element subtree intact and
/// avoiding any saveLayer overhead at rest.
class _OptionDimFilter extends SingleChildRenderObjectWidget {
  const _OptionDimFilter({required this.brightness, super.child});

  final double brightness;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderOptionDimFilter(brightness);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOptionDimFilter renderObject,
  ) {
    renderObject.brightness = brightness;
  }
}

class _RenderOptionDimFilter extends RenderProxyBox {
  _RenderOptionDimFilter(this._brightness);

  double _brightness;
  double get brightness => _brightness;

  set brightness(double value) {
    if (_brightness == value) return;
    final wasCompositing = _brightness < 1.0;
    _brightness = value;
    if (wasCompositing != (_brightness < 1.0)) {
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => _brightness < 1.0;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_brightness >= 1.0) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    final b = _brightness;
    layer = context.pushColorFilter(
      offset,
      ColorFilter.matrix(<double>[
        b,
        0,
        0,
        0,
        0,
        0,
        b,
        0,
        0,
        0,
        0,
        0,
        b,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      super.paint,
      oldLayer: layer as ColorFilterLayer?,
    );
  }
}

/// What the page's `#main` is, for the layout: the screen less the top bar and the safe area.
class LessonBox {
  const LessonBox({
    required this.width,
    required this.height,
    required this.mainWidth,
    required this.mainHeight,
    required this.landscape,
    required this.dpr,
    required this.safeTop,
  });

  /// The whole screen handed to the lesson.
  final double width;
  final double height;

  /// juego.js: fit(): mw, mh.
  final double mainWidth;
  final double mainHeight;
  final bool landscape;
  final double dpr;
  final double safeTop;

  factory LessonBox.of(BuildContext context, BoxConstraints box) {
    final safe = MediaQuery.paddingOf(context);
    final landscape = CoquiLayout.lessonLandscape(context);
    final w = box.maxWidth;
    final h = box.maxHeight;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    if (landscape) {
      return LessonBox(
        width: w,
        height: h,
        mainWidth: w - safe.horizontal,
        mainHeight: h - safe.vertical,
        landscape: true,
        dpr: dpr,
        safeTop: safe.top,
      );
    }
    return LessonBox(
      width: w,
      height: h,
      mainWidth: w - safe.horizontal,
      mainHeight: h - safe.bottom - (nocheLessonTopBar + safe.top),
      landscape: false,
      dpr: dpr,
      safeTop: safe.top,
    );
  }

  BlockFit fit(BlockSpec spec) => fitBlock(
    spec,
    dpr: dpr,
    mainWidth: mainWidth,
    mainHeight: mainHeight,
    landscape: landscape,
  );
}

/// `#fin`: the title and the lines of a start or end screen. Portrait: the title sits at about 35% of the screen's
/// height (cual.html:34: `padding-top: calc(35dvh - 56px - env(safe-area-inset-top))`); on its side it is the top
/// of the column beside the picture (`padding: 8px 0 152px`). [children] come under the title, 8 px apart.
class LessonTextScreen extends StatelessWidget {
  const LessonTextScreen({
    super.key,
    required this.box,
    required this.title,
    required this.lines,
  });

  final LessonBox box;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final top = box.landscape
        ? 8.0
        : (0.35 * box.height - nocheLessonTopBar - box.safeTop).clamp(
            0.0,
            double.infinity,
          );
    return Positioned.fill(
      child: ColoredBox(
        color: box.landscape ? Colors.transparent : NocheColors.lessonGround,
        child: SingleChildScrollView(
          padding: box.landscape
              ? EdgeInsetsDirectional.fromSTEB(0, top, 0, 152)
              : EdgeInsetsDirectional.fromSTEB(16, top, 16, 160),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: nocheLessonColumnMax),
              child: Column(
                // `#fin>*{width:100%;max-width:480px}`: each line is as wide as the column
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: NocheType.pageTitle.copyWith(
                      color: NocheColors.text,
                    ),
                  ),
                  for (final l in lines) ...[
                    const SizedBox(height: 8),
                    Text(
                      l,
                      style: NocheType.bodyLarge.copyWith(
                        color: NocheColors.label,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
