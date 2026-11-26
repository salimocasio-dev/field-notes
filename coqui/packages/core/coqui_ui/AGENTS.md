# coqui_ui

Colours, type, shared widgets, the lesson frame, the widget that shows a pixel picture.

- Kind: Flutter package.
- Replaces: the CSS in app.html, notas/ui-decisiones-1 to 3, page 09.
- One package is one lane. Branch: `lane/coqui_ui/<order number>`.
- Work orders: 20.
- The runbook is `../../../AGENTS.md`. Read it first.

## May depend on

- The plan's row: contracts, Flutter.
  The plan's table says "Flutter only". The orchestrator changed it on Nov 19, 2026: page 12, section 3 needs the contracts, and contracts depends on nothing.
- Coquí packages: `coqui_contracts`.
- Third party: `material_ui` ^1.11.1.
- Dev only: `flutter_lints`, `flutter_test` (from the SDK).
- Material widgets come from `package:material_ui/material_ui.dart`. Nobody imports `package:flutter/material.dart`.
- Nothing else. A package that is not listed here is added by a request in `coqui/requests/`, not by you.
- `dart run tool/check_boundaries.dart` (at `coqui/`) fails the branch otherwise.

## Public surface

- `lib/coqui_ui.dart` is the one public file. Everything else is under `lib/src/`.
- Nobody imports another package's `src/`.
- Today the public file holds a library comment and nothing else. `fonts/` holds Pixelify Sans, weights 400 and 700, as `.ttf` (converted from `historia/fuentes/`), with its licence `LICENSE-pixelify-sans.txt` beside them. The pubspec declares the family `Pixelify Sans`. Use it only where page 09 allows: signs on the map, never learning content.
- Since order 02 it holds `PictureRef`, `PictureSource`, `Services`, `FeatureTab`, `FeatureModule` (page 12, section 3).
  `PictureSource.of(ref, {width = 196, height = 104, animated})`: the size is in picture pixels (196 x 104 a review picture, 96 x 106 a level-check cell); the widget it returns shows it through `PixelView`, which takes the whole scale from its box; there is no scale parameter.
- Since order 20 it also holds `PixelView` and the shared look of v=39 (`PictureRef` has a `name`, part of its equality: `PictureRef.of` names a pair's side `<word>.si` or `<word>.no`, `PictureRef.ofLevel` a level-check picture `nivel.<word>.<index>`):
  - `CoquiLabels`: the Spanish names v=39 hard-codes for its screens and activities (the five tab names, `reviewTitle` "¿Cuál?", `review` "Repaso", the app name, which is also the speaker label of a book line; the book's `fin` "Fin" and `again` "Otra vez"; the shelf's `pictureStory` "Cuento con dibujos" and `routine` "Haz esto"), each with its source line. Nothing else Spanish lives in a widget;
  - tokens: `CoquiColors`, `CoquiMetrics`, `CoquiShadows`, `CoquiText`, `pixelifyStyle` (ligatures off), `coquiTheme()` (standard visual density on every platform). Text is Roboto, shipped in `fonts/` in four weights (Regular 400, Medium 500, SemiBold 600, Bold 700), all converted from the one source `@fontsource/roboto` 5.3.0 (SIL OFL 1.1, `LICENSE-roboto.txt`), the same on every platform; every text style turns ligatures off (`coquiNoLigatures`: "fi" is two plain letters); borders go through `cssBorderWidth` (the CSS width floored to whole CSS pixels and drawn as it is, anti-aliased, as Chrome does: 2.625 device pixels at ratio 2.625); each says the CSS file and line it comes from;
  - `CoquiIcons`/`CoquiIcon` (the old SVG path data; `CoquiIcons.flame` and `CoquiFlame` are the streak's flame, drawn in two tones: no emoji is written as text anywhere),  `CoquiLayout` (media queries, safe area);
  - buttons: `CoquiButton`, `PlayButton`, `CoquiCloseButton`, `LessonButton`, `LessonButtonRow` (`.pair`, `.reader`, `.readerLast`), `LessonBackButton`, `LessonNextButton`, `LessonStartButton`, `LessonIconButton`, `LessonCloseButton`, `LessonSoundButton`, `LessonTextSizeButton`;
  - `CoquiSheet`, `CoquiSheetLayer` (a sheet in place), `showCoquiSheet` (one sheet over the whole app, tab bar included: a route of the root navigator with v=39's scrim; X, drag, scrim tap and the system back close it, a `modal` one only its own button; a second call while one is open is ignored); `CoquiTabBar`, `CoquiTabs`, `MapChips`; `LessonFrame` (with `underPicture`, a story's end title 16 px under the picture), `PictureChoice`, `LessonProgressDashes`, `LessonProgressLine`, `lessonGridPlan`/`LessonPictureGrid` (the Repaso end screen's grid: 2 or 3 columns at a whole scale, cual.js `cualGrid`);
  - `MeterDots`, `SkillMeter`, `EarMouthMeters`, `WordCard`, `WordGrid`;
  - cards and rows: `TabPage`, `CollapsingColumn`/`Block` (CSS margin collapse), `ScreenTitle`, `SectionTitle`, `KeyLine`, `EyebrowLabel`, `CoquiCard`, `CoquiRow`, `DividedRows`, `ListRow`, `TodayCard`, `StatCard`, `SegmentedPills`, `CoquiSwitch`, `PageDots`, `PictureFrame`;
  - `ListFade`, `FadingEdges`.
  All are dumb: values and callbacks, no feature logic. Every number is copied from the old CSS (v=39), never chosen.

- Order 27, the parts of Repaso's games (`lib/src/game_tiles.dart`, `test/game_tiles_test.dart`): `WordTile` (a written
  word, with a speaker of its own when the word can be heard alone), `SpeakerTile`, `RoundSpeaker` (the round 64 px
  speaker of a game that plays a sentence, with a ring that pulses while it sounds), `TileTray` (its rows centred; a child that is not a tile, such as Arma la frase's check, is 8 px after the last tile
  level with the row's middle, or alone on the row below; with `line` it is the answer line of Arma la frase: tiles from the
  left, `lineRows` rows high from the start whatever is on it (`TileTray.lineHeight`), a 1.5 px baseline under them), `StreakChip` ("N in a
  row" from three; with `reserve` its place of `StreakChip.reservedWidth` is kept when it does not show, and the pill
  shrinks to fit it), `TouchSign` (the sign for what to touch: Material's pointing hand, `touch_app`, as path data
  `CoquiIcons.touchApp`, white on a 44 px green disc, bouncing gently, still with reduced motion, taking no touch; it goes
  inside a picture's bottom-right corner, `TouchSign.pictureInset` (12 px) from both edges, and at the right end of a word
  tile (`WordTile.sign`: inside it, vertically centred; the word stays centred with 40 px clear of it on both sides, as for a
  speaker, which gives the sign its place while it shows), never a chevron or arrow), `NumberBadge`, `TileLook` (with `empty`: the place of
  a tile that is not there, an outline of its size); the tokens `lessonTile`, `lessonTilePressed`, `lessonChip` and the
  styles `lessonTile`, `lessonHint`, `lessonChip` (not in v=39: chosen for the games). A tile's frame is drawn over its
  face (a foreground decoration), so a ring, a badge or the sign never changes its size. `CheckBadge` and `WrongBadge`
  (the round X in the red-orange, at the corner where a right answer has its check) are in `lesson_frame.dart` with
  `PictureChoice(cross:)`; a tile has `check`, `cross` and `number` (Parejas' pair, beside the check).
  `LessonProgressDashes(marks:, current:)` is Repaso's bar: a dash for each item in the colour of its first answer
  (`DashMark.right` green, `wrong` red-orange, `skipped` the lighter grey `CoquiColors.dotSkipped`, `none` the grey of not
  reached), and a white outline round the `current` one, outside its box; without `marks` it is v=39's bar (`done`).
  `PictureChoice(inside: true)` draws a picture's ring inside its box (a picture marked is the same size as one not). `Pressable` is exported. They are not in the gallery; feature_review's screenshots show them.

- Noche, story N1.1 (`lib/src/noche_tokens.dart`, `test/noche_tokens_test.dart`): `NocheColors` (and `NocheCoverColors` for `coverPlum` and `coverBlue`), `NocheType` (with `forScript` and `unbundledScripts`), `NocheSize`, `nocheFontFiles`. They sit beside the old tokens; no old token changed. A `NocheType` style sets family, weight, size, line height and tracking, and no colour (page 22 gives none): the piece that uses it names the colour. Fonts, in `fonts/`, are static TTFs cut with fonttools from github.com/google/fonts at commit `06bfe0d62a98375cb09c942fa18e68bd32cff057` and subset as page 22, N1.1 says: Atkinson Hyperlegible Next (400, 500, 600, 700, 800), Bricolage Grotesque (700, 800), Bricolage Grotesque Display (800), Literata (400, 500, 600), Literata Italic (400), Lexend (400, 500), Noto Sans Arabic (500, 700), each with its `LICENSE-<family>.txt`, each declared twice in the pubspec. The test `noche_tokens_test.dart` checks every hex, the WCAG contrast (at least 4.5), the files and a golden of one line per family and weight (`test/goldens/noche_fonts.png`).

- Noche, story N1.2 (`lib/src/noche_icons.dart`, `lib/src/noche_a11y.dart`, `lib/src/noche_controls.dart`, `lib/src/noche_data.dart`, `lib/src/noche_chrome.dart`, `tool/gallery/noche_pieces.dart`, `test/noche_pieces_test.dart`): `NocheTabBar` (and `NocheTabs`), `NochePill`, `NocheChip`, `NocheCard`, `NochePrimaryButton`, `NocheOutlineButton`, `NochePlayBar`, `NochePlayDisc`, `NocheSegmented`, `NocheDashes`, `NocheStageBar`, `NocheProgressBar`, `NocheSheet` (`NocheSheetOverlay`, `showNocheSheet`), `NocheSwitchRow`, `NocheSectionLabel`, `NocheBarChart`, `NocheIcon`/`NocheIcons`, `NocheCover`, `NocheA11y` (`lessonLabelsInCourseLanguage = false`), and `NocheScreen`. Directional layout only; no old piece changed. Dev page sections `?section=noche-ltr` and `?section=noche-rtl` in `tool/dev_main.dart`, with goldens (`test/goldens/noche_dev_ltr.png`, `test/goldens/noche_dev_rtl.png`), a 48x48 touch-target walker test, and a directional grep test.

- Noche, story N1.3 (`lib/src/noche_mic.dart`, `lib/src/noche_a11y.dart`, `tool/gallery/noche_mic.dart`, `test/noche_mic_test.dart`): `NocheMic` and `NocheMicState` (`ready`, `listening`, `thinking`, `theySpeak`, `right`, `notYet`), stateless with zero timers or delays (`thinking` shows immediately on frame 0; `notYet` never uses red and never shakes), level-driven flanking voice bars (`8..56`, five per side), status words read from `Language.micWords` with `NocheType.forScript`, and the six `NocheA11y` mic roles (`micReady`, `micListening`, `micThinking`, `micTheySpeak`, `micRight`, `micNotYet`). Dev page sections `?section=noche-mic` and `?section=noche-mic-rtl` in `tool/dev_main.dart`, and the 6-state board golden (`test/goldens/noche_mic_states.png`).

- Directional UI, `#49` (`lib/src/speech_bubble.dart`, `tool/gallery/lesson_direction.dart`, `test/direction_test.dart`): package-wide directional audit across all `lib/src/*.dart` files replacing physical `left`/`right` layout APIs (`EdgeInsets.fromLTRB`, `EdgeInsets.only`, `Positioned`, `AnimatedPositioned`, `Alignment.*Left/*Right`, etc.) with `EdgeInsetsDirectional`, `PositionedDirectional`, `AnimatedPositionedDirectional`, and `AlignmentDirectional`; `CoquiIconData.matchTextDirection` mirrors directional icons (`CoquiIcons.left`, `CoquiIcons.right`) in RTL while `PixelView` stays unmirrored; `LessonSpeechBubble`, `BubbleTailSide`, `LanguageDirectionUi`, and `LanguageUi` helpers; explicit `textDirection` on `NocheMic` status text; dev page sections `?section=lesson-direction-es` and `?section=lesson-direction-ar` in `tool/dev_main.dart` with 390x844 and 412x915 Chrome captures under `test/screenshots/`.

- Noche cleanup, story N1.4 (`#82`): deleted every unreferenced v=39 legacy widget, file, font, gallery section, and test with zero callers outside `coqui_ui` — `meters.dart` (`MeterDots`, `SkillMeter`, `EarMouthMeters`), `word_card.dart` (`WordCard`, `WordGrid`), `sheet.dart` (`CoquiSheet`, `CoquiSheetLayer`, `showCoquiSheet`), `CoquiTabBar`, `MapChips`, `CoquiFlame`, `ListFade`/`FadeEdge`, `CoquiButton`/`PlayButton`/`CoquiCloseButton`/`LessonButtonRow`/`LessonBackButton`/`LessonNextButton`/`LessonSoundButton`/`LessonTextSizeButton`, all 19 unused v=39 layout/card/row widgets in `cards.dart`, `LessonFrame`/`LessonProgressDashes`/`LessonProgressLine`/`LessonFin`/`LessonPictureGrid`/`lessonGridPlan`, `pixelifyStyle` + `Pixelify Sans` font files, `tool/gallery/screens.dart`, `test/sheet_test.dart`, and `test/word_card_picture_test.dart`. Kept only the minimal legacy symbols still actively referenced outside `coqui_ui` (`CoquiColors`, `CoquiMetrics`, `CoquiShadows`, `CoquiText`, `Roboto` fonts, `CoquiIcons`/`CoquiIcon`, `CoquiLabels`, `CoquiLayout`, `CoquiTabs`, `coquiTheme`, `PictureFrame`, `FadingEdges`, `LessonButton`/`LessonCloseButton`/`LessonStartButton`, `DashMark`/`ChoiceRing`/`ChoiceDim`/`PictureChoice`, and `game_tiles.dart`) pending follow-up cleanup in `feature_speaking`, `feature_review`, and `coqui/app/tool/`.

## The gallery

`tool/dev_main.dart` shows every token and every widget in each of its states, one section per reference picture of `coqui/ref/pantallas/` (the file is named under each section). The sample words and titles are placeholders; the labels v=39 hard-codes are copied. The book reader and the shelf row are not here: Biblioteca (`feature_library`) draws its own, the only place that uses them.

```
cd coqui/packages/core/coqui_ui
flutter run -d chrome -t tool/dev_main.dart                       # all sections
flutter run -d chrome -t tool/dev_main.dart --web-launch-url "/?section=palabras"
flutter build web -t tool/dev_main.dart --no-web-resources-cdn    # the web build
node tool/shots.mjs --out <dir>      # builds it, serves it, captures every section at 412 x 915, ratio 2.625, and writes <dir>/pairs.json and <dir>/network.json; it fails if any request leaves localhost
node tool/shots.mjs --device iphone --no-build --out <dir>   # the same at 390 x 844, ratio 3
```

## Run and test it alone

```
cd coqui/packages/core/coqui_ui
flutter test
```

At `coqui/`, for the checks every branch passes:

```
flutter pub get
dart run tool/check_boundaries.dart
dart format --output=none --set-exit-if-changed .
flutter analyze
```

## Lines that apply

Quoted exactly from the pages. Where this file and a page differ, the page wins.

From 09-ui-plan, "What the doc says, in short":

- Hybrid rendering: only the map, terrain, avatar and its animations are pixel art. Buttons, text, pop-ups, counters and the tab bar are crisp modern UI over it. A pixel font only for signs on the map, never for learning content.
- Pixel art scaled nearest-neighbour, by whole numbers; no sub-pixel movement.
- Thumb zone: primary actions and the mic in the bottom third. Targets 48 px or more, 16 to 24 px apart. 8-point grid. Type: H1 24 semibold, H2 16 to 18, body 14 to 16, labels 12.
- Lessons go full screen; the tab bar hides and comes back on exit. Learning screens are calm (white, off-white or dark grey); colour only for meaning (green right, red/orange wrong, blue/purple system and active tab).
- Each tab keeps its state (scroll, place in a deck).
- Speaking: a big mic in the bottom centre with clear states (idle, listening with a live wave, processing within 200 ms, system speaking in another colour); reply within about 0.6 to 1 s; pitch-contour feedback for intonation.

From 09-ui-plan, "What is built (v=34, Nov 14)":

- One system: green #17803F for anything that starts or continues learning, blue #3B5BDB for other primary actions; one green 48 px play disc; one outline secondary button; 48 px targets 16 px apart; 8-point grid; H1 24, H2 18, body 16, labels 12.
- Lessons (story, ¿Cuál?, level check) are full screen on calm dark grey, the tab bar hidden: a top bar with a close X (works mid-play and returns to where the lesson began), a thin progress bar and the sound button; pictures whole-number scaled; the start disc in the bottom third; at a story's end its last picture stays, with the title and buttons under it.

From 10-leer-y-repaso, "Rules that bind this (his)":

- Only the map is game-styled. Reading and review are calm screens (UI plan).

From 03-requirements, "Lessons":

- English only so a stuck learner can navigate; never a mostly-English lesson.

From 03-requirements, "His instructions to the build chat (Nov 13)":

- "Why are the captions English. Everything should be in spanish." (The code was all Spanish; most likely his phone translated the page. Pages are now marked do-not-translate.) Then: "It's good. Continue". So: nothing on screen in a lesson may turn into English, by any route.
