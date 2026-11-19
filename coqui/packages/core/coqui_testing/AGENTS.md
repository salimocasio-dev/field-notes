# coqui_testing

A fake for every interface, and a tiny sample course.

- Kind: Flutter package.
- Replaces: (new).
- One package is one lane. Branch: `lane/coqui_testing/<order number>`.
- Work orders: 02, by the orchestrator.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, ui.
- Coquí packages: `coqui_contracts`, `coqui_ui`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_testing.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Since order 02 it holds a fake for every interface of page 12, sections 2 and 3, `fakeServices`, `FeatureDevApp` and the sample course (`sample/`, read through `lib/src/sample_files.dart`; both made by `coqui/tool/contracts/make_sample.mjs`). Each fake's doc comment says what it does and does not do.

## Run and test it alone

```
cd coqui/packages/core/coqui_testing
flutter test
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

None apply directly.
