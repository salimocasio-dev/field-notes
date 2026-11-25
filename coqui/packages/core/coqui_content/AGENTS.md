# coqui_content

Reads the course, stories, review sets, books, clip list. Pure Dart.

- Kind: pure Dart (no Flutter SDK).
- Replaces: curso.js, the pair index (`CU.items`), `NV` in nivel.js, `LLAMADAS` in llamada.js, the fetches of cuentos/, libros/, audio/ready.json.
- One package is one lane. Branch: `lane/coqui_content/<order number>`.
- Work orders: 17.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts.
- Coquí packages: `coqui_contracts`.
- Third party: `collection` ^1.19.1.
- Dev only: `lints`, `test`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_content.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Since order 17 it exports `ContentCatalog`, the `CourseCatalog` of page 12, section 2, over a `FetchText` (`Future<String> Function(String path)`, the path relative to `historia/`, for example `cuentos/la-lluvia.json`) the shell gives it.
- `load()` reads `datos/curso.json`, `datos/nivel.json`, `datos/llamadas.json`, `datos/fijos.json`, `audio/ready.json`, `audio/marcas.json` and the review sets `curso.json` names. `story(id)` and `book(id)` fetch on demand and keep the answer.
- A clip's who, text and habla are in the story files: `clip(id)` has them once a story with the clip has been read (the review sets are read by `load()`); before that it has the marks and the url, and the line `datos/fijos.json` holds for it under `lineas` (the lines the old code writes in code: juego.js line 103, `ahora_tu`; made by `coqui/tool/export_datos.mjs`), or an empty `who` and `text` where there is none. A story's own line wins once it has been read. A `fijos.json` without `lineas` is not an error.

- Order 27: `ContentCatalog` is also a `RepasoCatalog`: `load()` reads `datos/repaso.json` into `repaso`, beside the
  other files; when it is missing or cannot be read, `repaso` is null and the load goes on (Repaso then plays today's game).

- Order 27 (the words said alone): `load()` also reads `cuentos/palabras-solas.json`, the one file of `cuentos/` the course
  names nowhere (each tracked word alone, clips `w_<word>`; `tipo` "palabras"). It is not a story and not a review set: no
  `meta`, no pair, no place lists it. Its clips are known like the others, by `clip(id)`, with their who and text from load
  on (a story that has the same id wins once it is read). Missing or unreadable, it is no error: those clips then have
  their marks and url and no line, like any clip no story has been read for.
- Issue #6 (`CallsCatalog`): `ContentCatalog` implements `CallsCatalog` (`callsFor(placeId)`) and parses both legacy single-object entries and multi-call JSON arrays in `datos/llamadas.json` (`callFor(placeId)` returns the `isMain` call, or the first call when none sets `isMain`). The 31 reviewed calls (10 main + 21 smaller) live as pure course JSON data in `data/llamadas.json` until promoted to `historia/datos/llamadas.json` (see `coqui/requests/6-coqui-content-needs-content-publish-llamadas-data.md`).
- Issue #175 (`MinAppCatalog`): `ContentCatalog` implements `MinAppCatalog`, reading optional top-level `minApp` from `datos/curso.json` into `minApp` (`null` when missing or null) alongside per-story `StoryMeta.minApp`.
- Issue #59 (split-story format & word table): `ContentCatalog` accepts optional `fetchSplit` (`games/<id>.json`, `lines/<lang>/<id>.json`, `lines/<lang>/words.json`), joins split game/lines for the course's `language.code` with legacy `cuentos/<id>.json` fallback, and exposes `wordTable`, `resolveWord`, and split helpers (`joinSplitStory`, `parseWordTable`, `resolveTestedWord`).

## Run and test it alone

```
cd coqui/packages/core/coqui_content
dart test -p vm
dart test -p chrome   # needs CHROME_EXECUTABLE, see the runbook
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 10-leer-y-repaso, "Rules that bind this (his)":

- No English in learning content: no translation, no gloss. English only in menus, labels, the welcome, the stuck line.
- Spanish text is shown exactly as recorded.

From 03-requirements, "Audio and voice (Nov 13)":

- "Okay - we'll go recorded". The audio is made once and saved as files (on Azure). It is not generated on demand each time a line plays.

From 10-leer-y-repaso, "What goes in a book (the text)":

- Routines (Haz esto) get no book: all their lines are commands. On the shelf they have Listen only.

## Test fixtures (order 17)

- `test/content_catalog_test.dart` runs on vm and chrome over a small course embedded as Dart strings (`test/fixture/small_tree.dart`). `test/real_tree_test.dart` is vm only: it reads the real files under `historia/`.
- The expected answers are the old code's, run in node: `cual.js` `cualCarga()`, `app.html` `pares()` and `oidoEn()`. They are in `test/fixture/small_expected.dart` and `test/fixture/real_expected.json`.
- To remake all three (after a change in `historia/` or in the old functions): `bash tool/make_fixtures.sh` in this folder. It says "unchanged (byte for byte)" when nothing differs. The scripts are `tool/old_code.mjs` (takes the old functions out of the old files and runs them), `tool/make_expected.mjs` and `tool/make_fixture.mjs`.
