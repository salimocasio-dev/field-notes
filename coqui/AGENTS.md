# Coquí runbook

Read this whole page before you touch anything. You are a builder working for an orchestrator who makes every decision. Do exactly the task you were given. When something needs a choice that your task does not settle, stop and report it instead of choosing.

## What you are given

- Your order, whole.
- This page.
- Page 12 (`docs/proyecto/12-flutter-contracts.md`), the sections your order names.
- Your package's `AGENTS.md`.
- The old files your order names, and the `coqui/ref/` folders it names.
- Nothing else. A builder makes no decisions.

## Where things are

```
coqui/
  pubspec.yaml        the workspace root (pub workspaces)
  AGENTS.md           this page
  .flutter-version    the pinned Flutter: 3.50.0
  analysis_options.yaml   the one analysis file
  requests/           what a builder needs from a package it may not touch
  tool/               check_boundaries.dart, test_all.sh, exports, reference dumps
  ref/                reference data made from the old code
  app/                the shell
  packages/core/      coqui_contracts, coqui_progress, coqui_content, coqui_platform,
                      coqui_pixel, coqui_scenes, coqui_ui, coqui_testing
  packages/features/  feature_map, feature_story, feature_review, feature_words,
                      feature_library, feature_speaking, feature_profile
```

## Lanes

- One package is one lane. One order changes files in one package.
- Your branch is `lane/<package>/<order number>`. For example `lane/feature_words/21`.
- The branch changes files in your package and in `coqui/requests/`. Nowhere else.
- The check script fails a lane branch that changes anything else.
- The orchestrator's own branches are not lanes.
- Core packages have one writer at a time, named in the order.

### The packages and what each may depend on

This is the plan's table "Packages: what each replaces and what it may depend on", without its "Replaces" column. `app` may depend on everything.

| Package | Kind | May depend on |
| --- | --- | --- |
| coqui_contracts | pure Dart | nothing |
| coqui_progress | pure Dart | contracts |
| coqui_content | pure Dart | contracts |
| coqui_platform | Flutter | contracts, plugins |
| coqui_pixel | pure Dart | contracts |
| coqui_scenes | Flutter | pixel, contracts, ui |
| coqui_ui | Flutter | Flutter only |
| coqui_testing | Flutter | contracts, ui |
| feature_map | Flutter | contracts, ui, pixel |
| feature_story | Flutter | contracts, ui, pixel, scenes |
| feature_review | Flutter | contracts, ui |
| feature_words | Flutter | contracts, ui |
| feature_library | Flutter | contracts, ui |
| feature_speaking | Flutter | contracts, ui |
| feature_profile | Flutter | contracts, ui |
| app | Flutter | everything |

"Flutter only" means the Flutter SDK and no Coquí package. "plugins" means the third-party packages below.

## The boundary rules

The check script enforces 1 to 5 on every branch.

1. A feature never depends on another feature. Not in its pubspec, not by import.
2. A package depends only on the packages in its row above.
3. A package's public surface is one file, `lib/<package>.dart`. Everything else is under `lib/src/`. Nobody imports another package's `src/`.
4. A feature exports one thing: its module. The shell holds the only list of modules.
5. One order changes files in one package. A branch that touches two fails, unless it is the orchestrator's. `coqui/requests/` is open to all.
6. Shared state is the progress store, nothing else. A feature's own settings live in its own storage space.
7. Core packages have one writer at a time, named in the order. A builder that needs something from a package it may not touch files a request, uses the fake or a local copy, and carries on.
8. Content is data. Code builders do not edit content. Content builders do not edit code.
9. No Spanish text and no clip id in engine or feature code. They come from content.

## Third-party packages

- These, and no others. Each is added now, at this version.
- Builders may not add a package. File a request in `coqui/requests/`.
- The check script fails a pubspec that lists a package outside this table. Its list is at the top of `tool/check_boundaries.dart`.

| Package | Version | Who may list it |
| --- | --- | --- |
| just_audio | ^0.10.6 | coqui_platform only (the audio player) |
| speech_to_text | ^7.5.0 | coqui_platform only |
| shared_preferences | ^2.5.6 | coqui_platform only |
| web | ^1.1.2 | coqui_platform only |
| go_router | ^18.1.4 | app only |
| collection | ^1.19.1 | any package |
| flutter_lints | ^6.0.0 | Flutter packages, dev only |
| lints | ^6.0.0 | pure Dart packages, dev only |
| test | ^1.32.0 | pure Dart packages, dev only |
| flutter_test | from the Flutter SDK | Flutter packages, dev only |

## Machine notes

- Flutter 3.50.0 (stable) with Dart 3.14.0. The version is in `coqui/.flutter-version` and in every pubspec. CI reads the same file.
- Before `dart test -p chrome` or `flutter test --platform chrome`: `export CHROME_EXECUTABLE=/opt/sdk/chrome-nosandbox.sh`.
- You run as root. Ignore the superuser warning.
- Another agent may use the same Flutter SDK at the same time. "waiting for another flutter command" is normal. Wait.
- Network: pub.dev works. Most other hosts are blocked.

## Commands

All at `coqui/` unless it says otherwise.

```
flutter pub get
dart run tool/check_boundaries.dart
dart run tool/check_boundaries.dart --base main   # a lane branch against another ref
dart test tool/test                  # the check script's own tests
dart format .                        # fix formatting
dart format --output=none --set-exit-if-changed .
flutter analyze
bash tool/test_all.sh                # all of the above, every test, and the web build
```

In a package:

```
dart test -p vm && dart test -p chrome    # pure Dart packages
flutter test                              # Flutter packages
```

`tool/test_all.sh` is what CI runs (`.github/workflows/coqui.yml`). Both run the same steps in the same order.

## Page 12, section 1: Words used on these pages

- **Old code:** the JavaScript under `historia/` and `docs/proyecto/pixel/`. It is the reference. Builders never edit it.
- **Lane:** one package. **Order:** one task for one builder in one lane.
- **Port:** the same behaviour in Dart, line for line where possible. Not a redesign. Not an improvement.
- **Set:** a scene's background, built with the Pixel Plays engine (page 11-pixel-engine).
- **Set reference:** a scene's set built first in JavaScript, like `pixel/frente-set.html`, with every state. Design work, done and checked before any builder ports it.
- **Sheet:** the data that goes with a set reference (section 5).
- **Sprite layer:** everything drawn over the set: characters, props that move, signs, bubbles.
- **Picture:** a `Uint32List` of width × height pixels, each `0xAABBGGRR` (the engine's `rgb()`), RGBA bytes in memory order.

## Page 12, section 6: Porting rules, JavaScript to Dart

These are where a port goes wrong without anyone noticing. Pure-Dart packages run their tests twice, `dart test -p vm` and `dart test -p chrome`: numbers behave differently on a phone and in a browser.

| JavaScript | Dart, exactly |
| --- | --- |
| `x \| 0` | `x.truncate()` for a number in int range. For a hash, `toInt32(x)` from coqui_pixel (wraps to 32 bits) |
| `Math.imul(a, b)` | `imul(a, b)` from coqui_pixel (16-bit halves). Never `a * b` on 32-bit values: the web loses bits |
| `>>>`, `>>`, `<<` on 32-bit values | the same operator, then `& 0xFFFFFFFF`. Check both test platforms |
| `a % b` with a negative `a` | `a.remainder(b)`. Dart's `%` never returns a negative |
| `Math.round(x)` | `(x + 0.5).floor()`. Dart's `round()` differs for negative halves |
| `Math.hypot`, `Math.cbrt` | `sqrt(a*a + b*b)`; `pow(x, 1/3)` for x ≥ 0 |
| `if (x)`, `x \|\| y`, `!x` on numbers, strings, null | spell it out: `x != 0`, `x != null && x.isNotEmpty`, `x ?? y`. JavaScript treats 0, "", null, undefined and NaN as false |
| `a == b` across types | compare the same types. `== null` covers undefined too |
| Reading past the end of a list, or a missing key | JavaScript gives undefined; Dart throws. Guard it the way the old code relies on |
| `arr.sort(f)` | JavaScript's sort is stable. Use `mergeSort` from package:collection, or add the index as a tie-break |
| `Math.random()` | the `Rng` passed in. Never a new one. `Math.floor(Math.random() * n)` is `(rng.next() * n).floor()` |
| `Date.now()`, `new Date()` | the `Clock` passed in |
| `setTimeout`, `await sleep(ms)` | the host's `wait` or `sleep`. Never `Future.delayed` in engine, scene or runner code: tests run on a fake clock |
| An `async` act that is not awaited (`suelto`) | keep it un-awaited, exactly where the old code does |
| Float32Array | `Float32List`. Do not swap it for doubles: `zb[i] === groundZ[i]` depends on the rounding |
| Colours `#RRGGBB` | convert once to `0xFFBBGGRR` |
| `canvas`, `document`, `localStorage`, `fetch`, `AudioContext` | never in a port. Each is behind a contract |

Other rules:

- Keep the old function's name in a comment above each ported function (`// juego.js: decide`).
- Keep the old code's constants as they are. A number that looks arbitrary was tuned.
- Do not fix a bug you find in the old code. Port it and report it.
- No Spanish text and no clip id in code. Take the fixed lines from `course.fixedClip(role)`.
- English on screen stays exactly as in v=39. Copy the strings.
- No `print`. No TODO left behind. `dart format`. `flutter analyze` with zero issues.

## Page 12, section 7: Commands and reports

- Get packages: `flutter pub get` at `coqui/`.
- One package's tests: `flutter test` in the package; pure Dart packages: `dart test -p vm` and `dart test -p chrome`.
- The boundary check: `dart run tool/check_boundaries.dart` at `coqui/`.
- A feature alone: `flutter run -d chrome -t lib/dev_main.dart` in the feature.
- A story played with no screen: `dart run tool/juega.dart <story> <plan> <seed>` at `coqui/` (after order 15).
- Git: branch `lane/<package>/<order number>`, your own worktree, commit small, push often. Never push to main. Never open a pull request. Never touch `historia/`, `docs/` or another package.
- Nothing that costs money: no ElevenLabs calls or tests, no push under `historia/cuentos/` (it starts the paid audio job), no accounts, no keys.
- Report, short: what you did; each check and its number; what failed; requests filed; anything you had to choose (there should be nothing). Never claim a check you did not run.

## Audio (costs money: read carefully)

- Pushing a file under `historia/cuentos/` starts the "Voz" workflow (id 417069462), which records every new line with Azure and commits "Audio: cuento". A line pushed early and changed later is recorded twice.
- So story JSON is kept OUT of git (`.git/info/exclude`) until the orchestrator says its Spanish is final. Do not remove exclude lines unless your task says so.
- Generators print "N clips, M new, C characters to record". Report C. Never push anything that would record more than your task allows.
- ElevenLabs is never used by builders. No accounts, no keys, no spending, no emails.

## Reporting back

- Keep the final report short: what you did, what you checked and how (numbers), what failed, anything that needs a decision. Paths to any sheets you made. Never claim a check you did not run.
