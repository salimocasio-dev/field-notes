/// Noche lesson and game UI pieces for feature_review.
///
/// Built solely on Noche tokens (`NocheColors`, `NocheType`, `NocheSize`,
/// `NocheIcon`, `NocheIcons`) with directional layout APIs and zero red.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/motion.dart';
import 'package:material_ui/material_ui.dart';

const double nocheLessonTopBar = 56.0;
const double nocheLessonColumnMax = 480.0;
const double nocheLessonFootReserve = 112.0;
const double nocheLessonStartDisc = 72.0;
const double nocheLessonBorder = 1.5;
const double nocheBadgeSize = 28.0;
const double nocheBadgeInset = 8.0;
const double nocheBadgeRing = 2.0;

/// 48x48 close button on the Noche lesson frame.
class NocheLessonCloseButton extends StatelessWidget {
  const NocheLessonCloseButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: 'Close',
    builder: (context, pressed) => Container(
      width: NocheSize.touch,
      height: NocheSize.touch,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pressed ? NocheColors.lessonPanel : null,
      ),
      child: const NocheIcon(
        NocheIcons.close,
        size: 24,
        color: NocheColors.text,
      ),
    ),
  );
}

class _MutedSlashPainter extends CustomPainter {
  const _MutedSlashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    canvas.drawLine(
      const Offset(4, 20),
      const Offset(20, 4),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MutedSlashPainter old) => old.color != color;
}

/// 48x48 sound toggle button on the Noche lesson frame.
class NocheLessonSoundButton extends StatelessWidget {
  const NocheLessonSoundButton({
    super.key,
    required this.onPressed,
    this.muted = false,
  });

  final VoidCallback? onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final iconColor = muted ? NocheColors.lessonLabel : NocheColors.text;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: muted ? 'Sound off' : 'Sound on',
      builder: (context, pressed) => Container(
        width: NocheSize.touch,
        height: NocheSize.touch,
        alignment: AlignmentDirectional.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? NocheColors.lessonPanel : null,
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            NocheIcon(NocheIcons.speaker, size: 24, color: iconColor),
            if (muted)
              SizedBox.square(
                dimension: 24,
                child: CustomPaint(painter: _MutedSlashPainter(iconColor)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen Noche lesson frame on [NocheColors.lessonGround].
class NocheLessonFrame extends StatelessWidget {
  const NocheLessonFrame({
    super.key,
    this.onClose,
    this.showClose = true,
    this.progress,
    this.onSound,
    this.muted = false,
    this.showSound = true,
    this.trailing,
    this.picture,
    this.caption,
    this.speaking = false,
    this.language,
    this.underPicture,
    this.bottom = const [],
    this.overlay,
    this.startState = false,
  });

  final VoidCallback? onClose;
  final bool showClose;
  final Widget? progress;
  final VoidCallback? onSound;
  final bool muted;
  final bool showSound;
  final Widget? trailing;
  final Widget? picture;
  final String? caption;
  final bool speaking;
  final Language? language;
  final Widget? underPicture;
  final List<Widget> bottom;
  final Widget? overlay;
  final bool startState;

  TextStyle _captionStyle() => NocheType.forScript(
    NocheType.lessonPrompt,
    language?.script ?? 'Latn',
  ).copyWith(color: NocheColors.text);

  Widget _captionText() => Text(
    caption ?? '',
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    textAlign: TextAlign.center,
    textDirection: language?.textDirection,
    locale: language?.locale,
    style: _captionStyle(),
  );

  Widget _captionRow() {
    final hasCaption = caption != null && caption!.isNotEmpty;
    if (!hasCaption) return _captionText();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: _captionText()),
        const SizedBox(width: 8),
        NocheSmallLevelBars(playing: speaking),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape = CoquiLayout.lessonLandscape(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: NocheColors.lessonGround,
      child: SafeArea(
        top: landscape,
        bottom: true,
        child: landscape ? _landscape(context) : _portrait(context, safeTop),
      ),
    );
  }

  Widget _topBar({required double safeTop, required double height}) => SizedBox(
    height: height + safeTop,
    child: Padding(
      padding: EdgeInsetsDirectional.fromSTEB(8, safeTop, 8, 0),
      child: Row(
        children: [
          Visibility(
            visible: showClose,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: NocheLessonCloseButton(
              key: const Key('review-close-button'),
              onPressed: onClose,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: progress ?? const SizedBox.shrink()),
          const SizedBox(width: 16),
          trailing ??
              Visibility(
                visible: showSound,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: NocheLessonSoundButton(onPressed: onSound, muted: muted),
              ),
        ],
      ),
    ),
  );

  Widget _stage(BuildContext context) {
    final motion = NocheMotion.of(context);
    final captionStyle = _captionStyle();
    final captionLineH =
        (captionStyle.fontSize ?? 18) * (captionStyle.height ?? 24 / 18);
    final captionMaxH = math.max(56.0, captionLineH * 2 + 8);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ?picture,
        SizedBox(
          height: 0,
          width: double.infinity,
          child: OverflowBox(
            alignment: AlignmentDirectional.topCenter,
            minHeight: 0,
            maxHeight: captionMaxH,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(top: 8),
              child: AnimatedOpacity(
                opacity: caption == null || caption!.isEmpty ? 0 : 1,
                duration: motion.quick,
                curve: motion.enter,
                child: _captionRow(),
              ),
            ),
          ),
        ),
        if (underPicture != null)
          SizedBox(
            height: 0,
            width: double.infinity,
            child: OverflowBox(
              alignment: AlignmentDirectional.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: 16),
                child: Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: nocheLessonColumnMax,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: underPicture,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _foot({required EdgeInsetsGeometry padding}) => Padding(
    padding: padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < bottom.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: nocheLessonColumnMax),
            child: bottom[i],
          ),
        ],
      ],
    ),
  );

  Widget _portrait(BuildContext context, double safeTop) => Column(
    children: [
      _topBar(safeTop: safeTop, height: nocheLessonTopBar),
      Expanded(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16,
                end: 16,
                bottom: nocheLessonFootReserve,
              ),
              child: Center(child: _stage(context)),
            ),
            ?overlay,
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: _foot(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _landscape(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width * 0.5),
              child: picture ?? const SizedBox.shrink(),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _topBar(safeTop: 0, height: nocheLessonTopBar),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(child: _captionRow()),
                      ?overlay,
                      if (startState)
                        Center(
                          child: _foot(padding: EdgeInsetsDirectional.zero),
                        )
                      else
                        PositionedDirectional(
                          start: 0,
                          end: 0,
                          bottom: 0,
                          child: _foot(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Progress dashes for Repaso with per-item outcome marks (no red).
class NocheReviewDashes extends StatelessWidget {
  const NocheReviewDashes({
    super.key,
    required this.segments,
    this.done = 0,
    this.dense = false,
    this.marks,
    this.current,
  });

  final int segments;
  final int done;
  final bool dense;
  final List<DashMark>? marks;
  final int? current;

  DashMark _mark(int i) {
    final m = marks;
    if (m == null) return i < done ? DashMark.right : DashMark.none;
    return i < m.length ? m[i] : DashMark.none;
  }

  @override
  Widget build(BuildContext context) {
    final all = [for (var i = 0; i < segments; i++) _mark(i)];
    final marked = all.where((m) => m != DashMark.none).length;
    final wrong = all.where((m) => m == DashMark.wrong).length;
    final gap = dense ? 1.0 : 4.0;
    final radius = dense ? 1.5 : 4.0;
    return Semantics(
      label: 'Progress',
      value: marks == null
          ? '$done of $segments'
          : wrong == 0
          ? '$marked of $segments'
          : '$marked of $segments, $wrong missed',
      excludeSemantics: true,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: nocheLessonColumnMax),
          child: Row(
            children: [
              for (var i = 0; i < segments; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(
                  child: _NocheReviewDash(
                    key: ValueKey('review_dash_$i'),
                    index: i,
                    mark: _mark(i),
                    isCurrent: current == i,
                    dense: dense,
                    radius: radius,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NocheReviewDash extends StatefulWidget {
  const _NocheReviewDash({
    super.key,
    required this.index,
    required this.mark,
    required this.isCurrent,
    required this.dense,
    required this.radius,
  });

  final int index;
  final DashMark mark;
  final bool isCurrent;
  final bool dense;
  final double radius;

  @override
  State<_NocheReviewDash> createState() => _NocheReviewDashState();
}

class _NocheReviewDashState extends State<_NocheReviewDash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  bool _animatingToRight = false;
  bool _reducedAtStart = false;
  Duration _fillDuration = NocheMotion.move;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _animatingToRight && mounted) {
      setState(() => _animatingToRight = false);
    }
  }

  @override
  void didUpdateWidget(_NocheReviewDash oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mark == DashMark.none && widget.mark == DashMark.right) {
      final motion = NocheMotion.of(context);
      _animatingToRight = true;
      _reducedAtStart = motion.reduced;
      _fillDuration = motion.reduced ? motion.quick : motion.move;
      _controller.duration = ReviewMotion.dashFillDelay + _fillDuration;
      _controller.forward(from: 0.0);
    } else if (widget.mark != DashMark.right && _animatingToRight) {
      _animatingToRight = false;
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
    final motion = NocheMotion.of(context);
    final radius = BorderRadius.circular(widget.radius);
    Widget? overlay;
    if (_animatingToRight) {
      overlay = AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final totalUs = (ReviewMotion.dashFillDelay + _fillDuration)
              .inMicroseconds
              .toDouble();
          final elapsedUs = _controller.value * totalUs;
          final delayUs = ReviewMotion.dashFillDelay.inMicroseconds.toDouble();
          final fillUs = _fillDuration.inMicroseconds.toDouble();
          final double raw;
          if (elapsedUs <= delayUs) {
            raw = 0.0;
          } else if (fillUs <= 0 || elapsedUs >= delayUs + fillUs) {
            raw = 1.0;
          } else {
            raw = ((elapsedUs - delayUs) / fillUs).clamp(0.0, 1.0);
          }
          final isReduced = _reducedAtStart || motion.reduced;
          final double fillWidth;
          final double fillOpacity;
          if (isReduced) {
            fillWidth = 1.0;
            fillOpacity = raw <= 0.0 ? 0.0 : motion.enter.transform(raw);
          } else {
            fillWidth = raw <= 0.0 ? 0.0 : motion.travel.transform(raw);
            fillOpacity = 1.0;
          }
          return ClipRRect(
            borderRadius: radius,
            child: ColoredBox(
              color: NocheColors.lessonLine,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  key: ValueKey('review_dash_fill_${widget.index}'),
                  widthFactor: fillWidth,
                  heightFactor: 1,
                  child: Opacity(
                    opacity: fillOpacity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: NocheColors.right,
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    return AnimatedContainer(
      duration: motion.quick,
      curve: motion.enter,
      height: 8,
      decoration: BoxDecoration(
        color: switch (widget.mark) {
          DashMark.right => NocheColors.right,
          DashMark.wrong => NocheColors.lessonGround,
          DashMark.skipped => NocheColors.lessonBorder,
          DashMark.none => NocheColors.lessonLine,
        },
        border: widget.mark == DashMark.wrong
            ? Border.all(color: NocheColors.text, width: 1.5)
            : null,
        borderRadius: radius,
        boxShadow: widget.isCurrent
            ? [
                BoxShadow(
                  color: NocheColors.listening,
                  spreadRadius: widget.dense ? 1 : 1.5,
                ),
              ]
            : null,
      ),
      child: overlay,
    );
  }
}

/// 28x28 green check badge with a white ring.
class NocheCheckBadge extends StatelessWidget {
  const NocheCheckBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: nocheBadgeSize,
    height: nocheBadgeSize,
    alignment: AlignmentDirectional.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: NocheColors.right,
      boxShadow: [
        BoxShadow(color: NocheColors.text, spreadRadius: nocheBadgeRing),
      ],
    ),
    child: const NocheIcon(
      NocheIcons.check,
      size: 16,
      strokeWidth: 3,
      color: NocheColors.onAccent,
    ),
  );
}

/// 28x28 calm wrong badge: panel fill with white outline (never red).
class NocheWrongBadge extends StatelessWidget {
  const NocheWrongBadge({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Wrong',
    excludeSemantics: true,
    child: Container(
      width: nocheBadgeSize,
      height: nocheBadgeSize,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: NocheColors.lessonPanel,
        border: Border.all(color: NocheColors.text, width: nocheBadgeRing),
      ),
      child: const NocheIcon(
        NocheIcons.close,
        size: 16,
        strokeWidth: 2.5,
        color: NocheColors.text,
      ),
    ),
  );
}

/// 22x22 pair-number badge for Parejas.
class NocheNumberBadge extends StatelessWidget {
  const NocheNumberBadge({super.key, required this.number});

  static const double size = 22;
  final int number;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Pair $number',
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: AlignmentDirectional.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: NocheColors.text,
      ),
      child: Text(
        '$number',
        style: NocheType.labelStrong.copyWith(
          color: NocheColors.lessonGround,
          letterSpacing: 0,
        ),
      ),
    ),
  );
}

/// 44x44 pointing-hand disc indicating the right option to touch.
class NocheTouchSign extends StatefulWidget {
  const NocheTouchSign({super.key, this.still = false});

  static const double size = 44;
  static const double pictureInset = 12;
  static const double bounce = 5;

  final bool still;

  @override
  State<NocheTouchSign> createState() => _NocheTouchSignState();
}

const _nocheTouchAppIcon = NocheIconData([
  NocheIconShape(
    'M9 11.24V7.5C9 6.12 10.12 5 11.5 5C12.88 5 14 6.12 14 7.5v3.74c1.21-.81 2-2.18 2-3.74'
    'C16 5.01 13.99 3 11.5 3C9.01 3 7 5.01 7 7.5c0 1.56.79 2.93 2 3.74z'
    'm9.84 4.63l-4.54-2.26c-.17-.07-.35-.11-.54-.11H13v-6c0-.83-.67-1.5-1.5-1.5'
    'C10.67 6 10 6.67 10 7.5v10.74l-3.43-.72c-.08-.01-.15-.03-.24-.03-.31 0-.59.13-.79.33l-.79.8'
    ' 4.94 4.94c.27.27.65.44 1.06.44h6.79c.75 0 1.33-.55 1.44-1.28l.75-5.27c.01-.07.02-.14.02-.2'
    ' 0-.62-.38-1.16-.91-1.38z',
    fill: true,
    stroke: false,
  ),
], strokeWidth: 0);

class _NocheTouchSignState extends State<NocheTouchSign>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: ReviewMotion.touchSignCycle,
  );

  bool get _still => widget.still || NocheMotion.of(context).reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NocheTouchSign old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (_still) {
      _a.stop();
      _a.value = 0;
    } else if (!_a.isAnimating) {
      _a.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return IgnorePointer(
      child: Semantics(
        label: 'Touch here',
        child: AnimatedBuilder(
          animation: _a,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              _still
                  ? 0
                  : -NocheTouchSign.bounce * motion.travel.transform(_a.value),
            ),
            child: child,
          ),
          child: Container(
            width: NocheTouchSign.size,
            height: NocheTouchSign.size,
            alignment: AlignmentDirectional.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: NocheColors.right,
              boxShadow: [BoxShadow(color: NocheColors.text, spreadRadius: 2)],
            ),
            child: const NocheIcon(
              _nocheTouchAppIcon,
              size: 30,
              color: NocheColors.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

(Color, double) _pictureRingSpec(ChoiceRing ring) => switch (ring) {
  ChoiceRing.none => (NocheColors.lessonBorder, nocheLessonBorder),
  ChoiceRing.right => (NocheColors.right, 3.0),
  ChoiceRing.wrong => (NocheColors.text, 3.0),
  ChoiceRing.selected => (NocheColors.text, 3.0),
};

/// Noche picture choice frame (green right, white outline + calm wrong badge on
/// wrong and never red, plain white outline on selected).
class NochePictureChoice extends StatefulWidget {
  const NochePictureChoice({
    super.key,
    required this.child,
    this.ring = ChoiceRing.none,
    this.dim = ChoiceDim.none,
    this.check = false,
    this.cross = false,
    this.inside = false,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final ChoiceRing ring;
  final ChoiceDim dim;
  final bool inside;
  final bool check;
  final bool cross;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<NochePictureChoice> createState() => _NochePictureChoiceState();
}

class _NochePictureChoiceState extends State<NochePictureChoice>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _badgeCtrl = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _expandCtrl = AnimationController(vsync: this)
    ..addStatusListener(_handleExpandStatus);

  late Color _fromColor;
  late Color _toColor;
  late double _fromWidth;
  late double _toWidth;
  bool _showExpandRing = false;

  void _handleExpandStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _showExpandRing && mounted) {
      setState(() => _showExpandRing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final (c, w) = _pictureRingSpec(widget.ring);
    _fromColor = _toColor = c;
    _fromWidth = _toWidth = w;
  }

  @override
  void didUpdateWidget(NochePictureChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    final motion = NocheMotion.of(context);
    if (widget.ring != oldWidget.ring) {
      final t = motion.enter.transform(_ringCtrl.value);
      _fromColor = Color.lerp(_fromColor, _toColor, t) ?? _toColor;
      _fromWidth = ui.lerpDouble(_fromWidth, _toWidth, t) ?? _toWidth;
      final (c, w) = _pictureRingSpec(widget.ring);
      _toColor = c;
      _toWidth = w;
      _ringCtrl.duration = motion.quick;
      _ringCtrl.forward(from: 0.0);

      if (oldWidget.ring != ChoiceRing.right &&
          widget.ring == ChoiceRing.right &&
          !motion.reduced) {
        _showExpandRing = true;
        _expandCtrl.duration = motion.settle;
        _expandCtrl.forward(from: 0.0);
      } else if (widget.ring != ChoiceRing.right && _showExpandRing) {
        _showExpandRing = false;
        _expandCtrl.stop();
        _expandCtrl.value = 0.0;
      }
    }

    final oldShowCross =
        oldWidget.cross ||
        (!oldWidget.check && oldWidget.ring == ChoiceRing.wrong);
    final newShowCross =
        widget.cross || (!widget.check && widget.ring == ChoiceRing.wrong);
    final oldHasBadge = oldWidget.check || oldShowCross;
    final newHasBadge = widget.check || newShowCross;
    if (newHasBadge && (!oldHasBadge || widget.check != oldWidget.check)) {
      _badgeCtrl.duration = motion.quick;
      _badgeCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _badgeCtrl.dispose();
    _expandCtrl
      ..removeStatusListener(_handleExpandStatus)
      ..dispose();
    super.dispose();
  }

  Widget _animatedBadge(NocheMotionData motion, Widget badge) =>
      AnimatedBuilder(
        animation: _badgeCtrl,
        child: badge,
        builder: (context, child) {
          final p = motion.enter.transform(_badgeCtrl.value).clamp(0.0, 1.0);
          final scale = motion.reduced ? 1.0 : (0.8 + 0.2 * p);
          return Opacity(
            opacity: p,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final showCross =
        widget.cross || (!widget.check && widget.ring == ChoiceRing.wrong);
    final pictureContent = AnimatedOpacity(
      opacity: widget.dim == ChoiceDim.whileSentence ? 0.5 : 1.0,
      duration: motion.move,
      curve: motion.enter,
      child: widget.child,
    );

    final body = AnimatedOpacity(
      opacity: widget.dim == ChoiceDim.unchosen ? 0.4 : 1.0,
      duration: motion.move,
      curve: motion.enter,
      child: AnimatedBuilder(
        animation: _ringCtrl,
        child: pictureContent,
        builder: (context, child) {
          final p = motion.enter.transform(_ringCtrl.value);
          final color = Color.lerp(_fromColor, _toColor, p) ?? _toColor;
          final width = ui.lerpDouble(_fromWidth, _toWidth, p) ?? _toWidth;
          if (widget.inside) {
            return Stack(
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: width),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: color, spreadRadius: width)],
            ),
            child: child,
          );
        },
      ),
    );

    final picture = Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        if (_showExpandRing && !motion.reduced)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _expandCtrl,
                builder: (context, _) {
                  final p = motion.enter.transform(_expandCtrl.value);
                  final scale = 1.0 + 0.08 * p;
                  final opacity = (0.9 * (1.0 - p)).clamp(0.0, 1.0);
                  return Transform.scale(
                    key: const ValueKey('choice_right_ring'),
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: NocheColors.right,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (widget.check)
          PositionedDirectional(
            end: nocheBadgeInset,
            top: nocheBadgeInset,
            child: _animatedBadge(motion, const NocheCheckBadge()),
          )
        else if (showCross)
          PositionedDirectional(
            end: nocheBadgeInset,
            top: nocheBadgeInset,
            child: _animatedBadge(motion, const NocheWrongBadge()),
          ),
      ],
    );
    if (widget.onTap == null) return picture;
    return Pressable(
      onPressed: widget.onTap,
      semanticLabel: widget.semanticLabel,
      builder: (context, pressed) => picture,
    );
  }
}

const double _nocheTileHeight = 56;
const double _nocheRingWidth = 3;
const double _nocheSignInset = 6;
const double _nocheEndRoom = 40;

Color? _nocheTileRingColor(ChoiceRing r) => switch (r) {
  ChoiceRing.none => null,
  ChoiceRing.right => NocheColors.right,
  ChoiceRing.wrong => NocheColors.text,
  ChoiceRing.selected => NocheColors.text,
};

(Color, double) _tileBorderSpec(TileLook look, ChoiceRing ring) {
  final empty = look == TileLook.empty;
  final rc = empty ? null : _nocheTileRingColor(ring);
  return (
    empty
        ? NocheColors.lessonLine.withValues(alpha: 0.6)
        : (rc ?? NocheColors.lessonBorder),
    rc == null ? nocheLessonBorder : _nocheRingWidth,
  );
}

class _NocheTileFace extends StatefulWidget {
  const _NocheTileFace({
    required this.child,
    required this.look,
    required this.ring,
    required this.check,
    required this.cross,
    required this.number,
    required this.sign,
    required this.pressed,
    required this.still,
    this.minWidth = _nocheTileHeight,
  });

  final Widget child;
  final TileLook look;
  final ChoiceRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool sign;
  final bool pressed;
  final bool still;
  final double minWidth;

  @override
  State<_NocheTileFace> createState() => _NocheTileFaceState();
}

class _NocheTileFaceState extends State<_NocheTileFace>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _badgeCtrl = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late final AnimationController _expandCtrl = AnimationController(vsync: this)
    ..addStatusListener(_handleExpandStatus);

  late Color _fromColor;
  late Color _toColor;
  late double _fromWidth;
  late double _toWidth;
  bool _showExpandRing = false;

  void _handleExpandStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _showExpandRing && mounted) {
      setState(() => _showExpandRing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final (c, w) = _tileBorderSpec(widget.look, widget.ring);
    _fromColor = _toColor = c;
    _fromWidth = _toWidth = w;
  }

  @override
  void didUpdateWidget(_NocheTileFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final motion = NocheMotion.of(context);
    final calm = widget.still || motion.reduced;
    if (widget.ring != oldWidget.ring ||
        (widget.look == TileLook.empty) != (oldWidget.look == TileLook.empty)) {
      final t = motion.enter.transform(_ringCtrl.value);
      _fromColor = Color.lerp(_fromColor, _toColor, t) ?? _toColor;
      _fromWidth = ui.lerpDouble(_fromWidth, _toWidth, t) ?? _toWidth;
      final (c, w) = _tileBorderSpec(widget.look, widget.ring);
      _toColor = c;
      _toWidth = w;
      _ringCtrl.duration = motion.quick;
      _ringCtrl.forward(from: 0.0);

      if (oldWidget.ring != ChoiceRing.right &&
          widget.ring == ChoiceRing.right &&
          widget.look != TileLook.empty &&
          !calm) {
        _showExpandRing = true;
        _expandCtrl.duration = motion.settle;
        _expandCtrl.forward(from: 0.0);
      } else if (widget.ring != ChoiceRing.right && _showExpandRing) {
        _showExpandRing = false;
        _expandCtrl.stop();
        _expandCtrl.value = 0.0;
      }
    }

    final oldEmpty = oldWidget.look == TileLook.empty;
    final newEmpty = widget.look == TileLook.empty;
    final oldShowCross =
        !oldEmpty &&
        (oldWidget.cross ||
            (!oldWidget.check && oldWidget.ring == ChoiceRing.wrong));
    final newShowCross =
        !newEmpty &&
        (widget.cross || (!widget.check && widget.ring == ChoiceRing.wrong));
    final oldHasBadge = oldWidget.check || oldShowCross;
    final newHasBadge = widget.check || newShowCross;
    if (newHasBadge && (!oldHasBadge || widget.check != oldWidget.check)) {
      _badgeCtrl.duration = motion.quick;
      _badgeCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _badgeCtrl.dispose();
    _expandCtrl
      ..removeStatusListener(_handleExpandStatus)
      ..dispose();
    super.dispose();
  }

  Widget _animatedBadge(NocheMotionData motion, Widget badge) =>
      AnimatedBuilder(
        animation: _badgeCtrl,
        child: badge,
        builder: (context, child) {
          final p = motion.enter.transform(_badgeCtrl.value).clamp(0.0, 1.0);
          final scale = motion.reduced ? 1.0 : (0.8 + 0.2 * p);
          return Opacity(
            opacity: p,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    final empty = widget.look == TileLook.empty;
    final calm = widget.still || motion.reduced;
    Widget face = AnimatedBuilder(
      animation: _ringCtrl,
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: empty ? Opacity(opacity: 0, child: widget.child) : widget.child,
      ),
      builder: (context, child) {
        final p = motion.enter.transform(_ringCtrl.value);
        final borderColor = Color.lerp(_fromColor, _toColor, p) ?? _toColor;
        final borderWidth = ui.lerpDouble(_fromWidth, _toWidth, p) ?? _toWidth;
        return Container(
          constraints: BoxConstraints(
            minHeight: _nocheTileHeight,
            minWidth: widget.minWidth,
          ),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 16 + nocheLessonBorder,
          ),
          decoration: BoxDecoration(
            color: empty
                ? null
                : (widget.pressed
                      ? NocheColors.litSentence
                      : NocheColors.lessonPanel),
            borderRadius: BorderRadius.circular(NocheSize.tileRadius),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NocheSize.tileRadius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        );
      },
    );
    face = AnimatedOpacity(
      opacity: switch (widget.look) {
        TileLook.normal || TileLook.empty => 1.0,
        TileLook.waiting => 0.5,
        TileLook.dim => 0.4,
      },
      duration: motion.move,
      curve: motion.enter,
      child: face,
    );
    final showCross =
        !empty &&
        (widget.cross || (!widget.check && widget.ring == ChoiceRing.wrong));
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        face,
        if (_showExpandRing && !calm)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _expandCtrl,
                builder: (context, _) {
                  final p = motion.enter.transform(_expandCtrl.value);
                  final scale = 1.0 + 0.08 * p;
                  final opacity = (0.9 * (1.0 - p)).clamp(0.0, 1.0);
                  return Transform.scale(
                    key: const ValueKey('choice_right_ring'),
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            NocheSize.tileRadius,
                          ),
                          border: Border.all(
                            color: NocheColors.right,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (widget.check)
          PositionedDirectional(
            end: -6,
            top: -10,
            child: _animatedBadge(motion, const NocheCheckBadge()),
          ),
        if (showCross)
          PositionedDirectional(
            end: -6,
            top: -10,
            child: _animatedBadge(motion, const NocheWrongBadge()),
          ),
        if (widget.number != null)
          PositionedDirectional(
            end: (widget.check || showCross) ? 28 : -4,
            top: (widget.check || showCross) ? -7 : -8,
            child: NocheNumberBadge(number: widget.number!),
          ),
        if (widget.sign)
          PositionedDirectional(
            end: _nocheSignInset,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Center(child: NocheTouchSign(still: calm)),
            ),
          ),
      ],
    );
  }
}

/// Noche word tile (56 min height, radius 16, calm feedback without shaking or red).
class NocheWordTile extends StatelessWidget {
  const NocheWordTile({
    super.key,
    required this.word,
    this.onTap,
    this.onSpeaker,
    this.look = TileLook.normal,
    this.ring = ChoiceRing.none,
    this.check = false,
    this.cross = false,
    this.number,
    this.sign = false,
    this.shake = 0,
    this.still = false,
    this.expand = false,
    this.language,
  });

  final String word;
  final VoidCallback? onTap;
  final VoidCallback? onSpeaker;
  final TileLook look;
  final ChoiceRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool sign;

  /// Accepted for API parity with `WordTile`; Noche keeps miss feedback calm
  /// (white outline, no shaking).
  final int shake;
  final bool still;
  final bool expand;
  final Language? language;

  @override
  Widget build(BuildContext context) {
    final wordStyle = NocheType.forScript(
      NocheType.row,
      language?.script ?? 'Latn',
    ).copyWith(color: NocheColors.text);
    final text = Text(
      word,
      textAlign: TextAlign.center,
      textDirection: language?.textDirection,
      locale: language?.locale,
      style: wordStyle,
    );
    final empty = look == TileLook.empty;
    final speaker = empty || sign ? null : onSpeaker;
    final endRoom = !empty && (onSpeaker != null || sign);
    Widget tile = Pressable(
      onPressed: empty ? null : onTap,
      semanticLabel: empty ? '' : word,
      builder: (context, pressed) => _NocheTileFace(
        look: look,
        ring: ring,
        check: check,
        cross: cross,
        number: number,
        sign: sign,
        pressed: pressed,
        still: still,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            vertical: 12,
            horizontal: endRoom ? _nocheEndRoom : 0,
          ),
          child: text,
        ),
      ),
    );
    if (expand) tile = SizedBox(width: double.infinity, child: tile);
    if (speaker == null) return tile;
    return Stack(
      children: [
        tile,
        PositionedDirectional(
          end: 6,
          top: 0,
          bottom: 0,
          child: Center(child: _NocheSpeakerButton(onPressed: speaker)),
        ),
      ],
    );
  }
}

class _NocheSpeakerButton extends StatelessWidget {
  const _NocheSpeakerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onPressed,
    semanticLabel: 'Hear the word',
    builder: (context, pressed) => Container(
      width: 40,
      height: 40,
      alignment: AlignmentDirectional.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: pressed ? NocheColors.litSentence : null,
      ),
      child: const NocheIcon(
        NocheIcons.speaker,
        size: 22,
        color: NocheColors.lessonLabel,
      ),
    ),
  );
}

/// Noche speaker tile for Parejas.
class NocheSpeakerTile extends StatelessWidget {
  const NocheSpeakerTile({
    super.key,
    required this.onTap,
    this.label = 'Play',
    this.look = TileLook.normal,
    this.ring = ChoiceRing.none,
    this.check = false,
    this.cross = false,
    this.number,
    this.playing = false,
    this.still = false,
    this.width = 88,
  });

  final VoidCallback? onTap;
  final String label;
  final TileLook look;
  final ChoiceRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool playing;
  final bool still;
  final double width;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticLabel: label,
    builder: (context, pressed) => _NocheTileFace(
      look: look,
      ring: ring,
      check: check,
      cross: cross,
      number: number,
      sign: false,
      pressed: pressed,
      still: still,
      minWidth: width,
      child: NocheIcon(
        NocheIcons.speaker,
        size: 26,
        color: playing ? NocheColors.text : NocheColors.lessonLabel,
      ),
    ),
  );
}

/// Noche tile tray for the word bank or answer line in Arma la frase.
class NocheTileTray extends StatelessWidget {
  const NocheTileTray({
    super.key,
    required this.children,
    this.line = false,
    this.lineRows = 1,
    this.lineTileHeight = _nocheTileHeight,
  });

  final List<Widget> children;
  final bool line;
  final int lineRows;
  final double lineTileHeight;

  static double lineHeight(int rows, {double tileHeight = _nocheTileHeight}) =>
      rows * tileHeight + (rows - 1) * 12 + 16 + nocheLessonBorder;

  @override
  Widget build(BuildContext context) {
    final wrap = Wrap(
      alignment: line ? WrapAlignment.start : WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 12,
      children: children,
    );
    if (!line) return wrap;
    return Container(
      constraints: BoxConstraints(
        minHeight: lineHeight(lineRows, tileHeight: lineTileHeight),
      ),
      padding: const EdgeInsetsDirectional.only(bottom: 8, top: 8),
      alignment: AlignmentDirectional.topStart,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: NocheColors.lessonBorder,
            width: nocheLessonBorder,
          ),
        ),
      ),
      child: wrap,
    );
  }
}

/// Noche streak chip ("N in a row").
class NocheStreakChip extends StatelessWidget {
  const NocheStreakChip({
    super.key,
    required this.count,
    this.from = 3,
    this.reserve = false,
  });

  static const double reservedWidth = 132;
  static const double height = 32;

  final int count;
  final int from;
  final bool reserve;

  @override
  Widget build(BuildContext context) {
    if (count < from) {
      return reserve
          ? const SizedBox(width: reservedWidth, height: height)
          : const SizedBox.shrink();
    }
    final chip = Semantics(
      label: '$count in a row',
      excludeSemantics: true,
      child: Container(
        height: height,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: NocheColors.lessonPanel,
          border: Border.all(color: NocheColors.lessonBorder, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.chipRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NocheIcon(
              NocheIcons.check,
              size: 16,
              strokeWidth: 3,
              color: NocheColors.right,
            ),
            const SizedBox(width: 6),
            Text(
              '$count in a row',
              style: NocheType.button.copyWith(color: NocheColors.text),
            ),
          ],
        ),
      ),
    );
    if (!reserve) return chip;
    return SizedBox(
      width: reservedWidth,
      height: height,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: chip,
      ),
    );
  }
}

/// Noche 64px round speaker button with listening pulse ring and replay arrow
/// spin (`settle`, `enter`, 1 counter-clockwise turn on replay).
class NocheRoundSpeaker extends StatefulWidget {
  const NocheRoundSpeaker({
    super.key,
    required this.onTap,
    this.playing = false,
    this.replayCount = 0,
    this.still = false,
    this.label = 'Hear it again',
  });

  static const double size = NocheSize.disc;
  static const double pulse = 10;

  final VoidCallback? onTap;
  final bool playing;
  final int replayCount;
  final bool still;
  final String label;

  @override
  State<NocheRoundSpeaker> createState() => _NocheRoundSpeakerState();
}

class _NocheRoundSpeakerState extends State<NocheRoundSpeaker>
    with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: ReviewMotion.speakerPulseCycle,
  );
  late final AnimationController _spin = AnimationController(vsync: this);

  bool get _calm => widget.still || NocheMotion.of(context).reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NocheRoundSpeaker old) {
    super.didUpdateWidget(old);
    _sync();
    if (widget.replayCount != old.replayCount &&
        widget.replayCount > old.replayCount &&
        !_calm) {
      final motion = NocheMotion.of(context);
      _spin.duration = motion.settle;
      _spin.forward(from: 0.0);
    } else if (_calm && _spin.isAnimating) {
      _spin.stop();
      _spin.value = 0.0;
    }
  }

  void _sync() {
    if (widget.playing && !_calm) {
      if (!_a.isAnimating) _a.repeat();
    } else {
      _a.stop();
      _a.value = 0;
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    const box = NocheRoundSpeaker.size + 2 * NocheRoundSpeaker.pulse;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          if (widget.playing)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _a,
                builder: (context, _) {
                  final t = _calm ? 0.5 : _a.value;
                  final r =
                      NocheRoundSpeaker.size / 2 + NocheRoundSpeaker.pulse * t;
                  return Container(
                    width: 2 * r,
                    height: 2 * r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: NocheColors.listening.withValues(
                          alpha: 0.9 * (1 - t),
                        ),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),
            ),
          Pressable(
            onPressed: widget.onTap,
            semanticLabel: widget.label,
            disc: true,
            builder: (context, pressed) => Container(
              width: NocheRoundSpeaker.size,
              height: NocheRoundSpeaker.size,
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pressed
                    ? NocheColors.litSentence
                    : NocheColors.lessonPanel,
                border: Border.all(
                  color: widget.playing
                      ? NocheColors.listening
                      : NocheColors.lessonBorder,
                  width: nocheLessonBorder,
                ),
              ),
              child: AnimatedBuilder(
                animation: _spin,
                builder: (context, child) {
                  final angle = _calm
                      ? 0.0
                      : -2 * math.pi * motion.enter.transform(_spin.value);
                  return Transform.rotate(
                    key: const ValueKey('review_replay_arrow'),
                    angle: angle,
                    child: child,
                  );
                },
                child: NocheIcon(
                  NocheIcons.replay,
                  size: 28,
                  color: widget.playing
                      ? NocheColors.listening
                      : NocheColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three small vertical audio level bars (`Noche-Motion-Cuento.dc.html` `.lvw`):
/// 4 px wide, 24 px max height, 2 px radius, 4 px gap, `NocheColors.other`.
/// Fades in/out over `quick` and loops bar heights on `NocheMotion.levelCycle`
/// (`0.15..1.0`); stands still at `0.6` under reduced motion or [still].
class NocheSmallLevelBars extends StatefulWidget {
  const NocheSmallLevelBars({
    super.key = const ValueKey('review_level_bars'),
    required this.playing,
    this.still = false,
  });

  final bool playing;
  final bool still;

  static const double barWidth = 4;
  static const double maxHeight = 24;
  static const double gap = 4;
  static const double radius = 2;

  @override
  State<NocheSmallLevelBars> createState() => _NocheSmallLevelBarsState();
}

class _NocheSmallLevelBarsState extends State<NocheSmallLevelBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: NocheMotion.levelCycle,
  );

  bool get _calm => widget.still || NocheMotion.of(context).reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NocheSmallLevelBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.playing && !_calm) {
      if (!_loop.isAnimating) _loop.repeat();
    } else {
      _loop.stop();
      _loop.value = 0;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  double _scaleFor(int i) {
    if (_calm) return 0.6;
    final phase = (_loop.value + i / 3.0) % 1.0;
    return 0.15 + 0.85 * (0.5 - 0.5 * math.cos(2 * math.pi * phase));
  }

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          opacity: widget.playing ? 1.0 : 0.0,
          duration: motion.quick,
          curve: motion.enter,
          child: SizedBox(
            height: NocheSmallLevelBars.maxHeight,
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: NocheSmallLevelBars.gap),
                    Transform.scale(
                      key: ValueKey('review_level_bar_$i'),
                      scaleY: _scaleFor(i),
                      alignment: AlignmentDirectional.center,
                      child: Container(
                        width: NocheSmallLevelBars.barWidth,
                        height: NocheSmallLevelBars.maxHeight,
                        decoration: BoxDecoration(
                          color: NocheColors.other,
                          borderRadius: BorderRadius.circular(
                            NocheSmallLevelBars.radius,
                          ),
                        ),
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

/// Fades the outgoing lesson item or view out in `quick` (`140 ms`, `exit`)
/// while mounting the incoming view under `ValueKey('review_item_incoming')`.
class NocheItemTransition extends StatefulWidget {
  const NocheItemTransition({
    super.key,
    required this.contentKey,
    required this.child,
    this.expand = false,
  });

  final Object contentKey;
  final Widget child;
  final bool expand;

  @override
  State<NocheItemTransition> createState() => _NocheItemTransitionState();
}

class _NocheItemTransitionState extends State<NocheItemTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _outCtrl = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  GlobalKey _currentKey = GlobalKey();
  GlobalKey? _outgoingKey;
  Widget? _outgoing;
  NocheMotionData _motion = NocheMotion.normal;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null && mounted) {
      setState(() {
        _outgoing = null;
        _outgoingKey = null;
      });
    }
  }

  @override
  void didUpdateWidget(NocheItemTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contentKey != oldWidget.contentKey) {
      _outgoing = oldWidget.child;
      _outgoingKey = _currentKey;
      _currentKey = GlobalKey();
      _motion = NocheMotion.of(context);
      _outCtrl.duration = _motion.quick;
      _outCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _outCtrl
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incoming = KeyedSubtree(
      key: const ValueKey('review_item_incoming'),
      child: KeyedSubtree(key: _currentKey, child: widget.child),
    );

    Widget? outgoingLayer;
    if (_outgoing != null && _outCtrl.value < 1.0) {
      final faded = IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _outCtrl,
            builder: (context, child) {
              final opacity = (1.0 - _motion.exit.transform(_outCtrl.value))
                  .clamp(0.0, 1.0);
              return Opacity(
                key: const ValueKey('review_item_outgoing'),
                opacity: opacity,
                child: child,
              );
            },
            child: KeyedSubtree(key: _outgoingKey, child: _outgoing!),
          ),
        ),
      );
      outgoingLayer = widget.expand ? Positioned.fill(child: faded) : faded;
    }

    if (widget.expand) {
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [incoming, ?outgoingLayer],
      );
    }
    return Stack(
      alignment: AlignmentDirectional.center,
      clipBehavior: Clip.none,
      children: [incoming, ?outgoingLayer],
    );
  }
}

/// Rises its [child] by `motion.row` (`8 px -> 0`) and fades `0 -> 1` in
/// `motion.move` on `motion.enter` after [delay]. Under reduced motion,
/// `row == 0` and `move == quick`, so it fades in place.
class NocheRiseIn extends StatefulWidget {
  const NocheRiseIn({
    super.key,
    this.delay = Duration.zero,
    this.animate = true,
    required this.child,
  });

  final Duration delay;
  final bool animate;
  final Widget child;

  @override
  State<NocheRiseIn> createState() => _NocheRiseInState();
}

class _NocheRiseInState extends State<NocheRiseIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  NocheMotionData _motion = NocheMotion.normal;
  bool _started = false;
  double _totalUs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _motion = NocheMotion.of(context);
    if (!widget.animate) {
      _totalUs = 0;
      _controller.value = 1.0;
      return;
    }
    final total = widget.delay + _motion.move;
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

  double _progress() {
    if (!widget.animate ||
        _controller.isCompleted ||
        (!_controller.isAnimating && _started)) {
      return 1.0;
    }
    if (_totalUs <= 0) return 1.0;
    final elapsedUs = _controller.value * _totalUs;
    final delayUs = widget.delay.inMicroseconds.toDouble();
    final moveUs = _motion.move.inMicroseconds.toDouble();
    if (elapsedUs <= delayUs) return 0.0;
    if (moveUs <= 0 || elapsedUs >= delayUs + moveUs) return 1.0;
    final raw = ((elapsedUs - delayUs) / moveUs).clamp(0.0, 1.0);
    return _motion.enter.transform(raw);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final p = _progress();
        final dy = _motion.row * (1.0 - p);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(opacity: p, child: child),
        );
      },
    );
  }
}

/// Pure arrival timing schedule for the review end screen.
class ReviewEndSchedule {
  ReviewEndSchedule(this.motion, List<int> groupSizes) {
    doneStart = ReviewMotion.endStartDelay;
    summaryStart = doneStart + motion.stagger;
    final headers = <Duration>[];
    final words = <List<Duration>>[];
    var lastStart = summaryStart;
    for (var g = 0; g < groupSizes.length; g++) {
      final headerStart = lastStart + motion.stagger;
      headers.add(headerStart);
      final size = groupSizes[g];
      final groupWords = <Duration>[];
      var groupLast = headerStart;
      for (var i = 0; i < size; i++) {
        final ws = headerStart + motion.stagger * (1 + math.min(i, 4));
        groupWords.add(ws);
        groupLast = ws;
      }
      words.add(groupWords);
      lastStart = groupLast;
    }
    groupHeaderStart = headers;
    wordStart = words;
    nextButtonStart = lastStart + motion.nextDelay;
  }

  final NocheMotionData motion;
  late final Duration doneStart;
  late final Duration summaryStart;
  late final List<Duration> groupHeaderStart;
  late final List<List<Duration>> wordStart;
  late final Duration nextButtonStart;
}
