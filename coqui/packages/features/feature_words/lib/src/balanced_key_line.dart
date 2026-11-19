/// The grey key line under the first place title (app.html: `.keyl`, with `text-wrap:balance`).
library;

import 'package:coqui_ui/coqui_ui.dart';
import 'package:material_ui/material_ui.dart';

/// `.keyl{margin:-8px 0 16px;text-wrap:balance}` on `.small.mut`: the same line as [KeyLine], but when it has to
/// wrap its lines come out of even length (the browser's `balance`: the narrowest width that keeps the number of
/// lines), where a plain [Text] fills the first line and leaves a stub.
class BalancedKeyLine extends BlockWidget {
  const BalancedKeyLine(this.text, {super.key});
  final String text;

  @override
  double get marginTop => -CoquiMetrics.s8;
  @override
  double get marginBottom => CoquiMetrics.s16;
  @override
  Widget get content => BalancedText(text, style: CoquiText.smallMuted);
}

/// A text whose lines are balanced, as `text-wrap:balance` does for a short paragraph.
class BalancedText extends StatelessWidget {
  const BalancedText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scaler = MediaQuery.textScalerOf(context);
      final plain = Text(text, style: style);
      if (!c.hasBoundedWidth) return plain;
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      );
      int lines(double w) {
        tp.layout(maxWidth: w);
        return tp.computeLineMetrics().length;
      }

      final n = lines(c.maxWidth);
      if (n < 2) return plain;
      // the narrowest width that still gives n lines
      var lo = 0.0;
      var hi = c.maxWidth;
      for (var i = 0; i < 24; i++) {
        final mid = (lo + hi) / 2;
        if (lines(mid) <= n) {
          hi = mid;
        } else {
          lo = mid;
        }
      }
      tp.dispose();
      return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: hi.ceilToDouble() + 1, child: plain),
      );
    },
  );
}
