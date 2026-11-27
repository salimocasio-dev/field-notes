/// The end of a story (`Noche-Motion-Tocar.dc.html`, N8.8):
/// `"Story <N> of <M> · <place>"`, the title (`placeTitle`), `"<N> new words"`
/// with `NocheStageBar`s growing from zero in `settle`, `"Today"` with
/// `"<N> of <M> min"` and a `NocheProgressBar` growing from before the story
/// to after it in `settle`, and the action buttons with the orange next action
/// landing last.
library;

import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_story/src/motion.dart';
import 'package:feature_story/src/runner/story_view.dart';
import 'package:feature_story/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// Kind of the primary orange action at the end of a story.
enum StoryEndNextKind { review, story, map }

/// The orange primary action shown at the bottom of the end-of-story panel.
class StoryEndNextAction {
  const StoryEndNextAction.review({required this.minutes})
    : kind = StoryEndNextKind.review,
      storyId = null,
      storyTitle = null;

  const StoryEndNextAction.story({
    required String this.storyId,
    required String this.storyTitle,
  }) : kind = StoryEndNextKind.story,
       minutes = 0;

  const StoryEndNextAction.map()
    : kind = StoryEndNextKind.map,
      storyId = null,
      storyTitle = null,
      minutes = 0;

  final StoryEndNextKind kind;
  final String? storyId;
  final String? storyTitle;
  final int minutes;

  String get label => switch (kind) {
    StoryEndNextKind.review => StoryWording.nextReview(minutes),
    StoryEndNextKind.story => StoryWording.nextStory(storyTitle!),
    StoryEndNextKind.map => StoryWording.backToMap,
  };
}

/// One newly learned word shown on the end-of-story summary.
class StoryEndWord {
  const StoryEndWord({required this.word, required this.stage});

  final String word;
  final int stage;
}

/// Data displayed by [StoryEndPanel] once a story ends.
class StoryEndSummary {
  const StoryEndSummary({
    required this.title,
    this.storyNumber,
    this.storyTotal,
    this.placeName = '',
    this.newWords = const [],
    this.stageMax = 4,
    this.beforeMinutes = 0,
    this.afterMinutes = 0,
    this.goalMinutes = 30,
    required this.nextAction,
  });

  final String title;
  final int? storyNumber;
  final int? storyTotal;
  final String placeName;
  final List<StoryEndWord> newWords;
  final int stageMax;
  final double beforeMinutes;
  final double afterMinutes;
  final int goalMinutes;
  final StoryEndNextAction nextAction;
}

/// Computes the [StoryEndSummary] from the course, progress, and story state.
StoryEndSummary buildStoryEndSummary({
  required String storyId,
  required Map<String, dynamic> story,
  required StoryFoot foot,
  required bool listen,
  required CourseCatalog course,
  required ProgressStore progress,
  required Clock clock,
  required Set<String> knownBefore,
  required double beforeMinutes,
}) {
  int? storyNumber;
  int? storyTotal;
  var placeName = '';
  for (final place in course.places) {
    final idx = place.stories.indexOf(storyId);
    if (idx >= 0) {
      storyNumber = idx + 1;
      storyTotal = place.stories.length;
      placeName = place.name;
      break;
    }
    if (place.pictureStories.contains(storyId) ||
        place.routines.contains(storyId)) {
      placeName = place.name;
      break;
    }
  }

  final title =
      (story['title'] as String?) ?? course.meta(storyId)?.title ?? '';

  final focusWords = <String>[
    for (final w in (story['focus_words'] as List?) ?? const [])
      if (w is String && w.isNotEmpty) w,
  ];
  final stageMax = math.max(1, progress.stageMax);
  final seenWords = <String>{};
  final newWords = <StoryEndWord>[];
  for (final w in focusWords) {
    if (!seenWords.add(w)) continue;
    if (knownBefore.contains(w)) continue;
    final rec = progress.word(w);
    final stage = math.max(1, math.min(stageMax, rec?.ear.etapa ?? 1));
    newWords.add(StoryEndWord(word: w, stage: stage));
  }

  final minSetting = progress.setting('min');
  final goalMinutes =
      minSetting is num && minSetting.isFinite && minSetting >= 1
      ? minSetting.round()
      : 30;
  final today = DateTime.fromMillisecondsSinceEpoch(clock.nowMs(), isUtc: true);
  final afterMinutes = progress.minutesOn(today);

  final StoryEndNextAction nextAction;
  if (!listen) {
    final serving = repasoServing(course, progress);
    final due = progress
        .due(Skill.ear)
        .where(
          (w) => serving != null
              ? serving.canServe(w)
              : course.pairs.any((p) => p.word == w),
        )
        .toList();
    final rawNext = story['next'];
    final nextId = rawNext is String && rawNext.isNotEmpty ? rawNext : null;
    if (due.isNotEmpty) {
      final nd = math.min(due.length, 10);
      final reviewMinutes = math.min(6, 2 + (nd / 3).ceil());
      nextAction = StoryEndNextAction.review(minutes: reviewMinutes);
    } else if (foot.next && nextId != null) {
      final nextMeta = course.meta(nextId);
      nextAction = StoryEndNextAction.story(
        storyId: nextId,
        storyTitle: nextMeta?.title ?? StoryWording.nextStoryFallback,
      );
    } else {
      nextAction = const StoryEndNextAction.map();
    }
  } else {
    nextAction = const StoryEndNextAction.map();
  }

  return StoryEndSummary(
    title: title,
    storyNumber: storyNumber,
    storyTotal: storyTotal,
    placeName: placeName,
    newWords: newWords,
    stageMax: stageMax,
    beforeMinutes: beforeMinutes,
    afterMinutes: math.max(beforeMinutes, afterMinutes),
    goalMinutes: goalMinutes,
    nextAction: nextAction,
  );
}

/// The story's title at the end, start-aligned under the picture in the
/// course's language and script font. Takes no touch (`#fin{pointer-events:none}`).
class StoryEndTitle extends StatelessWidget {
  const StoryEndTitle({super.key, required this.title, this.language});

  final String title;
  final Language? language;

  @override
  Widget build(BuildContext context) {
    if (title.isEmpty) return const SizedBox.shrink();
    final lang = language ?? Language.spanish;
    final titleStyle = NocheType.forScript(
      NocheType.placeTitle,
      lang.script,
    ).copyWith(color: NocheColors.text);

    return IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        child: Text(
          title,
          textAlign: TextAlign.start,
          textDirection: lang.textDirection,
          locale: lang.locale,
          style: titleStyle,
        ),
      ),
    );
  }
}

/// The Noche buttons of the end screen, from [StoryFoot]: "Play again" (outline,
/// `Key('story-end-replay')`) with the outline "Map" (`Key('story-end-map')`)
/// beside it when a primary next action waits, then the ONE orange primary
/// action (`Key('story-end-primary')`).
List<Widget> storyEndButtons({
  required StoryFoot foot,
  required VoidCallback onAgain,
  required VoidCallback onNext,
  required VoidCallback onMap,
  String? primaryLabel,
  VoidCallback? onPrimary,
  bool primaryIsMap = false,
}) {
  final hasPrimaryNext = !primaryIsMap && (onPrimary != null || foot.next);
  final showOutlineMap = hasPrimaryNext
      ? (foot.map || foot.home || onPrimary != null)
      : (!foot.home && foot.map);
  final Widget? primaryButton;
  if (hasPrimaryNext) {
    primaryButton = NochePrimaryButton(
      key: const Key('story-end-primary'),
      label: primaryLabel ?? StoryWording.nextStoryFallback,
      onPressed: onPrimary ?? onNext,
    );
  } else if (foot.home) {
    primaryButton = KeyedSubtree(
      key: const Key('story-end-map'),
      child: NochePrimaryButton(
        key: const Key('story-end-primary'),
        label: primaryLabel ?? StoryWording.backToMap,
        onPressed: onPrimary ?? onMap,
      ),
    );
  } else {
    primaryButton = null;
  }

  return [
    if (foot.again && showOutlineMap)
      Row(
        children: [
          Expanded(
            child: NocheOutlineButton(
              key: const Key('story-end-replay'),
              label: StoryWording.playAgain,
              onPressed: onAgain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: NocheOutlineButton(
              key: const Key('story-end-map'),
              label: StoryWording.map,
              onPressed: onMap,
            ),
          ),
        ],
      )
    else if (foot.again)
      NocheOutlineButton(
        key: const Key('story-end-replay'),
        label: StoryWording.playAgain,
        onPressed: onAgain,
      )
    else if (showOutlineMap)
      NocheOutlineButton(
        key: const Key('story-end-map'),
        label: StoryWording.map,
        onPressed: onMap,
      ),
    ?primaryButton,
  ];
}

/// The N8.8 end-of-story summary panel shown below the 296-high [NocheWindow]
/// (`Noche-Motion-Tocar.dc.html`): staggered summary rows, new-word stage bars
/// growing from zero in `settle`, today's minutes bar growing from before to
/// after the story in `settle`, and the action buttons with the orange primary
/// button landing last.
class StoryEndPanel extends StatelessWidget {
  const StoryEndPanel({
    super.key,
    required this.summary,
    required this.foot,
    required this.language,
    required this.onAgain,
    required this.onPrimary,
    required this.onMap,
    this.reduceMotion = false,
  });

  final StoryEndSummary summary;
  final StoryFoot foot;
  final Language language;
  final VoidCallback onAgain;
  final VoidCallback onPrimary;
  final VoidCallback onMap;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final motion = StoryMotion.resolve(
      context,
      serviceReduceMotion: reduceMotion,
    );
    final rowsDelay = motion.reduced ? Duration.zero : StoryMotion.endRowsDelay;
    final stageBaseDelay = motion.reduced
        ? Duration.zero
        : StoryMotion.endStageBarDelay;
    final minsDelay = motion.reduced
        ? Duration.zero
        : StoryMotion.endMinutesBarDelay;
    final nextDelay = motion.reduced ? Duration.zero : StoryMotion.endNextDelay;

    final goal = math.max(1, summary.goalMinutes);
    final beforeFrac = (summary.beforeMinutes / goal).clamp(0.0, 1.0);
    final afterFrac = (summary.afterMinutes / goal).clamp(0.0, 1.0);
    final shownMins = summary.afterMinutes.round();

    final placeLabelStyle = NocheType.forScript(
      NocheType.label,
      language.script,
    ).copyWith(color: NocheColors.label);
    final wordStyle = NocheType.forScript(
      NocheType.row,
      language.script,
    ).copyWith(color: NocheColors.text);

    final rows = <Widget>[
      if (summary.storyNumber != null && summary.storyTotal != null)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            NocheLtr(
              child: Text(
                StoryWording.storyCounter(
                  summary.storyNumber!,
                  summary.storyTotal!,
                ),
                style: NocheType.label.copyWith(color: NocheColors.label),
              ),
            ),
            if (summary.placeName.isNotEmpty) ...[
              Text(
                '·',
                style: NocheType.label.copyWith(color: NocheColors.label),
              ),
              Text(
                language.script == 'Latn'
                    ? summary.placeName.toUpperCase()
                    : summary.placeName,
                textDirection: language.textDirection,
                locale: language.locale,
                style: placeLabelStyle,
              ),
            ],
          ],
        )
      else if (summary.placeName.isNotEmpty)
        Text(
          language.script == 'Latn'
              ? summary.placeName.toUpperCase()
              : summary.placeName,
          textDirection: language.textDirection,
          locale: language.locale,
          style: placeLabelStyle,
        ),
      Padding(
        padding: const EdgeInsetsDirectional.only(top: 8),
        child: StoryEndTitle(title: summary.title, language: language),
      ),
      if (summary.newWords.isNotEmpty)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 24),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: NocheLtr(
              child: Text(
                StoryWording.newWordsHeading(summary.newWords.length),
                style: NocheType.label.copyWith(color: NocheColors.label),
              ),
            ),
          ),
        ),
      for (var i = 0; i < summary.newWords.length; i++)
        Container(
          key: ValueKey('story_end_word_$i'),
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: NocheColors.lessonLine, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  summary.newWords[i].word,
                  textAlign: TextAlign.start,
                  textDirection: language.textDirection,
                  locale: language.locale,
                  style: wordStyle,
                ),
              ),
              const SizedBox(width: 12),
              NocheStageBar(
                key: ValueKey('story_end_stage_$i'),
                stage: summary.newWords[i].stage,
                max: summary.stageMax,
                animateFrom: 0,
                delay: stageBaseDelay + motion.stagger * math.min(i, 4),
              ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsetsDirectional.only(top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  StoryWording.todayHeading,
                  textDirection: TextDirection.ltr,
                  style: NocheType.label.copyWith(color: NocheColors.label),
                ),
                NocheLtr(
                  child: Text(
                    StoryWording.minutesOfGoal(shownMins, goal),
                    style: NocheType.buttonStrong.copyWith(
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            NocheProgressBar(
              key: const ValueKey('story_end_minutes_bar'),
              value: afterFrac,
              animateFrom: beforeFrac,
              delay: minsDelay,
              color: NocheColors.text,
              trackColor: NocheColors.lessonLine,
              semanticLabel: StoryWording.minutesListenedSemantic,
            ),
          ],
        ),
      ),
    ];

    // NochePrimaryButton uses Atkinson (Latin-only font) and inherits text
    // direction; for non-Latin scripts fall back to English "Next story" and
    // keep the English button text LTR so punctuation and glyphs render cleanly.
    final primaryLabel =
        summary.nextAction.kind == StoryEndNextKind.story &&
            language.script != 'Latn'
        ? StoryWording.nextStoryFallback
        : summary.nextAction.label;

    final buttons = storyEndButtons(
      foot: foot,
      onAgain: onAgain,
      onNext: onPrimary,
      onMap: onMap,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      primaryIsMap: summary.nextAction.kind == StoryEndNextKind.map,
    );

    final secondaryButtons = buttons.length > 1
        ? buttons.sublist(0, buttons.length - 1)
        : const <Widget>[];
    final primaryButton = buttons.isNotEmpty
        ? NocheLtr(child: buttons.last)
        : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsetsDirectional.fromSTEB(16, 24, 16, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: NocheArrive(
                key: const ValueKey('story_end_rows'),
                delay: rowsDelay,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: NocheArrive(
                key: const ValueKey('story_end_actions'),
                delay: nextDelay,
                spacing: 12,
                nextSpacing: 12,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                next: primaryButton,
                children: secondaryButtons,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
