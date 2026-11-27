# Request: Cross-fade icon changes in `NochePlayDisc`

## What I need

Animate icon transitions in `NochePlayDisc` (`coqui/packages/core/coqui_ui/lib/src/noche_controls.dart`) so when `icon` changes (for example between `NocheIcons.play` and `NocheIcons.pause`), the outgoing and incoming icons cross-fade in `NocheMotion.quick` on `NocheMotion.enter`.

## Why

Story N8.13 (`docs/proyecto/24-noche-motion.md`: "The play disc's icon swaps play and pause by a `quick` fade", board `docs/proyecto/noche/Noche-Motion-Pagina.dc.html`) requires the reader's Listen/Pause disc to cross-fade its icon in `quick`. `lane/feature_library/231` may not modify `coqui_ui`.

## What I am using meanwhile

A package-local `_ReaderPlayDisc` widget in `coqui/packages/features/feature_library/lib/src/text_reader.dart` wrapping `Pressable(disc: true)` with two `AnimatedOpacity` layers (`NocheIcons.play` and `NocheIcons.pause`) driven by `NocheMotion.of(context).quick` on `NocheMotion.enter`.

## Order and branch

- Order: #231 (N8.13 Reader: pages, the sentence being read, a word)
- Branch: `lane/feature_library/231`
