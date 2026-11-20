/// Repaso as games on screen (docs/proyecto/15-repaso-juegos.md): the start, each game, the end. The session
/// (logic/repaso_session.dart) decides everything; this draws it and passes touches on.
///
/// The lesson frame as every lesson has it (page 09): calm dark grey, the close X, the dashes (one per word), the
/// sound button. Each game has its one English line at the top, and the "N in a row" chip beside it from three up.
/// What he must do next sits in the bottom third (the Next button; Dilo's mic).
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

class RepasoScreenState extends State<RepasoScreen> {
  late final RepasoSession session;
  HostWait? _host;
  final Map<String, Widget> _pairPictures = {};

  Services get _s => widget.services;

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

  // ---- the bottom zone

  double get _footRoom {
    final s = session;
    if (s.canNext) return 56 + 24 + 16;
    if (s.item is SayItem && !s.showText) return 72 + 16 + 48 + 24 + 16;
    return 24;
  }

  List<Widget> _bottom() {
    final s = session;
    if (s.canNext) {
      return [LessonButton(label: RepasoStrings.next, onPressed: s.pressNext)];
    }
    if (s.item is SayItem && !s.showText) {
      return [
        RepasoMic(state: s.mic, onPressed: s.pressMic, still: _still),
        LessonButton(
          kind: LessonButtonKind.outline,
          label: RepasoStrings.cantSpeak,
          onPressed: s.cantSpeak,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = LessonBox.of(context, constraints);
      final s = session;
      final start = s.screen == LessonScreen.start;
      final end = s.screen == LessonScreen.end;
      final play = s.screen == LessonScreen.play && s.item != null;
      return LessonFrame(
        onClose: _close,
        showClose: !end,
        showSound: !end,
        onSound: _toggleSound,
        muted: _s.clips.muted,
        progress: LessonProgressDashes(
          segments: s.barSegments,
          done: s.barLit,
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
                bottom: _footRoom,
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
          if (play) ..._bottom(),
        ],
        startState: start,
      );
    },
  );

  // ---- a game

  Widget _game(BuildContext context, LessonBox box) => LayoutBuilder(
    builder: (context, c) {
      final s = session;
      final it = s.item!;
      final side = box.landscape ? 0.0 : CoquiMetrics.s16;
      final width = math.min(
        CoquiMetrics.lessonColumnMax,
        c.maxWidth - 2 * side,
      );
      final room = Size(width, c.maxHeight - 16 - 40 - 16);
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(side, 16, side, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 32),
          child: Center(
            child: SizedBox(
              width: width,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          gameInstruction(it.kind),
                          style: CoquiText.lessonHint,
                        ),
                      ),
                      StreakChip(count: s.streak, from: repasoStreakFrom),
                    ],
                  ),
                  const SizedBox(height: CoquiMetrics.s24),
                  switch (it) {
                    CualItem() => _cual(context, it, room),
                    HearItem() => _hear(context, it, room),
                    BuildItem() => _build(context, it, room),
                    MatchItem() => _match(it),
                    WhereItem() => _where(context, it, room),
                    SayItem() => _say(context, it, room),
                  },
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  TileLook _look(Choice c) =>
      c.dim ? TileLook.dim : (c.pre ? TileLook.waiting : TileLook.normal);

  Widget _signed(Widget child, bool sign) => sign
      ? Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              left: 0,
              right: 0,
              top: -TouchSign.size / 2,
              child: Center(child: TouchSign(still: _still)),
            ),
          ],
        )
      : child;

  // ¿Cuál?: the word's two pictures, one above the other, at the largest whole scale that fits; its line under them
  Widget _cual(BuildContext context, CualItem it, Size room) {
    final s = session;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final kw = (room.width * dpr / pictureWidth).floor();
    final kh = ((room.height - 16 - 64) / 2 * dpr / pictureHeight).floor();
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
      return _signed(
        OptionTouch(
          index: i,
          onTouch: s.touch,
          child: PictureChoice(
            ring: choiceRing(c.ring),
            dim: c.dim
                ? ChoiceDim.unchosen
                : (c.pre ? ChoiceDim.whileSentence : ChoiceDim.none),
            check: c.check,
            child: picture,
          ),
        ),
        c.sign,
      );
    }

    return Column(
      children: [
        if (s.choices.length == 2) ...[
          pic(0),
          const SizedBox(height: CoquiMetrics.s16),
          pic(1),
        ],
        const SizedBox(height: CoquiMetrics.s8),
        SizedBox(
          height: 56,
          child: Text(
            s.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: CoquiText.lessonCaption,
          ),
        ),
      ],
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

  Widget _picture(
    BuildContext context,
    String? img,
    Size room, {
    double part = .4,
  }) {
    if (img == null) return const SizedBox.shrink();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final k = bookScale(aw: room.width, ah: room.height * part, dpr: dpr);
    return Center(
      child: PictureFrame(
        background: const Color(0x00000000),
        child: BookImage(provider: _book(img), k: k),
      ),
    );
  }

  // ¿Qué oyes?: three written tiles, each with its speaker when the word can be heard alone; after the answer, the
  // sentence written with the word lit, and its picture where the readers judged it shows it
  Widget _hear(BuildContext context, HearItem it, Size room) {
    final s = session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var k = 0; k < s.choices.length; k++) ...[
          if (k > 0) const SizedBox(height: CoquiMetrics.s12),
          WordTile(
            word: s.choices[k].label,
            expand: true,
            look: _look(s.choices[k]),
            ring: choiceRing(s.choices[k].ring),
            check: s.choices[k].check,
            sign: s.choices[k].sign,
            still: _still,
            onTap: () => s.touch(k),
            onSpeaker: s.choices[k].clip == null
                ? null
                : () => s.touchSpeaker(k),
          ),
        ],
        if (s.showText) ...[
          const SizedBox(height: CoquiMetrics.s24),
          _picture(context, it.sentence.picture, room, part: .35),
          if (it.sentence.picture != null)
            const SizedBox(height: CoquiMetrics.s16),
          _litText(it.text, it.word),
        ],
      ],
    );
  }

  Widget _again(VoidCallback onTap) => Center(
    child: SpeakerTile(onTap: onTap, label: 'Hear it again', still: _still),
  );

  // Arma la frase: hear it again; the sentence so far on its line; the tiles in their mixed order
  Widget _build(BuildContext context, BuildItem it, Size room) {
    final s = session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _picture(context, it.sentence.picture, room, part: .3),
        if (it.sentence.picture != null)
          const SizedBox(height: CoquiMetrics.s16),
        _again(() => s.touchSpeaker(0)),
        const SizedBox(height: CoquiMetrics.s16),
        TileTray(
          line: true,
          children: [
            for (final w in s.built)
              WordTile(
                word: w,
                ring: s.showText ? ChoiceRing.right : ChoiceRing.none,
              ),
          ],
        ),
        const SizedBox(height: CoquiMetrics.s24),
        TileTray(
          children: [
            for (var k = 0; k < s.choices.length; k++)
              Visibility(
                visible: !s.choices[k].done,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: WordTile(
                  word: s.choices[k].label,
                  look: _look(s.choices[k]),
                  shake: s.choices[k].shakes,
                  still: _still,
                  onTap: s.choices[k].done ? null : () => s.touch(k),
                ),
              ),
          ],
        ),
        if (s.showText) ...[
          const SizedBox(height: CoquiMetrics.s24),
          _litText(it.text, null),
        ],
      ],
    );
  }

  // Parejas: four sounds at the left, four words at the right; a found pair is green on both sides
  Widget _match(MatchItem it) {
    final s = session;
    return Column(
      children: [
        for (var i = 0; i < s.speakers.length; i++) ...[
          if (i > 0) const SizedBox(height: CoquiMetrics.s12),
          Row(
            children: [
              SpeakerTile(
                onTap: s.speakers[i].done ? null : () => s.touchSpeaker(i),
                label: 'Sound ${i + 1}',
                ring: choiceRing(s.speakers[i].ring),
                check: s.speakers[i].check,
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
                  shake: s.choices[i].shakes,
                  still: _still,
                  onTap: s.choices[i].done ? null : () => s.touch(i),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ¿Dónde?: two or three pictures of the story, the same size; after the answer, the sentence written
  Widget _where(BuildContext context, WhereItem it, Size room) {
    final s = session;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final n = s.choices.length;
    // the pictures as big as they can be at one whole scale: in one, two or three columns, whichever gives the
    // largest (a tie: more to a row); the room less the speaker above and a line of text under
    final h = room.height - 56 - CoquiMetrics.s24 - 64;
    var k = 0;
    for (var cols = 1; cols <= n; cols++) {
      final rows = (n / cols).ceil();
      final kk = bookScale(
        aw: (room.width - (cols - 1) * CoquiMetrics.s16) / cols,
        ah: (h - (rows - 1) * CoquiMetrics.s16) / rows,
        dpr: dpr,
      );
      if (kk >= k) k = kk;
    }
    Widget pic(int i) {
      final c = s.choices[i];
      return _signed(
        OptionTouch(
          index: i,
          onTouch: s.touch,
          child: PictureChoice(
            ring: choiceRing(c.ring),
            dim: c.dim
                ? ChoiceDim.unchosen
                : (c.pre ? ChoiceDim.whileSentence : ChoiceDim.none),
            check: c.check,
            child: BookImage(provider: _book(c.label), k: k),
          ),
        ),
        c.sign,
      );
    }

    return Column(
      children: [
        _again(() => s.touchSpeaker(0)),
        const SizedBox(height: CoquiMetrics.s24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: CoquiMetrics.s16,
          runSpacing: CoquiMetrics.s16,
          children: [for (var i = 0; i < n; i++) pic(i)],
        ),
        if (s.showText) ...[
          const SizedBox(height: CoquiMetrics.s24),
          _litText(it.text, null),
        ],
      ],
    );
  }

  // Dilo: the moment's picture, the line before it to hear again, what the app heard
  Widget _say(BuildContext context, SayItem it, Size room) {
    final s = session;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _picture(context, it.line.picture, room, part: .45),
        if (it.line.picture != null) const SizedBox(height: CoquiMetrics.s16),
        _again(() => s.touchSpeaker(0)),
        const SizedBox(height: CoquiMetrics.s24),
        if (s.heard.isNotEmpty || s.mic == MicState.ok)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (s.heardRight) ...[
                const CoquiIcon(
                  CoquiIcons.check,
                  size: 24,
                  color: CoquiColors.bookLineLitBar,
                ),
                const SizedBox(width: CoquiMetrics.s8),
              ],
              Flexible(
                child: Text(
                  s.heard,
                  textAlign: TextAlign.center,
                  style: CoquiText.lessonBody.copyWith(
                    color: s.heardRight
                        ? CoquiColors.heard
                        : CoquiColors.lessonInk2,
                  ),
                ),
              ),
            ],
          ),
        if (s.showText) ...[
          const SizedBox(height: CoquiMetrics.s16),
          _litText(it.line.text, it.word),
        ],
      ],
    );
  }
}

// ---- Dilo's mic

const Color _micGrey = Color(0xFF2B2B33), _micGreyIcon = Color(0xFFA7A7B0);
const Color _micCoral = Color(0xFFFF5A5F), _micCoralInk = Color(0xFF2B0A0C);

/// Dilo's mic: the 72 px disc of a speaking turn (index.html `#mic`, as feature_story's and the call's draw it; a local
/// stand-in, as theirs are). Dead grey while a line plays; ready green with a white mic; listening coral with a ring;
/// processing grey with three dots; heard right an outline with a green tick. Only a ready mic takes a tap.
class RepasoMic extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
    return Pressable(
      onPressed: state == MicState.ready ? onPressed : null,
      semanticLabel: 'Microphone',
      builder: (context, pressed) => Container(
        width: CoquiMetrics.startDisc,
        height: CoquiMetrics.startDisc,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: ring == null ? null : Border.all(color: ring, width: 3),
          boxShadow: state == MicState.listening
              ? [
                  BoxShadow(
                    color: _micCoral.withValues(alpha: .35),
                    spreadRadius: 6,
                  ),
                ]
              : null,
        ),
        child: icon,
      ),
    );
  }
}

// ---- the end

/// The end of a session: "Done", how many he got right the first time, and each word with the sentence it was asked
/// in under "Moving up" and "Coming back soon" ("Right" and "Missed" in a practice); a touch on a row plays its
/// sentence. The list scrolls above the 56 px button and fades at both ends, as the old end does.
class RepasoEndView extends StatelessWidget {
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

  Widget _row(RepasoEndRow r) => Pressable(
    onPressed: () => onRow(r),
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
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    top: 0,
    bottom: 96,
    child: FadingEdges(
      top: 16,
      bottom: 16,
      child: SingleChildScrollView(
        controller: controller,
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
  );
}
