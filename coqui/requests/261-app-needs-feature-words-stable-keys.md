# Request: Stable widget keys and copy assertions in feature_words

## What I need

In `coqui/packages/features/feature_words/`:

1. Treat the existing keys (`Key('words-due-count')`, `Key('words-review-button')`, `ValueKey('word-row:<word>')`) as stable public test keys, and add a root key on `WordsTab` (e.g. `Key('words-tab')`).
2. Keep Words tab wording assertions (e.g. due-words caption, "Start review" label, section headings) inside `feature_words/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('WordsTab')` and quoted Words copy (`'Start review'`, `'words come\nback today'`) from `coqui/app/test/` so copy revisions in `feature_words` never break shell tests.

## What I am using meanwhile

`coqui/app/test/` checks `ShellKeys.tab('words')`, `Key('words-due-count')`, `Key('words-review-button')`, and `ValueKey('word-row:<word>')`.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
