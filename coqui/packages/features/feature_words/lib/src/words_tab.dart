/// The Palabras tab (app.html: `palabras`): the Repaso card, every word he has met by place, and "Add a word or a
/// goal".
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/add_box.dart';
import 'package:feature_words/src/balanced_key_line.dart';
import 'package:feature_words/src/find_box.dart';
import 'package:feature_words/src/word_sheet.dart';
import 'package:feature_words/src/word_tile.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:material_ui/material_ui.dart';

/// The tab. It reads the progress store and the course, and reads them again after every save of the store (an
/// answer given elsewhere): the old page drew itself once each time the tab opened.
class WordsTab extends StatefulWidget {
  const WordsTab({super.key, required this.services});

  final Services services;

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final _scroll = ScrollController();
  final _field = TextEditingController();
  final _find = TextEditingController();
  StreamSubscription<void>? _changes;

  // what the list shows: every word, today's, or the good ones; and the find field's text
  WordFilter _filter = WordFilter.all;
  String _query = '';
  bool _finding = false;
  WordsView? _view;

  // app.html: PALT (a drawing that a newer one has overtaken is dropped)
  int _gen = 0;
  bool _opening = false;

  // app.html: fadeTab (more of the page below the tab bar's edge)
  bool _more = false;

  Services get _s => widget.services;

  @override
  void initState() {
    super.initState();
    _changes = _s.progress.changes.listen((_) => unawaited(_load()));
    _find.addListener(_onFind);
    unawaited(_load());
  }

  void _onFind() {
    if (_find.text != _query) setState(() => _query = _find.text);
  }

  @override
  void didUpdateWidget(WordsTab old) {
    super.didUpdateWidget(old);
    final a = old.services;
    final b = widget.services;
    if (!identical(a.progress, b.progress) || !identical(a.course, b.course)) {
      unawaited(_changes?.cancel());
      _changes = b.progress.changes.listen((_) => unawaited(_load()));
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    _scroll.dispose();
    _field.dispose();
    _find.dispose();
    super.dispose();
  }

  // app.html: palabras
  Future<void> _load() async {
    final my = ++_gen;
    final view = await buildWordsView(_s);
    if (my != _gen || !mounted) return;
    setState(() => _view = view);
  }

  // app.html: palabra
  Future<void> _openWord(String w) async {
    _s.haptics.tick();
    final r = _s.progress.word(w);
    if (r == null || _opening) return;
    _opening = true;
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
      );
      // above everything, the tab bar included: the scrim of v=39 dims both
      await showCoquiSheet(context, builder: sheet.build);
      sheet
          .closed(); // cierra: the sound stops as the sheet starts to slide out
    } finally {
      _opening = false;
    }
  }

  // app.html: `onclick="tick();location.href='cual.html?desde=app'"`
  void _review(WordsView v) {
    _s.haptics.tick();
    _s.nav.go(ReviewRoute(practice: v.practice));
  }

  // app.html: extra
  void _add() {
    final v = _field.text.trim();
    if (v.isEmpty) return;
    _field.clear();
    _s.progress.add(v);
  }

  bool _onScroll(Notification n) {
    final ScrollMetrics? m = n is ScrollMetricsNotification
        ? n.metrics
        : n is ScrollNotification
        ? n.metrics
        : null;
    if (m != null) {
      final more = m.pixels < m.maxScrollExtent - 1;
      if (more != _more) setState(() => _more = more);
    }
    return false;
  }

  Widget _card(WordEntry e, {required bool tag}) {
    final r = e.record;
    final pair = e.pair;
    return WordTile(
      word: r.w,
      ear: r.ear.etapa,
      mouth: r.mouth.etapa,
      picture: pair == null
          ? null
          : _s.pictures.of(PictureRef.of(pair, pair.yes)),
      line: e.line?.text,
      today: tag && e.today,
      onTap: () => unawaited(_openWord(r.w)),
    );
  }

  /// The words, as [_filter] and [_query] leave them: the pills, the line under them, the key, and the groups.
  List<Widget> _words(WordsView v) {
    final groups = shownGroups(v, _filter, _query);
    final today = v.todayWords.length;
    final good = v.goodCount;
    final query = _query.trim();
    final String about;
    if (query.isNotEmpty && groups.isEmpty) {
      about = 'No word has "$query" in it.';
    } else {
      about = switch (_filter) {
        WordFilter.all =>
          '${v.count} word${v.count == 1 ? '' : 's'} · $today today · $good good',
        WordFilter.today =>
          today == 0
              ? 'Nothing comes back today.'
              : 'Repaso asks ${today == 1 ? 'this word' : 'these $today words'} today.',
        WordFilter.good =>
          good == 0
              ? 'No word is good yet. A word is good once you get it right three times when it comes back, over two weeks or more.'
              : 'Good: right three times when it came back, over two weeks or more.',
      };
    }
    final finder = v.count > _findFrom;
    return [
      Block(
        bottom: CoquiMetrics.s8,
        // the pills keep one line: their text grows with the text size up to 1.3 times
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: Row(
            children: [
              Expanded(
                child: SegmentedPills(
                  labels: const ['All', 'Today', 'Good'],
                  selected: _filter.index,
                  onSelected: (i) {
                    _s.haptics.tick();
                    setState(() => _filter = WordFilter.values[i]);
                  },
                ),
              ),
              if (finder) ...[
                const SizedBox(width: CoquiMetrics.s16),
                FindButton(on: _finding, onPressed: _toggleFind),
              ],
            ],
          ),
        ),
      ),
      if (finder && _finding)
        Block(
          top: CoquiMetrics.s8,
          bottom: CoquiMetrics.s8,
          child: FindBox(controller: _find),
        ),
      Block(
        bottom: CoquiMetrics.s8,
        child: BalancedText(about, style: CoquiText.smallMuted),
      ),
      if (groups.isNotEmpty) const Block(bottom: 0, child: SkillKey()),
      for (final g in groups) ...[
        if (g.name.isNotEmpty)
          Block(
            top: CoquiMetrics.s24,
            bottom: CoquiMetrics.s16,
            // the counts at the right end of the heading's line, or under it when both do not fit
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: CoquiMetrics.s8,
              children: [
                Text(g.name, style: CoquiText.h2),
                Text(_placeLine(g, v), style: CoquiText.smallMuted),
              ],
            ),
          )
        else
          const Block(top: CoquiMetrics.s16, child: SizedBox.shrink()),
        TileGrid(
          children: [
            for (final e in g.words) _card(e, tag: _filter != WordFilter.today),
          ],
        ),
      ],
    ];
  }

  // the find button: opens the field (and puts the caret in it), or closes it and lets every word back
  void _toggleFind() {
    _s.haptics.tick();
    setState(() => _finding = !_finding);
    if (!_finding) _find.clear();
  }

  /// Under a place's heading: how many of its words there are, and how many are good (of all its words, whatever
  /// the list shows).
  String _placeLine(PlaceGroup shown, WordsView v) {
    final all = v.groups.firstWhere(
      (g) => g.name == shown.name,
      orElse: () => shown,
    );
    final n = all.words.length;
    final good = all.words.where((e) => e.good).length;
    return '$n word${n == 1 ? '' : 's'} · $good good';
  }

  /// The find field shows once there are more words than this.
  static const _findFrom = 12;

  @override
  Widget build(BuildContext context) {
    final v = _view;
    return ColoredBox(
      color: CoquiColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: v == null
                ? const SizedBox.shrink()
                : NotificationListener<Notification>(
                    onNotification: _onScroll,
                    child: TabPage(
                      controller: _scroll,
                      children: [
                        const ScreenTitle(CoquiLabels.words),
                        CoquiCard(
                          child: CoquiRow(
                            minHeight: 0,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CoquiLabels.review,
                                      style: CoquiText.rowBold,
                                    ),
                                    Text(
                                      v.reviewText,
                                      style: CoquiText.smallMuted,
                                    ),
                                  ],
                                ),
                              ),
                              CoquiButton(
                                label: v.reviewButton,
                                kind: CoquiButtonKind.go,
                                onPressed: v.reviewOff
                                    ? null
                                    : () => _review(v),
                              ),
                            ],
                          ),
                        ),
                        if (v.groups.isEmpty)
                          Block(
                            top: CoquiMetrics.s16,
                            bottom: CoquiMetrics.s16,
                            child: Text(
                              'Play the first story on the map. Every word you hear shows up here, with how well you know it.',
                              style: CoquiText.bodyMuted,
                            ),
                          )
                        else
                          ..._words(v),
                        const SectionTitle('Add a word or a goal'),
                        AddBox(controller: _field, added: v.added, onAdd: _add),
                      ],
                    ),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: CoquiLayout.tabBarHeight(context),
            child: ListFade(visible: _more),
          ),
        ],
      ),
    );
  }
}
