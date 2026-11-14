# UI fixes, round 3 (polish): the orchestrator's decisions (Nov 14)

From a fresh review of v=33 (uitour3, in the orchestrator's scratchpad). Rounds 1 and 2 stand; this round wins where it differs. Tokens unchanged (green #17803F learning actions, blue #3B5BDB other primary, 48 px targets 16 px apart, 8-point grid).

## A. Lesson screens — agent "lesson" (index.html, juego.js, cual.html, cual.js, nivel.html, nivel.js, escenas/kit.js, and escenas/frente.js for items 1 and 6 only)

1. La lluvia's opening: the frog is cut off at the bottom of the picture in the first seconds (uitour3/09, 66, 76). Keep his feet at least 8 art px inside the view: fix the opening camera or his start position in escenas/frente.js, without changing the "ventana" or "cuadro" cameras' other uses; check la-lluvia's +5 s, +20 s and end frames.
2. Landscape lessons: the X, progress bar and sound button move into the right column, so the picture gets at least 16 px margins on every side (uitour3/65-67, 102).
3. Story end: when there is a next story, add an outline "Map" button beside "Play again" (both 48 px, 16 px apart), so the map is reachable without the X.
4. ¿Cuál? and level-check start screens: under the H1, one body line: "N words · about M min" (¿Cuál?) / "16 pictures · about 3 min" (level check, with its real count), 16 px #C9C9D1.
5. Level-check result: the H1 and ONE short line (English allowed: it is a system screen), and the button. The long explanation ("each gets one cold check…") moves to the app's Yo tab: report its exact text so the shell agent can place it; do not edit app.html.
6. La lluvia's end picture: a lighter, hard-edged translucent rectangle lies over the door and step at the picture's right edge (uitour3/13, 90, 102, 103). Find what draws it (an overlay, a highlight box, or the "cuadro" camera's edge) and remove it.

## B. The app shell — agent "shell" (app.html and app-only scripts)

1. Map stop states: current = a blue #3B5BDB ring (4 px, crisp) plus the frog; open (unlocked, not done) = outline only, no white fill; done = green #17803F tile with a white check; locked = grey. Under the current stop a small crisp label "N/M" (stories played of the place's stories), 12 px medium on a white rounded chip.
2. The Mapa disc must clear the Today card by 16 px: add the disc's rise plus 16 px to the map area's bottom padding (uitour3/05).
3. Place sheet: its header (title + X) is an opaque bar, 56 px, so rows scroll under it and the X keeps 16 px from any row (uitour3/07, 63, 64). Rows: a solid green disc only on the first unplayed story of the place; every other row an outline disc (1.5 px #C9C6BB ring, dark triangle); "Played" rows keep their label.
4. Landscape map: when the map scrolls, a soft fade (16 px, from the background colour) at the edge that has more map, so it reads as scrollable (uitour3/61, 62).
5. Hablar: replace the ten "Opens later" rows with ONE card: H2 "Calls", body "Calls with Danny open later.", and the disabled mic disc in it. Nothing under the tab bar.
6. Disabled text (Review when nothing is heard; the mic icon): contrast at least 4.5:1 (#636A75 on #F2F1EC or lighter).
7. Yo: add the level check's explanation (the text the lesson agent reports, or, if not yet reported, the current text from nivel.js's result screen) under a "Level check" heading in "How it works".

## Both agents
- Read historia/notas/runbook-agentes.md. The server on 8765 may be running; leave it running.
- Before/after shots at 390x844, 360x640, 844x390 into new folders scratchpad/ui3_lesson_after/, scratchpad/ui3_shell_after/.
- Tests: lesson: matriz rrr/www on el-jugo and jugo-de-china, rr/ww on la-lluvia; cual_check all; nivel_check todo. Shell: app_check; a real story run from the map with the record saved.
- Bump nothing; publish nothing; commit small; pull --rebase before each push.
