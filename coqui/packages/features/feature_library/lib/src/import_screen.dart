import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/book_coverage.dart';
import 'package:feature_library/src/book_importer.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/wording.dart';
import 'package:material_ui/material_ui.dart';

/// Full-screen importer for adding the learner's own books and texts (`ImportRoute`).
class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.services,
    this.filePicker,
    this.stepYield,
    this.initialJobs = const [],
    this.initialErrors = const [],
  });

  final Services services;
  final ImportFilePicker? filePicker;
  final Future<void> Function()? stepYield;
  final List<ImportJobState> initialJobs;
  final List<ImportErrorItem> initialErrors;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  Services get _s => widget.services;
  late ReadingStore _store = ReadingStore(_s.storage(ReadingStore.space));
  late List<ReadingText> _books = _loadBooks();
  late final List<ImportJobState> _jobs = List<ImportJobState>.of(
    widget.initialJobs,
  );
  late final List<ImportErrorItem> _errors = List<ImportErrorItem>.of(
    widget.initialErrors,
  );
  final Map<String, BookCoverage> _coverageCache = {};
  StreamSubscription<void>? _changes;
  int _jobCounter = 0;
  bool _picking = false;

  BookCoverage _coverageFor(ReadingText book, Language lang) =>
      _coverageCache.putIfAbsent(
        book.id,
        () => coverageOfText(book, _s.progress.words, lang),
      );

  List<ReadingText> _loadBooks() {
    final raw = _store.texts().where((t) => !t.generated).toList();
    final indexed = [
      for (var i = 0; i < raw.length; i++)
        (index: i, book: raw[i], importedAt: raw[i].importedAt ?? 0),
    ];
    indexed.sort((a, b) {
      final byTime = b.importedAt.compareTo(a.importedAt);
      return byTime != 0 ? byTime : a.index.compareTo(b.index);
    });
    return [for (final item in indexed) item.book];
  }

  void _listenProgress() {
    unawaited(_changes?.cancel());
    _changes = _s.progress.changes.listen((_) {
      if (mounted) {
        setState(() {
          _coverageCache.clear();
          _books = _loadBooks();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _listenProgress();
  }

  @override
  void didUpdateWidget(ImportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.services != oldWidget.services) {
      _store = ReadingStore(_s.storage(ReadingStore.space));
      _coverageCache.clear();
      _books = _loadBooks();
      _listenProgress();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _books = _loadBooks();
    }
  }

  @override
  void dispose() {
    unawaited(_changes?.cancel());
    super.dispose();
  }

  BookImporter _makeImporter() => BookImporter(
    store: _store,
    progress: _s.progress,
    language: _s.course.language,
    clock: _s.clock,
    stepYield: widget.stepYield,
  );

  String _nextJobId() => 'import-job-${++_jobCounter}';

  void _upsertJob(ImportJobState state) {
    if (!mounted) return;
    setState(() {
      final idx = _jobs.indexWhere((j) => j.id == state.id);
      if (idx >= 0) {
        _jobs[idx] = state;
      } else {
        _jobs.insert(0, state);
      }
    });
  }

  void _finishJobSuccess(
    String jobId, {
    required String bookId,
    required BookCoverage coverage,
  }) {
    if (!mounted) return;
    setState(() {
      _jobs.removeWhere((j) => j.id == jobId);
      _coverageCache[bookId] = coverage;
      _books = _loadBooks();
    });
  }

  void _finishJobError(
    String jobId, {
    required String fileName,
    required String reason,
    bool locked = false,
  }) {
    if (!mounted) return;
    setState(() {
      _jobs.removeWhere((j) => j.id == jobId);
      _errors.insert(
        0,
        ImportErrorItem(
          id: jobId,
          fileName: fileName,
          reason: reason,
          locked: locked,
        ),
      );
    });
  }

  Future<void> _chooseFile() async {
    if (_picking) return;
    final picker = widget.filePicker;
    if (picker == null) {
      setState(() {
        _errors.removeWhere(
          (e) => e.reason == LibraryWording.errorPickerUnavailable,
        );
        _errors.insert(
          0,
          ImportErrorItem(
            id: _nextJobId(),
            fileName: LibraryWording.chooseFileButton,
            reason: LibraryWording.errorPickerUnavailable,
          ),
        );
      });
      return;
    }

    _picking = true;
    final PickedImportFile? picked;
    try {
      picked = await picker.pick(allowedExtensions: supportedImportExtensions);
    } on Object {
      _picking = false;
      if (!mounted) return;
      _finishJobError(
        _nextJobId(),
        fileName: LibraryWording.chooseFileButton,
        reason: LibraryWording.errorCouldNotOpen,
      );
      return;
    }
    _picking = false;
    if (picked == null || !mounted) return;

    final jobId = _nextJobId();
    final importer = _makeImporter();
    try {
      final result = await importer.importFile(
        picked,
        jobId: jobId,
        onProgress: _upsertJob,
      );
      _finishJobSuccess(
        jobId,
        bookId: result.book.id,
        coverage: result.coverage,
      );
    } on ImportFailure catch (e) {
      _finishJobError(
        jobId,
        fileName: picked.name,
        reason: e.reason,
        locked: e.locked,
      );
    } on Object {
      _finishJobError(
        jobId,
        fileName: picked.name,
        reason: LibraryWording.errorCouldNotOpen,
      );
    }
  }

  Future<void> _openPasteScreen() async {
    final result = await Navigator.of(context).push<PasteTextResult>(
      MaterialPageRoute<PasteTextResult>(
        builder: (_) => PasteTextScreen(language: _s.course.language),
      ),
    );
    if (result == null || !mounted) return;

    final jobId = _nextJobId();
    final displayName =
        (result.title != null && result.title!.trim().isNotEmpty)
        ? result.title!.trim()
        : LibraryWording.pasteTextTile;
    final importer = _makeImporter();
    try {
      final imported = await importer.importPastedText(
        rawText: result.text,
        title: result.title,
        jobId: jobId,
        onProgress: _upsertJob,
      );
      _finishJobSuccess(
        jobId,
        bookId: imported.book.id,
        coverage: imported.coverage,
      );
    } on ImportFailure catch (e) {
      _finishJobError(
        jobId,
        fileName: displayName,
        reason: e.reason,
        locked: e.locked,
      );
    } on Object {
      _finishJobError(
        jobId,
        fileName: displayName,
        reason: LibraryWording.errorCouldNotAdd,
      );
    }
  }

  Future<void> _openBook(ReadingText book) async {
    _s.haptics.tick();
    unawaited(_s.clips.unlock());
    await _store
        .markOpened(book.id, _s.clock.nowMs())
        .catchError((Object _) {});
    if (!mounted) return;
    _s.nav.go(BookRoute(book.id));
  }

  @override
  Widget build(BuildContext context) {
    final lang = _s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final pad = MediaQuery.paddingOf(context);
    final locale = Locale(lang.code);

    final header = Padding(
      padding: EdgeInsetsDirectional.only(top: pad.top),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 16, 0),
          child: Row(
            children: [
              Pressable(
                onPressed: () => _s.nav.back(),
                semanticLabel: LibraryWording.importClose,
                disc: true,
                builder: (context, _) => const SizedBox(
                  width: NocheSize.touch,
                  height: NocheSize.touch,
                  child: Center(
                    child: NocheIcon(
                      NocheIcons.close,
                      size: 24,
                      strokeWidth: 2.4,
                      color: NocheColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    LibraryWording.importTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NocheType.pageTitle.copyWith(
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

    final body = SingleChildScrollView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            LibraryWording.importIntro(supportedImportFormats),
            style: NocheType.body.copyWith(color: NocheColors.label),
          ),
          if (_jobs.isNotEmpty) ...[
            const SizedBox(height: 24),
            const NocheSectionLabel(
              LibraryWording.addingNowHeading,
              bottomGap: 12,
            ),
            for (var i = 0; i < _jobs.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _AddingNowCard(job: _jobs[i]),
            ],
          ],
          if (_books.isNotEmpty) ...[
            const SizedBox(height: 24),
            const NocheSectionLabel(LibraryWording.readyHeading, bottomGap: 12),
            for (var i = 0; i < _books.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ReadyBookCard(
                book: _books[i],
                place: _store.place(_books[i].id),
                coverage: _coverageFor(_books[i], lang),
                language: lang,
                locale: locale,
                onPressed: () => _openBook(_books[i]),
              ),
            ],
          ],
          if (_errors.isNotEmpty) ...[
            SizedBox(height: _books.isNotEmpty || _jobs.isNotEmpty ? 12 : 24),
            for (var i = 0; i < _errors.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _ImportErrorCard(error: _errors[i]),
            ],
          ],
        ],
      ),
    );

    final foot = Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24 + pad.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PasteTextTile(onPressed: _openPasteScreen),
          const SizedBox(height: 12),
          NochePrimaryButton(
            label: LibraryWording.chooseFileButton,
            small: true,
            onPressed: _chooseFile,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(child: body),
              foot,
            ],
          ),
        ),
      ),
    );
  }
}

class _AddingNowCard extends StatelessWidget {
  const _AddingNowCard({required this.job});

  final ImportJobState job;

  double _dashValue(int index) {
    final stepNumber = index + 1;
    if (stepNumber < job.step) return 1.0;
    if (stepNumber == job.step) return job.stepProgress.clamp(0.0, 1.0);
    return 0.0;
  }

  String _stepDetail() {
    switch (job.step) {
      case 1:
        return LibraryWording.stepOpeningDetail;
      case 2:
        if (job.pagesDone != null &&
            job.pagesTotal != null &&
            job.pagesTotal! > 0) {
          return LibraryWording.stepReadingPagesDetail(
            job.pagesDone!,
            job.pagesTotal!,
          );
        }
        return LibraryWording.stepReadingDetail;
      default:
        return LibraryWording.stepCheckingDetail;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NocheCard(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  job.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.rowTitle.copyWith(color: NocheColors.text),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                LibraryWording.formatFileSize(job.byteSize),
                maxLines: 1,
                softWrap: false,
                style: NocheType.label.copyWith(
                  letterSpacing: 0,
                  height: 20 / 12,
                  color: NocheColors.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: LibraryWording.stepSemanticLabel(job.step),
            readOnly: true,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: NocheProgressBar(
                        value: _dashValue(i),
                        color: NocheColors.text,
                        trackColor: NocheColors.line,
                        height: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: NocheType.body.copyWith(color: NocheColors.label),
              children: [
                TextSpan(
                  text: '${LibraryWording.stepOfTotal(job.step)} ',
                  style: NocheType.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: NocheColors.text,
                  ),
                ),
                TextSpan(text: _stepDetail()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyBookCard extends StatelessWidget {
  const _ReadyBookCard({
    required this.book,
    required this.place,
    required this.coverage,
    required this.language,
    required this.locale,
    required this.onPressed,
  });

  final ReadingText book;
  final ReadingPlace place;
  final BookCoverage coverage;
  final Language language;
  final Locale locale;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final pages =
        place.totalPages ??
        book.estimatedPages ??
        estimateBookPagesFromText(book, language);
    final metaLine = LibraryWording.bookMetaLine(
      format: book.format ?? LibraryWording.formatTxt,
      pages: pages,
      chapters: book.chapters?.length,
    );

    return NocheCard(
      padding: const EdgeInsetsDirectional.all(16),
      onPressed: onPressed,
      semanticLabel:
          '${book.title}. $metaLine. ${coverage.headline} ${coverage.phrase}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NocheCover(
            bookId: book.id,
            title: book.title,
            size: NocheCoverSize.small,
            script: language.script,
            locale: locale,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  locale: locale,
                  style: NocheType.forScript(
                    NocheType.rowTitle,
                    language.script,
                  ).copyWith(color: NocheColors.text),
                ),
                const SizedBox(height: 4),
                Text(
                  metaLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.bodySmall.copyWith(color: NocheColors.label),
                ),
                const SizedBox(height: 12),
                BookCoverageSummary(coverage: coverage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportErrorCard extends StatelessWidget {
  const _ImportErrorCard({required this.error});

  final ImportErrorItem error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: NocheColors.text, width: 1),
        borderRadius: BorderRadius.circular(NocheSize.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          NocheIcon(
            error.locked ? NocheIcons.lock : NocheIcons.library,
            size: 24,
            color: NocheColors.text,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NocheType.rowTitle.copyWith(
                    fontSize: 15,
                    height: 20 / 15,
                    color: NocheColors.text,
                  ),
                ),
                Text(
                  error.reason,
                  style: NocheType.bodySmall.copyWith(
                    height: 18 / 13,
                    color: NocheColors.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasteTextTile extends StatelessWidget {
  const _PasteTextTile({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      semanticLabel: LibraryWording.pasteTextTile,
      builder: (context, _) => Container(
        height: 64,
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: NocheColors.panel,
          border: Border.all(color: NocheColors.line, width: 1),
          borderRadius: BorderRadius.circular(NocheSize.tileRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NocheIcon(NocheIcons.clipboard, size: 22, color: NocheColors.text),
            const SizedBox(height: 6),
            Text(
              LibraryWording.pasteTextTile,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NocheType.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                height: 1,
                color: NocheColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Value returned from [PasteTextScreen] when the learner confirms pasting text.
typedef PasteTextResult = ({String? title, String text});

/// Full-screen input opened from the "Paste text" tile on [ImportScreen].
class PasteTextScreen extends StatefulWidget {
  const PasteTextScreen({super.key, required this.language});

  final Language language;

  @override
  State<PasteTextScreen> createState() => _PasteTextScreenState();
}

class _PasteTextScreenState extends State<PasteTextScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_onBodyChanged);
  }

  void _onBodyChanged() {
    final next = _bodyController.text.trim().isNotEmpty;
    if (next != _hasText) {
      setState(() => _hasText = next);
    }
  }

  @override
  void dispose() {
    _bodyController.removeListener(_onBodyChanged);
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _bodyController.text;
    if (text.trim().isEmpty) return;
    final rawTitle = _titleController.text.trim();
    Navigator.of(context).pop<PasteTextResult>((
      title: rawTitle.isEmpty ? null : rawTitle,
      text: text,
    ));
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

    final inputTextStyle = fieldStyle(
      NocheType.forScript(NocheType.body, widget.language.script),
      NocheColors.text,
    );

    return Directionality(
      textDirection: courseDirection,
      child: Scaffold(
        backgroundColor: NocheColors.ground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 16, 0),
                  child: Row(
                    children: [
                      Pressable(
                        onPressed: () => Navigator.of(context).pop(),
                        semanticLabel: LibraryWording.importClose,
                        disc: true,
                        builder: (context, _) => const SizedBox(
                          width: NocheSize.touch,
                          height: NocheSize.touch,
                          child: Center(
                            child: NocheIcon(
                              NocheIcons.close,
                              size: 24,
                              strokeWidth: 2.4,
                              color: NocheColors.text,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            LibraryWording.pasteScreenTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NocheType.pageTitle.copyWith(
                              color: NocheColors.text,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        cursorColor: NocheColors.next,
                        textDirection: courseDirection,
                        style: inputTextStyle,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: NocheColors.panel,
                          labelText: LibraryWording.pasteTitleLabel,
                          labelStyle: fieldStyle(
                            NocheType.body,
                            NocheColors.label,
                          ),
                          floatingLabelStyle: fieldStyle(
                            NocheType.label,
                            NocheColors.text,
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
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _bodyController,
                          expands: true,
                          maxLines: null,
                          minLines: null,
                          textAlignVertical: TextAlignVertical.top,
                          cursorColor: NocheColors.next,
                          textDirection: courseDirection,
                          style: inputTextStyle,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: NocheColors.panel,
                            hintText: LibraryWording.pasteBodyHint,
                            hintStyle: fieldStyle(
                              NocheType.body,
                              NocheColors.label,
                            ),
                            alignLabelWithHint: true,
                            contentPadding: const EdgeInsetsDirectional.all(16),
                            border: border,
                            enabledBorder: border,
                            focusedBorder: focusedBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
                child: NochePrimaryButton(
                  label: LibraryWording.pasteAddButton,
                  small: true,
                  onPressed: _hasText ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
