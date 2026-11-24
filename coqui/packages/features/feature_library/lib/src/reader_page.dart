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
    final palette = settings.palette;
    final chapter = document.chapters[page.chapterIndex];
    final hasLabel = chapter.label != null && chapter.label!.trim().isNotEmpty;
    final hasTitle = chapter.title.trim().isNotEmpty;
    final showHeader = page.isChapterStart && (hasLabel || hasTitle);
    final locale = Locale(language.code);

    return Padding(
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
                      textAlign: TextAlign.center,
                      locale: locale,
                      style: chapterLabelStyleFor(language, palette.label),
                    ),
                  if (hasLabel && hasTitle) const SizedBox(height: 8),
                  if (hasTitle)
                    Text(
                      chapter.title,
                      textAlign: TextAlign.center,
                      locale: locale,
                      style: chapterTitleStyleFor(language, palette.heading),
                    ),
                  Container(
                    width: 32,
                    height: 1,
                    margin: const EdgeInsetsDirectional.only(
                      top: 20,
                      bottom: 24,
                    ),
                    color: palette.rule,
                  ),
                ],
              ),
            ),
          for (final slice in page.slices)
            _buildSlice(
              context,
              chapter.paragraphs[slice.paragraphIndex],
              slice,
            ),
        ],
      ),
    );
  }

  Widget _buildSlice(
    BuildContext context,
    ReaderParagraph paragraph,
    PageParagraphSlice slice,
  ) {
    final palette = settings.palette;
    final locale = Locale(language.code);
    final paragraphText = paragraph.text;

    if (slice.hasDropCap && slice.dropCapBesideEnd != null) {
      final besideEnd = slice.dropCapBesideEnd!.clamp(1, slice.charEnd);
      final firstChar = paragraphText.substring(0, 1);
      final besideText = paragraphText.substring(1, besideEnd);
      final restText = besideEnd < slice.charEnd
          ? paragraphText.substring(besideEnd, slice.charEnd)
          : '';
      final tokens = language.tokens(paragraphText);
      final firstToken = tokens.isNotEmpty && tokens.first.start == 0
          ? tokens.first.text
          : firstChar;
      final dropKey = GlobalKey();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final rect = _globalRectInViewport(dropKey, viewportKey);
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
                  key: dropKey,
                  padding: const EdgeInsetsDirectional.only(top: 4, end: 2),
                  child: Text(
                    firstChar,
                    locale: locale,
                    style: dropCapStyleFor(settings, language, palette.heading),
                  ),
                ),
              ),
              Expanded(
                child: _ReaderTextBlock(
                  paragraph: paragraph,
                  chapterIndex: slice.chapterIndex,
                  paragraphIndex: slice.paragraphIndex,
                  charStart: 1,
                  charEnd: besideEnd,
                  text: besideText,
                  hasIndent: false,
                  hasAudio: document.hasAudio,
                  settings: settings,
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
      language: language,
      earIndex: earIndex,
      activeSentenceId: activeSentenceId,
      selectedWord: selectedWord,
      viewportKey: viewportKey,
      onWordTap: onWordTap,
    );
  }
}

Rect? _globalRectInViewport(GlobalKey targetKey, GlobalKey viewportKey) {
  final targetBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
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

class _ReaderTextBlockState extends State<_ReaderTextBlock> {
  final _blockKey = GlobalKey();
  final _recognizers = <TapGestureRecognizer?>[];
  late List<WordToken> _tokens;

  @override
  void initState() {
    super.initState();
    _rebuildRecognizers();
  }

  @override
  void didUpdateWidget(_ReaderTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.language != widget.language ||
        oldWidget.charStart != widget.charStart) {
      _rebuildRecognizers();
    }
  }

  @override
  void dispose() {
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
    for (final token in _tokens) {
      final full = _fullTokenFor(token);
      if (widget.earIndex.markFor(full.text) == WordMarkKind.none) {
        _recognizers.add(null);
      } else {
        _recognizers.add(
          TapGestureRecognizer()..onTap = () => _handleTokenTap(token),
        );
      }
    }
  }

  WordToken _fullTokenFor(WordToken localToken) {
    final globalStart = widget.charStart + localToken.start;
    final globalEnd = widget.charStart + localToken.end;
    for (final pToken in widget.language.tokens(widget.paragraph.text)) {
      if (globalStart >= pToken.start && globalEnd <= pToken.end) {
        return pToken;
      }
    }
    return WordToken(localToken.text, globalStart, globalEnd);
  }

  void _handleTokenTap(WordToken token) {
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
    final full = _fullTokenFor(token);
    widget.onWordTap(
      widget.chapterIndex,
      widget.paragraphIndex,
      full.start,
      full.text,
      topLeft & union.size,
    );
  }

  TextSpan _buildSpan({required bool includeRecognizers}) {
    final palette = widget.settings.palette;
    final bodyStyle = widget.settings.bodyStyle(widget.language, palette.body);
    final indentWidth = widget.settings.bodyFontSize * 1.4;
    final ranges = widget.paragraph.sentenceRanges;

    String? sentenceIdAt(int paragraphOffset) {
      for (final r in ranges) {
        if (paragraphOffset >= r.start && paragraphOffset < r.end) {
          return r.sentence.id;
        }
      }
      return null;
    }

    final litActive =
        widget.hasAudio &&
        widget.settings.lightUpSentence &&
        widget.activeSentenceId != null;

    bool isLitAt(int paragraphOffset) =>
        litActive && sentenceIdAt(paragraphOffset) == widget.activeSentenceId;

    bool isSelectedToken(WordToken token) {
      final sel = widget.selectedWord;
      if (sel == null) return false;
      final full = _fullTokenFor(token);
      return sel.chapterIndex == widget.chapterIndex &&
          sel.paragraphIndex == widget.paragraphIndex &&
          sel.charOffset == full.start;
    }

    final children = <InlineSpan>[];
    if (widget.hasIndent) {
      children.add(WidgetSpan(child: SizedBox(width: indentWidth, height: 1)));
    }

    void addGapText(int start, int end) {
      if (start >= end) return;
      if (!litActive) {
        children.add(TextSpan(text: widget.text.substring(start, end)));
        return;
      }
      var cursor = start;
      while (cursor < end) {
        final lit = isLitAt(widget.charStart + cursor);
        var runEnd = cursor + 1;
        while (runEnd < end && isLitAt(widget.charStart + runEnd) == lit) {
          runEnd++;
        }
        children.add(
          TextSpan(
            text: widget.text.substring(cursor, runEnd),
            style: lit ? TextStyle(color: palette.litText) : null,
          ),
        );
        cursor = runEnd;
      }
    }

    var cursor = 0;
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.start > cursor) {
        addGapText(cursor, token.start);
      }
      final selected = isSelectedToken(token);
      final lit = isLitAt(widget.charStart + token.start);
      TextStyle? tokenStyle;
      if (selected) {
        tokenStyle = TextStyle(color: palette.ground);
      } else if (lit) {
        tokenStyle = TextStyle(color: palette.litText);
      }
      children.add(
        TextSpan(
          text: token.text,
          style: tokenStyle,
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
    final span = _buildSpan(includeRecognizers: true);
    final paintSpan = _buildSpan(includeRecognizers: false);
    final textDirection = widget.language.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final locale = Locale(widget.language.code);
    final textScaler = MediaQuery.textScalerOf(context);

    return CustomPaint(
      painter: _ReaderTextDecorator(
        span: paintSpan,
        paragraph: widget.paragraph,
        chapterIndex: widget.chapterIndex,
        paragraphIndex: widget.paragraphIndex,
        charStart: widget.charStart,
        charEnd: widget.charEnd,
        text: widget.text,
        tokens: _tokens,
        hasIndent: widget.hasIndent,
        indentWidth: widget.settings.bodyFontSize * 1.4,
        hasAudio: widget.hasAudio,
        settings: widget.settings,
        language: widget.language,
        earIndex: widget.earIndex,
        activeSentenceId: widget.activeSentenceId,
        selectedWord: widget.selectedWord,
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
  }
}

class _ReaderTextDecorator extends CustomPainter {
  _ReaderTextDecorator({
    required this.span,
    required this.paragraph,
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charStart,
    required this.charEnd,
    required this.text,
    required this.tokens,
    required this.hasIndent,
    required this.indentWidth,
    required this.hasAudio,
    required this.settings,
    required this.language,
    required this.earIndex,
    required this.activeSentenceId,
    required this.selectedWord,
    required this.textDirection,
    required this.locale,
    required this.textScaler,
  });

  final TextSpan span;
  final ReaderParagraph paragraph;
  final int chapterIndex;
  final int paragraphIndex;
  final int charStart;
  final int charEnd;
  final String text;
  final List<WordToken> tokens;
  final bool hasIndent;
  final double indentWidth;
  final bool hasAudio;
  final ReaderSettings settings;
  final Language language;
  final ReaderEarIndex earIndex;
  final String? activeSentenceId;
  final SelectedWord? selectedWord;
  final TextDirection textDirection;
  final Locale locale;
  final TextScaler textScaler;

  int _fullTokenStart(WordToken localToken) {
    final globalStart = charStart + localToken.start;
    final globalEnd = charStart + localToken.end;
    for (final pToken in language.tokens(paragraph.text)) {
      if (globalStart >= pToken.start && globalEnd <= pToken.end) {
        return pToken.start;
      }
    }
    return globalStart;
  }

  String _fullTokenText(WordToken localToken) {
    final globalStart = charStart + localToken.start;
    final globalEnd = charStart + localToken.end;
    for (final pToken in language.tokens(paragraph.text)) {
      if (globalStart >= pToken.start && globalEnd <= pToken.end) {
        return pToken.text;
      }
    }
    return localToken.text;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final palette = settings.palette;
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

    // 1. Lit active sentence background.
    if (hasAudio && settings.lightUpSentence && activeSentenceId != null) {
      for (final r in paragraph.sentenceRanges) {
        if (r.sentence.id != activeSentenceId) continue;
        final overlapStart = math.max(r.start, charStart);
        final overlapEnd = math.min(r.end, charEnd);
        if (overlapStart >= overlapEnd) continue;
        final boxes = tp.getBoxesForSelection(
          TextSelection(
            baseOffset: prefix + (overlapStart - charStart),
            extentOffset: prefix + (overlapEnd - charStart),
          ),
        );
        final litPaint = Paint()..color = palette.lit;
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

    // 2. Underlines and selected word highlight.
    final neverHeardPaint = Paint()
      ..color = NocheColors.listening
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final learningPaint = Paint()
      ..color = palette.label
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()..color = NocheColors.listening;

    for (final token in tokens) {
      final globalOffset = _fullTokenStart(token);
      final isSelected =
          selectedWord != null &&
          selectedWord!.chapterIndex == chapterIndex &&
          selectedWord!.paragraphIndex == paragraphIndex &&
          selectedWord!.charOffset == globalOffset;

      final boxes = tp.getBoxesForSelection(
        TextSelection(
          baseOffset: prefix + token.start,
          extentOffset: prefix + token.end,
        ),
      );
      if (boxes.isEmpty) continue;

      if (isSelected) {
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
        continue;
      }

      if (!settings.underlineWords) continue;

      final mark = earIndex.markFor(_fullTokenText(token));
      if (mark == WordMarkKind.none || mark == WordMarkKind.known) continue;

      for (final box in boxes) {
        final y = box.bottom - 2.0;
        if (mark == WordMarkKind.neverHeard) {
          canvas.drawLine(
            Offset(box.left, y),
            Offset(box.right, y),
            neverHeardPaint,
          );
        } else {
          // Dotted 2px underline in palette.label (2px dots every 4px).
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
      old.settings != settings ||
      old.activeSentenceId != activeSentenceId ||
      old.selectedWord != selectedWord ||
      old.earIndex != earIndex ||
      old.textDirection != textDirection ||
      old.textScaler != textScaler;
}

class ReaderWordBubble extends StatelessWidget {
  const ReaderWordBubble({
    super.key,
    required this.selected,
    required this.viewportSize,
    required this.settings,
    required this.language,
    required this.stageMax,
    required this.onTap,
  });

  final SelectedWord selected;
  final Size viewportSize;
  final ReaderSettings settings;
  final Language language;
  final int stageMax;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = settings.palette;
    final hasClip = selected.clipId != null;
    final textStyle = NocheType.forScript(
      NocheType.primarySmall,
      language.script,
    ).copyWith(color: palette.bubbleText);
    final textDirection = Directionality.of(context);
    final locale = Locale(language.code);

    final tp = TextPainter(
      text: TextSpan(text: selected.token, style: textStyle),
      textDirection: textDirection,
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

    final wordRect = selected.rectInViewport;
    final wordCenterX = wordRect.center.dx;
    final maxStart = math.max(16.0, viewportSize.width - 16.0 - bubbleWidth);

    final double bubbleLeft;
    if (textDirection == TextDirection.rtl) {
      final wordCenterFromEnd = viewportSize.width - wordCenterX;
      final start = (wordCenterFromEnd - bubbleWidth / 2)
          .clamp(16.0, maxStart)
          .toDouble();
      bubbleLeft = viewportSize.width - start - bubbleWidth;
    } else {
      bubbleLeft = (wordCenterX - bubbleWidth / 2)
          .clamp(16.0, maxStart)
          .toDouble();
    }

    final placeAbove = wordRect.top >= bubbleHeight + pointerGap + 8.0;
    final bubbleTop = placeAbove
        ? (wordRect.top - bubbleHeight - pointerGap)
        : (wordRect.bottom + pointerGap)
              .clamp(
                8.0,
                math.max(8.0, viewportSize.height - bubbleHeight - 8.0),
              )
              .toDouble();

    final bubbleStart = textDirection == TextDirection.rtl
        ? viewportSize.width - bubbleLeft - bubbleWidth
        : bubbleLeft;
    final pointerOffsetFromBubbleStart =
        (textDirection == TextDirection.rtl
                ? (viewportSize.width - wordCenterX) - bubbleStart - 6.0
                : wordCenterX - bubbleStart - 6.0)
            .clamp(12.0, math.max(12.0, bubbleWidth - 24.0))
            .toDouble();

    final bubbleBody = Container(
      width: bubbleWidth,
      height: bubbleHeight,
      padding: EdgeInsetsDirectional.only(start: hasClip ? 12 : 14, end: 14),
      decoration: BoxDecoration(
        color: palette.bubbleFill,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: NocheColors.lessonGround.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasClip) ...[
            NocheIcon(
              NocheIcons.speaker,
              size: 20,
              strokeWidth: 2.2,
              color: palette.bubbleText,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              selected.token,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              locale: locale,
              style: textStyle,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < dotsCount; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < selected.stage ? palette.bubbleText : null,
                    border: i >= selected.stage
                        ? Border.all(color: palette.bubbleText, width: 1.5)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    return PositionedDirectional(
      start: bubbleStart,
      top: bubbleTop,
      child: Semantics(
        button: hasClip,
        label: selected.token,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              bubbleBody,
              PositionedDirectional(
                start: pointerOffsetFromBubbleStart,
                top: placeAbove ? bubbleHeight - 7.0 : -5.0,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 12,
                    height: 12,
                    color: palette.bubbleFill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
