/// Scroll-edge fade mask still used by `feature_review`.
library;

import 'package:coqui_ui/src/tokens.dart';
import 'package:material_ui/material_ui.dart';

/// A mask that lets a line scroll out softly: the content fades to nothing over
/// [bottom] px at its foot and [top] px at its head.
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
