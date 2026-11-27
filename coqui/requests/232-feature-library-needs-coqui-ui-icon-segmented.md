# Request: Icon/child option and compact 0-padding mode on NocheSegmented

## What I need

In `coqui/packages/core/coqui_ui/lib/src/noche_controls.dart`:

Extend `NocheSegmentOption<T>` and `NocheSegmented<T>` to support icon or custom child options (for example an optional `NocheIconData? icon` or `Widget Function(BuildContext, Color color, bool selected)? builder` alongside `label`) and a compact 0-padding mode (e.g., `EdgeInsetsDirectional padding = const EdgeInsetsDirectional.all(4)`, border radius matching `NocheSize.pillRadius + 1` with inner 48 px options and full-bleed sliding `NocheColors.text` thumb) while keeping `NocheSegmented`'s `move` on `travel` sliding thumb, mid-flight retargeting, `quick` icon/text colour fade, and reduced-motion snap+fade.

## Why

Order #232 (`N8.14 Reader: text and page`, `docs/proyecto/noche/Noche-Motion-Lector.dc.html`, `docs/proyecto/noche/Noche-Lector-Aa.dc.html`) requires the Line spacing control (tight / normal / loose icons inside a compact 50 px-tall 0-padding pill track) to slide a single `NocheColors.text` thumb in `move` on `travel` and cross-fade icon colour in `quick` on `enter`, using the same motion contract as `NocheSegmented`.

## What I am using meanwhile

A package-local stateful `_LineSpacingControl` widget in `coqui/packages/features/feature_library/lib/src/reader_settings_sheet.dart` mirroring `NocheSegmented`'s `SingleTickerProviderStateMixin` sliding thumb (`motion.move` on `motion.travel` with mid-flight retargeting and reduced-motion `quick` fade) and `TweenAnimationBuilder<Color?>` icon colour fades.

## Order and branch

- Order: #232 (`N8.14 Reader: text and page`, `lane:feature_library`)
- Branch: `lane/feature_library/232`
