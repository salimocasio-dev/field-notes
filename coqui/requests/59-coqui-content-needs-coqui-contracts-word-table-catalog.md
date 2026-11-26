# Request: Optional `WordTableCatalog` interface on `CourseCatalog`

## What I need

Add an optional `WordTableCatalog` interface and `CourseWordTable` extension on `CourseCatalog` in `coqui/packages/core/coqui_contracts/` (following the existing `LanguageCatalog` / `CallsCatalog` / `MinAppCatalog` pattern):

- `abstract interface class WordTableCatalog`:
  - `Map<String, String> get wordTable;`
  - `String resolveWord(String testedId, {Map<String, dynamic>? storyPalabras});`
- `extension CourseWordTable on CourseCatalog`:
  - `Map<String, String> get wordTable` returning `const {}` when the catalog does not implement `WordTableCatalog`.
  - `String resolveWord(String testedId, {Map<String, dynamic>? storyPalabras})` implementing the `docs/proyecto/23-split-story-format.md` precedence (`storyPalabras[testedId]` when non-empty string -> `wordTable[testedId]` when non-empty string -> `testedId`).

Once added, `ContentCatalog` can add `WordTableCatalog` to its `implements` list without breaking any existing `CourseCatalog` fakes.

## Why

Issue `#59` (`lane:coqui_content`) loads `lines/<lang>/words.json` into `ContentCatalog.wordTable` and exposes `resolveWord`, while `lane/coqui_content/59` cannot edit `coqui/packages/core/coqui_contracts/`. Downstream consumers (such as `feature_story` `#58` if it reads the table directly instead of relying solely on the joined `story['palabras']` map) may want typed access through `CourseCatalog`.

## What I am using meanwhile

- `ContentCatalog` directly exposes `wordTable` and `resolveWord(testedId, storyPalabras: ...)`, and exports `resolveTestedWord` from `package:coqui_content/coqui_content.dart`.
- When `ContentCatalog` joins a split story via `joinSplitStory`, it merges `wordTable` beneath per-story `lines['palabras']` into the returned `story(id)['palabras']` map, so `feature_story`'s `steps.dart` already resolves tested IDs to target-language words and logs `Decision.word` into `coqui_progress` under the course language without changes to `coqui_progress` or `coqui_contracts`.

## Order and branch

- Order: Issue `#59` (`lane:coqui_content`)
- Branch: `lane/coqui_content/59`
