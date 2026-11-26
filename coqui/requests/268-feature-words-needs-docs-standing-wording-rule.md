# Add standing feature screen-wording rule to `coqui/AGENTS.md`

## What I need

Add the standing rule from issue `#268` to `coqui/AGENTS.md` (alongside E1 `#257` docs updates):

> A feature's screen wording lives in one file in that feature (`lib/src/wording.dart`); screens and that feature's tests both read from it; no other package's tests look for a feature's wording.

## Why

Issue `#268` ("Screen wording in one file per feature") runs in `lane:feature_words`, which may only modify `coqui/packages/features/feature_words/` and `coqui/requests/`. Updating `coqui/AGENTS.md` belongs to `lane:docs` / E1 (`#257`).

## What I am using meanwhile

`feature_words` implements the pattern in `coqui/packages/features/feature_words/lib/src/wording.dart` (`WordsWording`) and reads every user-visible and semantic string from it across `lib/src/` and `test/`.

## Order and branch

Issue `#268` · branch `lane/feature_words/268`.
