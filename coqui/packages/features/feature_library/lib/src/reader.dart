/// Leer: the book of a story. A full-screen frame, one page at a time.
/// app.html:343-405 (`leer` to `initLibro`), 103-128 (the CSS).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/book_line.dart';
import 'package:feature_library/src/book_picture.dart';
import 'package:feature_library/src/images.dart';
import 'package:feature_library/src/strings.dart';
import 'package:feature_library/src/word_marks.dart';
import 'package:feature_library/src/word_popup.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// `.lbmain`, `.lbfoot` width cap. app.html:110, 120
const double _columnMax = 560;

/// `.lbtxt{max-height:55%}`. app.html:113
const double _textMaxFraction = 0.55;

/// `reservaTxt`: the text area is never taller than half the screen (`lb.clientHeight*.5`). app.html:394
const double _reserveMaxFraction = 0.5;

/// `--finx`: what the last page's "Fin" adds to the foot, kept as padding under the picture on every other page. app.html:103
const double _finExtra = 72;

/// `lbTam`: 20 or 24. app.html:342
const String _sizeKey = 'tam';

/// The reader of one book. It reads the book and the story's lines when it opens; if there is no such book it
/// goes back (the old page then simply did not open one). Reading writes no word record; the last page marks the book read.
class BookReader extends StatefulWidget {
  const BookReader({
    super.key,
    required this.services,
    required this.bookId,
    this.imageUrl = defaultBookImageUrl,
    this.imageProvider = networkBookImage,
    this.startPage = 0,
    this.startCard = false,
  });

  final Services services;
  final String bookId;
  final BookImageUrl imageUrl;
  final BookImageProvider imageProvider;

  /// The page it opens at (0 for the first). Only the dev entry sets it, to open at a reference state.
  final int startPage;

  /// Open, and when the page has played its lines show the card of the first picture word on it. Only the dev entry sets it.
  final bool startCard;

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> {
  Services get _s => widget.services;

  // LEE: the open book
  Book? _book;
  Map<String, BookLine> _lines = const {}; // T.clips
  PictureWords? _pictureWords; // pares()
  int _i = 0; // LEE.i
  List<String> _ids = const []; // LEE.ids
  final Map<String, List<WordMark>> _marks = {};

  String? _lit; // the line with `.now`
  int _loop = 0; // LOOP: numbers the one running line sequence
  int _leert = 0; // LEERT: changes every time a book opens or closes (a late fetch drops itself)
  bool _swiped = false; // SWIPED
  Timer? _swipedTimer;
  Offset? _swipeStart; // `sw`
  PictureWord? _card; // the word card, open
  int? _uw; // the picture word whose places are underlined (`.bw.uw`)
  Timer? _uwTimer; // UWT
  bool _big = false; // lbTam()===24

  // the reserved text height, kept while nothing it depends on changes
  ({double width, bool big, TextScaler scaler, double height})? _reserved;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _big = _readSize() == 24;
    unawaited(_open());
  }

  @override
  void didUpdateWidget(BookReader old) {
    super.didUpdateWidget(old);
    if (old.bookId != widget.bookId) {
      _stopAll();
      _book = null;
      _i = 0;
      _ids = const [];
      _lit = null;
      _card = null;
      _uw = null;
      _reserved = null;
      unawaited(_open());
    }
  }

  @override
  void dispose() {
    _stopAll();
    _swipedTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  // app.html: lbTam
  int _readSize() {
    try {
      return _s.storage('leer').read(_sizeKey) == '24' ? 24 : 20;
    } on Object {
      return 20;
    }
  }

  // app.html: lbGuarda
  void _saveSize(int v) {
    try {
      unawaited(
        _s.storage('leer').write(_sizeKey, '$v').catchError((Object _) {}),
      );
    } on Object {
      // not kept
    }
  }

  // app.html: leer
  Future<void> _open() async {
    _paraLeer();
    final my = _leert;
    Book? b;
    Map<String, dynamic>? t;
    try {
      b = await _s.course.book(widget.bookId);
    } on Object {
      b = null;
    }
    try {
      t = await _s.course.story(widget.bookId);
    } on Object {
      t = null;
    }
    if (my != _leert || !mounted) return;
    if (b == null || b.pages.isEmpty || t == null) {
      // the old page did not open a book here; the screen has nothing to show, so it goes back to the shelf
      _s.nav.back();
      return;
    }
    final clips = (t['clips'] as Map?)?.cast<String, dynamic>() ?? const {};
    _lines = {
      for (final e in clips.entries)
        if (e.value is Map)
          e.key: BookLine.fromJson(
            e.key,
            (e.value as Map).cast<String, dynamic>(),
          ),
    };
    _pictureWords = PictureWords(_s.course.pairs);
    _marks.clear();
    _book = b;
    _i = widget.startPage.clamp(0, b.pages.length - 1);
    _big = _readSize() == 24;
    _pinta();
    final playing = _arranca();
    if (widget.startCard) {
      // the dev entry's reference state: the page has played its lines, then a word is tapped
      await playing;
      if (mounted && my == _leert) _firstCard();
    } else {
      unawaited(playing);
    }
  }

  // the dev entry's reference state: a word with a picture, tapped
  void _firstCard() {
    for (final id in _ids) {
      final marks = _marksOf(id);
      if (marks.isNotEmpty) {
        _tarjetaPal(marks.first.k);
        _uwTimer?.cancel(); // the picture of the old page was taken while the underline showed: it stays
        return;
      }
    }
  }

  // app.html: paraLeer
  void _paraLeer() {
    _leert++;
    _loop++;
    _hush();
  }

  // app.html: corta
  void _corta() {
    _loop++;
    _hush();
  }

  // app.html: hush
  void _hush() {
    unawaited(_s.clips.stop());
  }

  // closing a book or leaving the screen: silence, no sequence left running, no card, no underline
  void _stopAll() {
    _leert++;
    _loop++;
    _hush();
    _uwTimer?.cancel();
    for (final t in _waitTimers) {
      t.cancel();
    }
    _waitTimers.clear();
    for (final w in _waits) {
      if (!w.isCompleted) {
        w.complete(); // the loops see that they are not current and end
      }
    }
    _waits.clear();
  }

  // app.html: cierraLibro
  void _close() {
    _stopAll();
    if (mounted) {
      setState(() {
        _lit = null;
        _card = null; // cierraTarjeta
        _uw = null; // quitaUw
      });
    }
    _s.nav.back();
  }

  // app.html: idsPag
  List<String> _idsPage(int i) {
    final b = _book;
    if (b == null || i < 0 || i >= b.pages.length) return const [];
    return [
      for (final id in b.pages[i].clips)
        if (_lines.containsKey(id)) id,
    ];
  }

  // app.html: pinta
  void _pinta() {
    final b = _book!;
    _ids = _idsPage(_i);
    final next = _i + 1 < b.pages.length ? b.pages[_i + 1] : null;
    if (next != null && mounted) {
      // the next picture is ready when the page turns
      unawaited(
        precacheImage(
          widget.imageProvider(widget.imageUrl(next.image)),
          context,
          onError: (error, stack) {},
        ),
      );
    }
    if (_i == b.pages.length - 1) _marcaLeido();
    if (mounted) setState(() {});
  }

  // app.html: marcaLeido (completion only: no word record is written)
  void _marcaLeido() {
    final id = widget.bookId;
    if (!_s.progress.hasRead(id)) _s.progress.markRead(id);
  }

  // app.html: luce
  void _luce(String? id) {
    if (!mounted || _lit == id) return;
    setState(() => _lit = id);
  }

  // app.html: sleep (the page's own wait). The waits are kept so that leaving the screen can end them.
  final Set<Completer<void>> _waits = {};
  final Set<Timer> _waitTimers = {};

  Future<void> _sleep(num ms) {
    final done = Completer<void>();
    late final Timer timer;
    timer = Timer(Duration(microseconds: (ms * 1000).round()), () {
      _waitTimers.remove(timer);
      _waits.remove(done);
      if (!done.isCompleted) done.complete();
    });
    _waitTimers.add(timer);
    _waits.add(done);
    return done.future;
  }

  // juego.js: dur (a line with no recording is read in its own time)
  double _dur(String id) {
    final text = _lines[id]?.text;
    final words = ((text == null || text.isEmpty) ? 'x x' : text)
        .split(RegExp(r'\s+'))
        .length;
    return (360 * words + 300) / 1000;
  }

  // app.html: leeClip
  Future<void> _leeClip(String id) async {
    await _s.clips.preload([id]);
    if (_s.course.clip(id) != null) {
      await _s.clips.play(id);
    } else {
      await _sleep(_dur(id) * 1000);
    }
  }

  // app.html: secuencia
  Future<void> _secuencia(int k, List<String> ids) async {
    for (final id in ids) {
      if (_loop != k || !mounted) return;
      _luce(id);
      await _leeClip(id);
      if (_loop != k || !mounted) return;
      await _sleep(350);
    }
    if (_loop == k) _luce(null);
  }

  // app.html: arranca: opening a page, its lines in order, then it waits. Only this page's recordings and the next page's are loaded
  Future<void> _arranca() async {
    final k = ++_loop;
    final i = _i;
    _hush();
    final ids = _idsPage(i);
    final nx = _idsPage(i + 1);
    if (ids.isNotEmpty) {
      _luce(
        ids.first,
      ); // the first line is lit at once, while its recording loads
    }
    await _s.clips.preload(ids);
    // (the old page's guard here, `if(LOOP!==k||LEE!==L)return;`, sits inside its // comment, so it never runs: ported as it is)
    unawaited(_s.clips.preload(nx));
    await _secuencia(k, ids);
  }

  // app.html: pag
  void _pag(int d) {
    if (_book != null) _irPag(_i + d);
  }

  // app.html: irPag
  void _irPag(int n) {
    final b = _book;
    if (b == null || n < 0 || n >= b.pages.length) return;
    _corta(); // the sound stops with the page
    _lit = null;
    _card = null;
    _quitaUw();
    _i = n;
    _pinta();
    unawaited(_arranca());
  }

  // app.html: leeUna (a tap on a line: that line again)
  Future<void> _leeUna(String id) async {
    _corta();
    final k = ++_loop;
    _luce(id);
    await _leeClip(id);
    if (_loop == k && mounted) _luce(null);
  }

  // app.html: tarjetaPal
  void _tarjetaPal(int k) {
    final words = _pictureWords!;
    _uwTimer?.cancel();
    setState(() {
      _card = words.list[k];
      _uw = k; // every place the word is on the page is underlined for a moment
    });
    _uwTimer = Timer(const Duration(milliseconds: 2400), _quitaUw);
  }

  // app.html: quitaUw
  void _quitaUw() {
    _uwTimer?.cancel();
    if (mounted && _uw != null) setState(() => _uw = null);
  }

  // app.html: cierraTarjeta
  void _cierraTarjeta() {
    if (mounted && _card != null) setState(() => _card = null);
  }

  // app.html: txt.onclick
  void _tapLine(String id, int? k) {
    if (_swiped || _book == null) return;
    _s.haptics.tick();
    if (k != null) {
      _tarjetaPal(k);
    } else {
      unawaited(_leeUna(id));
    }
  }

  // app.html: lbaa.onclick
  void _toggleSize() {
    _s.haptics.tick();
    setState(() => _big = !_big);
    _saveSize(_big ? 24 : 20);
  }

  void _tick(VoidCallback f) {
    _s.haptics.tick();
    f();
  }

  // app.html: the keys (Escape closes, the arrows turn the page)
  KeyEventResult _key(FocusNode node, KeyEvent e) {
    if (_book == null || e is KeyUpEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _pag(1);
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _pag(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // app.html: main's pointer events (a swipe turns the page: left for the next)
  void _down(PointerDownEvent e) => _swipeStart = e.position;

  void _cancel(PointerCancelEvent e) => _swipeStart = null;

  void _up(PointerUpEvent e) {
    final sw = _swipeStart;
    if (sw == null) return;
    final dx = e.position.dx - sw.dx;
    final dy = e.position.dy - sw.dy;
    _swipeStart = null;
    if (dx.abs() >= 48 && dx.abs() > 1.5 * dy.abs()) {
      _swiped = true;
      _swipedTimer?.cancel();
      _swipedTimer = Timer(
        const Duration(milliseconds: 400),
        () => _swiped = false,
      );
      _pag(dx < 0 ? 1 : -1);
    }
  }

  // ---------------------------------------------------------------- the layout

  // app.html: reservaTxt: the text area is as tall as the book's tallest page (never under three single lines),
  // so the picture does not move from page to page
  double _reservedHeight({
    required double width,
    required double screenHeight,
    required TextScaler scaler,
  }) {
    final r = _reserved;
    if (r != null && r.width == width && r.big == _big && r.scaler == scaler) {
      return r.height;
    }
    final style = _big ? CoquiText.bookLineBig : CoquiText.bookLine;
    final ll = style.fontSize! * style.height!;
    var h = 3 * math.max(BookLineMetrics.minHeight, ll + 18) + 2 * 4 + 8.0;
    final b = _book!;
    final textW = BookLineMetrics.textWidth(width - 32);
    for (var p = 0; p < b.pages.length; p++) {
      final ids = _idsPage(p);
      var page = 8.0 + 4 * math.max(0, ids.length - 1);
      for (final id in ids) {
        final line = _lines[id]!;
        final tp = TextPainter(
          text: TextSpan(text: line.text, style: style),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout(maxWidth: textW);
        final block =
            (line.who == 'tu' ? BookLineMetrics.whoHeight : 0) + tp.height;
        page += math.max(
          BookLineMetrics.minHeight,
          math.max(block, BookLineMetrics.speaker) + 2 * BookLineMetrics.padY,
        );
      }
      h = math.max(h, page);
    }
    final double height = math.min(h, screenHeight * _reserveMaxFraction);
    _reserved = (width: width, big: _big, scaler: scaler, height: height);
    return height;
  }

  List<WordMark> _marksOf(String id) => _marks.putIfAbsent(
    id,
    () => _pictureWords?.marks(_lines[id]?.text ?? '') ?? const [],
  );

  Widget _lineList({required bool shrink}) {
    final ids = _ids;
    return ListView.separated(
      key: ValueKey(
        'page$_i',
      ), // every page starts at the top (`box.scrollTop=0`)
      shrinkWrap: shrink,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: ids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final id = ids[index];
        return BookLineView(
          key: ValueKey('line:$id'),
          line: _lines[id]!,
          marks: _marksOf(id),
          big: _big,
          lit: _lit == id,
          underlined: _uw,
          onTap: _tapLine,
        );
      },
    );
  }

  Widget _topBar(double safeTop) {
    final b = _book!;
    final n = b.pages.length;
    return SizedBox(
      height: 56 + safeTop,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, safeTop, 8, 0),
        child: Row(
          children: [
            LessonIconButton(
              onPressed: () => _tick(_close),
              semanticLabel: LibraryStrings.closeLabel,
              child: const CoquiIcon(
                CoquiIcons.close,
                color: CoquiColors.lessonInk2,
              ),
            ),
            const SizedBox(width: CoquiMetrics.s16),
            Flexible(
              child: Semantics(
                label: LibraryStrings.pageLabel,
                value: LibraryStrings.pageOf(_i + 1, n),
                excludeSemantics: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: CoquiMetrics.lessonBarMax,
                  ),
                  child: LessonProgressLine(value: (_i + 1) / n),
                ),
              ),
            ),
            const SizedBox(width: CoquiMetrics.s16),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40),
              child: Text(
                '${_i + 1} / $n',
                textAlign: TextAlign.right,
                style: CoquiText.lessonCount,
              ),
            ),
            const SizedBox(width: CoquiMetrics.s16),
            LessonTextSizeButton(onPressed: _toggleSize, big: _big),
          ],
        ),
      ),
    );
  }

  // app.html: pie
  Widget _foot({required bool last}) {
    final back = SizedBox(
      width: last ? 72 : null,
      child: LessonButton(
        kind: LessonButtonKind.outline,
        height: 56,
        fillWidth: false,
        semanticLabel: LibraryStrings.previousPage,
        onPressed: _i == 0 ? null : () => _tick(() => _pag(-1)),
        child: CoquiIcon(
          CoquiIcons.left,
          size: 28,
          color: CoquiColors.lessonInk,
        ),
      ),
    );
    final Widget row;
    if (last) {
      row = Row(
        children: [
          back,
          const SizedBox(width: 16),
          Expanded(
            child: LessonButton(
              height: 56,
              fillWidth: false,
              onPressed: () => _tick(() => _irPag(0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CoquiIcon(
                    CoquiIcons.replay,
                    size: 20,
                    color: CoquiColors.lessonInk,
                  ),
                  const SizedBox(width: 8),
                  Text(LibraryStrings.again, style: CoquiText.lessonButton),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: LessonButton(
              height: 56,
              fillWidth: false,
              label: LibraryStrings.shelf,
              onPressed: () => _tick(_close),
            ),
          ),
        ],
      );
    } else {
      row = Row(
        children: [
          Expanded(child: back),
          const SizedBox(width: 16),
          Expanded(
            child: LessonButton(
              height: 56,
              fillWidth: false,
              semanticLabel: LibraryStrings.nextPage,
              onPressed: () => _tick(() => _pag(1)),
              child: CoquiIcon(
                CoquiIcons.right,
                size: 28,
                color: CoquiColors.lessonInk,
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (last) ...[
            // `.lbfin`: 32 px high, 16 px of space above and below, then the 8 px gap of the foot
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: Center(
                child: Text(LibraryStrings.fin, style: CoquiText.lessonFin),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 8),
          ],
          row,
        ],
      ),
    );
  }

  Widget _picture({required BoxConstraints area, required double bottomExtra}) {
    final b = _book!;
    return ClipRect(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomExtra),
        child: Center(
          child: BookPicture(
            provider: widget.imageProvider(widget.imageUrl(b.pages[_i].image)),
            availableWidth: math.max(0, area.maxWidth - 32),
            availableHeight: math.max(0, area.maxHeight - 16 - bottomExtra),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_book == null) {
      // the page is being fetched (or there is none): the calm frame, nothing in it
      return Semantics(
        label: LibraryStrings.book,
        child: const ColoredBox(
          color: CoquiColors.lessonBg,
          child: SizedBox.expand(),
        ),
      );
    }
    final b = _book!;
    final last = _i == b.pages.length - 1;
    final safe = MediaQuery.paddingOf(context);
    final scaler = MediaQuery.textScalerOf(context);
    final compact = CoquiLayout.compact(context);
    return Semantics(
      label: LibraryStrings.book,
      explicitChildNodes: true,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _key,
        child: ColoredBox(
          color: CoquiColors.lessonBg,
          child: LayoutBuilder(
            builder: (context, c) {
              final inner = Size(
                c.maxWidth - safe.left - safe.right,
                c.maxHeight - safe.bottom,
              );
              final Widget body = compact
                  ? _landscape(inner, safe, scaler, c.maxHeight)
                  : _portrait(inner, safe, scaler, c.maxHeight, last);
              return Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      safe.left,
                      0,
                      safe.right,
                      safe.bottom,
                    ),
                    child: body,
                  ),
                  if (_card != null)
                    Positioned.fill(
                      child: Semantics(
                        liveRegion: true,
                        child: WordPopup(
                          word: _card!,
                          pictures: _s.pictures,
                          onClose: _cierraTarjeta,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _portrait(
    Size inner,
    EdgeInsets safe,
    TextScaler scaler,
    double screenHeight,
    bool last,
  ) {
    final colW = math.min(inner.width, _columnMax);
    final reserved = _reservedHeight(
      width: colW,
      screenHeight: screenHeight,
      scaler: scaler,
    );
    return Column(
      children: [
        _topBar(safe.top),
        Expanded(
          child: Center(
            child: SizedBox(
              width: colW,
              child: Listener(
                onPointerDown: _down,
                onPointerUp: _up,
                onPointerCancel: _cancel,
                behavior: HitTestBehavior.translucent,
                child: LayoutBuilder(
                  builder: (context, main) {
                    final cap = math.max(
                      reserved,
                      main.maxHeight * _textMaxFraction,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, area) => _picture(
                              area: area,
                              bottomExtra: last ? 0 : _finExtra,
                            ),
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: reserved,
                            maxHeight: cap,
                          ),
                          child: _lineList(shrink: true),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: colW,
            child: _foot(last: last),
          ),
        ),
      ],
    );
  }

  // `@media (orientation:landscape) and (max-height:500px)`: the picture at the left, the top bar, the lines and the buttons in a column at the right
  Widget _landscape(
    Size inner,
    EdgeInsets safe,
    TextScaler scaler,
    double screenHeight,
  ) {
    final right = math.max(280.0, inner.width * 0.44);
    return Row(
      children: [
        Expanded(
          child: Listener(
            onPointerDown: _down,
            onPointerUp: _up,
            onPointerCancel: _cancel,
            behavior: HitTestBehavior.translucent,
            child: LayoutBuilder(
              builder: (context, area) => _picture(area: area, bottomExtra: 0),
            ),
          ),
        ),
        SizedBox(
          width: right,
          child: Column(
            children: [
              _topBar(safe.top),
              Expanded(
                child: Listener(
                  onPointerDown: _down,
                  onPointerUp: _up,
                  onPointerCancel: _cancel,
                  behavior: HitTestBehavior.translucent,
                  child: _lineList(shrink: false),
                ),
              ),
              _foot(last: _i == _book!.pages.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}
