/// The shelf (`CoquiLabels.library`). One row for each story he has played: its cover, the title, Listen and Read.
/// app.html:323-341 (`biblioteca`), redesigned by order 27: a "Hear next" card at the top (the one green button), a grey
/// line under each place's name (stories played, books read), every book with its cover, compact rows (Listen is the
/// quiet play disc, Read only on a book that reads well), and a way to the map when nothing is played.
library;

import 'dart:async';

import 'package:coqui_contracts/coqui_contracts.dart';
import 'package:coqui_ui/coqui_ui.dart';
import 'package:feature_library/src/images.dart';
import 'package:feature_library/src/shelf_row.dart';
import 'package:feature_library/src/strings.dart';
import 'package:material_ui/material_ui.dart';

/// One row of the shelf, before it is drawn: `[c, q, kind, haz]` of app.html:332-333.
class ShelfItem {
  const ShelfItem({
    required this.id,
    required this.listen,
    required this.kind,
    required this.routine,
  });

  final String id;

  /// `&oir=1` on the old Listen link: a story is told straight through; a picture story and a routine are played.
  final bool listen;

  /// `""`, or the kind of a picture story or a routine (`CoquiLabels.pictureStory`, `CoquiLabels.routine`).
  final String kind;

  /// A routine has no book: Listen only, and no request for a book.
  final bool routine;
}

/// The shelf, as the tab of the library.
class LibraryShelf extends StatefulWidget {
  const LibraryShelf({
    super.key,
    required this.services,
    this.imageUrl = defaultBookImageUrl,
    this.imageProvider = networkBookImage,
    this.controller,
  });

  final Services services;
  final BookImageUrl imageUrl;
  final BookImageProvider imageProvider;

  /// The scroll of the list, when the shell keeps it (each tab keeps its place); otherwise the shelf's own.
  final ScrollController? controller;

  @override
  State<LibraryShelf> createState() => _LibraryShelfState();
}

class _Group {
  const _Group(this.place, this.items, this.played);
  final Place place;
  final List<ShelfItem> items;

  /// How many of the place's map stories he has played.
  final int played;
}

class _Loaded {
  const _Loaded({
    required this.groups,
    required this.books,
    required this.oidos,
    required this.read,
    required this.closed,
    required this.next,
    required this.nextIsNew,
  });

  final List<_Group> groups;
  final Map<String, Book?> books;
  final Map<String, dynamic> oidos;
  final Set<String> read;
  final int closed;

  /// The story the card at the top names (order 27): the one heard least, the newest of those.
  final ShelfItem? next;

  /// [next] was never heard yet (not played, not listened to).
  final bool nextIsNew;
}

class _LibraryShelfState extends State<LibraryShelf> {
  Services get _s => widget.services;

  StreamSubscription<void>? _changes;
  int _token = 0; // app.html: BIBT
  final Map<String, Book?> _books =
      {}; // app.html: BOOKS (the books asked for, kept)
  _Loaded? _loaded;
  bool _more = false; // #fadeTab: there is more to scroll
  ScrollController? _own;
  ScrollController get _scroll =>
      widget.controller ?? (_own ??= ScrollController());

  @override
  void initState() {
    super.initState();
    // the shelf shows what is played and what is read: it is drawn again after every save
    _changes = _s.progress.changes.listen((_) => _load());
    _load();
  }

  @override
  void dispose() {
    _token++;
    unawaited(_changes?.cancel());
    _own?.dispose();
    super.dispose();
  }

  static bool _truthy(Object? v) =>
      v is num ? v != 0 : (v is bool ? v : v != null);

  // app.html: biblioteca
  Future<void> _load() async {
    final my = ++_token;
    final p = _s.progress;
    final raw = p.raw;
    final oidosRaw = raw['oidos'];
    final oi = oidosRaw is Map
        ? oidosRaw.cast<String, dynamic>()
        : <String, dynamic>{};
    final todo = _truthy(p.setting('todo')); // AJ().todo
    // only what he can play now is listed, per place; everything still closed is counted in the one grey line at the bottom
    var closed = 0;
    final groups = <_Group>[];
    for (final l in _s.course.places) {
      if (l.stories.isEmpty) continue;
      final fin = todo || l.stories.every(p.played);
      final jug = l.stories.where(p.played).toList();
      final dib = fin ? l.pictureStories : const <String>[];
      final haz = fin ? l.routines : const <String>[];
      closed +=
          l.stories.length -
          jug.length +
          (fin ? 0 : l.pictureStories.length + l.routines.length);
      final items = <ShelfItem>[
        for (final c in jug)
          ShelfItem(id: c, listen: true, kind: '', routine: false),
        for (final c in dib)
          ShelfItem(
            id: c,
            listen: false,
            kind: CoquiLabels.pictureStory,
            routine: false,
          ),
        for (final c in haz)
          ShelfItem(
            id: c,
            listen: false,
            kind: CoquiLabels.routine,
            routine: true,
          ),
      ];
      if (items.isNotEmpty) groups.add(_Group(l, items, jug.length));
    }
    final read = <String>{
      for (final g in groups)
        for (final it in g.items)
          if (p.hasRead(it.id)) it.id,
    };
    final (next, nextHeard) = _pickNext(groups, oi);
    await Future.wait([
      for (final g in groups)
        for (final it in g.items)
          if (!it.routine) _book(it.id),
    ]);
    if (my != _token || !mounted) return;
    setState(
      () => _loaded = _Loaded(
        groups: groups,
        books: Map.of(_books),
        oidos: oi,
        read: read,
        closed: closed,
        next: next,
        nextIsNew: nextHeard == 0,
      ),
    );
  }

  /// The story to hear next (order 27): of everything on the shelf, the one heard the fewest times (played on the map,
  /// or listened to here); of those, the one played last; then the shelf's own order. Its hearings come with it.
  (ShelfItem?, int) _pickNext(List<_Group> groups, Map<String, dynamic> oi) {
    final p = _s.progress;
    ShelfItem? best;
    var bestHeard = 0;
    var bestLast = 0;
    for (final g in groups) {
      for (final it in g.items) {
        if (_s.course.meta(it.id) == null) continue; // not drawn, not named
        final rec = p.story(it.id);
        final here = oi[it.id];
        final heard = (rec?.n ?? 0) + (here is num ? here.truncate() : 0);
        final last = rec?.ultima ?? rec?.primera ?? 0;
        if (best == null ||
            heard < bestHeard ||
            (heard == bestHeard && last > bestLast)) {
          best = it;
          bestHeard = heard;
          bestLast = last;
        }
      }
    }
    return (best, bestHeard);
  }

  // app.html: libro (the file is asked for once; a story with no book is null)
  Future<void> _book(String id) async {
    if (_books.containsKey(id)) return;
    try {
      _books[id] = await _s.course.book(id);
    } on Object {
      _books[id] = null;
    }
  }

  void _listen(ShelfItem it) {
    _s.haptics.tick();
    _s.nav.go(StoryRoute(it.id, listen: it.listen));
  }

  void _read(String id) {
    _s.haptics.tick();
    unawaited(_s.clips.unlock()); // the sound opens inside the tap
    _s.nav.go(BookRoute(id));
  }

  /// The first page of [it]'s book, or null: a routine, a book that could not be fetched, a book with no pages.
  /// Every book has a cover, whether or not it reads well (order 27: the verdict is about the text, not the picture).
  BookPage? _coverPage(_Loaded d, ShelfItem it) {
    final b = d.books[it.id];
    return b != null && b.pages.isNotEmpty ? b.pages.first : null;
  }

  /// Read only when the book's own verdict says it reads well.
  bool _readable(_Loaded d, ShelfItem it) {
    final b = d.books[it.id];
    return b != null && b.readable && b.pages.isNotEmpty;
  }

  Widget? _cover(BookPage? page, double width) => page == null
      ? null
      : Image(
          image: widget.imageProvider(widget.imageUrl(page.image)),
          width: width,
          height: width / ShelfCover.aspect,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          // the picture does not load: the plain tile (app.html: onerror removes the image)
          errorBuilder: (context, error, stack) => ShelfCover(width: width),
        );

  Widget _readButton(
    _Loaded d,
    ShelfItem it,
    String title, {
    bool full = false,
  }) {
    final leido = d.read.contains(it.id);
    return ShelfButton(
      label: LibraryStrings.read,
      icon: CoquiIcons.read,
      kind: ShelfButtonKind.outline,
      check: leido,
      full: full,
      semanticLabel: LibraryStrings.readLabel(title, again: leido),
      onPressed: () => _read(it.id),
    );
  }

  // app.html: fila
  Widget? _row(_Loaded d, ShelfItem it) {
    final meta = _s.course.meta(it.id);
    if (meta == null) {
      return null; // a story the catalog does not know cannot be drawn
    }
    final heard = d.oidos[it.id];
    final sub =
        '${it.kind.isNotEmpty ? "${it.kind} · " : ""}'
        '${heard is num && heard != 0 ? LibraryStrings.heard(heard) : ""}'
        '${LibraryStrings.about(meta.minutes)}';
    return ShelfEntry(
      title: meta.title,
      subtitle: sub,
      cover: _cover(_coverPage(d, it), ShelfEntry.coverWidth),
      listen: PlayButton(
        quiet: true,
        semanticLabel: LibraryStrings.listenLabel(meta.title),
        onPressed: () => _listen(it),
      ),
      read: _readable(d, it) ? _readButton(d, it, meta.title) : null,
    );
  }

  /// The card at the top: the story to hear next, with the screen's one green button.
  Widget? _nextCard(_Loaded d) {
    final it = d.next;
    final meta = it == null ? null : _s.course.meta(it.id);
    if (it == null || meta == null) return null;
    return ShelfNextCard(
      eyebrow: LibraryStrings.hearNext,
      title: meta.title,
      subtitle: LibraryStrings.nextLine(
        d.nextIsNew ? LibraryStrings.newOnShelf : LibraryStrings.heardLeast,
        meta.minutes,
      ),
      cover: _cover(_coverPage(d, it), ShelfNextCard.coverWidth),
      listen: ShelfButton(
        label: LibraryStrings.listen,
        icon: CoquiIcons.play,
        kind: ShelfButtonKind.go,
        full: true,
        semanticLabel: LibraryStrings.listenLabel(meta.title),
        onPressed: () => _listen(it),
      ),
      read: _readable(d, it)
          ? _readButton(d, it, meta.title, full: true)
          : null,
    );
  }

  /// The grey line under a place's name: what is played of its stories, what is read of its books on the shelf.
  String _placeLine(_Loaded d, _Group g) {
    final books = g.items.where((it) => _readable(d, it)).toList();
    return LibraryStrings.placeLine(
      played: g.played,
      stories: g.place.stories.length,
      read: books.where((it) => d.read.contains(it.id)).length,
      books: books.length,
    );
  }

  // #fadeTab: shown while there is more to scroll (scrollY+innerHeight<scrollHeight-1)
  bool _onScroll(Notification n) {
    if (n is ScrollMetricsNotification || n is ScrollNotification) {
      final m = n is ScrollMetricsNotification
          ? n.metrics
          : (n as ScrollNotification).metrics;
      if (m.axis == Axis.vertical) {
        final more = m.extentAfter > 1;
        if (more != _more) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _more != more) setState(() => _more = more);
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final d = _loaded;
    final children = <Widget>[];
    if (d != null) {
      children.add(ScreenTitle(CoquiTabs.library.label));
      final next = _nextCard(d);
      if (next != null) children.add(CoquiCard(child: next));
      for (final g in d.groups) {
        children.add(SectionTitle(g.place.name));
        children.add(KeyLine(_placeLine(d, g)));
        children.add(
          CoquiCard(
            padding: const EdgeInsets.symmetric(horizontal: CoquiMetrics.s16),
            child: DividedRows(rows: [for (final it in g.items) ?_row(d, it)]),
          ),
        );
      }
      if (d.groups.isEmpty) {
        children.add(
          CoquiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LibraryStrings.emptyShelf, style: CoquiText.bodyMuted),
                const SizedBox(height: CoquiMetrics.s16),
                CoquiButton(
                  label: LibraryStrings.openMap,
                  icon: CoquiIcons.map,
                  onPressed: () {
                    _s.haptics.tick();
                    _s.nav.go(const TabRoute(CoquiTabs.mapId));
                  },
                ),
              ],
            ),
          ),
        );
      }
      if (d.closed != 0) {
        children.add(
          Block(
            top: CoquiMetrics.s24,
            child: Text(
              LibraryStrings.closed(d.closed),
              style: CoquiText.smallMuted,
            ),
          ),
        );
      }
    }
    return ColoredBox(
      color: CoquiColors.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<Notification>(
              onNotification: _onScroll,
              child: TabPage(controller: _scroll, children: children),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: CoquiLayout.tabBarHeight(context),
            child: ListFade(visible: _more),
          ),
        ],
      ),
    );
  }
}
