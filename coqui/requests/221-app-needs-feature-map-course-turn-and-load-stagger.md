# Request: Course-turn overlay fade & cold-load stagger scope in feature_map

## What I need

In `coqui/packages/features/feature_map/`:

Add an inherited scope or hook (e.g., an `InheritedWidget` / `MapArrivalScope` read by `MapScreen`) that lets the shell:
1. Keep `MapScreen`'s `PixelView` map picture unfaded during a course language change (`Noche-Motion-Idioma.dc.html`) while fading only the course-language overlays (`_TopChips`, `"You are here"`, and `_UpNextCard`) via the shell's course-turn opacity.
2. Trigger staggered cold-load arrival of internal map elements on first load (`Noche-Motion-Carga.dc.html`: `.a1` top chips at 180 ms, `.a3` "You are here" at 210 ms, `.a2` up-next card at 240 ms, `.play` disc at 400 ms).

## Why

Order #221 (`N8.3 The shell: tabs, lessons, loading`) implements `Noche-Motion-Carga.dc.html` and `Noche-Motion-Idioma.dc.html` in `coqui/app/`. Because `feature_map`'s `MapScreen` bundles `PixelView` together with `_TopChips`, `"You are here"`, and `_UpNextCard` inside a single feature widget (and `lane:app` may not edit `feature_map`), `app` cannot fade course-language overlays independently of the map picture during course turn or stagger internal map rows and the play disc on cold load.

## What I am using meanwhile

`CoquiApp` (`coqui/app/lib/src/app.dart`) wraps the course layer (`WelcomeGate` / `AppShell`) in `Opacity(key: shellCourseTurnKey, ...)` during course turn (`quick` fade-out on `exit`, swap, `move` fade-in on `enter`), and `AppShell` (`coqui/app/lib/src/shell.dart`) fades the initial tab/map layer `0 -> 1` in `motion.pageIn` on `animateLoadArrival: true` while rising `NocheTabBar` after `ShellMotion.loadTabBarDelay` (`160 ms`).

## Order and branch

- Order: 221 (`lane:app`)
- Branch: `lane/app/221`

## Status

`MapModule` (`lib/src/module.dart`) now exposes optional `ValueListenable<double>? overlayOpacity` and `bool animateColdLoad = false` parameters (forwarded to `MapScreen`, keeping `feature_map.dart`'s single-module public surface), ready for `lane:app` to wire in `AppShell`/`CoquiApp`.
