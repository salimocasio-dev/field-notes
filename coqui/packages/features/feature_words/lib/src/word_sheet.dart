/// The word sheet (app.html: `palabra`, `oyeLinea`): the big picture, the word,
/// Ear and Mouth stage bars, when it comes back, and "Heard in", styled with
/// Noche tokens and [showNocheSheet].
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/text_rules.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:material_ui/material_ui.dart';

/// The word sheet, for [showNocheSheet]: call `showNocheSheet(context,
/// builder: sheet.build)`, then [closed] when the sheet route completes so any
/// playing clip stops at once.
class WordSheet {
  WordSheet({
    required this.services,
    required this.record,
    required this.pair,
    required this.lines,
    this.stageMax = defaultStageMax,
  });

  final Services services;
  final WordRecord record;
  final ReviewPair? pair;
  final List<HeardLine> lines;
  final int stageMax;

  // app.html: LOOP (what is playing now is the run of the player that has this
  // number; a run that another has overtaken, or that the closing of the sheet
  // has ended, goes no further)
  int _loop = 0;
  bool _built = false;

  late final Widget _body = _WordSheetBody(sheet: this);

  /// The builder of [showNocheSheet].
  Widget build(BuildContext context, VoidCallback close) {
    _built = true;
    return _body;
  }

  /// app.html: cierra (`paraLeer()`): what is playing stops, and no run of it
  /// goes on. Called at once when the sheet is closed, and again on dispose.
  void closed() {
    if (!_built) return;
    _loop++;
    unawaited(services.clips.stop());
  }
}

class _WordSheetBody extends StatefulWidget {
  const _WordSheetBody({required this.sheet});

  final WordSheet sheet;

  @override
  State<_WordSheetBody> createState() => _WordSheetBodyState();
}

class _WordSheetBodyState extends State<_WordSheetBody> {
  // app.html: LOOP (the clip id of the line that is playing)
  String? _playing;

  WordSheet get _sheet => widget.sheet;
  Services get _s => _sheet.services;

  @override
  void dispose() {
    _sheet.closed();
    super.dispose();
  }

  // app.html: oyeLinea
  void _playLine(HeardLine line) {
    final s = _s;
    s.haptics.tick();
    final was = _playing == line.clipId;
    _sheet._loop++; // paraLeer(): stop whatever is playing
    unawaited(s.clips.stop());
    setState(() => _playing = null);
    if (was) return; // a second touch stops it
    final k = ++_sheet._loop;
    setState(() => _playing = line.clipId);
    unawaited(() async {
      await s.clips.preload([line.clipId]);
      if (_sheet._loop != k) return;
      await s.clips.play(line.clipId);
      if (_sheet._loop == k && mounted) setState(() => _playing = null);
    }());
  }

  @override
  Widget build(BuildContext context) {
    final r = _sheet.record;
    final pair = _sheet.pair;
    final lang = _s.course.language;
    final courseDir = lang.direction == LanguageDirection.rtl
        ? TextDirection.rtl
        : TextDirection.ltr;
    final courseLocale = Locale(lang.code);
    final tokens = wordTokens(r.w, language: lang);
    final back = comesBack(r.ear.due, _s.clock.nowMs());
    final wordStyle = NocheType.forScript(
      NocheType.placeTitle,
      lang.script,
    ).copyWith(color: NocheColors.text);

    return Directionality(
      textDirection: courseDir,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pair != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NocheSize.tileRadius),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: _s.pictures.of(PictureRef.of(pair, pair.yes)),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 16),
            child: Text(
              r.w,
              key: const Key('word-sheet-heading'),
              textAlign: TextAlign.center,
              textDirection: courseDir,
              locale: courseLocale,
              style: wordStyle,
            ),
          ),
          NocheCard(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StageMeterRow(
                  label: 'Ear',
                  stage: r.ear.etapa,
                  max: _sheet.stageMax,
                ),
                const SizedBox(height: 12),
                _StageMeterRow(
                  label: 'Mouth',
                  stage: r.mouth.etapa,
                  max: _sheet.stageMax,
                ),
              ],
            ),
          ),
          if (back.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 16),
              child: Text(
                back,
                textAlign: TextAlign.center,
                style: NocheType.bodySmall.copyWith(color: NocheColors.label),
              ),
            ),
          if (_sheet.lines.isNotEmpty) ...[
            const SizedBox(height: 24),
            const NocheSectionLabel('Heard in', bottomGap: 12),
            NocheCard(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _sheet.lines.length; i++)
                    _HeardLineRow(
                      line: _sheet.lines[i],
                      span: _lineSpan(_sheet.lines[i].text, tokens, lang),
                      storyStyle: NocheType.forScript(
                        NocheType.bodySmall,
                        lang.script,
                      ).copyWith(color: NocheColors.label),
                      courseDir: courseDir,
                      courseLocale: courseLocale,
                      playing: _playing == _sheet.lines[i].clipId,
                      showDivider: i < _sheet.lines.length - 1,
                      onPlay: () => _playLine(_sheet.lines[i]),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The line, with the word bold inside it and the text unchanged.
  TextSpan _lineSpan(String text, List<String> tokens, Language language) {
    final baseStyle = NocheType.forScript(
      NocheType.body,
      language.script,
    ).copyWith(color: NocheColors.text);
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);
    final spans = <TextSpan>[];
    var pos = 0;
    for (final o in occurrences(text, [tokens], language: language)) {
      if (o.a > pos) spans.add(TextSpan(text: text.substring(pos, o.a)));
      spans.add(TextSpan(text: text.substring(o.a, o.z), style: boldStyle));
      pos = o.z;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: baseStyle, children: spans);
  }
}

class _StageMeterRow extends StatelessWidget {
  const _StageMeterRow({
    required this.label,
    required this.stage,
    required this.max,
  });

  final String label;
  final int stage;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: NocheType.bodySmall.copyWith(color: NocheColors.label),
        ),
        NocheStageBar(stage: stage, max: max),
      ],
    );
  }
}

class _HeardLineRow extends StatelessWidget {
  const _HeardLineRow({
    required this.line,
    required this.span,
    required this.storyStyle,
    required this.courseDir,
    required this.courseLocale,
    required this.playing,
    required this.showDivider,
    required this.onPlay,
  });

  final HeardLine line;
  final TextSpan span;
  final TextStyle storyStyle;
  final TextDirection courseDir;
  final Locale courseLocale;
  final bool playing;
  final bool showDivider;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsetsDirectional.symmetric(vertical: 12),
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
                Text.rich(span, textDirection: courseDir, locale: courseLocale),
                const SizedBox(height: 4),
                Text(
                  line.storyTitle,
                  textDirection: courseDir,
                  locale: courseLocale,
                  style: storyStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Pressable(
            onPressed: onPlay,
            semanticLabel: 'Play: ${line.text}',
            builder: (context, pressed) => Transform.scale(
              scale: pressed ? 0.94 : 1,
              child: Container(
                width: NocheSize.touch,
                height: NocheSize.touch,
                alignment: AlignmentDirectional.center,
                decoration: const BoxDecoration(
                  color: NocheColors.chip,
                  shape: BoxShape.circle,
                ),
                child: NocheIcon(
                  playing ? NocheIcons.pause : NocheIcons.play,
                  size: 20,
                  color: NocheColors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
