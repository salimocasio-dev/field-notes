/// Repaso as games on screen (docs/proyecto/15-repaso-juegos.md): the start, each game, the end. The session
/// (logic/repaso_session.dart) decides everything; this draws it and passes touches on.
///
/// The Noche lesson frame: dark lesson ground, the close X, the dashes (one for each item of the session), the sound
/// button. Each game has one fixed layout from the moment it is asked, and nothing moves when he touches: (1) the
/// English line saying what to do, and the place of the "N in a row" chip (kept whether it shows or not); (2) the
/// round speaker, the same size and place in every game that plays a sentence; (3) the game's own area; (4) the
/// reveal, a place of its own where the sentence appears after the answer; (5) the Next button's place at the bottom,
/// empty until Next shows. The content starts under the top bar.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/repaso_plan.dart';
import 'package:feature_review/src/logic/repaso_session.dart';
import 'package:feature_review/src/logic/repaso_words.dart';
import 'package:feature_review/src/logic/review_session.dart'
    show OptionRing, ReviewOptions;
import 'package:feature_review/src/logic/word_picture.dart';
import 'package:feature_review/src/motion.dart';
import 'package:feature_review/src/ui/block_layout.dart'
    show pictureHeight, pictureWidth;
import 'package:feature_review/src/ui/book_image.dart';
import 'package:feature_review/src/ui/host_wait.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
import 'package:feature_review/src/ui/repaso_layout.dart';
import 'package:material_ui/material_ui.dart';

/// The feature's own storage space (the last sentence each word was asked in).
const String reviewSpace = 'review';

class RepasoScreen extends StatefulWidget {
  const RepasoScreen({
    super.key,
    required this.services,
    required this.data,
    this.imageUrl = defaultBookImageUrl,
    this.imageProvider = networkBookImage,
    this.options = const ReviewOptions(),
    this.wordAssets = const {},
    this.wait,
    this.endScroll,
  });

  final Services services;
  final RepasoData data;
  final BookImageUrl imageUrl;
  final BookImageProvider imageProvider;
  final ReviewOptions options;
  final Map<String, WordPictureAsset> wordAssets;

  /// The host's wait. Left out, a timer is used; tests give a virtual clock's.
  final Wait? wait;
  final ScrollController? endScroll;

  @override
  State<RepasoScreen> createState() => RepasoScreenState();
}

/// What the reveal shows once an item is answered: its sentence (with [word] lit).
class _Reveal {
  const _Reveal(this.text, this.word);
  final String? text;
  final String? word;
}

/// A game's own area and the height it takes.
class _Area {
  const _Area(this.child, this.height);
  final Widget child;
  final double height;
}

/// Immutable snapshot of a [Choice] captured when building a game view so
/// outgoing [NocheItemTransition] layers stay frozen while fading out.
class _ChoiceSnap {
  _ChoiceSnap.from(Choice c)
    : label = c.label,
      clip = c.clip,
      right = c.right,
      pre = c.pre,
      dim = c.dim,
      ring = c.ring,
      check = c.check,
      cross = c.cross,
      number = c.number,
      sign = c.sign,
      done = c.done,
      shakes = c.shakes;

  final String label;
  final String? clip;
  final bool right;
  final bool pre;
  final bool dim;
  final OptionRing ring;
  final bool check;
  final bool cross;
  final int? number;
  final bool sign;
  final bool done;
  final int shakes;
}

/// Immutable snapshot of the active item in [RepasoSession].
class _GameSnap {
  _GameSnap.from(RepasoSession s)
    : entry = s.entry!,
      item = s.item!,
      streak = s.streak,
      sentencePlaying = s.sentencePlaying,
      replayCount = s.replayCount,
      showText = s.showText,
      choices = [for (final c in s.choices) _ChoiceSnap.from(c)],
      speakers = [for (final c in s.speakers) _ChoiceSnap.from(c)],
      selectedSpeaker = s.selectedSpeaker,
      placed = List<int>.of(s.placed),
      mic = s.mic,
      heard = s.heard,
      heardRight = s.heardRight,
      notHeard = s.notHeard;

  final QueueEntry entry;
  final GameItem item;
  final int streak;
  final bool sentencePlaying;
  final int replayCount;
  final bool showText;
  final List<_ChoiceSnap> choices;
  final List<_ChoiceSnap> speakers;
  final int? selectedSpeaker;
  final List<int> placed;
  final MicState mic;
  final String heard;
  final bool heardRight;
  final bool notHeard;
}

class RepasoScreenState extends State<RepasoScreen> {
  late final RepasoSession session;
  HostWait? _host;

  Services get _s => widget.services;
  Language get _lang => _s.course.language;
  TextStyle _courseStyle(TextStyle style) =>
      NocheType.forScript(style, _lang.script);

  static const double _gap = 12.0;
  static const double _topPad = 8.0;
  static const double _bottomPad = 16.0;

  /// The Next button's place: 56 px high, 24 under it and 16 above it. It is the same whether Next shows or not.
  static const double _foot = 56 + 24 + 16;

  static final TextStyle _instructionStyle = NocheType.bodyLarge.copyWith(
    color: NocheColors.label,
  );
  static final TextStyle _revealStyle = NocheType.lessonPrompt.copyWith(
    color: NocheColors.text,
  );
  static final TextStyle _tileTextStyle = NocheType.row.copyWith(
    color: NocheColors.text,
  );
  static final TextStyle _sayLabelStyle = NocheType.body.copyWith(
    color: NocheColors.lessonLabel,
  );
  static final TextStyle _sayPillStyle = NocheType.rowTitle.copyWith(
    color: NocheColors.text,
  );
  static final TextStyle _saySentenceStyle = NocheType.transcriptNow.copyWith(
    color: NocheColors.text,
  );

  @override
  void initState() {
    super.initState();
    final wait = widget.wait ?? (_host = HostWait()).call;
    KeyValueStore? space;
    try {
      space = _s.storage(reviewSpace);
    } catch (_) {
      space = null;
    }
    session = RepasoSession(
      data: widget.data,
      rng: _s.rng,
      clock: _s.clock,
      course: _s.course,
      progress: _s.progress,
      clips: _s.clips,
      wait: wait,
      speech: _s.speech,
      storage: space,
      options: widget.options,
      wordAssets: widget.wordAssets,
    );
    session.prepare();
    session.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    session.removeListener(_changed);
    session.dispose();
    _host?.cancelAll();
    super.dispose();
  }

  void _start() {
    if (session.screen != LessonScreen.start) return;
    unawaited(_s.clips.unlock());
    unawaited(session.run());
  }

  /// The start disc pressed, for a test or a tool that cannot reach it by touch.
  Future<void> pressStart() async => _start();

  void _close() {
    session.leave();
    _s.nav.go(const TabRoute('words'));
  }

  void _toggleSound() => setState(() => _s.clips.muted = !_s.clips.muted);

  bool get _still => _s.reduceMotion || MediaQuery.disableAnimationsOf(context);

  ImageProvider _book(String img) => widget.imageProvider(widget.imageUrl(img));

  // ---- the bottom zone: Next's place, kept whether Next shows or not

  Widget _next() {
    final s = session;
    Widget? button;
    if (s.canNext) {
      button = NochePrimaryButton(
        key: const Key('review-next-button'),
        label: RepasoStrings.next,
        onPressed: s.pressNext,
      );
    } else if (s.item is SayItem &&
        !s.showText &&
        s.mic != MicState.ok &&
        s.mic != MicState.missed) {
      // "Can't speak now" stands where Next will: the one button of the bottom of the screen (not once the turn is
      // over: heard right, or the two tries not heard)
      button = Align(
        child: NocheOutlineButton(
          label: RepasoStrings.cantSpeak,
          expand: false,
          onPressed: s.cantSpeak,
        ),
      );
    }
    return SizedBox(
      key: const ValueKey('next-slot'),
      width: double.infinity,
      height: NocheSize.primaryHeight,
      child: button,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = LessonBox.of(context, constraints);
      final s = session;
      final start = s.screen == LessonScreen.start;
      final end = s.screen == LessonScreen.end;
      final play = s.screen == LessonScreen.play && s.item != null;
      final motion = NocheMotion.of(context);
      final endSchedule = end
          ? ReviewEndSchedule(motion, [
              for (final g in s.end!.groups) g.rows.length,
            ])
          : null;
      // before the first item is asked: how many pictures a ¿Dónde? item can have on this screen
      s.wherePictures = _wherePlan(context, box, constraints).count;
      final Object contentKey = start
          ? LessonScreen.start
          : end
          ? LessonScreen.end
          : play
          ? s.entry!
          : 'empty';
      final Widget overlayChild = start
          ? Stack(
              fit: StackFit.expand,
              children: [
                LessonTextScreen(
                  box: box,
                  title: s.screenTitle,
                  lines: s.screenLines,
                ),
              ],
            )
          : end
          ? Stack(
              fit: StackFit.expand,
              children: [
                RepasoEndView(
                  box: box,
                  end: s.end!,
                  onRow: s.playRow,
                  language: _lang,
                  controller: widget.endScroll,
                  schedule: endSchedule,
                ),
              ],
            )
          : play
          ? Padding(
              padding: const EdgeInsetsDirectional.only(bottom: _foot),
              child: _game(context, box, _GameSnap.from(s)),
            )
          : const SizedBox.shrink();
      return NocheLessonFrame(
        onClose: _close,
        showClose: !end,
        showSound: !end,
        onSound: _toggleSound,
        muted: _s.clips.muted,
        language: _lang,
        progress: NocheReviewDashes(
          segments: s.barSegments,
          marks: s.barMarks,
          current: s.barCurrent,
          dense: s.barSegments > 24,
        ),
        overlay: Positioned.fill(
          child: NocheItemTransition(
            contentKey: contentKey,
            expand: true,
            child: overlayChild,
          ),
        ),
        bottom: [
          if (start)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 16),
              child: NochePlayDisc(
                key: const Key('review-start-disc'),
                size: nocheLessonStartDisc,
                icon: NocheIcons.play,
                semanticLabel: 'Start',
                onPressed: _start,
              ),
            ),
          if (end)
            NocheRiseIn(
              key: const ValueKey('review_end_action_rise'),
              delay: endSchedule!.nextButtonStart,
              child: NochePrimaryButton(
                key: const Key('review-end-action'),
                label:
                    'Back to ${_lang.tabNames['words'] ?? CoquiLabels.words}',
                onPressed: () {
                  s.leave();
                  _s.nav.go(const TabRoute('words'));
                },
              ),
            ),
          if (play) _next(),
        ],
        startState: start,
      );
    },
  );

  // ---- the arithmetic

  double _width(LessonBox box, BoxConstraints c) {
    final side = box.landscape ? 0.0 : 16.0;
    return math.min(nocheLessonColumnMax, c.maxWidth - 2 * side);
  }

  Size _textSize(
    BuildContext context,
    String text,
    TextStyle style,
    double w, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: w);
    final size = tp.size;
    tp.dispose();
    return size;
  }

  double _textH(
    BuildContext context,
    String text,
    TextStyle style,
    double w, {
    TextDirection textDirection = TextDirection.ltr,
  }) => _textSize(context, text, style, w, textDirection: textDirection).height;

  /// The line that says what to do, with the chip's place at its end: as high as the tallest of the six lines, so that
  /// what stands under it (the round speaker) is in the same place in every game.
  double _headerH(BuildContext context, GameKind kind, double width) => [
    NocheStreakChip.height,
    for (final k in GameKind.values)
      _textH(
        context,
        gameInstruction(k),
        _instructionStyle,
        width - NocheStreakChip.reservedWidth - 12,
      ),
  ].reduce(math.max);

  bool _hasRound(GameItem it) => it is! MatchItem;

  /// What stands above the game's own area: the top, the line and its chip, the round speaker.
  double _above(BuildContext context, GameItem it, double width) =>
      _topPad +
      _headerH(context, it.kind, width) +
      _gap +
      (_hasRound(it) ? NocheRoundSpeaker.size + _gap : 0);

  _Reveal _reveal(GameItem it) => switch (it) {
    CualItem() => _Reveal(it.text, it.word),
    HearItem() => _Reveal(it.text, it.word),
    BuildItem() => _Reveal(it.text, null),
    MatchItem() => const _Reveal(null, null),
    WhereItem() => _Reveal(it.text, null),
    SayItem() => const _Reveal(null, null),
  };

  /// ¿Dónde?'s pictures on this screen: how many, and how big. The room is what is left under the line and the
  /// round speaker when the reveal has three lines of text.
  ({int count, int k}) _wherePlan(
    BuildContext context,
    LessonBox box,
    BoxConstraints c,
  ) {
    final width = _width(box, c);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final above =
        _topPad +
        _headerH(context, GameKind.where, width) +
        _gap +
        NocheRoundSpeaker.size +
        _gap;
    final text =
        3 *
        _textH(
          context,
          'x',
          _courseStyle(_revealStyle),
          width,
          textDirection: _lang.textDirection,
        );
    final room = box.mainHeight - _foot - above - _gap - text - _bottomPad;
    return planWhere(available: 3, width: width, height: room, dpr: dpr);
  }

  // ---- a game

  Widget _game(BuildContext context, LessonBox box, _GameSnap snap) =>
      LayoutBuilder(
        builder: (context, c) {
          final it = snap.item;
          final side = box.landscape ? 0.0 : 16.0;
          final width = _width(box, c);
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final reveal = _reveal(it);
          final textH = reveal.text == null
              ? 0.0
              : _textH(
                  context,
                  reveal.text!,
                  _courseStyle(_revealStyle),
                  width,
                  textDirection: _lang.textDirection,
                );
          final above = _above(context, it, width);
          final motion = NocheMotion.of(context);
          final hasRound = _hasRound(it);
          final areaStartIdx = hasRound ? 2 : 1;
          Duration rowDelay(int idx) =>
              ReviewMotion.itemRowsDelay + motion.stagger * math.min(idx, 4);
          // the game's own area gets what is left when the reveal has its text
          final budget = c.maxHeight - above - _gap - textH - _bottomPad;
          final area = switch (it) {
            CualItem() => _cual(
              context,
              snap,
              it,
              width,
              budget,
              dpr,
              motion,
              areaStartIdx,
            ),
            HearItem() => _hear(snap, it, motion, areaStartIdx),
            BuildItem() => _build(context, snap, it, width),
            MatchItem() => _match(snap, it, motion, areaStartIdx),
            WhereItem() => _where(context, snap, it, width, budget, dpr),
            SayItem() => _say(context, snap, it, width),
          };
          final areaHasOwnRise =
              it is CualItem || it is HearItem || it is MatchItem;
          final revealIdx = switch (it) {
            CualItem() => areaStartIdx + snap.choices.length,
            HearItem() => areaStartIdx + snap.choices.length,
            MatchItem() => areaStartIdx + snap.speakers.length,
            _ => areaStartIdx + 1,
          };
          return SingleChildScrollView(
            padding: EdgeInsetsDirectional.fromSTEB(
              side,
              _topPad,
              side,
              _bottomPad,
            ),
            child: Center(
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // (1) the line saying what to do, and the chip's place: as high as the tallest of the six lines, so
                    // that what is under it is in the same place in every game
                    NocheRiseIn(
                      key: const ValueKey('review_item_row_0'),
                      delay: rowDelay(0),
                      child: SizedBox(
                        height: _headerH(context, it.kind, width),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                gameInstruction(it.kind),
                                key: const ValueKey('game-instruction'),
                                style: _instructionStyle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            NocheStreakChip(
                              count: snap.streak,
                              from: repasoStreakFrom,
                              reserve: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: _gap),
                    // (2) the round speaker
                    if (hasRound) ...[
                      NocheRiseIn(
                        key: const ValueKey('review_item_row_1'),
                        delay: rowDelay(1),
                        child: _speaker(snap),
                      ),
                      const SizedBox(height: _gap),
                    ],
                    // (3) the game's own area
                    if (areaHasOwnRise)
                      area.child
                    else
                      NocheRiseIn(
                        key: ValueKey('review_item_row_$areaStartIdx'),
                        delay: rowDelay(areaStartIdx),
                        child: area.child,
                      ),
                    const SizedBox(height: _gap),
                    // (4) the reveal
                    NocheRiseIn(
                      key: const ValueKey('review_item_row_reveal'),
                      delay: rowDelay(revealIdx),
                      child: KeyedSubtree(
                        key: const ValueKey('reveal'),
                        child: _revealArea(snap, reveal, textH),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _speaker(_GameSnap snap) {
    const room = NocheRoundSpeaker.size + 2 * NocheRoundSpeaker.pulse;
    return SizedBox(
      height: NocheRoundSpeaker.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: AlignmentDirectional.center,
        children: [
          OverflowBox(
            minWidth: 0,
            minHeight: 0,
            maxWidth: room,
            maxHeight: room,
            child: NocheRoundSpeaker(
              onTap: session.replay,
              playing: snap.sentencePlaying,
              replayCount: snap.replayCount,
              still: _still,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.center,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: room + 24),
              child: NocheSmallLevelBars(
                playing: snap.sentencePlaying,
                still: _still,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The sentence written out, the word lit (Noche lit-sentence colours), following the course's language.
  Widget _litText(
    String text,
    String? word, {
    TextStyle? style,
    bool underline = false,
  }) {
    final at = word == null ? null : findWord(text, word, language: _lang);
    final base = _courseStyle(style ?? _revealStyle);
    return Text.rich(
      at == null
          ? TextSpan(text: text, style: base)
          : TextSpan(
              style: base,
              children: [
                TextSpan(text: text.substring(0, at.start)),
                TextSpan(
                  text: text.substring(at.start, at.end),
                  style: base.copyWith(
                    fontWeight: FontWeight.w700,
                    backgroundColor: NocheColors.litSentence,
                    decoration: underline ? TextDecoration.underline : null,
                    decorationColor: underline ? NocheColors.listening : null,
                    decorationThickness: underline ? 2 : null,
                  ),
                ),
                TextSpan(text: text.substring(at.end)),
              ],
            ),
      textAlign: TextAlign.center,
      textDirection: _lang.textDirection,
      locale: _lang.locale,
    );
  }

  /// (4) The reveal: a place of its own, as high as the sentence it will show, kept empty until the item is
  /// answered. Nothing round it moves when its content comes (no story-book screenshots under #10).
  Widget _revealArea(_GameSnap snap, _Reveal r, double textH) {
    final text = r.text;
    if (text == null) return const SizedBox.shrink();
    return SizedBox(
      height: textH,
      child: snap.showText
          ? OverflowBox(
              alignment: AlignmentDirectional.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: _litText(text, r.word),
            )
          : null,
    );
  }

  TileLook _look(_ChoiceSnap c) =>
      c.dim ? TileLook.dim : (c.pre ? TileLook.waiting : TileLook.normal);

  /// A picture of a picture game with the sign inside its bottom-end corner when it is the one to touch: 12 px from
  /// both edges, so that it never covers what the picture is about. Pictures stay unmirrored LTR.
  Widget _signed(Widget child, bool sign) => sign
      ? Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              PositionedDirectional(
                end: NocheTouchSign.pictureInset,
                bottom: NocheTouchSign.pictureInset,
                child: NocheTouchSign(still: _still),
              ),
            ],
          ),
        )
      : child;

  Widget _choicePicture(_GameSnap snap, int i, Widget picture) {
    final c = snap.choices[i];
    return _signed(
      OptionTouch(
        index: i,
        onTouch: session.touch,
        child: NochePictureChoice(
          ring: choiceRing(c.ring),
          dim: c.dim
              ? ChoiceDim.unchosen
              : (c.pre ? ChoiceDim.whileSentence : ChoiceDim.none),
          check: c.check,
          cross: c.cross,
          // a picture's frame is drawn inside its box: it is the same size marked or not
          inside: true,
          child: picture,
        ),
      ),
      c.sign,
    );
  }

  // ¿Cuál?: the word's two dedicated single-word pictures, one above the other, at the largest whole scale that fits.
  // Never falls back to ScenePictures story crops (#10).
  _Area _cual(
    BuildContext context,
    _GameSnap snap,
    CualItem it,
    double width,
    double budget,
    double dpr,
    NocheMotionData motion,
    int startIdx,
  ) {
    final asset = it.asset;
    if (asset == null || !asset.isUsable) {
      return const _Area(SizedBox.shrink(), 0);
    }
    final kw = (width * dpr / pictureWidth).floor();
    final kh = ((budget - _gap) / 2 * dpr / pictureHeight).floor();
    final k = math.max(1, math.min(kw, kh));
    final w = pictureWidth * k / dpr, h = pictureHeight * k / dpr;
    Widget pic(int i) {
      final c = snap.choices[i];
      final path = (c.right ? asset.yesAsset : asset.noAsset).trim();
      final picture = SizedBox(
        width: w,
        height: h,
        child: BookImage(
          provider: _book(path),
          k: k,
          placeholderWidth: pictureWidth,
          placeholderHeight: pictureHeight,
        ),
      );
      // each item's pictures are their own (a new picture is never an old one handed another pair)
      return NocheRiseIn(
        key: ValueKey('review_item_row_${startIdx + i}'),
        delay:
            ReviewMotion.itemRowsDelay +
            motion.stagger * math.min(startIdx + i, 4),
        child: KeyedSubtree(
          key: ValueKey((snap.entry, i)),
          child: _choicePicture(snap, i, picture),
        ),
      );
    }

    return _Area(
      Column(
        children: [
          if (snap.choices.length == 2) ...[
            pic(0),
            const SizedBox(height: _gap),
            pic(1),
          ],
        ],
      ),
      2 * h + _gap,
    );
  }

  // ¿Qué oyes?: three written tiles, each with its speaker when every tile has the word alone
  _Area _hear(
    _GameSnap snap,
    HearItem it,
    NocheMotionData motion,
    int startIdx,
  ) {
    final s = session;
    return _Area(
      Directionality(
        textDirection: _lang.textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var k = 0; k < snap.choices.length; k++) ...[
              if (k > 0) const SizedBox(height: _gap),
              NocheRiseIn(
                key: ValueKey('review_item_row_${startIdx + k}'),
                delay:
                    ReviewMotion.itemRowsDelay +
                    motion.stagger * math.min(startIdx + k, 4),
                child: NocheWordTile(
                  word: snap.choices[k].label,
                  language: _lang,
                  expand: true,
                  look: _look(snap.choices[k]),
                  ring: choiceRing(snap.choices[k].ring),
                  check: snap.choices[k].check,
                  cross: snap.choices[k].cross,
                  sign: snap.choices[k].sign,
                  still: _still,
                  onTap: () => s.touch(k),
                  onSpeaker: snap.choices[k].clip == null
                      ? null
                      : () => s.touchSpeaker(k),
                ),
              ),
            ],
          ],
        ),
      ),
      3 * 56.0 + 2 * _gap,
    );
  }

  /// How many rows of tiles Arma la frase's answer line has room for from the start: two, or more when the whole
  /// sentence with its check would take more at this width. It is known from the item before a tile is placed, so the
  /// line never grows and nothing under it moves.
  int _lineRows(BuildContext context, BuildItem it, double width) {
    final scaler = MediaQuery.textScalerOf(context);
    final tileStyle = _courseStyle(_tileTextStyle);
    double tileWidth(String word) {
      final tp = TextPainter(
        text: TextSpan(text: word, style: tileStyle),
        textDirection: _lang.textDirection,
        textScaler: scaler,
      )..layout();
      final w = tp.width + 2 * (16 + nocheLessonBorder);
      tp.dispose();
      return math.max(56.0, w);
    }

    var rows = 1;
    var used = 0.0;
    for (final w in [for (final x in it.order) tileWidth(x), nocheBadgeSize]) {
      if (used == 0) {
        used = w;
      } else if (used + 8 + w <= width + .01) {
        used += 8 + w;
      } else {
        rows++;
        used = w;
      }
    }
    return math.max(2, rows);
  }

  /// The height of a word tile at this text size: 56, or more when the word's line is taller than that.
  double _tileHeight(BuildContext context) {
    final tp = TextPainter(
      text: TextSpan(text: 'x', style: _courseStyle(_tileTextStyle)),
      textDirection: _lang.textDirection,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final h = tp.height + 24;
    tp.dispose();
    return math.max(56.0, h);
  }

  // Arma la frase: an empty line with a baseline (no places: its tiles go onto it one after another from start to end
  // in the course's reading direction, and are green at once), the tiles in their mixed order under it; a tile put on
  // the line leaves an empty place of its size in the bank
  _Area _build(
    BuildContext context,
    _GameSnap snap,
    BuildItem it,
    double width,
  ) {
    final s = session;
    final done = snap.showText;
    final rows = _lineRows(context, it, width);
    final tileH = _tileHeight(context);
    final line = NocheTileTray(
      key: const ValueKey('answer-line'),
      line: true,
      lineRows: rows,
      lineTileHeight: tileH,
      children: [
        for (final k in snap.placed)
          NocheWordTile(
            word: snap.choices[k].label,
            language: _lang,
            ring: choiceRing(snap.choices[k].ring),
            still: _still,
          ),
        SizedBox(
          key: const ValueKey('check-place'),
          width: nocheBadgeSize,
          height: nocheBadgeSize,
          child: done ? const NocheCheckBadge() : null,
        ),
      ],
    );
    return _Area(
      Directionality(
        textDirection: _lang.textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line,
            const SizedBox(height: 24),
            NocheTileTray(
              children: [
                for (var k = 0; k < snap.choices.length; k++)
                  NocheWordTile(
                    word: snap.choices[k].label,
                    language: _lang,
                    look: snap.choices[k].done
                        ? TileLook.empty
                        : _look(snap.choices[k]),
                    ring: choiceRing(snap.choices[k].ring),
                    cross: snap.choices[k].cross,
                    shake: snap.choices[k].shakes,
                    still: _still,
                    onTap: snap.choices[k].done ? null : () => s.touch(k),
                  ),
              ],
            ),
          ],
        ),
      ),
      NocheTileTray.lineHeight(rows, tileHeight: tileH) +
          24 +
          3 * 56.0 +
          2 * _gap,
    );
  }

  // Parejas: four sounds at the start, four words at the end; a found pair is green on both sides, with its number
  _Area _match(
    _GameSnap snap,
    MatchItem it,
    NocheMotionData motion,
    int startIdx,
  ) {
    final s = session;
    return _Area(
      Directionality(
        textDirection: _lang.textDirection,
        child: Column(
          children: [
            for (var i = 0; i < snap.speakers.length; i++) ...[
              if (i > 0) const SizedBox(height: _gap),
              NocheRiseIn(
                key: ValueKey('review_item_row_${startIdx + i}'),
                delay:
                    ReviewMotion.itemRowsDelay +
                    motion.stagger * math.min(startIdx + i, 4),
                child: Row(
                  children: [
                    NocheSpeakerTile(
                      onTap: snap.speakers[i].done
                          ? null
                          : () => s.touchSpeaker(i),
                      label: 'Sound ${i + 1}',
                      ring: choiceRing(snap.speakers[i].ring),
                      check: snap.speakers[i].check,
                      cross: snap.speakers[i].cross,
                      number: snap.speakers[i].number,
                      playing: snap.selectedSpeaker == i,
                      still: _still,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NocheWordTile(
                        word: snap.choices[i].label,
                        language: _lang,
                        expand: true,
                        ring: choiceRing(snap.choices[i].ring),
                        check: snap.choices[i].check,
                        cross: snap.choices[i].cross,
                        number: snap.choices[i].number,
                        shake: snap.choices[i].shakes,
                        still: _still,
                        onTap: snap.choices[i].done ? null : () => s.touch(i),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      4 * 56.0 + 3 * _gap,
    );
  }

  // ¿Dónde?: defensive guard against story-book screenshots (#10).
  _Area _where(
    BuildContext context,
    _GameSnap snap,
    WhereItem it,
    double width,
    double budget,
    double dpr,
  ) {
    if (snap.choices.isEmpty ||
        snap.choices.any((c) => !isDedicatedWordAssetPath(c.label))) {
      return const _Area(SizedBox.shrink(), 0);
    }
    final n = snap.choices.length;
    final k = math.max(
      1,
      whereScaleFor(n: n, width: width, height: budget, dpr: dpr),
    );
    return _Area(
      Column(
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(height: whereGap),
            KeyedSubtree(
              key: ValueKey((snap.entry, i)),
              child: _choicePicture(
                snap,
                i,
                BookImage(provider: _book(snap.choices[i].label), k: k),
              ),
            ),
          ],
        ],
      ),
      n * bookPictureHeight * k / dpr + (n - 1) * whereGap,
    );
  }

  // Dilo: the speaking prompt card (target word + sentence with target word highlighted), NocheMic, status, and heard.
  _Area _say(BuildContext context, _GameSnap snap, SayItem it, double width) {
    final s = session;
    final status = switch (snap.mic) {
      MicState.listening => RepasoStrings.listening,
      MicState.ready when snap.notHeard => RepasoStrings.tryAgain,
      _ => '',
    };
    final heardLine = (snap.notHeard || snap.heardRight)
        ? (snap.heard.isEmpty
              ? RepasoStrings.nothingHeard
              : RepasoStrings.heard(snap.heard))
        : '';
    Widget statusBox(String text) => SizedBox(
      height: 24,
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: NocheType.body.copyWith(color: NocheColors.lessonLabel),
        ),
      ),
    );
    Widget heardBox(String text, {Widget? lead, Color? color}) => SizedBox(
      height: 28,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 8)],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: NocheType.bodyLarge.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    const pillPadX = 12.0;
    const pillPadY = 4.0;
    const pillBorder = nocheLessonBorder;
    const calloutSpacing = 8.0;
    const calloutRunSpacing = 4.0;
    final innerW = math.max(0.0, width - 2 * (16 + nocheLessonBorder));
    final labelSize = _textSize(
      context,
      RepasoStrings.sayTargetWord,
      _sayLabelStyle,
      innerW,
    );
    final pillTextMaxW = math.max(0.0, innerW - 2 * (pillPadX + pillBorder));
    final pillStyle = _courseStyle(_sayPillStyle);
    final pillTextSize = _textSize(
      context,
      it.word,
      pillStyle,
      pillTextMaxW,
      textDirection: _lang.textDirection,
    );
    final pillW = pillTextSize.width + 2 * (pillPadX + pillBorder);
    final pillH = pillTextSize.height + 2 * (pillPadY + pillBorder);
    final fitsOneLine =
        labelSize.width + calloutSpacing + pillW <= innerW + 0.01;
    final calloutH = fitsOneLine
        ? math.max(labelSize.height, pillH)
        : labelSize.height + calloutRunSpacing + pillH;
    final sentenceH = _textH(
      context,
      it.line.text,
      _courseStyle(_saySentenceStyle),
      innerW,
      textDirection: _lang.textDirection,
    );
    final cardH = 2 * (16 + nocheLessonBorder) + calloutH + 12 + sentenceH;
    final micState = switch (snap.mic) {
      MicState.dead => NocheMicState.theySpeak,
      MicState.ready =>
        snap.notHeard ? NocheMicState.notYet : NocheMicState.ready,
      MicState.listening => NocheMicState.listening,
      MicState.processing => NocheMicState.thinking,
      MicState.ok => NocheMicState.right,
      MicState.missed => NocheMicState.notYet,
    };
    final micLevel =
        (snap.mic == MicState.listening ||
            (snap.mic == MicState.dead && snap.sentencePlaying))
        ? 0.6
        : 0.0;
    final micWordStyle = NocheType.forScript(
      NocheType.buttonStrong,
      _lang.script,
    );
    final micWordH =
        (micWordStyle.fontSize ?? 14) * (micWordStyle.height ?? 1.0);
    final micH = NocheMic.discSize + 12 + micWordH;
    return _Area(
      Column(
        children: [
          Container(
            key: const ValueKey('say-prompt'),
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
              color: NocheColors.lessonPanel,
              borderRadius: BorderRadius.circular(NocheSize.cardRadius),
              border: Border.all(
                color: NocheColors.lessonBorder,
                width: nocheLessonBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Wrap(
                  key: const ValueKey('say-target-word'),
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: calloutSpacing,
                  runSpacing: calloutRunSpacing,
                  children: [
                    Text(RepasoStrings.sayTargetWord, style: _sayLabelStyle),
                    Container(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: pillPadX,
                        vertical: pillPadY,
                      ),
                      decoration: BoxDecoration(
                        color: NocheColors.litSentence,
                        borderRadius: BorderRadius.circular(
                          NocheSize.chipRadius,
                        ),
                        border: Border.all(
                          color: NocheColors.listening,
                          width: pillBorder,
                        ),
                      ),
                      child: Text(
                        it.word,
                        textDirection: _lang.textDirection,
                        locale: _lang.locale,
                        style: pillStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: const ValueKey('say-sentence'),
                  child: _litText(
                    it.line.text,
                    it.word,
                    style: _saySentenceStyle,
                    underline: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          NocheMic(
            state: micState,
            language: _lang,
            level: micLevel,
            onPressed: snap.mic == MicState.ready ? s.pressMic : null,
            compactLabel: true,
            labelGap: 12,
          ),
          const SizedBox(height: 8),
          statusBox(status),
          heardBox(
            heardLine,
            color: snap.heardRight ? NocheColors.right : NocheColors.text,
            lead: snap.heardRight
                ? const NocheIcon(
                    NocheIcons.check,
                    size: 20,
                    strokeWidth: 3,
                    color: NocheColors.right,
                  )
                : null,
          ),
        ],
      ),
      cardH + 24 + micH + 8 + 24 + 28,
    );
  }
}

// ---- the end

/// The end of a session: "Done", how many of its scored words he got right the first time, and every one of them in
/// one of two lists, "Got it the first time" and "Coming back soon" ("Right" and "Missed" in a practice), each row
/// the word, the sentence it was asked in and its speaker; a touch on a row plays its sentence. The list scrolls above
/// the 56 px button (always there) and shows that it does: a scroll bar, and a fade at both ends.
class RepasoEndView extends StatefulWidget {
  const RepasoEndView({
    super.key,
    required this.box,
    required this.end,
    required this.onRow,
    this.language,
    this.controller,
    this.schedule,
  });

  final LessonBox box;
  final RepasoEnd end;
  final void Function(RepasoEndRow r) onRow;
  final Language? language;
  final ScrollController? controller;
  final ReviewEndSchedule? schedule;

  @override
  State<RepasoEndView> createState() => _RepasoEndViewState();
}

class _RepasoEndViewState extends State<RepasoEndView> {
  ScrollController? _own;
  ScrollController get _c => widget.controller ?? (_own ??= ScrollController());
  Language get _lang => widget.language ?? Language.spanish;

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  Widget _row(RepasoEndRow r, Duration wordStart) {
    final end = widget.end;
    final animateFrom = (r.ok && r.newStage > r.oldStage && end.stageMax > 0)
        ? (r.oldStage / end.stageMax).clamp(0.0, 1.0)
        : null;
    return NocheRiseIn(
      key: ValueKey('end_word_${r.word}'),
      delay: wordStart,
      child: Directionality(
        textDirection: _lang.textDirection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Pressable(
              onPressed: () => widget.onRow(r),
              semanticLabel: '${r.word}: ${r.text}',
              builder: (context, pressed) => Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: pressed ? NocheColors.lessonPanel : null,
                  borderRadius: BorderRadius.circular(NocheSize.tileRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.word,
                            textDirection: _lang.textDirection,
                            locale: _lang.locale,
                            style: NocheType.forScript(
                              NocheType.row,
                              _lang.script,
                            ).copyWith(color: NocheColors.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.text,
                            textDirection: _lang.textDirection,
                            locale: _lang.locale,
                            style: NocheType.forScript(
                              NocheType.bodyLarge,
                              _lang.script,
                            ).copyWith(color: NocheColors.label),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const NocheIcon(
                      NocheIcons.speaker,
                      size: 22,
                      color: NocheColors.lessonLabel,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: NocheStageBar(
                key: ValueKey('end_stage_bar_${r.word}'),
                stage: r.newStage,
                max: end.stageMax,
                animateFrom: animateFrom,
                delay: wordStart + ReviewMotion.stageBarDelay,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final end = widget.end;
    final timing =
        widget.schedule ??
        ReviewEndSchedule(NocheMotion.of(context), [
          for (final g in end.groups) g.rows.length,
        ]);
    return PositionedDirectional(
      start: 0,
      end: 0,
      top: 0,
      bottom: 96,
      child: FadingEdges(
        top: 16,
        bottom: 16,
        child: Scrollbar(
          controller: _c,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _c,
            padding: EdgeInsetsDirectional.fromSTEB(
              box.landscape ? 0 : 16,
              box.landscape ? 8 : 16,
              box.landscape ? 0 : 16,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: nocheLessonColumnMax,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NocheRiseIn(
                      key: const ValueKey('end_done_title'),
                      delay: timing.doneStart,
                      child: Text(
                        RepasoStrings.doneTitle,
                        style: NocheType.pageTitle.copyWith(
                          color: NocheColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    NocheRiseIn(
                      key: const ValueKey('end_summary'),
                      delay: timing.summaryStart,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: NocheLtr(
                          child: Text(
                            end.summary,
                            style: NocheType.bodyLarge.copyWith(
                              color: NocheColors.label,
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (var gi = 0; gi < end.groups.length; gi++) ...[
                      const SizedBox(height: 24),
                      NocheRiseIn(
                        key: ValueKey('end_group_header_$gi'),
                        delay: timing.groupHeaderStart[gi],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              end.groups[gi].title,
                              style: NocheType.row.copyWith(
                                color: NocheColors.text,
                              ),
                            ),
                            if (end.groups[gi].sub.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                end.groups[gi].sub,
                                style: NocheType.body.copyWith(
                                  color: NocheColors.label,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (var ri = 0; ri < end.groups[gi].rows.length; ri++)
                        _row(end.groups[gi].rows[ri], timing.wordStart[gi][ri]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
