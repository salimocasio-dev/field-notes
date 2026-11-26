# Request: Stable widget keys and copy assertions in feature_words

## What I need

In `coqui/packages/features/feature_words/`:

### Already present on `main` (document as standing rule in `feature_words/AGENTS.md`)

Keep these existing keys stable as shell/integration test contracts:

- `Key('words-due-count')` — `coqui/packages/features/feature_words/lib/src/words_tab.dart:210`
- `Key('words-review-button')` — `coqui/packages/features/feature_words/lib/src/words_tab.dart:367`
- `ValueKey('word-row:${entry.record.w}')` — `coqui/packages/features/feature_words/lib/src/words_tab.dart:471`

### New keys requested

- Root key on `WordsTab` (`Key('words-tab')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

Words tab copy assertions (due-words caption, "Start review" label, section headings, word detail sheets) are owned and verified inside `coqui/packages/features/feature_words/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('WordsTab')` and quoted Words copy (`'Start review'`, `'words come\nback today'`) from `coqui/app/test/` so copy revisions in `feature_words` never break shell tests.

## What I am using meanwhile

`coqui/app/test/` checks `ShellKeys.tab('words')`, `Key('words-due-count')`, `Key('words-review-button')`, and `ValueKey('word-row:<word>')`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
