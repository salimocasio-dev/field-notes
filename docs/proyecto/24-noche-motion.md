# Noche motion: epic N8 and its stories

Written Nov 26 2026 from the motion boards on the canvas "Coquí: new app designs, 3 directions" ([https://claude.ai/artifact/Ls3fG6ZKNzaLW9TeESvPp1](https://claude.ai/artifact/Ls3fG6ZKNzaLW9TeESvPp1), the rows "Noche: motion between selections" and "Noche: more motion"), and from the Noche rules on page 22 ([`22-noche-epics.md`](22-noche-epics.md)).

Salim, Nov 26: "Noche has been adopted and is being executed, but animations between selections need to be developed so that everything feels smooth and polished."

So:

- This page adds one epic, N8, to the Noche epics. Its stories are written in the board's story format (repo-root `AGENTS.md`, "A story").
- Every N8 story follows the Noche rules of page 22, Part 1, and the motion rules of Part 1 below.
- None of this is on the GitHub board yet. Posting it is story N8.0.

---

## Part 1. The motion rules (every N8 story links here)

A reviewer fails a pull request that breaks one.

### 1.1 Where the design is

- The motion boards are the `Noche-Motion*.dc.html` files in [`noche/`](noche/), with a PNG of each at rest beside it. `Noche-Biblioteca-Cerrado.dc.html` is the new Library.
- A motion board is one HTML file. Its `<style>` block holds the motion: every rule has a comment in plain words above it, and the times and curves in it are the ones in 1.2. Its `<script type="text/x-dc">` block holds the order of events and the waits between them.
- **What the board file decides:** which element moves, from where to where, in which order, and every wait between steps. Read them from the `<style>` and the script.
- **What this page decides:** the names, the tokens, the behaviour, and every place where it says the build differs from the board. Where this page and a board disagree, this page wins.
- Each board has a video of it playing at real speed, 60 frames a second, named `Noche motion <N> - <what>.mp4`. Story N8.0 says where they are kept. Watch the video before building the story.
- Everything page 22, Part 1.1 says to ignore in a board file is ignored here too. The pictures on the boards (`/_blob/...`) are the app's own: the map, its frames of the coquí hopping, the scene pictures.
- Every number, name and line on a motion board is sample data (page 22, Part 1.2). So are its pictures: where a board cuts a piece out of a scene picture to stand for something else (a word's picture, a new story's cover), the build uses the app's own picture for that thing and never a story's picture (repo-root `AGENTS.md`, guardrail 5).
- The boards mark what is chosen with `aria-checked` on their radio and switch buttons. The build gives screen readers the same selected and on/off state.
- The boards use `left` and `right` in places. Port every one as start and end (page 22, Part 1.4).

### 1.2 The tokens

One class in coqui_ui, `NocheMotion` (story N8.1). No `Duration(` and no `Curves.` or `Cubic(` literal anywhere outside coqui_ui in a file an N8 story changes. A reviewer greps for them.

| Name | Value | Used for |
| :---- | :---- | :---- |
| `press` | 90 ms | finger down: the thing touched answers |
| `pressBack` | 140 ms | finger up: it returns |
| `quick` | 140 ms | colour, outline and weight changing in place |
| `move` | 220 ms | a mark travelling inside a screen: pill, thumb, knob, dash |
| `pageIn` | 320 ms | a screen or a sheet arriving |
| `pageOut` | 200 ms | a screen or a sheet leaving |
| `settle` | 480 ms | a result: the ring on a right answer, bars growing |
| `stagger` | 30 ms | between rows that arrive one after another, the first five only |
| `nextDelay` | 80 ms | the orange action lands this long after the last row |
| `hop` | 200 ms | one hop of the coquí on the map |

| Curve | Value | Used for |
| :---- | :---- | :---- |
| `enter` | `Cubic(0.2, 0, 0, 1)` | arriving, and everything the finger starts |
| `travel` | `Cubic(0.4, 0, 0.2, 1)` | moving between two places both on screen |
| `exit` | `Cubic(0.4, 0, 1, 1)` | leaving |

| Distance | Value | Used for |
| :---- | :---- | :---- |
| `row` | 8 | a row or a line rising into place |
| `tab` | 16 | a tab's content, or the content under a segmented control or a chip row |
| `page` | 24 | a reader page |
| `pressScale` | 0.97 (0.94 for the round discs: mic, play, Map) | the thing touched |
| `pressDim` | 10% darker | the thing touched |

No bounce, no overshoot and no spring anywhere in the app's own interface. The coquí's hop on the map is the pixel world's and keeps its arc.

### 1.3 The nine rules

1. **Answer the finger first.** What is touched dims and shrinks to `pressScale` in `press`, before anything else moves.
2. **One mark travels.** The pill, thumb, outline or ring slides from the old choice to the new one in `move` on `travel`. It never fades out in one place and in at another.
3. **Content follows the choice.** Pick something toward the end side and the new content comes in from the end side by `tab`, on `enter`, in `move`. The old content only fades, in `press` to `quick` on `exit`.
4. **Going in grows from what was touched.** Going back returns to it, and faster: `pageIn` in, `pageOut` out.
5. **Pixel pictures never zoom.** Their window grows and the picture slides behind it, always at the same whole-number scale (`PixelView`).
6. **Orange moves last, and once.** The next action lands `nextDelay` after the last row, rises `row`, then stays still. It never pulses.
7. **A miss is quiet.** A white outline draws in `quick` and the line plays again. No shake, no colour. A locked thing answers the same way: its outline turns solid and its reason lights up for about 1.4 s.
8. **Only live things loop:** the mic's level bars, the thinking dots, a voice playing, the dots while something loads. Everything else moves once and stops.
9. **A trip on the map is short.** The coquí takes the shortest road in at most 6 hops. The camera travels with him. As he lands the card becomes that place and grows; a swipe up or a tap opens it.

### 1.4 Reduced motion

When the platform asks for reduced motion (`MediaQuery.disableAnimationsOf`, already read into `Services.reduceMotion`):

- Every move becomes a `quick` fade in place. Nothing travels, nothing staggers, nothing scales.
- Nothing loops. The level bars stand still at a middle height, the dots stand still.
- The coquí is placed at once (the app already does this).
- Each board's `<style>` ends with a `prefers-reduced-motion` block that says what that screen does.

### 1.5 Right to left

- Direction of travel follows the layout: "the end side" is the left in an Arabic course. A test runs each motion story's screen with the Arabic fake course (story N2.2).
- The app's own English keeps its own direction inside a right-to-left screen. A line that starts with a number ("6 days", "12 of 30 min today") is wrapped so it reads left to right (`Directionality(textDirection: TextDirection.ltr)` or the piece coqui_ui gives for it, story N8.2). Without this the board showed "days 6".
- Pixel pictures and the map never mirror.

### 1.6 Each pull request shows its motion

Beside what page 22, Part 1.6 asks:

- A widget test for each move the story names, pumped at its start, its middle and its end (`tester.pump(NocheMotion.move ~/ 2)`), reading the position or the opacity, not a golden of a moving frame.
- A test with `disableAnimations: true` showing the reduced form.
- A screen recording of the screen on a phone or the simulator, beside the board's video, in the pull request.

### 1.7 Things that cost money or need Salim

No N8 story records audio, calls Danny, buys anything or adds a package. Motion is built with Flutter's own animation classes.

---

## Part 2. The order

| Wave | Stories (lane) | Waits for |
| :---- | :---- | :---- |
| 0 | N8.0 (docs) | nothing |
| 1 | N8.1 (coqui_ui) | nothing: everything it needs is on this page |
| 2 | N8.2 (coqui_ui) | N8.1, N1.2, N1.3 |
| 3 | N8.3 (app); N8.4 (feature_map); N8.8 (feature_story); N8.9 (feature_review); N8.10 (feature_words); N8.11 (feature_library); N8.15 (feature_speaking); N8.16 (feature_profile) | N8.2, and the Noche screen story of that lane |
| 4 | N8.5, then N8.6, then N8.7 (feature_map); N8.12, then N8.13, then N8.14 (feature_library) | the story before it in the same lane |

- coqui_ui has one writer at a time. N8.1 and N8.2 go to the same agent, one after the other.
- feature_map and feature_library each hold several N8 stories. A lane holds one story at a time, so they run in the order written.
- A feature story that is ready before N8.2 merges does not start: it would have to draw its own copy of a shared piece.

---

## Part 3. The epic

### Epic N8. Motion between selections

Everything in the app that changes when the learner picks something moves by the rules of Part 1, so the app feels like one thing.

#### N8.0 Put the motion boards and this page in the repo, and post the epic

- Labels: `type:story`, `agent:claude`, `lane:docs`, `status:ready`.

**Salim's words**

> Write the stories

**Done when**

- `docs/proyecto/noche/` holds the 15 files of the list below, each with a PNG of it at rest beside it (390 by 844; the rules board 808 by 1070).
- This page is in the repo as `docs/proyecto/24-noche-motion.md`.
- The 14 videos are in a place every agent can open, and this page says where. They are not in the repo unless Salim says so (together they are about 77 MB).
- One `type:epic` issue for N8, with stories N8.1 to N8.16 as sub-issues, posted with the labels each story lists. The issue number of each is written next to it on this page.
- Page 22 gets one line under "Part 3. The epics" pointing here.

**The files**

| Board | What it shows | Video |
| :---- | :---- | :---- |
| `Noche-Motion.dc.html` | the rules: five times, three curves, nine rules | 1 |
| `Noche-Motion-Tabs.dc.html` | tab bar, skill switch, chips, shelf filter, bars growing | 2 |
| `Noche-Motion-Lugar.dc.html` | map card to place to story lesson and back | 3 |
| `Noche-Motion-Cuento.dc.html` | the mic's six states in a turn; a choice with a miss and a right answer | 4 |
| `Noche-Motion-Visita.dc.html` | tapping another place; the place card; a locked place | 5 |
| `Noche-Motion-Nuevo.dc.html` | a new place opens | 6 |
| `Noche-Motion-Escribir.dc.html` | the "Write my story" sheet, the wait, the story landing on the shelf | 7 |
| `Noche-Motion-Lector.dc.html` | the reader's text-and-page sheet, every control | 8 |
| `Noche-Motion-Fin.dc.html` | the end of a review | 9 |
| `Noche-Motion-Pagina.dc.html` | reader page turns, the sentence being read, the word bubble | 10 |
| `Noche-Motion-Llamada.dc.html` | locked calls; a live call; what it heard; "Call done" | 11 |
| `Noche-Motion-Idioma.dc.html` | changing language; Arabic, right to left | 12 |
| `Noche-Motion-Tocar.dc.html` | a touch turn; the end of a story | 13 |
| `Noche-Motion-Carga.dc.html` | loading; failing to load | 14 |
| `Noche-Biblioteca-Cerrado.dc.html` | the Library as a bookcase; a new story locked or open | (pictures) |

**Lane** lane:docs (and `.github/` is not touched).

---

#### N8.1 Motion tokens

- Labels: `agent:claude`, `lane:coqui_ui`. Waits for nothing.

**What to build**

- `NocheMotion` in `lib/src/noche_motion.dart`, exported from the package: the durations, curves and distances of Part 1.2, with exactly those names and values.
- `NocheMotion.of(context)`: the same values, or their reduced form (Part 1.4) when `MediaQuery.disableAnimationsOf(context)` is true: every duration `quick`, every distance 0, `loops` false.
- `Pressable` (`pressable.dart`) gives its child rule 1: scale to `pressScale` and dim in `press`, back in `pressBack`. A parameter picks the disc scale.
- Every duration and curve now written in coqui_ui (`fades.dart`, `sheet.dart`, `lesson_frame.dart`, `noche_chrome.dart`, `noche_controls.dart`, `cards.dart`, `game_tiles.dart`) reads from `NocheMotion`. No behaviour changes in this story except the values.

**Done when**

- A test reads every token and compares it with the table in Part 1.2.
- A test presses a `Pressable` down and up and reads its scale at the end of `press` and of `pressBack`.
- `grep -rn "Duration(milliseconds" coqui/packages/core/coqui_ui/lib` finds only `noche_motion.dart`.
- The reduced form is tested.

**Lane** lane:coqui_ui.

#### N8.2 The shared pieces move

- Labels: `agent:claude` (the same agent as N8.1), `lane:coqui_ui`. Waits for N8.1, N1.2, N1.3.

**Boards** [`Noche-Motion-Tabs.dc.html`](noche/Noche-Motion-Tabs.dc.html), [`Noche-Motion-Cuento.dc.html`](noche/Noche-Motion-Cuento.dc.html), [`Noche-Motion-Lector.dc.html`](noche/Noche-Motion-Lector.dc.html), [`Noche-Motion-Escribir.dc.html`](noche/Noche-Motion-Escribir.dc.html).

**What to build**

Each piece of N1.2 and N1.3 gets its motion, inside the piece. A feature gets it by using the piece.

| Piece | Its motion |
| :---- | :---- |
| `NocheTabBar` | One pill (48 by 28, `line` fill) behind the icons. It slides to the chosen tab in `move` on `travel`. Going to Map it slides under the disc, shrinks to half and fades in `quick`; leaving Map it comes out the same way. Label colour changes in `quick`; the weight changes at once. Icons and the disc take rule 1. |
| `NocheSegmented` | One thumb (text fill) slides in `move` on `travel`. Label colours change in `quick`. |
| `NochePill` in a group (a new `NochePillGroup`) | One text-fill mark slides behind the pills from the old one to the new one, changing its left edge and its width in `move` on `travel`. Text colours change in `quick`. |
| `NocheSwitchRow` | The knob travels in `move` on `travel`; the track's colour changes in `quick`. |
| `NocheSheet` (and `showNocheSheet`) | Up in `pageIn` on `enter`, down in `pageOut` on `exit`. The scrim fades in `move` and out in `pageOut`. Its rows rise by `row`, `stagger` apart, starting 120 ms after it starts. A sheet can swap its content in place (old fades in `quick`, new fades in `move` after 100 ms) without changing its height: used for a wait. |
| `NocheDashes` | A dash that becomes done fills from its start in `move` on `travel`. |
| `NocheStageBar`, `NocheProgressBar` | `animateFrom`: grows from that fraction to its value in `settle` on `enter`, once. |
| `NocheBarChart` | On first build its bars grow from zero in `settle` on `enter`, `stagger` apart, the first five only. |
| `NocheMic` | One disc; a state change is in place. Fill and icon colour in `quick`; the 8 px halo of `listening` grows in `move`; the icon swaps by a `quick` fade with a scale from 0.8. `right`: one ring leaves the disc, growing to 1.5 and fading, in `settle`, once. `notYet`: the 2 px text ring draws in `quick`. The word under it cross-fades in `quick`. Level bars and thinking dots are the only loops, and only while their state is on. |
| `NocheCard` holding a choice (font card, language row) | One outline mark slides between the options in `move` on `travel` (a new `NocheOutlineGroup`). |

New pieces:

| Piece | What it is |
| :---- | :---- |
| `NocheArrive` | Children rise by `row` and fade in over `move` on `enter`, `stagger` apart, the first five only; a `next` child lands `nextDelay` after the last. Takes a start delay. |
| `NocheFollow` | Shows one child for a key. When the key changes, the old child fades out in `press`, the new one comes in from the side given (start or end) by a distance given (`tab` or `page`), in `move` on `enter`, after 60 ms. |
| `NocheWindow` | Rule 5. A clipped window on a `PixelView` picture with a rect, a corner radius and the picture's offset, all three animated together in `pageIn` (or `pageOut`) on `enter`. The picture's scale never changes. |
| `NocheQuietLock` | Rule 7 for locked things: on tap the dashed outline turns solid in `press` and the reason text goes from label to text colour; both return after 1.4 s over `move`. |
| `NocheLtr` | Keeps the app's own English left to right inside a right-to-left screen (Part 1.5). |

**Done when**

- The gallery (`tool/gallery/noche_pieces.dart`) has a page where each piece can be played.
- A test per piece: start, middle, end, and the reduced form.
- `NocheMic`'s golden of its six states still matches.
- The package's old tests pass.

**Lane** lane:coqui_ui.

---

#### N8.3 The shell: tabs, lessons, loading

- Labels: `agent:claude`, `lane:app`. Waits for N8.2, N4.9, N2.11.

**Boards** [`Noche-Motion-Tabs.dc.html`](noche/Noche-Motion-Tabs.dc.html), [`Noche-Motion-Idioma.dc.html`](noche/Noche-Motion-Idioma.dc.html), [`Noche-Motion-Carga.dc.html`](noche/Noche-Motion-Carga.dc.html).

**What to build**

- **Changing tab.** The tab's content is in a `NocheFollow` with distance `tab`: a tab further toward the end comes in from the end side, one toward the start from the start side. The tab bar itself never moves.
- **A lesson, a call or the reader opens** (a full-screen route with no tab bar): the tab bar sinks 96 below its place and fades in `pageOut` on `exit`; the ground goes from `ground` to `lessonGround` in `pageIn`. On the way back the tab bar rises in `move` on `enter` after 60 ms.
- **Changing course** (N2.11): everything in the course's language fades out in `quick` on `exit`, the course is swapped, and it fades back in `move` on `enter`, in the new course's direction. The map picture does not fade.
- **Loading the course.** Nothing for the first 300 ms. Then three 12 dots in label colour (the only thing that moves) and one line in `bodyLarge`, label colour. When it has loaded: the map fades in over `pageIn`; the top chips, "You are here" and the card rise by `row`, `stagger` apart; the tab bar rises from 96 below in `pageIn` after 160 ms; the play disc lands last.
- **It could not load.** The dots fade; the line the app has now rises; the orange "Try again" lands `nextDelay` after it. "Try again" goes back to the dots.

**Differs from the board**

- The board's line "Getting your course" is a stand-in. Keep the app's own loading line if it has one; if it has none, use it.
- The board changes course inside one screen. In the app the change comes from the sheet of N8.16.

**Done when**

- A test changes tab toward the end and toward the start and reads the side the content comes from, in the Spanish and the Arabic fake.
- A test opens and closes a lesson route and reads the tab bar's offset.
- The load failure screen's screenshots are redone, both sizes.

**Lane** lane:app.

---

#### N8.4 Map: opening a place, and a story from the card

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N8.2, N4.1, N4.2.

**Board** [`Noche-Motion-Lugar.dc.html`](noche/Noche-Motion-Lugar.dc.html).

**What to build**

- The scene picture is one thing from the card to the place to the lesson. It is a `NocheWindow`: on the map, 72 by 72 with radius 16 in the card; in the place, the 296 hero with radius 0; in the lesson, the 400 picture under the 64 header.
- **Card to place:** the window grows in `pageIn`; the map and the card fade in `quick`; the place's back button and "Place N of M" pill fade in after 200 ms; the title, the story row and the three pills rise by `row` at 120, 150 and 180 ms; the play bar lands at 260 ms.
- **Place to story, or card's play disc to story:** the window moves to the lesson's picture in `pageIn`; the shell does the tab bar and the ground (N8.3); the lesson's rows rise as N8.8 says.
- **Back:** the same in reverse in `pageOut`, and nothing rises: rows only fade in over `quick` after 40 ms.

**Differs from the board**

- The lesson is feature_story's screen. This story hands it the window's start rect through the route (if `StoryRoute` has no place for it, file a request and open the lesson with a plain `pageIn` fade until it lands).

**Done when**

- A test opens the place from the card and reads the window's rect at the start, the middle and the end, and the picture's scale at each (always the same).
- Back is tested and takes `pageOut`.

**Lane** lane:feature_map.

#### N8.5 Map: going to another place, and a locked place

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N8.4.

**Salim's words**

> youre missing doing to a new place.

**Board** [`Noche-Motion-Visita.dc.html`](noche/Noche-Motion-Visita.dc.html) (the map half).

**What to build**

- **Tapping an open place the coquí is not at:**
  1. At once (`press`): a pill with the place's name appears over its stop (panel fill, line border, `buttonStrong`, 40 high), and "You are here" fades out in `quick`.
  2. 90 ms later the coquí starts hopping there and the camera starts travelling to centre on that stop, on `travel`, for as long as the hops take.
  3. When he has landed and settled (about a quarter of a second): the name pill fades, "You are here" rises over him, and the card becomes that place (N8.6). The place does not open by itself.
- **The trip is short** (rule 9). In `MapPicture`:
  - The route is the shortest way along the road. Today `route()` goes from pad to pad, so place 3 to place 2 passes through place 1: 18 hops, 3.6 s. It must go through the junction: 4 hops.
  - A trip has at most 6 hops. Count the hops as now (one per 2.2 units of each leg, at least one per leg); if that is more than 6, share 6 among the legs by their length. Each hop stays `hop` long, so a trip is never more than 1.2 s. Longer trips make longer hops.
- **Tapping the place he is at:** the card becomes that place (N8.6). Tapping it again opens it.
- **Tapping a place that is not open yet** (rule 7): a pill over it with a lock and its reason (`"After <place>"`, the place before it) shows in `press` and leaves after 1.5 s over `move`. The coquí does not move. Nothing else changes. A place locked by plan keeps N3.4's behaviour.
- With reduced motion: the coquí is placed at once, the camera jumps, the card changes with a `quick` fade.

**Differs from the board**

- "You are here" sits above the place's house when the house is right above its stop (places 1 and 4 on the board's map), so it never covers the house. N4.1 put it a fixed distance above the stop.
- The hop sound and the haptic tick stay as they are.

**Done when**

- A test of `route` and the hops for every pair of places: never more than 6 hops, and never through a third place's stop when the road does not need it.
- The recorded map runs still pass, with their times updated where a trip got shorter. Each change is listed in the pull request.
- A test taps a closed place and reads that the coquí's place did not change.

**Lane** lane:feature_map.

#### N8.6 Map: the place card

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N8.5.

**Salim's words**

> when he goes to a new place, it should change and expand slightly, make it clear the user can go to the fully expanded screen with a gester or opening it,

**Board** [`Noche-Motion-Visita.dc.html`](noche/Noche-Motion-Visita.dc.html) (the card half).

**What to build**

- The card above the tab bar has two forms. **Up next** is N4.1's card (155 high on the board). **The place card** shows the place the coquí is at, and is about 60 taller (216):
  - a 40 by 4 handle (`bar` colour) centred at its top;
  - the place's scene picture 72 with radius 16; `"Place <N> of <M>"` (`label`); the place name (`cardTitle`, content language); `"<N> of <M> stories heard"`;
  - a 48 round button with an arrow up (ground fill, line border), labelled `"Open <place>"`;
  - under a line: `"Play next · Story <N>"`, the story title, `"<M> min"`, and the 64 play disc. With every story heard, N4.2's rule for the play bar.
- **Becoming the place card:** the card's height changes in `move` on `travel`; the old content fades out in `press`; the new content rises by `row` in `move` after 60 ms; the play disc lands last.
- **Opening the place** (rule 4), three ways, all the same result:
  - a swipe up on the card: the card and its picture follow the finger (no further than 80 up); let go past 28 and it opens;
  - a tap on the card;
  - the arrow button.
  The place opens as in N8.4, with the window starting from the card's picture.
- **A swipe down** past 28 on the place card turns it back into Up next. Let go before 28 either way and it returns in `move`.
- Coming back from the place, the card is still the place card.
- The app opens on Up next.

**Done when**

- Tests for: the height change; a drag of 20 (returns), of 40 up (opens), of 40 down (Up next); the tap; the button.
- The card's screen reader actions: "Open" and "Show what is next".
- Screenshots of the place card for a new place, a half-done place and a finished place, both sizes.

**Lane** lane:feature_map.

#### N8.7 Map: a new place opens

- Labels: `agent:gemini`, `lane:feature_map`. Waits for N8.6.

**Board** [`Noche-Motion-Nuevo.dc.html`](noche/Noche-Motion-Nuevo.dc.html).

**What to build**

When the map shows again after the last story of a place was finished and the learner's place has moved on (`_progressChanged` with `moved`), instead of placing the coquí at once:

1. "You are here" fades out in `quick`.
2. 100 ms later the new place's house gets its colours, the finished stop gets its flag and its number plate turns: one cross-fade of the map picture in `settle` on `enter`. A pill names the new place (`"New place"` in label colour, then the name), rising by `row`.
3. 600 ms after step 1 the coquí hops there (N8.5's hops) and the camera travels with him.
4. When he has settled: the pill becomes "You are here" in place (a `quick` cross-fade), and the card becomes the new place's card (N8.6) with `"New place · <N> of <M>"` as its label and `"Play first · Story 1"`.

It plays once. Leaving the map during it finishes it at once.

**Differs from the board**

- The board's dark screen before step 1 stands for the story being played. Do not build it.
- The board's card picture for El colmado is a piece of the map and its title is the scene's name. Use the place's first story and its scene picture.

**Done when**

- A test finishes the last story of a place in the fake and reads the four steps in order and their start times.
- With reduced motion: the coquí is placed, the picture changes, the card changes with a `quick` fade.

**Lane** lane:feature_map.

---

#### N8.8 Story lesson: turns, the touch turn, the end

- Labels: `agent:gemini`, `lane:feature_story`. Waits for N8.2, N4.3.

**Boards** [`Noche-Motion-Cuento.dc.html`](noche/Noche-Motion-Cuento.dc.html), [`Noche-Motion-Tocar.dc.html`](noche/Noche-Motion-Tocar.dc.html), [`Noche-Motion-Lugar.dc.html`](noche/Noche-Motion-Lugar.dc.html) (the lesson's arrival).

**What to build**

- **The lesson arrives:** the speaker's name, the line and the prompt rise by `row` at 160, 190 and 220 ms; the controls land at 300 ms.
- **A speaking turn:** `NocheMic` follows the turn (N4.3). Thinking shows the moment he stops. On a miss: `notYet` for 900 ms, then the line plays again: the "hear it again" arrow turns once in `settle`, the mic goes to `theySpeak`, then `ready`. On right: `right`, 600 ms later the part's dash fills, and 700 ms after that the next turn comes.
- **From turn to turn:** the frame (close, dashes, TXT) holds. The old turn fades out in `quick`; the new turn's rows rise by `row`, `stagger` apart.
- **TXT** is a switch: fill, text and border change in `quick`; the lines fade in `quick`.
- **A touch turn:** what he touches gets a 3 px outline with radius 12 around its hint box. Wrong: text colour, drawn in `quick`, held 1.3 s while the line plays again (small level bars beside the line), then gone in `move`. Right: `right` colour, with one ring leaving it in `settle`; then the dash and the next turn as above.
- **The end of the story:** the picture stays. Its window closes from 400 to 296 and moves to the top in `pageIn` (a `NocheWindow`); the header and the turn fade in `quick`. Under it, rising by `row`, `stagger` apart: `"Story <N> of <M> · <place>"` (`label`), the title (`placeTitle`), `"<N> new words"` and a row per new word with a `NocheStageBar` that grows from zero to its stage in `settle`, then `"Today"` with `"<N> of <M> min"` and a bar that grows from before the story to after it in `settle`. The orange next action lands last: the plan's next entry (`"Next: review · <N> min"`, `"Next: <story title>"`, or `"Back to the map"` with nothing left).

**Differs from the board**

- The end of a story had no board and no screen to follow; this one is new. If the app has an end screen, keep its content and give it this motion, and say so in the pull request.
- The touch turn's hint (`TouchSign`) bounces today. It keeps its place and timing but rises and falls on `travel` with no overshoot, and stands still with reduced motion.

**Done when**

- Every recorded run of the package passes; where a wait changed, the change is listed.
- Tests for a miss and a right answer in a speaking turn and in a touch turn: the outline's colour, and that nothing is red.
- Screenshots of the end of a story, both sizes, and with the Arabic fake.

**Lane** lane:feature_story.

#### N8.9 Review: answers and the end

- Labels: `agent:gemini`, `lane:feature_review`. Waits for N8.2, N4.8a.

**Boards** [`Noche-Motion-Cuento.dc.html`](noche/Noche-Motion-Cuento.dc.html) (the second turn), [`Noche-Motion-Fin.dc.html`](noche/Noche-Motion-Fin.dc.html).

**What to build**

- **A choice (¿Cuál? and the games with tiles):** a tile takes rule 1. A miss: a 3 px text outline and its round badge in `quick`; the line plays again (the arrow turns once, small level bars beside the word); the tile keeps its outline. Right: a 3 px `right` outline, its badge, one ring leaving the tile in `settle` (to 1.08); the other tiles fade to 40% in `move`; 300 ms later the dash fills.
- **From item to item:** as N8.8's turn to turn.
- **The end:** the last item fades in `quick`. "Done" and the summary line rise; then each section's title; the words arrive by `row`, `stagger` apart, the first five only, the rest together; the orange button lands last.
- Under each word a `NocheStageBar` (full width of its tile). For a word that moved up it grows from its old stage to its new one in `settle`, starting 300 ms after the word arrived. For a word coming back soon it does not move.

**Differs from the board**

- The stage bar under each word is new on this screen. It is what shows "moving up".
- The pictures on the board's tiles are stand-ins cut from scene pictures. Keep the review's own word pictures as they are.

**Done when**

- Tests for a miss and a right answer: colours, and nothing red.
- The end screen's screenshots redone, both sizes.

**Lane** lane:feature_review.

#### N8.10 Words

- Labels: `agent:gemini`, `lane:feature_words`. Waits for N8.2, N4.4.

**Board** [`Noche-Motion-Tabs.dc.html`](noche/Noche-Motion-Tabs.dc.html) (the Words tab).

**What to build**

- The list under the skill switch is in a `NocheFollow` with distance `tab`: Speaking comes from the end side after Listening, and so on.
- The chart's bars grow when the tab arrives (`NocheBarChart`).
- "Start review" lands last.

**Done when** a test picks each skill in both orders and reads the side the list comes from.

**Lane** lane:feature_words.

---

#### N8.11 Library: a bookcase, and a new story locked until he knows more words

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N8.2, N4.5.

**Salim's words**

> I'd like the shelf to read more like a shelf. that page is too busy right now.

> when you want to generate a story and dont have a enough words yet, it should just be locked and say come back when you learn more words.

**Board** [`Noche-Biblioteca-Cerrado.dc.html`](noche/Noche-Biblioteca-Cerrado.dc.html). It replaces [`Noche-Biblioteca.dc.html`](noche/Noche-Biblioteca.dc.html) for this screen.

**What to build**

The page is three shelves. A shelf is a row of things standing on a plank: 4 of `line` on 8 of `chip`, from 16 at the start to the screen's end edge.

- **Reading now** (only with a book in progress): its cover 90 by 126 facing out, and beside it `"Keep reading · Chapter <N>"`, the title, `"Page <P> of <Total> · <M> min left in the chapter"` and a progress bar in text colour.
- **Stories:** the first place is the new-story slot (132 by 120, dashed). Then the stories, newest first: scene picture 104 by 120 with radius 12 at the top and 2 at the plank; the title under the plank.
- **Books:** covers standing on the plank, 120 or 132 high, titles on the covers, nothing under the plank.
- The orange "Continue reading" (56) above the tab bar, as now.

Gone from the page: the topic pills and "Write my story" (they are in the sheet, N8.12), the All / Stories / Books filter, the "Story" and "Book" captions, the boxed card, "reading counts from A2".

**The new-story slot**

- Ask the generator first. `StoryGenerator` gets `canWrite(vocabulary, due, previous)`: true when `generate` with no practice words would return a story. The Library calls it when it opens and when progress changes.
- **Locked** (it is false): a dashed `line` outline, a lock, and "Come back when you learn more words." It is not a button and nothing happens on a tap.
- **Open:** a dashed label-colour outline, a plus, and "A new story at your level". A tap opens the sheet (N8.12).
- Turning from locked to open while on screen: the lock fades out in `quick`, the open slot fades in.
- The message "There's no new story that fits your known words yet." is no longer reachable from an empty prompt and is removed. The one for practice words that do not fit stays, in the sheet.

**Differs from the board**

- The board's switch "enoughWords" is `canWrite`.
- With no book in progress there is no first shelf and no orange button.

**Done when**

- Screenshots: locked, open, an empty shelf, stories only, stories and books; both sizes.
- A test: a learner with no words gets the locked slot and cannot open the sheet.

**Lane** lane:feature_library.

#### N8.12 Library: writing a story

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N8.11.

**Board** [`Noche-Motion-Escribir.dc.html`](noche/Noche-Motion-Escribir.dc.html).

**What to build**

- The sheet "Write my story" (`NocheSheet`): what the app's sheet holds now, with its main button text-filled (not orange: the page keeps its one orange).
- **Writing:** on "Write my story" the sheet keeps its place and height and swaps its content (N8.2): three 12 dots in `other` and "Writing your story" (`sheetTitle`) with "With the words you know." under it. Only the dots move. It cannot be closed while it writes.
- **Done:** the sheet goes down; 260 ms after it starts down, the new story takes the place after the slot: the others travel over in `move` on `travel`, then it fades in over `move`. It carries a "New" tag (ground fill, `labelStrong`) until it is opened.
- **It could not be written or saved:** the sheet swaps back to its form with the app's message above the button.

**Differs from the board**

- The board asks for a topic. Keep what the app's sheet asks today (practice words); topics only if #2 built them (page 22, N4.5).
- The new story's picture on the board is a stand-in. Show a written story on the shelf as the Library shows one today (N4.5).

**Done when**

- A test with a slow fake generator reads the sheet's height before, during and after, and that it does not close on a tap outside while writing.
- A test reads the shelf's order after a story is written.

**Lane** lane:feature_library.

#### N8.13 Reader: pages, the sentence being read, a word

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N8.12, N5.1.

**Board** [`Noche-Motion-Pagina.dc.html`](noche/Noche-Motion-Pagina.dc.html).

**What to build**

- **A page turn:** the page's text is in a `NocheFollow` with distance `page`. The page number changes in place; the progress bar's fill changes in `move` on `travel`. A swipe turns the page the same way.
- **Listening:** the sentence being read has the lit fill; when the voice moves on the old one loses it and the new one gets it, both in `quick`. At the end of a page it turns by itself and the first sentence is lit as it arrives. The play disc's icon swaps play and pause by a `quick` fade.
- **A word** (N5.1): its fill and text colour change in `quick`; its bubble rises by `row` and fades in over `quick`; it leaves in `press`. The bubble stays inside the page: centred on the word, or tied to the word's start or end when it would cross the page's edge.

**Done when**

- A test turns forward and back and reads the side the page comes from, with the Spanish and the Arabic fake.
- A test opens a bubble on the first and the last word of a line and reads that it is inside the page.

**Lane** lane:feature_library.

#### N8.14 Reader: text and page

- Labels: `agent:gemini`, `lane:feature_library`. Waits for N8.13, N5.2.

**Board** [`Noche-Motion-Lector.dc.html`](noche/Noche-Motion-Lector.dc.html).

**What to build**

- The sheet has no scrim, so the page shows each change as it is made. The "Aa" button fills while it is open (`quick`).
- **Text size:** a step's dash fills or empties in `quick`; the text changes size at once.
- **Font:** the outline slides between the three cards (`NocheOutlineGroup`); the text changes at once.
- **Line spacing:** the thumb slides (`NocheSegmented`); the text changes at once.
- **Page:** the ring slides between the three colours in `move` on `travel`; the page's ground, text, labels and rules change colour together in `move` on `travel`.
- **The two switches:** `NocheSwitchRow`; the underline and the lit sentence change in `quick`.

**Done when** a test per control, and the sheet's screenshots redone.

**Lane** lane:feature_library.

---

#### N8.15 Speak: locked calls, a call, "Call done"

- Labels: `agent:gemini`, `lane:feature_speaking`. Waits for N8.2, N4.6.

**Board** [`Noche-Motion-Llamada.dc.html`](noche/Noche-Motion-Llamada.dc.html).

**What to build**

- **Locked** (rule 7, `NocheQuietLock`): the locked place pill shows a small pill under it with a lock and `"After <place>"`; the locked call card's outline turns solid and its `"<N> min · after story <M>"` lights up. Both for 1.4 s. The place pills use `NochePillGroup`, and the card under them a `NocheFollow` with distance `tab`.
- **Calling:** the call disc stays where it is and becomes the call's mic. The Speak screen fades in `quick`; the shell does the tab bar and the ground (N8.3); the close button and the clock fade in after 200 ms; the picture rises by `row`.
- **In the call:** `NocheMic` for every state. While it rings: the thinking look with the word "Calling <partner>". Then `theySpeak`, `listening`, `thinking`, with the course's mic words. Each line of the partner rises by `row` in `move`. When he stops, what the app heard rises under the partner's line in `right` colour, while the mic thinks.
- **Hanging up:** the call fades in `quick`. "Call done" (`pageTitle`) and `"<N> min · <M> words said"` rise by `row`; the words he said arrive as outline pills (40 high), `stagger` apart, the first five only; the orange `"Back to <Speak tab name>"` lands last.

**Differs from the board**

- The summary's button is orange (`NochePrimaryButton`); the app's is blue.
- Help, the errors and the call with a picture keep their screens and get the same arrivals.

**Done when**

- The recorded call runs pass.
- Tests: a locked tap changes nothing but the outline and the reason; the summary's pills arrive in order.
- Screenshots of the call in each mic state and of "Call done", both sizes.

**Lane** lane:feature_speaking.

#### N8.16 Me and Your languages

- Labels: `agent:gemini`, `lane:feature_profile`. Waits for N8.2, N4.7, N2.10.

**Boards** [`Noche-Motion-Idioma.dc.html`](noche/Noche-Motion-Idioma.dc.html), [`Noche-Motion-Tabs.dc.html`](noche/Noche-Motion-Tabs.dc.html) (the Me tab).

**What to build**

- **Your languages:** the 2 px outline slides from the language he had to the one he picks (`NocheOutlineGroup`); the tick appears on it and "Switch" appears on the other, in `quick`. 420 ms after the tap the sheet goes down and the course changes (the shell does the turn-over, N8.3).
- **Me:** the minutes chart's bars grow when the tab arrives; the Listening and Speaking bars grow from zero in `settle` after 180 ms.

**Done when** a test picks the other language and reads the outline's place at the start, the middle and the end.

**Lane** lane:feature_profile.

---

## Part 4. Decisions on this page that are Claude's, for Salim to change

- Treated every motion board as approved, including the ones drawn without a screen to follow: the end of a story, the wait while a story is written, the line while the course loads.
- No bounce anywhere in the interface. The touch turn's hint loses its bounce.
- Map trips are capped at 6 hops (1.2 s) and take the shortest road. This changes the map's route code and the times of some recorded runs.
- "You are here" moves above a place's house when the house is in the way.
- Arriving at a place no longer opens it. The card becomes the place; a swipe up or a tap opens it. A swipe down goes back to Up next.
- The Library loses its filter, its captions and "reading counts from A2".
- "Enough words" is "the generator has a story for him"; there is no number to show.
- The stage bar under each word at the end of a review, and under each new word at the end of a story, is new.
- The "Write my story" sheet's main button is text-filled, and "Call done"'s is orange.
- The videos are not in the repo.

## Part 5. Not covered

- Reduced motion is written into every board and every story, but no video shows it.
- The welcome, the level check, the review card, Plans, Add your own and the YouTube boards have no motion board. They take the shared pieces' motion (N8.2) and `NocheArrive` for their rows, and nothing else, until they are drawn.
- Sound and haptics: the hop's sound and tick stay; nothing else is added.
