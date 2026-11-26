# Request: Remove AllowAllEntitlements default on Services in coqui_ui

## What I need

In `coqui/packages/core/coqui_ui/lib/src/contracts.dart:205`, remove the default value `= const AllowAllEntitlements()` from `Services`'s `entitlements` constructor parameter and make it required:

- Change `this.entitlements = const AllowAllEntitlements(),` to `required this.entitlements,` on `Services(...)`.
- Update `coqui_ui` tests that construct `Services(...)` directly without passing `entitlements` (`coqui_testing`'s `fakeServices` already passes `FakeEntitlements()`).

## Why

Issue #256 (`lane:app`, audit story D1 / Finding P13) ensures release builds never silently fall back to `AllowAllEntitlements` by wiring an explicit `ReleaseEntitlements` in `coqui/app`. Keeping `= const AllowAllEntitlements()` as a default parameter on `Services` allows any production caller that forgets `entitlements:` to silently fall back to `AllowAllEntitlements` without a compile error.

## What I am using meanwhile

`coqui/app` now supplies `ReleaseEntitlements.preBilling(callsAllowed: info.callsAllowed)` explicitly via `AppPlatform.entitlements` into `Services(...)` in `coqui/app/lib/src/app.dart`, and verifies in `coqui/app/test/entitlements_test.dart` that `Services.entitlements` is never `AllowAllEntitlements`.

## Order and branch

- Order: 256 (`lane:app`, audit story D1 / Finding P13)
- Branch: `lane/app/256`
