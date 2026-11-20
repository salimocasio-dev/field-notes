/// Repaso as games on screen (docs/proyecto/15-repaso-juegos.md): the start, each game, the end. The session
/// (logic/repaso_session.dart) decides everything; this draws it and passes touches on.
///
/// The lesson frame as every lesson has it (page 09): calm dark grey, the close X, the dashes (one for each item of
/// the session), the sound button. Each game has one fixed layout from the moment it is asked, and nothing moves
/// when he touches: (1) the English line saying what to do, and the place of the "N in a row" chip (kept whether it
/// shows or not); (2) the round speaker, the same size and place in every game that plays a sentence; (3) the game's
/// own area; (4) the reveal, a place of its own where the sentence (and its story picture) appears after the answer;
/// (5) the Next button's place at the bottom, empty until Next shows. The content starts under the top bar.
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
    show ReviewOptions;
import 'package:feature_review/src/ui/block_layout.dart'
    show pictureHeight, pictureWidth;
import 'package:feature_review/src/ui/book_image.dart';
import 'package:feature_review/src/ui/host_wait.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
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
    this.wait,
    this.endScroll,
  });

  final Services services;
  final RepasoData data;
  final BookImageUrl imageUrl;
  final BookImageProvider imageProvider;
  final ReviewOptions options;

  /// The host's wait. Left out, a timer is used; tests give a virtual clock's.
  final Wait? wait;
  final ScrollController? endScroll;

  @override
  State<RepasoScreen> createState() => RepasoScreenState();
}

/// What the reveal shows once an item is answered: its sentence (with [word] lit), and its story picture.
class _Reveal {
  const _Reveal(this.text, this.word, this.picture);
  final String? text;
  final String? word;
  final String? picture;
}

/// A game's own area and the height it takes.
class _Area {
  const _Area(this.child, this.height);
  final Widget child;
  final double height;
}

class RepasoScreenState extends State<RepasoScreen> {
  late final RepasoSession session;
  HostWait? _host;
  final Map<String, Widget> _pairPictures = {};

  Services get _s => widget.services;

  // the one layout of a game: a gap between its blocks, and what stays under it
  static const double _gap = CoquiMetrics.s12;
  static const double _topPad = CoquiMetrics.s8;
  static const double _bottomPad = CoquiMetrics.s16;

  /// The Next button's place: 56 px high, 24 under it and 16 above it. It is the same whether Next shows or not.
  static const double _foot = 56 + 24 + 16;

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
      warm: (refs) => unawaited(_s.pictures.warm(refs)),
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

  /// The green disc pressed, for a test or a tool that cannot reach it by touch.
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
      button = LessonButton(label: RepasoStrings.next, onPressed: s.pressNext);
    } else if (s.item is SayItem && !s.showText) {
      // "Can't speak now" stands where Next will: the one button of the bottom of the screen
      button = Align(
        child: LessonButton(
          kind: LessonButtonKind.outline,
          label: RepasoStrings.cantSpeak,
          onPressed: s.cantSpeak,
        ),
      );
    }
    return SizedBox(
      key: const ValueKey('next-slot'),
      width: double.infinity,
      height: 56,
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
      // before the first item is asked: how many pictures a ¿Dónde? item can have on this screen
      s.wherePictures = _wherePlan(context, box, constraints).count;
      return LessonFrame(
        onClose: _close,
        showClose: !end,
        showSound: !end,
        onSound: _toggleSound,
        muted: _s.clips.muted,
        progress: LessonProgressDashes(
          segments: s.barSegments,
          done: s.barLit,
          missed: s.barMissed,
          dense: s.barSegments > 24,
        ),
        overlay: start
            ? LessonTextScreen(
                box: box,
                title: s.screenTitle,
                lines: s.screenLines,
              )
            : end
            ? RepasoEndView(
                box: box,
                end: s.end!,
                onRow: s.playRow,
                controller: widget.endScroll,
              )
            : play
            ? Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: _foot,
                child: _game(context, box),
              )
            : null,
        bottom: [
          if (start) LessonStartButton(onPressed: _start),
          if (end)
            LessonButton(
              label: 'Back to ${CoquiLabels.words}',
              onPressed: () {
                s.leave();
                _s.nav.go(const TabRoute('words'));
              },
            ),
          if (play) _next(),
        ],
        startState: start,
      );
    },
  );

  // ---- the arithmetic

  double _width(LessonBox box, BoxConstraints c) {
    final side = box.landscape ? 0.0 : CoquiMetrics.s16;
    return math.min(CoquiMetrics.lessonColumnMax, c.maxWidth - 2 * side);
  }

  double _textH(BuildContext context, String text, TextStyle style, double w) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: w);
    final h = tp.height;
    tp.dispose();
    return h;
  }

  /// The line that says what to do, with the chip's place at its right: as high as the tallest of the six lines, so that
  /// what stands under it (the round speaker) is in the same place in every game.
  double _headerH(BuildContext context, GameKind kind, double width) => [
    StreakChip.height,
    for (final k in GameKind.values)
      _textH(
        context,
        gameInstruction(k),
        CoquiText.lessonHint,
        width - StreakChip.reservedWidth - CoquiMetrics.s12,
      ),
  ].reduce(math.max);

  bool _hasRound(GameItem it) => it is! MatchItem;

  /// What stands above the game's own area: the top, the line and its chip, the round speaker.
  double _above(BuildContext context, GameItem it, double width) =>
      _topPad +
      _headerH(context, it.kind, width) +
      _gap +
      (_hasRound(it) ? RoundSpeaker.size + _gap : 0);

  _Reveal _reveal(GameItem it) => switch (it) {
    CualItem() => _Reveal(it.text, it.word, null),
    HearItem() => _Reveal(it.text, it.word, it.sentence.picture),
    BuildItem() => _Reveal(it.text, null, it.sentence.picture),
    MatchItem() => const _Reveal(null, null, null),
    WhereItem() => _Reveal(it.text, null, null),
    SayItem() => _Reveal(it.line.text, it.word, it.line.picture),
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
        RoundSpeaker.size +
        _gap;
    final text = 3 * _textH(context, 'x', CoquiText.bookLine, width);
    final room = box.mainHeight - _foot - above - _gap - text - _bottomPad;
    return planWhere(available: 3, width: width, height: room, dpr: dpr);
  }

  // ---- a game

  Widget _game(BuildContext context, LessonBox box) => LayoutBuilder(
    builder: (context, c) {
      final s = session;
      final it = s.item!;
      final side = box.landscape ? 0.0 : CoquiMetrics.s16;
      final width = _width(box, c);
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final reveal = _reveal(it);
      final textH = reveal.text == null
          ? 0.0
          : _textH(context, reveal.text!, CoquiText.bookLine, width);
      final above = _above(context, it, width);
      // the game's own area gets what is left when the reveal has its text
      final budget = c.maxHeight - above - _gap - textH - _bottomPad;
      final area = switch (it) {
        CualItem() => _cual(context, it, width, budget, dpr),
        HearItem() => _hear(it),
        BuildItem() => _build(it),
        MatchItem() => _match(it),
        WhereItem() => _where(context, it, width, budget, dpr),
        SayItem() => _say(it),
      };
      // the reveal's picture gets what is left under the game's area
      final left = c.maxHeight - above - area.height - 2 * _gap - _bottomPad;
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(side, _topPad, side, _bottomPad),
        child: Center(
          child: SizedBox(
            width: width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // (1) the line saying what to do, and the chip's place
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        gameInstruction(it.kind),
                        style: CoquiText.lessonHint,
                      ),
                    ),
                    const SizedBox(width: CoquiMetrics.s12),
                    StreakChip(
                      count: s.streak,
                      from: repasoStreakFrom,
                      reserve: true,
                    ),
                  ],
                ),
                const SizedBox(height: _gap),
                // (2) the round speaker
                if (_hasRound(it)) ...[
                  _speaker(it),
                  const SizedBox(height: _gap),
                ],
                // (3) the game's own area
                area.child,
                const SizedBox(height: _gap),
                // (4) the reveal
                KeyedSubtree(
                  key: const ValueKey('reveal'),
                  child: _revealArea(
                    context,
                    it,
                    reveal,
                    width,
                    textH,
                    left,
                    dpr,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _speaker(GameItem it) {
    const room = RoundSpeaker.size + 2 * RoundSpeaker.pulse;
    return SizedBox(
      height: RoundSpeaker.size,
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: room,
        maxHeight: room,
        child: RoundSpeaker(
          onTap: session.replay,
          playing: session.sentencePlaying,
          still: _still,
        ),
      ),
    );
  }

  /// The sentence written out, the word lit (the book's lit line colours).
  Widget _litText(String text, String? word) {
    final at = word == null ? null : findWord(text, word);
    final style = CoquiText.bookLine;
    return Text.rich(
      at == null
          ? TextSpan(text: text, style: style)
          : TextSpan(
              style: style,
              children: [
                TextSpan(text: text.substring(0, at.start)),
                TextSpan(
                  text: text.substring(at.start, at.end),
                  style: style.copyWith(
                    fontWeight: FontWeight.w700,
                    backgroundColor: CoquiColors.bookLineLit,
                  ),
                ),
                TextSpan(text: text.substring(at.end)),
              ],
            ),
      textAlign: TextAlign.center,
    );
  }

  /// (4) The reveal: a place of its own, as high as what it will show (the story picture where there is one, the
  /// sentence), kept empty until the item is answered. Nothing round it moves when its content comes.
  Widget _revealArea(
    BuildContext context,
    GameItem it,
    _Reveal r,
    double width,
    double textH,
    double left,
    double dpr,
  ) {
    final text = r.text;
    if (text == null) return const SizedBox.shrink();
    final img = r.picture;
    var k = 1;
    var picH = 0.0;
    if (img != null) {
      k = bookScale(aw: width, ah: left - textH - _gap, dpr: dpr);
      picH = bookPictureHeight * k / dpr;
    }
    final height = (img == null ? 0.0 : picH + _gap) + textH;
    return SizedBox(
      height: height,
      child: session.showText
          ? OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (img != null) ...[
                    PictureFrame(
                      background: const Color(0x00000000),
                      child: BookImage(provider: _book(img), k: k),
                    ),
                    const SizedBox(height: _gap),
                  ],
                  _litText(text, r.word),
                ],
              ),
            )
          : null,
    );
  }

  TileLook _look(Choice c) =>
      c.dim ? TileLook.dim : (c.pre ? TileLook.waiting : TileLook.normal);

  /// A picture or tile of a picture game with the sign over its middle when it is the one to touch.
  Widget _signed(Widget child, bool sign) => sign
      ? Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            child,
            TouchSign(still: _still),
          ],
        )
      : child;

  Widget _choicePicture(int i, Widget picture) {
    final c = session.choices[i];
    return _signed(
      OptionTouch(
        index: i,
        onTouch: session.touch,
        child: PictureChoice(
          ring: choiceRing(c.ring),
          dim: c.dim
              ? ChoiceDim.unchosen
              : (c.pre ? ChoiceDim.whileSentence : ChoiceDim.none),
          check: c.check,
          cross: c.cross,
          child: picture,
        ),
      ),
      c.sign,
    );
  }

  // ¿Cuál?: the word's two pictures, one above the other, at the largest whole scale that fits
  _Area _cual(
    BuildContext context,
    CualItem it,
    double width,
    double budget,
    double dpr,
  ) {
    final s = session;
    final kw = (width * dpr / pictureWidth).floor();
    final kh = ((budget - _gap) / 2 * dpr / pictureHeight).floor();
    final k = math.max(1, math.min(kw, kh));
    final w = pictureWidth * k / dpr, h = pictureHeight * k / dpr;
    Widget pic(int i) {
      final c = s.choices[i];
      final side = c.right ? it.pair.yes : it.pair.no;
      final ref = PictureRef.of(it.pair, side);
      final picture = _pairPictures['${ref.name}|$k'] ??= SizedBox(
        width: w,
        height: h,
        child: _s.pictures.of(ref, animated: true),
      );
      // each item's pictures are their own (a new picture is never an old one handed another pair)
      return KeyedSubtree(
        key: ValueKey((s.entry, i)),
        child: _choicePicture(i, picture),
      );
    }

    return _Area(
      Column(
        children: [
          if (s.choices.length == 2) ...[
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
  _Area _hear(HearItem it) {
    final s = session;
    return _Area(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var k = 0; k < s.choices.length; k++) ...[
            if (k > 0) const SizedBox(height: _gap),
            WordTile(
              word: s.choices[k].label,
              expand: true,
              look: _look(s.choices[k]),
              ring: choiceRing(s.choices[k].ring),
              check: s.choices[k].check,
              cross: s.choices[k].cross,
              sign: s.choices[k].sign,
              still: _still,
              onTap: () => s.touch(k),
              onSpeaker: s.choices[k].clip == null
                  ? null
                  : () => s.touchSpeaker(k),
            ),
          ],
        ],
      ),
      3 * 56.0 + 2 * _gap,
    );
  }

  // Arma la frase: the sentence's places on their line (empty slots, then the tiles put in them), the tiles in their
  // mixed order under it; a tile put in the sentence leaves an empty slot of its size in the bank
  _Area _build(BuildItem it) {
    final s = session;
    final done = s.showText;
    final line = Stack(
      clipBehavior: Clip.none,
      children: [
        TileTray(
          line: true,
          children: [
            for (var i = 0; i < it.order.length; i++)
              if (s.slots.length > i && s.slots[i] != null)
                WordTile(
                  word: s.choices[s.slots[i]!].label,
                  ring: done ? ChoiceRing.right : ChoiceRing.none,
                  still: _still,
                  onTap: done ? null : () => s.touch(s.slots[i]!),
                )
              else
                WordTile(word: it.order[i], look: TileLook.empty),
          ],
        ),
        // the sentence is whole: a check badge at the end of the line
        if (done) const Positioned(right: -6, top: -10, child: CheckBadge()),
      ],
    );
    return _Area(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line,
          const SizedBox(height: CoquiMetrics.s24),
          TileTray(
            children: [
              for (var k = 0; k < s.choices.length; k++)
                WordTile(
                  word: s.choices[k].label,
                  look: s.choices[k].done
                      ? TileLook.empty
                      : _look(s.choices[k]),
                  ring: choiceRing(s.choices[k].ring),
                  shake: s.choices[k].shakes,
                  still: _still,
                  onTap: s.choices[k].done ? null : () => s.touch(k),
                ),
            ],
          ),
        ],
      ),
      2 * 56.0 + _gap + 16 + CoquiMetrics.s24 + 3 * 56.0 + 2 * _gap,
    );
  }

  // Parejas: four sounds at the left, four words at the right; a found pair is green on both sides, with its number
  _Area _match(MatchItem it) {
    final s = session;
    return _Area(
      Column(
        children: [
          for (var i = 0; i < s.speakers.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            Row(
              children: [
                SpeakerTile(
                  onTap: s.speakers[i].done ? null : () => s.touchSpeaker(i),
                  label: 'Sound ${i + 1}',
                  ring: choiceRing(s.speakers[i].ring),
                  check: s.speakers[i].check,
                  cross: s.speakers[i].cross,
                  number: s.speakers[i].number,
                  playing: s.selectedSpeaker == i,
                  still: _still,
                ),
                const SizedBox(width: CoquiMetrics.s16),
                Expanded(
                  child: WordTile(
                    word: s.choices[i].label,
                    expand: true,
                    ring: choiceRing(s.choices[i].ring),
                    check: s.choices[i].check,
                    cross: s.choices[i].cross,
                    number: s.choices[i].number,
                    shake: s.choices[i].shakes,
                    still: _still,
                    onTap: s.choices[i].done ? null : () => s.touch(i),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      4 * 56.0 + 3 * _gap,
    );
  }

  // ¿Dónde?: two or three pictures of the story, one above another, the same size
  _Area _where(
    BuildContext context,
    WhereItem it,
    double width,
    double budget,
    double dpr,
  ) {
    final s = session;
    final n = s.choices.length;
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
              key: ValueKey((s.entry, i)),
              child: _choicePicture(
                i,
                BookImage(provider: _book(s.choices[i].label), k: k),
              ),
            ),
          ],
        ],
      ),
      n * bookPictureHeight * k / dpr + (n - 1) * whereGap,
    );
  }

  // Dilo: the mic with its ring while the app listens, the line under it, and what was heard
  _Area _say(SayItem it) {
    final s = session;
    final status = switch (s.mic) {
      MicState.listening => RepasoStrings.listening,
      MicState.ready when s.notHeard => RepasoStrings.tryAgain,
      _ => '',
    };
    final heardLine = (s.notHeard || s.heardRight)
        ? (s.heard.isEmpty
              ? RepasoStrings.nothingHeard
              : RepasoStrings.heard(s.heard))
        : '';
    Widget line(String text, {Widget? lead, Color? color}) => SizedBox(
      height: 28,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (lead != null) ...[lead, const SizedBox(width: CoquiMetrics.s8)],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CoquiText.lessonCaption.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
    return _Area(
      Column(
        children: [
          // room for the mic's ring to pulse without touching the speaker above it
          const SizedBox(height: CoquiMetrics.s16),
          SizedBox(
            height: CoquiMetrics.startDisc,
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: CoquiMetrics.startDisc * 2,
              maxHeight: CoquiMetrics.startDisc * 2,
              child: RepasoMic(
                state: s.mic,
                onPressed: s.pressMic,
                still: _still,
              ),
            ),
          ),
          const SizedBox(height: CoquiMetrics.s8),
          line(status, color: CoquiColors.lessonInk2),
          line(
            heardLine,
            color: s.heardRight ? CoquiColors.heard : CoquiColors.lessonInk,
            lead: s.heardRight
                ? const CoquiIcon(
                    CoquiIcons.check,
                    size: 24,
                    color: CoquiColors.bookLineLitBar,
                  )
                : null,
          ),
        ],
      ),
      CoquiMetrics.s16 + CoquiMetrics.startDisc + CoquiMetrics.s8 + 56,
    );
  }
}

// ---- Dilo's mic

const Color _micGrey = Color(0xFF2B2B33), _micGreyIcon = Color(0xFFA7A7B0);
const Color _micCoral = Color(0xFFFF5A5F), _micCoralInk = Color(0xFF2B0A0C);

/// Dilo's mic: the 72 px disc of a speaking turn (index.html `#mic`, as feature_story's and the call's draw it; a local
/// stand-in, as theirs are). Dead grey while a line plays; ready green with a white mic; listening coral with a ring
/// that pulses; processing grey with three dots; heard right an outline with a green tick. Only a ready mic takes a
/// tap. The pulse goes out past the disc (give it room); with reduced motion it is a still ring.
class RepasoMic extends StatefulWidget {
  const RepasoMic({
    super.key,
    required this.state,
    required this.onPressed,
    this.still = false,
  });

  final MicState state;
  final VoidCallback onPressed;
  final bool still;

  @override
  State<RepasoMic> createState() => _RepasoMicState();
}

class _RepasoMicState extends State<RepasoMic>
    with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool get _calm =>
      widget.still || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RepasoMic old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.state == MicState.listening && !_calm) {
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
    final state = widget.state;
    final (fill, ink, ring) = switch (state) {
      MicState.dead => (_micGrey, _micGreyIcon, null),
      MicState.ready => (CoquiColors.lessonGreen, CoquiColors.lessonInk, null),
      MicState.listening => (_micCoral, _micCoralInk, _micCoral),
      MicState.processing => (_micGrey, _micGreyIcon, null),
      MicState.ok => (
        const Color(0x00000000),
        CoquiColors.bookLineLitBar,
        CoquiColors.lessonLine,
      ),
    };
    final Widget icon = switch (state) {
      MicState.processing => Text(
        '• • •',
        style: CoquiText.lessonH2.copyWith(color: _micGreyIcon),
      ),
      MicState.ok => const CoquiIcon(
        CoquiIcons.check,
        size: 36,
        color: CoquiColors.bookLineLitBar,
      ),
      _ => CoquiIcon(CoquiIcons.lessonMic, size: 32, color: ink),
    };
    final disc = Pressable(
      onPressed: state == MicState.ready ? widget.onPressed : null,
      semanticLabel: 'Microphone',
      builder: (context, pressed) => Container(
        width: CoquiMetrics.startDisc,
        height: CoquiMetrics.startDisc,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: ring == null ? null : Border.all(color: ring, width: 3),
        ),
        child: icon,
      ),
    );
    if (state != MicState.listening) return disc;
    // the ring grows out past the disc without the widget's size changing: it is as big as the disc all the time
    return SizedBox(
      width: CoquiMetrics.startDisc,
      height: CoquiMetrics.startDisc,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: OverflowBox(
                minWidth: 0,
                minHeight: 0,
                maxWidth: 2 * CoquiMetrics.startDisc,
                maxHeight: 2 * CoquiMetrics.startDisc,
                child: AnimatedBuilder(
                  animation: _a,
                  builder: (context, _) {
                    final t = _calm ? .5 : _a.value;
                    final d = CoquiMetrics.startDisc * (1 + .45 * t);
                    return Container(
                      key: const ValueKey('mic-pulse'),
                      width: d,
                      height: d,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _micCoral.withValues(alpha: .8 * (1 - t)),
                          width: 4,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          disc,
        ],
      ),
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
    this.controller,
  });

  final LessonBox box;
  final RepasoEnd end;
  final void Function(RepasoEndRow r) onRow;
  final ScrollController? controller;

  @override
  State<RepasoEndView> createState() => _RepasoEndViewState();
}

class _RepasoEndViewState extends State<RepasoEndView> {
  ScrollController? _own;
  ScrollController get _c => widget.controller ?? (_own ??= ScrollController());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  Widget _row(RepasoEndRow r) => Pressable(
    onPressed: () => widget.onRow(r),
    semanticLabel: '${r.word}: ${r.text}',
    builder: (context, pressed) => Container(
      constraints: const BoxConstraints(minHeight: CoquiMetrics.rowMin),
      padding: const EdgeInsets.symmetric(
        horizontal: CoquiMetrics.s12,
        vertical: CoquiMetrics.s8,
      ),
      decoration: BoxDecoration(
        color: pressed ? CoquiColors.bookLinePressed : null,
        borderRadius: BorderRadius.circular(CoquiMetrics.radiusButton),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.word, style: CoquiText.lessonH2),
                const SizedBox(height: 2),
                Text(r.text, style: CoquiText.lessonBody),
              ],
            ),
          ),
          const SizedBox(width: CoquiMetrics.s8),
          const CoquiIcon(
            CoquiIcons.lessonSound,
            size: 24,
            color: CoquiColors.bookSpeaker,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    final end = widget.end;
    return Positioned(
      left: 0,
      right: 0,
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
            padding: EdgeInsets.fromLTRB(
              box.landscape ? 0 : 16,
              box.landscape ? 8 : 16,
              box.landscape ? 0 : 16,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: CoquiMetrics.lessonColumnMax,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(RepasoStrings.doneTitle, style: CoquiText.lessonH1),
                    const SizedBox(height: 8),
                    Text(end.summary, style: CoquiText.lessonBody),
                    for (final g in end.groups) ...[
                      const SizedBox(height: 24),
                      Text(g.title, style: CoquiText.lessonH2),
                      if (g.sub.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(g.sub, style: CoquiText.lessonSub),
                      ],
                      const SizedBox(height: 8),
                      for (final r in g.rows) _row(r),
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
