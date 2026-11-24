# Request: Update app/test reader page count assertion for N5.1 pagination

## What I need

In `coqui/app/test/lessons_test.dart` test `(n)` at line 340, `'Mi cuaderno'` (`'Tengo un cuaderno. Es azul. Tiene papel. Escribo aquí.'`) currently asserts:

```dart
expect(find.text('1 / 2'), findsOneWidget);
```

Update line 340 to expect `'1 / 1'` (or `find.textContaining(' / ')`, matching line 360).

## Why

Story N5.1 ("The reader page", issue #112) replaces the legacy fixed 3-sentence-per-page chunker (`readingPageSize = 3`) in `TextReader` with dynamic `TextPainter` pagination based on viewport size and `ReaderSettings`. Under N5.1 pagination, the 10 words of `'Mi cuaderno'` fit on a single page (`'1 / 1'`). `lane/feature_library/112` cannot edit files under `coqui/app/`.

## What I am using meanwhile

All tests inside `feature_library` are updated for N5.1 dynamic pagination, and `readingProgress` in `reading.dart` preserves the legacy `readingPageSize` fallback when `ReadingPlace.totalPages` is null so existing `reading_home_test.dart` assertions stay green.

## Order and branch

Order #112 (N5.1), branch `lane/feature_library/112`.
