import 'dart:async';
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/motion.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/story_generator.dart';
import 'package:feature_library/src/wording.dart';
import 'package:material_ui/material_ui.dart';

class ReadingHome extends StatefulWidget {
  const ReadingHome({
    super.key,
    required this.services,
    this.controller,
    this.showAddYourOwn = true,
    this.bottomClearance,
    this.generator,
  });

  final Services services;
  final ScrollController? controller;
  final bool showAddYourOwn;
  final double? bottomClearance;

  /// Optional pre-loaded generator (used in tests to inject deterministic plots).
  final StoryGenerator? generator;

  @override
  State<ReadingHome> createState() => _ReadingHomeState();
}

class _ReadingHomeState extends State<ReadingHome> {
  Services get _s => widget.services;
  ReadingStore get _store => ReadingStore(_s.storage(ReadingStore.space));

  late List<ReadingText> _texts;
  StreamSubscription<void>? _changes;
  StoryGenerator? _generator;
  bool? _canWrite;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _texts = _store.texts();
    _generator = widget.generator;
    if (_generator != null) {
      _canWrite = _evaluateCanWrite(_generator!);
    } else {
      unawaited(_loadGenerator());
    }
    _subscribeProgress();
  }

  void _subscribeProgress() {
    unawaited(_changes?.cancel());
    _changes = _s.progress.changes.listen((_) {
      if (!mounted) return;
      _refreshState();
    });
  }

  Future<void> _loadGenerator() async {
    try {
      final loaded = await StoryGenerator.load();
      if (!mounted) return;
      // Ignore stale load if a newer generator was injected while loading.
      if (_generator != null) return;
      setState(() {
        _generator = loaded;
        _canWrite = _evaluateCanWrite(loaded);
      });
    } on Object {
      if (!mounted) return;
      setState(() => _canWrite ??= false);
    }
  }

  bool _evaluateCanWrite(StoryGenerator generator) {
    final lang = _s.course.language;
    return generator.canWrite(
      vocabulary: ReadingVocabulary(_s.progress.words, language: lang),
      due: _s.progress.due(Skill.ear),
      previous: {
        for (final text in _texts.where((t) => t.generated)) text.body,
      },
    );
  }

  void _refreshState() {
    final nextTexts = _store.texts();
    final gen = _generator;
    setState(() {
      _texts = nextTexts;
      if (gen != null) {
        _canWrite = _evaluateCanWrite(gen);
      }
    });
  }

  @override
  void didUpdateWidget(ReadingHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final servicesChanged = oldWidget.services != widget.services;
    final generatorChanged = oldWidget.generator != widget.generator;
    if (servicesChanged) {
      _subscribeProgress();
    }
    if (generatorChanged) {
      _generator = widget.generator;
      if (_generator == null) {
        _canWrite = null;
        unawaited(_loadGenerator());
      }
    }
    if (servicesChanged || generatorChanged) {
      _texts = _store.texts();
      final gen = _generator;
      if (gen != null) {
        _canWrite = _evaluateCanWrite(gen);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _texts = _store.texts();
      final gen = _generator;
      if (gen != null) {
        _canWrite = _evaluateCanWrite(gen);
      }
    }
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
    _refreshState();
    _s.nav.go(BookRoute(text.id));
  }

  Future<({ReadingText? text, String? error, bool close})> _submitStoryPrompt(
    String input,
    Language lang,
  ) async {
    if (_busy) return (text: null, error: null, close: false);
    setState(() => _busy = true);
    try {
      final generator = _generator ??= await StoryGenerator.load();
      if (!mounted) return (text: null, error: null, close: true);
      final trimmed = input.trim();
      final story = generator.generate(
        vocabulary: ReadingVocabulary(_s.progress.words, language: lang),
        focus: trimmed.isEmpty ? const [] : trimmed.split(RegExp(r'[,،]')),
        due: _s.progress.due(Skill.ear),
        previous: {
          for (final text in _texts.where((t) => t.generated)) text.body,
        },
        rng: _s.rng,
      );
      if (story == null) {
        if (trimmed.isNotEmpty) {
          return (
            text: null,
            error: LibraryWording.noStoryMatchFocused,
            close: false,
          );
        }
        if (mounted) _refreshState();
        return (text: null, error: null, close: true);
      }
      final saved = await _store.add(
        now: _s.clock.nowMs(),
        title: story.title,
        body: story.body,
        generated: true,
      );
      if (mounted) _refreshState();
      return (text: saved, error: null, close: true);
    } on Object {
      return (text: null, error: LibraryWording.storySaveFailed, close: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generate() async {
    if (_busy || _canWrite != true) return;
    final lang = _s.course.language;
    final created = await showNocheSheet<ReadingText>(
      context,
      title: LibraryWording.writeMyStory,
      builder: (context, close) => _StoryPromptSheet(
        language: lang,
        onCancel: close,
        onSubmit: (words) => _submitStoryPrompt(words, lang),
      ),
    );
    if (created != null && mounted) {
      await _open(created);
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

  @override
  Widget build(BuildContext context) {
    final lang = _s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final pad = MediaQuery.paddingOf(context);
    final stories = _texts.where((t) => t.generated).toList();
    final books = sortShelfByRecent(
      _texts.where((t) => !t.generated).toList(),
      _store.place,
    );
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
              NocheLtr(
                child: NochePill.outline(
                  label: LibraryWording.addYourOwnPill,
                  onPressed: _busy
                      ? null
                      : () => _s.nav.go(const ImportRoute()),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final storiesShelf = Padding(
      padding: EdgeInsetsDirectional.only(
        start: 16,
        top: keepBook != null ? 24 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NocheSectionLabel(LibraryWording.storiesSection, bottomGap: 12),
          Stack(
            alignment: AlignmentDirectional.topStart,
            children: [
              const PositionedDirectional(
                start: 0,
                end: 0,
                top: 120,
                child: _ShelfPlank(),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 132,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsetsDirectional.only(end: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NewStorySlot(
                        canWrite: _canWrite,
                        onPressed: _busy ? null : _generate,
                      ),
                      for (final story in stories) ...[
                        const SizedBox(width: 12),
                        _StoryShelfItem(
                          text: story,
                          lang: lang,
                          pair: _storyPair(story),
                          pictures: _s.pictures,
                          onPressed: _busy ? null : () => _open(story),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final booksShelf = Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NocheSectionLabel(LibraryWording.booksSection, bottomGap: 12),
          if (books.isEmpty) ...[
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 16, 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: NocheLtr(
                  child: Text(
                    LibraryWording.emptyShelfBooks,
                    style: NocheType.body.copyWith(color: NocheColors.label),
                  ),
                ),
              ),
            ),
            const _ShelfPlank(),
          ] else ...[
            SizedBox(
              height: 132,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(end: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < books.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      _BookShelfItem(
                        book: books[i],
                        lang: lang,
                        onPressed: _busy ? null : () => _open(books[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const _ShelfPlank(),
          ],
        ],
      ),
    );

    return Directionality(
      key: const Key('library-home'),
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
                      children: [
                        header,
                        if (keepBook != null)
                          _ReadingNowShelf(
                            book: keepBook,
                            place: _store.place(keepBook.id),
                            lang: lang,
                            onContinue: _busy ? null : () => _open(keepBook),
                          ),
                        storiesShelf,
                        booksShelf,
                        const SizedBox(height: 16),
                      ],
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
                    child: NochePrimaryButton(
                      label: LibraryWording.continueReading,
                      small: true,
                      onPressed: _busy ? null : () => _open(keepBook),
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

/// Bookcase shelf plank (`Noche-Biblioteca-Cerrado.dc.html`): 4 of `line` with
/// top-start radius 2 on 8 of `chip` with bottom-start radius 4, running from
/// 16 at the start to the screen's end edge.
class _ShelfPlank extends StatelessWidget {
  const _ShelfPlank();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 4,
          decoration: const BoxDecoration(
            color: NocheColors.line,
            borderRadius: BorderRadiusDirectional.only(
              topStart: Radius.circular(2),
            ),
          ),
        ),
        Container(
          height: 8,
          decoration: const BoxDecoration(
            color: NocheColors.chip,
            borderRadius: BorderRadiusDirectional.only(
              bottomStart: Radius.circular(4),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReadingNowShelf extends StatelessWidget {
  const _ReadingNowShelf({
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
    final chapters = book.chapters;
    final chapterCount = chapters != null && chapters.isNotEmpty
        ? chapters.length
        : 1;
    final chapterNumber = chapterCount > 1
        ? (place.chapterIndex ?? 0).clamp(0, chapterCount - 1) + 1
        : 1;
    final eyebrow = keepReadingEyebrow(
      chapter: chapterNumber,
      chapterCount: chapterCount,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Pressable(
              onPressed: onContinue,
              builder: (context, _) => ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 126),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 126,
                      child: NocheCover(
                        bookId: book.id,
                        title: book.title,
                        size: NocheCoverSize.regular,
                        script: lang.script,
                        locale: locale,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: NocheLtr(
                                child: Text(
                                  eyebrow.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: NocheType.label.copyWith(
                                    color: NocheColors.label,
                                  ),
                                ),
                              ),
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
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: NocheLtr(
                                child: Text(
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
                              ),
                            ),
                            const SizedBox(height: 10),
                            NocheProgressBar(
                              value: prog.totalPages <= 1
                                  ? 0.0
                                  : (prog.page - 1) / prog.totalPages,
                              color: NocheColors.text,
                              semanticLabel:
                                  LibraryWording.keepReadingPageSemantic(
                                    page: prog.page,
                                    totalPages: prog.totalPages,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const _ShelfPlank(),
        ],
      ),
    );
  }
}

class _DashedSlotBorderPainter extends CustomPainter {
  const _DashedSlotBorderPainter({
    required this.color,
    required this.textDirection,
  });

  static const double _strokeWidth = 1;
  static const double _dashLength = 4;
  static const double _gapLength = 3;

  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = _strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      (size.width - _strokeWidth).clamp(0, double.infinity),
      (size.height - _strokeWidth).clamp(0, double.infinity),
    );
    const radius = BorderRadiusDirectional.only(
      topStart: Radius.circular(12),
      topEnd: Radius.circular(12),
      bottomStart: Radius.circular(2),
      bottomEnd: Radius.circular(2),
    );
    final rrect = radius.resolve(textDirection).toRRect(rect);
    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final next = (dist + _dashLength).clamp(0.0, metric.length);
        dashed.addPath(metric.extractPath(dist, next), Offset.zero);
        dist += _dashLength + _gapLength;
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_DashedSlotBorderPainter old) =>
      old.color != color || old.textDirection != textDirection;
}

class _NewStorySlot extends StatefulWidget {
  const _NewStorySlot({required this.canWrite, required this.onPressed});

  /// `null` while the initial `StoryGenerator` load is pending (rendered locked
  /// and snaps directly without animation once resolved).
  final bool? canWrite;
  final VoidCallback? onPressed;

  @override
  State<_NewStorySlot> createState() => _NewStorySlotState();
}

class _NewStorySlotState extends State<_NewStorySlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
  )..addStatusListener(_handleStatus);

  bool _transitioning = false;
  bool _fromOpen = false;
  bool _toOpen = false;
  NocheMotionData _activeMotion = NocheMotion.normal;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _transitioning && mounted) {
      setState(() => _transitioning = false);
    }
  }

  @override
  void didUpdateWidget(_NewStorySlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prev = oldWidget.canWrite;
    final next = widget.canWrite;
    if (prev != null && next != null && prev != next) {
      _activeMotion = NocheMotion.of(context);
      _fromOpen = prev;
      _toOpen = next;
      _transitioning = true;
      _controller.duration = LibraryMotion.slotFade(_activeMotion);
      _controller.forward(from: 0.0);
    } else if (prev == null && next != null) {
      _transitioning = false;
      _fromOpen = next;
      _toOpen = next;
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  Widget _buildLocked(TextDirection textDirection) => SizedBox(
    key: const Key('library-slot-locked'),
    width: 132,
    height: 120,
    child: CustomPaint(
      painter: _DashedSlotBorderPainter(
        color: NocheColors.line,
        textDirection: textDirection,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: NocheIcon(
                NocheIcons.lock,
                size: 22,
                color: NocheColors.label,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: NocheLtr(
                child: Text(
                  LibraryWording.newStoryLocked,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: NocheColors.text,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildOpen(TextDirection textDirection) => Pressable(
    key: const Key('library-write-story'),
    onPressed: widget.onPressed,
    semanticLabel: LibraryWording.newStoryOpen,
    builder: (context, _) => SizedBox(
      width: 132,
      height: 120,
      child: CustomPaint(
        painter: _DashedSlotBorderPainter(
          color: NocheColors.label,
          textDirection: textDirection,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ExcludeSemantics(
                child: NocheIcon(
                  NocheIcons.plus,
                  size: 22,
                  strokeWidth: 2.5,
                  color: NocheColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: NocheLtr(
                  child: Text(
                    LibraryWording.newStoryOpen,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final isOpen = widget.canWrite ?? false;

    if (!_transitioning) {
      return SizedBox(
        width: 132,
        height: 120,
        child: isOpen
            ? Opacity(
                key: const ValueKey('library-slot-open-opacity'),
                opacity: 1.0,
                child: _buildOpen(textDirection),
              )
            : Opacity(
                key: const ValueKey('library-slot-locked-opacity'),
                opacity: 1.0,
                child: _buildLocked(textDirection),
              ),
      );
    }

    return SizedBox(
      width: 132,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value.clamp(0.0, 1.0);
          final outOpacity = (1.0 - _activeMotion.exit.transform(t)).clamp(
            0.0,
            1.0,
          );
          final inOpacity = _activeMotion.enter.transform(t).clamp(0.0, 1.0);

          final lockedOpacity = _toOpen ? outOpacity : inOpacity;
          final openOpacity = _toOpen ? inOpacity : outOpacity;

          final lockedLayer = Positioned.fill(
            child: IgnorePointer(
              ignoring: _toOpen,
              child: ExcludeSemantics(
                excluding: _toOpen,
                child: Opacity(
                  key: const ValueKey('library-slot-locked-opacity'),
                  opacity: lockedOpacity,
                  child: _buildLocked(textDirection),
                ),
              ),
            ),
          );

          final openLayer = Positioned.fill(
            child: IgnorePointer(
              ignoring: !_toOpen,
              child: ExcludeSemantics(
                excluding: !_toOpen,
                child: Opacity(
                  key: const ValueKey('library-slot-open-opacity'),
                  opacity: openOpacity,
                  child: _buildOpen(textDirection),
                ),
              ),
            ),
          );

          return Stack(
            children: _fromOpen
                ? [openLayer, lockedLayer]
                : [lockedLayer, openLayer],
          );
        },
      ),
    );
  }
}

class _StoryShelfItem extends StatelessWidget {
  const _StoryShelfItem({
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

  static const _pictureRadius = BorderRadiusDirectional.only(
    topStart: Radius.circular(12),
    topEnd: Radius.circular(12),
    bottomStart: Radius.circular(2),
    bottomEnd: Radius.circular(2),
  );

  @override
  Widget build(BuildContext context) {
    final locale = Locale(lang.code);
    final titleStyle = NocheType.forScript(
      NocheType.button.copyWith(height: 18 / 14),
      lang.script,
    ).copyWith(color: NocheColors.text);

    final Widget visual;
    final matchedPair = pair;
    if (matchedPair != null) {
      visual = ExcludeSemantics(
        child: NocheLtr(
          child: SizedBox(
            width: 104,
            height: 120,
            child: ClipRRect(
              borderRadius: _pictureRadius,
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
          decoration: const BoxDecoration(
            color: NocheColors.panel,
            border: Border.fromBorderSide(
              BorderSide(color: NocheColors.line, width: 1),
            ),
            borderRadius: _pictureRadius,
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

    return Pressable(
      key: ValueKey('library-book:${text.id}'),
      onPressed: onPressed,
      semanticLabel: text.title,
      builder: (context, _) => SizedBox(
        width: 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            visual,
            const SizedBox(height: 20),
            Text(
              text.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              locale: locale,
              style: titleStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookShelfItem extends StatelessWidget {
  const _BookShelfItem({
    required this.book,
    required this.lang,
    required this.onPressed,
  });

  final ReadingText book;
  final Language lang;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tall = nocheStableHash(book.id).isEven;
    final width = tall ? 96.0 : 90.0;
    final height = tall ? 132.0 : 120.0;
    final locale = Locale(lang.code);

    return Pressable(
      key: ValueKey('library-book:${book.id}'),
      onPressed: onPressed,
      semanticLabel: book.title,
      builder: (context, _) => SizedBox(
        width: width,
        height: height,
        child: NocheCover(
          bookId: book.id,
          title: book.title,
          size: NocheCoverSize.regular,
          script: lang.script,
          locale: locale,
        ),
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
  final Future<({ReadingText? text, String? error, bool close})> Function(
    String words,
  )
  onSubmit;

  @override
  State<_StoryPromptSheet> createState() => _StoryPromptSheetState();
}

class _StoryPromptSheetState extends State<_StoryPromptSheet> {
  final _words = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _words.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await widget.onSubmit(_words.text.trim());
    if (!mounted) return;
    if (result.close) {
      Navigator.pop(context, result.text);
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.error;
    });
  }

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
              enabled: !_submitting,
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
              onFieldSubmitted: (_) => unawaited(_submit()),
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
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: NocheType.body.copyWith(color: NocheColors.label),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                NocheOutlineButton(
                  label: LibraryWording.cancel,
                  expand: false,
                  onPressed: _submitting ? null : widget.onCancel,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NochePrimaryButton(
                    label: LibraryWording.writeMyStory,
                    small: true,
                    onPressed: _submitting ? null : () => unawaited(_submit()),
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
