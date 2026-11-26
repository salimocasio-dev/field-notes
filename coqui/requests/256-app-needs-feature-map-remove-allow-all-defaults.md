# Request: Remove AllowAllEntitlements defaults in feature_map

## What I need

In `coqui/packages/features/feature_map/`:

1. Remove the `= const AllowAllEntitlements()` constructor defaults on:
   - `coqui/packages/features/feature_map/lib/src/module.dart:16` (`MapModule`)
   - `coqui/packages/features/feature_map/lib/src/map_screen.dart:99` (`MapScreen`)
   - `coqui/packages/features/feature_map/lib/src/place_screen.dart:90` (`PlaceScreen`)
2. Because `Services.entitlements` is now present in `coqui_ui` and wired explicitly by `coqui/app`, have `feature_map` either read `services.entitlements` directly or require an explicit `Entitlements` parameter (keeping `AllowAllEntitlements` only in tests/fakes).

**Scheduling note:** **Land this request before N8.4 (`#222`) is claimed**, because the four map motion stories (`#222` to `#225`) run sequentially on those same files and would otherwise block this cleanup behind them.

## Why

Issue #256 (`lane:app`, audit story D1 / Finding P13) ensures release builds never silently fall back to `AllowAllEntitlements` by passing explicit `ReleaseEntitlements` into `MapModule`. Leaving `= const AllowAllEntitlements()` defaults on `MapModule`, `MapScreen`, and `PlaceScreen` allows callers that omit `entitlements:` to silently fall back to `AllowAllEntitlements` without a compile error.

## What I am using meanwhile

`coqui/app` passes `AppPlatform.entitlements` explicitly into `coquiModules(...)` and `MapModule(showPerf: switches.perf, entitlements: entitlements)`, and verifies in `coqui/app/test/entitlements_test.dart` that `MapModule.entitlements` matches `Services.entitlements` and is never `AllowAllEntitlements`.

## Order and branch

- Order: 256 (`lane:app`, audit story D1 / Finding P13)
- Branch: `lane/app/256`
