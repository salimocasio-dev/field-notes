# 24 · feature_speaking needs coqui_ui: the call screen's colours, text and widgets, the voice test's marks

## What I need

The pieces below, as members of `coqui_ui` (colours in `CoquiColors`, text in `CoquiText`, sizes in `CoquiMetrics`, the rest as widgets), each from the old page's CSS. Each has a stand-in in `feature_speaking` today (`lib/src/call_look.dart`, `call_mic.dart`, `call_screen.dart`, `voice_test_screen.dart`), named here.

Colours and text of the call (llamada.js, `#llam`):
- `#A7A7B0` (the timer, the grey line before the call, the note under the label): `CallColors.grey`;
- `#2B2B33` (the mic disc while Danny speaks and while the call thinks): `CallColors.discQuiet`;
- `#33333B` (the Help button just touched): `CallColors.helpPressed`;
- `#3FAE6B` (the ring that follows the microphone's level): `CallColors.levelRing`;
- the call's text styles: Danny's line (18 on 24, white, regular), the grey line, what was heard (`CoquiColors.heard`, 16 on 24), the state label (16 on 24 semibold), the note (14 on 20), the timer (12 on 16, tabular): `CallText`.

Widgets of the call:
- the call's frame: the top bar (X at the left, the timer at the right), the picture and its two lines centred in the room above a bottom zone of 244 px (the mic box, the label, the note, Help, 32 px under), and on a phone on its side (`@media (orientation:landscape) and (max-height:500px)`) the picture at the left and the lines and the mic at the right. `LessonFrame` centres only the picture and hangs the caption, so it does not give this layout: `_portrait` and `_landscape` of `CallScreen`;
- the picture's scale: llamada.js's `fit()` (the largest whole number of device pixels per art pixel that fits, from numbers the layout fixes): `CallMetrics.pictureScale`;
- the mic stage with its states (a 96 px box with a 72 px disc): green with a phone; pulsing while it calls; three blue rings spreading from it (1.5 s, the second 0.5 s and the third 1 s late) while Danny speaks; a green ring of box-shadow whose width follows the level; three dots (1 s, 0.18 s apart) while it thinks; every animation off with reduced motion: `CallMicStage`;
- the summary's chips (`.lchips span`: 32 px high, 12 px at the sides, a 1.5 px ring, a pill, as wide as the word): `CallScreen._chip`.

The voice test's marks (habla-prueba.html):
- the progress dashes with a lighter dash (`#7A7A84`) for the line he is on: `LessonProgressDashes` has only the green and the grey;
- the filled microphone (`.mi`), the next arrow (stroke 2.4), the TICK (a green disc, a white tick) and MISS (a grey ring, a short dash) of the rows and of what was just heard, and `#2C2C33` for the hairlines of the rows: `_Test` in `voice_test_screen.dart`;
- the mic disc with its states (a listening ring spreading 28 px in 1.4 s, a blue disc with three blinking dots while it thinks): `_VoiceMicDisc`.

And the Spanish words the voice test writes itself, as `CoquiLabels` has the names v=39 hard-codes ("Escuchando…", "Un momento…", "El micrófono no está disponible.", "Otra vez", and the aria-labels "Micrófono", "Siguiente", "Progreso"; habla-prueba.html lines 78, 88, 89, 97, 148, 168). Today they come with the lines (see 24-feature-speaking-needs-coqui-contracts-voice-test-lines.md), because a feature may not write them.

## Why

Order 24: "Screens built ONLY from coqui_ui widgets and tokens (a missing or mismatching widget: file a request and build a local stand-in in your package meanwhile; list each)".

## What I am using meanwhile

The stand-ins named above, built from `CoquiColors`, `CoquiText`, `CoquiMetrics`, `CoquiIcon`/`CoquiIconData` (my own icon data for the filled mic, the arrow, the tick and the dash), `LessonCloseButton`, `LessonButton`, `PictureFrame` and `CoquiLayout.border`. Nothing under `lib/` draws a colour or a style that these do not name. When coqui_ui has them, the files `call_look.dart` and the private widgets go and the screens import the shared ones.

## Order and branch

Order 24, branch `lane/feature_speaking/24`.
