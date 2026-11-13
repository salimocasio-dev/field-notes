# The app's look: Salim's UI plan (Nov 13)

## His words

- On the first shell (dark cards, a tab bar, the map one tab among many): "What kind of UI is this????"
- On the second (the whole app made into a pixel game): "I didn't say the whole thing is a game, I said on the home screen is the map to the game as the main part of the course."
- He pointed to his plan doc: "Language App UI Design Plan", https://docs.google.com/document/d/1oYSXXDBPCQhxDJ3IbrvKfI7LC2eDjCPhOW8Ljs9BEm0 . It is the spec for the app's UI. Read it before changing any screen.

## What the doc says, in short

- Home is the 16-bit course map, in the centre tab of a persistent bottom tab bar (3 to 5 tabs). Map = home; flashcards/review; library/reading; stats/profile; optional community.
- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.
- The map must read instantly: clear paths, done vs locked stops, the current objective highlighted. Branching allowed (autonomy).
- Thumb zone: primary actions and the mic in the bottom third. Targets 48 px or more, 16 to 24 px apart. 8-point grid. Type: H1 24 semibold, H2 16 to 18, body 14 to 16, labels 12.
- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Each tab keeps its state (scroll, place in a deck).
- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.
- Reading: karaoke highlight synced with the audio; tap a line or word to jump there. (The doc also says a translation tooltip; see below.)
- Flashcards: spaced repetition; the doc suggests swipe right/left to rate and tap to flip. (See below.)
- Haptics: short crisp ticks on taps, a richer pattern on unlocking a place, never long buzzes. Synced with sound and visuals.
- Avoid gamification fatigue: forgiving streaks (streak freezes), meaningful rewards, no rigid single path.

## Where the build differs from the doc, and why (told to him in one line each)

- No swipe-to-rate flashcards: that is the learner telling the app he knows a word. Review stays the picture check (¿Cuál?), where the app finds out. His rule against self-report buttons.
- No English translation tooltip in reading: his rule that English is only for menus, the welcome and the stuck line.

## What is built (v=20, commit e85b55b): historia/app.html

- Tabs: Biblioteca (listen again; read with each line lit while its recording plays), Palabras (due count and Review first, then word cards with picture, stage bar, next return; tap to hear), Mapa (centre, raised, home), Hablar (one big mic to the call page, open words, cost), Yo (stats, minutes a day, open every place, level check placeholder, how it works).
- Map: the SMB3-style map, without bonus houses (practice lives in the tabs). Whole-number scaling to the screen. The current stop blinks. Top: streak and place chips. Bottom: "Today" card with the next step and a big green play button. Places open in a bottom sheet.
- Welcome: three steps in a bottom sheet.
- Haptics: 8 ms ticks on taps (Android; iPhones ignore web vibration).

## Not done from the doc

- The mic states, live waveform and pitch contour (calls still run on the old test page).
- Per-word tap-to-jump in reading (tap works per line).
- A rich haptic on unlocking a place; streak freezes; the map at an angle; finished places changing the map.
- The story and ¿Cuál? screens still use their earlier frame and round yellow buttons; under the doc they should be calm, minimal, full screen.
