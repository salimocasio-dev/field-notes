# Request: Stable widget keys and copy assertions in feature_profile

## What I need

In `coqui/packages/features/feature_profile/`:

1. Treat the existing keys on Welcome (`ValueKey('welcome-step-0')`..`ValueKey('welcome-step-2')`, `ValueKey('welcome')`, `Key('welcome-next-button')`, `Key('welcome-new-button')`), Me (`Key('me-scroll')`, `Key('yo-level-check')`), Plans (`Key('plans-scroll')`), and Languages (`ValueKey('language-card-<code>')`) as stable test keys, and add root keys on `LanguagesSheet` (`Key('languages-sheet')`) and `PlansScreen` (`Key('plans-screen')`).
2. Keep Me tab metric formatting and Welcome copy assertions (`'Next'`, `"I'm new to Spanish"`, `'0 of 78 good'`, `'A1 · place 2 of 10'`) inside `feature_profile/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('PlansScreen')`, `byTypeName('LanguagesSheet')`, and quoted profile/welcome copy from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` checks `ShellKeys.tab('me')`, `ShellKeys.route(const LanguagesRoute())`, `ShellKeys.route(const PlansRoute())`, and `feature_profile`'s existing keys (`ValueKey('welcome-step-0')`, `ValueKey('welcome-step-2')`, `Key('welcome-next-button')`, `Key('welcome-new-button')`, `Key('me-scroll')`, `Key('yo-level-check')`, `Key('plans-scroll')`, `ValueKey('language-card-es')`).

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
