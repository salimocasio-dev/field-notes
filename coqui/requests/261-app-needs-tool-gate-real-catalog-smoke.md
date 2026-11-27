# Request: Gate real_catalog_smoke_test.dart in coqui/tool/test_all.sh / CI workflows

## What I need

In `coqui/tool/test_all.sh` and `.github/workflows/coqui.yml`:

Optionally pass `--dart-define=COQUI_SKIP_SMOKE=true` when running `coqui/app` tests on fast feature-lane PR checks, while running `coqui/app/test/real_catalog_smoke_test.dart` without `COQUI_SKIP_SMOKE` on `main`, `lane:app` PRs, and release builds.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) consolidates full real-catalog gameplay into a single key-driven smoke test (`coqui/app/test/real_catalog_smoke_test.dart`) gated by `const _skipSmoke = bool.fromEnvironment('COQUI_SKIP_SMOKE')`. Because `lane:app` may not edit `coqui/tool/test_all.sh` or `.github/workflows/`, wiring the fast-PR skip flag needs an orchestrator/tooling follow-up.

## What I am using meanwhile

`_skipSmoke` defaults to `false`, so `coqui/app/test/real_catalog_smoke_test.dart` runs and passes by default under `flutter test` and `bash coqui/tool/test_all.sh`, and already supports `--dart-define=COQUI_SKIP_SMOKE=true` whenever `test_all.sh` or CI opts in.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
