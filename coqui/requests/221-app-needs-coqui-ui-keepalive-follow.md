# Request: Keep-alive / indexed NocheFollow in coqui_ui

## What I need

In `coqui/packages/core/coqui_ui/`:

Add a keep-alive or indexed variant of `NocheFollow` (e.g., `NocheFollowDeck` or `NocheFollow.keepAlive`) that accepts already-built or keyed slots (`List<Widget>` / `Map<Object, Widget>` or indexed children) and keeps every visited child mounted offstage (`Offstage` + `TickerMode` + `IgnorePointer` + `ExcludeSemantics`) without assigning a fresh `GlobalKey` on switch or unmounting `_outgoingChild` at `press`.

## Why

Order #221 (`N8.3 The shell: tabs, lessons, loading`) requires `AppShell` to animate tab switches using `NocheFollow` semantics (`NocheFollowSide`, distance `NocheMotion.tab`, `press` outgoing fade on `exit`, `followAfter` + `move` incoming slide/fade on `enter`). However, `AppShell` must keep every visited tab alive offstage (`MapScreen` must only bake once, and `coqui/app/test/tabs_test.dart` asserts `findShellTab(id, skipOffstage: false)` finds all 5 tabs). Currently `NocheFollow` in `coqui_ui` creates a fresh `GlobalKey()` on every `contentKey` change and unmounts `_outgoingChild` when `press` completes, which would dispose and recreate tab `State`.

## What I am using meanwhile

`AppShell` (`coqui/app/lib/src/shell.dart`) implements a local keep-alive `NocheFollow` equivalent inside `_AppShellState` using `NocheMotion.of(context)` and `NocheFollowSide`, keeping every built tab permanently mounted in the same `Stack` slot with fixed wrapper keys (`ShellKeys.tabMotion(id)`, `ShellKeys.tabOpacity(id)`, `ShellKeys.tab(id)`).

## Order and branch

- Order: 221 (`lane:app`)
- Branch: `lane/app/221`
