/// The Palabras tab (app.html: `palabras`): the Repaso card, every word he has met by place, and "Add a word or a
/// goal".
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/add_box.dart';
import 'package:feature_words/src/balanced_key_line.dart';
import 'package:feature_words/src/word_sheet.dart';
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
  StreamSubscription<void>? _changes;
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
    unawaited(_load());
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
      await showWordSheet(
        context,
        services: _s,
        record: r,
        pair: pair,
        lines: lines,
      );
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

  Widget _card(WordEntry e) {
    final r = e.record;
    final pair = e.pair;
    return WordCard(
      word: r.w,
      ear: r.ear.etapa,
      mouth: r.mouth.etapa,
      picture: pair == null
          ? null
          : _s.pictures.of(PictureRef.of(pair, pair.yes)),
      onTap: () => unawaited(_openWord(r.w)),
    );
  }

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
                        const ScreenTitle('Palabras'),
                        CoquiCard(
                          child: CoquiRow(
                            minHeight: 0,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Repaso', style: CoquiText.rowBold),
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
                              'Play the first story on the map. Your words show up here.',
                              style: CoquiText.bodyMuted,
                            ),
                          )
                        else
                          for (var i = 0; i < v.groups.length; i++) ...[
                            SectionTitle(v.groups[i].name),
                            if (i == 0)
                              const BalancedKeyLine(
                                'Ear: you know it when you hear it. Mouth: you can say it.',
                              ),
                            WordGrid(
                              children: [
                                for (final e in v.groups[i].words) _card(e),
                              ],
                            ),
                          ],
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
