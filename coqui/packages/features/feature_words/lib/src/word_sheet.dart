/// The word sheet (app.html: `palabra`, `oyeLinea`): the big picture, the word, the Ear and Mouth meters, when it
/// comes back, and "Heard in".
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/text_rules.dart';
import 'package:feature_words/src/words_view.dart';
import 'package:material_ui/material_ui.dart';

/// The word sheet, for `showCoquiSheet`: `showCoquiSheet(context, builder: sheet.build)`, then [closed] when the
/// future of `showCoquiSheet` completes (the sheet has been popped and is sliding out).
///
/// [pair] is the word's review pair (null: no picture); [lines] are the lines it was heard in.
class WordSheet {
  WordSheet({
    required this.services,
    required this.record,
    required this.pair,
    required this.lines,
  });

  final Services services;
  final WordRecord record;
  final ReviewPair? pair;
  final List<HeardLine> lines;

  // app.html: LOOP (what is playing now is the run of the player that has this number; a run that another has
  // overtaken, or that the closing of the sheet has ended, goes no further)
  int _loop = 0;

  // The route calls [build] once, and `CoquiSheet` takes its `titleVisible` when it is made. The title shows
  // when the big word has scrolled away, so the body tells [_showTitle], which builds the route's builder again.
  Element? _builder;
  bool _titleVisible = false;
  bool _built = false;

  late final Widget _body = _WordSheetBody(sheet: this);

  /// The builder of `showCoquiSheet`. The X, the scrim, the drag and the back button are the route's.
  CoquiSheet build(BuildContext context, VoidCallback close) {
    _builder = context as Element;
    _built = true;
    return CoquiSheet(
      title: record.w,
      titleVisible: _titleVisible,
      child: _body,
    );
  }

  void _showTitle(bool show) {
    if (show == _titleVisible) return;
    _titleVisible = show;
    final at = _builder;
    if (at != null && at.mounted) at.markNeedsBuild();
  }

  /// app.html: cierra (`paraLeer()`): what is playing stops, and no run of it goes on. Called at once when the sheet
  /// is closed, and again when its widgets are gone.
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
  final _wordKey = GlobalKey();
  ScrollPosition? _position;

  // app.html: LOOP (the clip id of the line that is playing)
  String? _playing;

  WordSheet get _sheet => widget.sheet;
  Services get _s => _sheet.services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_onScroll);
      _position = position?..addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _sheet.closed();
    super.dispose();
  }

  // app.html: palabra (`sb.onscroll`): the word shows in the header once its big word has scrolled away
  void _onScroll() {
    final position = _position;
    if (position == null || !position.hasPixels) return;
    final word = _wordKey.currentContext?.findRenderObject();
    final body = position.context.storageContext.findRenderObject();
    if (word is! RenderBox || body is! RenderBox) return;
    if (!word.attached || !body.attached) return;
    final bottom = word.localToGlobal(Offset(0, word.size.height)).dy;
    final top = body.localToGlobal(Offset.zero).dy;
    _sheet._showTitle(bottom < top + 8);
  }

  // app.html: oyeLinea
  void _playLine(HeardLine line) {
    final s = _s;
    s.haptics.tick();
    final was = _playing == line.clipId;
    _sheet._loop++; // paraLeer(): whatever is playing stops, and no run of the old one goes on
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
    final tokens = wordTokens(r.w);
    final back = comesBack(r.ear.due, _s.clock.nowMs());
    return CollapsingColumn(
      children: [
        if (pair != null)
          Block(
            bottom: CoquiMetrics.s16,
            child: Center(
              child: PictureFrame(
                radius: CoquiMetrics.radiusWordPicture,
                child: _s.pictures.of(PictureRef.of(pair, pair.yes)),
              ),
            ),
          ),
        Block(
          bottom: CoquiMetrics.s8,
          child: Text(
            r.w,
            key: _wordKey,
            textAlign: TextAlign.center,
            style: CoquiText.h1,
          ),
        ),
        // the two meters, each with its stage named (palabras.js: heard, found, holding, good)
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (label, value) in [
                ('Ear', r.ear.etapa),
                ('Mouth', r.mouth.etapa),
              ]) ...[
                if (label == 'Mouth') const SizedBox(height: CoquiMetrics.s4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkillMeter(label: label, value: value),
                    const SizedBox(width: CoquiMetrics.s12),
                    Text(stageName(value), style: CoquiText.meterLabel),
                  ],
                ),
              ],
            ],
          ),
        ),
        Block(
          top: CoquiMetrics.s16,
          child: Text(
            back,
            textAlign: TextAlign.center,
            style: CoquiText.smallMuted,
          ),
        ),
        if (_sheet.lines.isNotEmpty) ...[
          const SectionTitle('Heard in'),
          CoquiCard(
            padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s16),
            child: DividedRows(
              rows: [
                for (final l in _sheet.lines)
                  ListRow(
                    title: Text.rich(_lineSpan(l.text, tokens)),
                    subtitle: Text(l.storyTitle),
                    trailing: PlayButton(
                      icon: _playing == l.clipId
                          ? CoquiIcons.stop
                          : CoquiIcons.play,
                      semanticLabel: 'Play: ${l.text}',
                      onPressed: () => _playLine(l),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// The line, with the word bold inside it (`<b>`) and the text unchanged.
  TextSpan _lineSpan(String text, List<String> tokens) {
    final spans = <TextSpan>[];
    var pos = 0;
    for (final o in occurrences(text, [tokens])) {
      if (o.a > pos) spans.add(TextSpan(text: text.substring(pos, o.a)));
      spans.add(
        TextSpan(text: text.substring(o.a, o.z), style: CoquiText.rowBold),
      );
      pos = o.z;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
    return TextSpan(style: CoquiText.body, children: spans);
  }
}
