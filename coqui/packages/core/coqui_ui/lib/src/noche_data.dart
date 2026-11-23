/// Noche data and visual pieces: progress dashes, stage bar, progress bar,
/// bar chart, and typographic book covers.
library;

import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:material_ui/material_ui.dart';

/// State of a single dash in [NocheDashes].
enum NocheDashState {
  /// Completed (`NocheColors.text`).
  done,

  /// Current item (`NocheColors.next`).
  current,

  /// Not reached (`NocheColors.line`, or `NocheColors.lessonLine` on lesson ground).
  notYet,
}

/// Row of equal horizontal dashes (`Noche-Cuento.dc.html`, `Noche-Yo.dc.html`):
/// 8 high, radius 4, gap 4 by default.
class NocheDashes extends StatelessWidget {
  const NocheDashes({
    super.key,
    required this.states,
    this.onLessonGround = false,
    this.gap = 4,
    this.semanticLabel,
  });

  /// Builds [count] dashes with [done] completed, an optional 0-based
  /// [currentIndex] highlighted in `next`, and the remainder not yet reached.
  factory NocheDashes.progress({
    Key? key,
    required int count,
    required int done,
    int? currentIndex,
    bool onLessonGround = false,
    double gap = 4,
    String? semanticLabel,
  }) {
    final built = List<NocheDashState>.generate(count, (i) {
      if (currentIndex != null && i == currentIndex) {
        return NocheDashState.current;
      }
      if (i < done) return NocheDashState.done;
      return NocheDashState.notYet;
    });
    return NocheDashes(
      key: key,
      states: built,
      onLessonGround: onLessonGround,
      gap: gap,
      semanticLabel: semanticLabel,
    );
  }

  final List<NocheDashState> states;
  final bool onLessonGround;
  final double gap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final notYetColor = onLessonGround
        ? NocheColors.lessonLine
        : NocheColors.line;
    final row = Row(
      children: [
        for (var i = 0; i < states.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: switch (states[i]) {
                  NocheDashState.done => NocheColors.text,
                  NocheDashState.current => NocheColors.next,
                  NocheDashState.notYet => notYetColor,
                },
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
    if (semanticLabel == null) return row;
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      child: ExcludeSemantics(child: row),
    );
  }
}

/// Word stage bar (`Noche-Palabras.dc.html`): 96 by 8 track (`line`), fill
/// `text`, width = `stage / max`.
class NocheStageBar extends StatelessWidget {
  const NocheStageBar({
    super.key,
    required this.stage,
    required this.max,
    this.semanticLabel,
  });

  final int stage;
  final int max;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (stage / max).clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel ?? 'Stage $stage of $max',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          width: 96,
          height: 8,
          decoration: BoxDecoration(
            color: NocheColors.line,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NocheColors.text,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linear progress bar (`Noche-Biblioteca.dc.html`, `Noche-Importar.dc.html`,
/// `Noche-Lector.dc.html`): 8 high (4 in the reader), radius 4 (2 at height 4),
/// track `line` (or custom `trackColor`), fill in [color].
class NocheProgressBar extends StatelessWidget {
  const NocheProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor = NocheColors.line,
    this.height = 8,
    this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height <= 4 ? 2 : 4);
    final bar = Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(color: trackColor, borderRadius: radius),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: clamped,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      ),
    );
    if (semanticLabel == null) return bar;
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      child: ExcludeSemantics(child: bar),
    );
  }
}

/// One column in [NocheBarChart].
class NocheBarItem {
  const NocheBarItem({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final num value;
  final bool highlighted;
}

class _HorizontalDashPainter extends CustomPainter {
  const _HorizontalDashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    final y = size.height / 2;
    while (x < size.width) {
      final end = (x + dash).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_HorizontalDashPainter old) => old.color != color;
}

/// Column bar chart (`Noche-Palabras.dc.html`, `Noche-Yo.dc.html`):
/// rounded bars (radius 8), optional numbers above (`buttonStrong` 14/16),
/// labels under (`label` size 12 line 16), one bar highlighted in `next`,
/// optional 1 px dashed goal line in `label` colour.
class NocheBarChart extends StatelessWidget {
  const NocheBarChart({
    super.key,
    required this.items,
    this.showValues = true,
    this.goal,
    this.barAreaHeight,
    this.semanticLabel,
  });

  final List<NocheBarItem> items;

  /// Shows each column's numeric value above its bar (`Noche-Palabras.dc.html`).
  final bool showValues;

  /// Optional horizontal dashed goal line (`Noche-Yo.dc.html`).
  final num? goal;

  /// Height of the bar plotting area (defaults to 96 when [showValues] is true
  /// as on `Noche-Palabras`, or 64 when false as on `Noche-Yo`).
  final double? barAreaHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final maxBarH = barAreaHeight ?? (showValues ? 96.0 : 64.0);
    const labelLineH = 16.0;
    const valueLineH = 16.0;
    const gap = NocheSize.grid;

    num scaleMax = 0;
    for (final item in items) {
      if (item.value > scaleMax) scaleMax = item.value;
    }
    if (goal != null && goal! > scaleMax) {
      scaleMax = goal!;
    }

    double barHeightFor(num v) {
      if (scaleMax <= 0 || v <= 0) return 0;
      return (v / scaleMax) * maxBarH;
    }

    final totalHeight =
        (showValues ? valueLineH + gap : 0) + maxBarH + gap + labelLineH;

    final goalBottom = goal != null && scaleMax > 0
        ? labelLineH + gap + barHeightFor(goal!)
        : null;

    final chart = SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (goalBottom != null)
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: goalBottom,
              height: 1,
              child: const CustomPaint(
                painter: _HorizontalDashPainter(color: NocheColors.label),
              ),
            ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showValues) ...[
                          Text(
                            '${items[i].value}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: NocheType.buttonStrong.copyWith(
                              height: valueLineH / 14,
                              color: items[i].highlighted
                                  ? NocheColors.next
                                  : NocheColors.text,
                            ),
                          ),
                          const SizedBox(height: gap),
                        ],
                        Container(
                          height: barHeightFor(items[i].value),
                          decoration: BoxDecoration(
                            color: items[i].highlighted
                                ? NocheColors.next
                                : NocheColors.bar,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: gap),
                        Text(
                          items[i].label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NocheType.label.copyWith(
                            letterSpacing: 0,
                            fontWeight: items[i].highlighted && !showValues
                                ? FontWeight.w700
                                : FontWeight.w600,
                            height: labelLineH / 12,
                            color: items[i].highlighted
                                ? (showValues
                                      ? NocheColors.text
                                      : NocheColors.next)
                                : NocheColors.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (semanticLabel == null) return chart;
    return Semantics(
      label: semanticLabel,
      readOnly: true,
      child: ExcludeSemantics(child: chart),
    );
  }
}

/// Size of [NocheCover].
enum NocheCoverSize {
  /// 90 by 120 (`Noche-Biblioteca.dc.html` shelf): spine 5, end radius 8, mark 20 by 2.
  regular,

  /// 60 by 84 (`Noche-Biblioteca.dc.html` keep reading, `Noche-Importar.dc.html`):
  /// spine 4, end radius 6, mark 16 by 2.
  small,
}

/// Deterministic, platform-independent 32-bit hash for [bookId] (identical on
/// VM and web).
int nocheStableHash(String bookId) {
  var h = 5381;
  for (final unit in bookId.codeUnits) {
    h = (((h << 5) + h) + unit) & 0x7FFFFFFF;
  }
  return h;
}

/// Typographic book cover (`Noche-Biblioteca.dc.html`, `Noche-Importar.dc.html`).
///
/// Chooses `coverBlue` (even) or `coverPlum` (odd) from [nocheStableHash] of
/// [bookId]. Mirrors spine side and corners automatically in RTL.
class NocheCover extends StatelessWidget {
  const NocheCover({
    super.key,
    required this.bookId,
    required this.title,
    this.size = NocheCoverSize.regular,
    this.script = 'Latn',
    this.locale,
  });

  final String bookId;
  final String title;
  final NocheCoverSize size;
  final String script;
  final Locale? locale;

  /// Returns the palette chosen for [bookId] (even: blue, odd: plum).
  static NocheCoverColors colorsFor(String bookId) =>
      nocheStableHash(bookId).isEven
      ? NocheColors.coverBlue
      : NocheColors.coverPlum;

  @override
  Widget build(BuildContext context) {
    final palette = colorsFor(bookId);
    final isSmall = size == NocheCoverSize.small;
    final width = isSmall ? 60.0 : 90.0;
    final height = isSmall ? 84.0 : 120.0;
    final spineWidth = isSmall ? 4.0 : 5.0;
    final endRadius = isSmall ? 6.0 : 8.0;
    final markWidth = isSmall ? 16.0 : 20.0;
    final padding = isSmall
        ? const EdgeInsetsDirectional.fromSTEB(8, 8, 6, 6)
        : const EdgeInsetsDirectional.fromSTEB(10, 12, 8, 10);
    final baseStyle = isSmall ? NocheType.coverSmall : NocheType.cover;
    final titleStyle = NocheType.forScript(
      baseStyle,
      script,
    ).copyWith(color: NocheColors.text);

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(3),
            bottomStart: const Radius.circular(3),
            topEnd: Radius.circular(endRadius),
            bottomEnd: Radius.circular(endRadius),
          ),
          child: ColoredBox(
            color: palette.face,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: spineWidth,
                  child: ColoredBox(color: palette.spine),
                ),
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          locale: locale,
                          style: titleStyle,
                        ),
                        SizedBox(
                          width: markWidth,
                          height: 2,
                          child: ColoredBox(color: palette.mark),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
