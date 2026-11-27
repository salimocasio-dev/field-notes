# Request: Quick fill-and-empty color fade mode on NocheDashes

## What I need

In `coqui/packages/core/coqui_ui/lib/src/noche_data.dart`:

Support a quick colour-fade mode on `NocheDashes` (for example a `bool quickColorFade = false` parameter or named constructor) where each dash transitions its colour between `NocheColors.text` (`done`) and `NocheColors.line` (`notYet`) in `NocheMotion.quick` on `NocheMotion.enter` on both fill and empty, without directional width-wipe animation.

## Why

Order #232 (`N8.14 Reader: text and page`, `docs/proyecto/noche/Noche-Motion-Lector.dc.html`) specifies that the 7 text-size dashes fill and empty by colour in `quick` (`140 ms` on `enter`) as the learner taps smaller or larger `A`. Default `NocheDashes` animates lesson-progress wipes differently from the symmetric `quick` fill-and-empty colour fade specified for the reader text-size meter.

## What I am using meanwhile

A package-local `_TextSizeDashes` widget in `coqui/packages/features/feature_library/lib/src/reader_settings_sheet.dart` rendering 7 equal 8 px-tall, 4 px-radius dashes separated by 4 px gaps with `AnimatedContainer(duration: motion.quick, curve: motion.enter)` between `NocheColors.text` and `NocheColors.line`.

## Order and branch

- Order: #232 (`N8.14 Reader: text and page`, `lane:feature_library`)
- Branch: `lane/feature_library/232`
