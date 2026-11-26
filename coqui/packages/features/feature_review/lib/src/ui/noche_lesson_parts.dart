/// Noche lesson and game UI pieces for feature_review.
///
/// Built solely on Noche tokens (`NocheColors`, `NocheType`, `NocheSize`,
/// `NocheIcon`, `NocheIcons`) with directional layout APIs and zero red.
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
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
            child: NocheLessonCloseButton(onPressed: onClose),
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

  Widget _stage() {
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
                duration: const Duration(milliseconds: 120),
                child: _captionText(),
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
              child: Center(child: _stage()),
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
                      Center(child: _captionText()),
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 8,
                    decoration: BoxDecoration(
                      color: switch (_mark(i)) {
                        DashMark.right => NocheColors.right,
                        DashMark.wrong => NocheColors.lessonGround,
                        DashMark.skipped => NocheColors.lessonBorder,
                        DashMark.none => NocheColors.lessonLine,
                      },
                      border: _mark(i) == DashMark.wrong
                          ? Border.all(color: NocheColors.text, width: 1.5)
                          : null,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: current == i
                          ? [
                              BoxShadow(
                                color: NocheColors.listening,
                                spreadRadius: dense ? 1 : 1.5,
                              ),
                            ]
                          : null,
                    ),
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
    duration: const Duration(milliseconds: 700),
  );

  bool get _still =>
      widget.still || MediaQuery.maybeDisableAnimationsOf(context) == true;

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
  Widget build(BuildContext context) => IgnorePointer(
    child: Semantics(
      label: 'Touch here',
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            -NocheTouchSign.bounce * Curves.easeInOut.transform(_a.value),
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

/// Noche picture choice frame (green right, white outline + calm wrong badge on
/// wrong and never red, plain white outline on selected).
class NochePictureChoice extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final showCross = cross || (!check && ring == ChoiceRing.wrong);
    final (color, width) = switch (ring) {
      ChoiceRing.none => (NocheColors.lessonBorder, nocheLessonBorder),
      ChoiceRing.right => (NocheColors.right, 3.0),
      ChoiceRing.wrong => (NocheColors.text, 3.0),
      ChoiceRing.selected => (NocheColors.text, 3.0),
    };
    final dimColor = switch (dim) {
      ChoiceDim.none => null,
      ChoiceDim.whileSentence => NocheColors.lessonGround.withValues(
        alpha: 0.5,
      ),
      ChoiceDim.unchosen => NocheColors.lessonGround.withValues(alpha: 0.55),
    };
    final picture = Stack(
      clipBehavior: Clip.none,
      children: [
        if (inside)
          Stack(
            children: [
              child,
              if (dimColor != null)
                Positioned.fill(child: ColoredBox(color: dimColor)),
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
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: color, spreadRadius: width)],
            ),
            child: Stack(
              children: [
                child,
                if (dimColor != null)
                  Positioned.fill(child: ColoredBox(color: dimColor)),
              ],
            ),
          ),
        if (check)
          const PositionedDirectional(
            end: nocheBadgeInset,
            top: nocheBadgeInset,
            child: NocheCheckBadge(),
          )
        else if (showCross)
          const PositionedDirectional(
            end: nocheBadgeInset,
            top: nocheBadgeInset,
            child: NocheWrongBadge(),
          ),
      ],
    );
    if (onTap == null) return picture;
    return Pressable(
      onPressed: onTap,
      semanticLabel: semanticLabel,
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

class _NocheTileFace extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final empty = look == TileLook.empty;
    final rc = empty ? null : _nocheTileRingColor(ring);
    Widget face = Container(
      constraints: BoxConstraints(
        minHeight: _nocheTileHeight,
        minWidth: minWidth,
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16 + nocheLessonBorder,
      ),
      decoration: BoxDecoration(
        color: empty
            ? null
            : (pressed ? NocheColors.litSentence : NocheColors.lessonPanel),
        borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(NocheSize.tileRadius),
        border: Border.all(
          color: empty
              ? NocheColors.lessonLine.withValues(alpha: 0.6)
              : (rc ?? NocheColors.lessonBorder),
          width: rc == null ? nocheLessonBorder : _nocheRingWidth,
        ),
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: empty ? Opacity(opacity: 0, child: child) : child,
      ),
    );
    face = Opacity(
      opacity: switch (look) {
        TileLook.normal || TileLook.empty => 1.0,
        TileLook.waiting => 0.5,
        TileLook.dim => 0.35,
      },
      child: face,
    );
    final calm = still || MediaQuery.maybeDisableAnimationsOf(context) == true;
    final showCross = !empty && (cross || (!check && ring == ChoiceRing.wrong));
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        face,
        if (check)
          const PositionedDirectional(
            end: -6,
            top: -10,
            child: NocheCheckBadge(),
          ),
        if (showCross)
          const PositionedDirectional(
            end: -6,
            top: -10,
            child: NocheWrongBadge(),
          ),
        if (number != null)
          PositionedDirectional(
            end: (check || showCross) ? 28 : -4,
            top: (check || showCross) ? -7 : -8,
            child: NocheNumberBadge(number: number!),
          ),
        if (sign)
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

/// Noche 64px round speaker button with listening pulse ring.
class NocheRoundSpeaker extends StatefulWidget {
  const NocheRoundSpeaker({
    super.key,
    required this.onTap,
    this.playing = false,
    this.still = false,
    this.label = 'Hear it again',
  });

  static const double size = NocheSize.disc;
  static const double pulse = 10;

  final VoidCallback? onTap;
  final bool playing;
  final bool still;
  final String label;

  @override
  State<NocheRoundSpeaker> createState() => _NocheRoundSpeakerState();
}

class _NocheRoundSpeakerState extends State<NocheRoundSpeaker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  bool get _calm =>
      widget.still || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(NocheRoundSpeaker old) {
    super.didUpdateWidget(old);
    _sync();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              child: NocheIcon(
                NocheIcons.speaker,
                size: 28,
                color: widget.playing
                    ? NocheColors.listening
                    : NocheColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
