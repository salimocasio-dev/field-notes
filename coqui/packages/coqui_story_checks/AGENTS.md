# coqui_story_checks

Every scene's play-every-path and sheet-rules checks, separated from `feature_story` so scene ports hold `lane:coqui_scenes` + `lane:coqui_story_checks` without colliding with `feature_story` work.

- Kind: Flutter package (checks only; `app` never depends on it).
- One package is one lane. Branch: `lane/coqui_story_checks/<order number>`, or `story/<n>` with `lane:coqui_scenes` for a scene port.
- The runbook is `../../AGENTS.md`. Read it first.

## May depend on

- Coquí packages: `coqui_contracts`, `coqui_pixel`, `coqui_scenes`, `feature_story`.
- Third party: `collection` (allowed anywhere).
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Material widgets are not used here. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_story_checks.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Exports the shared check helpers (`DiskCourse`, `findRoot`, `ToolProgress`, `realScene`, `realSceneFor`, `startFrogOf`, `frogShadowOf`).

## Layout

- `test/fixtures/<scene>/`: each scene's three story JSON files (never under `historia/cuentos/`).
- `test/support/<scene>_paths.dart` and `<scene>_rules.dart`: draw enumeration, story runner wrappers, and sheet rule checkers.
- `test/<scene>_stories_test.dart`: representative-path + sheet-rules tests run by `flutter test` and `coqui/tool/test_all.sh`.
- `tool/<scene>_paths_test.dart`: play-every-path runners (`--dart-define=SHARD=i/n`, `OUT=dir`, `ONLY=story`, plus scene-specific options like `COVER=rounds` or `SEEDS=n`).

## Run and test it alone

```
cd coqui/packages/coqui_story_checks
flutter test
flutter test tool/<scene>_paths_test.dart
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```
