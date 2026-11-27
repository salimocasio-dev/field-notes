/// The Noche Words tab (story N4.4, issue #104, board `Noche-Palabras.dc.html`):
/// header with language label, "Words" title and "+ Add a word or goal" pill,
/// due-today summary card, 5-column return bar chart, Listening/Speaking/Reading
/// segmented switch, soonest-first word list with stage bars, and the orange
/// "Start review" / "Practice" button above the tab bar.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/add_box.dart';
import 'package:feature_words/src/motion.dart';
import 'package:feature_words/src/word_sheet.dart';
import 'package:feature_words/src/wording.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:material_ui/material_ui.dart';

/// The Words tab. Reads [Services.progress], [Services.course], and
/// [Services.clock], and refreshes after every save of the store.
class WordsTab extends StatefulWidget {
  const WordsTab({
    super.key,
    required this.services,
    this.stageMax,
    this.initialSkill = WordsSkill.listening,
  });

  final Services services;

  /// Optional override for the maximum stage; defaults to [defaultStageMax]
  /// until request 87 lands `stageMax` on `ProgressStore`.
  final int? stageMax;

  /// Initial skill tab (defaults to [WordsSkill.listening]).
  final WordsSkill initialSkill;

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final _scroll = ScrollController();
  StreamSubscription<void>? _changes;
  WordsView? _view;
  late WordsSkill _skill = widget.initialSkill;
  NocheFollowSide _skillFollowSide = NocheFollowSide.end;

  // app.html: PALT (a drawing that a newer one has overtaken is dropped)
  int _gen = 0;
  bool _openingWord = false;
  bool _openingAdd = false;

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _changes = _s.progress.changes.listen((_) => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void didUpdateWidget(WordsTab old) {
    super.didUpdateWidget(old);
    final a = old.services;
    final b = widget.services;
    if (!identical(a.progress, b.progress) ||
        !identical(a.course, b.course) ||
        old.stageMax != widget.stageMax) {
      unawaited(_changes?.cancel());
      _changes = b.progress.changes.listen((_) => unawaited(_load()));
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final my = ++_gen;
    final view = await buildWordsView(_s, stageMax: widget.stageMax);
    if (my != _gen || !mounted) return;
    setState(() => _view = view);
  }

  // app.html: palabra
  Future<void> _openWord(String w) async {
    _s.haptics.tick();
    final r = _s.progress.word(w);
    if (r == null || _openingWord) return;
    _openingWord = true;
    try {
      unawaited(_s.clips.stop()); // paraLeer()
      final pair = pairsByWord(_s.course)[w];
      final lines = await _s.course.linesWith(w, playedStories(_s));
      if (!mounted) return;
      final sheet = WordSheet(
        services: _s,
        record: r,
        pair: pair,
        lines: lines,
        stageMax: _view?.stageMax ?? widget.stageMax ?? defaultStageMax,
      );
      await showNocheSheet<void>(context, title: r.w, builder: sheet.build);
      sheet.closed();
    } finally {
      _openingWord = false;
    }
  }

  Future<void> _openAddBox() async {
    _s.haptics.tick();
    if (_openingAdd) return;
    _openingAdd = true;
    try {
      await showNocheSheet<void>(
        context,
        title: WordsWording.addSheetTitle,
        builder: (context, close) =>
            AddBoxSheetBody(progress: _s.progress, haptics: _s.haptics),
      );
    } finally {
      _openingAdd = false;
    }
  }

  void _selectSkill(WordsSkill skill) {
    if (skill == _skill) return;
    _s.haptics.tick();
    setState(() {
      _skillFollowSide = WordsMotion.skillFollowSide(from: _skill, to: skill);
      _skill = skill;
    });
  }

  void _review(WordsView v) {
    _s.haptics.tick();
    _s.nav.go(ReviewRoute(practice: v.reviewPractice));
  }

  @override
  Widget build(BuildContext context) {
    final v = _view;
    final lang = _s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final courseLocale = Locale(lang.code);
    final pad = MediaQuery.paddingOf(context);

    return Directionality(
      textDirection: textDirection,
      child: ColoredBox(
        key: const Key('words-tab'),
        color: NocheColors.ground,
        child: DefaultTextStyle.merge(
          style: NocheType.body.copyWith(color: NocheColors.text),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: pad.top,
              bottom: NocheSize.aboveTabBar + pad.bottom,
            ),
            child: v == null
                ? const SizedBox.shrink()
                : _buildContent(v, lang, courseLocale),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(WordsView v, Language lang, Locale courseLocale) {
    final skillView = v.of(_skill);
    final b = skillView.buckets;
    final dueLabel = WordsWording.dueTodayLabel(skillView.dueToday);
    final chartHeading = WordsWording.chartHeading(skillView.totalWords);
    final chartSemanticLabel = WordsWording.chartSemanticLabel(
      today: b.today,
      tomorrow: b.tomorrow,
      threeDays: b.threeDays,
      thisWeek: b.thisWeek,
      later: b.later,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WordsHeader(
                      languageName: lang.englishName,
                      onAddTap: _openAddBox,
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 16,
                      ),
                      child: NocheCard(
                        padding: const EdgeInsetsDirectional.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '${skillView.dueToday}',
                              key: const Key('words-due-count'),
                              style: NocheType.bigNumber.copyWith(
                                color: NocheColors.next,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                dueLabel,
                                style: NocheType.row.copyWith(
                                  color: NocheColors.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        24,
                        16,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NocheSectionLabel(chartHeading, bottomGap: 16),
                          NocheBarChart(
                            delay: WordsMotion.chartArrivalDelay,
                            semanticLabel: chartSemanticLabel,
                            items: [
                              NocheBarItem(
                                label: WordsWording.bucketToday,
                                value: b.today,
                                highlighted: true,
                              ),
                              NocheBarItem(
                                label: WordsWording.bucketTomorrow,
                                value: b.tomorrow,
                              ),
                              NocheBarItem(
                                label: WordsWording.bucketThreeDays,
                                value: b.threeDays,
                              ),
                              NocheBarItem(
                                label: WordsWording.bucketThisWeek,
                                value: b.thisWeek,
                              ),
                              NocheBarItem(
                                label: WordsWording.bucketLater,
                                value: b.later,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        24,
                        16,
                        0,
                      ),
                      child: NocheSegmented<WordsSkill>(
                        role: NocheSegmentedRole.tabList,
                        semanticLabel: WordsWording.skillSwitchSemanticLabel,
                        selected: _skill,
                        onChanged: _selectSkill,
                        options: [
                          NocheSegmentOption(
                            value: WordsSkill.listening,
                            label: WordsWording.listeningTab(
                              v.listening.goodCount,
                            ),
                          ),
                          NocheSegmentOption(
                            value: WordsSkill.speaking,
                            label: WordsWording.speakingTab(
                              v.speaking.goodCount,
                            ),
                          ),
                          NocheSegmentOption(
                            value: WordsSkill.reading,
                            label: v.tracksReading
                                ? WordsWording.readingTab(v.reading.goodCount)
                                : WordsWording.readingLockedTab,
                            muted: !v.tracksReading,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: NocheFollow(
                  contentKey: _skill,
                  side: _skillFollowSide,
                  distance: WordsMotion.skillListDistance,
                  child: _SkillListViewport(
                    child: _buildSkillList(v, skillView, lang, courseLocale),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
          child: NocheArrive(
            delay: WordsMotion.reviewActionDelay,
            next: NochePrimaryButton(
              key: const Key('words-review-button'),
              label: v.reviewButtonLabel,
              onPressed: v.reviewEnabled ? () => _review(v) : null,
            ),
            children: const [],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillList(
    WordsView v,
    SkillWordsView skillView,
    Language lang,
    Locale courseLocale,
  ) {
    if (_skill == WordsSkill.reading && !v.tracksReading) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Text(
          WordsWording.readingLockedMessage,
          style: NocheType.body.copyWith(color: NocheColors.label),
        ),
      );
    }
    if (skillView.rows.isEmpty) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
        child: Text(switch (_skill) {
          WordsSkill.listening => WordsWording.emptyListening,
          WordsSkill.speaking => WordsWording.emptySpeaking,
          WordsSkill.reading => WordsWording.emptyReading,
        }, style: NocheType.body.copyWith(color: NocheColors.label)),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < skillView.rows.length; i++)
            _WordRow(
              entry: skillView.rows[i],
              stageMax: v.stageMax,
              script: lang.script,
              locale: courseLocale,
              showDivider: i < skillView.rows.length - 1,
              onTap: () => unawaited(_openWord(skillView.rows[i].record.w)),
            ),
        ],
      ),
    );
  }
}

class _SkillListViewport extends StatelessWidget {
  const _SkillListViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: OverflowBox(
        alignment: AlignmentDirectional.topStart,
        minHeight: 0,
        maxHeight: double.infinity,
        fit: OverflowBoxFit.deferToChild,
        child: child,
      ),
    );
  }
}

class _WordsHeader extends StatelessWidget {
  const _WordsHeader({required this.languageName, required this.onAddTap});

  final String languageName;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    languageName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.label.copyWith(color: NocheColors.label),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(
                      WordsWording.screenTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NocheType.pageTitle.copyWith(
                        color: NocheColors.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: NochePill.outline(
                key: const Key('words-add-pill'),
                label: WordsWording.addPillLabel,
                onPressed: onAddTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.entry,
    required this.stageMax,
    required this.script,
    required this.locale,
    required this.showDivider,
    required this.onTap,
  });

  final WordRowEntry entry;
  final int stageMax;
  final String script;
  final Locale locale;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final wordStyle = NocheType.forScript(
      NocheType.row,
      script,
    ).copyWith(color: NocheColors.text);
    final dueStyle = NocheType.bodySmall.copyWith(
      fontSize: 12,
      height: 16 / 12,
      color: entry.isDueToday ? NocheColors.next : NocheColors.label,
    );
    final semanticLabel = WordsWording.wordRowSemanticLabel(
      word: entry.record.w,
      dueLine: entry.dueLine,
      stage: entry.stage,
      stageMax: stageMax,
    );

    return Pressable(
      key: ValueKey('word-row:${entry.record.w}'),
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => Opacity(
        opacity: pressed ? 0.72 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
          decoration: showDivider
              ? const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: NocheColors.line, width: 1),
                  ),
                )
              : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.record.w,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      locale: locale,
                      style: wordStyle,
                    ),
                    if (entry.dueLine.isNotEmpty)
                      Text(
                        entry.dueLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dueStyle,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              NocheStageBar(stage: entry.stage, max: stageMax),
            ],
          ),
        ),
      ),
    );
  }
}
