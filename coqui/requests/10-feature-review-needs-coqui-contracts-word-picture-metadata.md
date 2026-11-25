## What I need

1. Add optional dedicated word-picture asset metadata (`picturable` flag and dedicated `word_assets/...` pair paths, separate from story-scene `ReviewPair`) to `RepasoWord` / `RepasoData` in `coqui_contracts` (or a dedicated catalog/contract field).
2. Confirm the hosting base path for dedicated `word_assets/...` files (whether under `libros/word_assets/...` via `ReviewModule.imageUrl` or a dedicated `wordAssetUrl` resolver on `ReviewModule` / `CourseCatalog`).

## Why

Issue #10 removes story-scene crops (`ReviewPair` via `ScenePictures`) and story-book screenshots from flashcards. `RepasoPlanner` stays 100% aligned with `RepasoServing.canServe` (used by Map and Palabras) by serving pair-only words (`tengo hambre`, `tengo sed`, `listo`, `ya`) via text-only `¿Qué oyes?` fallback sentences until dedicated `word_assets/...` metadata is added to `coqui_contracts`.

## What I am using meanwhile

Local `WordPictureAsset` and `isDedicatedWordAssetPath` in `feature_review/lib/src/logic/word_picture.dart`, gated in `RepasoPlanner`, `RepasoSession`, and `RepasoScreen` via an optional `wordAssets` map (default `{}`), plus text-only `HearItem` fallback for `cual`-only words so Map/Palabras due counts match Repaso's served words.

## Order and branch

- Issue #10 (`lane/feature_review/10`)
