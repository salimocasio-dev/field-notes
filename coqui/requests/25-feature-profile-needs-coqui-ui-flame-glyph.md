# 25 · feature_profile needs coqui_ui: the streak's flame without a font fetched while the app runs

## What I need

Either a flame icon among `CoquiIcons` (drawn like the others), or a colour emoji font in coqui_ui's `fonts/` (Noto Color
Emoji, or a subset with U+1F525, with its licence beside it) declared as the fallback of `CoquiText`, so that the flame of
"🔥 5" draws on every platform and a web build never asks another site for it.

## Why

Order 25, the Yo tab: the first number is "🔥" and the streak (app.html:473, `st("🔥 "+r,"day streak")`), a character in a
text, as v=39 has it; the map's chip "🔥 5 days" (app.html:286) is the same. On Android and iPhone the system's emoji font
draws it. On the web Flutter has no emoji font of its own, so CanvasKit fetches Noto Color Emoji from
`https://fonts.gstatic.com/s/notocoloremoji/...` while the page is open: I saw that request in the dev entry's network log
(`flutter build web --no-web-resources-cdn`, which moves CanvasKit to our own site but not the fallback fonts). The runbook
says nothing may come from gstatic; a learner offline, or one whose network blocks that host, gets an empty box in place of
the flame.

## What I am using meanwhile

The character itself, in `StatCard(value: '🔥 5')`, exactly as v=39 writes it. On the screenshots (taken where the
fetch works) it is the colour flame, within a few pixels of the reference.

## Order and branch

Order 25, branch `lane/feature_profile/25`.
