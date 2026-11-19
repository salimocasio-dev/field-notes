/// Biblioteca: the shelf. One row for each story he has played: its cover, the title, Listen and Read.
/// app.html:323-341 (`biblioteca`).
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

  /// `""`, "Cuento con dibujos" or "Haz esto".
  final String kind;

  /// A routine (Haz esto) has no book: Listen only, and no request for a book.
  final bool routine;
}

/// The shelf, as the tab of the Biblioteca.
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
  const _Group(this.place, this.items);
  final Place place;
  final List<ShelfItem> items;
}

class _Loaded {
  const _Loaded({
    required this.groups,
    required this.books,
    required this.oidos,
    required this.read,
    required this.closed,
  });

  final List<_Group> groups;
  final Map<String, Book?> books;
  final Map<String, dynamic> oidos;
  final Set<String> read;
  final int closed;
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
            kind: LibraryStrings.pictureStory,
            routine: false,
          ),
        for (final c in haz)
          ShelfItem(
            id: c,
            listen: false,
            kind: LibraryStrings.routine,
            routine: true,
          ),
      ];
      if (items.isNotEmpty) groups.add(_Group(l, items));
    }
    final read = <String>{
      for (final g in groups)
        for (final it in g.items)
          if (p.hasRead(it.id)) it.id,
    };
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
      ),
    );
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

  // app.html: fila
  Widget? _row(_Loaded d, ShelfItem it) {
    final meta = _s.course.meta(it.id);
    if (meta == null) {
      return null; // a story the catalog does not know cannot be drawn
    }
    final b = d.books[it.id];
    // Read and the cover only when the book's own verdict says it reads well
    final page = b != null && b.readable && b.pages.isNotEmpty
        ? b.pages.first
        : null;
    final leido = d.read.contains(it.id);
    final heard = d.oidos[it.id];
    final sub =
        '${it.kind.isNotEmpty ? "${it.kind} · " : ""}'
        '${heard is num && heard != 0 ? LibraryStrings.heard(heard) : ""}'
        '${LibraryStrings.about(meta.minutes)}';
    return ShelfEntry(
      title: meta.title,
      subtitle: sub,
      cover: page == null
          ? null
          : Image(
              image: widget.imageProvider(widget.imageUrl(page.image)),
              width: ShelfEntry.coverWidth(MediaQuery.sizeOf(context).width),
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
      actions: [
        ShelfButton(
          label: LibraryStrings.listen,
          icon: CoquiIcons.play,
          kind: ShelfButtonKind.go,
          semanticLabel: LibraryStrings.listenLabel(meta.title),
          onPressed: () => _listen(it),
        ),
        if (page != null)
          ShelfButton(
            label: LibraryStrings.read,
            icon: CoquiIcons.read,
            kind: ShelfButtonKind.outline,
            check: leido,
            semanticLabel: LibraryStrings.readLabel(meta.title, again: leido),
            onPressed: () => _read(it.id),
          ),
      ],
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
      for (final g in d.groups) {
        children.add(SectionTitle(g.place.name));
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
            child: Text(LibraryStrings.emptyShelf, style: CoquiText.bodyMuted),
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
