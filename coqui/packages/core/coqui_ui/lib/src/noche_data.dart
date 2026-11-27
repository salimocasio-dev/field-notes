/// Noche data and visual pieces: progress dashes, stage bar, progress bar,
/// bar chart, and typographic book covers.
library;

import 'dart:math' as math;

import 'package:coqui_ui/src/noche_motion.dart';
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
            child: _NocheDash(
              key: ValueKey('noche_dash_$i'),
              state: states[i],
              notYetColor: notYetColor,
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

class _NocheDash extends StatefulWidget {
  const _NocheDash({super.key, required this.state, required this.notYetColor});

  final NocheDashState state;
  final Color notYetColor;

  @override
  State<_NocheDash> createState() => _NocheDashState();
}

class _NocheDashState extends State<_NocheDash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  bool _animatingToDone = false;
  bool _reducedAtStart = false;
  Color _trackColor = NocheColors.line;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _animatingToDone && mounted) {
      setState(() => _animatingToDone = false);
    }
  }

  @override
  void didUpdateWidget(_NocheDash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != NocheDashState.done &&
        widget.state == NocheDashState.done) {
      final motion = NocheMotion.of(context);
      _animatingToDone = true;
      _reducedAtStart = motion.reduced;
      _trackColor = oldWidget.state == NocheDashState.current
          ? NocheColors.next
          : widget.notYetColor;
      _controller.duration = motion.reduced ? motion.quick : motion.move;
      _controller.forward(from: 0.0);
    } else if (widget.state != NocheDashState.done && _animatingToDone) {
      _animatingToDone = false;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_animatingToDone) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: switch (widget.state) {
            NocheDashState.done => NocheColors.text,
            NocheDashState.current => NocheColors.next,
            NocheDashState.notYet => widget.notYetColor,
          },
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final motion = NocheMotion.of(context);
        final isReduced = _reducedAtStart || motion.reduced;
        final widthFactor = isReduced
            ? 1.0
            : motion.travel.transform(_controller.value);
        final opacity = isReduced
            ? motion.enter.transform(_controller.value)
            : 1.0;
        return Container(
          height: 8,
          decoration: BoxDecoration(
            color: _trackColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: widthFactor,
              heightFactor: 1,
              child: Opacity(
                opacity: opacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: NocheColors.text,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBarFill extends StatefulWidget {
  const _AnimatedBarFill({
    required this.from,
    required this.to,
    required this.delay,
    required this.color,
    required this.borderRadius,
  });

  final double from;
  final double to;
  final Duration delay;
  final Color color;
  final BorderRadius borderRadius;

  @override
  State<_AnimatedBarFill> createState() => _AnimatedBarFillState();
}

class _AnimatedBarFillState extends State<_AnimatedBarFill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late NocheMotionData _motion;
  late Duration _animDuration;
  bool _started = false;
  double _totalUs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    _animDuration = _motion.reduced ? _motion.quick : _motion.settle;
    final total = widget.delay + _animDuration;
    _totalUs = total.inMicroseconds.toDouble();
    if (_totalUs <= 0) {
      _controller.value = 1.0;
    } else {
      _controller.duration = total;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double p;
        if (_totalUs <= 0) {
          p = 1.0;
        } else {
          final elapsedUs = _controller.value * _totalUs;
          final delayUs = widget.delay.inMicroseconds.toDouble();
          final animUs = _animDuration.inMicroseconds.toDouble();
          if (elapsedUs <= delayUs) {
            p = 0.0;
          } else if (animUs <= 0 || elapsedUs >= delayUs + animUs) {
            p = 1.0;
          } else {
            final raw = ((elapsedUs - delayUs) / animUs).clamp(0.0, 1.0);
            p = _motion.enter.transform(raw);
          }
        }

        final widthFactor = _motion.reduced
            ? widget.to
            : widget.from + (widget.to - widget.from) * p;
        final opacity = _motion.reduced ? p : 1.0;

        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 1,
            child: Opacity(
              opacity: opacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: widget.borderRadius,
                ),
              ),
            ),
          ),
        );
      },
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
    this.animateFrom,
    this.delay = Duration.zero,
    this.semanticLabel,
  });

  final int stage;
  final int max;

  /// When non-null, grows once on first build from [animateFrom] (`0..1`) to
  /// `stage / max` in `settle` on `enter` after [delay].
  final double? animateFrom;
  final Duration delay;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final fraction = max <= 0 ? 0.0 : (stage / max).clamp(0.0, 1.0);
    final radius = BorderRadius.circular(4);
    final Widget fill = animateFrom != null
        ? _AnimatedBarFill(
            from: animateFrom!.clamp(0.0, 1.0),
            to: fraction,
            delay: delay,
            color: NocheColors.text,
            borderRadius: radius,
          )
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: NocheColors.text,
                  borderRadius: radius,
                ),
              ),
            ),
          );

    return Semantics(
      label: semanticLabel ?? 'Stage $stage of $max',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          width: 96,
          height: 8,
          decoration: BoxDecoration(
            color: NocheColors.line,
            borderRadius: radius,
          ),
          child: fill,
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
    this.animateFrom,
    this.delay = Duration.zero,
    this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;

  /// When non-null, grows once on first build from [animateFrom] (`0..1`) to
  /// [value] in `settle` on `enter` after [delay].
  final double? animateFrom;
  final Duration delay;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(height <= 4 ? 2 : 4);
    final Widget fill = animateFrom != null
        ? _AnimatedBarFill(
            from: animateFrom!.clamp(0.0, 1.0),
            to: clamped,
            delay: delay,
            color: color,
            borderRadius: radius,
          )
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: FractionallySizedBox(
              widthFactor: clamped,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: radius),
              ),
            ),
          );

    final bar = Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(color: trackColor, borderRadius: radius),
      child: fill,
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

class _BarGrowClipper extends CustomClipper<RRect> {
  const _BarGrowClipper({required this.fraction, required this.radius});

  final double fraction;
  final double radius;

  @override
  RRect getClip(Size size) {
    final clamped = fraction.clamp(0.0, 1.0);
    final h = size.height * clamped;
    final top = size.height - h;
    return RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, size.width, h),
      Radius.circular(radius),
    );
  }

  @override
  bool shouldReclip(_BarGrowClipper oldClipper) =>
      oldClipper.fraction != fraction || oldClipper.radius != radius;
}

/// Column bar chart (`Noche-Palabras.dc.html`, `Noche-Yo.dc.html`):
/// rounded bars (radius 8), optional numbers above (`buttonStrong` 14/16),
/// labels under (`label` size 12 line 16), one bar highlighted in `next`,
/// optional 1 px dashed goal line in `label` colour.
///
/// Bars grow from zero once on first build in `settle` on `enter`, staggered by
/// `stagger` for the first 5 bars (bars at index `>= 5` share index 4's start).
class NocheBarChart extends StatefulWidget {
  const NocheBarChart({
    super.key,
    required this.items,
    this.showValues = true,
    this.goal,
    this.barAreaHeight,
    this.delay = Duration.zero,
    this.semanticLabel,
  });

  final List<NocheBarItem> items;

  /// Shows each column's numeric value above its bar (`Noche-Palabras.dc.html`).
  final bool showValues;

  /// Optional horizontal dashed goal line (`Noche-Yo.dc.html`). Goals outside
  /// the plotted values' range are omitted without changing the bar scale.
  final num? goal;

  /// Height of the bar plotting area (defaults to 96 when [showValues] is true
  /// as on `Noche-Palabras`, or 64 when false as on `Noche-Yo`).
  final double? barAreaHeight;
  final Duration delay;
  final String? semanticLabel;

  @override
  State<NocheBarChart> createState() => _NocheBarChartState();
}

class _NocheBarChartState extends State<NocheBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late NocheMotionData _motion;
  late Duration _barDuration;
  bool _started = false;
  double _totalUs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    _barDuration = _motion.reduced ? _motion.quick : _motion.settle;
    final n = widget.items.length;
    if (n == 0) {
      _totalUs = 0;
      _controller.value = 1.0;
      return;
    }
    final maxStaggerIdx = math.min(n - 1, 4);
    final total = widget.delay + _motion.stagger * maxStaggerIdx + _barDuration;
    _totalUs = total.inMicroseconds.toDouble();
    if (_totalUs <= 0) {
      _controller.value = 1.0;
    } else {
      _controller.duration = total;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(NocheBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started || !_controller.isAnimating) return;
    if (widget.items.length != oldWidget.items.length ||
        widget.delay != oldWidget.delay) {
      final prevElapsedUs = _controller.value * _totalUs;
      final n = widget.items.length;
      if (n == 0) {
        _totalUs = 0;
        _controller.value = 1.0;
        return;
      }
      final maxStaggerIdx = math.min(n - 1, 4);
      final newTotal =
          widget.delay + _motion.stagger * maxStaggerIdx + _barDuration;
      _totalUs = newTotal.inMicroseconds.toDouble();
      if (_totalUs <= 0 || prevElapsedUs >= _totalUs) {
        _controller.value = 1.0;
      } else {
        _controller.duration = newTotal;
        _controller.forward(from: (prevElapsedUs / _totalUs).clamp(0.0, 1.0));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _progressForBar(int index) {
    if (_controller.isCompleted || (!_controller.isAnimating && _started)) {
      return 1.0;
    }
    if (_totalUs <= 0) return 1.0;
    final elapsedUs = _controller.value * _totalUs;
    final startUs = (widget.delay + _motion.stagger * math.min(index, 4))
        .inMicroseconds
        .toDouble();
    final durUs = _barDuration.inMicroseconds.toDouble();
    if (elapsedUs <= startUs) return 0.0;
    if (durUs <= 0 || elapsedUs >= startUs + durUs) return 1.0;
    final raw = ((elapsedUs - startUs) / durUs).clamp(0.0, 1.0);
    return _motion.enter.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final maxBarH = widget.barAreaHeight ?? (widget.showValues ? 96.0 : 64.0);
    const labelLineH = 16.0;
    const valueLineH = 16.0;
    const gap = NocheSize.grid;

    num scaleMax = 0;
    for (final item in widget.items) {
      if (item.value > scaleMax) scaleMax = item.value;
    }

    double barHeightFor(num v) {
      if (scaleMax <= 0 || v <= 0) return 0;
      return (v / scaleMax) * maxBarH;
    }

    final totalHeight =
        (widget.showValues ? valueLineH + gap : 0) + maxBarH + gap + labelLineH;

    final goalBottom =
        widget.goal != null &&
            scaleMax > 0 &&
            widget.goal! >= 0 &&
            widget.goal! <= scaleMax
        ? labelLineH + gap + barHeightFor(widget.goal!)
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < widget.items.length; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.showValues) ...[
                            Text(
                              '${widget.items[i].value}',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: NocheType.buttonStrong.copyWith(
                                height: valueLineH / 14,
                                color: widget.items[i].highlighted
                                    ? NocheColors.next
                                    : NocheColors.text,
                              ),
                            ),
                            const SizedBox(height: gap),
                          ],
                          Builder(
                            builder: (context) {
                              final p = _progressForBar(i);
                              final barBox = Container(
                                height: barHeightFor(widget.items[i].value),
                                decoration: BoxDecoration(
                                  color: widget.items[i].highlighted
                                      ? NocheColors.next
                                      : NocheColors.bar,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              );
                              final effectiveFraction = _motion.reduced
                                  ? 1.0
                                  : p;
                              final clipped = ClipRRect(
                                key: ValueKey('noche_bar_clip_$i'),
                                clipBehavior: effectiveFraction >= 1.0
                                    ? Clip.none
                                    : Clip.antiAlias,
                                clipper: _BarGrowClipper(
                                  fraction: effectiveFraction,
                                  radius: 8,
                                ),
                                child: barBox,
                              );
                              if (_motion.reduced) {
                                return Opacity(opacity: p, child: clipped);
                              }
                              return clipped;
                            },
                          ),
                          const SizedBox(height: gap),
                          Text(
                            widget.items[i].label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NocheType.label.copyWith(
                              letterSpacing: 0,
                              fontWeight:
                                  widget.items[i].highlighted &&
                                      !widget.showValues
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: labelLineH / 12,
                              color: widget.items[i].highlighted
                                  ? (widget.showValues
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
          ),
        ],
      ),
    );

    if (widget.semanticLabel == null) return chart;
    return Semantics(
      label: widget.semanticLabel,
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
