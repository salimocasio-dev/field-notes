/// The word sheet (app.html: `palabra`, `oyeLinea`): the big picture, the word, the Ear and Mouth meters, when it
/// comes back, and "Heard in".
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_words/src/text_rules.dart';
import 'package:material_ui/material_ui.dart';

/// Opens the word sheet over everything, the tab bar included (the scrim of v=39 dims both): a transparent route on
/// the root navigator. [pair] is the word's review pair (null: no picture); [lines] are the lines it was heard in.
Future<void> showWordSheet(
  BuildContext context, {
  required Services services,
  required WordRecord record,
  required ReviewPair? pair,
  required List<HeardLine> lines,
}) => Navigator.of(context, rootNavigator: true).push<void>(
  PageRouteBuilder<void>(
    opaque: false,
    barrierColor: null,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => WordSheetPage(
      services: services,
      record: record,
      pair: pair,
      lines: lines,
    ),
  ),
);

/// The sheet and its scrim, sliding up in 200 ms and down again when closed.
class WordSheetPage extends StatefulWidget {
  const WordSheetPage({
    super.key,
    required this.services,
    required this.record,
    required this.pair,
    required this.lines,
  });

  final Services services;
  final WordRecord record;
  final ReviewPair? pair;
  final List<HeardLine> lines;

  @override
  State<WordSheetPage> createState() => _WordSheetPageState();
}

class _WordSheetPageState extends State<WordSheetPage> {
  final _scroll = ScrollController();
  final _wordKey = GlobalKey();
  Timer? _closing;
  bool _open = false;
  bool _titleVisible = false;

  // app.html: LOOP (what is playing: the clip id of the line, and which run of the player it is)
  String? _playing;
  int _loop = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _open = true);
    });
  }

  @override
  void dispose() {
    _closing?.cancel();
    _loop++;
    unawaited(widget.services.clips.stop());
    _scroll.dispose();
    super.dispose();
  }

  // app.html: palabra (`sb.onscroll`): the word shows in the header once its big word has scrolled away
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final word = _wordKey.currentContext?.findRenderObject();
    final body = _scroll.position.context.storageContext.findRenderObject();
    if (word is! RenderBox || body is! RenderBox) return;
    if (!word.attached || !body.attached) return;
    final bottom = word.localToGlobal(Offset(0, word.size.height)).dy;
    final top = body.localToGlobal(Offset.zero).dy;
    final show = bottom < top + 8;
    if (show != _titleVisible) setState(() => _titleVisible = show);
  }

  // app.html: cierra
  void _close() {
    if (_closing != null) return;
    _loop++;
    unawaited(widget.services.clips.stop());
    setState(() => _open = false);
    _closing = Timer(const Duration(milliseconds: 200), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // app.html: oyeLinea
  void _playLine(HeardLine line) {
    final s = widget.services;
    s.haptics.tick();
    final was = _playing == line.clipId;
    _loop++; // paraLeer(): whatever is playing stops, and no run of the old one goes on
    unawaited(s.clips.stop());
    setState(() => _playing = null);
    if (was) return; // a second touch stops it
    final k = ++_loop;
    setState(() => _playing = line.clipId);
    unawaited(() async {
      await s.clips.preload([line.clipId]);
      if (_loop != k) return;
      await s.clips.play(line.clipId);
      if (_loop == k && mounted) setState(() => _playing = null);
    }());
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    final r = widget.record;
    final pair = widget.pair;
    final tokens = wordTokens(r.w);
    final back = comesBack(r.ear.due, s.clock.nowMs());
    // a route has no Material above it: it brings the default text style the sheet's own texts sit on
    return Material(
      type: MaterialType.transparency,
      child: CoquiSheetLayer(
        open: _open,
        onScrimTap: _close,
        sheet: CoquiSheet(
          title: r.w,
          titleVisible: _titleVisible,
          onClose: _close,
          scrollController: _scroll,
          child: CollapsingColumn(
            children: [
              if (pair != null)
                Block(
                  bottom: CoquiMetrics.s16,
                  child: Center(
                    child: PictureFrame(
                      radius: CoquiMetrics.radiusWordPicture,
                      child: s.pictures.of(PictureRef.of(pair, pair.yes)),
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
              Center(
                child: EarMouthMeters(
                  ear: r.ear.etapa,
                  mouth: r.mouth.etapa,
                  centered: true,
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
              if (widget.lines.isNotEmpty) ...[
                const SectionTitle('Heard in'),
                CoquiCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CoquiMetrics.s16,
                  ),
                  child: DividedRows(
                    rows: [
                      for (final l in widget.lines)
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
          ),
        ),
      ),
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
