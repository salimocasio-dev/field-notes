# Request: Stable widget keys and copy assertions in feature_profile

## What I need

In `coqui/packages/features/feature_profile/`:

### Already present on `main` (document as standing rule in `feature_profile/AGENTS.md`)

Keep these existing keys stable as shell/integration test contracts:

- `ValueKey('welcome-step-$step')` — `coqui/packages/features/feature_profile/lib/src/welcome.dart:82`
- `Key('welcome-next-button')` — `coqui/packages/features/feature_profile/lib/src/welcome.dart:287`
- `Key('welcome-new-button')` — `coqui/packages/features/feature_profile/lib/src/welcome.dart:300`
- `Key('me-scroll')` — `coqui/packages/features/feature_profile/lib/src/yo_screen.dart:261`
- `Key('yo-level-check')` — `coqui/packages/features/feature_profile/lib/src/yo_screen.dart:939`
- `Key('plans-scroll')` — `coqui/packages/features/feature_profile/lib/src/plans_screen.dart:105`
- `Key('plans-back')` — `coqui/packages/features/feature_profile/lib/src/plans_screen.dart:252`
- `ValueKey('language-card-${yourLanguages[i].language.code}')` — `coqui/packages/features/feature_profile/lib/src/languages_sheet.dart:145-147`

### New keys requested

- Root keys on `LanguagesSheet` (`Key('languages-sheet')`) and `PlansScreen` (`Key('plans-screen')`).

### Already-merged feature test coverage on `main` (zero coverage loss)

Me tab metric formatting, Plans cards, Languages picker, and Welcome copy assertions (`'Next'`, `"I'm new to Spanish"`, `'0 of 78 good'`, `'A1 · place 2 of 10'`) are owned and verified inside `coqui/packages/features/feature_profile/test/` rather than `coqui/app/test/`.

## Why

Issue #261 (`lane:app`, `coqui/app/test: shell checks only`) removes `byTypeName('PlansScreen')`, `byTypeName('LanguagesSheet')`, and quoted profile/welcome copy from `coqui/app/test/`.

## What I am using meanwhile

`coqui/app/test/` checks `ShellKeys.tab('me')`, `ShellKeys.route(const LanguagesRoute())`, `ShellKeys.route(const PlansRoute())`, and `feature_profile`'s existing keys listed above (`welcome-step-0`, `welcome-step-2`, `welcome-next-button`, `welcome-new-button`, `me-scroll`, `yo-level-check`, `plans-scroll`, `language-card-es`).

## Order and branch

- Order: 261 (`lane:app`)
- Branch: `lane/app/261`
