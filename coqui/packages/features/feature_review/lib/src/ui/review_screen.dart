/// Repaso (¿Cuál?) on screen: cual.html, built from coqui_ui. The session (logic/review_session.dart) decides
/// everything; this draws it and passes touches on.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:feature_review/src/ui/host_wait.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
import 'package:material_ui/material_ui.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.services,
    this.options = const ReviewOptions(),
    this.captions = CaptionMode.during,
    this.wait,
    this.endScroll,
  });

  final Services services;
  final ReviewOptions options;

  /// The end screen's list, for a dev entry or a test that scrolls it.
  final ScrollController? endScroll;
  final CaptionMode captions;

  /// The host's wait. Left out, a timer is used; tests and the dev entry give a virtual clock's.
  final Wait? wait;

  @override
  State<ReviewScreen> createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> {
  late final ReviewSession session;
  HostWait? _host;
  final Expando<Widget> _pictures = Expando<Widget>();

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    final wait = widget.wait ?? (_host = HostWait()).call;
    session = ReviewSession(
      rng: _s.rng,
      clock: _s.clock,
      course: _s.course,
      progress: _s.progress,
      clips: _s.clips,
      wait: wait,
      captions: widget.captions,
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

  // the green disc: the first tap of the lesson wakes the audio (`ac().resume()`), then the session runs
  void _start() {
    if (session.screen != LessonScreen.start) return;
    unawaited(_s.clips.unlock());
    unawaited(session.run());
  }

  /// The green disc pressed, for a dev entry or a test that cannot reach it by touch.
  Future<void> pressStart() async => _start();

  // `#close`: all sound stops, back to Palabras (cual.js: SALIDA)
  void _close() {
    session.leave();
    _s.nav.go(const TabRoute('words'));
  }

  // `#snd`
  void _toggleSound() => setState(() => _s.clips.muted = !_s.clips.muted);

  // `#next`: "Back to Palabras"
  void _back() {
    session.leave();
    _s.nav.go(const TabRoute('words'));
  }

  ChoiceDim _dim(ReviewPanel p) => p.dim
      ? ChoiceDim.unchosen
      : (p.pre ? ChoiceDim.whileSentence : ChoiceDim.none);

  Widget _picture(ReviewPanel p, CellRect r) => _pictures[p] ??= SizedBox(
    width: r.width,
    height: r.height,
    child: _s.pictures.of(p.ref, animated: true),
  );

  Widget _choices(LessonBox box) {
    final s = session;
    final panels = s.panels!;
    return PictureBlock(
      fit: box.fit(BlockSpec.review),
      cell: (context, k, r) => OptionTouch(
        index: k,
        onTouch: s.touch,
        child: PictureChoice(
          ring: choiceRing(s.rings[k]),
          dim: _dim(panels[k]),
          check: s.checks[k],
          child: _picture(panels[k], r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final box = LessonBox.of(context, constraints);
      final s = session;
      final start = s.screen == LessonScreen.start;
      final end = s.screen == LessonScreen.end;
      final showPictures = s.screen == LessonScreen.play && s.panels != null;
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
        picture: showPictures ? _choices(box) : null,
        caption: showPictures && s.caption.isNotEmpty ? s.caption : null,
        language: _s.course.language,
        overlay: start
            ? LessonTextScreen(
                box: box,
                title: s.screenTitle,
                lines: s.screenLines,
              )
            : end
            ? ReviewEndScreen(
                box: box,
                end: s.end!,
                pictures: _s.pictures,
                language: _s.course.language,
                controller: widget.endScroll,
              )
            : null,
        bottom: [
          if (start) LessonStartButton(onPressed: _start),
          if (end)
            LessonButton(
              label:
                  'Back to ${_s.course.language.tabNames['words'] ?? CoquiLabels.words}',
              onPressed: _back,
            ),
        ],
        startState: start,
      );
    },
  );
}

/// `#fin.lis`: the end of a Repaso: the title, a summary line, and the session's words with their pictures under two
/// headings, each with a grey line; one block as wide as the grid, centred; the list scrolls in the space above the
/// 56 px button and fades out at both ends (cual.html:40-44; cual.js: cualGrupo, cualGrid).
class ReviewEndScreen extends StatelessWidget {
  const ReviewEndScreen({
    super.key,
    required this.box,
    required this.end,
    required this.pictures,
    this.language,
    this.controller,
  });

  final ScrollController? controller;

  final LessonBox box;
  final ReviewEnd end;
  final PictureSource pictures;
  final Language? language;

  Language get _lang => language ?? Language.spanish;

  Widget _cell(ReviewPair pair, EndGrid grid) => SizedBox(
    width: grid.cellWidth,
    child: Directionality(
      textDirection: _lang.textDirection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(color: CoquiColors.lessonLine, spreadRadius: 1.5),
              ],
            ),
            child: SizedBox(
              width: grid.cellWidth,
              height: grid.pictureHeightCss,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: ExcludeSemantics(
                  child: pictures.of(PictureRef.of(pair, pair.yes)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pair.word,
            textDirection: _lang.textDirection,
            locale: _lang.locale,
            style: NocheType.forScript(CoquiText.lessonWord, _lang.script),
          ),
        ],
      ),
    ),
  );

  Widget _group(ReviewGroup g, EndGrid grid) {
    final rows = <List<ReviewPair>>[];
    for (var i = 0; i < g.pairs.length; i += grid.columns) {
      rows.add(g.pairs.sublist(i, (i + grid.columns).clamp(0, g.pairs.length)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(g.title, style: CoquiText.lessonH2),
        if (g.sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(g.sub, style: CoquiText.lessonSub),
        ],
        const SizedBox(height: 12),
        Directionality(
          textDirection: _lang.textDirection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < rows[r].length; c++) ...[
                      if (c > 0) const SizedBox(width: 16),
                      _cell(rows[r][c], grid),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    start: 0,
    end: 0,
    top: 0,
    bottom: 96,
    child: FadingEdges(
      top: 16,
      bottom: 16,
      child: LayoutBuilder(
        builder: (context, c) {
          final horizontal = box.landscape ? 0.0 : 16.0;
          final grid = endGridFor(
            clientWidth: c.maxWidth,
            padding: 2 * horizontal,
            dpr: box.dpr,
          );
          return SingleChildScrollView(
            controller: controller,
            padding: EdgeInsetsDirectional.fromSTEB(
              horizontal,
              box.landscape ? 8 : 16,
              horizontal,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: grid.width),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ReviewStrings.doneTitle, style: CoquiText.lessonH1),
                    const SizedBox(height: 8),
                    Text(end.summary, style: CoquiText.lessonBody),
                    for (final g in end.groups) _group(g, grid),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
