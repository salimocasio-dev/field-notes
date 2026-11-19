# 21-feature-words-needs-coqui-ui-show-sheet

## What I need

A way for a feature to open a `CoquiSheet` over the whole screen, tab bar and Mapa disc included, with the scrim and the 200 ms slide of v=39: for example `Future<void> showCoquiSheet(BuildContext context, {required CoquiSheet sheet})` in coqui_ui, which pushes a transparent route on the root navigator and puts a `CoquiSheetLayer` in it, and closes it (slide down, then pop) when the sheet's `onClose` or the scrim asks. (Or, if the shell is to own the layer, the orchestrator's word on where it stands.)

## Why

Order 21: the word sheet. In v=39 the scrim dims the page and the tab bar, and the sheet stands just above the tab bar and the Mapa disc (`#sheetbg` z-index 11 above `nav`, app.html:68-73; leer_check.py: "word sheet: sits fully above the tab bar and the Mapa disc, the scrim dims both"). `CoquiSheetLayer` says "fill the screen with it (a `Stack` child)", but a feature builds only its tab, inside whatever the shell puts round it: the tab bar is the shell's and is drawn over, or beside, the tab. The place sheet (feature_map) and the welcome (feature_profile) have the same need.

## What I am using meanwhile

`showWordSheet` in `feature_words/lib/src/word_sheet.dart`: a `PageRouteBuilder` (not opaque, no transition) on `Navigator.of(context, rootNavigator: true)`, whose page is a `Material(type: transparency)` holding a `CoquiSheetLayer` that slides open after the first frame and, on close, slides out, waits 200 ms and pops. The dev entry draws a stand-in tab bar under it so that the scrim dims the bar as in the old pictures. This needs a `Navigator` above the tab bar; the shell's `MaterialApp` has one.

## Order and branch

Order 21, `lane/feature_words/21`.
