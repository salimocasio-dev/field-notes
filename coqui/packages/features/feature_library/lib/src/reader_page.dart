import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:feature_library/src/reader_pagination.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

class SelectedWord {
  const SelectedWord({
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charOffset,
    required this.token,
    required this.rectInViewport,
    required this.stage,
    required this.clipId,
    this.audioWord,
  });

  final int chapterIndex;
  final int paragraphIndex;
  final int charOffset;
  final String token;
  final Rect rectInViewport;
  final int stage;
  final String? clipId;
  final String? audioWord;
}

class ReaderPageView extends StatelessWidget {
  const ReaderPageView({
    super.key,
    required this.document,
    required this.page,
    required this.settings,
    this.palette,
    required this.language,
    required this.earIndex,
    required this.activeSentenceId,
    required this.selectedWord,
    required this.viewportKey,
    required this.onWordTap,
  });

  final ReaderDocument document;
  final ReaderPage page;
  final ReaderSettings settings;
  final ReaderPalette? palette;
  final Language language;
  final ReaderEarIndex earIndex;
  final String? activeSentenceId;
  final SelectedWord? selectedWord;
  final GlobalKey viewportKey;
  final void Function(
    int chapterIndex,
    int paragraphIndex,
    int charOffset,
    String token,
    Rect rectInViewport,
  )
  onWordTap;

  @override
  Widget build(BuildContext context) {
    final activePalette = palette ?? settings.palette;
    final chapter = document.chapters[page.chapterIndex];
    final hasLabel = chapter.label != null && chapter.label!.trim().isNotEmpty;
    final hasTitle = chapter.title.trim().isNotEmpty;
    final showHeader = page.isChapterStart && (hasLabel || hasTitle);
    final locale = Locale(language.code);
    final textDirection = language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasLabel)
                      Text(
                        chapter.label!.toUpperCase(),
                        key: const Key('reader-chapter-label'),
                        textAlign: TextAlign.center,
                        textDirection: textDirection,
                        locale: locale,
                        style: chapterLabelStyleFor(
                          language,
                          activePalette.label,
                        ),
                      ),
                    if (hasLabel && hasTitle) const SizedBox(height: 8),
                    if (hasTitle)
                      Text(
                        chapter.title,
                        key: const Key('reader-chapter-title'),
                        textAlign: TextAlign.center,
                        textDirection: textDirection,
                        locale: locale,
                        style: chapterTitleStyleFor(
                          language,
                          activePalette.heading,
                        ),
                      ),
                    Container(
                      key: const Key('reader-chapter-rule'),
                      width: 32,
                      height: 1,
                      margin: const EdgeInsetsDirectional.only(
                        top: 20,
                        bottom: 24,
                      ),
                      color: activePalette.rule,
                    ),
                  ],
                ),
              ),
            for (final slice in page.slices)
              _buildSlice(
                context,
                chapter.paragraphs[slice.paragraphIndex],
                slice,
                activePalette,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlice(
    BuildContext context,
    ReaderParagraph paragraph,
    PageParagraphSlice slice,
    ReaderPalette activePalette,
  ) {
    final locale = Locale(language.code);
    final paragraphText = paragraph.text;

    if (slice.hasDropCap && slice.dropCapBesideEnd != null) {
      final firstEnd = firstGraphemeEnd(paragraphText).clamp(1, slice.charEnd);
      final besideEnd = slice.dropCapBesideEnd!.clamp(firstEnd, slice.charEnd);
      final firstChar = paragraphText.substring(0, firstEnd);
      final besideText = paragraphText.substring(firstEnd, besideEnd);
      final restText = besideEnd < slice.charEnd
          ? paragraphText.substring(besideEnd, slice.charEnd)
          : '';
      final tokens = language.tokens(paragraphText);
      final firstToken = tokens.isNotEmpty && tokens.first.start == 0
          ? tokens.first.text
          : firstChar;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (dropContext) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final rect = _contextRectInViewport(
                      dropContext,
                      viewportKey,
                    );
                    if (rect != null) {
                      onWordTap(
                        slice.chapterIndex,
                        slice.paragraphIndex,
                        0,
                        firstToken,
                        rect,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(top: 4, end: 2),
                    child: Text(
                      firstChar,
                      locale: locale,
                      style: dropCapStyleFor(
                        settings,
                        language,
                        activePalette.heading,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _ReaderTextBlock(
                  paragraph: paragraph,
                  chapterIndex: slice.chapterIndex,
                  paragraphIndex: slice.paragraphIndex,
                  charStart: firstEnd,
                  charEnd: besideEnd,
                  text: besideText,
                  hasIndent: false,
                  hasAudio: document.hasAudio,
                  settings: settings,
                  palette: activePalette,
                  language: language,
                  earIndex: earIndex,
                  activeSentenceId: activeSentenceId,
                  selectedWord: selectedWord,
                  viewportKey: viewportKey,
                  onWordTap: onWordTap,
                ),
              ),
            ],
          ),
          if (restText.isNotEmpty)
            _ReaderTextBlock(
              paragraph: paragraph,
              chapterIndex: slice.chapterIndex,
              paragraphIndex: slice.paragraphIndex,
              charStart: besideEnd,
              charEnd: slice.charEnd,
              text: restText,
              hasIndent: false,
              hasAudio: document.hasAudio,
              settings: settings,
              palette: activePalette,
              language: language,
              earIndex: earIndex,
              activeSentenceId: activeSentenceId,
              selectedWord: selectedWord,
              viewportKey: viewportKey,
              onWordTap: onWordTap,
            ),
        ],
      );
    }

    return _ReaderTextBlock(
      paragraph: paragraph,
      chapterIndex: slice.chapterIndex,
      paragraphIndex: slice.paragraphIndex,
      charStart: slice.charStart,
      charEnd: slice.charEnd,
      text: paragraphText.substring(slice.charStart, slice.charEnd),
      hasIndent: slice.hasIndent,
      hasAudio: document.hasAudio,
      settings: settings,
      palette: activePalette,
      language: language,
      earIndex: earIndex,
      activeSentenceId: activeSentenceId,
      selectedWord: selectedWord,
      viewportKey: viewportKey,
      onWordTap: onWordTap,
    );
  }
}

Rect? _contextRectInViewport(
  BuildContext targetContext,
  GlobalKey viewportKey,
) {
  final targetBox = targetContext.findRenderObject() as RenderBox?;
  final viewportBox =
      viewportKey.currentContext?.findRenderObject() as RenderBox?;
  if (targetBox == null || viewportBox == null) return null;
  final topLeft = targetBox.localToGlobal(Offset.zero, ancestor: viewportBox);
  return topLeft & targetBox.size;
}

class _ReaderTextBlock extends StatefulWidget {
  const _ReaderTextBlock({
    required this.paragraph,
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charStart,
    required this.charEnd,
    required this.text,
    required this.hasIndent,
    required this.hasAudio,
    required this.settings,
    this.palette,
    required this.language,
    required this.earIndex,
    required this.activeSentenceId,
    required this.selectedWord,
    required this.viewportKey,
    required this.onWordTap,
  });

  final ReaderParagraph paragraph;
  final int chapterIndex;
  final int paragraphIndex;
  final int charStart;
  final int charEnd;
  final String text;
  final bool hasIndent;
  final bool hasAudio;
  final ReaderSettings settings;
  final ReaderPalette? palette;
  final Language language;
  final ReaderEarIndex earIndex;
  final String? activeSentenceId;
  final SelectedWord? selectedWord;
  final GlobalKey viewportKey;
  final void Function(
    int chapterIndex,
    int paragraphIndex,
    int charOffset,
    String token,
    Rect rectInViewport,
  )
  onWordTap;

  @override
  State<_ReaderTextBlock> createState() => _ReaderTextBlockState();
}

class _ReaderTextBlockState extends State<_ReaderTextBlock>
    with TickerProviderStateMixin {
  final _blockKey = GlobalKey();
  final _recognizers = <TapGestureRecognizer?>[];
  late List<WordToken> _tokens;
  late List<WordToken> _fullTokens;

  late final AnimationController _litController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  String? _currentLitId;
  String? _outgoingLitId;
  double _outgoingLitStartAlpha = 0.0;

  late final AnimationController _wordController = AnimationController(
    vsync: this,
    value: 1.0,
  );
  int? _currentSelectedOffset;
  int? _outgoingSelectedOffset;
  double _outgoingWordStartAlpha = 0.0;

  late final AnimationController _underlineController = AnimationController(
    vsync: this,
    value: widget.settings.underlineWords ? 1.0 : 0.0,
  );

  String? _effectiveLitId({
    required bool hasAudio,
    required bool lightUpSentence,
    required String? activeSentenceId,
  }) => hasAudio && lightUpSentence ? activeSentenceId : null;

  int? _selectedOffsetForBlock(SelectedWord? sel) {
    if (sel == null) return null;
    if (sel.chapterIndex != widget.chapterIndex ||
        sel.paragraphIndex != widget.paragraphIndex) {
      return null;
    }
    return sel.charOffset;
  }

  @override
  void initState() {
    super.initState();
    _currentLitId = _effectiveLitId(
      hasAudio: widget.hasAudio,
      lightUpSentence: widget.settings.lightUpSentence,
      activeSentenceId: widget.activeSentenceId,
    );
    _currentSelectedOffset = _selectedOffsetForBlock(widget.selectedWord);
    _rebuildRecognizers();
  }

  @override
  void didUpdateWidget(_ReaderTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language ||
        oldWidget.charStart != widget.charStart ||
        oldWidget.paragraph != widget.paragraph ||
        oldWidget.earIndex != widget.earIndex) {
      _rebuildRecognizers();
    }

    final motion = NocheMotion.of(context);
    final newLit = _effectiveLitId(
      hasAudio: widget.hasAudio,
      lightUpSentence: widget.settings.lightUpSentence,
      activeSentenceId: widget.activeSentenceId,
    );
    if (newLit != _currentLitId) {
      final prevAlpha = _currentLitId == null
          ? 0.0
          : motion.enter.transform(_litController.value);
      _outgoingLitId = _currentLitId;
      _outgoingLitStartAlpha = prevAlpha;
      _currentLitId = newLit;
      _litController.duration = motion.quick;
      _litController.forward(from: 0.0);
    }

    final newWordOffset = _selectedOffsetForBlock(widget.selectedWord);
    if (newWordOffset != _currentSelectedOffset) {
      final prevAlpha = _currentSelectedOffset == null
          ? 0.0
          : motion.enter.transform(_wordController.value);
      _outgoingSelectedOffset = _currentSelectedOffset;
      _outgoingWordStartAlpha = prevAlpha;
      _currentSelectedOffset = newWordOffset;
      _wordController.duration = motion.quick;
      _wordController.forward(from: 0.0);
    }

    if (oldWidget.settings.underlineWords != widget.settings.underlineWords) {
      _underlineController.animateTo(
        widget.settings.underlineWords ? 1.0 : 0.0,
        duration: motion.quick,
        curve: motion.enter,
      );
    }
  }

  @override
  void dispose() {
    _litController.dispose();
    _wordController.dispose();
    _underlineController.dispose();
    for (final r in _recognizers) {
      r?.dispose();
    }
    super.dispose();
  }

  void _rebuildRecognizers() {
    for (final r in _recognizers) {
      r?.dispose();
    }
    _recognizers.clear();
    _tokens = widget.language.tokens(widget.text);
    final paragraphTokens = widget.language.tokens(widget.paragraph.text);
    _fullTokens = <WordToken>[];
    var pIdx = 0;
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      final globalStart = widget.charStart + token.start;
      final globalEnd = widget.charStart + token.end;
      while (pIdx < paragraphTokens.length &&
          paragraphTokens[pIdx].end <= globalStart) {
        pIdx++;
      }
      final full =
          (pIdx < paragraphTokens.length &&
              globalStart >= paragraphTokens[pIdx].start &&
              globalEnd <= paragraphTokens[pIdx].end)
          ? paragraphTokens[pIdx]
          : WordToken(token.text, globalStart, globalEnd);
      _fullTokens.add(full);
      if (widget.earIndex.markFor(full.text) == WordMarkKind.none) {
        _recognizers.add(null);
      } else {
        final fullToken = full;
        _recognizers.add(
          TapGestureRecognizer()
            ..onTap = () => _handleTokenTap(token, fullToken),
        );
      }
    }
  }

  void _handleTokenTap(WordToken token, WordToken full) {
    final box = _blockKey.currentContext?.findRenderObject() as RenderBox?;
    final viewportBox =
        widget.viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || viewportBox == null) return;

    final span = _buildSpan(includeRecognizers: false);
    final indentWidth = widget.settings.bodyFontSize * 1.4;
    final textDirection = widget.language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final tp = TextPainter(
      text: span,
      textDirection: textDirection,
      textAlign: TextAlign.start,
      locale: Locale(widget.language.code),
      textScaler: MediaQuery.textScalerOf(context),
    );
    if (widget.hasIndent) {
      tp.setPlaceholderDimensions([
        PlaceholderDimensions(
          size: Size(indentWidth, 1),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
        ),
      ]);
    }
    tp.layout(maxWidth: box.size.width);

    final prefix = widget.hasIndent ? 1 : 0;
    final boxes = tp.getBoxesForSelection(
      TextSelection(
        baseOffset: prefix + token.start,
        extentOffset: prefix + token.end,
      ),
    );
    if (boxes.isEmpty) return;
    var union = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      union = union.expandToInclude(b.toRect());
    }
    final topLeft = box.localToGlobal(union.topLeft, ancestor: viewportBox);
    widget.onWordTap(
      widget.chapterIndex,
      widget.paragraphIndex,
      full.start,
      full.text,
      topLeft & union.size,
    );
  }

  ({int start, int end})? _localRangeForSentence(String? sentenceId) {
    if (sentenceId == null) return null;
    for (final r in widget.paragraph.sentenceRanges) {
      if (r.sentence.id == sentenceId) {
        final s = math.max(r.start, widget.charStart) - widget.charStart;
        final e = math.min(r.end, widget.charEnd) - widget.charStart;
        return s < e ? (start: s, end: e) : null;
      }
    }
    return null;
  }

  TextSpan _buildSpan({
    required bool includeRecognizers,
    double currentLitAlpha = 1.0,
    double outgoingLitAlpha = 0.0,
    double currentWordAlpha = 1.0,
    double outgoingWordAlpha = 0.0,
  }) {
    final palette = widget.palette ?? widget.settings.palette;
    final bodyStyle = widget.settings.bodyStyle(widget.language, palette.body);
    final indentWidth = widget.settings.bodyFontSize * 1.4;

    final currentLitRange = currentLitAlpha > 0
        ? _localRangeForSentence(_currentLitId)
        : null;
    final outgoingLitRange =
        outgoingLitAlpha > 0 && _outgoingLitId != _currentLitId
        ? _localRangeForSentence(_outgoingLitId)
        : null;

    double litAlphaAt(int localOffset) {
      if (currentLitRange != null &&
          localOffset >= currentLitRange.start &&
          localOffset < currentLitRange.end) {
        return currentLitAlpha;
      }
      if (outgoingLitRange != null &&
          localOffset >= outgoingLitRange.start &&
          localOffset < outgoingLitRange.end) {
        return outgoingLitAlpha;
      }
      return 0.0;
    }

    double selectionAlphaFor(WordToken full) {
      if (_currentSelectedOffset != null &&
          full.start == _currentSelectedOffset) {
        return currentWordAlpha;
      }
      if (_outgoingSelectedOffset != null &&
          _outgoingSelectedOffset != _currentSelectedOffset &&
          full.start == _outgoingSelectedOffset) {
        return outgoingWordAlpha;
      }
      return 0.0;
    }

    final children = <InlineSpan>[];
    if (widget.hasIndent) {
      children.add(WidgetSpan(child: SizedBox(width: indentWidth, height: 1)));
    }

    void addGapText(int start, int end) {
      if (start >= end) return;
      final cuts = <int>{start, end};
      for (final r in [currentLitRange, outgoingLitRange]) {
        if (r == null) continue;
        if (r.start > start && r.start < end) cuts.add(r.start);
        if (r.end > start && r.end < end) cuts.add(r.end);
      }
      final sorted = cuts.toList()..sort();
      for (var i = 0; i < sorted.length - 1; i++) {
        final s = sorted[i];
        final e = sorted[i + 1];
        if (s >= e) continue;
        final alpha = litAlphaAt(s);
        final color = alpha > 0
            ? Color.lerp(palette.body, palette.litText, alpha)
            : null;
        children.add(
          TextSpan(
            text: widget.text.substring(s, e),
            style: color == null ? null : TextStyle(color: color),
          ),
        );
      }
    }

    var cursor = 0;
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.start > cursor) {
        addGapText(cursor, token.start);
      }
      final litAlpha = litAlphaAt(token.start);
      final selAlpha = selectionAlphaFor(_fullTokens[i]);
      final litColor = litAlpha > 0
          ? Color.lerp(palette.body, palette.litText, litAlpha)!
          : palette.body;
      final tokenColor = selAlpha > 0
          ? Color.lerp(litColor, palette.ground, selAlpha)!
          : litColor;
      children.add(
        TextSpan(
          text: token.text,
          style: (litAlpha > 0 || selAlpha > 0)
              ? TextStyle(color: tokenColor)
              : null,
          recognizer: includeRecognizers ? _recognizers[i] : null,
        ),
      );
      cursor = token.end;
    }
    if (cursor < widget.text.length) {
      addGapText(cursor, widget.text.length);
    }

    return TextSpan(style: bodyStyle, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = widget.language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final locale = Locale(widget.language.code);
    final textScaler = MediaQuery.textScalerOf(context);
    final motion = NocheMotion.of(context);
    final activePalette = widget.palette ?? widget.settings.palette;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _litController,
        _wordController,
        _underlineController,
      ]),
      builder: (context, _) {
        final litT = motion.enter.transform(_litController.value);
        final currentLitAlpha = _currentLitId != null ? litT : 0.0;
        final outgoingLitAlpha =
            (_outgoingLitId != null && _outgoingLitId != _currentLitId)
            ? _outgoingLitStartAlpha * (1.0 - litT)
            : 0.0;

        final wordT = motion.enter.transform(_wordController.value);
        final currentWordAlpha = _currentSelectedOffset != null ? wordT : 0.0;
        final outgoingWordAlpha =
            (_outgoingSelectedOffset != null &&
                _outgoingSelectedOffset != _currentSelectedOffset)
            ? _outgoingWordStartAlpha * (1.0 - wordT)
            : 0.0;

        final span = _buildSpan(
          includeRecognizers: true,
          currentLitAlpha: currentLitAlpha,
          outgoingLitAlpha: outgoingLitAlpha,
          currentWordAlpha: currentWordAlpha,
          outgoingWordAlpha: outgoingWordAlpha,
        );
        final paintSpan = _buildSpan(
          includeRecognizers: false,
          currentLitAlpha: currentLitAlpha,
          outgoingLitAlpha: outgoingLitAlpha,
          currentWordAlpha: currentWordAlpha,
          outgoingWordAlpha: outgoingWordAlpha,
        );

        return CustomPaint(
          painter: _ReaderTextDecorator(
            span: paintSpan,
            paragraph: widget.paragraph,
            charStart: widget.charStart,
            charEnd: widget.charEnd,
            text: widget.text,
            tokens: _tokens,
            fullTokens: _fullTokens,
            hasIndent: widget.hasIndent,
            indentWidth: widget.settings.bodyFontSize * 1.4,
            settings: widget.settings,
            palette: activePalette,
            underlineVisibility: _underlineController.value,
            language: widget.language,
            earIndex: widget.earIndex,
            currentLitId: _currentLitId,
            outgoingLitId: _outgoingLitId,
            currentLitAlpha: currentLitAlpha,
            outgoingLitAlpha: outgoingLitAlpha,
            currentSelectedOffset: _currentSelectedOffset,
            outgoingSelectedOffset: _outgoingSelectedOffset,
            currentWordAlpha: currentWordAlpha,
            outgoingWordAlpha: outgoingWordAlpha,
            textDirection: textDirection,
            locale: locale,
            textScaler: textScaler,
          ),
          child: Text.rich(
            span,
            key: _blockKey,
            textDirection: textDirection,
            textAlign: TextAlign.start,
            locale: locale,
          ),
        );
      },
    );
  }
}

class _ReaderTextDecorator extends CustomPainter {
  _ReaderTextDecorator({
    required this.span,
    required this.paragraph,
    required this.charStart,
    required this.charEnd,
    required this.text,
    required this.tokens,
    required this.fullTokens,
    required this.hasIndent,
    required this.indentWidth,
    required this.settings,
    this.palette,
    this.underlineVisibility = 1.0,
    required this.language,
    required this.earIndex,
    required this.currentLitId,
    required this.outgoingLitId,
    required this.currentLitAlpha,
    required this.outgoingLitAlpha,
    required this.currentSelectedOffset,
    required this.outgoingSelectedOffset,
    required this.currentWordAlpha,
    required this.outgoingWordAlpha,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
  });

  final TextSpan span;
  final ReaderParagraph paragraph;
  final int charStart;
  final int charEnd;
  final String text;
  final List<WordToken> tokens;
  final List<WordToken> fullTokens;
  final bool hasIndent;
  final double indentWidth;
  final ReaderSettings settings;
  final ReaderPalette? palette;
  final double underlineVisibility;
  final Language language;
  final ReaderEarIndex earIndex;
  final String? currentLitId;
  final String? outgoingLitId;
  final double currentLitAlpha;
  final double outgoingLitAlpha;
  final int? currentSelectedOffset;
  final int? outgoingSelectedOffset;
  final double currentWordAlpha;
  final double outgoingWordAlpha;
  final TextDirection textDirection;
  final Locale locale;
  final TextScaler textScaler;

  void _paintSentenceHighlight(
    Canvas canvas,
    TextPainter tp,
    int prefix,
    String sentenceId,
    double alpha,
    Color baseColor,
  ) {
    if (alpha <= 0) return;
    for (final r in paragraph.sentenceRanges) {
      if (r.sentence.id != sentenceId) continue;
      final overlapStart = math.max(r.start, charStart);
      final overlapEnd = math.min(r.end, charEnd);
      if (overlapStart >= overlapEnd) continue;
      final boxes = tp.getBoxesForSelection(
        TextSelection(
          baseOffset: prefix + (overlapStart - charStart),
          extentOffset: prefix + (overlapEnd - charStart),
        ),
      );
      final litPaint = Paint()
        ..color = baseColor.withValues(alpha: baseColor.a * alpha);
      for (final box in boxes) {
        final rect = Rect.fromLTWH(
          box.left - 3,
          box.top + 1,
          (box.right - box.left) + 6,
          (box.bottom - box.top) - 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          litPaint,
        );
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final activePalette = palette ?? settings.palette;
    final prefix = hasIndent ? 1 : 0;
    final tp = TextPainter(
      text: span,
      textDirection: textDirection,
      textAlign: TextAlign.start,
      locale: locale,
      textScaler: textScaler,
    );
    if (hasIndent) {
      tp.setPlaceholderDimensions([
        PlaceholderDimensions(
          size: Size(indentWidth, 1),
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
        ),
      ]);
    }
    tp.layout(maxWidth: size.width);

    // 1. Lit active & outgoing sentence backgrounds.
    if (outgoingLitId != null &&
        outgoingLitId != currentLitId &&
        outgoingLitAlpha > 0) {
      _paintSentenceHighlight(
        canvas,
        tp,
        prefix,
        outgoingLitId!,
        outgoingLitAlpha,
        activePalette.lit,
      );
    }
    if (currentLitId != null && currentLitAlpha > 0) {
      _paintSentenceHighlight(
        canvas,
        tp,
        prefix,
        currentLitId!,
        currentLitAlpha,
        activePalette.lit,
      );
    }

    // 2. Underlines and selected word highlight.
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final full = fullTokens[i];
      final double selectionAlpha;
      if (currentSelectedOffset != null &&
          full.start == currentSelectedOffset) {
        selectionAlpha = currentWordAlpha;
      } else if (outgoingSelectedOffset != null &&
          outgoingSelectedOffset != currentSelectedOffset &&
          full.start == outgoingSelectedOffset) {
        selectionAlpha = outgoingWordAlpha;
      } else {
        selectionAlpha = 0.0;
      }

      final boxes = tp.getBoxesForSelection(
        TextSelection(
          baseOffset: prefix + token.start,
          extentOffset: prefix + token.end,
        ),
      );
      if (boxes.isEmpty) continue;

      if (selectionAlpha > 0) {
        final selectedPaint = Paint()
          ..color = NocheColors.listening.withValues(
            alpha: NocheColors.listening.a * selectionAlpha,
          );
        for (final box in boxes) {
          final rect = Rect.fromLTWH(
            box.left - 4,
            box.top + 1,
            (box.right - box.left) + 8,
            (box.bottom - box.top) - 2,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(6)),
            selectedPaint,
          );
        }
      }

      final underlineAlpha = underlineVisibility * (1.0 - selectionAlpha);
      if (underlineAlpha <= 0.0) continue;

      final mark = earIndex.markFor(full.text);
      if (mark == WordMarkKind.none || mark == WordMarkKind.known) continue;

      final neverHeardPaint = Paint()
        ..color = NocheColors.listening.withValues(
          alpha: NocheColors.listening.a * underlineAlpha,
        )
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      final learningPaint = Paint()
        ..color = activePalette.label.withValues(
          alpha: activePalette.label.a * underlineAlpha,
        )
        ..style = PaintingStyle.fill;

      for (final box in boxes) {
        final y = box.bottom - 2.0;
        if (mark == WordMarkKind.neverHeard) {
          canvas.drawLine(
            Offset(box.left, y),
            Offset(box.right, y),
            neverHeardPaint,
          );
        } else {
          // Dotted 2px underline in activePalette.label (2px dots every 4px).
          var x = box.left;
          while (x + 1.0 <= box.right) {
            final dotW = math.min(2.0, box.right - x);
            canvas.drawRect(
              Rect.fromLTWH(x, y - 1.0, dotW, 2.0),
              learningPaint,
            );
            x += 4.0;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_ReaderTextDecorator old) =>
      old.text != text ||
      old.charStart != charStart ||
      old.charEnd != charEnd ||
      old.hasIndent != hasIndent ||
      old.paragraph != paragraph ||
      old.language != language ||
      old.settings != settings ||
      (old.palette ?? old.settings.palette) != (palette ?? settings.palette) ||
      old.underlineVisibility != underlineVisibility ||
      old.currentLitId != currentLitId ||
      old.outgoingLitId != outgoingLitId ||
      old.currentLitAlpha != currentLitAlpha ||
      old.outgoingLitAlpha != outgoingLitAlpha ||
      old.currentSelectedOffset != currentSelectedOffset ||
      old.outgoingSelectedOffset != outgoingSelectedOffset ||
      old.currentWordAlpha != currentWordAlpha ||
      old.outgoingWordAlpha != outgoingWordAlpha ||
      old.earIndex != earIndex ||
      old.textDirection != textDirection ||
      old.textScaler != textScaler;
}

typedef WordBubblePlacement = ({
  double bubbleWidth,
  double bubbleHeight,
  double bubbleStart,
  double bubbleTop,
  double pointerOffsetFromBubbleStart,
  bool placeAbove,
  bool hasClip,
  TextStyle textStyle,
  TextDirection wordDirection,
  Locale locale,
  int dotsCount,
});

class ReaderWordBubbleOverlay extends StatefulWidget {
  const ReaderWordBubbleOverlay({
    super.key,
    required this.selected,
    required this.viewportSize,
    required this.settings,
    this.palette,
    required this.language,
    required this.stageMax,
    required this.onReplay,
  });

  final SelectedWord? selected;
  final Size viewportSize;
  final ReaderSettings settings;
  final ReaderPalette? palette;
  final Language language;
  final int stageMax;
  final ValueChanged<SelectedWord>? onReplay;

  @override
  State<ReaderWordBubbleOverlay> createState() =>
      _ReaderWordBubbleOverlayState();
}

class _ReaderWordBubbleOverlayState extends State<ReaderWordBubbleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)
    ..addStatusListener(_handleStatus);

  SelectedWord? _displayed;
  bool _exiting = false;

  static bool _sameWord(SelectedWord a, SelectedWord b) =>
      a.chapterIndex == b.chapterIndex &&
      a.paragraphIndex == b.paragraphIndex &&
      a.charOffset == b.charOffset &&
      a.token == b.token;

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        _exiting &&
        widget.selected == null &&
        mounted) {
      setState(() {
        _displayed = null;
        _exiting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _displayed = widget.selected;
    if (_displayed != null) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ReaderWordBubbleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.selected;
    final motion = NocheMotion.of(context);
    if (next != null) {
      if (_displayed == null || _exiting || !_sameWord(_displayed!, next)) {
        _displayed = next;
        _exiting = false;
        _controller.duration = motion.quick;
        _controller.forward(from: 0.0);
      } else {
        _displayed = next;
      }
    } else if (_displayed != null && !_exiting) {
      if (_controller.value <= 0.0) {
        _displayed = null;
        _exiting = false;
        _controller.stop();
      } else {
        _exiting = true;
        _controller.reverseDuration = motion.press;
        _controller.reverse(from: _controller.value);
      }
    }
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _displayed;
    if (displayed == null) {
      return const SizedBox.shrink();
    }
    final activePalette = widget.palette ?? widget.settings.palette;
    final placement = ReaderWordBubble.computePlacement(
      context,
      selected: displayed,
      viewportSize: widget.viewportSize,
      language: widget.language,
      stageMax: widget.stageMax,
      color: activePalette.bubbleText,
    );

    final bubble = ReaderWordBubble(
      selected: displayed,
      viewportSize: widget.viewportSize,
      settings: widget.settings,
      palette: activePalette,
      language: widget.language,
      stageMax: widget.stageMax,
      positioned: false,
      onTap: _exiting || displayed.clipId == null || widget.onReplay == null
          ? null
          : () => widget.onReplay!(displayed),
    );

    return PositionedDirectional(
      start: placement.bubbleStart,
      top: placement.bubbleTop,
      child: AnimatedBuilder(
        animation: _controller,
        child: _exiting
            ? IgnorePointer(child: ExcludeSemantics(child: bubble))
            : bubble,
        builder: (context, child) {
          final motion = NocheMotion.of(context);
          final double opacity;
          final double dy;
          if (_exiting) {
            final u = (1.0 - _controller.value).clamp(0.0, 1.0);
            final easedExit = motion.exit.transform(u);
            opacity = (1.0 - easedExit).clamp(0.0, 1.0);
            dy = motion.row * easedExit;
          } else {
            final t = motion.enter.transform(_controller.value.clamp(0.0, 1.0));
            opacity = t.clamp(0.0, 1.0);
            dy = motion.row * (1.0 - t);
          }
          return Transform.translate(
            key: const Key('reader-word-bubble-motion'),
            offset: Offset(0, dy),
            child: Opacity(
              key: const Key('reader-word-bubble-opacity'),
              opacity: opacity,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class ReaderWordBubble extends StatelessWidget {
  const ReaderWordBubble({
    super.key,
    required this.selected,
    required this.viewportSize,
    required this.settings,
    this.palette,
    required this.language,
    required this.stageMax,
    required this.onTap,
    this.positioned = true,
  });

  final SelectedWord selected;
  final Size viewportSize;
  final ReaderSettings settings;
  final ReaderPalette? palette;
  final Language language;
  final int stageMax;
  final VoidCallback? onTap;
  final bool positioned;

  static WordBubblePlacement computePlacement(
    BuildContext context, {
    required SelectedWord selected,
    required Size viewportSize,
    required Language language,
    required int stageMax,
    required Color color,
  }) {
    final hasClip = selected.clipId != null;
    final textStyle = NocheType.forScript(
      NocheType.primarySmall,
      language.script,
    ).copyWith(color: color);
    final stackDirection = Directionality.of(context);
    final wordDirection = language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final locale = Locale(language.code);

    final tp = TextPainter(
      text: TextSpan(text: selected.token, style: textStyle),
      textDirection: wordDirection,
      locale: locale,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    final dotsCount = math.max(1, stageMax);
    final dotsWidth = dotsCount * 6.0 + (dotsCount - 1) * 3.0;
    final contentWidth =
        (hasClip ? 20.0 + 8.0 : 0.0) + tp.width + 10.0 + dotsWidth;
    final bubbleWidth = (contentWidth + (hasClip ? 12.0 : 14.0) + 14.0)
        .clamp(72.0, math.max(72.0, viewportSize.width - 32.0))
        .toDouble();
    const bubbleHeight = 44.0;
    const pointerGap = 8.0;
    const minInset = 16.0;
    const pageEdgeInset = 24.0;

    final wordRect = selected.rectInViewport;
    final wordCenterX = wordRect.center.dx;
    final double wordStart;
    final double wordEnd;
    final double wordCenterFromStart;
    if (stackDirection == TextDirection.rtl) {
      wordStart = viewportSize.width - wordRect.right;
      wordEnd = viewportSize.width - wordRect.left;
      wordCenterFromStart = viewportSize.width - wordCenterX;
    } else {
      wordStart = wordRect.left;
      wordEnd = wordRect.right;
      wordCenterFromStart = wordCenterX;
    }

    final maxStart = math.max(
      minInset,
      viewportSize.width - minInset - bubbleWidth,
    );
    final centered = wordCenterFromStart - bubbleWidth / 2;
    final double rawStart;
    if (centered < pageEdgeInset) {
      rawStart = wordStart - 4.0;
    } else if (centered + bubbleWidth > viewportSize.width - pageEdgeInset) {
      rawStart = wordEnd + 4.0 - bubbleWidth;
    } else {
      rawStart = centered;
    }
    final bubbleStart = rawStart.clamp(minInset, maxStart).toDouble();

    final placeAbove = wordRect.top >= bubbleHeight + pointerGap + 8.0;
    final rawTop = placeAbove
        ? (wordRect.top - bubbleHeight - pointerGap)
        : (wordRect.bottom + pointerGap);
    final bubbleTop = rawTop
        .clamp(8.0, math.max(8.0, viewportSize.height - bubbleHeight - 8.0))
        .toDouble();

    final pointerOffsetFromBubbleStart =
        (wordCenterFromStart - bubbleStart - 6.0)
            .clamp(12.0, math.max(12.0, bubbleWidth - 24.0))
            .toDouble();

    return (
      bubbleWidth: bubbleWidth,
      bubbleHeight: bubbleHeight,
      bubbleStart: bubbleStart,
      bubbleTop: bubbleTop,
      pointerOffsetFromBubbleStart: pointerOffsetFromBubbleStart,
      placeAbove: placeAbove,
      hasClip: hasClip,
      textStyle: textStyle,
      wordDirection: wordDirection,
      locale: locale,
      dotsCount: dotsCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = palette ?? settings.palette;
    final p = computePlacement(
      context,
      selected: selected,
      viewportSize: viewportSize,
      language: language,
      stageMax: stageMax,
      color: activePalette.bubbleText,
    );

    final bubbleBody = Container(
      key: const Key('reader-word-bubble-body'),
      width: p.bubbleWidth,
      height: p.bubbleHeight,
      padding: EdgeInsetsDirectional.only(start: p.hasClip ? 12 : 14, end: 14),
      decoration: BoxDecoration(
        color: activePalette.bubbleFill,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: activePalette.bubbleShadowColor.withValues(
              alpha: activePalette.bubbleShadowAlpha,
            ),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p.hasClip) ...[
            NocheIcon(
              NocheIcons.speaker,
              size: 20,
              strokeWidth: 2.2,
              color: activePalette.bubbleText,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              selected.token,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: p.wordDirection,
              locale: p.locale,
              style: p.textStyle,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < p.dotsCount; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < selected.stage ? activePalette.bubbleText : null,
                    border: i >= selected.stage
                        ? Border.all(
                            color: activePalette.bubbleText,
                            width: 1.5,
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    final content = Semantics(
      button: p.hasClip,
      label: selected.token,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            bubbleBody,
            PositionedDirectional(
              start: p.pointerOffsetFromBubbleStart,
              top: p.placeAbove ? p.bubbleHeight - 7.0 : -5.0,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 12,
                  height: 12,
                  color: activePalette.bubbleFill,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!positioned) return content;
    return PositionedDirectional(
      start: p.bubbleStart,
      top: p.bubbleTop,
      child: content,
    );
  }
}
