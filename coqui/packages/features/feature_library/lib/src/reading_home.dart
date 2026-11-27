import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:feature_library/src/wording.dart';
import 'package:material_ui/material_ui.dart';

enum _ShelfFilter { all, stories, books }

class ReadingHome extends StatefulWidget {
  const ReadingHome({
    super.key,
    required this.services,
    this.controller,
    this.showAddYourOwn = true,
    this.bottomClearance,
  });

  final Services services;
  final ScrollController? controller;
  final bool showAddYourOwn;
  final double? bottomClearance;

  @override
  State<ReadingHome> createState() => _ReadingHomeState();
}

class _ReadingHomeState extends State<ReadingHome> {
  Services get _s => widget.services;
  late final _store = ReadingStore(_s.storage(ReadingStore.space));
  late List<ReadingText> _texts = _store.texts();
  StreamSubscription<void>? _changes;
  StoryGenerator? _generator;
  _ShelfFilter _filter = _ShelfFilter.all;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _changes = _s.progress.changes.listen((_) {
      if (mounted) setState(() => _texts = _store.texts());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) _texts = _store.texts();
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  Future<void> _open(ReadingText text) async {
    _s.haptics.tick();
    unawaited(_s.clips.unlock());
    await _store
        .markOpened(text.id, _s.clock.nowMs())
        .catchError((Object _) {});
    if (!mounted) return;
    setState(() => _texts = _store.texts());
    _s.nav.go(BookRoute(text.id));
  }

  Future<void> _save(
    String title,
    String body, {
    required bool generated,
  }) async {
    final text = await _store.add(
      now: _s.clock.nowMs(),
      title: title,
      body: body,
      generated: generated,
    );
    if (!mounted) return;
    setState(() => _texts = _store.texts());
    await _open(text);
  }

  Future<void> _generate() async {
    final lang = _s.course.language;
    final input = await showNocheSheet<String>(
      context,
      title: LibraryWording.writeMyStory,
      builder: (context, close) => _StoryPromptSheet(
        language: lang,
        onCancel: close,
        onSubmit: (words) => Navigator.pop(context, words),
      ),
    );
    if (input == null || !mounted || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final generator = _generator ??= await StoryGenerator.load();
      if (!mounted) return;
      final story = generator.generate(
        vocabulary: ReadingVocabulary(_s.progress.words, language: lang),
        focus: input.split(RegExp(r'[,،]')),
        due: _s.progress.due(Skill.ear),
        previous: {
          for (final text in _texts.where((t) => t.generated)) text.body,
        },
        rng: _s.rng,
      );
      if (story == null) {
        setState(
          () => _message = input.isEmpty
              ? LibraryWording.noStoryMatchEmpty
              : LibraryWording.noStoryMatchFocused,
        );
      } else {
        await _save(story.title, story.body, generated: true);
      }
    } on Object {
      if (mounted) {
        setState(() => _message = LibraryWording.storySaveFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ReviewPair? _storyPair(ReadingText text) {
    final lang = _s.course.language;
    ReviewPair? fallback;
    for (final word in [
      ...readingWords(text.title, language: lang),
      ...readingWords(text.body, language: lang),
    ]) {
      final pair = _s.course.pairFor(word);
      if (pair == null) continue;
      if (word.length >= 3) return pair;
      fallback ??= pair;
    }
    return fallback;
  }

  Widget _filterPill(String label, _ShelfFilter value) {
    final selected = _filter == value;
    void select() => setState(() => _filter = value);
    return selected
        ? NochePill.selected(label: label, onPressed: select)
        : NochePill.outline(label: label, onPressed: select);
  }

  @override
  Widget build(BuildContext context) {
    final lang = _s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final pad = MediaQuery.paddingOf(context);
    final tracked = tracksReading(_s.progress);
    final ordered = sortShelfByRecent(_texts, _store.place);
    final visible = switch (_filter) {
      _ShelfFilter.all => ordered,
      _ShelfFilter.stories => ordered.where((t) => t.generated).toList(),
      _ShelfFilter.books => ordered.where((t) => !t.generated).toList(),
    };
    final emptyMessage = switch (_filter) {
      _ShelfFilter.all => LibraryWording.emptyShelfAll,
      _ShelfFilter.stories => LibraryWording.emptyShelfStories,
      _ShelfFilter.books => LibraryWording.emptyShelfBooks,
    };
    final keepBook = keepReadingBook(_texts, _store.place, _s.progress.hasRead);

    final header = SizedBox(
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
                    lang.englishName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.label.copyWith(color: NocheColors.label),
                  ),
                  const SizedBox(height: 4),
                  Semantics(
                    header: true,
                    child: Text(
                      LibraryWording.libraryTitle,
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
            if (widget.showAddYourOwn) ...[
              const SizedBox(width: 12),
              NochePill.outline(
                label: LibraryWording.addYourOwnPill,
                onPressed: _busy ? null : () => _s.nav.go(const ImportRoute()),
              ),
            ],
          ],
        ),
      ),
    );

    final storySection = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NocheSectionLabel(
            LibraryWording.writeStorySection,
            bottomGap: 16,
          ),
          NocheOutlineButton(
            label: LibraryWording.writeMyStory,
            onPressed: _busy ? null : _generate,
          ),
          if (_message case final message?) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: NocheType.body.copyWith(color: NocheColors.label),
              ),
            ),
          ],
        ],
      ),
    );

    final shelfSection = Padding(
      padding: const EdgeInsetsDirectional.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: NocheSectionLabel(
              tracked
                  ? LibraryWording.yourShelf
                  : LibraryWording.yourShelfBeforeA2,
              bottomGap: 12,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
            child: Row(
              children: [
                _filterPill(LibraryWording.filterAll, _ShelfFilter.all),
                const SizedBox(width: 8),
                _filterPill(LibraryWording.filterStories, _ShelfFilter.stories),
                const SizedBox(width: 8),
                _filterPill(LibraryWording.filterBooks, _ShelfFilter.books),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: NocheCard(
                variant: NocheCardVariant.dashed,
                child: Text(
                  emptyMessage,
                  style: NocheType.body.copyWith(color: NocheColors.label),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    _ShelfTile(
                      text: visible[i],
                      lang: lang,
                      pair: visible[i].generated
                          ? _storyPair(visible[i])
                          : null,
                      pictures: _s.pictures,
                      onPressed: _busy ? null : () => _open(visible[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );

    return Directionality(
      textDirection: textDirection,
      child: ColoredBox(
        color: NocheColors.ground,
        child: DefaultTextStyle.merge(
          style: NocheType.body.copyWith(color: NocheColors.text),
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              top: pad.top,
              bottom:
                  (widget.bottomClearance ?? NocheSize.aboveTabBar) +
                  pad.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: widget.controller,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [header, storySection, shelfSection],
                    ),
                  ),
                ),
                if (keepBook != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      16,
                      12,
                      16,
                      0,
                    ),
                    child: _KeepReadingCard(
                      book: keepBook,
                      place: _store.place(keepBook.id),
                      lang: lang,
                      onContinue: _busy ? null : () => _open(keepBook),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfTile extends StatelessWidget {
  const _ShelfTile({
    required this.text,
    required this.lang,
    required this.pair,
    required this.pictures,
    required this.onPressed,
  });

  final ReadingText text;
  final Language lang;
  final ReviewPair? pair;
  final PictureSource pictures;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isStory = text.generated;
    final subtitle = isStory
        ? LibraryWording.typeStory
        : LibraryWording.typeBook;
    final locale = Locale(lang.code);
    final titleStyle = NocheType.forScript(
      NocheType.button.copyWith(height: 18 / 14),
      lang.script,
    ).copyWith(color: NocheColors.text);
    final subtitleStyle = NocheType.bodySmall.copyWith(
      fontSize: 12,
      height: 16 / 12,
      color: NocheColors.label,
    );

    final Widget visual;
    if (isStory) {
      final matchedPair = pair;
      if (matchedPair != null) {
        visual = ExcludeSemantics(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 104,
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(NocheSize.tileRadius),
                child: ColoredBox(
                  color: NocheColors.panel,
                  child: OverflowBox(
                    minWidth: 226,
                    maxWidth: 226,
                    minHeight: 120,
                    maxHeight: 120,
                    child: pictures.of(
                      PictureRef.of(matchedPair, matchedPair.yes),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        visual = ExcludeSemantics(
          child: Container(
            width: 104,
            height: 120,
            decoration: BoxDecoration(
              color: NocheColors.panel,
              border: Border.all(color: NocheColors.line, width: 1),
              borderRadius: BorderRadius.circular(NocheSize.tileRadius),
            ),
            alignment: AlignmentDirectional.center,
            child: const NocheIcon(
              NocheIcons.library,
              size: 28,
              color: NocheColors.label,
            ),
          ),
        );
      }
    } else {
      visual = NocheCover(
        bookId: text.id,
        title: text.title,
        size: NocheCoverSize.regular,
        script: lang.script,
        locale: locale,
      );
    }

    return Pressable(
      onPressed: onPressed,
      semanticLabel: '${text.title}, $subtitle',
      builder: (context, pressed) => Transform.scale(
        scale: pressed ? 0.98 : 1,
        child: SizedBox(
          width: isStory ? 104 : 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              visual,
              const SizedBox(height: 8),
              Text(
                text.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                locale: locale,
                style: titleStyle,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeepReadingCard extends StatelessWidget {
  const _KeepReadingCard({
    required this.book,
    required this.place,
    required this.lang,
    required this.onContinue,
  });

  final ReadingText book;
  final ReadingPlace place;
  final Language lang;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final prog = readingProgress(book, place, language: lang);
    final locale = Locale(lang.code);
    return NocheCard(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NocheCover(
                bookId: book.id,
                title: book.title,
                size: NocheCoverSize.small,
                script: lang.script,
                locale: locale,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      keepReadingEyebrow().toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NocheType.label.copyWith(color: NocheColors.label),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      locale: locale,
                      style: NocheType.forScript(
                        NocheType.cardTitle.copyWith(
                          fontSize: 20,
                          height: 24 / 20,
                        ),
                        lang.script,
                      ).copyWith(color: NocheColors.text),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LibraryWording.keepReadingPageProgress(
                        page: prog.page,
                        totalPages: prog.totalPages,
                        minutesLeft: prog.minutesLeft,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NocheType.bodySmall.copyWith(
                        color: NocheColors.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    NocheProgressBar(
                      value: prog.totalPages <= 1
                          ? 0.0
                          : (prog.page - 1) / prog.totalPages,
                      color: NocheColors.next,
                      semanticLabel: LibraryWording.keepReadingPageSemantic(
                        page: prog.page,
                        totalPages: prog.totalPages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          NochePrimaryButton(
            label: LibraryWording.continueReading,
            small: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _StoryPromptSheet extends StatefulWidget {
  const _StoryPromptSheet({
    required this.language,
    required this.onCancel,
    required this.onSubmit,
  });

  final Language language;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  @override
  State<_StoryPromptSheet> createState() => _StoryPromptSheetState();
}

class _StoryPromptSheetState extends State<_StoryPromptSheet> {
  final _words = TextEditingController();

  @override
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmit(_words.text.trim());

  @override
  Widget build(BuildContext context) {
    final courseDirection = widget.language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.line),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(NocheSize.tileRadius),
      borderSide: const BorderSide(color: NocheColors.text),
    );

    TextStyle fieldStyle(TextStyle base, Color color) =>
        base.copyWith(color: color, textBaseline: TextBaseline.alphabetic);

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _words,
              minLines: 1,
              maxLines: 2,
              maxLength: 180,
              cursorColor: NocheColors.next,
              textDirection: courseDirection,
              style: fieldStyle(
                NocheType.forScript(NocheType.body, widget.language.script),
                NocheColors.text,
              ),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                filled: true,
                fillColor: NocheColors.ground,
                labelText: LibraryWording.practiceWordsLabel,
                labelStyle: fieldStyle(NocheType.body, NocheColors.label),
                floatingLabelStyle: fieldStyle(
                  NocheType.label,
                  NocheColors.text,
                ),
                helperText: LibraryWording.practiceWordsHelper,
                helperStyle: fieldStyle(NocheType.bodySmall, NocheColors.label),
                helperMaxLines: 3,
                counterStyle: fieldStyle(
                  NocheType.bodySmall,
                  NocheColors.label,
                ),
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: border,
                enabledBorder: border,
                focusedBorder: focusedBorder,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NocheOutlineButton(
                  label: LibraryWording.cancel,
                  expand: false,
                  onPressed: widget.onCancel,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NochePrimaryButton(
                    label: LibraryWording.writeMyStory,
                    small: true,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
