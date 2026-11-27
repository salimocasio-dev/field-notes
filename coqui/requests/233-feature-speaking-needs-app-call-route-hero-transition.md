# Request: `PageRoute` + `HeroController` push/pop for `CallRoute` in `coqui/app`

## What I need

In `coqui/app/`:

When navigating to `CallRoute` from the Speak tab (`HablarTab`), push `CallScreen` on a `Navigator` with a `HeroController` using a Noche `PageRoute` whose `transitionDuration` is `NocheMotion.pageIn` (`quick` under reduced motion), `reverseTransitionDuration` is `NocheMotion.pageOut` (`quick` under reduced motion), and `transitionsBuilder` passes the child straight through (matching `buildNocheCallRoute` in `feature_speaking/lib/src/motion.dart`).

## Why

Story #233 (`lane:feature_speaking`, N8.15, `Noche-Motion-Llamada.dc.html`) connects `HablarTab`'s orange call disc (`Key('speak-call-disc')`) to `CallScreen`'s `NocheMic` via `Hero(tag: SpeakingMotion.callMicHeroTag)` and fades the outgoing Speak tab in `NocheMotion.quick` via `ModalRoute.of(context)?.secondaryAnimation`. When the shell swaps screens directly without pushing a `PageRoute` under a `HeroController`, the Hero flight and `secondaryAnimation` fade cannot run in the live app.

## What I am using meanwhile

`HablarTab` and `CallScreen` wire the matching `Hero(tag: SpeakingMotion.callMicHeroTag)` endpoints and `secondaryAnimation` outgoing fade, and `feature_speaking/lib/src/motion.dart` provides `buildNocheCallRoute<T>` so widget tests in `feature_speaking` exercise the full Hero disc-to-mic flight and outgoing Speak fade end to end. Without a `Navigator` push, both screens degrade cleanly to their standalone arrivals.

## Order and branch

- Order: 233 (`lane:feature_speaking`)
- Branch: `lane/feature_speaking/233`
