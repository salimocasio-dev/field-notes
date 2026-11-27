# Request: Book body / file storage contract and platform store in `coqui_contracts` + `coqui_platform`

## What I need

1. A contract in `coqui_contracts` (e.g. `BookFileStore` exposed on `Services` or an optional capability interface following the `DeletableKeyValueStore` pattern) for storing and retrieving imported personal book bodies outside `localStorage` / `SharedPreferences` size limits (for example, IndexedDB on web and app-private document files on iOS/Android):
   - `Future<void> writeBook(String id, String content)` (throwing a typed storage-full error when device quota is exceeded rather than dropping writes silently)
   - `Future<String?> readBook(String id)`
   - `Future<void> deleteBook(String id)`
2. Platform implementations in `coqui_platform` (IndexedDB on web, local file directory on mobile, in-memory fake in `coqui_testing`) wired through `app`.

## Why

Story N5.4 ("Add your own: the screen, paste text and plain text files", issue #115) saves learner-imported `.txt` books and pasted texts so they persist across restarts and open in `TextReader`. Large plain-text books (and upcoming EPUB/PDF/DOCX imports in N5.5–N5.7) can exceed browser `localStorage` (~5 MB) limits. Under `coqui/AGENTS.md` boundary rule 7, `lane/feature_library/115` may not edit `coqui_contracts`, `coqui_platform`, `coqui_testing`, or `app`.

## What I am using meanwhile

- `ReadingStore` in `coqui/packages/features/feature_library/lib/src/reading.dart` splits each book's body into its own `KeyValueStore` entry (`body:<id>`) instead of duplicating the full text inside the `'texts'` index JSON, while remaining 100% backward compatible with legacy inline `'body'` entries.
- `ReadingStore.add` verifies read-back of both `body:<id>` and `'texts'` after writing, cleans up `body:<id>` via `storage.delete(...)` on failure or silent browser quota drop, and throws `ReadingStorageFullException`, which `BookImporter` surfaces to the learner as a calm error card (`LibraryWording.errorStorageFull`).

## Order and branch

- Order: #115 (N5.4 Add your own: the screen, paste text and plain text files)
- Branch: `lane/feature_library/115`
