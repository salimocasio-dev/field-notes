import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/reader_model.dart';
import 'package:material_ui/material_ui.dart';

class PageParagraphSlice {
  const PageParagraphSlice({
    required this.chapterIndex,
    required this.paragraphIndex,
    required this.charStart,
    required this.charEnd,
    this.hasDropCap = false,
    this.dropCapBesideEnd,
    this.hasIndent = false,
  });

  final int chapterIndex;
  final int paragraphIndex;
  final int charStart;
  final int charEnd;
  final bool hasDropCap;

  /// End offset relative to slice start (`charStart`) for lines beside the drop cap.
  final int? dropCapBesideEnd;
  final bool hasIndent;
}

class ReaderPage {
  const ReaderPage({
    required this.pageIndex,
    required this.chapterIndex,
    required this.isChapterStart,
    required this.slices,
    required this.wordsRemainingInChapter,
  });

  final int pageIndex;
  final int chapterIndex;
  final bool isChapterStart;
  final List<PageParagraphSlice> slices;
  final int wordsRemainingInChapter;

  int get minutesLeftInChapter =>
      wordsRemainingInChapter <= 0 ? 1 : (wordsRemainingInChapter + 119) ~/ 120;
}

bool isDropCapEligible({
  required int paragraphIndex,
  required int charStart,
  required String paragraphText,
  required Language language,
}) {
  if (paragraphIndex != 0 || charStart != 0) return false;
  if (language.script != 'Latn') return false;
  if (paragraphText.length < 2) return false;
  if (!RegExp(r'^\p{L}', unicode: true).hasMatch(paragraphText)) return false;
  return language.tokens(paragraphText).length >= 2;
}

TextStyle dropCapStyleFor(
  ReaderSettings settings,
  Language language,
  Color color,
) {
  final adapted = NocheType.forScript(NocheType.dropCap, language.script);
  return adapted.copyWith(
    fontSize: settings.dropCapFontSize,
    height: settings.dropCapLineHeight / settings.dropCapFontSize,
    color: color,
  );
}

TextStyle chapterLabelStyleFor(Language language, Color color) {
  final adapted = NocheType.forScript(NocheType.label, language.script);
  return adapted.copyWith(
    color: color,
    letterSpacing: language.script == 'Latn' ? 1.68 : adapted.letterSpacing,
  );
}

TextStyle chapterTitleStyleFor(Language language, Color color) =>
    NocheType.forScript(
      NocheType.bookTitle,
      language.script,
    ).copyWith(color: color);

double measureChapterHeaderHeight({
  required ReaderChapterDoc chapter,
  required double contentWidth,
  required Language language,
  required TextScaler textScaler,
  required ReaderPalette palette,
}) {
  final hasLabel = chapter.label != null && chapter.label!.trim().isNotEmpty;
  final hasTitle = chapter.title.trim().isNotEmpty;
  if (!hasLabel && !hasTitle) return 0;

  final textDirection = language.direction == LanguageDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
  final locale = Locale(language.code);
  var height = 20.0; // top padding

  if (hasLabel) {
    final labelPainter = TextPainter(
      text: TextSpan(
        text: chapter.label!.toUpperCase(),
        style: chapterLabelStyleFor(language, palette.label),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      locale: locale,
      textScaler: textScaler,
    )..layout(maxWidth: contentWidth);
    height += labelPainter.height;
    if (hasTitle) height += 8.0;
  }

  if (hasTitle) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: chapter.title,
        style: chapterTitleStyleFor(language, palette.heading),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
      locale: locale,
      textScaler: textScaler,
    )..layout(maxWidth: contentWidth);
    height += titlePainter.height;
  }

  // Rule: margin top 20 + height 1 + margin bottom 24.
  height += 20.0 + 1.0 + 24.0;
  return height;
}

double measureDropCapWidth({
  required String firstChar,
  required ReaderSettings settings,
  required Language language,
  required TextScaler textScaler,
  required Color color,
}) {
  final textDirection = language.direction == LanguageDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
  final painter = TextPainter(
    text: TextSpan(
      text: firstChar,
      style: dropCapStyleFor(settings, language, color),
    ),
    textDirection: textDirection,
    locale: Locale(language.code),
    textScaler: textScaler,
  )..layout();
  return painter.width;
}

List<ReaderPage> paginateDocument({
  required ReaderDocument doc,
  required double contentWidth,
  required double contentHeight,
  required ReaderSettings settings,
  required Language language,
  required TextScaler textScaler,
}) {
  if (contentWidth <= 0 || contentHeight <= 0 || doc.chapters.isEmpty) {
    return const [];
  }

  final palette = settings.palette;
  final bodyStyle = settings.bodyStyle(language, palette.body);
  final textDirection = language.direction == LanguageDirection.rtl
      ? TextDirection.rtl
      : TextDirection.ltr;
  final locale = Locale(language.code);
  final indentWidth = settings.bodyFontSize * 1.4;
  final bodyLineHeight = bodyStyle.fontSize! * (bodyStyle.height ?? 1.5);

  TextPainter layoutText({
    required String text,
    required double maxWidth,
    bool hasIndent = false,
  }) {
    final span = hasIndent
        ? TextSpan(
            style: bodyStyle,
            children: [
              WidgetSpan(child: SizedBox(width: indentWidth, height: 1)),
              TextSpan(text: text),
            ],
          )
        : TextSpan(text: text, style: bodyStyle);
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
    tp.layout(maxWidth: maxWidth);
    return tp;
  }

  int textEndForLineCount(
    TextPainter tp,
    List<ui.LineMetrics> lines,
    int lineCount,
    int textLength,
    double maxWidth, {
    int prefixOffset = 0,
  }) {
    if (lineCount <= 0) return 0;
    if (lineCount >= lines.length) return textLength;
    final lastLine = lines[lineCount - 1];
    final pos = tp.getPositionForOffset(
      Offset(
        textDirection == TextDirection.rtl ? 0 : maxWidth,
        lastLine.baseline,
      ),
    );
    final boundary = tp.getLineBoundary(pos);
    final end = math.max(boundary.end - prefixOffset, 0);
    return end.clamp(0, textLength);
  }

  final pages = <ReaderPage>[];

  for (var chapterIdx = 0; chapterIdx < doc.chapters.length; chapterIdx++) {
    final chapter = doc.chapters[chapterIdx];
    final headerHeight = measureChapterHeaderHeight(
      chapter: chapter,
      contentWidth: contentWidth,
      language: language,
      textScaler: textScaler,
      palette: palette,
    );

    if (chapter.paragraphs.isEmpty) {
      pages.add(
        ReaderPage(
          pageIndex: pages.length,
          chapterIndex: chapterIdx,
          isChapterStart: true,
          slices: const [],
          wordsRemainingInChapter: 0,
        ),
      );
      continue;
    }

    var pIdx = 0;
    var charOffset = 0;
    var isFirstPageOfChapter = true;
    final chapterPageStart = pages.length;

    while (pIdx < chapter.paragraphs.length) {
      var availableHeight = isFirstPageOfChapter
          ? (contentHeight - headerHeight).clamp(bodyLineHeight, contentHeight)
          : contentHeight;
      final slices = <PageParagraphSlice>[];

      while (pIdx < chapter.paragraphs.length) {
        final paragraphText = chapter.paragraphs[pIdx].text;
        if (charOffset >= paragraphText.length) {
          pIdx++;
          charOffset = 0;
          continue;
        }
        final remainingText = paragraphText.substring(charOffset);
        final dropCap = isDropCapEligible(
          paragraphIndex: pIdx,
          charStart: charOffset,
          paragraphText: paragraphText,
          language: language,
        );

        if (dropCap) {
          final firstChar = paragraphText.substring(0, 1);
          final dropText = paragraphText.substring(1);
          final dropCapW = measureDropCapWidth(
            firstChar: firstChar,
            settings: settings,
            language: language,
            textScaler: textScaler,
            color: palette.heading,
          );
          final dropCapTotalH =
              textScaler.scale(settings.dropCapLineHeight) + 4.0;
          final narrowWidth = (contentWidth - dropCapW - 2.0).clamp(
            40.0,
            contentWidth,
          );
          final besideTargetLines = (dropCapTotalH / bodyLineHeight)
              .ceil()
              .clamp(2, 3);

          final narrowTp = layoutText(text: dropText, maxWidth: narrowWidth);
          final narrowLines = narrowTp.computeLineMetrics();

          final besideLinesCount = math.min(
            besideTargetLines,
            narrowLines.length,
          );
          var besideEnd = 1;
          if (besideLinesCount > 0) {
            // Walk line by line at narrowWidth.
            var cursor = 0;
            var takenLines = 0;
            var besideHeight = 0.0;
            while (takenLines < besideLinesCount &&
                takenLines < narrowLines.length) {
              final nextH = besideHeight + narrowLines[takenLines].height;
              if (nextH > availableHeight && slices.isNotEmpty) {
                break;
              }
              besideHeight = nextH;
              final pos = narrowTp.getPositionForOffset(
                Offset(
                  textDirection == TextDirection.rtl ? 0 : narrowWidth,
                  narrowLines[takenLines].baseline,
                ),
              );
              final boundary = narrowTp.getLineBoundary(pos);
              cursor = math.max(cursor, boundary.end);
              takenLines++;
            }
            if (takenLines == 0 && slices.isNotEmpty) {
              break;
            }
            if (takenLines == 0) {
              // Force at least one line on an empty page.
              final boundary = narrowTp.getLineBoundary(
                const TextPosition(offset: 0),
              );
              cursor = math.max(1, boundary.end);
              besideHeight = narrowLines.isNotEmpty
                  ? narrowLines.first.height
                  : bodyLineHeight;
            }
            besideEnd = 1 + cursor.clamp(0, dropText.length);
            final besideBlockHeight = math.max(besideHeight, dropCapTotalH);
            final afterBeside = paragraphText.substring(besideEnd);

            if (afterBeside.isEmpty) {
              slices.add(
                PageParagraphSlice(
                  chapterIndex: chapterIdx,
                  paragraphIndex: pIdx,
                  charStart: 0,
                  charEnd: paragraphText.length,
                  hasDropCap: true,
                  dropCapBesideEnd: besideEnd,
                ),
              );
              availableHeight -= besideBlockHeight;
              pIdx++;
              charOffset = 0;
              continue;
            }

            // Layout remaining text at full contentWidth.
            final restTp = layoutText(
              text: afterBeside,
              maxWidth: contentWidth,
            );
            final restLines = restTp.computeLineMetrics();
            var usedH = besideBlockHeight;
            var fitRestLines = 0;
            while (fitRestLines < restLines.length) {
              final lh = restLines[fitRestLines].height;
              if (usedH + lh > availableHeight) break;
              usedH += lh;
              fitRestLines++;
            }

            final restEndOffset = fitRestLines == 0
                ? 0
                : textEndForLineCount(
                    restTp,
                    restLines,
                    fitRestLines,
                    afterBeside.length,
                    contentWidth,
                  );
            final totalEnd = besideEnd + restEndOffset;
            slices.add(
              PageParagraphSlice(
                chapterIndex: chapterIdx,
                paragraphIndex: pIdx,
                charStart: 0,
                charEnd: totalEnd,
                hasDropCap: true,
                dropCapBesideEnd: besideEnd,
              ),
            );
            availableHeight -= usedH;
            if (totalEnd >= paragraphText.length) {
              pIdx++;
              charOffset = 0;
              continue;
            } else {
              var nextOffset = totalEnd;
              while (nextOffset < paragraphText.length &&
                  paragraphText[nextOffset] == ' ') {
                nextOffset++;
              }
              charOffset = nextOffset;
              break;
            }
          }
        }

        final hasIndent = pIdx > 0 && charOffset == 0;
        final prefixOffset = hasIndent ? 1 : 0;
        final tp = layoutText(
          text: remainingText,
          maxWidth: contentWidth,
          hasIndent: hasIndent,
        );
        final lines = tp.computeLineMetrics();
        if (lines.isEmpty) {
          pIdx++;
          charOffset = 0;
          continue;
        }

        var fitLines = 0;
        var usedH = 0.0;
        while (fitLines < lines.length) {
          final lh = lines[fitLines].height;
          if (usedH + lh > availableHeight) break;
          usedH += lh;
          fitLines++;
        }

        if (fitLines == 0) {
          if (slices.isNotEmpty) {
            break;
          }
          // Guarantee progress on empty page.
          fitLines = 1;
          usedH = lines.first.height;
        }

        var consumed = textEndForLineCount(
          tp,
          lines,
          fitLines,
          remainingText.length,
          contentWidth,
          prefixOffset: prefixOffset,
        );
        if (consumed <= 0) {
          consumed = remainingText.length;
        }
        final sliceEnd = (charOffset + consumed).clamp(
          charOffset + 1,
          paragraphText.length,
        );

        slices.add(
          PageParagraphSlice(
            chapterIndex: chapterIdx,
            paragraphIndex: pIdx,
            charStart: charOffset,
            charEnd: sliceEnd,
            hasIndent: hasIndent,
          ),
        );
        availableHeight -= usedH;

        if (sliceEnd >= paragraphText.length) {
          pIdx++;
          charOffset = 0;
        } else {
          var nextOffset = sliceEnd;
          while (nextOffset < paragraphText.length &&
              paragraphText[nextOffset] == ' ') {
            nextOffset++;
          }
          charOffset = nextOffset;
          break;
        }
      }

      if (slices.isEmpty && pIdx < chapter.paragraphs.length) {
        // Safety fallback: force whole paragraph so loop always terminates.
        final len = chapter.paragraphs[pIdx].text.length;
        slices.add(
          PageParagraphSlice(
            chapterIndex: chapterIdx,
            paragraphIndex: pIdx,
            charStart: charOffset,
            charEnd: len,
          ),
        );
        pIdx++;
        charOffset = 0;
      }

      pages.add(
        ReaderPage(
          pageIndex: pages.length,
          chapterIndex: chapterIdx,
          isChapterStart: isFirstPageOfChapter,
          slices: slices,
          wordsRemainingInChapter: 0,
        ),
      );
      isFirstPageOfChapter = false;
    }

    // Compute words remaining in chapter for every page in this chapter.
    var cumulativeWords = 0;
    for (var i = pages.length - 1; i >= chapterPageStart; i--) {
      final page = pages[i];
      var pageWords = 0;
      for (final slice in page.slices) {
        final sliceText = chapter.paragraphs[slice.paragraphIndex].text
            .substring(slice.charStart, slice.charEnd);
        pageWords += language.tokens(sliceText).length;
      }
      cumulativeWords += pageWords;
      pages[i] = ReaderPage(
        pageIndex: page.pageIndex,
        chapterIndex: page.chapterIndex,
        isChapterStart: page.isChapterStart,
        slices: page.slices,
        wordsRemainingInChapter: cumulativeWords,
      );
    }
  }

  return pages;
}

int pageForAnchor(
  List<ReaderPage> pages, {
  required int chapterIndex,
  required int paragraphIndex,
  required int charOffset,
}) {
  if (pages.isEmpty) return 0;
  for (final page in pages) {
    if (page.chapterIndex != chapterIndex) continue;
    for (final slice in page.slices) {
      if (slice.paragraphIndex == paragraphIndex &&
          charOffset >= slice.charStart &&
          charOffset < slice.charEnd) {
        return page.pageIndex;
      }
    }
  }
  for (final page in pages) {
    if (page.chapterIndex == chapterIndex) return page.pageIndex;
  }
  return 0;
}
