# Request: Populate course-level minApp in ContentCatalog

## What I need

Have `ContentCatalog` in `coqui/packages/core/coqui_content/lib/src/content_catalog.dart` read optional top-level `curso['minApp']` (`int?`, missing = `null`) from `datos/curso.json` and implement `MinAppCatalog` (`int? get minApp`). (Story-level `minApp` already works automatically because `ContentCatalog` parses entries with `StoryMeta.fromJson`. Also note: `AppInfoNumber.appNumber` already parses `FixedAppInfo.build` from `COQUI_BUILD` without requiring `coqui_platform` changes, though numbered phone store builds should pass `--dart-define=COQUI_BUILD=<n>` or implement `AppNumberInfo`.)

## Why

Issue `#61` defines `minApp` on both the course and each story in `coqui_contracts`, and `#62` will gate story playback via `course.minAppFor(storyId)` and `info.supportsMinApp(...)`. `ContentCatalog` lives in `coqui_content`, outside `#61`'s lane.

## What I am using meanwhile

`MinAppCatalog` and `CourseMinApp` are exported by `coqui_contracts`; catalogs that do not yet implement `MinAppCatalog` safely default `course.minApp` to `null` (any app) while still honoring story-level `StoryMeta.minApp`.

## Order and branch

- Order: Issue `#61` (`lane:coqui_contracts`)
- Branch: `lane/coqui_contracts/61`
