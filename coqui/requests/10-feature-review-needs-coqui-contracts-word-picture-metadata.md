## What I need

1. Add optional dedicated word-picture asset metadata (`picturable` flag and dedicated `word_assets/...` pair paths, separate from story-scene `ReviewPair`) to `RepasoWord` / `RepasoData` in `coqui_contracts` (or a dedicated catalog/contract field).
2. Update `RepasoServing.cualLines` and `RepasoServing.servable` in `coqui/packages/core/coqui_contracts/lib/src/repaso.dart` so Map and Palabras due counts (`"N words today"`) match `RepasoPlanner`'s `#10` rule: do not count story-scene `ReviewPair` crops as servable `¿Cuál?` items when no dedicated single-word `word_assets/...` asset exists.

## Why

Issue #10 removes story-scene crops (`ReviewPair` via `ScenePictures`) from `RepasoPlanner.cualLines` and `RepasoPlanner.servable`. Until `RepasoServing` in `coqui_contracts` applies the same rule (and surfaces dedicated `word_assets/...` metadata), `serving.canServe(w)` will still count the 4 `cual`-only words (`tengo hambre`, `tengo sed`, `listo`, `ya`) while `RepasoPlanner` drops them.

## What I am using meanwhile

Local `WordPictureAsset` and `isDedicatedWordAssetPath` in `feature_review/lib/src/logic/word_picture.dart`, gated in `RepasoPlanner`, `RepasoSession`, and `RepasoScreen` via an optional `wordAssets` map (default `{}`).

## Order and branch

- Issue #10 (`lane/feature_review/10`)
