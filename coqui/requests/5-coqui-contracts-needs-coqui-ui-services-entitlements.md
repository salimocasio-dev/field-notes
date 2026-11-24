# Request: Expose Entitlements on Services in coqui_ui

## What I need

Add `final Entitlements entitlements;` with default `this.entitlements = const AllowAllEntitlements()` to `Services` in `coqui/packages/core/coqui_ui/lib/src/contracts.dart` (using `Entitlements` and `AllowAllEntitlements` already exported by `coqui_contracts`).

## Why

Request 25 section 3 and issue `#5` ask to expose `Entitlements` on `Services` with an allow-all default so `feature_speaking` and other features can read `services.entitlements` instead of local hooks. `Services` lives in `coqui_ui`, outside `#5`'s lane.

## What I am using meanwhile

`Entitlements`, `AllowAllEntitlements`, `Plan`, and `Feature` remain exported by `coqui_contracts`; `feature_speaking` continues using its local `CallEntitlement` hook until `coqui_ui` exposes `Services.entitlements`.

## Order and branch

- Order: Issue `#5` (`lane:coqui_contracts`)
- Branch: `story/5`
