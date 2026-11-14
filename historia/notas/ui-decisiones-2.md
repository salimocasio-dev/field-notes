# UI fixes, round 2: the orchestrator's decisions (Nov 14)

From a fresh review of the v=33 screens (uitour2) against the owner's research and the tokens in ui-decisiones-1.md. Tokens unchanged; they are tightened below. Where a rule here and round 1 differ, this one wins.

## One system for every screen (both agents apply it in their own files)

- Primary buttons: green #1E9E52 for anything that starts or continues learning (Play, Practice, Next story, reading Play). Blue #3B5BDB for every other primary action (welcome Next, Add, To the map, Back to Palabras, a selected pill). No near-black #16181D fills anywhere.
- One play control everywhere: a green 48 px disc with a white triangle (Stop: the same disc with a white square). It replaces the grey rectangle (Biblioteca), the dark Play/Stop pill (reading), and the "Play" buttons in the place sheet. The lesson start disc is the same, 72 px.
- One secondary button: 48 px high, transparent, 1.5 px border #C9C6BB on light screens and #4A4A52 on dark, text #16181D / #FFFFFF, 12 px radius. It replaces grey fills (#ECEAE3), the 2 px outlines and bare-text buttons.
- Spacing: 16 px between any two targets or cards, 24 px between sections, 16 px side margins everywhere (lesson pictures included).
- Headings: H1 24 semibold for a screen title; sections H2 18 medium; caps only as a 12 px eyebrow above a title.
- Every sheet: its X is 48x48, 8 px from its top and right. Drag handles only on sheets that can be dragged away. The welcome has no handle and no X (it must be finished once).
- Text colours: titles #16181D; secondary #636A75; nothing under 4.5:1 contrast on its background.
- Navigation and system text may stay English (owner's rule: English in menus). No English inside a lesson's learning content.

## A. Lesson screens — agent "lesson" (same files as round 1: index.html, juego.js, cual.html, cual.js, nivel.html, nivel.js, escenas/kit.js if needed; NOT escenas/frente.js, which another agent is fixing now)

1. Whole-number scaling, always: picture scale = floor(device-pixel width available ÷ art width), centred, with 16 px side margins at least. The picture may be smaller than the screen width; that is accepted. Only camera zooms inside a story may be fractional.
2. Layout: picture block centred vertically between the top bar and the bottom zone (its centre at about 45 to 55% of the screen height). The start disc (72 px, green, white triangle) sits in the bottom third, centred, 40 px above the bottom edge (plus the safe area), on the grey, not over the picture.
3. Start screens of ¿Cuál? and the level check: no navy box. A 24 px title (Spanish where it is the learning content's own title; "Review" / "Level check" are menu text and stay English), the start disc in the bottom third, and the progress bar drawn with its true number of segments from the start (today it shows 5, then jumps to 6 or 16).
4. End screens, one layout for all three (story, ¿Cuál?, level check): H1 24 left-aligned at about 35% of the height (story: "¡Muy bien!" is not to be invented; use the story's title as the H1; ¿Cuál?: "Done"; level check: its result title); one line of body text under it where there is a result; a 56 px primary button at the bottom (green "Next story" for a story when there is a next; else blue "Map"; ¿Cuál?: blue "Back to Palabras"; level check: blue "To the map"); the secondary button (outline) above it where there is one ("Play again").
5. ¿Cuál? and level-check options: each picture in its own 1.5 px #4A4A52 frame with 16 px between options; a right answer gets a 3 px green #1E9E52 ring, a wrong one a 3 px red-orange #D9480F ring. No yellow highlight on these screens. (Inside stories the yellow big sign stays: it is part of the game.)
6. Remove the English note at the start of quien-eres-tu ("Yo soy: I am…") entirely: English in learning content. Do not replace it.
7. Landscape and small phone: apply 1 to 5; in landscape the picture left, everything else in a column on the right; nothing cut off.

## B. The app shell — agent "shell" (app.html and app-only scripts; palabras.js display only). Starts after the agent fixing the Hablar label and the Yo switch has finished.

1. Apply the system above to every app screen: the welcome, map chips and Today card, place sheet, Biblioteca and its reading view, Palabras, Hablar, Yo, every sheet.
2. Map states: the current stop gets a 4 px white ring (crisp, over the pixel art) plus the frog; done stops a green #1E9E52 tile with a white check; open-but-not-done stops a quiet outline; locked stops grey. Change the stop tiles' colour from the orange #F89838 (too close to the wrong-answer colour). Keep the art pixel-crisp.
3. Tab bar: the Mapa disc inactive = white fill with a 1.5 px #C9C6BB ring and the map icon #636A75; active = blue #3B5BDB fill, white icon. Every scrolling screen gets enough bottom padding that the disc never covers content (about 28 px more than today). Hablar's mic label at least 16 px above the disc.
4. Today card: title #16181D 18 px semibold; subtitle #636A75 14 px; the play control is the green 48 px disc.
5. Chips at the top of the map: flat labels (no shadow, no pill look) unless they are tappable; if tappable, 48 px high.
6. Biblioteca: list only played stories per place, each a row with the green 48 px disc; then ONE line at the bottom, 14 px #636A75: "N more open as you play the map". No other "opens when…" paragraphs.
7. Reading view: the same green disc for Play/Stop; a tap on a line gives a visible pressed state (a light #EEF1FF fill for 150 ms) so it reads as tappable.
8. Palabras: each word card shows a 16 px speaker glyph at its top right (the card plays the word). Section headings by the system above.
9. Hablar: the call rows are plain text rows at 60% opacity with "Opens later" as plain secondary text (no grey pill fills); they must not look like buttons.
10. Landscape: the map scales to the largest whole number whose height fits the viewport minus 72 px; no stop cut off; the place sheet header is one line ("La casa" and the X) so at least three rows show; the welcome body never cut mid-line (it scrolls).
11. Yo, Palabras, Biblioteca: 16 px between cards and targets, 24 px between sections; one heading style.

## Both agents

- Read historia/notas/runbook-agentes.md. The server on 8765 may be running: check with pgrep; leave it running.
- Before/after screenshots at 390x844, 360x640, 844x390 into new folders: scratchpad/ui2_lesson_after/, scratchpad/ui2_shell_after/; contact sheets with historia/tools/hojas.py.
- Tests as in round 1 (lesson: matriz rrr/www on el-jugo, para-los-pajaros, jugo-de-china; cual_check all pairs; nivel_check todo. Shell: app_check; a real run map → story → back with the record saved; Biblioteca reading play/stop/close; every tab).
- Do not bump ?v= (33 stands) and do not publish to main. Commit small, pull --rebase before each push.
- Report: commits, tests as numbers, the after sheets, anything done differently and why.
