/// The fades of the old app: a line that scrolls out fades instead of being cut.
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// Which edge a [ListFade] sits at.
enum FadeEdge { top, bottom }

/// `.fade` / `#fadeTab`: a soft 16 px gradient from the page colour (`--bg`
/// `#F6F5F1`, transparent at the far side), laid over the edge of a list that has
/// more to scroll; it comes and goes in 150 ms (`opacity` transition).
/// app.html:42-43, 134
class ListFade extends StatelessWidget {
  const ListFade({
    super.key,
    this.edge = FadeEdge.bottom,
    this.visible = true,
    this.color = CoquiColors.bg,
  });

  final FadeEdge edge;

  /// `.fade.on`: shown when there is more to scroll at that edge.
  final bool visible;

  /// `--bg`; the fade is `rgba(246,245,241,0)` to `var(--bg)`.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clear = color.withAlpha(0);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: CoquiMetrics.fadeList,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: edge == FadeEdge.top ? [color, clear] : [clear, color],
            ),
          ),
        ),
      ),
    );
  }
}

/// A mask that lets a line scroll out softly: the content fades to nothing over
/// [bottom] px at its foot and [top] px at its head. `#sbody`'s
/// `mask-image:linear-gradient(#000 calc(100% - 24px), transparent)` (app.html:82)
/// is `FadingEdges(bottom: 24)`; a Repaso end list's mask, 16 px at both ends
/// (cual.html:40), is `FadingEdges(top: 16, bottom: 16)`.
class FadingEdges extends StatelessWidget {
  const FadingEdges({
    super.key,
    this.top = 0,
    this.bottom = CoquiMetrics.fadeSheet,
    required this.child,
  });

  final double top;
  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) {
      final h = rect.height;
      if (h <= 0) {
        return const LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF000000)],
        ).createShader(rect);
      }
      final a = (top / h).clamp(0.0, 1.0);
      final b = (1 - bottom / h).clamp(0.0, 1.0);
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          if (top > 0) const Color(0x00000000),
          const Color(0xFF000000),
          const Color(0xFF000000),
          if (bottom > 0) const Color(0x00000000),
        ],
        stops: [if (top > 0) 0, a, b, if (bottom > 0) 1],
      ).createShader(rect);
    },
    child: child,
  );
}
