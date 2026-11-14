# UI fixes, round 1: the orchestrator's decisions (Nov 14)

Source of truth for the look: the owner's doc "Language App UI Design Plan" (summary and the owner's own rules in docs/proyecto/09-ui-plan.md). His rules that win over the doc: no self-rating flashcards (review stays ¿Cuál?); no English in learning content (English only in menus, the welcome and the "stuck" line); Spanish on screen otherwise.

Evidence: a screenshot tour at /tmp/claude-0/-home-user-field-notes/3c5d275f-89f8-5f76-b4a5-103358f42923/scratchpad/uitour1/ (89 shots, numbered; sheets hoja_1..10.png).

Design tokens for every screen built here (the doc's 8-point grid and type scale):
- Spacing in multiples of 8. Touch targets 48x48 px at least, 16 px apart at least.
- Type: system sans (the app's current font). H1 24 semibold; H2 18 medium; body 16; labels 12 medium.
- Colour only for meaning: green #1E9E52 = go / right / done; red-orange #D9480F = wrong; blue #3B5BDB = system / active tab. Neutral otherwise.
- Learning screens (story, ¿Cuál?, level check) are full screen on a calm dark grey #1B1B1F; text white or #C9C9D1. The tab bar is hidden there and comes back on exit.
- Pixel art always nearest-neighbour, whole-number scaling. UI drawn over it is crisp HTML/CSS, never pixel font.

## A. Lesson screens (story, ¿Cuál? review, level check) — agent "lesson"

Files: historia/index.html, historia/juego.js, historia/cual.html, historia/cual.js, historia/nivel.html, historia/nivel.js, historia/escenas/kit.js only if needed. Do not touch historia/app.html or the app's own scripts or palabras.js.

1. P0. Progress is not saved: juego.js line ~257 tests `window.PAL`, but `PAL` is a top-level `const` in palabras.js, so `window.PAL` is undefined and nothing is recorded. Use `typeof PAL!=="undefined"`. Search juego.js, cual.js and nivel.js for any other `window.X` test of a top-level const/let (PAL, CURSO, App, Story…) and fix the same way. Prove it: play a story through in the app (opened from the map), return, and see the map's streak/Today card, Palabras, Biblioteca and Yo change.
2. One frame for all three screens. Top bar, 56 px high, over the dark grey: a close button (an X icon, 48x48 target) at the left; a thin progress bar in the middle (segments, one per step, 6 px high, 4 px gaps, filled green as he goes; it replaces the row of yellow squares); the sound button at the right, 48x48 (today it is 34x30). The picture below it, centred, whole-number scaled as now. The caption under the picture: 18 px, white, centred, at most two lines, never covered by anything.
3. Close (X) is always there, mid-play too: it stops all sound and returns to the screen the lesson was opened from (map, Palabras, Biblioteca, Yo). From the level check started in the welcome, it returns to the map. Today a story has no way out until the end and the level check hides #home.
4. Start: keep one big round play button over the picture, but restyle it: 72 px, green #1E9E52, white triangle, soft shadow (not the yellow one).
5. End screen of a story: the round yellow Home / Again / Next buttons go. In the bottom third, a full-width green primary button "Next story" (56 px high, 16 px side margins) and under it two secondary text buttons side by side, "Play again" and "Map" (48 px high). Nothing covers the progress bar or the caption. Keep the heart/stars art in the picture as it is.
6. ¿Cuál? end screen: today an empty box. Show "Done" as H1, one line "N words · M right" (body), and a full-width green "Back to Palabras" button. The close X and the end button return to Palabras (not to the map).
7. Level check end: its progress is right (today all 16 dots light after 3 or 14 items); the result card keeps its text; one full-width green button to the map.
8. Small phone (360x640) and landscape (844x390): nothing cut off. In landscape the picture takes the left and the caption and buttons sit to its right.
9. Story camera: in la-lluvia at about +20 s the frog is cut off at the picture's edge (uitour1/11). Find why (a camera or a position) and fix it only if the fix is local to the scene's camera; otherwise report it.
10. The English note card that covers the picture at the start of quien-eres-tu (uitour1/89): no English over the picture. Move that note to one small grey line (14 px, #9A9AA5) under the start button, shown only before play; it goes when play starts.

## B. The app shell (map, sheets, tabs) — agent "shell"

Files: historia/app.html and any script or CSS that only the app uses, historia/palabras.js (display only; do not change how words are scheduled or stored). Do not touch juego.js, cual.js, nivel.js, index.html, cual.html, nivel.html.

1. P0. Reading view: its audio keeps playing after its sheet is closed, and Play again starts a second loop (uitour1/29, 30). Closing the sheet, switching tab, or opening another text stops it; only one loop can run.
2. P0. Hablar: the mic must not leave the course for the old "field notes" page (uitour1/47). Calls are not open yet (they wait on the owner). Hablar shows, for each place, a call card "Call · La casa" with the state "Opens later" (disabled, grey), and the big mic in the bottom centre, 72 px, disabled, with the label "Calls open later". No link to the old page anywhere in the app.
3. Place sheet (uitour1/06, 07, 17): at most 70% of the screen high; a drag handle and a close X (48x48) at its top right; a tap on the map above it closes it; the tab bar stays visible and works while it is open (the sheet sits above the tab bar); switching tab closes any open sheet. Rows: the next story to play has a green "Play" button; stories already played show "Played" and an outline "Again" button; others an outline "Play". Keep "New · about N min".
4. Map layout (uitour1/05, 70, 61): the map area is the space between the top chips and the Today card; the Today card never covers a stop. On small phones the map scales down to the largest whole number that fits or scrolls inside its area, with the current stop scrolled into view. The flat blue band around the map goes: fill the space around the map with the map's own water pattern (tile the water edge used at the map's sides). Landscape: the map on the left, the Today card in a column on the right.
5. Biblioteca (uitour1/22-24): today 50 disabled rows. Per place, list only the stories he has played; under them one grey line "N more open as you play them on the map". The Escuchar items keep their rules but the same: locked ones are one line, not rows.
6. Palabras (uitour1/19, 35, 86): Review asks only words he has heard. If none is due but some are heard, the card says "Nothing due" and its button says "Practice" (uses heard words only). If no word is heard, the button is disabled and the card says "Play a story first". The "toca" card has a grey empty picture: find why and fix it.
7. State per tab: each tab keeps its scroll position when you leave and come back.
8. Text: "1 minutes" → "1 minute" (plurals right everywhere in Yo). Menu English stays (place subtitles such as "Grandma's house" are menu text and stay).
9. First paint (uitour1/01): no blue screen with empty pills; the tab bar and the map appear together.
10. Tab bar: "Mapa" label aligned with the others; the active tab blue #3B5BDB; labels 12 px.
11. Welcome: in landscape the Next button is cut off (uitour1/59): the sheet scrolls or the button stays visible. A welcome closed by a tap outside does not come back after reload unless it was never finished... decide: a tap outside does nothing during the welcome (it must be finished once).

## Both agents

- Read historia/notas/runbook-agentes.md first; follow it (server, tools, git). End commits with your own session's attribution lines.
- Before you change anything, take "before" screenshots of the screens you will change; after, the same "after" at 390x844, 360x640 and 844x390, into a new folder each: scratchpad/ui_lesson_after/ or scratchpad/ui_shell_after/. Make a contact sheet with historia/tools/hojas.py.
- Tests that must pass after your change: lesson agent — historia/tools/matriz.sh rrr and www on el-jugo, para-los-pajaros and jugo-de-china (all six good), cual_check.py all pairs (`"" "todo=1&n=140&txt=no"`, every answer ok, errors: []), nivel_check.py with todo (errors: []); shell agent — app_check.py (errors only the navigator.vibrate line), and a real run in the app: map → place → story → finish → back, then Palabras, Biblioteca (open a text, play, close: silence), Hablar, Yo, back to map, with screenshots.
- Do NOT bump ?v= (a later step does it), do NOT publish to main. Commit and push to the branch only. Pull --rebase before each push: the other agent commits to the same branch.
- If a decision here cannot be done as written, do the nearest thing and report it.
