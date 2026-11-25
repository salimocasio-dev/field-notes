# What I need

Optional `Language` parameter (defaulting to `Language.spanish`) on:

1. `repasoTokens(String s, {Language? language})` in `coqui_contracts/lib/src/repaso.dart`, routing through `(language ?? Language.spanish).normalize(s)` instead of hardcoding `Language.spanish.normalize(s)`.
2. `RepasoServing({..., Language? language})` (defaulting to `Language.spanish`), routing `_tokensOf(s)` through `repasoTokens(s, language: language)`.
3. `repasoServing(CourseCatalog course, ProgressStore progress)`, forwarding `language: course.language` into `RepasoServing`.

# Why

Issue #90 (N2.7 `feature_review` uses the course's language) requires `feature_review` to work for non-Latin courses such as the Arabic fake course (`FakeCourseCatalog.arabic()`, `script: 'Arab'`), including `¿Qué oyes?`, `Arma la frase`, `Parejas`, and `Dilo`.

Today `RepasoServing` calls `repasoTokens`, which hardcodes `Language.spanish.normalize(s)`. For Arabic text, `Language.spanish.normalize` strips all Arabic letters and returns an empty token list, which causes:
- `wrongTileChoices(..., singleWords: true)` to return empty for Arabic words (`_tokensOf(m.word).length == 1` is always `false`), blocking `Arma la frase`.
- `wrongTileChoices(..., singleWords: false)` to fail to filter out Arabic words that appear in the sentence.
- `repasoServing(course, progress)` (used by Map and Palabras counts) to drift from `RepasoPlanner` on non-Latin courses.

# What I am using meanwhile

`RepasoPlanner` in `coqui/packages/features/feature_review/lib/src/logic/repaso_plan.dart` accepts `Language? language` (passed `course.language` by `RepasoSession`), uses `foldedTokens(s, language: language)` in `repaso_words.dart`, and computes `wrongTileChoices` and `hearSentences` locally with `language` instead of delegating those two methods to `serving`. Once `coqui_contracts` accepts `Language` on `RepasoServing`, `RepasoPlanner` can pass `language: language` to `RepasoServing` and delegate back to it.

# Order and branch

- Order: #90 (`N2.7 feature_review uses the course's language`)
- Branch: `lane/feature_review/90`
