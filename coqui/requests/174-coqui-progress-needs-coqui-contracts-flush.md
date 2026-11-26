# Request: Optional FlushableProgressStore / ProgressFlush extension in coqui_contracts

## What I need

In `coqui/packages/core/coqui_contracts/lib/src/progress.dart`:

1. Add an optional interface `FlushableProgressStore`:
   ```dart
   abstract interface class FlushableProgressStore {
     void flush();
   }
   ```
2. Add a `ProgressFlush` extension on `ProgressStore`:
   ```dart
   extension ProgressFlush on ProgressStore {
     void flush() {
       final p = this;
       if (p is FlushableProgressStore) {
         (p as FlushableProgressStore).flush();
       }
     }
   }
   ```
3. (Once `FlushableProgressStore` lands in `coqui_contracts`, `PalabrasStore` can add `FlushableProgressStore` to its `implements` list alongside `ProgressStore`, `CallProgressStore`, and `LanguageProgressStore`, and feature callers like `feature_library`'s `TextReader` can call `progress.flush()` on dispose/exit.)

## Why

Issue #174 (`lane:coqui_progress`) adds `PalabrasStore.flush()` and `PalabrasStore.heard(String w, {bool save = false})` so callers that credit `heard()` outside `storyFinished()` (such as `TextReader` in `feature_library`) do not leave word mutations unsaved in memory on exit. Because feature packages depend only on `coqui_contracts` (never `coqui_progress`) and receive a `ProgressStore`-typed reference, they cannot call `PalabrasStore.flush()` or `heard(w, save: true)` without an optional interface + extension in `coqui_contracts` (following the same pattern as `CallProgressStore`/`CallProgress` and `LanguageProgressStore`/`LanguageProgress`).

## What I am using meanwhile

`PalabrasStore` exposes `void flush() => _save();` and `WordRecord heard(String w, {bool save = false})` directly on `PalabrasStore` without modifying `coqui_contracts` from this lane.

## Order and branch

- Order: 174 (Implement LanguageProgressStore & ProgressStoreCollection on PalabrasStore and persist flush/cefr hooks)
- Branch: `lane/coqui_progress/174`
