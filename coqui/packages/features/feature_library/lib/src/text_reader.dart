import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reader_page.dart';
import 'package:feature_library/src/reader_pagination.dart';
import 'package:feature_library/src/reader_settings_sheet.dart';
import 'package:feature_library/src/reading.dart';
import 'package:feature_library/src/reading_audio.dart';
import 'package:flutter/semantics.dart';
import 'package:material_ui/material_ui.dart';

/// The reader's own words (menus may be English).
abstract final class ReaderTexts {
  static const close = 'Close';
  static const audioUnavailable = 'No recording for this yet.';
  static const textUnavailable = 'This text is not available.';
  static const previousPage = 'Previous page';
  static const nextPage = 'Next page';
  static const finishBook = 'Finish book';
  static const textSize = 'Text and page';
}

class TextReader extends StatefulWidget {
  const TextReader({
    super.key,
    required this.services,
    required this.id,
    this.initialSettings,
    this.onOpenSettings,
    this.stageMax = defaultStageMax,
  });

  final Services services;
  final String id;
  final ReaderSettings? initialSettings;
  final Future<void> Function(
    ReaderSettings current,
    ValueChanged<ReaderSettings> onChanged,
  )?
  onOpenSettings;
  final int stageMax;

  @override
  State<TextReader> createState() => _TextReaderState();
}

typedef _WordIndex = ({
  Map<String, String> exact,
  Map<String, String> normalized,
});

class _TextReaderState extends State<TextReader>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Services get _s => widget.services;
  late final _store = ReadingStore(_s.storage(ReadingStore.space));
  late final _audio = ReadingAudio(_s.course);
  late final _courseWordIndex = _buildCourseWordIndex();
  late final _settingsStore = _s.storage('leer');
  final _viewportKey = GlobalKey();
  final _met = <String>{};

  late ReaderSettings _settings;
  late final ValueNotifier<ReaderSettings> _settingsNotifier;
  late final AnimationController _paletteController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  late ReaderPalette _fromPalette;
  late ReaderPalette _toPalette;
  late final AnimationController _aaController = AnimationController(
    vsync: this,
    value: 0.0,
  );
  bool _settingsOpen = false;
  ReaderDocument? _doc;
  List<ReaderPage> _pages = const [];
  int _pageIndex = 0;
  int _pageTurnId = 0;
  NocheFollowSide _pageTurnSide = NocheFollowSide.end;
  int? _pendingSavedPage;
  ({int chapterIndex, int paragraphIndex, int charOffset})? _pendingSavedAnchor;
  double? _lastWidth;
  double? _lastHeight;
  TextScaler? _lastScaler;
  ReaderSettings? _lastPaginatedSettings;

  int _playback = 0;
  bool _playing = false;
  int? _audioStartedAtMs;
  int _pendingListenedMs = 0;
  bool _hasUnsavedEarCredits = false;
  String? _activeSentenceId;
  String? _lastSentenceId;
  SelectedWord? _selectedWord;
  bool _missing = false;
  bool _loading = true;
  Future<void> _writes = Future.value();
  Future<void> _settingsWrites = Future.value();
  StreamSubscription<void>? _changes;

  ReaderPalette _currentPalette(NocheMotionData motion) {
    final curve = motion.reduced ? motion.enter : motion.travel;
    final t = curve.transform(_paletteController.value);
    return ReaderPalette.lerp(_fromPalette, _toPalette, t);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings =
        widget.initialSettings ?? ReaderSettings.loadFrom(_settingsStore);
    _fromPalette = _settings.palette;
    _toPalette = _settings.palette;
    _settingsNotifier = ValueNotifier<ReaderSettings>(_settings);
    _changes = _s.progress.changes.listen((_) {
      if (mounted) setState(() {});
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    final id = widget.id;
    ReaderDocument? doc;
    if (id.startsWith(personalBookPrefix)) {
      final saved = _store.text(id);
      if (saved == null) {
        if (mounted) {
          setState(() {
            _missing = true;
            _loading = false;
          });
        }
        return;
      }
      doc = ReaderDocument.fromPersonal(saved);
    } else {
      final Book? book;
      final Map<String, dynamic> story;
      try {
        book = await _s.course.book(id);
        story = await _s.course.story(id);
      } on Object {
        if (mounted) {
          setState(() {
            _missing = true;
            _loading = false;
          });
        }
        return;
      }
      if (!mounted) return;
      if (book == null || !book.readable) {
        setState(() {
          _missing = true;
          _loading = false;
        });
        return;
      }
      doc = ReaderDocument.fromCourseBook(book, story, _s.course);
    }

    final hasContent = doc.chapters.any((c) => c.paragraphs.isNotEmpty);
    if (!hasContent) {
      if (mounted) {
        setState(() {
          _missing = true;
          _loading = false;
        });
      }
      return;
    }

    final place = _store.place(id);
    if (!mounted) return;
    setState(() {
      _doc = doc;
      _pendingSavedPage = place.page;
      _pendingSavedAnchor =
          place.chapterIndex != null &&
              place.paragraphIndex != null &&
              place.charOffset != null
          ? (
              chapterIndex: place.chapterIndex!,
              paragraphIndex: place.paragraphIndex!,
              charOffset: place.charOffset!,
            )
          : null;
      _met.addAll(place.words);
      _loading = false;
      _lastWidth = null;
      _lastHeight = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      final wasPlaying = _playing || _activeSentenceId != null;
      _stopNarration();
      if (wasPlaying && mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playback++;
    _paletteController.dispose();
    _aaController.dispose();
    _settingsNotifier.dispose();
    unawaited(_changes?.cancel());
    _changes = null;
    _flushListeningProgress();
    unawaited(_s.clips.stop().catchError((Object _) {}));
    super.dispose();
  }

  void _ensurePaginated(double width, double height, TextScaler textScaler) {
    final doc = _doc;
    if (doc == null || width <= 0 || height <= 0) return;
    final contentWidth = math.max(40.0, width - 56.0);
    final contentHeight = height;

    final unchanged =
        _lastWidth == contentWidth &&
        _lastHeight == contentHeight &&
        _lastScaler == textScaler &&
        _lastPaginatedSettings != null &&
        _lastPaginatedSettings!.samePaginationAs(_settings) &&
        _pages.isNotEmpty;
    if (unchanged) return;

    final previousAnchor =
        _pages.isNotEmpty &&
            _pageIndex < _pages.length &&
            _pages[_pageIndex].slices.isNotEmpty
        ? _pages[_pageIndex].slices.first
        : null;

    final newPages = paginateDocument(
      doc: doc,
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      settings: _settings,
      language: _s.course.language,
      textScaler: textScaler,
    );

    _lastWidth = contentWidth;
    _lastHeight = contentHeight;
    _lastScaler = textScaler;
    _lastPaginatedSettings = _settings;
    _pages = newPages;

    final activeSentencePage =
        !_playing || _activeSentenceId == null || newPages.isEmpty
        ? null
        : _recordedSentences()
              .where((e) => e.sentence.id == _activeSentenceId)
              .firstOrNull;

    if (newPages.isEmpty) {
      _pageIndex = 0;
    } else if (_pendingSavedAnchor != null) {
      final anchor = _pendingSavedAnchor!;
      _pageIndex = pageForAnchor(
        newPages,
        chapterIndex: anchor.chapterIndex,
        paragraphIndex: anchor.paragraphIndex,
        charOffset: anchor.charOffset,
      );
      _pendingSavedAnchor = null;
      _pendingSavedPage = null;
    } else if (_pendingSavedPage != null) {
      _pageIndex = _pendingSavedPage!.clamp(0, newPages.length - 1);
      _pendingSavedPage = null;
    } else if (activeSentencePage != null) {
      _pageIndex = activeSentencePage.firstPage.clamp(0, newPages.length - 1);
    } else if (previousAnchor != null) {
      _pageIndex = pageForAnchor(
        newPages,
        chapterIndex: previousAnchor.chapterIndex,
        paragraphIndex: previousAnchor.paragraphIndex,
        charOffset: previousAnchor.charStart,
      );
    } else {
      _pageIndex = _pageIndex.clamp(0, newPages.length - 1);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _savePlace();
    });
  }

  void _savePlace({bool finished = false}) {
    final doc = _doc;
    if (doc == null || _pages.isEmpty) return;
    final clampedPage = _pageIndex.clamp(0, _pages.length - 1);
    final currentPage = _pages[clampedPage];

    if (tracksReading(_s.progress)) {
      final chapter = doc.chapters[currentPage.chapterIndex];
      for (final slice in currentPage.slices) {
        final sliceText = chapter.paragraphs[slice.paragraphIndex].text
            .substring(slice.charStart, slice.charEnd);
        _met.addAll(readingWords(sliceText, language: _s.course.language));
      }
    }

    final anchorSlice = currentPage.slices.isNotEmpty
        ? currentPage.slices.first
        : null;
    final place = ReadingPlace(
      page: clampedPage,
      words: Set.of(_met),
      openedAt: _s.clock.nowMs(),
      finished: finished,
      totalPages: _pages.length,
      chapterIndex: currentPage.chapterIndex,
      paragraphIndex: anchorSlice?.paragraphIndex,
      charOffset: anchorSlice?.charStart,
    );
    _writes = _writes
        .then<void>((_) => _store.savePlace(widget.id, place))
        .catchError((Object _) {});
  }

  void _updateSettings(ReaderSettings next) {
    if (!mounted || next == _settings) return;
    if (next.page != _settings.page) {
      final motion = NocheMotion.of(context);
      _fromPalette = _currentPalette(motion);
      _toPalette = next.palette;
      _paletteController.duration = motion.move;
      _paletteController.forward(from: 0.0);
    }
    setState(() {
      _settings = next;
      _selectedWord = null;
    });
    _settingsNotifier.value = next;
    _settingsWrites = _settingsWrites
        .then<void>((_) => next.saveTo(_settingsStore))
        .catchError((Object _) {});
  }

  void _beginAudioTiming() {
    if (_s.clips.muted) {
      _audioStartedAtMs = null;
      return;
    }
    _audioStartedAtMs = _s.clock.nowMs();
  }

  void _stopAudioTiming() {
    final startedAt = _audioStartedAtMs;
    _audioStartedAtMs = null;
    if (startedAt == null || _s.clips.muted) return;
    final elapsedMs = math.max(0, _s.clock.nowMs() - startedAt);
    if (elapsedMs > 0) {
      _pendingListenedMs += elapsedMs;
    }
  }

  void _finishAudioTiming(String clipId, {required bool played}) {
    final startedAt = _audioStartedAtMs;
    _audioStartedAtMs = null;
    if (!played || startedAt == null || _s.clips.muted) return;
    final elapsedMs = math.max(0, _s.clock.nowMs() - startedAt);
    if (elapsedMs > 0) {
      _pendingListenedMs += elapsedMs;
    } else {
      final clip = _s.course.clip(clipId);
      if (clip != null && clip.endMs > clip.startMs) {
        _pendingListenedMs += clip.endMs - clip.startMs;
      }
    }
  }

  void _flushListeningProgress() {
    _stopAudioTiming();
    if (_pendingListenedMs <= 0 && !_hasUnsavedEarCredits) return;
    final minutes = _pendingListenedMs / 6e4;
    _pendingListenedMs = 0;
    _hasUnsavedEarCredits = false;
    _s.progress.addMinutes(minutes);
  }

  void _stopNarration({bool clearActive = true}) {
    _playback++;
    if (_playing || (clearActive && _activeSentenceId != null)) {
      _playing = false;
      if (clearActive) _activeSentenceId = null;
    }
    _flushListeningProgress();
    unawaited(_s.clips.stop().catchError((Object _) {}));
  }

  void _setPageWithTurn(int nextIndex) {
    if (_pages.isEmpty) return;
    final clamped = nextIndex.clamp(0, _pages.length - 1);
    if (clamped != _pageIndex) {
      _pageTurnSide = clamped > _pageIndex
          ? NocheFollowSide.end
          : NocheFollowSide.start;
      _pageTurnId++;
      _pageIndex = clamped;
    }
  }

  void _turnToPage(int nextIndex) {
    if (_pages.isEmpty) return;
    _stopNarration();
    setState(() {
      _selectedWord = null;
      _activeSentenceId = null;
      _setPageWithTurn(nextIndex);
    });
    _savePlace();
  }

  void _turnForward() {
    if (_pages.isEmpty) return;
    if (_pageIndex >= _pages.length - 1) {
      _finishBook();
      return;
    }
    _turnToPage(_pageIndex + 1);
  }

  void _turnBackward() {
    if (_pages.isEmpty || _pageIndex <= 0) return;
    _turnToPage(_pageIndex - 1);
  }

  void _finishBook() {
    if (tracksReading(_s.progress)) _s.progress.markRead(widget.id);
    _stopNarration();
    _savePlace(finished: true);
    _s.nav.back();
  }

  void _close() {
    _stopNarration();
    _savePlace();
    _s.nav.back();
  }

  List<({int firstPage, int lastPage, ReaderSentence sentence})>
  _recordedSentences() {
    final doc = _doc;
    if (doc == null || _pages.isEmpty) return const [];
    final out = <({int firstPage, int lastPage, ReaderSentence sentence})>[];
    final byId = <String, int>{};
    for (final page in _pages) {
      final chapter = doc.chapters[page.chapterIndex];
      for (final slice in page.slices) {
        final paragraph = chapter.paragraphs[slice.paragraphIndex];
        for (final r in paragraph.sentenceRanges) {
          if (r.sentence.clipId == null) continue;
          if (r.end <= slice.charStart || r.start >= slice.charEnd) continue;
          final existingIndex = byId[r.sentence.id];
          if (existingIndex == null) {
            byId[r.sentence.id] = out.length;
            out.add((
              firstPage: page.pageIndex,
              lastPage: page.pageIndex,
              sentence: r.sentence,
            ));
          } else {
            final prev = out[existingIndex];
            out[existingIndex] = (
              firstPage: prev.firstPage,
              lastPage: math.max(prev.lastPage, page.pageIndex),
              sentence: prev.sentence,
            );
          }
        }
      }
    }
    return out;
  }

  static void _addToWordIndex(
    String word,
    Language lang,
    Map<String, String> exact,
    Map<String, String> normalized,
  ) {
    final trimmed = word.trim();
    if (trimmed.isEmpty) return;
    exact.putIfAbsent(trimmed.toLowerCase(), () => word);
    final exactKey = readingExactKey(trimmed, language: lang);
    if (exactKey.isNotEmpty) {
      exact.putIfAbsent(exactKey, () => word);
    }
    final norm = lang.normalize(trimmed).trim();
    if (norm.isNotEmpty) {
      normalized.putIfAbsent(norm, () => word);
    }
  }

  _WordIndex _buildCourseWordIndex() {
    final lang = _s.course.language;
    final exact = <String, String>{};
    final normalized = <String, String>{};
    final catalog = _s.course as Object;
    final review = catalog is RepasoCatalog ? catalog.repaso : null;
    for (final word in review?.words ?? const <RepasoWord>[]) {
      _addToWordIndex(word.word, lang, exact, normalized);
    }
    for (final pair in _s.course.pairs) {
      _addToWordIndex(pair.word, lang, exact, normalized);
    }
    for (final item in _s.course.levelItems) {
      _addToWordIndex(item.word, lang, exact, normalized);
    }
    return (exact: exact, normalized: normalized);
  }

  _WordIndex _progressWordIndex() {
    final lang = _s.course.language;
    final exact = <String, String>{};
    final normalized = <String, String>{};
    for (final existing in _s.progress.words) {
      _addToWordIndex(existing.w, lang, exact, normalized);
    }
    return (exact: exact, normalized: normalized);
  }

  String? _resolveFromIndex(String rawToken, _WordIndex index) {
    final lower = rawToken.toLowerCase();
    final exactHit = index.exact[lower];
    if (exactHit != null) return exactHit;
    final exactKey = readingExactKey(rawToken, language: _s.course.language);
    if (exactKey.isNotEmpty) {
      final keyHit = index.exact[exactKey];
      if (keyHit != null) return keyHit;
    }
    final norm = _s.course.language.normalize(rawToken).trim();
    if (norm.isNotEmpty) {
      final normHit = index.normalized[norm];
      if (normHit != null) return normHit;
    }
    return null;
  }

  String? _resolveProgressWord(String rawToken, _WordIndex index) =>
      _resolveFromIndex(rawToken, index);

  String? _resolveKnownWord(String rawToken, _WordIndex progressIndex) {
    final audioWord = _audio.word(rawToken)?.word;
    if (audioWord != null && audioWord.isNotEmpty) return audioWord;
    final progressWord = _resolveProgressWord(rawToken, progressIndex);
    if (progressWord != null && progressWord.isNotEmpty) return progressWord;
    return _resolveFromIndex(rawToken, _courseWordIndex);
  }

  void _creditWord(String word) {
    _s.progress.heard(word);
    _hasUnsavedEarCredits = true;
  }

  void _creditSentenceWords(ReaderSentence sentence) {
    final lang = _s.course.language;
    final index = _progressWordIndex();
    final keys = <String>{};
    for (final token in lang.tokens(sentence.text)) {
      final resolved = _resolveKnownWord(token.text, index);
      if (resolved != null && resolved.isNotEmpty) keys.add(resolved);
    }
    for (final key in keys) {
      _creditWord(key);
    }
  }

  Future<void> _toggleListen() async {
    if (_doc == null || !_doc!.hasAudio) return;
    if (_playing) {
      _playback++;
      _flushListeningProgress();
      unawaited(_s.clips.stop().catchError((Object _) {}));
      setState(() {
        _playing = false;
      });
      return;
    }

    final list = _recordedSentences();
    if (list.isEmpty) return;

    var startIdx = -1;
    if (_lastSentenceId != null) {
      final idx = list.indexWhere((e) => e.sentence.id == _lastSentenceId);
      if (idx >= 0 &&
          list[idx].firstPage <= _pageIndex &&
          _pageIndex <= list[idx].lastPage) {
        startIdx = idx;
      }
    }
    if (startIdx < 0) {
      startIdx = list.indexWhere((e) => e.lastPage >= _pageIndex);
    }
    if (startIdx < 0) startIdx = 0;

    final request = ++_playback;
    _flushListeningProgress();
    setState(() {
      _playing = true;
      _selectedWord = null;
    });

    try {
      await _s.clips.unlock();
      if (!mounted || request != _playback) return;
      await _s.clips.stop();
      if (!mounted || request != _playback) return;

      final sentenceIds = [for (final e in list) e.sentence.id];
      for (var i = startIdx; i < sentenceIds.length; i++) {
        if (!mounted || request != _playback) return;
        final item = _recordedSentences()
            .where((e) => e.sentence.id == sentenceIds[i])
            .firstOrNull;
        if (item == null) continue;
        setState(() {
          if (_pages.isNotEmpty &&
              (_pageIndex < item.firstPage || _pageIndex > item.lastPage)) {
            _setPageWithTurn(item.firstPage);
          }
          _activeSentenceId = item.sentence.id;
          _lastSentenceId = item.sentence.id;
        });
        _savePlace();

        final played = await _playPreparedClip(item.sentence.clipId!, request);
        if (!mounted || request != _playback) return;
        if (played && !_s.clips.muted) {
          _creditSentenceWords(item.sentence);
        }
        if (!played) break;
      }
    } on Object {
      // Playback failure must not count as an ear meeting or listening time.
      _audioStartedAtMs = null;
    }

    if (!mounted || request != _playback) return;
    _flushListeningProgress();
    setState(() {
      _playing = false;
      _activeSentenceId = null;
    });
  }

  Future<bool> _playPreparedClip(String clipId, int request) async {
    final missing = await _s.clips.preload([clipId]);
    if (!mounted || request != _playback) return false;
    if (missing.contains(clipId)) return false;
    _beginAudioTiming();
    final played = await _s.clips.play(clipId);
    if (!mounted || request != _playback) return false;
    _finishAudioTiming(clipId, played: played);
    return played;
  }

  Future<void> _repeatSentence() async {
    if (_doc == null || !_doc!.hasAudio) return;
    final list = _recordedSentences();
    if (list.isEmpty) return;

    var target = list
        .where((e) => e.sentence.id == _lastSentenceId)
        .firstOrNull;
    target ??= list
        .where((e) => e.firstPage <= _pageIndex && _pageIndex <= e.lastPage)
        .firstOrNull;
    target ??= list.where((e) => e.lastPage >= _pageIndex).firstOrNull;
    target ??= list.first;

    final request = ++_playback;
    _flushListeningProgress();
    setState(() {
      _playing = true;
      _selectedWord = null;
      if (_pageIndex < target!.firstPage || _pageIndex > target.lastPage) {
        _setPageWithTurn(target.firstPage);
      }
      _activeSentenceId = target.sentence.id;
      _lastSentenceId = target.sentence.id;
    });
    _savePlace();

    try {
      await _s.clips.unlock();
      if (!mounted || request != _playback) return;
      await _s.clips.stop();
      if (!mounted || request != _playback) return;
      final played = await _playPreparedClip(target.sentence.clipId!, request);
      if (!mounted || request != _playback) return;
      if (played && !_s.clips.muted) {
        _creditSentenceWords(target.sentence);
      }
    } on Object {
      // Ignore playback failures.
      _audioStartedAtMs = null;
    }

    if (!mounted || request != _playback) return;
    _flushListeningProgress();
    setState(() {
      _playing = false;
      _activeSentenceId = null;
    });
  }

  Future<void> _handleWordTap(
    int chapterIndex,
    int paragraphIndex,
    int charOffset,
    String token,
    Rect rectInViewport,
  ) async {
    final earIndex = ReaderEarIndex(
      _s.progress.words,
      _s.course.language,
      stageMax: widget.stageMax,
    );
    final wordMatch = _audio.word(token);
    final stage = earIndex.stageOf(token);

    _playback++;
    _flushListeningProgress();
    setState(() {
      _playing = false;
      _selectedWord = SelectedWord(
        chapterIndex: chapterIndex,
        paragraphIndex: paragraphIndex,
        charOffset: charOffset,
        token: token,
        rectInViewport: rectInViewport,
        stage: stage,
        clipId: wordMatch?.clip,
        audioWord: wordMatch?.word,
      );
    });

    await _playWordClip(wordMatch);
  }

  Future<void> _replaySelectedWord(SelectedWord selected) async {
    final clipId = selected.clipId;
    if (clipId == null) return;
    _playback++;
    _flushListeningProgress();
    setState(() => _playing = false);
    await _playWordClip((
      clip: clipId,
      word:
          selected.audioWord ??
          _resolveKnownWord(selected.token, _progressWordIndex()),
    ));
  }

  Future<void> _playWordClip(({String clip, String? word})? wordMatch) async {
    final request = _playback;
    if (wordMatch == null) {
      await _s.clips.stop().catchError((Object _) {});
      return;
    }
    var played = false;
    try {
      await _s.clips.unlock();
      if (!mounted || request != _playback) return;
      await _s.clips.stop();
      if (!mounted || request != _playback) return;
      played = await _playPreparedClip(wordMatch.clip, request);
    } on Object {
      // Ignore playback failures.
      _audioStartedAtMs = null;
    }
    if (!mounted || request != _playback) return;
    if (played && !_s.clips.muted) {
      final word = wordMatch.word;
      if (word != null && word.isNotEmpty) {
        _creditWord(word);
      }
    }
    _flushListeningProgress();
  }

  void _handleBodyTapUp(
    TapUpDetails details,
    double width,
    TextDirection textDirection,
  ) {
    if (_selectedWord != null) {
      setState(() => _selectedWord = null);
      return;
    }
    final fifth = width * 0.2;
    final x = details.localPosition.dx;
    if (x < fifth) {
      if (textDirection == TextDirection.rtl) {
        _turnForward();
      } else {
        _turnBackward();
      }
    } else if (x > width - fifth) {
      if (textDirection == TextDirection.rtl) {
        _turnBackward();
      } else {
        _turnForward();
      }
    }
  }

  void _handleHorizontalDragEnd(
    DragEndDetails details,
    TextDirection textDirection,
  ) {
    final vx = details.primaryVelocity ?? 0;
    if (vx.abs() < 150) return;
    final swipedLeft = vx < 0;
    final forward = textDirection == TextDirection.rtl
        ? !swipedLeft
        : swipedLeft;
    if (forward) {
      _turnForward();
    } else {
      _turnBackward();
    }
  }

  Future<void> _openSettings() async {
    if (_settingsOpen) return;
    final motion = NocheMotion.of(context);
    setState(() {
      _settingsOpen = true;
      _selectedWord = null;
    });
    unawaited(
      _aaController.animateTo(1.0, duration: motion.quick, curve: motion.enter),
    );
    try {
      if (widget.onOpenSettings != null) {
        await widget.onOpenSettings!(_settings, _updateSettings);
        return;
      }
      final lang = _s.course.language;
      await showReaderSettingsSheet<void>(
        context,
        closeLabel: NocheA11y.label(
          NocheA11y.closeTextAndPage,
          courseWords: lang.a11yWords,
        ),
        builder: (context, close) => ValueListenableBuilder<ReaderSettings>(
          valueListenable: _settingsNotifier,
          builder: (context, current, _) => ReaderSettingsSheet(
            settings: current,
            language: lang,
            onChanged: _updateSettings,
          ),
        ),
      );
    } finally {
      if (mounted) {
        final closeMotion = NocheMotion.of(context);
        setState(() => _settingsOpen = false);
        unawaited(
          _aaController.animateTo(
            0.0,
            duration: closeMotion.quick,
            curve: closeMotion.enter,
          ),
        );
      }
    }
  }

  Future<void> _openChapters() async {
    final doc = _doc;
    if (doc == null || _pages.isEmpty) return;
    final lang = _s.course.language;
    final courseDir = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final currentChapter = _pages[_pageIndex].chapterIndex;
    final locale = Locale(lang.code);

    await showNocheSheet<void>(
      context,
      title: NocheA11y.label(NocheA11y.chapters, courseWords: lang.a11yWords),
      closeLabel: NocheA11y.label(
        NocheA11y.closeSheet,
        courseWords: lang.a11yWords,
      ),
      builder: (context, close) => Directionality(
        textDirection: courseDir,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < doc.chapters.length; i++)
              _ChapterRow(
                chapter: doc.chapters[i],
                selected: i == currentChapter,
                language: lang,
                locale: locale,
                showTopBorder: i > 0,
                onPressed: () {
                  close();
                  final targetPage = _pages.indexWhere(
                    (p) => p.chapterIndex == i,
                  );
                  if (targetPage >= 0) {
                    _turnToPage(targetPage);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _s.course.language;
    final textDirection = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final locale = Locale(lang.code);

    return AnimatedBuilder(
      animation: _paletteController,
      builder: (context, _) {
        final motion = NocheMotion.of(context);
        final palette = _currentPalette(motion);

        final backButton = Tooltip(
          message: ReaderTexts.close,
          child: Pressable(
            key: const Key('reader-close-button'),
            disc: true,
            onPressed: _close,
            semanticLabel: NocheA11y.label(
              NocheA11y.back,
              courseWords: lang.a11yWords,
            ),
            builder: (context, _) => SizedBox(
              width: NocheSize.touch,
              height: NocheSize.touch,
              child: Center(
                child: NocheIcon(
                  NocheIcons.back,
                  size: 24,
                  strokeWidth: 2.2,
                  color: palette.chromeIcon,
                ),
              ),
            ),
          ),
        );

        if (_missing) {
          return Directionality(
            textDirection: textDirection,
            child: Material(
              color: palette.ground,
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 4,
                        ),
                        child: Row(children: [backButton]),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 28,
                          ),
                          child: Text(
                            ReaderTexts.textUnavailable,
                            textAlign: TextAlign.center,
                            style: NocheType.body.copyWith(
                              color: palette.label,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (_loading || _doc == null) {
          return Directionality(
            textDirection: textDirection,
            child: Material(
              color: palette.ground,
              child: const SizedBox.expand(),
            ),
          );
        }

        final doc = _doc!;
        final earIndex = ReaderEarIndex(
          _s.progress.words,
          lang,
          stageMax: widget.stageMax,
        );

        return Directionality(
          textDirection: textDirection,
          child: Material(
            color: palette.ground,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          backButton,
                          Expanded(
                            child: Text(
                              doc.title.toUpperCase(),
                              key: const Key('reader-book-title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              locale: locale,
                              style:
                                  NocheType.forScript(
                                    NocheType.label,
                                    lang.script,
                                  ).copyWith(
                                    color: palette.label,
                                    letterSpacing: lang.script == 'Latn'
                                        ? 1.2
                                        : 0,
                                  ),
                            ),
                          ),
                          Pressable(
                            key: const Key('reader-aa-button'),
                            disc: true,
                            onPressed: _openSettings,
                            semanticLabel: NocheA11y.label(
                              NocheA11y.textAndPage,
                              courseWords: lang.a11yWords,
                            ),
                            selected: _settingsOpen ? true : null,
                            builder: (context, _) => AnimatedBuilder(
                              animation: _aaController,
                              builder: (context, _) {
                                final openT = _aaController.value;
                                return Container(
                                  key: const Key('reader-aa-button-surface'),
                                  width: NocheSize.touch,
                                  height: NocheSize.touch,
                                  alignment: AlignmentDirectional.center,
                                  decoration: BoxDecoration(
                                    color: palette.chromeIcon.withValues(
                                      alpha: palette.chromeIcon.a * openT,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    'Aa',
                                    key: const Key('reader-aa-button-label'),
                                    style: NocheType.bookTitle.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                      height: 1,
                                      color: Color.lerp(
                                        palette.chromeIcon,
                                        palette.ground,
                                        openT,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Pressable(
                            disc: true,
                            onPressed: _openChapters,
                            semanticLabel: NocheA11y.label(
                              NocheA11y.chapters,
                              courseWords: lang.a11yWords,
                            ),
                            builder: (context, _) => SizedBox(
                              width: NocheSize.touch,
                              height: NocheSize.touch,
                              child: Center(
                                child: NocheIcon(
                                  NocheIcons.chapters,
                                  size: 24,
                                  strokeWidth: 2.2,
                                  color: palette.chromeIcon,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final textScaler = MediaQuery.textScalerOf(context);
                        _ensurePaginated(
                          constraints.maxWidth,
                          constraints.maxHeight,
                          textScaler,
                        );
                        if (_pages.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final currentPage = _pages[_pageIndex];
                        final viewportSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final isLastPage = _pageIndex >= _pages.length - 1;
                        return Semantics(
                          container: true,
                          onIncrease: _turnForward,
                          onDecrease: _pageIndex > 0 ? _turnBackward : null,
                          customSemanticsActions: {
                            if (_pageIndex > 0)
                              const CustomSemanticsAction(
                                label: ReaderTexts.previousPage,
                              ): _turnBackward,
                            CustomSemanticsAction(
                              label: isLastPage
                                  ? ReaderTexts.finishBook
                                  : ReaderTexts.nextPage,
                            ): _turnForward,
                          },
                          child: GestureDetector(
                            key: _viewportKey,
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) => _handleBodyTapUp(
                              details,
                              constraints.maxWidth,
                              textDirection,
                            ),
                            onHorizontalDragEnd: (details) =>
                                _handleHorizontalDragEnd(
                                  details,
                                  textDirection,
                                ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: NocheFollow(
                                    key: const Key('reader-page-follow'),
                                    contentKey: _pageTurnId,
                                    side: _pageTurnSide,
                                    distance: NocheMotion.page,
                                    child: SizedBox.expand(
                                      child: ReaderPageView(
                                        document: doc,
                                        page: currentPage,
                                        settings: _settings,
                                        palette: palette,
                                        language: lang,
                                        earIndex: earIndex,
                                        activeSentenceId: _activeSentenceId,
                                        selectedWord: _selectedWord,
                                        viewportKey: _viewportKey,
                                        onWordTap: (c, p, offset, tok, rect) =>
                                            unawaited(
                                              _handleWordTap(
                                                c,
                                                p,
                                                offset,
                                                tok,
                                                rect,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                                ReaderWordBubbleOverlay(
                                  selected: _selectedWord,
                                  viewportSize: viewportSize,
                                  settings: _settings,
                                  palette: palette,
                                  language: lang,
                                  stageMax: widget.stageMax,
                                  onReplay: (selected) =>
                                      unawaited(_replaySelectedWord(selected)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildFooter(context, doc, lang, palette),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ReaderDocument doc,
    Language lang,
    ReaderPalette palette,
  ) {
    final motion = NocheMotion.of(context);
    final total = math.max(1, _pages.length);
    final current = _pages.isEmpty ? 1 : _pageIndex + 1;
    final minLeft = _pages.isEmpty
        ? 1
        : _pages[_pageIndex].minutesLeftInChapter;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(28, 12, 28, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                readOnly: true,
                label: NocheA11y.label(
                  NocheA11y.pageProgress,
                  courseWords: lang.a11yWords,
                  args: {'current': '$current', 'total': '$total'},
                ),
                child: ExcludeSemantics(
                  child: NocheLtr(
                    child: Text(
                      '$current / $total',
                      key: const Key('reader-page-counter'),
                      style: NocheType.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.label,
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                readOnly: true,
                label: NocheA11y.label(
                  NocheA11y.minutesRemaining,
                  courseWords: lang.a11yWords,
                  args: {'minutes': '$minLeft'},
                ),
                child: ExcludeSemantics(
                  child: NocheLtr(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NocheIcon(
                          NocheIcons.clock,
                          size: 14,
                          strokeWidth: 2.4,
                          color: palette.label,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$minLeft min',
                          style: NocheType.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: palette.label,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey('reader-progress-bar-anim:${_pages.isNotEmpty}'),
            tween: Tween<double>(end: current / total),
            duration: motion.reduced ? Duration.zero : motion.move,
            curve: motion.travel,
            builder: (context, animatedValue, _) => NocheProgressBar(
              value: animatedValue,
              height: 4,
              trackColor: palette.track,
              color: palette.label,
            ),
          ),
          if (doc.hasAudio) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Pressable(
                  disc: true,
                  onPressed: () => unawaited(_repeatSentence()),
                  semanticLabel: NocheA11y.label(
                    NocheA11y.sentenceAgain,
                    courseWords: lang.a11yWords,
                  ),
                  builder: (context, _) => Container(
                    width: NocheSize.touch,
                    height: NocheSize.touch,
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.rule, width: 1),
                    ),
                    child: NocheIcon(
                      NocheIcons.sentenceAgain,
                      size: 22,
                      strokeWidth: 2.2,
                      color: palette.chromeIcon,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                _ReaderPlayDisc(
                  playing: _playing,
                  semanticLabel: NocheA11y.label(
                    _playing ? NocheA11y.pause : NocheA11y.listen,
                    courseWords: lang.a11yWords,
                  ),
                  onPressed: () => unawaited(_toggleListen()),
                ),
                const SizedBox(width: 32),
                Pressable(
                  disc: true,
                  onPressed: () => _updateSettings(_settings.cycleSpeed()),
                  semanticLabel:
                      '${NocheA11y.label(NocheA11y.speed, courseWords: lang.a11yWords)}: ${_settings.speedLabel}',
                  builder: (context, _) => Container(
                    width: NocheSize.touch,
                    height: NocheSize.touch,
                    alignment: AlignmentDirectional.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.rule, width: 1),
                    ),
                    child: NocheLtr(
                      child: Text(
                        _settings.speedLabel,
                        style: NocheType.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1,
                          color: palette.chromeIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReaderPlayDisc extends StatelessWidget {
  const _ReaderPlayDisc({
    required this.playing,
    required this.semanticLabel,
    required this.onPressed,
  });

  final bool playing;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final motion = NocheMotion.of(context);
    return Pressable(
      key: const Key('reader-play-disc'),
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      disc: true,
      builder: (context, _) => Container(
        width: NocheSize.disc,
        height: NocheSize.disc,
        alignment: AlignmentDirectional.center,
        decoration: const BoxDecoration(
          color: NocheColors.next,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            AnimatedOpacity(
              key: const Key('reader-play-icon'),
              opacity: playing ? 0.0 : 1.0,
              duration: motion.quick,
              curve: motion.enter,
              child: const NocheIcon(
                NocheIcons.play,
                size: 28,
                color: NocheColors.onAccent,
              ),
            ),
            AnimatedOpacity(
              key: const Key('reader-pause-icon'),
              opacity: playing ? 1.0 : 0.0,
              duration: motion.quick,
              curve: motion.enter,
              child: const NocheIcon(
                NocheIcons.pause,
                size: 26,
                color: NocheColors.onAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.selected,
    required this.language,
    required this.locale,
    required this.showTopBorder,
    required this.onPressed,
  });

  final ReaderChapterDoc chapter;
  final bool selected;
  final Language language;
  final Locale locale;
  final bool showTopBorder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final courseDir = language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final hasLabel = chapter.label != null && chapter.label!.trim().isNotEmpty;
    final labelText = hasLabel
        ? '${chapter.label} · ${chapter.title}'
        : chapter.title;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: labelText,
      selected: selected,
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsetsDirectional.symmetric(vertical: 8),
        decoration: showTopBorder
            ? const BoxDecoration(
                border: Border(
                  top: BorderSide(color: NocheColors.line, width: 1),
                ),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasLabel) ...[
                    Text(
                      chapter.label!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: courseDir,
                      locale: locale,
                      style: NocheType.forScript(
                        NocheType.label,
                        language.script,
                      ).copyWith(color: NocheColors.label),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    chapter.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: courseDir,
                    locale: locale,
                    style: NocheType.forScript(
                      NocheType.row,
                      language.script,
                    ).copyWith(color: NocheColors.text),
                  ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              Container(
                width: 32,
                height: 32,
                alignment: AlignmentDirectional.center,
                decoration: const BoxDecoration(
                  color: NocheColors.text,
                  shape: BoxShape.circle,
                ),
                child: const NocheIcon(
                  NocheIcons.check,
                  size: 18,
                  color: NocheColors.ground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
