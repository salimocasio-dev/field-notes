# Request: Add Entitlements field to Services in coqui_ui

## What I need

Add `Entitlements entitlements = const AllowAllEntitlements()` to `Services` in `coqui_ui` (`lib/src/contracts.dart`) so features and `fakeServices` can wire `Entitlements` cleanly without breaking existing `Services(...)` callers.

## Why

Issue #85 (N2.2) adds `FakeEntitlements` in `coqui_testing`; `Services` currently has no `entitlements` field, so `fakeServices(...)` cannot wire `FakeEntitlements` into `Services` yet.

## What I am using meanwhile

`FakeEntitlements` is exported directly from `coqui_testing`, and `fakeServices(...)` stays unchanged so all existing callers continue working.

## Order and branch

Issue #85 (N2.2), branch `lane/coqui_testing/85`.
