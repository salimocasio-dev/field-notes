# Request: Wire `fetchSplit` into `ContentCatalog` in `app`

## What I need

Update `coqui/app/lib/src/app.dart` (where `ContentCatalog` is instantiated) to pass the optional `fetchSplit` callback pointing at the `content/` tree (sibling to `historia/`, i.e. `../content/<path>` relative to `historia/` on the site and in local/integration runners) once split files under `content/` are deployed alongside `historia/`:

```dart
ContentCatalog(
  previaFetch(widget.platform.fetch, widget.platform.previa ?? noPrevia),
  fetchSplit: ...,
)
```

Also ensure `AppPlatform` / web/asset deployment serves `content/games/*.json` and `content/lines/<lang>/*.json` (including `words.json`) at that base path without breaking preview (`previa`) overlays for stories not yet in `content/`.

## Why

Issue `#59` (`lane:coqui_content`) adds split-story and per-language `words.json` support to `ContentCatalog` behind an optional `fetchSplit` parameter so existing `historia/`-only callers and tests remain unchanged, while `lane/coqui_content/59` may not edit `coqui/app/`.

## What I am using meanwhile

- `ContentCatalog(this._fetch, {FetchText? fetchSplit})` keeps `fetchSplit` optional so `app` and all existing callers compile and pass without changes.
- Split loading, multi-language switching, and full parity with all 70 `historia/cuentos/` + `content/` files are tested directly in `coqui_content` (`test/split_story_test.dart` and `test/real_tree_test.dart`).

## Order and branch

- Order: Issue `#59` (`lane:coqui_content`)
- Branch: `lane/coqui_content/59`
