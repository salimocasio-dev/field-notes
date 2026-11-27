/// Repaso (¿Cuál?) on screen: cual.html, built on Noche tokens and lesson parts. The session
/// (logic/review_session.dart) decides everything; this draws it and passes touches on.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_review/src/logic/lesson_base.dart';
import 'package:feature_review/src/logic/review_session.dart';
import 'package:feature_review/src/motion.dart';
import 'package:feature_review/src/ui/block_layout.dart';
import 'package:feature_review/src/ui/host_wait.dart';
import 'package:feature_review/src/ui/lesson_parts.dart';
import 'package:feature_review/src/ui/noche_lesson_parts.dart';
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

  void _start() {
    if (session.screen != LessonScreen.start) return;
    unawaited(_s.clips.unlock());
    unawaited(session.run());
  }

  /// The start disc pressed, for a dev entry or a test that cannot reach it by touch.
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

  Widget _choices(BuildContext context, LessonBox box) {
    final s = session;
    final panels = s.panels!;
    final motion = NocheMotion.of(context);
    return PictureBlock(
      fit: box.fit(BlockSpec.review),
      cell: (context, k, r) => NocheRiseIn(
        key: ValueKey('review_item_row_$k'),
        delay: ReviewMotion.itemRowsDelay + motion.stagger * k,
        child: OptionTouch(
          index: k,
          onTouch: s.touch,
          child: NochePictureChoice(
            ring: choiceRing(s.rings[k]),
            dim: _dim(panels[k]),
            check: s.checks[k],
            child: _picture(panels[k], r),
          ),
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
      final motion = NocheMotion.of(context);
      final endSchedule = end
          ? ReviewEndSchedule(motion, [
              for (final g in s.end!.groups) g.pairs.length,
            ])
          : null;
      final Object pictureKey = showPictures
          ? ('review_play', s.index)
          : s.screen;
      return NocheLessonFrame(
        onClose: _close,
        showClose: !end,
        showSound: !end,
        onSound: _toggleSound,
        muted: _s.clips.muted,
        progress: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: nocheLessonColumnMax),
            child: NocheDashes.progress(
              count: s.barSegments,
              done: s.barLit,
              onLessonGround: true,
              gap: s.barSegments > 24 ? 1 : 4,
              semanticLabel: 'Progress: ${s.barLit} of ${s.barSegments}',
            ),
          ),
        ),
        picture: NocheItemTransition(
          contentKey: pictureKey,
          child: showPictures
              ? _choices(context, box)
              : const SizedBox.shrink(),
        ),
        caption: showPictures && s.caption.isNotEmpty ? s.caption : null,
        speaking: showPictures && s.speaking > 0,
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
                schedule: endSchedule,
              )
            : null,
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
                    'Back to ${_s.course.language.tabNames['words'] ?? CoquiLabels.words}',
                onPressed: _back,
              ),
            ),
        ],
        startState: start,
      );
    },
  );
}

/// `#fin.lis`: the end of a Repaso: the title, a summary line, and the session's words with their pictures under two
/// headings, each with a secondary line; one block as wide as the grid, centred; the list scrolls in the space above
/// the 56 px button and fades out at both ends (cual.html:40-44; cual.js: cualGrupo, cualGrid).
class ReviewEndScreen extends StatelessWidget {
  const ReviewEndScreen({
    super.key,
    required this.box,
    required this.end,
    required this.pictures,
    this.language,
    this.controller,
    this.schedule,
  });

  final ScrollController? controller;

  final LessonBox box;
  final ReviewEnd end;
  final PictureSource pictures;
  final Language? language;
  final ReviewEndSchedule? schedule;

  Language get _lang => language ?? Language.spanish;

  Widget _cell(ReviewPair pair, EndGrid grid, Duration wordStart) {
    final st = end.stages[pair.word];
    final before = st?.before ?? 0;
    final after = st?.after ?? 0;
    final movedUp =
        end.up.contains(pair.word) && after > before && end.stageMax > 0;
    return NocheRiseIn(
      key: ValueKey('end_word_${pair.word}'),
      delay: wordStart,
      child: SizedBox(
        width: grid.cellWidth,
        child: Directionality(
          textDirection: _lang.textDirection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: NocheColors.lessonBorder,
                      spreadRadius: nocheLessonBorder,
                    ),
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
                style: NocheType.forScript(
                  NocheType.bodyLarge,
                  _lang.script,
                ).copyWith(color: NocheColors.text),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: NocheStageBar(
                  key: ValueKey('end_stage_bar_${pair.word}'),
                  stage: after,
                  max: end.stageMax,
                  animateFrom: movedUp
                      ? (before / end.stageMax).clamp(0.0, 1.0)
                      : null,
                  delay: wordStart + ReviewMotion.stageBarDelay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _group(
    ReviewGroup g,
    int groupIndex,
    EndGrid grid,
    ReviewEndSchedule timing,
  ) {
    final rows = <List<(int, ReviewPair)>>[];
    for (var i = 0; i < g.pairs.length; i += grid.columns) {
      final sliceEnd = (i + grid.columns).clamp(0, g.pairs.length);
      rows.add([for (var j = i; j < sliceEnd; j++) (j, g.pairs[j])]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        NocheRiseIn(
          key: ValueKey('end_group_header_$groupIndex'),
          delay: timing.groupHeaderStart[groupIndex],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                g.title,
                style: NocheType.row.copyWith(color: NocheColors.text),
              ),
              if (g.sub.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  g.sub,
                  style: NocheType.body.copyWith(color: NocheColors.label),
                ),
              ],
            ],
          ),
        ),
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
                      _cell(
                        rows[r][c].$2,
                        grid,
                        timing.wordStart[groupIndex][rows[r][c].$1],
                      ),
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
  Widget build(BuildContext context) {
    final timing =
        schedule ??
        ReviewEndSchedule(NocheMotion.of(context), [
          for (final g in end.groups) g.pairs.length,
        ]);
    return PositionedDirectional(
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
                      NocheRiseIn(
                        key: const ValueKey('end_done_title'),
                        delay: timing.doneStart,
                        child: Text(
                          ReviewStrings.doneTitle,
                          style: NocheType.pageTitle.copyWith(
                            color: NocheColors.text,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      NocheRiseIn(
                        key: const ValueKey('end_summary'),
                        delay: timing.summaryStart,
                        child: Text(
                          end.summary,
                          style: NocheType.bodyLarge.copyWith(
                            color: NocheColors.label,
                          ),
                        ),
                      ),
                      for (var gi = 0; gi < end.groups.length; gi++)
                        _group(end.groups[gi], gi, grid, timing),
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
}
