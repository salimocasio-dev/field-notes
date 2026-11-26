# Request: Library shelf & reader checks and stable keys in feature_library

## What I need

In `coqui/packages/features/feature_library/`:

### Already present on `main` (document as standing rule in `feature_library/AGENTS.md`)

Keep this existing key stable as a shell/integration test contract:

- `ValueKey('book:${route.id}')` — `coqui/packages/features/feature_library/lib/src/module.dart:25`

### New keys requested

- Shelf root (`Key('library-home')`) and primary action (`Key('library-write-story')`)
- Shelf item rows (`ValueKey('library-book:<id>')`)
- Reader close button (`Key('reader-close-button')`) and page counter (`Key('reader-page-counter')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

The library shelf and reader assertions removed from `coqui/app/test/lessons_test.dart`, `tabs_test.dart`, and `previa_test.dart` are already covered inside `feature_library/test/`:

- `coqui/packages/features/feature_library/test/module_test.dart:78` — text-only book rendering (`find.byType(Image)` -> `findsNothing`, enforcing product rule 4)
- `coqui/packages/features/feature_library/test/reading_home_test.dart:426-445` — shelf -> `TextReader` -> close -> `Continue reading` resume flow
- `coqui/packages/features/feature_library/test/reader_test.dart:1049` — reader pagination and close behavior.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('ReadingHome')`, `byTypeName('TextReader')`, `find.byTooltip('Close')`, and quoted library copy (`'Write my story'`, `'Continue reading'`, `'Stories you make and books you add appear here.'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `ShellKeys.tab('library')` mounting and `BookRoute('la-familia')` routing (via `go` and direct `/libro/la-familia`) using `ShellKeys.route(const BookRoute('la-familia'))`, `ValueKey('book:la-familia')`, `expect(find.byType(Image), findsNothing)` (shell defense-in-depth for product rule 4), and `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
