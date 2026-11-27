# Request: Stable per-tab item keys on NocheTabBar in coqui_ui

## What I need

In `coqui/packages/core/coqui_ui/`:

Add a stable `ValueKey('tab-item:$id')` (or `NocheTabBar.itemKey(String id)`) on each interactive tab item rendered inside `NocheTabBar`, so tests can tap tabs by tab id without looking up localized labels from `Language.tabNames`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes text-based lookups from `coqui/app/test/`. Currently `TestApp.openTab(String id)` in `coqui/app/test/support/harness.dart` must look up `services.course.language.tabNames[id]!` and tap `find.descendant(of: find.byType(NocheTabBar), matching: find.text(label))`. Stable per-tab keys on `NocheTabBar` make tab tapping completely text-independent.

## What I am using meanwhile

`TestApp.openTab(String id)` taps `find.descendant(of: find.byType(NocheTabBar), matching: find.text(services.course.language.tabNames[id]!))` using the `Language.tabNames` contract map.

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
