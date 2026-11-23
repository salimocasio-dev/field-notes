# Biblioteca

Biblioteca generates readings locally by combining reviewed story beats. It checks each draft against current ear records, prefers words due for review, and accepts optional practice words or phrases. Stage 4 is the threshold for known vocabulary. A draft needs at least 98% known word tokens. The initial plots are finite and some learner records will have no match.

Learners can paste text with a title. Generated and imported texts are stored through the app’s device storage. The reader keeps a bookmark, shows ear stages in the text and plays existing recordings when the catalog has them. An isolated word tap never falls back to a sentence. Successful audible playback counts toward ear progress. New text can be read without audio. The feature makes no generation or recording requests over the network.

## Integration

- `BookRoute(id)` still opens an available course transcript without scene screenshots. The map already replays course stories. Adding a transcript action to its **Listen again** UI belongs in `feature_map`.
- The current level check stores a course placement result. Biblioteca needs a verified CEFR band in `ProgressStore.levelResult['cefr']` to enable reading completion and encountered-word counts at A2 and above. Bookmarking and ear exposure work without that field.
- Isolated words and matching sentences use recordings already in the catalog. Narrating arbitrary imports and new stories requires a recording service and a separate budget decision.

## Standalone entry

Run `flutter run -d chrome -t tool/dev_main.dart` from this package. The default fixture includes checked vocabulary so generation and imports are both available. `?seed=vacio` reflects a learner without ear records. The dev entry uses fake audio timing.

The app uses the existing `LibraryModule` and `BookRoute`. Build web output with the repository’s pinned Flutter 3.50.0 and `--no-web-resources-cdn` to bundle CanvasKit locally.
