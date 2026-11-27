/// Noche shared motion pieces (epic N8, story N8.2):
/// [NocheLtr], [NocheArrive], [NocheFollow], [NocheWindow], and
/// [NocheQuietLock].
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coqui_ui/src/noche_motion.dart';
import 'package:coqui_ui/src/noche_tokens.dart';
import 'package:coqui_ui/src/pressable.dart';
import 'package:material_ui/material_ui.dart';

/// Forces [TextDirection.ltr] on [child] regardless of ambient directionality.
///
/// Used for fixed-order pieces (tab bar, maps, diagrams) that never mirror in
/// RTL locales.
class NocheLtr extends StatelessWidget {
  const NocheLtr({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Staggers a column of [children] (and an optional trailing [next] action)
/// into place once on first build.
///
/// Rows `0..4` start `motion.stagger` apart after [delay]; any row at index
/// `>= 5` shares index 4's start time. If [next] is given, it starts
/// `motion.nextDelay` after the last staggered row (or `delay + nextDelay` when
/// [children] is empty). Each item rises by `motion.row` and fades `0 -> 1` in
/// `motion.move` on `motion.enter`.
///
/// Under reduced motion (`motion.reduced`), `stagger`, `nextDelay`, and `row`
/// are zero and `move` is `quick`, so everything fades in together in place.
class NocheArrive extends StatefulWidget {
  const NocheArrive({
    super.key,
    required this.children,
    this.next,
    this.delay = Duration.zero,
    this.spacing = 0,
    this.nextSpacing,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final Widget? next;
  final Duration delay;
  final double spacing;
  final double? nextSpacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  State<NocheArrive> createState() => _NocheArriveState();
}

class _NocheArriveState extends State<NocheArrive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late NocheMotionData _motion;
  bool _started = false;
  double _totalUs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    final n = widget.children.length;
    if (n == 0 && widget.next == null) {
      _totalUs = 0;
      _controller.value = 1.0;
      return;
    }
    final maxStaggerIdx = n == 0 ? 0 : math.min(n - 1, 4);
    final lastStart =
        widget.delay +
        _motion.stagger * maxStaggerIdx +
        (widget.next != null ? _motion.nextDelay : Duration.zero);
    final total = lastStart + _motion.move;
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

  double _progressForStart(Duration start) {
    if (_totalUs <= 0) return 1.0;
    final elapsedUs = _controller.value * _totalUs;
    final startUs = start.inMicroseconds.toDouble();
    final moveUs = _motion.move.inMicroseconds.toDouble();
    if (elapsedUs <= startUs) return 0.0;
    if (moveUs <= 0 || elapsedUs >= startUs + moveUs) return 1.0;
    final raw = ((elapsedUs - startUs) / moveUs).clamp(0.0, 1.0);
    return _motion.enter.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    final maxStaggerIdx = n == 0 ? 0 : math.min(n - 1, 4);
    final nextStart = n == 0
        ? widget.delay + _motion.nextDelay
        : widget.delay + _motion.stagger * maxStaggerIdx + _motion.nextDelay;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final items = <Widget>[];
        for (var i = 0; i < n; i++) {
          if (i > 0 && widget.spacing > 0) {
            items.add(SizedBox(height: widget.spacing));
          }
          final start = widget.delay + _motion.stagger * math.min(i, 4);
          final p = _progressForStart(start);
          final dy = _motion.row * (1.0 - p);
          items.add(
            Transform.translate(
              key: ValueKey('noche_arrive_item_$i'),
              offset: Offset(0, dy),
              child: Opacity(opacity: p, child: widget.children[i]),
            ),
          );
        }
        if (widget.next != null) {
          final gap = widget.nextSpacing ?? widget.spacing;
          if (n > 0 && gap > 0) {
            items.add(SizedBox(height: gap));
          }
          final p = _progressForStart(nextStart);
          final dy = _motion.row * (1.0 - p);
          items.add(
            Transform.translate(
              key: const ValueKey('noche_arrive_next'),
              offset: Offset(0, dy),
              child: Opacity(opacity: p, child: widget.next),
            ),
          );
        }
        return Column(
          mainAxisSize: widget.mainAxisSize,
          crossAxisAlignment: widget.crossAxisAlignment,
          children: items,
        );
      },
    );
  }
}

/// Which directional side new content enters from in [NocheFollow].
enum NocheFollowSide { start, end }

/// Follows a selection change by fading out the outgoing view in place and
/// sliding + fading the incoming view from [side] by [distance].
///
/// Mirrors automatically in RTL. Under reduced motion, travel distance is zero
/// so both views cross-fade in place with the same wait (`followAfter`).
class NocheFollow extends StatefulWidget {
  const NocheFollow({
    super.key,
    required this.contentKey,
    required this.child,
    this.side = NocheFollowSide.end,
    this.distance = NocheMotion.tab,
    this.alignment = AlignmentDirectional.topStart,
  });

  final Object contentKey;
  final Widget child;
  final NocheFollowSide side;
  final double distance;
  final AlignmentGeometry alignment;

  @override
  State<NocheFollow> createState() => _NocheFollowState();
}

class _NocheFollowState extends State<NocheFollow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  Widget? _outgoing;
  NocheMotionData _activeMotion = NocheMotion.normal;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null && mounted) {
      setState(() => _outgoing = null);
    }
  }

  @override
  void didUpdateWidget(NocheFollow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      _outgoing = oldWidget.child;
      _activeMotion = NocheMotion.of(context);
      final total = _activeMotion.followAfter + _activeMotion.move;
      _controller.duration = total;
      _controller.forward(from: 0.0);
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final baseSign = widget.side == NocheFollowSide.end ? 1.0 : -1.0;
    final sign = isRtl ? -baseSign : baseSign;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final motion = _controller.isAnimating
            ? _activeMotion
            : NocheMotion.of(context);
        final totalUs = (motion.followAfter + motion.move).inMicroseconds
            .toDouble();
        final elapsedUs = _controller.value * totalUs;

        Widget? outgoingLayer;
        if (_outgoing != null && _controller.value < 1.0) {
          final pressUs = motion.press.inMicroseconds.toDouble();
          final tOut = pressUs <= 0
              ? 1.0
              : (elapsedUs / pressUs).clamp(0.0, 1.0);
          if (tOut < 1.0) {
            final outOpacity = (1.0 - motion.exit.transform(tOut)).clamp(
              0.0,
              1.0,
            );
            outgoingLayer = Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    key: const ValueKey('noche_follow_outgoing'),
                    opacity: outOpacity,
                    child: _outgoing,
                  ),
                ),
              ),
            );
          }
        }

        final double pIn;
        if (_controller.value >= 1.0) {
          pIn = 1.0;
        } else {
          final followAfterUs = motion.followAfter.inMicroseconds.toDouble();
          final moveUs = motion.move.inMicroseconds.toDouble();
          if (elapsedUs <= followAfterUs) {
            pIn = 0.0;
          } else if (moveUs <= 0) {
            pIn = 1.0;
          } else {
            final rawIn = ((elapsedUs - followAfterUs) / moveUs).clamp(
              0.0,
              1.0,
            );
            pIn = motion.enter.transform(rawIn);
          }
        }

        final effectiveDist = motion.reduced ? 0.0 : widget.distance;
        final dx = sign * effectiveDist * (1.0 - pIn);

        final incoming = Transform.translate(
          key: const ValueKey('noche_follow_incoming'),
          offset: Offset(dx, 0),
          child: Opacity(opacity: pIn, child: widget.child),
        );

        return Stack(
          alignment: widget.alignment,
          clipBehavior: Clip.none,
          children: [?outgoingLayer, incoming],
        );
      },
    );
  }
}

/// Private holder placed directly inside [Hero.child] so [NocheWindow]'s
/// `flightShuttleBuilder` can read border radius, picture offset, picture size,
/// and child from both endpoints on push and pop.
class _NocheWindowHeroEndpoint extends StatelessWidget {
  const _NocheWindowHeroEndpoint({
    required this.borderRadius,
    required this.pictureOffset,
    required this.pictureSize,
    required this.picture,
    required this.surface,
  });

  final double borderRadius;
  final Offset pictureOffset;
  final Size? pictureSize;
  final Widget picture;
  final Widget surface;

  @override
  Widget build(BuildContext context) => surface;
}

Widget _buildWindowSurface({
  required Key key,
  required Widget child,
  required double borderRadius,
  required Offset pictureOffset,
  required Size? pictureSize,
  VoidCallback? onPressed,
  String? semanticLabel,
}) {
  final Widget innerChild = pictureSize != null
      ? Positioned.fromRect(
          rect: Rect.fromLTWH(
            pictureOffset.dx,
            pictureOffset.dy,
            pictureSize.width,
            pictureSize.height,
          ),
          child: child,
        )
      : Transform.translate(
          offset: pictureOffset,
          child: OverflowBox(
            alignment: AlignmentDirectional.topStart,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: child,
          ),
        );

  final Widget clippedSurface = ClipRRect(
    key: key,
    borderRadius: BorderRadius.circular(borderRadius),
    child: Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [innerChild],
    ),
  );

  if (onPressed != null) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      scaleOnPress: false,
      builder: (context, _) => clippedSurface,
    );
  }
  return clippedSurface;
}

/// A clipped window onto an unscaled picture (Rule 5).
///
/// The [child] picture is never wrapped in `Transform.scale` or `FittedBox`;
/// only the clipped frame rect, corner [borderRadius], and [pictureOffset]
/// change. Supports two modes:
///
/// - **Single-screen animated mode**: when [rect], [borderRadius], or
///   [pictureOffset] changes on the same widget, they animate together in
///   `pageIn` (or `pageOut` when [leaving] is true) on `enter`.
/// - **Cross-screen travel mode**: when [tag] is set and [rect] is null,
///   matches a [NocheWindow] with the same [tag] across routes via [Hero] on
///   `travel`, interpolating [borderRadius] and [pictureOffset] in lockstep
///   with the frame rect while keeping [child] unscaled. Under reduced motion,
///   does not fly across routes and instead fades in place in `quick`.
class NocheWindow extends StatefulWidget {
  const NocheWindow({
    super.key,
    required this.child,
    this.tag,
    this.rect,
    this.borderRadius = 0,
    this.pictureOffset = Offset.zero,
    this.pictureSize,
    this.leaving = false,
    this.onPressed,
    this.semanticLabel,
  });

  /// Stable key placed on the clipped window surface (including inside an
  /// active cross-route flight shuttle) for a given [tag].
  static Key surfaceKey(Object tag) => ValueKey<String>('noche_window_$tag');

  final Widget child;
  final Object? tag;
  final Rect? rect;
  final double borderRadius;
  final Offset pictureOffset;
  final Size? pictureSize;
  final bool leaving;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  State<NocheWindow> createState() => _NocheWindowState();
}

class _NocheWindowState extends State<NocheWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  );

  Rect? _fromRect;
  Rect? _toRect;
  late double _fromRadius;
  late double _toRadius;
  late Offset _fromOffset;
  late Offset _toOffset;
  bool _isReducedFade = false;
  bool _didInitialDepCheck = false;

  @override
  void initState() {
    super.initState();
    _fromRect = _toRect = widget.rect;
    _fromRadius = _toRadius = widget.borderRadius;
    _fromOffset = _toOffset = widget.pictureOffset;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitialDepCheck) return;
    _didInitialDepCheck = true;
    final motion = NocheMotion.of(context);
    if (widget.tag != null && widget.rect == null && motion.reduced) {
      _isReducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(NocheWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final geometryChanged =
        widget.rect != oldWidget.rect ||
        widget.borderRadius != oldWidget.borderRadius ||
        widget.pictureOffset != oldWidget.pictureOffset;
    if (!geometryChanged) return;

    final motion = NocheMotion.of(context);
    if (motion.reduced) {
      _fromRect = _toRect = widget.rect;
      _fromRadius = _toRadius = widget.borderRadius;
      _fromOffset = _toOffset = widget.pictureOffset;
      _isReducedFade = true;
      _controller.duration = motion.quick;
      _controller.forward(from: 0.0);
    } else {
      final t = motion.enter.transform(_controller.value);
      _fromRect = (_fromRect != null && _toRect != null)
          ? Rect.lerp(_fromRect, _toRect, t)
          : widget.rect;
      _toRect = widget.rect;
      _fromRadius =
          ui.lerpDouble(_fromRadius, _toRadius, t) ?? widget.borderRadius;
      _toRadius = widget.borderRadius;
      _fromOffset =
          Offset.lerp(_fromOffset, _toOffset, t) ?? widget.pictureOffset;
      _toOffset = widget.pictureOffset;
      _isReducedFade = false;
      _controller.duration = widget.leaving ? motion.pageOut : motion.pageIn;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildHeroShuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final fromHero = fromHeroContext.widget as Hero;
    final toHero = toHeroContext.widget as Hero;
    final fromEp = fromHero.child as _NocheWindowHeroEndpoint;
    final toEp = toHero.child as _NocheWindowHeroEndpoint;
    final tag = widget.tag!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // Flutter Hero passes a CurvedAnimation driven on Hero.curve
        // (`NocheMotion.travel`). Push runs 0 -> 1 (from -> to); pop runs
        // 1 -> 0 so `1 - animation.value` runs 0 -> 1 (from -> to) in lockstep
        // with Hero's own RectTween evaluation.
        final t =
            (flightDirection == HeroFlightDirection.push
                    ? animation.value
                    : 1.0 - animation.value)
                .clamp(0.0, 1.0);
        final radius =
            ui.lerpDouble(fromEp.borderRadius, toEp.borderRadius, t) ??
            toEp.borderRadius;
        final offset =
            Offset.lerp(fromEp.pictureOffset, toEp.pictureOffset, t) ??
            toEp.pictureOffset;
        final pictureSize = toEp.pictureSize ?? fromEp.pictureSize;
        return _buildWindowSurface(
          key: NocheWindow.surfaceKey(tag),
          child: toEp.picture,
          borderRadius: radius,
          pictureOffset: offset,
          pictureSize: pictureSize,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final key = widget.tag != null
        ? NocheWindow.surfaceKey(widget.tag!)
        : const ValueKey<String>('noche_window_surface');

    // Cross-screen Hero mode when tag is provided and rect is null.
    if (widget.tag != null && widget.rect == null) {
      if (!motion.reduced) {
        final surface = _buildWindowSurface(
          key: key,
          child: widget.child,
          borderRadius: widget.borderRadius,
          pictureOffset: widget.pictureOffset,
          pictureSize: widget.pictureSize,
          onPressed: widget.onPressed,
          semanticLabel: widget.semanticLabel,
        );
        return Hero(
          tag: widget.tag!,
          curve: motion.travel,
          createRectTween: (begin, end) => RectTween(begin: begin, end: end),
          placeholderBuilder: (context, heroSize, child) =>
              SizedBox.fromSize(size: heroSize),
          flightShuttleBuilder: _buildHeroShuttle,
          child: _NocheWindowHeroEndpoint(
            borderRadius: widget.borderRadius,
            pictureOffset: widget.pictureOffset,
            pictureSize: widget.pictureSize,
            picture: widget.child,
            surface: surface,
          ),
        );
      }

      // Reduced motion: render in place with a quick fade, no Hero flight.
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final opacity = _isReducedFade
              ? motion.enter.transform(_controller.value)
              : 1.0;
          return Opacity(
            opacity: opacity,
            child: _buildWindowSurface(
              key: key,
              child: widget.child,
              borderRadius: widget.borderRadius,
              pictureOffset: widget.pictureOffset,
              pictureSize: widget.pictureSize,
              onPressed: widget.onPressed,
              semanticLabel: widget.semanticLabel,
            ),
          );
        },
      );
    }

    // Single-screen mode (with or without explicit rect).
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final p = motion.enter.transform(_controller.value);
        final currentRect = (_fromRect != null && _toRect != null)
            ? Rect.lerp(_fromRect, _toRect, p)
            : widget.rect;
        final currentRadius =
            ui.lerpDouble(_fromRadius, _toRadius, p) ?? widget.borderRadius;
        final currentOffset =
            Offset.lerp(_fromOffset, _toOffset, p) ?? widget.pictureOffset;
        final opacity = _isReducedFade ? p : 1.0;

        Widget surface = _buildWindowSurface(
          key: key,
          child: widget.child,
          borderRadius: currentRadius,
          pictureOffset: currentOffset,
          pictureSize: widget.pictureSize,
          onPressed: widget.onPressed,
          semanticLabel: widget.semanticLabel,
        );
        if (_isReducedFade) {
          surface = Opacity(opacity: opacity, child: surface);
        }
        if (widget.rect != null && currentRect != null) {
          return Positioned.fromRect(rect: currentRect, child: surface);
        }
        return surface;
      },
    );
  }
}

class _QuietLockBorderPainter extends CustomPainter {
  const _QuietLockBorderPainter({
    required this.color,
    required this.radius,
    required this.lit,
  });

  static const double _strokeWidth = 1;
  static const double _dashLength = 4;
  static const double _gapLength = 3;

  final Color color;
  final double radius;
  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      (size.width - _strokeWidth).clamp(0, double.infinity),
      (size.height - _strokeWidth).clamp(0, double.infinity),
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular((radius - inset).clamp(0, double.infinity)),
    );
    final source = Path()..addRRect(rrect);

    final dashedAlpha = (1.0 - lit).clamp(0.0, 1.0);
    if (dashedAlpha > 0) {
      final dashed = Path();
      for (final ui.PathMetric metric in source.computeMetrics()) {
        var dist = 0.0;
        while (dist < metric.length) {
          final next = (dist + _dashLength).clamp(0.0, metric.length);
          dashed.addPath(metric.extractPath(dist, next), Offset.zero);
          dist += _dashLength + _gapLength;
        }
      }
      canvas.drawPath(
        dashed,
        Paint()
          ..color = color.withValues(alpha: color.a * dashedAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }

    final solidAlpha = lit.clamp(0.0, 1.0);
    if (solidAlpha > 0) {
      canvas.drawPath(
        source,
        Paint()
          ..color = color.withValues(alpha: color.a * solidAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }
  }

  @override
  bool shouldRepaint(_QuietLockBorderPainter old) =>
      old.color != color || old.radius != radius || old.lit != lit;
}

/// Quiet lock feedback: tapping turns the dashed border solid (`line -> label`)
/// and brightens the reason text (`label -> text`) in `press`, holds for
/// `lockHold`, and gently returns in `move`. No shake, no scale, no red.
class NocheQuietLock extends StatefulWidget {
  const NocheQuietLock({
    super.key,
    required this.builder,
    this.borderRadius = NocheSize.cardRadius,
    this.padding = const EdgeInsetsDirectional.all(16),
    this.onTap,
    this.semanticLabel,
    this.active = true,
  });

  final Widget Function(BuildContext context, Color reasonColor) builder;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool active;

  @override
  State<NocheQuietLock> createState() => _NocheQuietLockState();
}

class _NocheQuietLockState extends State<NocheQuietLock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  NocheMotionData _activeMotion = NocheMotion.normal;

  void _trigger() {
    if (!widget.active) return;
    _activeMotion = NocheMotion.of(context);
    _controller.duration =
        _activeMotion.press + _activeMotion.lockHold + _activeMotion.move;
    _controller.forward(from: 0.0);
    widget.onTap?.call();
  }

  double _litValue() {
    if (!_controller.isAnimating &&
        (_controller.value == 0.0 || _controller.value == 1.0)) {
      return 0.0;
    }
    final pressUs = _activeMotion.press.inMicroseconds.toDouble();
    final holdEndUs = (_activeMotion.press + _activeMotion.lockHold)
        .inMicroseconds
        .toDouble();
    final moveUs = _activeMotion.move.inMicroseconds.toDouble();
    final totalUs =
        (_activeMotion.press + _activeMotion.lockHold + _activeMotion.move)
            .inMicroseconds
            .toDouble();
    if (totalUs <= 0) return 0.0;

    final elapsedUs = _controller.value * totalUs;
    if (elapsedUs < pressUs - 1.0) {
      if (pressUs <= 0) return 1.0;
      return _activeMotion.enter.transform((elapsedUs / pressUs).clamp(0.0, 1));
    }
    if (elapsedUs <= holdEndUs + 1.0) {
      return 1.0;
    }
    if (moveUs <= 0) return 0.0;
    final raw = ((elapsedUs - holdEndUs) / moveUs).clamp(0.0, 1.0);
    return (1.0 - _activeMotion.enter.transform(raw)).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final lit = _litValue();
        final reasonColor = Color.lerp(
          NocheColors.label,
          NocheColors.text,
          lit,
        )!;
        final borderColor = Color.lerp(
          NocheColors.line,
          NocheColors.label,
          lit,
        )!;
        return ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: NocheSize.touch,
            minHeight: NocheSize.touch,
          ),
          child: CustomPaint(
            key: const ValueKey('noche_quiet_lock_paint'),
            painter: _QuietLockBorderPainter(
              color: borderColor,
              radius: widget.borderRadius,
              lit: lit,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.all(1),
              child: DefaultTextStyle.merge(
                style: NocheType.body.copyWith(color: reasonColor),
                child: IconTheme.merge(
                  data: IconThemeData(color: reasonColor),
                  child: Padding(
                    padding: widget.padding,
                    child: widget.builder(context, reasonColor),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!widget.active) {
      return Semantics(label: widget.semanticLabel, child: content);
    }

    return Semantics(
      label: widget.semanticLabel,
      onTap: _trigger,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _trigger,
        child: content,
      ),
    );
  }
}
