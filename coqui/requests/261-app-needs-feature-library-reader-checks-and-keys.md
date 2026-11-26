# Request: Library shelf & reader checks and stable keys in feature_library

## What I need

In `coqui/packages/features/feature_library/`:

1. Expose stable widget keys on `ReadingHome` and `TextReader`:
   - Shelf root (`Key('library-home')`) and primary action (`Key('library-write-story')`)
   - Shelf item rows (`ValueKey('library-book:<id>')`)
   - Reader close button (`Key('reader-close-button')`) and page counter (`Key('reader-page-counter')`)
   - Keep `ValueKey('book:<id>')` on `TextReader` as a stable contract key.
2. Own shelf display, text-only book rendering (no `Image` widgets), close/resume ("Continue reading") flow, and course-story exclusion assertions previously in `coqui/app/test/lessons_test.dart`, `tabs_test.dart`, and `previa_test.dart` inside `feature_library/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('ReadingHome')`, `byTypeName('TextReader')`, `find.byTooltip('Close')`, and quoted library copy (`'Write my story'`, `'Continue reading'`, `'Stories you make and books you add appear here.'`) from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` verifies `ShellKeys.tab('library')` mounting and `BookRoute('la-familia')` routing (via `go` and direct `/libro/la-familia`) using `ShellKeys.route(const BookRoute('la-familia'))`, `ValueKey('book:la-familia')`, and `handlePopRoute()`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
